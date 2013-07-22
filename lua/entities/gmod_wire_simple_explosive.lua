AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Simple Explosive"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self.NormInfo = ""

	self.Inputs = Wire_CreateInputs(self, { "Detonate" })
end

function ENT:Setup( key, damage, removeafter, radius, nocollide )
	self.key			= key
	self.damage			= math.Min(damage, 1500)
	self.removeafter	= removeafter
	self.radius			= math.Clamp(radius, 1, 10000)
	self.nocollide		= nocollide
	self.Exploded		= false

	if (self.nocollide) then
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	else
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	end

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
		if (!self.Exploded) and ( math.abs(value) == self.key ) then
			self:Explode()
		elseif (value == 0) then
			self.Exploded = false
		end
	end
end

function ENT:Explode( )

	if ( !self:IsValid() ) then return end
	if (self.Exploded) then return end

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

function ENT:ShowOutput( )
	if (self.Exploded) then
		self:SetOverlayText("Exploded\n"..self.NormInfo)
	else
		self:SetOverlayText("Explosive\n"..self.NormInfo)
	end
end

function MakeWireSimpleExplosive(pl, Pos, Ang, model, key, damage, removeafter, radius, nocollide )
	if ( !pl:CheckLimit( "wire_simple_explosives" ) ) then return nil end
	local explosive = ents.Create( "gmod_wire_simple_explosive" )

	explosive:SetModel( model )
	explosive:SetPos( Pos )
	explosive:SetAngles( Ang )
	explosive:Spawn()
	explosive:Activate()

	explosive:Setup( key, damage, removeafter, radius, nocollide )
	explosive:SetPlayer( pl )
	explosive.pl = pl

	pl:AddCount( "wire_simple_explosive", explosive )
	pl:AddCleanup( "gmod_wire_simple_explosive", explosive )

	return explosive
end
duplicator.RegisterEntityClass( "gmod_wire_simple_explosive", MakeWireSimpleExplosive, "Pos", "Ang", "Model", "key", "damage", "removeafter", "radius", "nocollide" )
