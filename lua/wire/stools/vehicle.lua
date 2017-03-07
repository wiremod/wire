WireToolSetup.setCategory( "Vehicle Control" )
WireToolSetup.open( "vehicle", "Vehicle Controller", "gmod_wire_vehicle", nil, "Vehicle Controllers" )

if CLIENT then
	language.Add("Tool.wire_vehicle.name", "Vehicle Controller Tool (Wire)")
	language.Add("Tool.wire_vehicle.desc", "Spawn/link a Wire Vehicle controller.")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

WireToolSetup.SetupLinking(true, "vehicle")

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_vehicle_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
