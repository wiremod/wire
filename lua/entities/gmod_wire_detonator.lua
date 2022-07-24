AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Detonator"
ENT.WireDebugName = "Detonator"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Trigger" } )
	self.Trigger = 0
	self.damage = 0
end

function ENT:TriggerInput(iname, value)
	if iname == "Trigger" then
		self:ShowOutput( value )
	end
end

function ENT:Setup(damage)
	self.damage = damage
	self:ShowOutput( 0 )
end

function ENT:ShowOutput( Trigger )
	if Trigger ~= self.Trigger then
		self:SetOverlayText( self.damage .. " = " .. Trigger )
		self.Trigger = Trigger
		if Trigger > 0 then
			self:DoDamage()
		end
	end
end

function ENT:DoDamage()
	if self.target and self.target:IsValid() then
		self.target:TakeDamage(self.damage, self:GetPlayer(), self)
	end

	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )
	self:Remove()
end

-- Dupe info functions added by TheApathetic
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if self.target and self.target:IsValid() then
		info.target = self.target:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.target = GetEntByID(info.target)
end

duplicator.RegisterEntityClass("gmod_wire_detonator", WireLib.MakeWireEnt, "Data", "damage")
