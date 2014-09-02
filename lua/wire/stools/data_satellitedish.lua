WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "data_satellitedish", "Satellite Dish", "gmod_wire_data_satellitedish", nil, "Satellite Dishs" )

if ( CLIENT ) then
    language.Add( "Tool.wire_data_satellitedish.name", "Satellite Dish Tool (Wire)" )
    language.Add( "Tool.wire_data_satellitedish.desc", "Spawns a Satellite Dish." )
    language.Add( "Tool.wire_data_satellitedish.0", "Primary: Create Satellite Dish. Secondary: Link Satellite Dish. Reload: Unlink/Change model" )
	language.Add( "Tool.wire_data_satellitedish.1", "Now select the Wire Transferer to link to" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar["model"] = "models/props_wasteland/prison_lamp001c.mdl"

TOOL.ReloadSetsModel = true
WireToolSetup.SetupLinking(true)

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_data_satellitedish_model", list.Get( "Wire_satellitedish_Models" ), 1)
end
