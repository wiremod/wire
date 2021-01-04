AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

DEFINE_BASECLASS("base_wire_entity")


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
  
	self.Inputs = WireLib.CreateInputs(self, {})
  self.Outputs = WireLib.CreateOutputs(self, {})
  
  self.Gates = {}

  self.InputIds = {}
  self.OutputIds = {}

	self:UpdateOverlay(true)
	--self:SetColor(Color(255, 0, 0, self:GetColor().a))
end


function ENT:Upload(data)
  MsgC(Color(0, 255, 100), "Uploading to FPGA\n")
  
  self.name = data.Name
  self.timebench = 0
  self:UpdateOverlay(false)

  self.Inputs = WireLib.AdjustSpecialInputs(self, data.Inputs, data.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, data.Outputs, data.OutputTypes, "")

  self.InputIds = data.InputIds
  self.OutputIds = data.OutputIds

  self.Nodes = data.Nodes
  --Initialize gate table
  self.Gates = {}
  for nodeId, node in pairs(data.Nodes) do
    self.Gates[nodeId] = {}
    --reset gate
  end

  --Initialize inputs to default values
  self.InputValues = {}
  for k, iname in pairs(data.Inputs) do
    self.InputValues[self.InputIds[iname]] = self.Inputs[iname].Value
  end

  print(table.ToString(data, "data", true))

  self:Run(data.InputIds)
end

function ENT:Reset()
  MsgC(Color(0, 100, 255), "Resetting FPGA\n")
end

function ENT:TriggerInput(iname, value)
  print("Set input " .. iname .. " to " .. value)

  self.InputValues[self.InputIds[iname]] = value
  self:Run({self.InputIds[iname]})
end


-- function ENT:Think()

-- 	self:NextThink(CurTime())
-- 	return true
-- end

local function getGate(node)
  if node.type == "wire" then 
    return GateActions[node.gate]
  elseif node.type == "fpga" then
    return FPGAGateActions[node.gate]
  end
end


function ENT:Run(changedInputs)
  local nodeQueue = {}
  local i = 1
  for k, id in pairs(changedInputs) do
    nodeQueue[i] = id
    i = i + 1
  end

  --print(table.ToString(changedInputs, "debug", true))

  local values = {}
  
  while not table.IsEmpty(nodeQueue) do
    local nodeId = table.remove(nodeQueue, 1)
    local node = self.Nodes[nodeId]

    --add connected nodes to queue
    if node.connections then
      for k, connection in pairs(node.connections[1]) do
        --check if already in queue, only add if it isnt (Set)
        table.insert(nodeQueue, connection[1])
      end
    end

    local gate = getGate(node)

    if gate.isOutput then
      WireLib.TriggerOutput(self, "Out", values[nodeId][1])
      continue
    end

    if gate.isInput then
      value = self.InputValues[nodeId]
    else
      value = gate.output(self.Gates[nodeId], unpack(values[nodeId]))
    end

    if node.connections then
      for k, connection in pairs(node.connections[1]) do
        toNode = connection[1]
        toInput = connection[2]
        if not values[toNode] then values[toNode] = {} end
        values[toNode][toInput] = value
      end
    end
  end



end