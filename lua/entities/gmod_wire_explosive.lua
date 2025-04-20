AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Explosive"
ENT.WireDebugName 	= "Explosive"

if CLIENT then return end -- No more client

local wire_explosive_delay = CreateConVar( "wire_explosive_delay", 0.2, FCVAR_ARCHIVE )
local wire_explosive_range = CreateConVar( "wire_explosive_range", 512, FCVAR_ARCHIVE )

function ENT:Initialize()

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self.exploding = false
	self.reloading = false
	self.NormInfo = ""
	self.count = 0
	self.ExplodeTime = 0
	self.ReloadTime = 0
	self.CountTime = 0

	self.Inputs = Wire_CreateInputs(self, { "Detonate", "ResetHealth" })

	self:SetMaxHealth(100)
	self:SetHealth(100)
	self.Outputs = Wire_CreateOutputs(self, { "Health" })
end

function ENT:TriggerInput(iname, value)
	if (iname == "Detonate") then
		if ( not self.exploding and not self.reloading ) then
			if ( math.abs(value) == self.key ) then
				self:Trigger()
			end
		end
	elseif (iname == "ResetHealth") then
		self:ResetHealth()
	end
end

function ENT:Setup( key, damage, delaytime, removeafter, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero )

	self.key = key
	self.Damage = math.Clamp( damage, 0, 1500 )
	self.Delaytime = delaytime
	self.Removeafter = removeafter
	self.Radius = math.Clamp(radius, 1, wire_explosive_range:GetFloat())
	self.Affectother = affectother
	self.Notaffected = notaffected
	self.Delayreloadtime = delayreloadtime

	self.BulletProof = bulletproof
	self.ExplosionProof = explosionproof
	self.FallProof = fallproof

	self.ExplodeAtZero = explodeatzero
	self.ResetAtExplode = resetatexplode

	self.FireEffect = fireeffect
	self.ColorEffect = coloreffect
	self.InvisibleAtZero = invisibleatzero

	self:SetMaxHealth(maxhealth)
	self:ResetHealth()

	--[[
	self:SetHealth(maxhealth)
	Wire_TriggerOutput(self, "Health", maxhealth)

	reset everthing back and try to stop exploding
	self.exploding = false
	self.reloading = false
	self.count = 0
	self:Extinguish()
	if (self.ColorEffect) then self:SetColor(Color(255, 255, 255, 255)) end
	]]

	self.NormInfo = ""
	if (self.Damage > 0) then self.NormInfo = self.NormInfo.."Damage: "..self.Damage end
	if (self.Radius > 0 or self.Delaytime > 0) then self.NormInfo = self.NormInfo.."\n" end
	if (self.Radius > 0 ) then self.NormInfo = self.NormInfo.." Rad: "..self.Radius end
	if (self.Delaytime > 0) then self.NormInfo = self.NormInfo.." Delay: "..self.Delaytime end

	self:ShowOutput()

	local ttable = {
		key = key,
		damage = damage,
		removeafter = removeafter,
		delaytime = delaytime,
		radius = radius,
		affectother = affectother,
		notaffected = notaffected,
		delayreloadtime = delayreloadtime,
		maxhealth = maxhealth,
		bulletproof = bulletproof,
		explosionproof = explosionproof,
		fallproof = fallproof,
		explodeatzero = explodeatzero,
		resetatexplode = resetatexplode,
		fireeffect = fireeffect,
		coloreffect = coloreffect,
		invisibleatzero = invisibleatzero
	}
	table.Merge( self:GetTable(), ttable )
end

function ENT:ResetHealth()
	self:SetHealth( self:GetMaxHealth() )
	Wire_TriggerOutput(self, "Health", self:GetMaxHealth())

	-- put the fires out and try to stop exploding
	self.exploding = false
	self.reloading = false
	self.count = 0
	self:Extinguish()

	if (self.ColorEffect) then self:SetColor(Color(255, 255, 255, 255)) end

	self:SetNoDraw( false )

	self:ShowOutput()
end

function ENT:OnTakeDamage( dmginfo )

	local inflictor = dmginfo:GetInflictor()
	if inflictor:IsValid() and inflictor:GetClass() == "gmod_wire_explosive" and not self.Affectother then return end

	if ( not self.Notaffected ) then self:TakePhysicsDamage( dmginfo ) end

	if (dmginfo:IsBulletDamage() and self.BulletProof) or
		(dmginfo:IsExplosionDamage() and self.ExplosionProof) or
		(dmginfo:IsFallDamage() and self.FallProof) then return end --fix fall damage, it doesn't happen

	if (self:Health() > 0) then --don't need to beat a dead horse
		local dammage = dmginfo:GetDamage()
		local h = self:Health() - dammage
		if (h < 0) then h = 0 end
		self:SetHealth(h)
		Wire_TriggerOutput(self, "Health", h)
		self:ShowOutput()
		if (self.ColorEffect) then
			local c = h == 0 and 0 or 255 * (h / self:GetMaxHealth())
			self:SetColor(Color(255, c, c, 255))
		end
		if (h == 0) then
			if (self.ExplodeAtZero) then self:Trigger() end
		end
	end

end

-- Start exploding
function ENT:Trigger()
	if ( self.Delaytime > 0 ) then
		self.ExplodeTime = CurTime() + self.Delaytime
		if (self.FireEffect) then self:Ignite( self.Delaytime + 3, 0 ) end
	end
	self.exploding = true
	-- Force reset of counter
	self.CountTime = 0
end

function ENT:Think()
	BaseClass.Think(self)

	if (self.exploding) then
		if (self.ExplodeTime < CurTime()) then
			self:Explode()
		end
	elseif (self.reloading) then
		if (self.ReloadTime < CurTime()) then
			self.reloading = false
			if (self.ResetAtExplode) then
				self:ResetHealth()
			else
				self:ShowOutput()
			end
		end
	end

	-- Do count check to ensure that
	-- ShowOutput() is called every second
	-- when exploding or reloading
	if ((self.CountTime or 0) < CurTime()) then
		local temptime = 0
		if (self.exploding) then
			temptime = self.ExplodeTime
		elseif (self.reloading) then
			temptime = self.ReloadTime
		end

		if (temptime > 0) then
			self.count = math.ceil(temptime - CurTime())
			self:ShowOutput()
		end

		self.CountTime = CurTime() + 1
	end

	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:Explode()

	if ( not self:IsValid() ) then return end

	self:Extinguish()

	if (not self.exploding) then return end --why are we exploding if we shouldn't be

	local ply = self:GetPlayer()
	if not IsValid(ply) then ply = self end

	if (self.InvisibleAtZero) then
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:SetNoDraw( true )
		self:SetColor(Color(255, 255, 255, 0))
	end

	if ( self.Damage > 0 ) then
		util.BlastDamage( self, ply, self:GetPos(), self.Radius, self.Damage )
	end

	local effectdata = EffectData()
	 effectdata:SetOrigin( self:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )

	if ( self.Removeafter ) then
		self:Remove()
		return
	end

	self.exploding = false

	self.reloading = true
	self.ReloadTime = CurTime() + math.max(wire_explosive_delay:GetFloat(), self.Delayreloadtime)
	-- Force reset of counter
	self.CountTime = 0
	self:ShowOutput()
end

-- don't foreget to call this when changes happen
function ENT:ShowOutput()
	local txt = ""
	if (self.reloading and self.Delayreloadtime > 0) then
		txt = "Rearming... "..self.count
		if (self.ColorEffect and not self.InvisibleAtZero) then
			local c = 255 * ((self.Delayreloadtime - self.count) / self.Delayreloadtime)
			self:SetColor(Color(255, c, c, 255))
		end
		if (self.InvisibleAtZero) then
			self:SetNoDraw( false )
			self:SetColor(Color(255, 255, 255, 255 * ((self.Delayreloadtime - self.count) / self.Delayreloadtime)))
			self:SetRenderMode(RENDERMODE_TRANSALPHA)
		end
	elseif (self.exploding) then
		txt = "Triggered... "..self.count
	else
		txt = self.NormInfo.."\nHealth: "..self:Health().."/"..self:GetMaxHealth()
	end
	self:SetOverlayText(txt)
end

duplicator.RegisterEntityClass( "gmod_wire_explosive", WireLib.MakeWireEnt, "Data", "key", "damage", "delaytime", "removeafter", "radius", "affectother", "notaffected", "delayreloadtime", "maxhealth", "bulletproof", "explosionproof", "fallproof", "explodeatzero", "resetatexplode", "fireeffect", "coloreffect", "invisibleatzero" )
