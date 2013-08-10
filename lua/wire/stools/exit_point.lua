WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "exit_point", "Vehicle Exit Point", "gmod_wire_exit_point", nil, "Exit Points" )

if CLIENT then
	language.Add( "tool."..TOOL.Mode..".name", TOOL.Name.." Tool (Wire)" )
	language.Add( "tool."..TOOL.Mode..".desc", "Spawns a "..TOOL.Name )
	language.Add( "tool."..TOOL.Mode..".0", "Primary: Create "..TOOL.Name.."" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(6)

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_range.mdl",
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_exit_point", true)
end
