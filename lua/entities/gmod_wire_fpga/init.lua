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
                timebench = self.timebench / (self.ExecutionInterval / self.TickRate),
                timebenchPeak = self.time,
                errorMessage = self.errorMessage,
							})
	end
end

function ENT:Error(message, overlay)
  self:SetColor(Color(255, 0, 0, self:GetColor().a))
  self.error = true
  self.errorMessage = overlay
  self:UpdateOverlay(false)

  WireLib.ClientError(message, WireLib.GetOwner(self))
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
  self.error = false
  self.errorMessage = nil

  self.TickRate = 0.015
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
	--self:SetColor(Color(255, 0, 0, self:GetColor().a))
end

function ENT:ValidateData(data)
  return true
end

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
  
  self.name = data.Name
  self.ExecutionInterval = math.max(data.ExecutionInterval, self.TickRate)
  self.time = 0
  self.timebench = 0
  self:UpdateOverlay(false)

  --validate
  local valid = self:ValidateData(data)
  if not valid then
    self:Error("FPGA: Failed to validate on server", "Failed to validate")
    self.Inputs = WireLib.AdjustSpecialInputs(self, {}, {}, "")
    self.Outputs = WireLib.AdjustSpecialOutputs(self, {}, {}, "")
    return
  end


  --compile
  self:CompileData(data)

  self.Inputs = WireLib.AdjustSpecialInputs(self, self.InputNames, self.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, self.OutputNames, self.OutputTypes, "")

  --Initialize gate table
  self.Gates = {}
  for nodeId, node in pairs(self.Nodes) do
    local gate = getGate(node)

    if gate.reset then
      --reset gate
      local tempGate = {}
      gate.reset(tempGate)
      self.Gates[nodeId] = tempGate
    else
      --empty gate
      self.Gates[nodeId] = {}
    end
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
end

--------------------------------------------------------
--RESET
--------------------------------------------------------
function ENT:Reset()
  --MsgC(Color(0, 100, 255), "Resetting FPGA\n")
  if self.error then return end

  --Set gates to default values again
  self.Values = {}
  for nodeId, node in pairs(self.Nodes) do
    self.Values[nodeId] = getDefaultValues(node)
  end

  --Reset gate table
  self.Gates = {}
  for nodeId, node in pairs(self.Nodes) do
    local gate = getGate(node)

    if gate.reset then
      --reset gate
      local tempGate = {}
      gate.reset(tempGate)
      self.Gates[nodeId] = tempGate
    else
      --empty gate
      self.Gates[nodeId] = {}
    end
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
  --print("Set input " .. iname .. " to " .. value)

  self.InputValues[self.InputIds[iname]] = value
  self:Run({self.InputIds[iname]})
end

function ENT:Think()
  if self.error then return end

  BaseClass.Think(self)
  self:NextThink(CurTime()+self.ExecutionInterval)

  --Update timed gates
  if not table.IsEmpty(self.TimedNodes) then
    self:Run(self.TimedNodes)
  end


  --Time benchmarking
  self.timebench = self.timebench * 0.95 + self.time * 0.05
  
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
    --if self.Nodes[id].neverActive then continue end
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
    if gate.isInput then
      value = {self.InputValues[nodeId]}
    elseif gate.isConstant then
      value = {node.value}
    else
      if nodeId == loopDetectionNodeId then
        --infinite loop...
        self:Error("FPGA: Execution stuck in infinite loop", "Infinite loop")
        break
      end

      local executeLater = false
      --if input hasnt arrived, send this node to the back of the queue
      for inputId, connection in pairs(self.NodeGetsInputFrom[nodeId]) do
        nodeId2 = connection[1]
        outputNum = connection[2]

        --if node hasnt been visited yet and its going to be visited
        if not nodesVisited[nodeId2] and activeNodes[nodeId2] then
          --send this node to the back of the queue (potential infinite looping???)
          table.insert(nodeQueue, nodeId)
          executeLater = true
          if loopDetectionNodeId == nil then
            loopDetectionNodeId = nodeId
          end
          break
        end
      end
      --skip node
      if executeLater then continue end
      loopDetectionNodeId = nil

      if self.Debug then print(table.ToString(self.Values[nodeId], "", false)) end

      --output logic
      if gate.isOutput then
        WireLib.TriggerOutput(self, node.ioName, self.Values[nodeId][1])
        if self.Debug then print(node.ioName .. " outputs " .. table.ToString(self.Values[nodeId], "", false)) end
        continue
      else
        --normal gates
        value = {gate.output(self.Gates[nodeId], unpack(self.Values[nodeId]))}
      end
    end

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

  --keep track of time spent this tick
  self.time = self.time + (SysTime() - bench)
end