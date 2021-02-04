AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

DEFINE_BASECLASS("base_wire_entity")

--HELPERS
local function getGate(node)
  if node.type == "wire" then 
    return GateActions[node.gate]
  elseif node.type == "fpga" then
    return FPGAGateActions[node.gate]
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

DefaultValueForType = {
  NORMAL = 0,
  VECTOR2 = nil, --no
  VECTOR = Vector(0, 0, 0),
  VECTOR4 = nil, --no
  ANGLE = Angle(0, 0, 0),
  STRING = "",
  ARRAY = {},
  ENTITY = NULL,
  RANGER = nil,
  WIRELINK = nil
}

local function getDefaultValues(node)
  local gate = getGate(node)

  values = {}
  for inputNum, name in pairs(gate.inputs) do
    local type = getInputType(gate, inputNum)

    values[inputNum] = DefaultValueForType[type]
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
		self:SetOverlayData( {
							  name = self.name,
                timebench = self.timebench / (self.ExecutionInterval / FrameTime()),
                timebenchPeak = self.time,
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

  self.Uploaded = false
  self.ExecutionError = false
  self.CompileError = false
  self.ErrorMessage = nil

  self.ExecutionInterval = 0.015

  self.Data = nil

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

    if gate == nil then return "invalid gate" end
    if gate.is_banned then return "banned gate" end

    if gate.isInput then
      if not node.ioName then return "missing input name" end
      if inputNames[node.ioName] then return "duplicate input name" end
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
  nodes = {}
  edges = {}
  inputs = {}
  inputTypes = {}
  outputs = {}
  outputTypes = {}
  inputIds = {}
  outputIds = {}
  nodeGetsInputFrom = {}
  timedNodes = {}

  for nodeId, node in pairs(data.Nodes) do
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
end

--------------------------------------------------------
--UPLOAD
--------------------------------------------------------
function ENT:Upload(data)
  --MsgC(Color(0, 255, 100), "Uploading to FPGA\n")
  --print(table.ToString(data, "data", true))

  self.Uploaded = false
  self.CompileError = false
  self.ExecutionError = false
  self.ErrorMessage = nil
  self:SetColor(Color(255, 255, 255, self:GetColor().a))

  if data.Name then
    self.name = data.Name
  else
    self.name = "(corrupt)"
  end
  if data.ExecutionInterval then
    self.ExecutionInterval = math.max(data.ExecutionInterval, FrameTime())
  else
    self.ExecutionInterval = 0.1
  end
  self.time = 0
  self.timebench = 0
  self:UpdateOverlay(false)

  --validate
  local invalid = self:ValidateData(data)
  if invalid then
    self:ThrowCompileError("failed to validate on server, "..invalid, "failed to validate")
    self.Inputs = WireLib.AdjustSpecialInputs(self, {}, {}, "")
    self.Outputs = WireLib.AdjustSpecialOutputs(self, {}, {}, "")
    return
  end


  --compile
  self:CompileData(data)

  self.Inputs = WireLib.AdjustSpecialInputs(self, self.InputNames, self.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, self.OutputNames, self.OutputTypes, "")


  --Functions for gates
  local owner = self:GetPlayer()
  --Initialize gate table
  self.Gates = {}
  for nodeId, node in pairs(self.Nodes) do
    local gate = getGate(node)

    local tempGate = {}
    function tempGate:GetPlayer()
      return owner
    end
    if gate.reset then
      gate.reset(tempGate)
    end
    self.Gates[nodeId] = tempGate
  end

  --Table that contains last input values for every gate
  self.Values = {}
  for nodeId, node in pairs(self.Nodes) do
    self.Values[nodeId] = getDefaultValues(node)
  end

  --Initialize inputs to default values
  self.InputValues = {}
  for k, iname in pairs(self.InputNames) do
    local inputNodeId = self.InputIds[iname]
    local value = self.Inputs[iname].Value
    self.InputValues[inputNodeId] = value
  end

  self.Data = data

  --First execution needs to be with all nodes, to properly get all the right standby values everywhere
  local allNodes = {}
  for nodeId, node in pairs(self.Nodes) do
    table.insert(allNodes, nodeId)
  end

  self:Run(allNodes)

  self.Uploaded = true
end



--------------------------------------------------------
--RESET
--------------------------------------------------------
function ENT:Reset()
  --MsgC(Color(0, 100, 255), "Resetting FPGA\n")
  if self.CompilationError or not self.Uploaded then return end
  self:SetColor(Color(255, 255, 255, self:GetColor().a))
  self.ExecutionError = false
  self.ErrorMessage = nil
  self.time = 0

  --Set gates to default values again
  self.Values = {}
  for nodeId, node in pairs(self.Nodes) do
    self.Values[nodeId] = getDefaultValues(node)
  end

  --Functions for gates
  local owner = self:GetPlayer()
  print(owner)
  --Reset gate table
  self.Gates = {}
  for nodeId, node in pairs(self.Nodes) do
    local gate = getGate(node)

    local tempGate = {}
    function tempGate:GetPlayer()
      return owner
    end
    if gate.reset then
      gate.reset(tempGate)
    end
    self.Gates[nodeId] = tempGate
  end

  --Run all nodes again (to properly propagate)
  local allNodes = {}
  for nodeId, node in pairs(self.Nodes) do
    table.insert(allNodes, nodeId)
  end

  self:Run(allNodes)
end

--------------------------------------------------------
--EXECUTION TRIGGERING
--------------------------------------------------------
function ENT:TriggerInput(iname, value)
  if self.CompilationError or self.ExecutionError or not self.Uploaded then return end

  self.InputValues[self.InputIds[iname]] = value
  self:Run({self.InputIds[iname]})
end

function ENT:Think()
  if self.CompilationError or self.ExecutionError or not self.Uploaded then return end

  BaseClass.Think(self)
  self:NextThink(CurTime()+self.ExecutionInterval)

  --Update timed gates
  if not table.IsEmpty(self.TimedNodes) then
    self:Run(self.TimedNodes)
  end


  --Time benchmarking
  self.timebench = self.timebench * 0.95 + self.time * 0.05
  
  --Limiting
  if self.timebench > fpga_quota_avg then
    self:ThrowExecutionError("exceeded cpu time limit", "cpu time limit exceeded")
  elseif fpga_quota_spike > 0 and self.time > fpga_quota_spike then
    self:ThrowExecutionError("exceeded spike cpu time limit", "spike cpu time limit exceeded")
  end

  self:UpdateOverlay(false)
  self.time = 0
	return true
end

--------------------------------------------------------
--RUNNING
--------------------------------------------------------
function ENT:Run(changedNodes)
  --print("--------------------")

  --Extra
  local bench = SysTime()

  -----------------------------------------
  --PREPARATION
  -----------------------------------------

  --Find out which nodes will be visited
  local activeNodes = {}
  for nodeId, node in pairs(self.Nodes) do
    activeNodes[nodeId] = false
  end
  local activeNodesQueue = {}
  local i = 1
  for k, id in pairs(changedNodes) do
    activeNodesQueue[i] = id
    activeNodes[id] = true
    i = i + 1
  end
  while not table.IsEmpty(activeNodesQueue) do
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
    if active and getGate(self.Nodes[nodeId]).neverActive then 
      activeNodes[nodeId] = false
    end
  end
  --activeNodes = {0,0,0,1,1,1,1,1,1}
  if self.Debug then print(table.ToString(activeNodes, "activeNodes", false)) end

  --Initialize nodesInQueue set
  local nodesInQueue = {}
  for nodeId, node in pairs(self.Nodes) do
    nodesInQueue[nodeId] = false
  end

  --Initialize nodeQueue with changed inputs
  --todo: also add self-triggering gates
  local nodeQueue = {}
  local i = 1
  for k, id in pairs(changedNodes) do
    nodeQueue[i] = id
    nodesInQueue[id] = true
    i = i + 1
  end

  --Initialize nodesVisited set
  local nodesVisited = {}

  --nodeQueue = {changedNodes[1], ... changedNodes[n]}
  --nodesInQueue = {0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0}
  --nodesVisited = {}

  if self.Debug then 
    for nodeId, node in pairs(self.Nodes) do
      print(nodeId .. table.ToString(node, "", false))
    end
  end

  -----------------------------------------
  --EXECUTION
  -----------------------------------------
  local calculations = 0
  local loopDetectionNodeId = nil
  local loopDetectionSize = 0
  while not table.IsEmpty(nodeQueue) do
    calculations = calculations + 1
    if calculations > 50 then break end

    if self.Debug then 
      print()
      print(table.ToString(nodeQueue, "nodeQueue", false))
      print(table.ToString(nodesInQueue, "nodesInQueue", false))
      print(table.ToString(nodesVisited, "nodesVisited", false))
    end

    local nodeId = table.remove(nodeQueue, 1)
    local node = self.Nodes[nodeId]

    --print(table.ToString(node.connections, "node.connections", false))

    --get gate
    local gate = getGate(node)

    --gate value logic
    local value

    if gate.isInput then
      value = {self.InputValues[nodeId]}
    elseif gate.isConstant then
      value = {node.value}
    else
      if nodeId == loopDetectionNodeId and #nodeQueue == loopDetectionSize then
        --infinite loop...
        self:ThrowExecutionError("stuck in infinite loop", "infinite loop")
        break
      end

      --neverActive gates don't wait for their input gates to finish
      if !gate.neverActive then
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
      end

      if self.Debug then print(table.ToString(self.Values[nodeId], "", false)) end

      --output logic
      if gate.isOutput then
        WireLib.TriggerOutput(self, node.ioName, self.Values[nodeId][1])
        if self.Debug then print(node.ioName .. " outputs " .. table.ToString(self.Values[nodeId], "", false)) end
        continue
      else
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
      end
    end

    loopDetectionNodeId = nil


    if self.Debug then print(table.ToString(value, "output", false)) end

    --for future reference, we've visited this node
    nodesVisited[nodeId] = true

    --propergate output value to inputs
    if node.connections then
      for outputNum, connections in pairs(node.connections) do
        for k, connection in pairs(connections) do
          toNode = connection[1]
          toInput = connection[2]

          --multiple outputs
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

  --postcycle hook
  for nodeId, node in pairs(self.Nodes) do
    local gate = getGate(node)
    if gate.postCycle then
      gate.postCycle(self.Gates[nodeId])
    end
  end

  --keep track of time spent this tick
  self.time = self.time + (SysTime() - bench)
end