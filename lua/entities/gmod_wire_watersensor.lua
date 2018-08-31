AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Water Sensor"
ENT.WireDebugName 	= "Water Sensor"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, {"Out"})
end

function ENT:ShowOutput()
	self:SetOverlayText( (self:WaterLevel()>0) and "Submerged" or "Above Water" )
end

function ENT:Think()
	BaseClass.Think(self)
	if(self:WaterLevel()>0)then
		Wire_TriggerOutput(self,"Out",1)
	else
		Wire_TriggerOutput(self,"Out",0)
	end
	self:ShowOutput()
	self:NextThink(CurTime()+0.125)
end

duplicator.RegisterEntityClass("gmod_wire_watersensor", WireLib.MakeWireEnt, "Data")
