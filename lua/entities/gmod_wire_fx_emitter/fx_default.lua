AddCSLuaFile()

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( angle:Forward() * 2 )
		effectdata:SetMagnitude( 1 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( 2 )
	util.Effect( "Sparks", effectdata )
end
AddFXEmitterEffect( "small_sparks", FX, "Sparks (Small)" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( angle:Forward() * 2 )
		effectdata:SetMagnitude( 2 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( 6 )
	util.Effect( "Sparks", effectdata )
end
AddFXEmitterEffect( "sparks", FX, "Sparks" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos + angle:Forward() * 5 )
		effectdata:SetAngles( angle )
		effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )
end
AddFXEmitterEffect( "muzzle", FX, "Muzzleflash" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos + angle:Forward() * 5 )
		effectdata:SetAngles( angle )
		effectdata:SetScale( 2 )
	util.Effect( "MuzzleEffect", effectdata )
end
AddFXEmitterEffect( "muzzlebig", FX, "Muzzleflash (Big)" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
	util.Effect( "BloodImpact", effectdata )
end
AddFXEmitterEffect( "bloodimpact", FX, "Blood Impact" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
		effectdata:SetNormal( angle:Forward() * 2 )
		effectdata:SetMagnitude( 1 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( 1 )
	util.Effect( "StriderBlood", effectdata )
end
AddFXEmitterEffect( "striderblood", FX, "Strider Blood" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
	util.Effect( "ShotgunShellEject", effectdata )
end
AddFXEmitterEffect( "shotgun shell", FX, "Shotgun Shell" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
	util.Effect( "RifleShellEject", effectdata )
end
AddFXEmitterEffect( "rifle shell", FX, "Rifle Shell" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
	util.Effect( "ShellEject", effectdata )
end
AddFXEmitterEffect( "pistol shell", FX, "Pistol Shell" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
		effectdata:SetNormal( angle:Forward() )
	util.Effect( "MetalSpark", effectdata )
end
AddFXEmitterEffect( "metalsparks", FX, "Metal Sparks" )

local function FX( pos, angle )
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetAngles( angle )
	util.Effect( "GlassImpact", effectdata )
end
AddFXEmitterEffect( "glassimpact", FX, "Glass Impact" )
