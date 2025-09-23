WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "oscilloscope", "Oscilloscope", "gmod_wire_oscilloscope", nil, "Oscilloscopes" )

if CLIENT then
	language.Add( "tool.wire_oscilloscope.name", "Oscilloscope Tool (Wire)" )
	language.Add( "tool.wire_oscilloscope.desc", "Spawns an oscilloscope that displays line graphs." )
	language.Add( "tool.wire_oscilloscope.interactive", "Interactive (if available):" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/chart_line.png")
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
	WireDermaExts.ModelSelect(panel, "wire_oscilloscope_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#tool.wire_oscilloscope.interactive", "wire_oscilloscope_interactive")
	panel:CheckBox("#Create Flat to Surface", "wire_oscilloscope_createflat")
end
