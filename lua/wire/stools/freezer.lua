WireToolSetup.setCategory( "Physics/Constraints" )
WireToolSetup.open( "freezer", "Freezer", "gmod_wire_freezer", nil, "Freezers" )

if CLIENT then
	language.Add( "Tool.wire_freezer.name", "Freezer Tool (Wire)" )
	language.Add( "Tool.wire_freezer.desc", "Spawns a Freezer Controller for use with the wire system." )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function

WireToolSetup.SetupLinking() -- Generates RightClick, Reload, and DrawHUD functions

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_freezer")
end
