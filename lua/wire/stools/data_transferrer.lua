WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "data_transferrer", "Transferrer", "gmod_wire_data_transferrer", nil, "Transferrers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_data_transferrer.name", "Data Transferrer Tool (Wire)" )
	language.Add( "Tool.wire_data_transferrer.desc", "Spawns a data transferrer." )
	language.Add( "WireDataTransferrerTool_data_transferrer", "Data Transferrer:" )
	language.Add( "WireDataTransferrerTool_Range", "Max Range:" )
	language.Add( "WireDataTransferrerTool_DefaultZero","Default To Zero")
	language.Add( "WireDataTransferrerTool_IgnoreZero","Ignore Zero")
	language.Add( "WireDataTransferrerTool_Model", "Choose a Model:")
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
	WireToolHelpers.MakePresetControl(panel, "wire_data_transferrer")
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_data_transferrer")

	panel:NumSlider("#WireDataTransferrerTool_Range", "wire_data_transferrer_Range", 1, 30000, 0)
	panel:CheckBox("#WireDataTransferrerTool_DefaultZero", "wire_data_transferrer_DefaultZero")
	panel:CheckBox("#WireDataTransferrerTool_IgnoreZero", "wire_data_transferrer_IgnoreZero")
end
