
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Locator"
ENT.OverlayDelay = 0

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
end

function ENT:GetBeaconPos(sensor)
	return self.Entity:GetPos()
end

function ENT:Setup()

end
