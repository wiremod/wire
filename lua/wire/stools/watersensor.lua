WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "watersensor", "Water Sensor", "gmod_wire_watersensor", nil, "Water Sensors" )

if CLIENT then
	language.Add( "Tool.wire_watersensor.name", "Water Sensor Tool (Wire)" )
	language.Add( "Tool.wire_watersensor.desc", "Spawns a constant Water Sensor prop for use with the wire system." )
	language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/water.png")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	model = "models/beer/wiremod/watersensor.mdl",
	modelsize = "",
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSizer(panel, "wire_watersensor_modelsize")
	ModelPlug_AddToCPanel(panel, "WaterSensor", "wire_watersensor")
end
