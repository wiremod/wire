WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "simple_explosive", "Explosives (Simple)", "gmod_wire_simple_explosive", nil, "Simple Explosives" )

if CLIENT then
	language.Add( "tool.wire_simple_explosive.name", "Simple Wired Explosives Tool" )
	language.Add( "tool.wire_simple_explosive.desc", "Creates a simple explosives for wire system." )
	language.Add( "Tool.simple_explosive.model", "Model:" )
	language.Add( "Tool.simple_explosive.trigger", "Trigger value:" )
	language.Add( "Tool.simple_explosive.damage", "Damage:" )
	language.Add( "Tool.simple_explosive.removeafter", "Remove on explosion" )
	language.Add( "Tool.simple_explosive.radius", "Blast radius:" )
	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "reload", text = "Copy model" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "trigger" ), self:GetClientNumber( "damage" ), self:GetClientNumber( "removeafter" )==1,
			self:GetClientNumber( "radius" )
	end
end

TOOL.ClientConVar = {
	model = "models/props_c17/oildrum001_explosive.mdl",
	modelman = "",
	trigger = 1,		-- Wire input value to cause the explosion
	damage = 200,		-- Damage to inflict
	radius = 300,
	removeafter = 0,
}
TOOL.ReloadSetsModel = true

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Explosive", "wire_simple_explosive")
	panel:Help("This tool is deprecated as its functionality is contained within Wire Explosive, and will be removed soon.")
	panel:NumSlider("#Tool.simple_explosive.trigger", "wire_simple_explosive_trigger", -10, 10, 0 )
	panel:NumSlider("#Tool.simple_explosive.damage", "wire_simple_explosive_damage", 0, 500, 0 )
	panel:NumSlider("#Tool.simple_explosive.radius", "wire_simple_explosive_radius", 1, 1500, 0 )
	panel:CheckBox("#Tool.simple_explosive.removeafter","wire_simple_explosive_removeafter")
end
