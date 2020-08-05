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

	self.Inputs = WireLib.CreateSpecialInputs(self,
		{ "Fire", "Force", "Damage", "NumBullets", "Spread", "Delay", "Sound", "Tracer" },
		{ "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "STRING" })

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "HitEntity" }, { "ENTITY" })
end

function ENT:FireShot()

	if ( self.NextShot > CurTime() ) then return end

	self.NextShot = CurTime() + self.delay

	-- Make a sound if you want to.
	if self.sound then
		self:EmitSound(self.sound)
	end

	-- Get the muzzle attachment (this is pretty much always 1)
	local Attachment = self:GetAttachment( 1 )

	-- Get the shot angles and stuff.
	local shootOrigin = Attachment.Pos + self:GetVelocity() * engine.TickInterval()
	local shootAngles = self:GetAngles()

	-- Shoot a bullet
	local bullet = {}
		bullet.Num 			= self.numbullets
		bullet.Src 			= shootOrigin
		bullet.Dir 			= shootAngles:Forward()
		bullet.Spread 		= self.spreadvector
		bullet.Tracer		= self.tracernum
		bullet.TracerName 	= self.tracer
		bullet.Force		= self.force
		bullet.Damage		= self.damage
		bullet.Attacker 	= self:GetPlayer()
		bullet.Callback = function(attacker, traceres, cdamageinfo)
			WireLib.TriggerOutput(self, "HitEntity", traceres.Entity)
		end
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
	BaseClass.Think(self)

	if( self.Firing ) then
		self:FireShot()
	end

	self:NextThink(CurTime())
	return true
end

local ValidTracers = {
	["Tracer"]=true,
	["AR2Tracer"]=true,
	["AirboatGunHeavyTracer"]=true,
	["LaserTracer"]=true,
	[""]=true,
}

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		self.Firing = value > 0
	elseif (iname == "Force") then
		self.force = math.Clamp(value,0,500)
	elseif (iname == "Damage") then
		self.damage = math.Clamp(value,0,100)
	elseif (iname == "NumBullets") then
		local gsp = game.SinglePlayer()
		value = math.floor(math.max(1,value))
		self.numbullets = gsp and value or math.Min(value,10)
	elseif (iname == "Spread") then
		self.spread = math.Clamp(value,0,1)
		self.spreadvector.x = self.spread
		self.spreadvector.y = self.spread
	elseif (iname == "Delay") then
		local gsp = game.SinglePlayer()
		local lim = 0.01 * (gsp and 1 or 5)
		self.delay = math.Clamp(value,lim,1)
	elseif (iname == "Sound") then
		self.sound = string.find(value, "[\"?]") and "" or value
	elseif (iname == "Tracer") then
		local tr = string.Trim(value)
		self.tracer = ValidTracers[tr] and tr or ""
	end
end

function ENT:Setup(delay, damage, force, sound, numbullets, spread, tracer, tracernum)
	local gsp, tr = game.SinglePlayer(), string.Trim(tracer)
	self.delay = gsp and delay or math.max(delay,0.05) -- clamp delay if it's not single player
	self.damage = damage
	self.force = force
	self.sound = string.find(sound, "[\"?]") and "" or sound -- Preventing client crashes
	self.numbullets = gsp and numbullets or math.Clamp( numbullets, 1, 10 ) -- clamp num bullets if it's not single player
	self.spread = spread -- for duplication
	self.spreadvector = Vector(spread,spread,0)
	self.tracer = ValidTracers[tr] and tr or ""
	self.tracernum = tracernum or 1
end

duplicator.RegisterEntityClass( "gmod_wire_turret", WireLib.MakeWireEnt, "Data", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "tracernum" )
