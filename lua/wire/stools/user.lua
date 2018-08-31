WireToolSetup.setCategory( "Other" )
WireToolSetup.open( "user", "User", "gmod_wire_user", nil, "Users" )

if CLIENT then
	language.Add( "Tool.wire_user.name", "User Tool (Wire)" )
	language.Add( "Tool.wire_user.desc", "Spawns a constant user prop for use with the wire system." )
	language.Add( "Tool.wire_user.range", "Max Range:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	model		= "models/jaanus/wiretool/wiretool_siren.mdl",
	range 		= 200,
}

if SERVER then
	function TOOL:GetConVars() return self:GetClientNumber("range") end
end

function TOOL.BuildCPanel( panel )
	ModelPlug_AddToCPanel(panel, "Laser_Tools", "wire_user", true)
	panel:NumSlider("#tool.wire_user.range", "wire_user_range", 1, 1000, 1)
end
