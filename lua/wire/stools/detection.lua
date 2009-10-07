AddCSLuaFile( "detection.lua" )
WireToolSetup.setCategory( "Detection" )

do -- wire_speedometer
	WireToolSetup.open( "speedometer", "Speedometer", "gmod_wire_speedometer", WireToolMakeSpeedometer )

	if CLIENT then
		language.Add( "Tool_wire_speedometer_name", "Speedometer Tool (Wire)" )
		language.Add( "Tool_wire_speedometer_desc", "Spawns a speedometer for use with the wire system." )
		language.Add( "Tool_wire_speedometer_0", "Primary: Create/Update Speedometer" )
		language.Add( "Tool_wire_speedometer_xyz_mode", "Split Outputs to X,Y,Z" )
		language.Add( "Tool_wire_speedometer_angvel", "Add Angular Velocity Outputs" )
		language.Add( "sboxlimit_wire_speedometers", "You've hit speedometers limit!" )
	end
	WireToolSetup.BaseLang("Speedometers")

	if SERVER then
		CreateConVar('sbox_maxwire_speedometers', 10)
	end

	TOOL.Model = "models/jaanus/wiretool/wiretool_speed.mdl"
	TOOL.ClientConVar = {
		xyz_mode = 0,
		angvel = 0
	}

	function TOOL.BuildCPanel(panel)
		panel:CheckBox("#Tool_wire_speedometer_xyz_mode", "wire_speedometer_xyz_mode")
		panel:CheckBox("#Tool_wire_speedometer_angvel", "wire_speedometer_AngVel")
	end
end -- wire_speedometer
