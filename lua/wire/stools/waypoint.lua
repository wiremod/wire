WireToolSetup.setCategory( "Detection/Beacon" )
WireToolSetup.open( "waypoint", "Waypoint", "gmod_wire_waypoint", nil, "Waypoints" )

if ( CLIENT ) then
	language.Add( "Tool.wire_waypoint.name", "Waypoint Beacon Tool (Wire)" )
	language.Add( "Tool.wire_waypoint.desc", "Spawns a waypoint beacon for use with the wire system." )
	language.Add( "WireWaypointTool_range", "Range:" )
	language.Add( "WireWaypointTool_alink", "Auto-link previous" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Create/Update " .. TOOL.Name },
		{ name = "right_0", stage = 0, text = "Link to next waypoint" },
		{ name = "reload_0", stage = 0, text = "Remove link to next waypoint" },
		{ name = "left_1", stage = 1, text = "Select waypoint to go to after this one" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	model = "models/props_lab/powerbox02d.mdl",
	range = 150,
	alink = 0,
	createflat = 1,
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("range")
	end
end

function TOOL:LeftClick(trace)
	if (not trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if (self:GetStage() == 1) then
	    self:SetStage(0)

	    if (trace.Entity:IsValid()) and (trace.Entity:GetClass() == "gmod_wire_waypoint") and (self.SrcWaypoint) and (self.SrcWaypoint:IsValid()) then
	        self.SrcWaypoint:SetNextWaypoint(trace.Entity)
	        self.SrcWaypoint = nil

	        return true
	    end

	    self.SrcWaypoint = nil

	    return
	end

	local ent = self:LeftClick_Make( trace, ply )
	if isbool(ent) then return ent end
	local ret = self:LeftClick_PostMake( ent, ply, trace )

	// Auto-link (itsbth)
	if ( self.OldWaypoint and self.OldWaypoint:IsValid() and self:GetClientNumber("alink") == 1 ) then
		self.OldWaypoint:SetNextWaypoint(ent)
	end
	self.OldWaypoint = ent

	return ret
end

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and (trace.Entity:IsValid()) and (trace.Entity:GetClass() == "gmod_wire_waypoint") then
	    self.SrcWaypoint = trace.Entity
		self:SetStage(1)

		return true
	end

	return self:LeftClick(trace)
end

function TOOL:Reload(trace)
	if self:GetStage() ~= 0 then return false end

	if (trace.Entity:IsValid()) and (trace.Entity:GetClass() == "gmod_wire_waypoint") then
		trace.Entity:SetNextWaypoint(NULL)

		return true
	end
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_waypoint")
	panel:NumSlider("#WireWaypointTool_range","wire_waypoint_range",1,2000,2)
	panel:CheckBox("#WireWaypointTool_alink","wire_waypoint_alink")
	panel:CheckBox("#Create Flat to Surface", "wire_waypoint_createflat")
end
