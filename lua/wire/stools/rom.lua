WireToolSetup.setCategory( "Advanced" )
WireToolSetup.open( "rom", "Memory - ROM", "gmod_wire_dhdd", nil, "Memory ROMs" )

if CLIENT then
	language.Add( "Tool.wire_rom.name", "ROM Tool (Wire)" )
	language.Add( "Tool.wire_rom.desc", "Spawns a ROM chip" )

	language.Add( "Tool.wire_rom.note", "ROM size will depend on written data.\nThe maximum size is 256 KB." )

	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"

	function TOOL.BuildCPanel( panel )
		ModelPlug_AddToCPanel(panel, "gate", "wire_rom", nil, 4)

		panel:Help("#Tool.wire_rom.note")
	end

	WireToolSetup.setToolMenuIcon( "icon16/database.png" )
end
TOOL.MaxLimitName = "wire_dhdds"

if SERVER then
	function TOOL:MakeEnt( ply, model, Ang, trace )
		local rom = WireLib.MakeWireEnt(ply, {Class = "gmod_wire_dhdd", Pos=trace.HitPos, Angle=Ang, Model=model}, self:GetConVars())
		if IsValid(rom) then
			rom.ROM = true
			rom:SetOverlayText("ROM")
		end
		return rom
	end
end
