WireToolSetup.setCategory("Other")
WireToolSetup.open("turret", "Turret", "gmod_wire_turret", nil, "Turrets")

if CLIENT then
	language.Add("tool.wire_turret.name", "Turret")
	language.Add("tool.wire_turret.desc", "Spawns a turret for use with the wire system.")
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon("icon16/gun.png")
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)

TOOL.GhostAngle = Angle(-90, 0, 0)
TOOL.GetGhostMin = function() return -2 end

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("delay"), self:GetClientNumber("damage"), self:GetClientNumber("force"), self:GetClientInfo("sound"), self:GetClientNumber("numbullets"), self:GetClientNumber("spread"), self:GetClientInfo("tracer"), self:GetClientNumber("tracernum")
	end
end

TOOL.ClientConVar = {
	delay 		= 0.05,
	force 		= 1,
	sound 		= "",
	damage 		= 10,
	spread 		= 0,
	numbullets	= 1,
	automatic	= 1,
	tracer 		= "Tracer",
	tracernum 	= 1,
	model		= "models/weapons/w_smg1.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_turret")

	-- Sounds
	local sounds = panel:ComboBox("Shoot Sound", "wire_turret_sound")
	sounds:AddChoice("None", "")
	sounds:AddChoice("Pistol", "Weapon_Pistol.Single")
	sounds:AddChoice("SMG", "Weapon_SMG1.Single")
	sounds:AddChoice("AR2", "Weapon_AR2.Single")
	sounds:AddChoice("Shotgun", "Weapon_Shotgun.Single")
	sounds:AddChoice("Floor Turret", "NPC_FloorTurret.Shoot")
	sounds:AddChoice("Airboat Heavy", "Airboat.FireGunHeavy")
	sounds:AddChoice("Zap", "ambient.electrical_zap_3")
	sounds:AddChoice("357", "Weapon_357.Single")
	sounds:AddChoice("Crossbow", "Weapon_Crossbow.Single")
	sounds:AddChoice("Flare Gun", "Weapon_FlareGun.Single")
	sounds:AddChoice("Stationary Turret", "Weapon_functank.Single")
	sounds:AddChoice("Mortar", "Weapon_Mortar.Single")
	sounds:AddChoice("RPG", "Weapon_RPG.Single")

	-- Models
	WireDermaExts.ModelSelect(panel, "wire_turret_model", list.Get("WireTurretModels"), 2)

	-- Tracers
	local tracers = panel:ComboBox("Tracer", "wire_turret_tracer")
	tracers:AddChoice("None", "")
	tracers:AddChoice("Default", "Tracer")
	tracers:AddChoice("AR2 Tracer", "AR2Tracer")
	tracers:AddChoice("Helicopter Tracer", "HelicopterTracer")
	tracers:AddChoice("Airboat Tracer", "AirboatGunHeavyTracer")
	tracers:AddChoice("Laser", "LaserTracer")
	tracers:AddChoice("Tool Tracer", "ToolTracer")

	panel:NumSlider("Bullets per shot", "wire_turret_numbullets", 1, 10, 0)
	panel:NumSlider("Damage", "wire_turret_damage", 0, 100, 0)
	panel:NumSlider("Bullet Spread", "wire_turret_spread", 0, 1, 2)
	panel:NumSlider("Bullet Force", "wire_turret_force", 0, 500, 0)
	panel:NumSlider("Tracer Every x Bullets", "wire_turret_tracernum", 0, 15, 0)
	panel:NumSlider("Delay", "wire_turret_delay", 0, 10, 2)
end
