AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Water Sensor"
ENT.WireDebugName = "Water Sensor"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	WireLib.CreateOutputs(self, { "Out" })
end

function ENT:PrepareOverlayData()
	self:SetOverlayText(self:WaterLevel() > 0 and "Submerged" or "Above Water")
end

function ENT:Think()
	BaseClass.Think(self)
	WireLib.TriggerOutput(self, "Out", self:WaterLevel() > 0 and 1 or 0)
	self:NextThink(CurTime() + 0.125)
end

duplicator.RegisterEntityClass("gmod_wire_watersensor", WireLib.MakeWireEnt, "Data")
