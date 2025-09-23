WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "consolescreen", "Console Screen", "gmod_wire_consolescreen", nil,  "Screens" )

if CLIENT then
	language.Add( "tool.wire_consolescreen.name", "Console Screen Tool (Wire)" )
	language.Add( "tool.wire_consolescreen.desc", "Spawns a console screen" )
	language.Add( "tool.wire_consolescreen.interactive", "Interactive (if available):" )
	TOOL.Information = { { name = "left", text = "Create " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/application_xp_terminal.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("interactive")
	end
end

TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 0,
	interactive = 1,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_consolescreen_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#tool.wire_consolescreen.interactive", "wire_consolescreen_interactive")
	panel:CheckBox("#Create Flat to Surface", "wire_consolescreen_createflat")
	panel:Help("CharParam is LBBBFFF format: background and foreground colour of the character (one digit each for RGB), if L is nonzero the char flashes")
end
