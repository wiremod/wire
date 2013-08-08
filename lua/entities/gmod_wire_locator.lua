AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Locator Beacon"
ENT.WireDebugName = "Locator"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
end

function ENT:GetBeaconPos(sensor)
	return self:GetPos()
end
function ENT:GetBeaconVelocity(sensor)
	return self:GetVelocity()
end

duplicator.RegisterEntityClass("gmod_wire_locator", WireLib.MakeWireEnt, "Data")
