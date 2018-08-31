WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "data_transferer", "Transferer", "gmod_wire_data_transferer", nil, "Transferers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_data_transferer.name", "Data Transferer Tool (Wire)" )
	language.Add( "Tool.wire_data_transferer.desc", "Spawns a data transferer." )
	language.Add( "WireDataTransfererTool_data_transferer", "Data Transferer:" )
	language.Add( "WireDataTransfererTool_Range", "Max Range:" )
	language.Add( "WireDataTransfererTool_DefaultZero","Default To Zero")
	language.Add( "WireDataTransfererTool_IgnoreZero","Ignore Zero")
	language.Add( "WireDataTransfererTool_Model", "Choose a Model:")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("Range"), self:GetClientNumber("DefaultZero") ~= 0, self:GetClientNumber("IgnoreZero") ~= 0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar = {
	Model       = "models/jaanus/wiretool/wiretool_siren.mdl",
	Range       = "25000",
	DefaultZero = 0,
	IgnoreZero  = 0,
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_data_transferer")
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_data_transferer")

	panel:NumSlider("#WireDataTransfererTool_Range", "wire_data_transferer_Range", 1, 30000, 0)
	panel:CheckBox("#WireDataTransfererTool_DefaultZero", "wire_data_transferer_DefaultZero")
	panel:CheckBox("#WireDataTransfererTool_IgnoreZero", "wire_data_transferer_IgnoreZero")
end
