WireToolSetup.setCategory( "Visuals/Screens" )
WireToolSetup.open( "oscilloscope", "Oscilloscope", "gmod_wire_oscilloscope", nil, "Oscilloscopes" )

if CLIENT then
	language.Add( "tool.wire_oscilloscope.name", "Oscilloscope Tool (Wire)" )
	language.Add( "tool.wire_oscilloscope.desc", "Spawns an oscilloscope that displays line graphs." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.NoLeftOnClass = true -- no update ent function needed
TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 0,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_oscilloscope_model", list.Get( "WireScreenModels" ), 5)
	panel:CheckBox("#Create Flat to Surface", "wire_oscilloscope_createflat")
end
