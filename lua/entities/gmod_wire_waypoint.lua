AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Waypoint Beacon"
ENT.WireDebugName	= "Waypoint"

function ENT:GetNextWaypoint()
	return self:GetNWEntity("NextWaypoint")
end

if CLIENT then
	local physBeamMat = Material("cable/physbeam")
	function ENT:Draw()
		BaseClass.Draw(self)

		local nextWP = self:GetNextWaypoint()
		if IsValid(nextWP) and (LocalPlayer():GetEyeTrace().Entity == self) and (EyePos():Distance(self:GetPos()) < 4096) then
			local start = self:GetPos()
			local endpos = nextWP:GetPos()
			local scroll = -3*CurTime()

			render.SetMaterial(physBeamMat)
			render.DrawBeam(start, endpos, 8, scroll, (endpos-start):Length()/10+scroll, Color(255, 255, 255, 192))
		end
	end

	return -- No more client
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Waypoints [ARRAY]" })

	self.waypoints = { self }
	Wire_TriggerOutput(self, "Waypoints", self.waypoints)
end

function ENT:Setup(range)
	self.range = range
end

function ENT:GetBeaconPos(sensor)
	if ((sensor:GetPos()-self:GetPos()):Length() < self.range) then
		sensor:LinkEnt(self:GetNextWaypoint())
	end

	return self:GetPos()
end
function ENT:GetBeaconVelocity(sensor)
	return self:GetVelocity()
end

function ENT:SetNextWaypoint(wp)
	local SavedNextWaypoint = self:GetNextWaypoint()

	if SavedNextWaypoint:IsValid() and SavedNextWaypoint ~= wp then
		self:SetNWEntity("NextWaypoint", wp)

		local waypoints = self.waypoints
		for _,ent in ipairs(waypoints) do
			ent.waypoints = { ent }
		end

		for _,ent in ipairs(waypoints) do
			ent:SetNextWaypoint(ent:GetNextWaypoint())
		end

		return
	end

	self:SetNWEntity("NextWaypoint", wp)

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

duplicator.RegisterEntityClass("gmod_wire_waypoint", WireLib.MakeWireEnt, "Data", "range")
