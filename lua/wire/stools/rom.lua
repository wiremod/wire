WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "rom", "Memory - ROM", "gmod_wire_dhdd", nil, "Memory ROMs" )

if CLIENT then
	language.Add( "Tool.wire_rom.name", "ROM Tool (Wire)" )
	language.Add( "Tool.wire_rom.desc", "Spawns a ROM chip" )
	language.Add( "Tool.wire_rom.0", "Primary: Create ROM." )

	language.Add( "Tool.wire_rom.weld", "Weld the ROM." )
	language.Add( "Tool.wire_rom.weldtoworld", "Weld the ROM to the world." )
	language.Add( "Tool.wire_rom.note", "ROM size will depend on written data.\nThe maximum size is 256 KB." )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["weldtoworld"] = 0

	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "gate", "wire_rom", nil, 4)
		
		panel:CheckBox("#Tool.wire_rom.weld", "wire_rom_weld")
		panel:CheckBox("#Tool.wire_rom.weldtoworld", "wire_rom_weldtoworld")
		panel:Help("#Tool.wire_rom.note")
	end
end
TOOL.MaxLimitName = "wire_dhdds"

if SERVER then
	function TOOL:MakeEnt( ply, model, Ang, trace )
		local rom = MakeWireDHDD( ply, trace.HitPos, Ang, model, self:GetConVars() )
		if IsValid(rom) then
			rom.ROM = true
			rom:SetOverlayText("ROM")
		end
		return rom
	end
end
