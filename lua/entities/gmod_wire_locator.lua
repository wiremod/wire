AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Locator Beacon"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName = "Locator"

if CLIENT then return end -- No more client

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self:SetModel( MODEL )
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
