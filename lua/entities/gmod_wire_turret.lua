AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName     = "Wire Turret"
ENT.WireDebugName = "Turret"

if ( CLIENT ) then return end -- No more client

local NumEnabled = CreateConVar("wire_turret_numbullets_enabled", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or Disable the numbullets function of wire turrets")
local TracerEnabled = CreateConVar("wire_turret_tracer_enabled", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or disable the tracer per x bullet function of wire turrets")
local MinTurretDelay = CreateConVar("wire_turret_delay_minimum", 0.01, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set the minimum allowed value for wire turrets")

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:Wake()
	end

	-- Allocating internal values on initialize
	self.NextShot     = 0
	self.Firing       = false
	self.spreadvector = Vector()
	self.effectdata   = EffectData()
	self.attachmentPos = phys:WorldToLocal(self:GetAttachment(1).Pos)

	self.Inputs = WireLib.CreateSpecialInputs(self,
		{ "Fire", "Force", "Damage", "NumBullets", "Spread", "Delay", "Sound", "Tracer" },
		{ "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "STRING" })

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "HitEntity" }, { "ENTITY" })
end

function ENT:FireShot()

	if ( self.NextShot > CurTime() ) then return end

	self.NextShot = CurTime() + self.delay

	-- Make a sound if you want to.
	if ( self.sound ) then
		self:EmitSound( self.sound )
	end

	local shootOrigin, shootAngles
	local parent = self:GetParent()
	if parent:IsValid() then
		shootOrigin = self:LocalToWorld(self.attachmentPos)
		shootAngles = self:GetAngles()
	else
		local phys = self:GetPhysicsObject()
		shootOrigin = phys:LocalToWorld(self.attachmentPos)
		shootAngles = phys:GetAngles()
	end

	-- Shoot a bullet
	local bullet      = {}
	bullet.Num        = self.numbullets
	bullet.Src        = shootOrigin
	bullet.Dir        = shootAngles:Forward()
	bullet.Spread     = self.spreadvector
	bullet.Tracer     = self.tracernum
	bullet.TracerName = self.tracer
	bullet.Force      = self.force
	bullet.Damage     = self.damage
	bullet.Attacker   = self:GetPlayer()
	bullet.Callback   = function(attacker, traceres, cdamageinfo)
		WireLib.TriggerOutput(self, "HitEntity", traceres.Entity)
	end

	self:FireBullets( bullet )

	-- Make a muzzle flash
	self.effectdata:SetOrigin( shootOrigin )
	self.effectdata:SetAngles( shootAngles )
	self.effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", self.effectdata )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Think()
	BaseClass.Think( self )

	if ( self.Firing ) then
		self:FireShot()
	end

	self:NextThink( CurTime() )
	return true
end

local ValidTracers = {
	["Tracer"]                = true,
	["AR2Tracer"]             = true,
	["ToolTracer"]            = true,
	["GaussTracer"]           = true,
	["LaserTracer"]           = true,
	["StriderTracer"]         = true,
	["GunshipTracer"]         = true,
	["HelicopterTracer"]      = true,
	["AirboatGunTracer"]      = true,
	["AirboatGunHeavyTracer"] = true,
	[""]                      = true
}

function ENT:SetSound( sound )
	sound = string.Trim( tostring( sound or "" ) ) -- Remove whitespace ( manual )
	local check = string.find( sound, "[\"?]" ) -- Preventing client crashes
	self.sound = check == nil and sound ~= "" and sound or nil -- Apply the pattern check
end

function ENT:SetDelay( delay )
	self.delay = math.Clamp( delay, MinTurretDelay:GetFloat(), 2 )
end

function ENT:SetNumBullets( numbullets )
	self.numbullets = NumEnabled:GetBool() and math.Clamp( math.floor( numbullets ), 1, 10 ) or 1
end

function ENT:SetTracer( tracer )
	tracer = string.Trim(tracer)
	self.tracer = TracerEnabled:GetBool() and ValidTracers[tracer] and tracer or ""
end

function ENT:SetSpread( spread )
	self.spread = math.Clamp( spread, 0, 1 )
	self.spreadvector.x = self.spread
	self.spreadvector.y = self.spread
end

function ENT:SetDamage( damage )
	self.damage = math.Clamp( damage, 0, 100 )
end

function ENT:SetForce( force )
	self.force = math.Clamp( force, 0, 500 )
end

function ENT:SetTraceNum( tracernum )
	self.tracernum = TracerEnabled:GetBool() and math.Clamp( math.floor( tracernum ), 0, 15 ) or 0
end

function ENT:TriggerInput( iname, value )
	if (iname == "Fire") then
		self.Firing = value > 0
	elseif (iname == "Force") then
		self:SetForce( value )
	elseif (iname == "Damage") then
		self:SetDamage( value )
	elseif (iname == "NumBullets") then
		self:SetNumBullets( value )
	elseif (iname == "Spread") then
		self:SetSpread( value )
	elseif (iname == "Delay") then
		self:SetDelay( value )
	elseif (iname == "Sound") then
		self:SetSound( value )
	elseif (iname == "Tracer") then
		self:SetTracer( value )
	end
end

function ENT:Setup(delay, damage, force, sound, numbullets, spread, tracer, tracernum)
	self:SetForce(force)
	self:SetDelay(delay)
	self:SetSound(sound)
	self:SetDamage(damage)
	self:SetSpread(spread)
	self:SetTracer(tracer)
	self:SetTraceNum(tracernum)
	self:SetNumBullets(numbullets)
end

duplicator.RegisterEntityClass( "gmod_wire_turret", WireLib.MakeWireEnt, "Data", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "tracernum" )
