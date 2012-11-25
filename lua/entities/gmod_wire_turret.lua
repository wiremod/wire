AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Turret"
ENT.WireDebugName 	= "Turret"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self.Firing 	= false
	self.NextShot 	= 0

	self.Inputs = Wire_CreateInputs(self, { "Fire" })
end

function ENT:SetDamage( f )
	self.Damage = f
end
function ENT:GetDamage()
	return self.Damage
end

function ENT:SetDelay( f )
	self.Delay = f
end
function ENT:GetDelay()
	return self.Delay
end

function ENT:SetForce( f )
	self.Force = f
end
function ENT:GetForce()
	return self.Force
end

function ENT:SetNumBullets( f )
	self.NumBullets = f
end
function ENT:GetNumBullets( f )
	return self.NumBullets
end

function ENT:SetSpread( f )
	self.Spread = Vector( f, f, 0 )
end
function ENT:GetSpread()
	return self.Spread
end

function ENT:SetSound( str )
	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(str, BlockedChars) ) then
		self.Sound = ""
	else
		self.Sound = str
	end
end
function ENT:GetSound()
	return self.Sound
end

local ValidTracers = {
	["Tracer"]=true,
	["AR2Tracer"]=true,
	["AirboatGunHeavyTracer"]=true,
	["LaserTracer"]=true,
	[""]=true,
}
function ENT:SetTracer( trcer )
	self.Tracer = trcer

	if !ValidTracers[string.Trim(trcer)] and !ValidTracers[trcer] then
		self.Tracer = ""
	end
end
function ENT:GetTracer()
	return self.Tracer
end

function ENT:SetTracerNum( trcernum )
	self.TracerNum = trcernum or 1
end
function ENT:GetTracerNum()
	return self.TracerNum
end


function ENT:FireShot()

	if ( self.NextShot > CurTime() ) then return end

	self.NextShot = CurTime() + self.Delay

	-- Make a sound if you want to.
	if ( self:GetSound() ) then
		self:EmitSound( self:GetSound() )
	end

	-- Get the muzzle attachment (this is pretty much always 1)
	local Attachment = self:GetAttachment( 1 )

	-- Get the shot angles and stuff.
	local shootOrigin = Attachment.Pos
	local shootAngles = self:GetAngles()
	local shootDir = shootAngles:Forward()

	-- Shoot a bullet
	local bullet = {}
		bullet.Num 			= self:GetNumBullets()
		bullet.Src 			= shootOrigin
		bullet.Dir 			= shootDir
		bullet.Spread 		= self:GetSpread()
		bullet.Tracer		= self:GetTracerNum()
		bullet.TracerName 	= self:GetTracer()
		bullet.Force		= self:GetForce()
		bullet.Damage		= self:GetDamage()
		bullet.Attacker 	= self:GetPlayer()
	self:FireBullets( bullet )

	-- Make a muzzle flash
	local effectdata = EffectData()
		effectdata:SetOrigin( shootOrigin )
		effectdata:SetAngles( shootAngles )
		effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )

end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Think()
	self.BaseClass.Think(self)

	if( self.Firing ) then
		self:FireShot()
	end

	self:NextThink(CurTime())
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		self.Firing = value > 0
	end
end

function MakeWireTurret( ply, Pos, Ang, model, delay, damage, force, sound, numbullets, spread, tracer, tracernum, nocollide )

	if not ply:CheckLimit( "wire_turrets" ) then return nil end

	local turret = ents.Create( "gmod_wire_turret" )
	if not turret:IsValid() then return false end

	turret:SetPos( Pos )
	if Ang then turret:SetAngles( Ang ) end

	function CorrectModel()
		local TurretModels = {
		"models/weapons/w_smg1.mdl",
		"models/weapons/w_smg_mp5.mdl",
		"models/weapons/w_smg_mac10.mdl",
		"models/weapons/w_rif_m4a1.mdl",
		"models/weapons/w_357.mdl",
		"models/weapons/w_shot_m3super90.mdl"
		}
		local found = false
		for k, v in pairs(TurretModels) do
			if model == TurretModels[k] then found = true end
		end
		return found
	end

	if CorrectModel() then
		turret:SetModel( model )
	else
		turret:SetModel( "models/weapons/w_smg1.mdl" )
	end
	turret:Spawn()

	-- Clamp stuff in multiplayer.. because people are idiots
	if not game.SinglePlayer() then
		delay		= math.Clamp( delay, 0.05, 3600 )
		numbullets	= 1
		force		= math.Clamp( force, 0.01, 100 )
		spread		= math.Clamp( spread, 0, 1 )
		damage		= math.Clamp( damage, 0, 500 )
		tracernum	= 1
	end

	turret:SetDamage( damage )
	turret:SetPlayer( ply )

	turret:SetSpread( spread )
	turret:SetForce( force )
	turret:SetSound( sound )
	turret:SetTracer( tracer )
	turret:SetTracerNum( tracernum or 1 )

	turret:SetNumBullets( numbullets )

	turret:SetDelay( delay )

	if nocollide == true then turret:GetPhysicsObject():EnableCollisions( false ) end

	local ttable = {
		delay 		= delay,
		damage 		= damage,
		pl			= ply,
		nocollide 	= nocollide,
		force		= force,
		sound		= sound,
		spread		= spread,
		numbullets	= numbullets,
		tracer		= tracer
	}
	table.Merge( turret:GetTable(), ttable )

	ply:AddCount( "wire_turrets", turret )
	ply:AddCleanup( "wire_turrets", turret )

	return turret
end
duplicator.RegisterEntityClass( "gmod_wire_turret", MakeWireTurret, "Pos", "Ang", "Model", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "tracernum", "nocollide" )
