WireToolSetup.setCategory( "Vehicle Control" )
WireToolSetup.open( "vehicle", "Vehicle Controller", "gmod_wire_vehicle", nil, "Vehicle Controllers" )

if CLIENT then
	language.Add("Tool.wire_vehicle.name", "Vehicle Controller Tool (Wire)")
	language.Add("Tool.wire_vehicle.desc", "Spawn/link a Wire Vehicle controller.")
	language.Add("Tool.wire_vehicle.0", "Primary: Create Vehicle controller. Secondary: Link controller.")
	language.Add("Tool.wire_vehicle.1", "Now select the Vehicle to link to.")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

WireToolSetup.SetupLinking(true)

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_vehicle_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
