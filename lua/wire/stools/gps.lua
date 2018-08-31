WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "gps", "GPS", "gmod_wire_gps", nil, "GPSs" )

if CLIENT then
	language.Add( "Tool.wire_gps.name", "GPS Tool (Wire)" )
	language.Add( "Tool.wire_gps.desc", "Spawns a GPS for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/world.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	ModelPlug_Register("GPS")
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/gps.mdl",
	modelsize = "",
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSizer(panel, "wire_gps_modelsize")
	ModelPlug_AddToCPanel(panel, "GPS", "wire_gps")
end
