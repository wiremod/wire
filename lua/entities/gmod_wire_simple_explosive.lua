AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Simple Explosive"
ENT.WireDebugName = "Simple Explosive"

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

	self.NormInfo = ""
	self.DisabledByTimeUntil = CurTime()

	self.Inputs = Wire_CreateInputs(self, { "Detonate" })
end

function ENT:Setup( key, damage, removeafter, radius )
	self.key			= key
	self.damage			= math.Min(damage, 1500)
	self.removeafter	= removeafter
	self.radius			= math.Clamp(radius, 1, wire_explosive_range:GetFloat())
	self.Exploded		= false

	if (self.damage > 0) then
		self.NormInfo = "Damage: " .. math.floor(self.damage) .. "\nRadius: " .. math.floor(self.radius)
	else
		self.NormInfo = "Radius: " .. math.floor(self.radius)
	end

	self:ShowOutput()

end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:TriggerInput(iname, value)
	if (iname == "Detonate") then
		if (not self.Exploded) and ( math.abs(value) == self.key ) then
			self:Explode()
		elseif (value == 0) then
			self.Exploded = false
		end
	end
end

function ENT:Explode()

	if ( not self:IsValid() ) then return end
	if (self.Exploded) then return end
	if self.DisabledByTimeUntil > CurTime() then return end
	self.DisabledByTimeUntil = CurTime() + wire_explosive_delay:GetFloat()

	local ply = self:GetPlayer()
	if not IsValid(ply) then ply = self end

	if ( self.damage > 0 ) then
		util.BlastDamage( self, ply, self:GetPos(), self.radius, self.damage )
	end

	local effectdata = EffectData()
	 effectdata:SetOrigin( self:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )

	self.Exploded = true
	self:ShowOutput()

	if ( self.removeafter ) then
		self:Remove()
		return
	end
end

function ENT:ShowOutput()
	if (self.Exploded) then
		self:SetOverlayText("Exploded\n"..self.NormInfo)
	else
		self:SetOverlayText("Explosive\n"..self.NormInfo)
	end
end

duplicator.RegisterEntityClass( "gmod_wire_simple_explosive", WireLib.MakeWireEnt, "Data", "key", "damage", "removeafter", "radius" )
