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

	TOOL.ClientConVar = {
		model = "models/beer/wiremod/gps.mdl",
		modelsize = "",
	}
	
	function TOOL:GetModel()
		local model = string.sub(self:GetClientInfo( "model" ), 1, -5) .. self:GetClientInfo( "modelsize" ) .. string.sub(self:GetClientInfo( "model" ), -4)
		if not self:CheckValidModel(model) then return model
		elseif not self:CheckValidModel(self:GetClientInfo( "model" )) then return self:GetClientInfo( "model" )
		else return "models/beer/wiremod/gps.mdl"
		end
	end

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
		ModelPlug_AddToCPanel(panel, "GPS", "wire_gps", "#ToolWireIndicator_Model")
	end
end -- wire_gps
