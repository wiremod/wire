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

	self.Inputs = WireLib.CreateInputs(self, {"In"})
	self.Outputs = WireLib.CreateOutputs(self, {"Out"})

	self:UpdateOverlay(true)
	--self:SetColor(Color(255, 0, 0, self:GetColor().a))
end


function ENT:Upload(data)
  MsgC(Color(0, 255, 100), "Uploading to FPGA\n")
  print(table.ToString(data, "data", true))
  self.name = data.Name
  self.timebench = 0
  self:UpdateOverlay(false)

  self.Inputs = WireLib.AdjustSpecialInputs(self, data.Inputs, data.InputTypes, "")
  self.Outputs = WireLib.AdjustSpecialOutputs(self, data.Outputs, data.OutputTypes, "")
end

function ENT:Reset()
  MsgC(Color(0, 100, 255), "Resetting FPGA\n")
end



function ENT:TriggerInput(iname, value)
  if iname == "In" then
    Wire_TriggerOutput(self, "Out", value)
  end
end


-- function ENT:Think()

-- 	self:NextThink(CurTime())
-- 	return true
-- end