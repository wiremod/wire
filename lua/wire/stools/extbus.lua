WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "extbus", "Data - Extended Bus", "gmod_wire_extbus", nil, "Extended Buses" )

if ( CLIENT ) then
	language.Add( "Tool.wire_extbus.name", "Extended bus tool (Wire)" )
	language.Add( "Tool.wire_extbus.desc", "Spawns an extended bus (programmable address bus)" )
	TOOL.Information = { { name = "left", text = "Create/Update extended bus" } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_extbus_model", list.Get("Wire_gate_Models"), 5)
end
