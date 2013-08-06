WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "adv_emarker", "Adv Entity Marker", "gmod_wire_adv_emarker", nil, "Adv Entity Markers" )

if CLIENT then
	language.Add( "Tool.wire_adv_emarker.name", "Adv Entity Marker Tool (Wire)" )
	language.Add( "Tool.wire_adv_emarker.desc", "Spawns an Adv Entity Marker for use with the wire system." )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function

WireToolSetup.SetupLinking() -- Generates RightClick, Reload, and DrawHUD functions

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_adv_emarker")
end
