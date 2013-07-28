
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

	self.Outputs = Wire_CreateOutputs(self, { "Waypoints [ARRAY]" })

	self.waypoints = { self }
	Wire_TriggerOutput(self, "Waypoints", self.waypoints)
end


function ENT:Setup(range)
	self.Range = range
end


function ENT:GetBeaconPos(sensor)
	if ((sensor:GetPos()-self:GetPos()):Length() < self.Range) then
		sensor:SetBeacon(self:GetNextWaypoint())
	end

	return self:GetPos()
end
function ENT:GetBeaconVelocity(sensor)
	return self:GetVelocity()
end

function ENT:SetNextWaypoint(wp)
	local SavedNextWaypoint = self:GetNextWaypoint()

	if SavedNextWaypoint:IsValid() and SavedNextWaypoint ~= wp then
		self:SetNetworkedEntity("NextWaypoint", wp)

		local waypoints = self.waypoints
		for _,ent in ipairs(waypoints) do
			ent.waypoints = { ent }
		end

		for _,ent in ipairs(waypoints) do
			ent:SetNextWaypoint(ent:GetNextWaypoint())
		end

		return
	end

	self:SetNetworkedEntity("NextWaypoint", wp)

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
