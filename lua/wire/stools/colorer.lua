WireToolSetup.setCategory( "Visuals" )
WireToolSetup.open( "colorer", "Colorer", "gmod_wire_colorer", nil, "Colorers" )

if CLIENT then
	language.Add( "Tool.wire_colorer.name", "Colorer Tool (Wire)" )
	language.Add( "Tool.wire_colorer.desc", "Spawns a constant colorer prop for use with the wire system." )
	language.Add( "WireColorerTool_colorer", "Colorer:" )
	language.Add( "WireColorerTool_outColor", "Output Color" )
	language.Add( "WireColorerTool_Range", "Max Range:" )
	language.Add( "WireColorerTool_Model", "Choose a Model:")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/color_wheel.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "outColor" ) ~= 0, self:GetClientNumber( "range" )
	end
end

TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "outColor" ] = "0"
TOOL.ClientConVar[ "range" ] = "2000"

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_colorer")
	WireDermaExts.ModelSelect(panel, "wire_colorer_model", list.Get( "Wire_Laser_Tools_Models" ), 1, true)
	panel:CheckBox("#WireColorerTool_outColor", "wire_colorer_outColor")
	panel:NumSlider("#WireColorerTool_Range", "wire_colorer_Range", 1, 10000, 2)
end
