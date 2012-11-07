WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "forcer", "Forcer", "gmod_wire_forcer", WireToolMakeForcer, "Forcers" )

if CLIENT then
	language.Add( "tool.wire_forcer.name", "Forcer Tool (Wire)" )
	language.Add( "tool.wire_forcer.desc", "Spawns a forcer prop for use with the wire system." )
	language.Add( "tool.wire_forcer.0", "Primary: Create/Update Forcer" )
end
WireToolSetup.BaseLang("Forcers")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

TOOL.ClientConVar = {
	multiplier	= 1,
	length		= 100,
	beam		= 1,
	reaction	= 0,
	model		= "models/jaanus/wiretool/wiretool_siren.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_forcer")
	ModelPlug_AddToCPanel(panel, "Forcer", "wire_forcer", true, 1)
	panel:NumSlider("Force multiplier", "wire_forcer_multiplier", 1, 10000, 0)
	panel:NumSlider("Force distance", "wire_forcer_length", 1, 10000, 0)
	panel:CheckBox("Show beam", "wire_forcer_beam")
	panel:CheckBox("Apply reaction force", "wire_forcer_reaction")
end
