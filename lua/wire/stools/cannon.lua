WireToolSetup.setCategory( "Other" )
WireToolSetup.open( "cannon", "Cannon", "gmod_wire_cannon", nil, "Cannons" )

-- Precache these sounds..
Sound( "ambient.electrical_zap_3" )
Sound( "NPC_FloorCannon.Shoot" )

-- Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "tool.wire_cannon.name", "Extended Cannon" )
	language.Add( "tool.wire_cannon.desc", "Throws bullets at things" )

	language.Add( "Tool_wire_cannon_spread", "Bullet Spread" )
	language.Add( "Tool_wire_cannon_numbullets", "Bullets per Shot" )
	language.Add( "Tool_wire_cannon_force", "Bullet Force" )
	language.Add( "Tool_wire_cannon_sound", "Shoot Sound" )
	language.Add( "Tool_wire_cannon_blastdamage", "Blast Damage" )
	language.Add( "Tool_wire_cannon_blastradius", "Blast Radius" )
	language.Add( "Tool_wire_cannon_tracernum", "Tracer Every x Bullets:" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	WireToolSetup.setToolMenuIcon( "icon16/bomb.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

TOOL.ClientConVar = {
	delay 		= 0.05,
	force 		= 1,
	sound 		= 0,
	damage 		= 10,
	blastdamage = 0,
	blastradius = 0,
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
			self:GetClientNumber("numbullets"), self:GetClientNumber("spread"), self:GetClientNumber("blastdamage"), self:GetClientNumber("blastradius"), self:GetClientInfo("tracer"), self:GetClientNumber("tracernum")
	end
end

local ValidCannonModels = {
	["models/weapons/w_smg1.mdl"] = true,
	["models/weapons/w_smg_mp5.mdl"] = true,
	["models/weapons/w_smg_mac10.mdl"] = true,
	["models/weapons/w_rif_m4a1.mdl"] = true,
	["models/weapons/w_357.mdl"] = true,
	["models/weapons/w_shot_m3super90.mdl"] = true
}

function TOOL:GetModel()
	local model = WireToolObj.GetModel(self)
	return ValidCannonModels[model] and model or "models/weapons/w_smg1.mdl"
end

CreateConVar( "wire_cannon_blastdamage_max", "100", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Sets the max damage that Cannons can have in regards to Blast Damage, This hardlocks the menu slider and actual damage" .. "0 to Disable", 0, 99999)
CreateConVar( "wire_cannon_blastradius_max", "500", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Sets the max radius that Cannons can have in regards to Blast Radius, This hardlocks the menu slider and actual damage" .. "0 to Disable", 0, 99999)

function TOOL.BuildCPanel( CPanel )
	WireToolHelpers.MakePresetControl(CPanel, "wire_cannon")

	-- Shot sounds
	local weaponSounds = {Label = "#Tool_wire_cannon_sound", MenuButton = 0, Options={}, CVars = {}}
		weaponSounds["Options"]["#No Weapon"]	= { wire_cannon_sound = "" }
		weaponSounds["Options"]["#Pistol"]		= { wire_cannon_sound = "Weapon_Pistol.Single" }
		weaponSounds["Options"]["#SMG"]			= { wire_cannon_sound = "Weapon_SMG1.Single" }
		weaponSounds["Options"]["#AR2"]			= { wire_cannon_sound = "Weapon_AR2.Single" }
		weaponSounds["Options"]["#Shotgun"]		= { wire_cannon_sound = "Weapon_Shotgun.Single" }
		weaponSounds["Options"]["#Floor Cannon"]	= { wire_cannon_sound = "NPC_FloorCannon.Shoot" }
		weaponSounds["Options"]["#Airboat Heavy"]	= { wire_cannon_sound = "Airboat.FireGunHeavy" }
		weaponSounds["Options"]["#Zap"]	= { wire_cannon_sound = "ambient.electrical_zap_3" }


	CPanel:AddControl("ComboBox", weaponSounds )

	WireDermaExts.ModelSelect(CPanel, "wire_cannon_model", list.Get( "WireTurretModels" ), 2)

	-- Tracer
	local TracerType = {Label = "#Tracer", MenuButton = 0, Options={}, CVars = {}}
		TracerType["Options"]["#Default"]			= { wire_cannon_tracer = "Tracer" }
		TracerType["Options"]["#AR2 Tracer"]		= { wire_cannon_tracer = "AR2Tracer" }
		TracerType["Options"]["#Airboat Tracer"]	= { wire_cannon_tracer = "AirboatGunHeavyTracer" }
		TracerType["Options"]["#Laser"]				= { wire_cannon_tracer = "LaserTracer" }

	CPanel:AddControl("ComboBox", TracerType )

	-- Various controls that you should play with!
	if game.SinglePlayer() then
		CPanel:NumSlider("#Tool_wire_cannon_numbullets", "wire_cannon_numbullets", 1, 10, 0)
	end
	CPanel:NumSlider("#Damage", "wire_cannon_damage", 0, 100, 0)
	CPanel:NumSlider("#Tool_wire_cannon_spread", "wire_cannon_spread", 0, 1.0, 2)
	CPanel:NumSlider("#Tool_wire_cannon_blastdamage", "wire_cannon_blastdamage", 0, GetConVar("wire_cannon_blastdamage_max"):GetInt(), 0)
	CPanel:NumSlider("#Tool_wire_cannon_blastradius", "wire_cannon_blastradius", 0, GetConVar("wire_cannon_blastradius_max"):GetInt(), 0)
	CPanel:NumSlider("#Tool_wire_cannon_force", "wire_cannon_force", 0, 500, 1)

	-- The delay between shots.
	if game.SinglePlayer() then
		CPanel:NumSlider("#Delay", "wire_cannon_delay", 0.01, 1.0, 2)
		CPanel:NumSlider("#Tool_wire_cannon_tracernum", "wire_cannon_tracernum", 0, 15, 0)
	else
		CPanel:NumSlider("#Delay", "wire_cannon_delay", 0.05, 1.0, 2)
	end
end
