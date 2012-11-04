AddCSLuaFile( "detection.lua" )
WireToolSetup.setCategory( "Detection" )

do -- wire_speedometer
	WireToolSetup.open( "speedometer", "Speedometer", "gmod_wire_speedometer", WireToolMakeSpeedometer, "Speedometers" )

	if CLIENT then
		language.Add( "tool.wire_speedometer.name", "Speedometer Tool (Wire)" )
		language.Add( "tool.wire_speedometer.desc", "Spawns a speedometer for use with the wire system." )
		language.Add( "tool.wire_speedometer.0", "Primary: Create/Update Speedometer" )
		language.Add( "Tool_wire_speedometer_xyz_mode", "Split Outputs to X,Y,Z" )
		language.Add( "Tool_wire_speedometer_angvel", "Add Angular Velocity Outputs" )
		language.Add( "sboxlimit_wire_speedometers", "You've hit speedometers limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_speedometers', 10)
		
		function TOOL:GetConVars() 
			return tobool(self:GetClientNumber("xyz_mode")), tobool(self:GetClientNumber("angvel")) 
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireSpeedometer( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/jaanus/wiretool/wiretool_speed.mdl"
	TOOL.ClientConVar = {
		xyz_mode = 0,
		angvel = 0
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_speedometer.desc")
		panel:CheckBox("#Tool_wire_speedometer_xyz_mode", "wire_speedometer_xyz_mode")
		panel:CheckBox("#Tool_wire_speedometer_angvel", "wire_speedometer_AngVel")
	end
end -- wire_speedometer

do -- wire_gps
	WireToolSetup.open( "gps", "GPS", "gmod_wire_gps", nil, "GPSs" )

	if CLIENT then
		language.Add( "Tool.wire_gps.name", "GPS Tool (Wire)" )
		language.Add( "Tool.wire_gps.desc", "Spawns a GPS for use with the wire system." )
		language.Add( "Tool.wire_gps.0", "Primary: Create/Update GPS" )
		language.Add( "Tool.wire_gps.modelsize", "Model Size (if available)" )
		
		language.Add( "sboxlimit_wire_gpss", "You've hit GPS limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_gpss', 10)
		ModelPlug_Register("GPS")
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireGPS( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/beer/wiremod/gps.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		modelsize = "",
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_gps.desc")
		panel:Help("#Tool.wire_gps.modelsize")
		panel:AddControl("ListBox", {
			Label = "Model Size",
			Options = {
					["normal"] = { wire_gps_modelsize = "" },
					["mini"] = { wire_gps_modelsize = "_mini" },
					["nano"] = { wire_gps_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(panel, "GPS", "wire_gps")
	end
end -- wire_gps

do -- wire_gyroscope
	WireToolSetup.open( "gyroscope", "Gyroscope", "gmod_wire_gyroscope", nil, "Gyroscopes" )

	if CLIENT then
		language.Add( "Tool.wire_gyroscope.name", "Gyroscope Tool (Wire)" )
		language.Add( "Tool.wire_gyroscope.desc", "Spawns a gyroscope for use with the wire system." )
		language.Add( "Tool.wire_gyroscope.0", "Primary: Create/Update Gyroscope" )
		language.Add( "Tool.wire_gyroscope.out180", "Output -180 to 180 instead of 0 to 360" )
		language.Add( "sboxlimit_wire_gyroscopes", "You've hit gyroscopes limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_gyroscopes', 10)
		ModelPlug_Register("GPS")
		
		function TOOL:GetConVars() 
			return tobool(self:GetClientNumber("out180"))
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireGyroscope( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/bull/various/gyroscope.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		out180 = 0,
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_gyroscope.desc")
		ModelPlug_AddToCPanel(panel, "gyroscope", "wire_gyroscope")
		panel:CheckBox("#Tool.wire_gyroscope.out180","wire_gyroscope_out180")
	end
end -- wire_gyroscope

do
	WireToolSetup.open( "las_reciever", "Laser Pointer Receiver", "gmod_wire_las_reciever", nil, "Laser Pointer Receiver" )

	if CLIENT then
		language.Add( "Tool.wire_las_reciever.name", "Laser Receiver Tool (Wire)" )
		language.Add( "Tool.wire_las_reciever.desc", "Spawns a constant laser receiver prop for use with the wire system." )
		language.Add( "Tool.wire_las_reciever.0", "Primary: Create/Update Laser Receiver" )
		language.Add( "WireILaserRecieverTool_ilas_reciever", "Laser Receiver:" )
		language.Add( "sboxlimit_wire_las_recievers", "You've hit laser receivers limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_las_recievers', 20)
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireLaserReciever( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model =  "models/jaanus/wiretool/wiretool_range.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_las_reciever.desc")
		ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_las_reciever")
	end
end

do
	WireToolSetup.open( "watersensor", "Water Sensor", "gmod_wire_watersensor", nil, "Water Sensors" )

	if CLIENT then
		language.Add( "Tool.wire_watersensor.name", "Water Sensor Tool (Wire)" )
		language.Add( "Tool.wire_watersensor.desc", "Spawns a constant Water Sensor prop for use with the wire system." )
		language.Add( "Tool.wire_watersensor.0", "Primary: Create/Update Water Sensor" )
		language.Add( "Tool.wire_watersensor.modelsize", "Model Size (if available)" )
		language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
		language.Add( "sboxlimit_wire_watersensors", "You've hit Water Sensors limit!" )
	end
	WireToolSetup.BaseLang()

	if SERVER then
		CreateConVar('sbox_maxwire_watersensors', 10)
		ModelPlug_Register("WaterSensor")
		
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireWaterSensor( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.Model = "models/beer/wiremod/watersensor.mdl"
	TOOL.ClientConVar = {
		model = TOOL.Model,
		modelsize = "",
	}

	function TOOL.BuildCPanel(panel)
		panel:Help("#Tool.wire_watersensor.desc")
		panel:Help("#Tool.wire_watersensor.modelsize")
		panel:AddControl("ListBox", {
			Label = "Model Size",
			Options = {
					["normal"] = { wire_watersensor_modelsize = "" },
					["mini"] = { wire_watersensor_modelsize = "_mini" },
					["nano"] = { wire_watersensor_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(panel, "WaterSensor", "wire_watersensor")
	end
end
