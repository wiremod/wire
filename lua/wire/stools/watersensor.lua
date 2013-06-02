WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "watersensor", "Water Sensor", "gmod_wire_watersensor", nil, "Water Sensors" )

if CLIENT then
	language.Add( "Tool.wire_watersensor.name", "Water Sensor Tool (Wire)" )
	language.Add( "Tool.wire_watersensor.desc", "Spawns a constant Water Sensor prop for use with the wire system." )
	language.Add( "Tool.wire_watersensor.0", "Primary: Create/Update Water Sensor" )
	language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("WaterSensor")
	
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireWaterSensor( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/watersensor.mdl",
	modelsize = "",
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSizer(panel, "wire_watersensor_modelsize")
	ModelPlug_AddToCPanel(panel, "WaterSensor", "wire_watersensor")
end
