WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "dataport", "Data - Port", "gmod_wire_dataport", nil, "Data Ports" )

if ( CLIENT ) then
	language.Add( "Tool.wire_dataport.name", "Data port tool (Wire)" )
	language.Add( "Tool.wire_dataport.desc", "Spawns data port consisting of 8 ports" )
	TOOL.Information = { { name = "left", text = "Create/Update data port" } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if SERVER then
	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gate", "wire_dataport", nil, 4)
end
