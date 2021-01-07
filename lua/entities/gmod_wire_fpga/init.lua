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

local function getDefaultValue(node)
  local gate = getGate(node)

  values = {}
  for inputNum, name in pairs(gate.inputs) do
    local type = getInputType(gate, inputNum)

    --default values
    local value = nil
    if type == "NORMAL" then
      value = 0
    elseif type == "VECTOR2" then
    elseif type == "VECTOR" then
      value = Vector(0, 0, 0)
    elseif type == "VECTOR4" then
    elseif type == "ANGLE" then
      value = Angle(0, 0, 0)
    elseif type == "STRING" then
      value = ""
    elseif type == "ARRAY" then
      value = {}
    elseif type == "ENTITY" then
      value = NULL
    elseif type == "RANGER" then
      value = nil
    elseif type == "WIRELINK" then
      value = nil
    end

    values[inputNum] = value
  end

  return values
end



function ENT:UpdateOverlay(clear)
	if clear then
		self:SetOverlayData( {
								name = "(none)",
								timebench = 0
							})
	else
		self:SetOverlayData( {
							  name = self.name,
								timebench = self.timebench
							})
	end
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  
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

  self.NodeGetsInputFrom = {}

	self:UpdateOverlay(true)
	--self:SetColor(Color(255, 0, 0, self:GetColor().a))
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

  for nodeId, node in pairs(data.Nodes) do
    nodes[nodeId] = {
      type = node.type,
      gate = node.gate,
      ioName = node.ioName,
    }
    for input, connection in pairs(node.connections) do
      fromNode = connection[1]
      fromOutput = connection[2]
      if not edges[fromNode] then edges[fromNode] = {} end
      if not edges[fromNode][fromOutput] then edges[fromNode][fromOutput] = {} end

      table.insert(edges[fromNode][fromOutput], {nodeId, input})
    end

    nodeGetsInputFrom[nodeId] = node.connections

    if node.type == "fpga" then
      local gate = getGate(node)

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
end


function ENT:Upload(data)
  MsgC(Color(0, 255, 100), "Uploading to FPGA\n")
  
  self.name = data.Name
  self.timebench = 0
  self:UpdateOverlay(false)

  --compile
  self:CompileData(data)

  self.Inputs = WireLib.AdjustSpecialInputs(self, self.InputNames, self.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, self.OutputNames, self.OutputTypes, "")

  --Initialize gate table
  self.Gates = {}
  for nodeId, node in pairs(self.Nodes) do
    self.Gates[nodeId] = {}
    --reset gate
  end
  --Initialize default values
  self.LastGateValues = {}
  for nodeId, node in pairs(self.Nodes) do
    self.LastGateValues[nodeId] = getDefaultValue(node)
  end

  --Initialize inputs to default values (and backup lastgatevalue table)
  self.InputValues = {}
  for k, iname in pairs(self.InputNames) do
    local inputNodeId = self.InputIds[iname]
    local value = self.Inputs[iname].Value
    self.InputValues[inputNodeId] = value
    self.LastGateValues[inputNodeId] = value
  end

  self.Data = data
  --print(table.ToString(data, "data", true))

  self:Run(self.InputIds)
end

function ENT:Reset()
  MsgC(Color(0, 100, 255), "Resetting FPGA\n")
end

function ENT:TriggerInput(iname, value)
  --print("Set input " .. iname .. " to " .. value)

  self.InputValues[self.InputIds[iname]] = value
  self:Run({self.InputIds[iname]})
end


-- function ENT:Think()

-- 	self:NextThink(CurTime())
-- 	return true
-- end


function ENT:Run(changedInputs)
  print("--------------------")

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
  for k, id in pairs(changedInputs) do
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
  print(table.ToString(activeNodes, "activeNodes", false))

  --Initialize nodesInQueue set
  local nodesInQueue = {}
  for nodeId, node in pairs(self.Nodes) do
    nodesInQueue[nodeId] = false
  end

  --Initialize nodeQueue with changed inputs
  --todo: also add self-triggering gates
  local nodeQueue = {}
  local i = 1
  for k, id in pairs(changedInputs) do
    nodeQueue[i] = id
    nodesInQueue[id] = true
    i = i + 1
  end

  --Initialize nodesVisited set
  local nodesVisited = {}

  --nodeQueue = {changedInputs[1], ... changedInputs[n]}
  --nodesInQueue = {0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0}
  --nodesVisited = {}

  local values = {}

  for nodeId, node in pairs(self.Nodes) do
    print(nodeId .. table.ToString(node, "", false))
  end

  -----------------------------------------
  --EXECUTION
  -----------------------------------------
  while not table.IsEmpty(nodeQueue) do
    print()
    print(table.ToString(nodeQueue, "nodeQueue", false))
    print(table.ToString(nodesInQueue, "nodesInQueue", false))
    print(table.ToString(nodesVisited, "nodesVisited", false))

    local nodeId = table.remove(nodeQueue, 1)
    table.insert(nodesVisited, nodeId)
    local node = self.Nodes[nodeId]

    --print(table.ToString(node.connections, "node.connections", false))

    --get gate
    local gate = getGate(node)

    --output logic
    if gate.isOutput then
      WireLib.TriggerOutput(self, node.ioName, values[nodeId][1])
      print(node.ioName .. " outputs " .. table.ToString(values[nodeId], "", false))
      continue
    end

    --gate value logic
    if gate.isInput then
      value = {self.InputValues[nodeId]}
    else
      --if input hasnt arrived, send this node to the back of the queue
      for inputId, connection in pairs(self.NodeGetsInputFrom[nodeId]) do
        if not values[nodeId][inputId] then
          nodeId2 = connection[1]
          outputNum = connection[2]

          --if node hasnt been visited yet and its going to be visited
          if not nodesVisited[nodeId2] and activeNodes[nodeId2] then
            --send this node to the back of the queue (potential infinite looping???)
            table.insert(nodeQueue, nodeId)
            continue
          else
            --if input isnt going to arrive, use older value
            values[nodeId][inputId] = self.LastGateValues[nodeId2][outputNum]
          end
        end
      end

      print(table.ToString(values[nodeId], "", false))

      value = {gate.output(self.Gates[nodeId], unpack(values[nodeId]))}
    end

    print(table.ToString(value, "output", false))

    --save value for future executions
    self.LastGateValues[nodeId] = value

    --propergate output value to inputs
    if node.connections then
      for outputNum, connections in pairs(node.connections) do
        for k, connection in pairs(connections) do
          toNode = connection[1]
          toInput = connection[2]
          if not values[toNode] then values[toNode] = {} end

          --multiple outputs
          values[toNode][toInput] = value[outputNum]

          --add connected nodes to queue
          if nodesInQueue[connection[1]] == false then
            table.insert(nodeQueue, connection[1])
            nodesInQueue[connection[1]] = true
          end
        end
      end
    end
  end



end