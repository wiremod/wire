WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "turret", "Turret", "gmod_wire_turret", nil, "Turrets" )

-- Precache these sounds..
Sound( "ambient.electrical_zap_3" )
Sound( "NPC_FloorTurret.Shoot" )

-- Add Default Language translation (saves adding it to the txt files)
if CLIENT then
	language.Add( "tool.wire_turret.name", "Turret" )
	language.Add( "tool.wire_turret.desc", "Throws bullets at things" )
	language.Add( "tool.wire_turret.0", "Click somewhere to spawn an turret. Click on an existing turret to change it." )

	language.Add( "Tool_wire_turret_spread", "Bullet Spread" )
	language.Add( "Tool_wire_turret_numbullets", "Bullets per Shot" )
	language.Add( "Tool_wire_turret_force", "Bullet Force" )
	language.Add( "Tool_wire_turret_sound", "Shoot Sound" )
	language.Add( "Tool_wire_turret_tracernum", "Tracer Every x Bullets:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

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

function TOOL:LeftClick( trace, worldweld )
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	local delay 		= self:GetClientNumber( "delay" )
	local force 		= self:GetClientNumber( "force" )
	local sound 		= self:GetClientInfo( "sound" )
	local tracer 		= self:GetClientInfo( "tracer" )
	local damage	 	= self:GetClientNumber( "damage" )
	local spread	 	= self:GetClientNumber( "spread" )
	local numbullets 	= self:GetClientNumber( "numbullets" )
	local tracernum 	= self:GetClientNumber( "tracernum" )
	local model 		= self:GetClientInfo( "model" )
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return end

	-- We shot an existing turret - just change its values
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_turret" then
		trace.Entity:SetDamage( damage )
		trace.Entity:SetDelay( delay )
		trace.Entity:SetNumBullets( numbullets )
		trace.Entity:SetSpread( spread )
		trace.Entity:SetForce( force )
		trace.Entity:SetSound( sound )
		trace.Entity:SetTracer( tracer )
		trace.Entity:SetTracerNum( tracernum )
		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_turrets" ) then return false end

	trace.HitPos = trace.HitPos + trace.HitNormal * 2

	local Ang=nil

	local turret = MakeWireTurret( ply, trace.HitPos, Ang, model, delay, damage, force, sound, numbullets, spread, tracer, tracernum )

	turret:SetAngles( trace.HitNormal:Angle() )

	local weld = WireLib.Weld(turret, trace.Entity, trace.PhysicsBone, true, false, worldweld or false)

	undo.Create("WireTurret")
		undo.AddEntity( turret )
		undo.AddEntity( weld )
		undo.SetPlayer( ply )
	undo.Finish()

	return true
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace, true )
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
	if game.SinglePlayer() then
		CPanel:NumSlider("#Tool_wire_turret_numbullets", "wire_turret_numbullets", 1, 10, 0)
	end
	CPanel:NumSlider("#Damage", "wire_turret_damage", 0, 100, 0)
	CPanel:NumSlider("#Tool_wire_turret_spread", "wire_turret_spread", 0, 1.0, 2)
	CPanel:NumSlider("#Tool_wire_turret_force", "wire_turret_force", 0, 500, 1)

	-- The delay between shots.
	if game.SinglePlayer() then
		CPanel:NumSlider("#Delay", "wire_turret_delay", 0.01, 1.0, 2)
		CPanel:NumSlider("#Tool_wire_turret_tracernum", "wire_turret_tracernum", 0, 15, 0)
	else
		CPanel:NumSlider("#Delay", "wire_turret_delay", 0.05, 1.0, 2)
	end

end
