TOOL.Category		= "Wire - Data"
TOOL.Name			= "Transferer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_data_transferer_name", "Data Transferer Tool (Wire)" )
    language.Add( "Tool_wire_data_transferer_desc", "Spawns a data transferer." )
    language.Add( "Tool_wire_data_transferer_0", "Primary: Create/Update data transferer" )
    language.Add( "WireDataTransfererTool_data_transferer", "Data Transferer:" )
    language.Add( "WireDataTransfererTool_Range", "Max Range:" )
    language.Add( "WireDataTransfererTool_DefaultZero","Default To Zero")
    language.Add( "WireDataTransfererTool_IgnoreZero","Ignore Zero")
    language.Add( "WireDataTransfererTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_data_transferers", "You've hit the data transferers limit!" )
	language.Add( "undone_Wire Data Transferer", "Undone Wire data transferer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_transferers', 20)
end

TOOL.ClientConVar = {
	Model       = "models/jaanus/wiretool/wiretool_siren.mdl",
	Range       = "25000",
	DefaultZero = 0,
	IgnoreZero  = 0,
}

local transmodels = {
	["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
	["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
}

cleanup.Register( "wire_data_transferers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_transferer" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_transferers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local range = self:GetClientNumber("Range")
	local defZero = (self:GetClientNumber("DefaultZero") ~= 0)
	local ignZero = (self:GetClientNumber("IgnoreZero") ~= 0)
	local model = self:GetClientInfo("Model")

	local wire_data_transferer = MakeWireTransferer( ply, trace.HitPos, Ang, model, range, defZero, ignZero )

	local min = wire_data_transferer:OBBMins()
	wire_data_transferer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_transferer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Transferer")
		undo.AddEntity( wire_data_transferer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_transferers", wire_data_transferer )
	ply:AddCleanup( "wire_data_transferers", const )

	return true
end

if (SERVER) then

	function MakeWireTransferer( pl, Pos, Ang, model, Range, DefaultZero, IgnoreZero )
		if ( !pl:CheckLimit( "wire_data_transferers" ) ) then return false end

		local wire_data_transferer = ents.Create( "gmod_wire_data_transferer" )
		if (!wire_data_transferer:IsValid()) then return false end

		wire_data_transferer:SetAngles( Ang )
		wire_data_transferer:SetPos( Pos )
		wire_data_transferer:SetModel( model )
		wire_data_transferer:Spawn()
		wire_data_transferer:Setup(Range,DefaultZero,IgnoreZero)

		wire_data_transferer:GetTable():SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    DefaultZero = DefaultZero,
		    IgnoreZero = IgnoreZero,
			pl = pl
		}
		table.Merge(wire_data_transferer:GetTable(), ttable )

		pl:AddCount( "wire_data_transferers", wire_data_transferer )

		return wire_data_transferer
	end

	duplicator.RegisterEntityClass("gmod_wire_data_transferer", MakeWireTransferer, "Pos", "Ang", "Model", "Range", "DefaultZero", "IgnoreZero")

end

function TOOL:UpdateGhostWireTransferer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_transferer" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireTransferer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_transferer_name", Description = "#Tool_wire_data_transferer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_data_transferer",

		Options = {
			Default = {
				wire_data_transferer_data_transferer = "0",
			}
		},
		CVars = {
		}
	})

	panel:AddControl( "PropSelect", { Label = "#WireDataTransfererTool_Model",
									 ConVar = "wire_data_transferer_Model",
									 Category = "Wire Data Transferer",
									 Models = transmodels } )

	panel:AddControl("Slider", {
		Label = "#WireDataTransfererTool_Range",
		Type = "Float",
		Min = "1",
		Max = "1000000",
		Command = "wire_data_transferer_Range"
	})

	panel:AddControl( "Checkbox", { Label = "#WireDataTransfererTool_DefaultZero", Command = "wire_data_transferer_DefaultZero" } )
	panel:AddControl( "Checkbox", { Label = "#WireDataTransfererTool_IgnoreZero", Command = "wire_data_transferer_IgnoreZero" } )
end

