WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "gyroscope", "Gyroscope", "gmod_wire_gyroscope", nil, "Gyroscopes" )

if CLIENT then
	language.Add( "Tool.wire_gyroscope.name", "Gyroscope Tool (Wire)" )
	language.Add( "Tool.wire_gyroscope.desc", "Spawns a gyroscope for use with the wire system." )
	language.Add( "Tool.wire_gyroscope.out180", "Output -180 to 180 instead of 0 to 360" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	ModelPlug_Register("GPS")

	function TOOL:GetConVars()
		return self:GetClientNumber("out180")~=0
	end
end

TOOL.ClientConVar = {
	model = "models/bull/various/gyroscope.mdl",
	out180 = 0,
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gyroscope", "wire_gyroscope")
	panel:CheckBox("#Tool.wire_gyroscope.out180","wire_gyroscope_out180")
end
