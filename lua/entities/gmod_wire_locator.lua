
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Locator"

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
