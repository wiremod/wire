AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

DEFINE_BASECLASS("base_wire_entity")

--HELPERS
local function getGate(node)
	if node.type == "wire" then
		return GateActions[node.gate]
	elseif node.type == "fpga" then
		return FPGAGateActions[node.gate]
	elseif node.type == "cpu" then
		return CPUGateActions[node.gate]
	end
end

local function getInputType(gate, inputNum)
	if gate.inputtypes then
		return gate.inputtypes[inputNum] or "NORMAL"
	else
		return "NORMAL"
	end
end

local function getOutputType(gate, outputNum)
	if gate.outputtypes then
		return gate.outputtypes[outputNum] or "NORMAL"
	else
		return "NORMAL"
	end
end

local function getDefaultValues(node)
	local gate = getGate(node)

	values = {}
	for inputNum, name in pairs(gate.inputs) do
		local type = getInputType(gate, inputNum)

		values[inputNum] = FPGADefaultValueForType[type]
	end

	return values
end

--CONVAR
fpga_quota_avg = nil
fpga_quota_spike = nil

do
	local wire_fpga_quota_avg = GetConVar("wire_fpga_quota_avg")
	local wire_fpga_quota_spike = GetConVar("wire_fpga_quota_spike")

	local function updateQuotas()
		fpga_quota_avg = wire_fpga_quota_avg:GetInt() * 0.000001
		fpga_quota_spike = wire_fpga_quota_spike:GetInt() * 0.000001
	end

	cvars.AddChangeCallback("wire_fpga_quota_avg", updateQuotas)
	cvars.AddChangeCallback("wire_fpga_quota_spike", updateQuotas)
	updateQuotas()
end



function ENT:UpdateOverlay(clear)
	if clear then
		self:SetOverlayData( {
								name = "(none)",
								timebench = 0,
								timebenchPeak = 0,
								errorMessage = nil,
							})
	else
		local timepeak = self.timepeak
		if self.timebench < 0.000001 then
			timepeak = 0
		end
		self:SetOverlayData( {
								name = self.name,
								timebench = self.timebench,
								timebenchPeak = timepeak,
								errorMessage = self.ErrorMessage,
							})
	end
end

function ENT:ThrowCompileError(message, overlay)
	self:SetColor(Color(255, 0, 0, self:GetColor().a))
	self.CompileError = true
	self.ErrorMessage = overlay
	self:UpdateOverlay(false)

	WireLib.ClientError("FPGA: Compilation error - " .. message, WireLib.GetOwner(self))
end
function ENT:ThrowExecutionError(message, overlay)
	self:SetColor(Color(255, 0, 0, self:GetColor().a))
	self.ExecutionError = true
	self.ErrorMessage = overlay
	self:UpdateOverlay(false)

	WireLib.ClientError("FPGA: Execution error - " .. message, WireLib.GetOwner(self))
end

--------------------------------------------------------
--INIT
--------------------------------------------------------
function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Debug = false

	self.time = 0
	self.timebench = 0
	self.timepeak = 0

	self.LastTimedUpdate = 0
	self.ExecutionCount = 0

	self.Uploaded = false
	self.ExecutionError = false
	self.CompileError = false
	self.ErrorMessage = nil

	self.ExecutionInterval = 0.015
	self.ExecuteOnInputs = false
	self.ExecuteOnTimed = false
	self.ExecuteOnTrigger = false

	self.Data = nil
	self.ViewData = nil
	self.Hash = -1

	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})

	self.Gates = {}
	self.LastGateValues = {}

	self.Nodes = {}
	self.InputNames = {}
	self.InputTypes = {}
	self.InputIds = {}
	self.OutputNames = {}
	self.OutputTypes = {}
	self.OutputIds = {}

	self.TimedNodes = {}

	self.NodeGetsInputFrom = {}

	self:UpdateOverlay(true)

	self:GetOptions()
end

--------------------------------------------------------
--DUPE
--------------------------------------------------------
function ENT:BuildDupeInfo()
	self.UploadData = self.Data
	return BaseClass.BuildDupeInfo(self) or {}
end

function ENT:Setup(data)
	if data then
		-- entity was duplicated
		self:Upload(data)
	end
end

duplicator.RegisterEntityClass("gmod_wire_fpga", WireLib.MakeWireEnt, "Data", "UploadData")

--------------------------------------------------------
--RECONSTRUCTION
--------------------------------------------------------
function ENT:GetOriginal()
	if self.Data then
		return WireLib.von.serialize(self.Data)
	else
		return WireLib.von.serialize({})
	end
end

--------------------------------------------------------
--OPTIONS
--------------------------------------------------------

function ENT:GetOptions()
	local ply = self:GetPlayer()

	if FPGAPlayerOptions[ply] then
		--set options
		self.Options = FPGAPlayerOptions[ply]
	else
		--set to default
		self.Options = {
			allow_inside_view = false
		}
	end
end

function ENT:AllowsInsideView()
	return self.Options.allow_inside_view
end

--------------------------------------------------------
--VIEW DATA SYNTHESIZATION
--------------------------------------------------------
function ENT:CreateTimeHash(str)
	self.Hash = tonumber(util.CRC(self:GetOriginal() .. CurTime())) or -1
end

function ENT:GetTimeHash()
	return self.Hash
end

function ENT:GetViewData()
	return self.ViewData
end

function ENT:SynthesizeViewData(data)
	if not data.Nodes then return end

	local viewData = {}

	viewData.Nodes = {}
	viewData.Labels = {}
	viewData.Edges = {}
	for nodeId, node in pairs(data.Nodes) do
		local gate = getGate(node)

		if not gate then
			--special case, label
			if node.type == "editor" and node.visual == "label" then
				table.insert(viewData.Labels, {
					x = math.Round(node.x),
					y = math.Round(node.y),
					t = node.value
				})
			end
			continue
		end

		local ports
		if gate.outputs then
			ports = math.max(#gate.inputs, #gate.outputs)
		else
			ports = #gate.inputs
		end

		table.insert(viewData.Nodes, {
			x = math.Round(node.x),
			y = math.Round(node.y),
			s = ports
		})

		for inputNum, connection in pairs(node.connections) do
			local fromNodeId = connection[1]
			local fromNode = data.Nodes[fromNodeId]
			local outputNum = connection[2]

			local edgeData = {
				sX = math.Round(fromNode.x + FPGANodeSize),
				sY = math.Round(fromNode.y + (outputNum - 0.5) * FPGANodeSize),
				eX = math.Round(node.x),
				eY = math.Round(node.y + (inputNum - 0.5) * FPGANodeSize),
				t = FPGATypeEnum[getInputType(gate, inputNum)]
			}

			-- Add waypoints if they exist
			if connection.waypoints and #connection.waypoints > 0 then
				edgeData.w = {}
				for _, wp in ipairs(connection.waypoints) do
					table.insert(edgeData.w, {math.Round(wp[1] + FPGANodeSize / 2), math.Round(wp[2] + FPGANodeSize / 2)})
				end
			end

			table.insert(viewData.Edges, edgeData)
		end
	end

	self.ViewData = WireLib.von.serialize(viewData)
end


--------------------------------------------------------
--VALIDATION
--------------------------------------------------------
function ENT:ValidateData(data)
	--Check if nodes are even there
	if not data.Nodes then return "missing nodes" end

	--Check that gates exist
	--Check if gate is banned
	--Check that there are no duplicate input names, or duplicate output names
	local connections = {} --Make connection table for later use
	local inputNames = {}
	local outputNames = {}
	for nodeId, node in pairs(data.Nodes) do
		local gate = getGate(node)

		if node.visual then continue end
		if gate == nil then return "invalid gate" end
		if gate.is_banned then return "banned gate" end

		if gate.isInput then
			if not node.ioName then return "missing input name" end
			if inputNames[node.ioName] then return "duplicate input name" end
			if node.ioName == "Trigger" then return "'Trigger' input name is reserved" end
			inputNames[node.ioName] = true
		elseif gate.isOutput then
			if not node.ioName then return "missing output name" end
			if outputNames[node.ioName] then return "duplicate output name" end
			outputNames[node.ioName] = true
		end

		connections[nodeId] = node.connections
	end

	--Check for out of bounds input/output
	--Type Check
	--Check that connections are valid (that the destination node exists)
	for nodeId, nodeConnections in pairs(connections) do
		local inGate = getGate(data.Nodes[nodeId])

		for inputNum, connection in pairs(nodeConnections) do
			local outNode = data.Nodes[connection[1]]
			if not outNode then return "connection exists to invalid node" end
			local outGate = getGate(outNode)
			local outputNum = connection[2]

			--bound check
			if inputNum < 1 or inputNum > #inGate.inputs then return "connection on nonexistant input" end
			if outGate.outputs then
				if connection[2] < 1 or connection[2] > #outGate.outputs then return "connection on nonexistant output" end
			else
				if connection[2] != 1 then return "connection on nonexistant output" end
			end

			--type check
			if getInputType(inGate, inputNum) != getOutputType(outGate, outputNum) then
				return "type mismatch between input and output " .. inGate.name .. " ["..getInputType(inGate, inputNum).."]" .. " and " .. outGate.name .. " ["..getOutputType(outGate, outputNum).."]"
			end
		end
	end

	--no errors
	return nil
end

--------------------------------------------------------
--COMPILATION
--------------------------------------------------------
-- Node 'compiler'
-- Flip connections, generate input output tabels
function ENT:CompileData(data)
	--Make node table and connection table [from][output] = {to, input}
	local nodes = {}
	local edges = {}
	local inputs = {}
	local inputTypes = {}
	local outputs = {}
	local outputTypes = {}
	local inputIds = {}
	local outputIds = {}
	local nodeGetsInputFrom = {}
	local timedNodes = {}
	local neverActiveNodes = {}
	local postCycleNodes = {}
	local postExecutionNodes = {}

	for nodeId, node in pairs(data.Nodes) do
		if node.visual then continue end

		nodes[nodeId] = {
			type = node.type,
			gate = node.gate,
			ioName = node.ioName,
			value = node.value,
		}
		for input, connection in pairs(node.connections) do
			fromNode = connection[1]
			fromOutput = connection[2]
			if not edges[fromNode] then edges[fromNode] = {} end
			if not edges[fromNode][fromOutput] then edges[fromNode][fromOutput] = {} end

			table.insert(edges[fromNode][fromOutput], {nodeId, input})
		end

		nodeGetsInputFrom[nodeId] = node.connections

		--get gate
		local gate = getGate(node)

		--timed
		if gate.timed then table.insert(timedNodes, nodeId) end

		--never active
		if gate.neverActive then neverActiveNodes[nodeId] = nodes[nodeId] end

		--postcycle
		if gate.postCycle then postCycleNodes[nodeId] = nodes[nodeId] end

		--postexecution
		if gate.postExecution then postExecutionNodes[nodeId] = nodes[nodeId] end

		--io
		if node.type == "fpga" then
			if gate.isInput then
				inputIds[node.ioName] = nodeId
				table.insert(inputs, node.ioName)
				table.insert(inputTypes, gate.outputtypes[1])
			end
			if gate.isOutput then
				outputIds[node.ioName] = nodeId
				table.insert(outputs, node.ioName)
				table.insert(outputTypes, gate.inputtypes[1])
			end
		end
	end

	--Integrate connection table into node table
	for nodeId, node in pairs(nodes) do
		nodes[nodeId].connections = edges[nodeId]
	end

	self.Nodes = nodes
	self.InputNames = inputs
	self.InputTypes = inputTypes
	self.InputIds = inputIds
	self.OutputNames = outputs
	self.OutputTypes = outputTypes
	self.OutputIds = outputIds

	self.NodeGetsInputFrom = nodeGetsInputFrom
	self.TimedNodes = timedNodes

	self.NeverActiveNodes = neverActiveNodes
	self.PostCycleNodes = postCycleNodes
	self.PostExecutionNodes = postExecutionNodes

	self.QueuedNodes = {}
	self.LazyQueuedNodes = {}
end

--------------------------------------------------------
--UPLOAD
--------------------------------------------------------
function ENT:Upload(data)
	self.Uploaded = false
	self.CompileError = false
	self.ExecutionError = false
	self.ErrorMessage = nil

	--Name
	if data.Name then
		self.name = data.Name
	else
		self.name = "(corrupt)"
	end
	--Execution interval
	if data.ExecutionInterval then
		self.ExecutionInterval = math.max(data.ExecutionInterval, 0.001)
	else
		self.ExecutionInterval = 0.1
	end
	--Executes on
	if data.ExecuteOn then
		self.ExecuteOnInputs = data.ExecuteOn.Inputs
		self.ExecuteOnTimed = data.ExecuteOn.Timed
		self.ExecuteOnTrigger = data.ExecuteOn.Trigger
	else
		self.ExecuteOnInputs = true
		self.ExecuteOnTimed = true
		self.ExecuteOnTrigger = false
	end

	self:UpdateOverlay(false)

	--validate
	local invalid = self:ValidateData(data)
	if invalid then
		self:ThrowCompileError("failed to validate on server, "..invalid, "failed to validate")
		self.Inputs = WireLib.AdjustSpecialInputs(self, {}, {}, "")
		self.Outputs = WireLib.AdjustSpecialOutputs(self, {}, {}, "")
		return
	end

	--view data
	self:SynthesizeViewData(data)

	--hash
	self:CreateTimeHash(data)

	--Compile
	self:CompileData(data)

	if self.ExecuteOnTrigger then
		local modifiedInputNames = {"Trigger"}
		local modifiedInputTypes = {"NORMAL"}
		for _, name in pairs(self.InputNames) do
			table.insert(modifiedInputNames, name)
		end
		for _, type in pairs(self.InputTypes) do
			table.insert(modifiedInputTypes, type)
		end
		self.Inputs = WireLib.AdjustSpecialInputs(self, modifiedInputNames, modifiedInputTypes, "")
	else
		self.Inputs = WireLib.AdjustSpecialInputs(self, self.InputNames, self.InputTypes, "")
	end
	self.Outputs = WireLib.AdjustSpecialOutputs(self, self.OutputNames, self.OutputTypes, "")

	--Initialize inputs to default values
	self.InputValues = {}
	for k, iname in pairs(self.InputNames) do
		local inputNodeId = self.InputIds[iname]
		local value = self.Inputs[iname].Value
		self.InputValues[inputNodeId] = value
	end

	self.Data = data

	self.Uploaded = true

	self:Reset()
end



--------------------------------------------------------
--RESET
--------------------------------------------------------
function ENT:ResetGates()
	--Set gates to default values again
	self.Values = {}
	for nodeId, node in pairs(self.Nodes) do
		self.Values[nodeId] = getDefaultValues(node)
	end

	--Functions for gates
	local owner = self:GetPlayer()
	local getOwner = function () return owner end
	local ent = self
	local getSelf = function () return ent end
	local getExecutionDelta = function () return ent.CurrentExecution - ent.LastExecution end
	local getExecutionCount = function () return ent.ExecutionCount end
	--Reset gate table
	self.Gates = {}
	for nodeId, node in pairs(self.Nodes) do
		local gate = getGate(node)

		local tempGate = {}
		tempGate.GetPlayer = getOwner
		if gate.specialFunctions then
			tempGate.GetSelf = getSelf
			tempGate.GetExecutionDelta = getExecutionDelta
			tempGate.GetExecutionCount = getExecutionCount
		end
		if gate.reset then
			gate.reset(tempGate)
		end
		self.Gates[nodeId] = tempGate
	end
end

function ENT:Reset()
	if self.CompilationError or not self.Uploaded then return end
	self:SetColor(Color(255, 255, 255, self:GetColor().a))
	self.ExecutionError = false
	self.ErrorMessage = nil
	self.time = 0
	self.timebench = 0
	self.timepeak = 0
	self.LastTimedUpdate = 0
	self.ExecutionCount = 0
	self.QueuedNodes = {}

	self:ResetGates()

	--Run all nodes again (to properly propagate)
	local allNodes = {}
	for nodeId, node in pairs(self.Nodes) do
		table.insert(allNodes, nodeId)
	end

	self.LastExecution = SysTime()
	self:RunProtected(allNodes)
end

--------------------------------------------------------
--EXECUTION TRIGGERING
--------------------------------------------------------
function ENT:TriggerInput(iname, value)
	if self.CompilationError or self.ExecutionError or not self.Uploaded then return end

	if iname == "Trigger" then
		if value != 0 then self:RunProtected({}) end
		return
	end

	local nodeId = self.InputIds[iname]
	self.InputValues[nodeId] = value

	if self.ExecuteOnInputs then
		self:RunProtected({nodeId})
	else
		self.LazyQueuedNodes[nodeId] = true
	end
end

function ENT:Think()
	BaseClass.Think(self)

	if not self.Uploaded then return end
	if self.CompilationError or self.ExecutionError then
		self:UpdateOverlay(false)
		return
	end
	self:NextThink(CurTime())

	--Get options (maybe do this less frequently)
	self:GetOptions()

	--Time benchmarking
	self.timebench = self.timebench * 0.98 + self.time * 0.02
	self.time = 0

	--Limiting
	if self.timebench > fpga_quota_avg then
		self:ThrowExecutionError("exceeded cpu time limit", "cpu time limit exceeded")
		return
	elseif fpga_quota_spike > 0 and self.time > fpga_quota_spike then
		self:ThrowExecutionError("exceeded spike cpu time limit", "spike cpu time limit exceeded")
		return
	end

	--postexecution hook
	for nodeId, node in pairs(self.PostExecutionNodes) do
		local gate = getGate(node)
		if gate.postExecution(self.Gates[nodeId]) then
			self.QueuedNodes[nodeId] = true
		end
		if node.connections then
			local value = self:CalculateNode(node, nodeId, gate)
			self:Propagate(node, value)
		end
	end

	--Update timed gates (and queued nodes)
	local nodesToRun = {}
	if not table.IsEmpty(self.TimedNodes) and SysTime() >= self.LastTimedUpdate + self.ExecutionInterval then
		self.LastTimedUpdate = SysTime()
		for _, nodeId in pairs(self.TimedNodes) do
			if self.ExecuteOnTimed then
				table.insert(nodesToRun, nodeId)
			else
				self.LazyQueuedNodes[nodeId] = true
			end
		end
	end

	--Run queued nodes immediately
	for nodeId, _ in pairs(self.QueuedNodes) do
		table.insert(nodesToRun, nodeId)
	end
	self.QueuedNodes = {}

	if #nodesToRun > 0 then self:RunProtected(nodesToRun) end

	self:UpdateOverlay(false)
	return true
end

--------------------------------------------------------
--RUNNING
--------------------------------------------------------
function ENT:RunProtected(changedNodes)
	local ok = pcall(self.Run, self, changedNodes)

	if not ok then
		local gate = getGate(FPGANodeCurrentlyInQueue)
		self:ThrowExecutionError("runtime error at gate " .. gate.name, "runtime error")
	end
end

FPGANodeCurrentlyInQueue = nil
function ENT:Run(changedNodes)
	if self.Debug then print("\n================================================================================") end

	--Extra
	self.ExecutionCount =  self.ExecutionCount + 1
	local bench = SysTime()
	self.CurrentExecution = bench

	--Lazy queued nodes are nodes that need to run
	--but can wait until the next execution
	if not table.IsEmpty(self.LazyQueuedNodes) then
		for nodeId, _ in pairs(self.LazyQueuedNodes) do
			table.insert(changedNodes, nodeId)
		end

		self.LazyQueuedNodes = {}
	end

	-----------------------------------------
	--PREPARATION
	-----------------------------------------
	local activeNodes = {}
	local activeNodesQueue = {}
	local nodesInQueue = {}
	local nodeQueue = {}

	--Find out which nodes will be visited
	for nodeId, node in pairs(self.Nodes) do
		activeNodes[nodeId] = false
	end
	for k, id in pairs(changedNodes) do
		table.insert(activeNodesQueue, id)
		activeNodes[id] = true
	end
	while #activeNodesQueue > 0 do
		local nodeId = table.remove(activeNodesQueue, 1)
		local node = self.Nodes[nodeId]
		--propergate output value to inputs
		if node.connections then
			for outputNum, connections in pairs(node.connections) do
				for k, connection in pairs(connections) do
					--add connected nodes to queue (and active nodes)
					if activeNodes[connection[1]] == false then
						table.insert(activeNodesQueue, connection[1])
						activeNodes[connection[1]] = true
					end
				end
			end
		end
	end
	for nodeId, active in pairs(activeNodes) do
		local gate = getGate(self.Nodes[nodeId])
		if active and gate.neverActive then
			activeNodes[nodeId] = false
		end
		if gate.alwaysActive then
			activeNodes[nodeId] = true
			table.insert(nodeQueue, nodeId)
			nodesInQueue[nodeId] = true
		end
	end

	if self.Debug then print(table.ToString(activeNodes, "activeNodes", false)) end

	--Initialize nodesInQueue set
	for nodeId, node in pairs(self.Nodes) do
		nodesInQueue[nodeId] = false
	end

	--Initialize nodeQueue with changed inputs
	for k, id in pairs(changedNodes) do
		table.insert(nodeQueue, id)
		nodesInQueue[id] = true
	end

	--Initialize nodesVisited set
	local nodesVisited = {}

	if self.Debug then
		for nodeId, node in pairs(self.Nodes) do
			print(nodeId .. table.ToString(node, "", false))
		end
	end

	-----------------------------------------
	--EXECUTION
	-----------------------------------------
	local loopCount = 0
	local loopDetectionNodeId = nil
	local loopDetectionSize = 0
	while #nodeQueue > 0 do
		loopCount = loopCount + 1
		if loopCount > 50000 then
			self.timepeak = SysTime() - bench
			self.timebench = self.timepeak
			self:ThrowExecutionError("stuck in loop for too long", "stuck in loop")
			return
		end
		if self.Debug then
			print()
			print(table.ToString(nodeQueue, "nodeQueue", false))
			print(table.ToString(nodesInQueue, "nodesInQueue", false))
			print(table.ToString(nodesVisited, "nodesVisited", false))
		end

		local nodeId = table.remove(nodeQueue, 1)
		local node = self.Nodes[nodeId]
		FPGANodeCurrentlyInQueue = node

		--get gate
		local gate = getGate(node)

		--gate value logic
		local value

		if gate.isInput then
			value = {self.InputValues[nodeId]}
			loopDetectionNodeId = nil
		elseif gate.isConstant then
			if gate.outputtypes[1] == "STRING" then
				value = { WireLib.ParseEscapes(node.value) }
			else
				value = {node.value}
			end
			loopDetectionNodeId = nil
		else
			if nodeId == loopDetectionNodeId and #nodeQueue == loopDetectionSize then
				--infinite loop...
				self:ThrowExecutionError("stuck in infinite loop", "infinite loop")
				break
			end

			--neverActive gates don't wait for their input gates to finish
			--if !gate.neverActive then
				local executeLater = false
				--if input hasnt arrived, send this node to the back of the queue
				for inputId, connection in pairs(self.NodeGetsInputFrom[nodeId]) do
					nodeId2 = connection[1]
					outputNum = connection[2]

					--if node hasnt been visited yet and its going to be visited
					if not nodesVisited[nodeId2] and activeNodes[nodeId2] then
						executeLater = true
						if loopDetectionNodeId == nil then
							loopDetectionNodeId = nodeId
							loopDetectionSize = #nodeQueue
						end
						break
					end
				end
				--skip node
				if executeLater then
					--add connected nodes to queue
					if node.connections then
						for outputNum, connections in pairs(node.connections) do
							for k, connection in pairs(connections) do
								if nodesInQueue[connection[1]] == false then
									table.insert(nodeQueue, connection[1])
									nodesInQueue[connection[1]] = true
								end
							end
						end
					end
					-- send this node to the back of the queue (potential infinite looping???)
					table.insert(nodeQueue, nodeId)
					continue
				end
			--end

			if self.Debug then print(table.ToString(self.Values[nodeId], "", false)) end

			loopDetectionNodeId = nil

			--output logic
			if gate.isOutput then
				if self.Debug then print(node.ioName .. " outputs " .. table.ToString(self.Values[nodeId], "", false)) end
				WireLib.TriggerOutput(self, node.ioName, self.Values[nodeId][1])
				continue
			else
				value = self:CalculateNode(node, nodeId, gate)
			end
		end

		if self.Debug then print(table.ToString(value, "output", false)) end

		--for future reference, we've visited this node
		nodesVisited[nodeId] = true

		self:PropagateAndAddToQueue(node, value, nodeQueue, nodesInQueue)
	end

	--postcycle hook
	for nodeId, node in pairs(self.PostCycleNodes) do
		local gate = getGate(node)
		gate.postCycle(self.Gates[nodeId])
		local value = self:CalculateNode(node, nodeId, gate)
		self:Propagate(node, value)
	end

	--keep track of time spent this tick
	self.LastExecution = bench
	self.time = self.time + (SysTime() - bench)
	self.timepeak = SysTime() - bench
end


function ENT:CalculateNode(node, nodeId, gate)
	local value
	--compact gates only calculate with connected inputs
	if gate.compact_inputs then
		--find connected inputs, and assign current values
		activeValues = {}
		for inputNum, _ in pairs(self.Data.Nodes[nodeId].connections) do
			table.insert(activeValues, self.Values[nodeId][inputNum])
		end

		value = {gate.output(self.Gates[nodeId], unpack(activeValues))}
	else
		--normal gates
		value = {gate.output(self.Gates[nodeId], unpack(self.Values[nodeId]))}
	end

	--Error correction - for dumb designed gates... (entity owner gate)
	if #value == 0 then value = getDefaultValues(node) end

	return value
end

function ENT:Propagate(node, value)
	if node.connections then
		for outputNum, connections in pairs(node.connections) do
			for k, connection in pairs(connections) do
				toNode = connection[1]
				toInput = connection[2]

				--send values to nodes
				self.Values[toNode][toInput] = value[outputNum]
			end
		end
	end
end

function ENT:PropagateAndAddToQueue(node, value, nodeQueue, nodesInQueue)
	if node.connections then
		for outputNum, connections in pairs(node.connections) do
			for k, connection in pairs(connections) do
				toNode = connection[1]
				toInput = connection[2]

				--send values to nodes
				self.Values[toNode][toInput] = value[outputNum]

				--add connected nodes to queue
				if nodesInQueue[connection[1]] == false then
					table.insert(nodeQueue, connection[1])
					nodesInQueue[connection[1]] = true
				end
			end
		end
	end
end