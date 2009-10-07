
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Simple Explosive"
ENT.OverlayDelay = 0.5

--[[---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------]]
function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self.NormInfo = ""

	self.Inputs = Wire_CreateInputs(self.Entity, { "Detonate" })

end

--[[---------------------------------------------------------
   Name: Setup
   Desc: does a whole lot of setting up
---------------------------------------------------------]]
function ENT:Setup( damage, delaytime, removeafter, doblastdamage, radius, nocollide )

	self.Damage			= damage
	self.Radius			= math.max(radius, 1)
	self.NoCollide		= nocollide
	self.DoBlastDamage	= doblastdamage
	self.Exploded		= false
	self.Removeafter		= removeafter

	if (self.NoCollide) then
		self.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	else
		self.Entity:SetCollisionGroup(COLLISION_GROUP_NONE)
	end

	self.NormInfo = ""
	if (self.DoBlastDamage) then
		self.NormInfo = "Damage: " .. math.floor(self.Damage) .. "\nRadius: " .. math.floor(self.Radius)
	else
		self.NormInfo = "Radius: " .. math.floor(self.Radius)
	end

	self:ShowOutput()

end


--[[---------------------------------------------------------
   Name: OnTakeDamage
   Desc: Entity takes damage
---------------------------------------------------------]]
function ENT:OnTakeDamage( dmginfo )
	self.Entity:TakePhysicsDamage( dmginfo )
end



--[[---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------]]
function ENT:TriggerInput(iname, value)
	if (iname == "Detonate") then
		if (!self.Exploded) and ( math.abs(value) == self.key ) then
			self:Explode()
		elseif (value == 0) then
			self.Exploded = false
		end
	end
end

--[[---------------------------------------------------------
   Name: Explode
   Desc: is one needed?
---------------------------------------------------------]]
function ENT:Explode( )

	if ( !self.Entity:IsValid() ) then return end
	if (self.Exploded) then return end

	ply = self:GetPlayer() or self.Entity

	if ( self.DoBlastDamage ) then
		util.BlastDamage( self.Entity, ply, self.Entity:GetPos(), self.Radius, self.Damage )
	end

	local effectdata = EffectData()
	 effectdata:SetOrigin( self.Entity:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )

	self.Exploded = true
	self:ShowOutput()

	if ( self.Removeafter ) then
		self.Entity:Remove()
		return
	end

end

--[[---------------------------------------------------------
   Name: ShowOutput
   Desc: don't foreget to call this when changes happen
---------------------------------------------------------]]
function ENT:ShowOutput( )
	local txt = ""
	if (self.Exploded) then
		txt = "Exploded\n"..self.NormInfo
	else
		txt = "Explosive\n"..self.NormInfo
	end
	self:SetOverlayText(txt)
end


function MakeWireSimpleExplosive(pl, Pos, Ang, model, key, damage, removeafter, doblastdamage, radius, nocollide )
	if ( !pl:CheckLimit( "wire_simple_explosive" ) ) then return nil end

	damage = math.Min(damage, 1500)
	radius = math.Min(radius, 10000)

	local explosive = ents.Create( "gmod_wire_simple_explosive" )

	explosive:SetModel( model )
	explosive:SetPos( Pos )
	explosive:SetAngles( Ang )
	explosive:Spawn()
	explosive:Activate()

	explosive:Setup( damage, delaytime, removeafter, doblastdamage, radius, nocollide )
	explosive:SetPlayer( pl )

	local ttable = {
		pl	= pl,
		nocollide = nocollide,
		key = key,
		damage = damage,
		removeafter = removeafter,
		doblastdamage = doblastdamage,
		radius = radius
	}
	table.Merge( explosive:GetTable(), ttable )

	pl:AddCount( "wire_simple_explosive", explosive )
	pl:AddCleanup( "gmod_wire_simple_explosive", explosive )

	return explosive
end
duplicator.RegisterEntityClass( "gmod_wire_simple_explosive", MakeWireSimpleExplosive, "Pos", "Ang", "Model", "key", "damage", "removeafter", "doblastdamage", "radius", "nocollide" )
