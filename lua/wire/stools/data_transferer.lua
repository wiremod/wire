WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "data_transferer", "Transferer", "gmod_wire_data_transferer", nil, "Transferers" )

if ( CLIENT ) then
    language.Add( "Tool.wire_data_transferer.name", "Data Transferer Tool (Wire)" )
    language.Add( "Tool.wire_data_transferer.desc", "Spawns a data transferer." )
    language.Add( "Tool.wire_data_transferer.0", "Primary: Create/Update data transferer" )
    language.Add( "WireDataTransfererTool_data_transferer", "Data Transferer:" )
    language.Add( "WireDataTransfererTool_Range", "Max Range:" )
    language.Add( "WireDataTransfererTool_DefaultZero","Default To Zero")
    language.Add( "WireDataTransfererTool_IgnoreZero","Ignore Zero")
    language.Add( "WireDataTransfererTool_Model", "Choose a Model:")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientNumber("Range"), self:GetClientNumber("DefaultZero") ~= 0, self:GetClientNumber("IgnoreZero") ~= 0
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireTransferer( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	Model       = "models/jaanus/wiretool/wiretool_siren.mdl",
	Range       = "25000",
	DefaultZero = 0,
	IgnoreZero  = 0,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_data_transferer")
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_data_store")

	panel:NumSlider("#WireDataTransfererTool_Range", "wire_data_transferer_Range", 1, 30000, 0)
	panel:CheckBox("#WireDataTransfererTool_DefaultZero", "wire_data_transferer_DefaultZero")
	panel:CheckBox("#WireDataTransfererTool_IgnoreZero", "wire_data_transferer_IgnoreZero")
end
