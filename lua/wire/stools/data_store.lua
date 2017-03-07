WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "data_store", "Store", "gmod_wire_data_store", nil, "Data Stores" )

if ( CLIENT ) then
	language.Add( "Tool.wire_data_store.name", "Data Store Tool (Wire)" )
	language.Add( "Tool.wire_data_store.desc", "Spawns a data store." )
	language.Add( "WireDataStoreTool_data_store", "Data Store:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_range.mdl"

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_data_store_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
