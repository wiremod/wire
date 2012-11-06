WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "light", "Light", "gmod_wire_light", nil, "Lights" )

if CLIENT then
	language.Add( "tool.wire_light.name", "Light Tool (Wire)" )
	language.Add( "tool.wire_light.desc", "Spawns a Light for use with the wire system." )
	language.Add( "tool.wire_light.0", "Primary: Create Light" )
	language.Add( "WireLightTool_directional", "Directional Component" )
	language.Add( "WireLightTool_radiant", "Radiant Component" )
	language.Add( "WireLightTool_glow", "Glow Component" )
end
WireToolSetup.BaseLang()

WireToolSetup.SetupMax( 8, "wire_lights", "You've hit lights limit!" )

if SERVER then
	function TOOL:GetConVars()
		return
			self:GetClientNumber("directional") ~= 0,
			self:GetClientNumber("radiant") ~= 0,
			self:GetClientNumber("glow") ~= 0
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireLight( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model       = "models/jaanus/wiretool/wiretool_siren.mdl",
	directional = 0,
	radiant     = 0,
	glow        = 0,
	weld        = 1,
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_light_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#WireLightTool_directional", "wire_light_directional")
	panel:CheckBox("#WireLightTool_radiant", "wire_light_radiant")
	panel:CheckBox("#WireLightTool_glow", "wire_light_glow")
	panel:CheckBox("Weld", "wire_light_weld")
end
