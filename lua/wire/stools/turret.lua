WireToolSetup.setCategory( "Other" )
WireToolSetup.open( "turret", "Turret", "gmod_wire_turret", nil, "Turrets" )

-- Precache these sounds..
Sound( "ambient.electrical_zap_3" )
Sound( "NPC_FloorTurret.Shoot" )

-- Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "tool.wire_turret.name", "Turret" )
	language.Add( "tool.wire_turret.desc", "Throws bullets at things" )

	language.Add( "Tool_wire_turret_spread", "Bullet Spread" )
	language.Add( "Tool_wire_turret_numbullets", "Bullets per Shot" )
	language.Add( "Tool_wire_turret_force", "Bullet Force" )
	language.Add( "Tool_wire_turret_sound", "Shoot Sound" )
	language.Add( "Tool_wire_turret_tracernum", "Tracer Every x Bullets:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	delay 		= 0.05,
	force 		= 1,
	sound 		= 0,
	damage 		= 10,
	spread 		= 0,
	numbullets	= 1,
	automatic	= 1,
	tracer 		= "Tracer",
	tracernum 	= 1,
	model		= "models/weapons/w_smg1.mdl"
}

TOOL.GhostAngle = Angle(-90,0,0)
TOOL.GetGhostMin = function() return -2 end

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("delay"), self:GetClientNumber("damage"), self:GetClientNumber("force"), self:GetClientInfo("sound"),
			self:GetClientNumber("numbullets"), self:GetClientNumber("spread"), self:GetClientInfo("tracer"), self:GetClientNumber("tracernum")
	end
end

local ValidTurretModels = {
	["models/weapons/w_smg1.mdl"] = true,
	["models/weapons/w_smg_mp5.mdl"] = true,
	["models/weapons/w_smg_mac10.mdl"] = true,
	["models/weapons/w_rif_m4a1.mdl"] = true,
	["models/weapons/w_357.mdl"] = true,
	["models/weapons/w_shot_m3super90.mdl"] = true
}

function TOOL:GetModel()
	local model = WireToolObj.GetModel(self)
	return ValidTurretModels[model] and model or "models/weapons/w_smg1.mdl"
end

function TOOL.BuildCPanel( CPanel )
	WireToolHelpers.MakePresetControl(CPanel, "wire_turret")

	-- Shot sounds
	local weaponSounds = {Label = "#Tool_wire_turret_sound", MenuButton = 0, Options={}, CVars = {}}
		weaponSounds["Options"]["#No Weapon"]	= { wire_turret_sound = "" }
		weaponSounds["Options"]["#Pistol"]		= { wire_turret_sound = "Weapon_Pistol.Single" }
		weaponSounds["Options"]["#SMG"]			= { wire_turret_sound = "Weapon_SMG1.Single" }
		weaponSounds["Options"]["#AR2"]			= { wire_turret_sound = "Weapon_AR2.Single" }
		weaponSounds["Options"]["#Shotgun"]		= { wire_turret_sound = "Weapon_Shotgun.Single" }
		weaponSounds["Options"]["#Floor Turret"]	= { wire_turret_sound = "NPC_FloorTurret.Shoot" }
		weaponSounds["Options"]["#Airboat Heavy"]	= { wire_turret_sound = "Airboat.FireGunHeavy" }
		weaponSounds["Options"]["#Zap"]	= { wire_turret_sound = "ambient.electrical_zap_3" }


	CPanel:AddControl("ComboBox", weaponSounds )

	WireDermaExts.ModelSelect(CPanel, "wire_turret_model", list.Get( "WireTurretModels" ), 2)

	-- Tracer
	local TracerType = {Label = "#Tracer", MenuButton = 0, Options={}, CVars = {}}
		TracerType["Options"]["#Default"]			= { wire_turret_tracer = "Tracer" }
		TracerType["Options"]["#AR2 Tracer"]		= { wire_turret_tracer = "AR2Tracer" }
		TracerType["Options"]["#Airboat Tracer"]	= { wire_turret_tracer = "AirboatGunHeavyTracer" }
		TracerType["Options"]["#Laser"]				= { wire_turret_tracer = "LaserTracer" }

	CPanel:AddControl("ComboBox", TracerType )

	-- Various controls that you should play with!
	CPanel:NumSlider("#Tool_wire_turret_numbullets", "wire_turret_numbullets", 1, 10, 0)
	CPanel:NumSlider("#Damage", "wire_turret_damage", 0, 100, 0)
	CPanel:NumSlider("#Tool_wire_turret_spread", "wire_turret_spread", 0, 1.0, 2)
	CPanel:NumSlider("#Tool_wire_turret_force", "wire_turret_force", 0, 500, 1)
	CPanel:NumSlider("#Tool_wire_turret_tracernum", "wire_turret_tracernum", 0, 15, 0)
	CPanel:NumSlider("#Delay", "wire_turret_delay", 0, 1.0, 2)

end
