WireToolSetup.setCategory( "Vehicle Control" )
WireToolSetup.open( "pod", "Pod Controller", "gmod_wire_pod", nil, "Pod Controllers" )

if CLIENT then
	language.Add("tool.wire_pod.name", "Pod Controller Tool (Wire)")
	language.Add("tool.wire_pod.desc", "Spawn/link a Wire Pod controller.")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.NoLeftOnClass = true
TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

WireToolSetup.SetupLinking(true, "pod")

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_pod", nil, 1)
	panel:Help("Formerly known as 'Advanced Pod Controller'")
end
