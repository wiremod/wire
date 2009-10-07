
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


function ENT:Setup(range)
	self.Range = range

	self:SetOverlayText("Waypoint Beacon")
end


function ENT:GetBeaconPos(sensor)
	if ((sensor:GetPos()-self.Entity:GetPos()):Length() < self.Range) then
	    sensor:SetBeacon(self:GetNextWaypoint())
	end

	return self.Entity:GetPos()
end
