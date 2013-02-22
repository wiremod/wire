WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "extbus", "Data - Extended Bus", "gmod_wire_extbus", nil, "Extended Buss" )

if ( CLIENT ) then
	language.Add( "Tool.wire_extbus.name", "Extended bus tool (Wire)" )
	language.Add( "Tool.wire_extbus.desc", "Spawns an extended bus (programmable address bus)" )
	language.Add( "Tool.wire_extbus.0", "Primary: Create/Update extended bus" )
	language.Add( "sboxlimit_wire_extbuss", "You've hit extended buses limit!" )
	language.Add( "undone_wiredatarate", "Undone Extended Bus" )
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

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_extbus" ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_extbuss" ) ) then return false end

	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

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

	ply:AddCleanup( "wire_extbuss", wire_extbus )

	return true
end

if (SERVER) then

	function MakeWireExtBus( ply, Pos, Ang, model, Mem1st, Mem2st, Mem3st, Mem4st, Mem1sz, Mem2sz, Mem3sz, Mem4sz )

		if ( !ply:CheckLimit( "wire_extbuss" ) ) then return false end

		local wire_extbus = ents.Create( "gmod_wire_extbus" )
		if (!wire_extbus:IsValid()) then return false end
		wire_extbus:SetModel(model)

		wire_extbus:SetAngles( Ang )
		wire_extbus:SetPos( Pos )
		wire_extbus:Spawn()
		wire_extbus:SetPlayer(ply)

		local ttable = {
			ply = ply,
			model = model,
		}
		table.Merge(wire_extbus:GetTable(), ttable )

		ply:AddCount( "wire_extbuss", wire_extbus )

		return wire_extbus

	end

	duplicator.RegisterEntityClass("gmod_wire_extbus", MakeWireExtBus, "Pos", "Ang", "Model", "Mem1st", "Mem2st", "Mem3st", "Mem4st", "Mem1sz", "Mem2sz", "Mem3sz", "Mem4sz")

end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_extbus_model", list.Get("Wire_gate_Models"), 5)
end

