WireToolSetup.setCategory( "Detection/Beacon" )
WireToolSetup.open( "locator", "Locator", "gmod_wire_locator", nil, "Locators" )

if ( CLIENT ) then
	language.Add( "Tool.wire_locator.name", "Locator Beacon Tool (Wire)" )
	language.Add( "Tool.wire_locator.desc", "Spawns a locator beacon for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	model = "models/props_lab/powerbox02d.mdl",
	createflat = 1
}

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_locator")
	panel:CheckBox("#Create Flat to Surface", "wire_locator_createflat")
end
