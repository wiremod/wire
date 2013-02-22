WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "data_store", "Store", "gmod_wire_data_store", nil, "Data Stores" )

if ( CLIENT ) then
    language.Add( "Tool.wire_data_store.name", "Data Store Tool (Wire)" )
    language.Add( "Tool.wire_data_store.desc", "Spawns a data store." )
    language.Add( "Tool.wire_data_store.0", "Primary: Create/Update data store" )
    language.Add( "WireDataStoreTool_data_store", "Data Store:" )
	language.Add( "sboxlimit_wire_data_stores", "You've hit data stores limit!" )
	language.Add( "undone_Wire Data Store", "Undone Wire data store" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_stores', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_data_stores" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_store" ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_stores" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_store = MakeWireStore( ply, trace.HitPos, Ang, self:GetModel())

	local min = wire_data_store:OBBMins()
	wire_data_store:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_store, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Store")
		undo.AddEntity( wire_data_store )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_stores", wire_data_store )
	ply:AddCleanup( "wire_data_stores", const )

	return true
end

if (SERVER) then

	function MakeWireStore( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_data_stores" ) ) then return false end

		local wire_data_store = ents.Create( "gmod_wire_data_store" )
		if (!wire_data_store:IsValid()) then return false end

		wire_data_store:SetAngles( Ang )
		wire_data_store:SetPos( Pos )
		wire_data_store:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
		wire_data_store:Spawn()

		wire_data_store:SetPlayer( pl )
		wire_data_store.pl = pl

		pl:AddCount( "wire_data_stores", wire_data_store )

		return wire_data_store
	end

	duplicator.RegisterEntityClass("gmod_wire_data_store", MakeWireStore, "Pos", "Ang", "Model")

end

function TOOL:UpdateGhostWireStore( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_store" ) then
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

	self:UpdateGhostWireStore( self.GhostEntity, self:GetOwner() )
end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_range.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_data_store_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
