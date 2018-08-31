WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "datarate", "Data - Transfer Bus", "gmod_wire_datarate", nil, "Transfer Buses" )

if ( CLIENT ) then
	language.Add( "Tool.wire_datarate.name", "Data transfer bus tool (Wire)" )
	language.Add( "Tool.wire_datarate.desc", "Spawns a data transferrer. Data transferrer acts like identity gate for hi-speed and regular links" )
	TOOL.Information = { { name = "left", text = "Create/Update data transferrer" } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if SERVER then
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gate", "wire_datarate", nil, 4)
end
