WireToolSetup.setCategory( "Data" )
WireToolSetup.open( "dhdd", "DHDD", "gmod_wire_dhdd", nil, "DHDDs" )

if CLIENT then
	language.Add( "Tool.wire_dhdd.name", "DHDD Tool (Wire)" )
	language.Add( "Tool.wire_dhdd.desc", "Spawns a dupeable hard drive gate for use with the wire system." )
	language.Add( "Tool.wire_dhdd.0", "Primary: Create DHDD." )

	language.Add( "Tool.wire_dhdd.weld", "Weld the DHDD." )
	language.Add( "Tool.wire_dhdd.weldtoworld", "Weld the DHDD to the world." )
	language.Add( "Tool.wire_dhdd.note", "NOTE: The DHDD only saves the first\n512^2 values to prevent\nmassive dupe files and lag." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["weldtoworld"] = 0
	
	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "gate", "wire_dhdd", nil, 4)
		
		panel:CheckBox("#Tool.wire_dhdd.weld", "wire_dhdd_weld")
		panel:CheckBox("#Tool.wire_dhdd.weldtoworld", "wire_dhdd_weldtoworld")
		panel:Help("#Tool.wire_dhdd.note")
	end
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireDHDD( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end
