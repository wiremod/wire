AddCSLuaFile()

ENT.Base = "base_wire_entity"
ENT.PrintName = "Wire Weight"
ENT.WireDebugName = "Weight"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateInputs(self, {"Weight"})
	WireLib.CreateOutputs(self, {"Weight"})

	local phys = self:GetPhysicsObject()
	self:ShowOutput(phys:IsValid() and phys:GetMass() or 0)
end

function ENT:TriggerInput(iname, value)
	if value > 0 then
		local phys = self:GetPhysicsObject()

		if phys:IsValid() then
			value = math.Clamp(value, 0.001, 50000)
			phys:SetMass(value)
			phys:Wake()

			self:ShowOutput(value)
			WireLib.TriggerOutput(self, "Weight", value)
		end
	end
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Weight: " .. value)
end

duplicator.RegisterEntityClass("gmod_wire_weight", WireLib.MakeWireEnt, "Data")
