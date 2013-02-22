--Wire graphics tablet  by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There may be a few bits of code from the wire panel here and there as i used it as a starting point.
--Credit to whoever created the first wire screen, from which all others seem to use the lagacy clientside drawing code (this one included)

WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "graphics_tablet", "Graphics Tablet", "gmod_wire_graphics_tablet", nil, "Graphics Tablet" )

if ( CLIENT ) then
    language.Add( "Tool.wire_graphics_tablet.name", "Graphics Tablet Tool (Wire)" )
    language.Add( "Tool.wire_graphics_tablet.desc", "Spawns a graphics tablet, which outputs cursor coordinates" )
    language.Add( "Tool.wire_graphics_tablet.0", "Primary: Create/Update graphics tablet" )
	language.Add( "sboxlimit_wire_graphics_tablets", "You've hit graphics tablets limit!" )
	language.Add( "undone_wire_graphics_tablet", "Undone Wire Graphics Tablet" )
	language.Add( "Tool_wire_graphics_tablet_mode", "Output mode: -1 to 1 (ticked), 0 to 1 (unticked)" )
	language.Add( "Tool_wire_graphics_tablet_draw_background", "Draw background" )
	language.Add( "Tool_wire_graphics_tablet_createflat", "Create flat to surface" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_graphics_tablets', 20)
end

TOOL.ClientConVar = {
	model = "models/kobilica/wiremonitorbig.mdl",
	outmode = 0,
	createflat = 1,
	draw_background = 1,
	drawoutline = 1,
}

cleanup.Register( "wire_graphics_tablets" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	if ( !self:GetSWEP():CheckLimit( "wire_graphics_tablets" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo("model")
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end
	local gmode = self:GetClientNumber("outmode") ~= 0
	local CreateFlat = self:GetClientNumber("createflat") ~= 0
	local draw_background = self:GetClientNumber("draw_background") ~= 0

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_graphics_tablet") then
		trace.Entity:Setup(gmode, draw_background)
		return true
	end

	if not CreateFlat then
		Ang.pitch = Ang.pitch + 90
	end

	local wire_graphics_tablet = MakeWireGraphicsTablet(ply, trace.HitPos, Ang, model, gmode, draw_background)
	local min = wire_graphics_tablet:OBBMins()
	wire_graphics_tablet:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_graphics_tablet, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGraphicsTablet")
		undo.AddEntity( wire_graphics_tablet )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_graphics_tablets", wire_graphics_tablet )

	return true
end

if (SERVER) then
	function MakeWireGraphicsTablet( pl, Pos, Ang, model, gmode, draw_background )
		if ( !pl:CheckLimit( "wire_graphics_tablets" ) ) then return false end

		local wire_graphics_tablet = ents.Create( "gmod_wire_graphics_tablet" )
		if (!wire_graphics_tablet:IsValid()) then return false end
		wire_graphics_tablet:SetModel(model)

		wire_graphics_tablet:SetAngles( Ang )
		wire_graphics_tablet:SetPos( Pos )
		wire_graphics_tablet:Setup(gmode, draw_background)
		wire_graphics_tablet:Spawn()
		wire_graphics_tablet:SetPlayer(pl)

		local ttable = {
			pl = pl,
			model = model,
			gmode = gmode
		}
		table.Merge(wire_graphics_tablet:GetTable(), ttable )
		pl:AddCount( "wire_graphics_tablets", wire_graphics_tablet )
		return wire_graphics_tablet
	end
	duplicator.RegisterEntityClass("gmod_wire_graphics_tablet", MakeWireGraphicsTablet, "Pos", "Ang", "Model", "gmode", "draw_background")
end

function TOOL:UpdateGhostWireGraphicsTablet( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_graphics_tablet" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	if (self:GetClientNumber("createflat") == 0) then
		Ang.pitch = Ang.pitch + 90
	end

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	ent:SetNoDraw( false )
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireGraphicsTablet( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_graphics_tablet.name", Description = "#Tool.wire_graphics_tablet.desc" })

	WireDermaExts.ModelSelect(panel, "wire_graphics_tablet_model", list.Get( "WireScreenModels" ), 5) -- screen with out a GPUlip setup
	panel:CheckBox("#Tool_wire_graphics_tablet_mode", "wire_graphics_tablet_outmode")
	panel:CheckBox("#Tool_wire_graphics_tablet_draw_background", "wire_graphics_tablet_draw_background")
	panel:CheckBox("#Tool_wire_graphics_tablet_createflat", "wire_graphics_tablet_createflat")
	panel:CheckBox("#Tool_wire_graphics_tablet_drawoutline", "wire_graphics_tablet_drawoutline")
end
