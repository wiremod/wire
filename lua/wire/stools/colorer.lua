WireToolSetup.setCategory( "Render" )
WireToolSetup.open( "colorer", "Colorer", "gmod_wire_colorer", nil, "Colorers" )

if CLIENT then
    language.Add( "Tool.wire_colorer.name", "Colorer Tool (Wire)" )
    language.Add( "Tool.wire_colorer.desc", "Spawns a constant colorer prop for use with the wire system." )
    language.Add( "Tool.wire_colorer.0", "Primary: Create/Update Colorer" )
    language.Add( "WireColorerTool_colorer", "Colorer:" )
    language.Add( "WireColorerTool_outColor", "Output Color" )
    language.Add( "WireColorerTool_Range", "Max Range:" )
    language.Add( "WireColorerTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_colorers", "You've hit Colorers limit!" )
	language.Add( "undone_Wire Colorer", "Undone Wire Colorer" )
end

if SERVER then
	CreateConVar('sbox_maxwire_colorers', 20)
end

TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "outColor" ] = "0"
TOOL.ClientConVar[ "Range" ] = "2000"

cleanup.Register( "wire_colorers" )

function TOOL:LeftClick( trace )
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_colorer" then
		trace.Entity:SetBeamLength( self:GetClientNumber( "Range" ) )
		return true
	end

	if !self:GetSWEP():CheckLimit( "wire_colorers" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

    local outColor = (self:GetClientNumber( "outColor" ) ~= 0)
    local range = self:GetClientNumber( "Range" )
    local model = self:GetClientInfo( "Model" )

	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end
	local wire_colorer = MakeWireColorer( ply, trace.HitPos, Ang, model, outColor, range )

	local min = wire_colorer:OBBMins()
	wire_colorer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld( wire_colorer, trace.Entity, trace.PhysicsBone, true )

	undo.Create( "Wire Colorer" )
		undo.AddEntity( wire_colorer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_colorers", wire_colorer )
	ply:AddCleanup( "wire_colorers", const )

	return true
end

if SERVER then

	function MakeWireColorer( pl, Pos, Ang, model, outColor, Range )
		if !pl:CheckLimit( "wire_colorers" ) then return false end

		local wire_colorer = ents.Create( "gmod_wire_colorer" )
		if !IsValid(wire_colorer) then return false end

		wire_colorer:SetAngles( Ang )
		wire_colorer:SetPos( Pos )
		wire_colorer:SetModel( model )
		wire_colorer:Spawn()
		wire_colorer:Setup( outColor, Range )

		wire_colorer:SetPlayer( pl )

		local ttable = {
		    outColor = outColor,
		    Range = Range,
			pl = pl
		}
		table.Merge( wire_colorer:GetTable(), ttable )

		pl:AddCount( "wire_colorers", wire_colorer )

		return wire_colorer
	end
	duplicator.RegisterEntityClass("gmod_wire_colorer", MakeWireColorer, "Pos", "Ang", "Model", "outColor", "Range")

end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_colorer")
	WireDermaExts.ModelSelect(panel, "wire_colorer_model", list.Get( "Wire_Laser_Tools_Models" ), 1, true)
	panel:CheckBox("#WireColorerTool_outColor", "wire_colorer_outColor")
	panel:NumSlider("#WireColorerTool_Range", "wire_colorer_Range", 1, 10000, 2)
end

