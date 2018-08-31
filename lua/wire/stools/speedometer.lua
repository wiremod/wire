WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "speedometer", "Speedometer", "gmod_wire_speedometer", nil, "Speedometers" )

if CLIENT then
	language.Add( "tool.wire_speedometer.name", "Speedometer Tool (Wire)" )
	language.Add( "tool.wire_speedometer.desc", "Spawns a speedometer for use with the wire system." )
	language.Add( "Tool_wire_speedometer_xyz_mode", "Split Outputs to X,Y,Z" )
	language.Add( "Tool_wire_speedometer_angvel", "Add Angular Velocity Outputs" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars()
		return tobool(self:GetClientNumber("xyz_mode")), tobool(self:GetClientNumber("angvel"))
	end
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
