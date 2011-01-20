TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Data Port"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool_wire_dataport_name", "Data port tool (Wire)" )
	language.Add( "Tool_wire_dataport_desc", "Spawns data port consisting of 8 ports" )
	language.Add( "Tool_wire_dataport_0", "Primary: Create/Update data ports unit" )
	language.Add( "sboxlimit_wire_dataports", "You've hit data ports limit!" )
	language.Add( "undone_wire_dataport", "Undone Data Port" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_dataports', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_dataports" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	if ( !self:GetSWEP():CheckLimit( "wire_dataports" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90

	wire_dataport = MakeWireDataPort( ply, trace.HitPos, Ang, model )
	local min = wire_dataport:OBBMins()
	wire_dataport:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_dataport, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireDataPort")
		undo.AddEntity( wire_dataport )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dataports", wire_dataport )

	return true
end

if (SERVER) then

	function MakeWireDataPort( pl, Pos, Ang, model )

		if ( !pl:CheckLimit( "wire_dataports" ) ) then return false end

		local wire_dataport = ents.Create( "gmod_wire_dataport" )
		if (!wire_dataport:IsValid()) then return false end
		wire_dataport:SetModel(model)

		wire_dataport:SetAngles( Ang )
		wire_dataport:SetPos( Pos )
		wire_dataport:Spawn()

		wire_dataport:SetPlayer(pl)

		local ttable = {
			pl = pl,
		}
		table.Merge(wire_dataport:GetTable(), ttable ) -- TODO: remove?

		pl:AddCount( "wire_dataports", wire_dataport )

		return wire_dataport

	end

	duplicator.RegisterEntityClass("gmod_wire_dataport", MakeWireDataPort, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireDataPort( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_dataport" || trace.Entity:IsPlayer()) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireDataPort( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_dataport_name", Description = "#Tool_wire_dataport_desc" })
end

