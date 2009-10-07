TOOL.Category   = "Wire - Detection"
TOOL.Name       = "Ranger"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if ( CLIENT ) then
	language.Add( "Tool_wire_ranger_name", "Ranger Tool (Wire)" )
	language.Add( "Tool_wire_ranger_desc", "Spawns a ranger for use with the wire system." )
	language.Add( "Tool_wire_ranger_0", "Primary: Create/Update Ranger" )
	language.Add( "WireRangerTool_range", "Range:" )
	language.Add( "WireRangerTool_default_zero", "Default to zero" )
	language.Add( "WireRangerTool_show_beam", "Show Beam" )
	language.Add( "WireRangerTool_ignore_world", "Ignore world" )
	language.Add( "WireRangerTool_trace_water", "Hit water" )
	language.Add( "WireRangerTool_out_dist", "Output Distance" )
	language.Add( "WireRangerTool_out_pos", "Output Position" )
	language.Add( "WireRangerTool_out_vel", "Output Velocity" )
	language.Add( "WireRangerTool_out_ang", "Output Angle" )
	language.Add( "WireRangerTool_out_col", "Output Color" )
	language.Add( "WireRangerTool_out_val", "Output Value" )
	language.Add( "WireRangerTool_out_sid", "Output SteamID(number)" )
	language.Add( "WireRangerTool_out_uid", "Output UniqueID" )
	language.Add( "WireRangerTool_out_eid", "Output Entity+EntID" )
	language.Add( "WireRangerTool_out_hnrm", "Output HitNormal" )
	language.Add( "WireRangerTool_hires", "High Resolution")
	language.Add( "sboxlimit_wire_rangers", "You've hit rangers limit!" )
	language.Add( "undone_wireranger", "Undone Wire Ranger" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_rangers', 10)
end

TOOL.ClientConVar[ "range" ] = "1500"
TOOL.ClientConVar[ "default_zero" ] = "1"
TOOL.ClientConVar[ "show_beam" ] = "0"
TOOL.ClientConVar[ "ignore_world" ] = "0"
TOOL.ClientConVar[ "trace_water" ] = "0"
TOOL.ClientConVar[ "out_dist" ] = "1"
TOOL.ClientConVar[ "out_pos" ] = "0"
TOOL.ClientConVar[ "out_vel" ] = "0"
TOOL.ClientConVar[ "out_ang" ] = "0"
TOOL.ClientConVar[ "out_col" ] = "0"
TOOL.ClientConVar[ "out_val" ] = "0"
TOOL.ClientConVar[ "out_sid" ] = "0"
TOOL.ClientConVar[ "out_uid" ] = "0"
TOOL.ClientConVar[ "out_eid" ] = "0"
TOOL.ClientConVar[ "out_hnrm" ] = "0"
TOOL.ClientConVar[ "hires" ] = "0"

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_rangers" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local range        = self:GetClientNumber("range")
	local default_zero = (self:GetClientNumber("default_zero") ~= 0)
	local show_beam    = (self:GetClientNumber("show_beam") ~= 0)
	local ignore_world = (self:GetClientNumber("ignore_world") ~= 0)
	local trace_water  = (self:GetClientNumber("trace_water") ~= 0)
	local out_dist     = (self:GetClientNumber("out_dist") ~= 0)
	local out_pos      = (self:GetClientNumber("out_pos") ~= 0)
	local out_vel      = (self:GetClientNumber("out_vel") ~= 0)
	local out_ang      = (self:GetClientNumber("out_ang") ~= 0)
	local out_col      = (self:GetClientNumber("out_col") ~= 0)
	local out_val      = (self:GetClientNumber("out_val") ~= 0)
	local out_sid      = (self:GetClientNumber("out_sid") ~= 0)
	local out_uid      = (self:GetClientNumber("out_uid") ~= 0)
	local out_eid      = (self:GetClientNumber("out_eid") ~= 0)
	local out_hnrm     = (self:GetClientNumber("out_hnrm") ~= 0)
	local hires        = (self:GetClientNumber("hires") ~= 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_ranger" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid,hires )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_rangers" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_ranger = MakeWireRanger( ply, trace.HitPos, Ang, self.Model, range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm )

	local min = wire_ranger:OBBMins()
	wire_ranger:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_ranger, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireRanger")
		undo.AddEntity( wire_ranger )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_rangers", wire_ranger )

	return true
end

if (SERVER) then

	function MakeWireRanger( pl, Pos, Ang, model, range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hires, nocollide )
		if ( !pl:CheckLimit( "wire_rangers" ) ) then return false end

		local wire_ranger = ents.Create( "gmod_wire_ranger" )
		if (!wire_ranger:IsValid()) then return false end

		wire_ranger:SetAngles( Ang )
		wire_ranger:SetPos( Pos )
		wire_ranger:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
		wire_ranger:Spawn()

		wire_ranger:Setup( range, default_zero, show_beam, ignore_world, trace_water, out_dist, out_pos, out_vel, out_ang, out_col, out_val, out_sid, out_uid, out_eid, out_hnrm, hires )
		wire_ranger:SetPlayer( pl )

		if ( nocollide == true ) then wire_ranger:GetPhysicsObject():EnableCollisions( false ) end

		wire_ranger.pl	= pl
		wire_ranger.nocollide = nocollide

		pl:AddCount( "wire_rangers", wire_ranger )

		return wire_ranger
	end

	duplicator.RegisterEntityClass("gmod_wire_ranger", MakeWireRanger, "Pos", "Ang", "Model", "range", "default_zero", "show_beam", "ignore_world", "trace_water", "out_dist", "out_pos", "out_vel", "out_ang", "out_col", "out_val", "out_sid", "out_uid", "out_eid", "out_hnrm", "hires", "nocollide")

end

function TOOL:UpdateGhostWireRanger( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_ranger" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end


function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireRanger( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_ranger_name", Description = "#Tool_wire_ranger_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_ranger",

		Options = {
			Default = {
				wire_ranger_range = "20",
				wire_ranger_default_zero = "0",
			}
		},

		CVars = {
			[0] = "wire_ranger_range",
			[1] = "wire_ranger_default_zero"
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireRangerTool_range",
		Type = "Float",
		Min = "1",
		Max = "1000",
		Command = "wire_ranger_range"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_default_zero",
		Command = "wire_ranger_default_zero"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_show_beam",
		Command = "wire_ranger_show_beam"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_ignore_world",
		Command = "wire_ranger_ignore_world"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_trace_water",
		Command = "wire_ranger_trace_water"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_dist",
		Command = "wire_ranger_out_dist"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_pos",
		Command = "wire_ranger_out_pos"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_vel",
		Command = "wire_ranger_out_vel"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_ang",
		Command = "wire_ranger_out_ang"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_col",
		Command = "wire_ranger_out_col"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_val",
		Command = "wire_ranger_out_val"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_sid",
		Command = "wire_ranger_out_sid"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_uid",
		Command = "wire_ranger_out_uid"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_eid",
		Command = "wire_ranger_out_eid"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_out_hnrm",
		Command = "wire_ranger_out_hnrm"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireRangerTool_hires",
		Command = "wire_ranger_hires"
	})

end
