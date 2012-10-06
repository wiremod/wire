TOOL.Category       = "Wire - Advanced"
TOOL.Name           = "Data - Extended Bus"
TOOL.Command        = nil
TOOL.ConfigName     = ""
TOOL.Tab            = "Wire"

if ( CLIENT ) then
	language12.Add( "Tool_wire_extbus_name", "Extended bus tool (Wire)" )
	language12.Add( "Tool_wire_extbus_desc", "Spawns an extended bus (programmable address bus)" )
	language12.Add( "Tool_wire_extbus_0", "Primary: Create/Update extended bus" )
	language12.Add( "sboxlimit_wire_extbuss", "You've hit extended buses limit!" )
	language12.Add( "undone_wiredatarate", "Undone Extended Bus" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_extbuss', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
cleanup.Register( "wire_extbuss" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_extbus" && trace.Entity.ply == ply ) then
		return true
	end

	if (pl!=nil) then if ( !self:GetSWEP():CheckLimit( "wire_extbuss" ) ) then return false end end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90

	wire_extbus = MakeWireExtBus( ply, trace.HitPos, Ang, model)
	local min = wire_extbus:OBBMins()
	wire_extbus:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_extbus, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireExtBus")
		undo.AddEntity( wire_extbus )
		undo.SetPlayer( ply )
	undo.Finish()

	if (ply!=nil) then ply:AddCleanup( "wire_extbuss", wire_extbus ) end

	return true
end

if (SERVER) then

	function MakeWireExtBus( ply, Pos, Ang, model, Mem1st, Mem2st, Mem3st, Mem4st, Mem1sz, Mem2sz, Mem3sz, Mem4sz )

		if (ply!=nil) then if (pl!=nil) then if ( !ply:CheckLimit( "wire_extbuss" ) ) then return false end end end

		local wire_extbus = ents.Create( "gmod_wire_extbus" )
		if (!wire_extbus:IsValid()) then return false end
		wire_extbus:SetModel(model)

		wire_extbus:SetAngles( Ang )
		wire_extbus:SetPos( Pos )
		wire_extbus:Spawn()

		local ttable = {
			ply = ply,
			model = model,
		}
		table.Merge(wire_extbus:GetTable(), ttable )

		if (ply!=nil) then ply:AddCount( "wire_extbuss", wire_extbus ) end

		return wire_extbus

	end

	duplicator.RegisterEntityClass("gmod_wire_extbus", MakeWireExtBus, "Pos", "Ang", "Model", "Mem1st", "Mem2st", "Mem3st", "Mem4st", "Mem1sz", "Mem2sz", "Mem3sz", "Mem4sz")

end

function TOOL:UpdateGhostWireExtBus( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_extbus" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireExtBus( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_extbus_name", Description = "#Tool_wire_extbus_desc" })

        local modelPanel = WireDermaExts.ModelSelect(panel, "wire_extbus_model", list.Get("Wire_gate_Models"), 2)
end

