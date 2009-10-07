TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Gyroscope"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_gyroscope_name", "Gyroscope Tool (Wire)" )
    language.Add( "Tool_wire_gyroscope_desc", "Spawns a gyroscope for use with the wire system." )
    language.Add( "Tool_wire_gyroscope_0", "Primary: Create/Update Gyroscope" )
    language.Add( "Tool_wire_gyroscope_out180", "Output -180 to 180 instead of 0 to 360" )
	language.Add( "sboxlimit_wire_gyroscopes", "You've hit gyroscopes limit!" )
	language.Add( "undone_wiregyroscope", "Undone Wire Gyroscope" )
end

TOOL.ClientConVar[ "out180" ] = 0

if (SERVER) then
	CreateConVar('sbox_maxwire_gyroscopes', 10)
end

TOOL.Model = "models/cheeze/wires/gyroscope.mdl"

cleanup.Register( "wire_gyroscopes" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local _out180 = self:GetClientNumber( "out180" ) == 1

	// If we shot a wire_gyroscope change its "Use +/-180?" property (TheApathetic)
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gyroscope" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _out180 )
		trace.Entity.out180 = _out180
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gyroscopes" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gyroscope = MakeWireGyroscope( ply, trace.HitPos, Ang, self.Model, _out180 )

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
		wire_gyroscope:SetModel(model)
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

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_gyroscope" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireGyroscope( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gyroscope_name", Description = "#Tool_wire_gyroscope_desc" })
	panel:AddControl( "Checkbox", { Label = "#Tool_wire_gyroscope_out180", Command = "wire_gyroscope_out180" } )
end
