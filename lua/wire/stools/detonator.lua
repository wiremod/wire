WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "detonator", "Detonator", "gmod_wire_detonator", nil, "Detonators" )

if CLIENT then
	language.Add( "tool.wire_detonator.name", "Detonator Tool (Wire)" )
	language.Add( "tool.wire_detonator.desc", "Spawns a Detonator for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	ModelPlug_Register("detonator")
	function TOOL:GetConVars()
		return self:GetClientNumber( "damage" )
	end

	function TOOL:MakeEnt(ply, model, Ang, trace)
		local ent = WireToolObj.MakeEnt(self, ply, model, Ang, trace )
		ent.target = trace.Entity
		return ent
	end
end

TOOL.ClientConVar = {
	damage = 1,
	model = "models/props_combine/breenclock.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_detonator")
	panel:NumSlider("#Damage", "wire_detonator_damage", 1, 200, 0)
	ModelPlug_AddToCPanel(panel, "detonator", "wire_detonator", true, 1)
end
