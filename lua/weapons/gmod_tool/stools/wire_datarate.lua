TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Data Transferrer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_datarate_name", "Data transferrer tool (Wire)" )
    language.Add( "Tool_wire_datarate_desc", "Spawns data transferrer. Data transferrer acts like identity gate for hi-speed and regular links, but also provides data rate of data going through it" )
    language.Add( "Tool_wire_datarate_0", "Primary: Create/Update data trasnferrer" )
	language.Add( "sboxlimit_wire_datarates", "You've hit data trasnferrers limit!" )
	language.Add( "undone_wiredatarate", "Undone Data Transferrer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_datarates', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_datarates" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_datarate" && trace.Entity.pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_datarates" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90

	wire_datarate = MakeWiredatarate( ply, trace.HitPos, Ang, model )
	local min = wire_datarate:OBBMins()
	wire_datarate:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_datarate, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wiredatarate")
		undo.AddEntity( wire_datarate )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_datarates", wire_datarate )

	return true
end

if (SERVER) then

	function MakeWiredatarate( pl, Pos, Ang, model )

		if ( !pl:CheckLimit( "wire_datarates" ) ) then return false end

		local wire_datarate = ents.Create( "gmod_wire_datarate" )
		if (!wire_datarate:IsValid()) then return false end
		wire_datarate:SetModel(model)

		wire_datarate:SetAngles( Ang )
		wire_datarate:SetPos( Pos )
		wire_datarate:Spawn()

		wire_datarate:SetPlayer(pl)

		local ttable = {
			pl = pl,
		}
		table.Merge(wire_datarate:GetTable(), ttable ) -- TODO: remove?

		pl:AddCount( "wire_datarates", wire_datarate )

		return wire_datarate

	end

	duplicator.RegisterEntityClass("gmod_wire_datarate", MakeWiredatarate, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWiredatarate( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_datarate" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWiredatarate( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_datarate_name", Description = "#Tool_wire_datarate_desc" })
end

