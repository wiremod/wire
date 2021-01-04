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

  self.InputNames = data.Inputs
  self.Inputs = WireLib.AdjustSpecialInputs(self, data.Inputs, data.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, data.Outputs, data.OutputTypes, "")

  self.InputIds = data.InputIds
  self.OutputIds = data.OutputIds

  self.Gates = data.Nodes
  self.Values = {}
  for nodeId, node in pairs(data.Nodes) do
    self.Values[nodeId] = nil
  end

  print(table.ToString(data, "data", true))
end

function ENT:Reset()
  MsgC(Color(0, 100, 255), "Resetting FPGA\n")
end

function ENT:TriggerInput(iname, value)
  self.Values[self.InputIds[iname]] = value
  self:Run({self.InputIds[iname]})
end


-- function ENT:Think()

-- 	self:NextThink(CurTime())
-- 	return true
-- end


function ENT:Run(changedInputs)
  -- local gateQueue = {}
  -- for k, id in pairs(changedInputs) do
  --   gateQueue[k] = id
  -- end
  
  -- while not table.IsEmpty(gateQueue) do
  --   local gateId = table.remove(gateQueue, 1)
  --   local gate = self.Gates[gateId]

  --   for k, connection in pairs(gate.connections[1]) do
  --     table.insert(gateQueue, connection[1])
  --   end
    

  -- end



end