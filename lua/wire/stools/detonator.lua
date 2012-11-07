WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "detonator", "Detonator", "gmod_wire_detonator", WireToolMakeDetonator, "Detonators" )

if CLIENT then
	language.Add( "tool.wire_detonator.name", "Detonator Tool (Wire)" )
	language.Add( "tool.wire_detonator.desc", "Spawns a Detonator for use with the wire system." )
	language.Add( "tool.wire_detonator.0", "Primary: Create/Update Detonator" )
end
WireToolSetup.BaseLang("Detonators")
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("detonator")
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
