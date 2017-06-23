WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "gimbal", "Gimbal (Facer)", "gmod_wire_gimbal", nil, "Gimbals" )

if CLIENT then
	language.Add( "tool.wire_gimbal.name", "Gimbal Tool (Wire)" )
	language.Add( "tool.wire_gimbal.desc", "Spawns a Gimbal (Facer)" )

	TOOL.Information = {
		{ name = "left", text = "Create/Update Gimbal" },
		{ name = "reload", text = "Copy model" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 8 )

-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function

TOOL.ClientConVar = {
	model = "models/props_c17/canister01a.mdl",
}
TOOL.ReloadSetsModel = true

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Gimbal", "wire_gimbal", true)
end
