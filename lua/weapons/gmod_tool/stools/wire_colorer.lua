TOOL.Category		= "Wire - Render"
TOOL.Name			= "Colorer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

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

local colormodels = {
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
	["models/jaanus/wiretool/wiretool_range.mdl"] = {}
}

cleanup.Register( "wire_colorers" )

function TOOL:LeftClick( trace )
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_colorer" and trace.Entity.pl == ply then
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

function TOOL:UpdateGhostWireColorer( ent, player )
	if !IsValid(ent) then return end

	local trace = player:GetEyeTrace()

	if !trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_colorer" then
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
	if !self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() ~= self:GetClientInfo("Model") then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireColorer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_colorer_name", Description = "#Tool_wire_colorer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_colorer",

		Options = {
			Default = {
				wire_colorer_outColor = "0",
			}
		},
		CVars = {
		  [0] = "wire_colorer_outColor"
		}
	})

	panel:AddControl( "PropSelect", { Label = "#WireColorerTool_Model",
									 ConVar = "wire_colorer_Model",
									 Category = "Wire Colorers",
									 Models = colormodels } )

	panel:AddControl("CheckBox", {
		Label = "#WireColorerTool_outColor",
		Command = "wire_colorer_outColor"
	})

	panel:AddControl("Slider", {
		Label = "#WireColorerTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_colorer_Range"
	})
end

