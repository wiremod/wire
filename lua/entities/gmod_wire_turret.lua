AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Turret"
ENT.WireDebugName = "Turret"

if CLIENT then return end

local num_enabled = CreateConVar("wire_turret_numbullets_enabled", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or Disable the numbullets function of wire turrets")
local tracer_enabled = CreateConVar("wire_turret_tracer_enabled", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable or disable the tracer per x bullet function of wire turrets")
local min_delay = CreateConVar("wire_turret_delay_minimum", 0.01, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Set the minimum allowed value for wire turrets")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
	self:PhysWake()

	self.NextShoot = 0
	self.Firing = false
	self.BulletTable = {Num = 1, Spread = Vector(0, 0, 0), Tracer = 1, TracerName = "Tracer", Force = 0, Damage = 0, Inflictor = self }
	self.BulletCallback = function(attacker, trace, dmg) WireLib.TriggerOutput(self, "Bullet", trace) WireLib.TriggerOutput(self, "HitEntity", trace.Entity) end

	-- Not all entities have an 1 attachment
	local attachment = self:GetAttachment(1)
	self.attachment = attachment and self:WorldToLocal(attachment.Pos) or Vector(0, 0, 0)

	WireLib.CreateInputs(self, { "Fire (Automatic fire)", "Shoot (Single shoot)", "Force", "Damage", "NumBullets", "Spread", "Delay", "Sound [STRING]", "Tracer [STRING]" })
	WireLib.CreateOutputs(self, { "HitEntity [ENTITY]", "Bullet [RANGER]" })
end

function ENT:FireShoot()
	local curtime = CurTime()
	local tab = self:GetTable()

	if tab.NextShoot > curtime then
		return
	end

	if tab.sound then
		self:EmitSound(tab.sound)
	end

	local origin = self:LocalToWorld(tab.attachment)
	local angles = self:GetAngles()
	local outputs = tab.Outputs

	local bullet = tab.BulletTable
	bullet.Src = origin
	bullet.Dir = angles:Forward()
	bullet.Attacker = tab.GetPlayer(self)
	bullet.Callback = (#outputs["HitEntity"].Connected > 0 or #outputs["Bullet"].Connected > 0) and tab.BulletCallback or nil
	tab.NextShoot = curtime + tab.delay
	self:FireBullets(bullet, true)

	local effect = EffectData()
	effect:SetOrigin(origin)
	effect:SetAngles(angles)
	effect:SetScale(1)
	util.Effect("MuzzleEffect", effect)
end

function ENT:OnTakeDamage(dmg)
	self:TakePhysicsDamage(dmg)
end

function ENT:Think()
	BaseClass.Think(self)

	local tab = self:GetTable()

	if tab.Firing then
		tab.FireShoot(self)
	end

	self:NextThink(CurTime())
	return true
end

local valid_tracers = {
	[""] = true,
	["AR2Tracer"] = true,
	["AirboatGunHeavyTracer"] = true,
	["AirboatGunTracer"] = true,
	["HelicopterTracer"] = true,
	["LaserTracer"] = true,
	["ToolTracer"] = true,
	["Tracer"] = true
}

function ENT:SetSound(path)
	self.sound = path and WireLib.SoundExists(path)
end

function ENT:SetDelay(delay)
	self.delay = math.max(delay, min_delay:GetFloat())
end

function ENT:SetNumBullets(num_bullets)
	self.numbullets = num_enabled:GetBool() and math.Clamp(math.floor(num_bullets), 1, 10) or 1
	self.BulletTable.Num = self.numbullets
end

function ENT:SetTracer(tracer)
	tracer = WireLib.Trim(tracer)
	self.tracer = tracer_enabled:GetBool() and valid_tracers[tracer] and tracer or ""
	self.BulletTable.TracerName = self.tracer
end

function ENT:SetSpread(spread)
	self.spread = math.Clamp(spread, 0, 5)
	self.BulletTable.Spread:SetUnpacked(self.spread, self.spread, 0)
end

function ENT:SetDamage(damage)
	self.damage = math.Clamp(damage, 0, 100)
	self.BulletTable.Damage = self.damage
end

function ENT:SetForce(force)
	self.force = math.Clamp(force, 0, 5000)
	self.BulletTable.Force = self.force
end

function ENT:SetTraceNum(tracer_num)
	self.tracernum = tracer_enabled:GetBool() and math.Clamp(math.floor(tracer_num), 0, 15) or 0
	self.BulletTable.Tracer = self.tracernum
end

function ENT:TriggerInput(name, value)
	if name == "Fire" then
		self.Firing = value > 0
	elseif name == "Shoot" and value > 0 then
		self:FireShoot()
	elseif name == "Force" then
		self:SetForce(value)
	elseif name == "Damage" then
		self:SetDamage(value)
	elseif name == "NumBullets" then
		self:SetNumBullets(value)
	elseif name == "Spread" then
		self:SetSpread(value)
	elseif name == "Delay" then
		self:SetDelay(value)
	elseif name == "Sound" then
		self:SetSound(value)
	elseif name == "Tracer" then
		self:SetTracer(value)
	end
end

function ENT:Setup(delay, damage, force, sound, numbullets, spread, tracer, tracernum)
	self:SetForce(force)
	self:SetDelay(delay)
	self:SetSound(sound)
	self:SetDamage(damage)
	self:SetSpread(spread or 0.1)
	self:SetTracer(tracer)
	self:SetTraceNum(tracernum or 0)
	self:SetNumBullets(numbullets)
	self.NextShoot = 0
end

duplicator.RegisterEntityClass("gmod_wire_turret", WireLib.MakeWireEnt, "Data", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "tracernum")
