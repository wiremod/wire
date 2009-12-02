
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

	self.Outputs = Wire_CreateOutputs(self, { "Waypoints [ARRAY]" })

	self.waypoints = { self.Entity }
	Wire_TriggerOutput(self, "Waypoints", self.waypoints)
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

function ENT:SetNextWaypoint(wp)
	print(self, wp)
	local SavedNextWaypoint = self:GetNextWaypoint()

	if SavedNextWaypoint:IsValid() and SavedNextWaypoint ~= wp then
		self.Entity:SetNetworkedEntity("NextWaypoint", wp)

		local waypoints = self.waypoints
		for _,ent in ipairs(waypoints) do
			ent.waypoints = { ent }
		end

		for _,ent in ipairs(waypoints) do
			ent:SetNextWaypoint(ent:GetNextWaypoint())
		end

		return
	end

	self.Entity:SetNetworkedEntity("NextWaypoint", wp)

	if table.HasValue(self.waypoints, wp) then return end

	table.Add(self.waypoints, wp.waypoints)
	for _,ent in ipairs(self.waypoints) do
		ent.waypoints = self.waypoints
		Wire_TriggerOutput(ent, "Waypoints", ent.waypoints)
	end
end

function ENT:OnRemove()
	-- empty tables on all ents from current table and update all tables

	local waypoints = self.waypoints
	for _,ent in ipairs(waypoints) do
		ent.waypoints = { ent }
	end

	for _,ent in ipairs(waypoints) do
		if ent == self or ent:GetNextWaypoint() == self then
			ent:SetNextWaypoint(NULL)
		elseif ent:IsValid() then
			ent:SetNextWaypoint(ent:GetNextWaypoint())
		end
	end
end
