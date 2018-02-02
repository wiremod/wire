WireToolSetup.setCategory( "Detection/Beacon" )
WireToolSetup.open( "sensor", "Beacon Sensor", "gmod_wire_sensor", nil, "Beacon Sensors" )

if ( CLIENT ) then
	language.Add( "Tool.wire_sensor.name", "Beacon Sensor Tool (Wire)" )
	language.Add( "Tool.wire_sensor.desc", "Returns distance and/or bearing to a beacon" )
	language.Add( "WireSensorTool_outdist", "Output distance" )
	language.Add( "WireSensorTool_outbrng", "Output bearing" )
	language.Add( "WireSensorTool_xyz_mode", "Output local position, relative to beacon" )
	language.Add( "WireSensorTool_gpscord", "Output world position ('split XYZ')" )
	language.Add( "WireSensorTool_direction_vector", "Output direction Vector" )
	language.Add( "WireSensorTool_direction_normalized", "Normalize direction Vector" )
	language.Add( "WireSensorTool_target_velocity", "Output target's velocity" )
	language.Add( "WireSensorTool_velocity_normalized", "Normalize velocity" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("xyz_mode") ~= 0, self:GetClientNumber("outdist") ~= 0, self:GetClientNumber("outbrng") ~= 0,
			self:GetClientNumber("gpscord") ~= 0, self:GetClientNumber("direction_vector") ~= 0, self:GetClientNumber("direction_normalized") ~= 0,
			self:GetClientNumber("target_velocity") ~= 0, self:GetClientNumber("velocity_normalized") ~= 0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar[ "xyz_mode" ] = "0"
TOOL.ClientConVar[ "outdist" ] = "1"
TOOL.ClientConVar[ "outbrng" ] = "0"
TOOL.ClientConVar[ "gpscord" ] = "0"
TOOL.ClientConVar[ "direction_vector" ] = "0"
TOOL.ClientConVar[ "direction_normalized" ] = "0"
TOOL.ClientConVar[ "target_velocity" ] = "0"
TOOL.ClientConVar[ "velocity_normalized" ] = "0"

TOOL.Model = "models/props_lab/huladoll.mdl"

WireToolSetup.SetupLinking(true, "beacon")

function TOOL.BuildCPanel( panel )
	panel:CheckBox("#WireSensorTool_outdist", "wire_sensor_outdist")
	panel:CheckBox("#WireSensorTool_outbrng", "wire_sensor_outbrng")
	panel:CheckBox("#WireSensorTool_xyz_mode", "wire_sensor_xyz_mode")
	panel:CheckBox("#WireSensorTool_gpscord", "wire_sensor_gpscord")
	panel:CheckBox("#WireSensorTool_direction_vector", "wire_sensor_direction_vector")
	panel:CheckBox("#WireSensorTool_direction_normalized", "wire_sensor_direction_normalized")
	panel:CheckBox("#WireSensorTool_target_velocity", "wire_sensor_target_velocity")
	panel:CheckBox("#WireSensorTool_velocity_normalized", "wire_sensor_velocity_normalized")
end
