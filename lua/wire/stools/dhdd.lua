WireToolSetup.setCategory( "Memory" )
WireToolSetup.open( "dhdd", "DHDD", "gmod_wire_dhdd", nil, "DHDDs" )

if CLIENT then
	language.Add( "Tool.wire_dhdd.name", "DHDD Tool (Wire)" )
	language.Add( "Tool.wire_dhdd.desc", "Spawns a dupeable hard drive gate for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	language.Add( "Tool.wire_dhdd.weld", "Weld the DHDD." )
	language.Add( "Tool.wire_dhdd.weldtoworld", "Weld the DHDD to the world." )
	language.Add( "Tool.wire_dhdd.note", "NOTE: The DHDD only saves the first\n512^2 values to prevent\nmassive dupe files and lag." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"

	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "gate", "wire_dhdd", nil, 4)

		panel:Help("#Tool.wire_dhdd.note")
	end

	WireToolSetup.setToolMenuIcon( "icon16/database.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )
