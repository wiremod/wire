WireToolSetup.setCategory( "Beacon" )
WireToolSetup.open( "waypoint", "Waypoint", "gmod_wire_waypoint", nil, "Waypoints" )

if ( CLIENT ) then
    language.Add( "Tool.wire_waypoint.name", "Waypoint Beacon Tool (Wire)" )
    language.Add( "Tool.wire_waypoint.desc", "Spawns a waypoint beacon for use with the wire system." )
    language.Add( "Tool.wire_waypoint.0", "Primary: Create/Update Waypoint Beacon, Secondary: Link to next waypoint, Reload: Remove link to next waypoint" )
    language.Add( "Tool.wire_waypoint.1", "Primary: Select waypoint to go to after this one" )
    language.Add( "WireWaypointTool_range", "Range:" )
	language.Add( "WireWaypointTool_alink", "Auto-link previous" )
	language.Add( "sboxlimit_wire_waypoints", "You've hit waypoint beacons limit!" )
	language.Add( "undone_wirewaypoint", "Undone Wire Waypoint Beacon" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_waypoints',30)
end

TOOL.ClientConVar[ "range" ] = "150"
TOOL.ClientConVar[ "alink" ] = "0"

TOOL.Model = "models/props_lab/powerbox02d.mdl"

cleanup.Register( "wire_waypoints" )

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
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

	local range = self:GetClientNumber("range")

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_waypoint" ) then
		trace.Entity:Setup(range)
		trace.Entity.range = range
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_waypoints" ) ) then return false end

	local Ang = trace.HitNormal:Angle()

	local wire_waypoint = MakeWireWaypoint( ply, trace.HitPos, Ang, self.Model, range )

	local min = wire_waypoint:OBBMins()
	wire_waypoint:SetPos( trace.HitPos - trace.HitNormal * (min.z) )

	// Auto-link (itsbth)
	if ( self.OldWaypoint && self.OldWaypoint:IsValid() and self:GetClientNumber("alink") == 1 ) then
		self.OldWaypoint:SetNextWaypoint(wire_waypoint)
	end

	self.OldWaypoint = wire_waypoint

	undo.Create("WireWaypoint")
		undo.AddEntity( wire_waypoint )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_waypoints", wire_waypoint )

	return true
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

if SERVER then

	function MakeWireWaypoint(pl, Pos, Ang, model, range )
		if (!pl:CheckLimit("wire_waypoints")) then return end

		local wire_waypoint = ents.Create("gmod_wire_waypoint")
		wire_waypoint:SetPos(Pos)
		wire_waypoint:SetAngles(Ang)
		wire_waypoint:SetModel( Model(model or "models/props_lab/powerbox02d.mdl") )
		wire_waypoint:Spawn()
		wire_waypoint:Activate()

		wire_waypoint:Setup(range)
		wire_waypoint:SetPlayer(pl)

		local ttable = {
			pl			= pl,
			range       = range,
			nocollide	= nocollide,
		}
		table.Merge( wire_waypoint:GetTable(), ttable )

		pl:AddCount( "wire_waypoints", wire_waypoint )

		return wire_waypoint
	end
	duplicator.RegisterEntityClass("gmod_wire_waypoint", MakeWireWaypoint, "Pos", "Ang", "Model", "range")
end

function TOOL.BuildCPanel(panel)
	panel:NumSlider("#WireWaypointTool_range","wire_waypoint_range",1,2000,2)
	panel:CheckBox("#WireWaypointTool_alink","wire_waypoint_alink")
end

