WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "explosive", "Explosive", "gmod_wire_explosive", nil, "Explosives" )

TOOL.ClientConVar = {
	model = "models/props_c17/oildrum001_explosive.mdl",
	effect = "Explosion",
	trigger = 1,		-- Wire input value to cause the explosion
	damage = 200,		-- Damage to inflict
	radius = 300,
	removeafter = 0,
	affectother = 0,
	notaffected = 0,
	delaytime = 0,
	delayreloadtime = 0,
	maxhealth = 100,
	bulletproof = 0,
	explosionproof = 0,
	explodeatzero = 1,
	resetatexplode = 1,
	fireeffect = 1,
	coloreffect = 1,
	invisibleatzero = 0,
}
TOOL.ReloadSetsModel = true

if ( CLIENT ) then
	language.Add( "Tool.wire_explosive.name", "Wired Explosives Tool" )
	language.Add( "Tool.wire_explosive.desc", "Creates a variety of different explosives for wire system." )
	language.Add( "Tool.wire_explosive.trigger", "Trigger value:" )
	language.Add( "Tool.wire_explosive.damage", "Damage:" )
	language.Add( "Tool.wire_explosive.radius", "Blast radius:" )
	language.Add( "Tool.wire_explosive.delaytime", "On fire time (delay after triggered before explosion):" )
	language.Add( "Tool.wire_explosive.delayreloadtime", "Delay after explosion before it can be triggered again:" )
	language.Add( "Tool.wire_explosive.removeafter", "Remove on explosion" )
	language.Add( "Tool.wire_explosive.affectother", "Damaged/moved by other wired explosives" )
	language.Add( "Tool.wire_explosive.notaffected", "Not moved by any phyiscal damage" )
	language.Add( "Tool.wire_explosive.maxhealth", "Max health:" )
	language.Add( "Tool.wire_explosive.bulletproof", "Bullet proof" )
	language.Add( "Tool.wire_explosive.explosionproof", "Explosion proof" )
	language.Add( "Tool.wire_explosive.explodeatzero", "Explode when health = zero" )
	language.Add( "Tool.wire_explosive.resetatexplode", "Reset health then" )
	language.Add( "Tool.wire_explosive.fireeffect", "Enable fire effect on triggered" )
	language.Add( "Tool.wire_explosive.coloreffect", "Enable color change effect on damage" )
	language.Add( "Tool.wire_explosive.invisibleatzero", "Become invisible when health reaches 0" )
	TOOL.Information = {
		{ name = "left", text = "Create " .. TOOL.Name },
		{ name = "right", text = "Update " .. TOOL.Name },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("trigger"), self:GetClientNumber("damage"), self:GetClientNumber("delaytime"), self:GetClientNumber("removeafter")~=0,
			self:GetClientNumber("radius"), self:GetClientNumber("affectother")~=0, self:GetClientNumber("notaffected")~=0, self:GetClientNumber("delayreloadtime"),
			self:GetClientNumber("maxhealth"), self:GetClientNumber("bulletproof")~=0, self:GetClientNumber("explosionproof")~=0, self:GetClientNumber("fallproof")~=0,
			self:GetClientNumber("explodeatzero")~=0, self:GetClientNumber("resetatexplode")~=0, self:GetClientNumber("fireeffect")~=0, self:GetClientNumber("coloreffect")~=0,
			self:GetClientNumber("invisibleatzero")~=0
	end

	-- Uses default WireToolObj:MakeEnt's WireLib.MakeWireEnt function
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_explosive")
	ModelPlug_AddToCPanel(panel, "Explosive", "wire_explosive", nil, 3)
	panel:NumSlider("#Tool.wire_explosive.trigger", "wire_explosive_trigger", -10, 10, 0 )
	panel:NumSlider("#Tool.wire_explosive.damage", "wire_explosive_damage", 0, 500, 0 )
	panel:NumSlider("#Tool.wire_explosive.radius", "wire_explosive_radius", 1, 1500, 0 )
	panel:NumSlider("#Tool.wire_explosive.delaytime", "wire_explosive_delaytime", 0, 60, 2 )
	panel:NumSlider("#Tool.wire_explosive.delayreloadtime", "wire_explosive_delayreloadtime", 0, 60, 2 )
	panel:CheckBox("#Tool.wire_explosive.removeafter","wire_explosive_removeafter")
	panel:CheckBox("#Tool.wire_explosive.affectother","wire_explosive_affectother")
	panel:CheckBox("#Tool.wire_explosive.notaffected","wire_explosive_notaffected")
	panel:NumSlider("#Tool.wire_explosive.maxhealth", "wire_explosive_maxhealth", 0, 500, 0 )
	panel:CheckBox("#Tool.wire_explosive.bulletproof","wire_explosive_bulletproof")
	panel:CheckBox("#Tool.wire_explosive.explosionproof","wire_explosive_explosionproof")
	panel:CheckBox("#Tool.wire_explosive.explodeatzero","wire_explosive_explodeatzero")
	panel:CheckBox("#Tool.wire_explosive.resetatexplode","wire_explosive_resetatexplode")
	panel:CheckBox("#Tool.wire_explosive.fireeffect","wire_explosive_fireeffect")
	panel:CheckBox("#Tool.wire_explosive.coloreffect","wire_explosive_coloreffect")
	panel:CheckBox("#Tool.wire_explosive.invisibleatzero","wire_explosive_invisibleatzero")
end
