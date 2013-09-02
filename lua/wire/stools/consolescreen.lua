WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "consolescreen", "Console Screen", "gmod_wire_consolescreen", nil,  "Screens" )

if CLIENT then
	language.Add( "tool.wire_consolescreen.name", "Console Screen Tool (Wire)" )
	language.Add( "tool.wire_consolescreen.desc", "Spawns a console screen" )
	language.Add( "tool.wire_consolescreen.0", "Primary: Create/Update screen" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 20 )

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 0,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_consolescreen_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#Create Flat to Surface", "wire_consolescreen_createflat")
end