TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Gyroscope"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_gyroscope.name", "Gyroscope Tool (Wire)" )
    language.Add( "Tool.wire_gyroscope.desc", "Spawns a gyroscope for use with the wire system." )
    language.Add( "Tool.wire_gyroscope.0", "Primary: Create/Update Gyroscope" )
    language.Add( "Tool.wire_gyroscope.out180", "Output -180 to 180 instead of 0 to 360" )
	language.Add( "sboxlimit_wire_gyroscopes", "You've hit gyroscopes limit!" )
	language.Add( "undone_wiregyroscope", "Undone Wire Gyroscope" )
end


TOOL.ClientConVar = {
  model           = "models/bull/various/gyroscope.mdl",
  out180          = 0
}


TOOL.ClientConVar[ "out180" ] = 0

if (SERVER) then
	CreateConVar('sbox_maxwire_gyroscopes', 10)
end

cleanup.Register( "wire_gyroscopes" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local _out180 = self:GetClientNumber( "out180" ) == 1

	// If we shot a wire_gyroscope change its "Use +/-180?" property (TheApathetic)
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gyroscope" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _out180 )
		trace.Entity.out180 = _out180
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gyroscopes" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gyroscope = MakeWireGyroscope( ply, trace.HitPos, Ang, self:GetModel(), _out180 )

	local min = wire_gyroscope:OBBMins()
	wire_gyroscope:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_gyroscope, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGyroscope")
		undo.AddEntity( wire_gyroscope )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_gyroscopes", wire_gyroscope )

	return true
end

if (SERVER) then

	function MakeWireGyroscope( pl, Pos, Ang, model, out180, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_gyroscopes" ) ) then return false end

		local wire_gyroscope = ents.Create( "gmod_wire_gyroscope" )
		if (!wire_gyroscope:IsValid()) then return false end

		wire_gyroscope:SetAngles(Ang)
		wire_gyroscope:SetPos(Pos)
		wire_gyroscope:SetModel( Model(model or "models/bull/various/gyroscope.mdl") )
		wire_gyroscope:Spawn()

		wire_gyroscope:Setup( out180 )
		wire_gyroscope:SetPlayer(pl)

		if ( nocollide == true ) then wire_gyroscope:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl = pl,
			out180 = out180,
		}
		table.Merge(wire_gyroscope:GetTable(), ttable )

		pl:AddCount( "wire_gyroscopes", wire_gyroscope )

		return wire_gyroscope
	end

	duplicator.RegisterEntityClass("gmod_wire_gyroscope", MakeWireGyroscope, "Pos", "Ang", "Model", "out180", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireGyroscope( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end
	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end
	
	if (!trace.Entity:IsValid() and trace.Entity != nil && trace.Entity:GetClass() == "gmod_wire_gyroscope" || trace.Entity:IsPlayer()) then
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
	local model = self:GetModel()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireGyroscope( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/cheeze/wires/gyroscope.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_gyroscope.name", Description = "#Tool.wire_gyroscope.desc" })
	ModelPlug_AddToCPanel(panel, "gyroscope", "wire_gyroscope", "#ToolWireGyroscope_Model")
	panel:AddControl( "Checkbox", { Label = "#Tool_wire_gyroscope_out180", Command = "wire_gyroscope_out180" } )
end
