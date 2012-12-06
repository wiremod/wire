AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Detonator"
ENT.RenderGroup		= RENDERGROUP_BOTH
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
	if self.target and self.target:IsValid() and self.target:Health() > 0 then
		if self.target:Health() <= self.damage then
			self.target:SetHealth(0)
			self.target:Fire( "break", "", 0 )
			self.target:Fire( "kill", "", 0.2 )
		else
			self.target:SetHealth( self.target:Health() - self.damage )
		end
	end

	local effectdata = EffectData()
	effectdata:SetOrigin( self:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )
	self:Remove()
end

-- Dupe info functions added by TheApathetic
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if self.target and self.target:IsValid() then
		info.target = self.target:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.target then
		local target = GetEntByID(info.target)
		if not target then
			target = ents.GetByIndex(info.target)
		end
		self.target = target
	end
end


-- "target" is now handled by TOOL:LeftClick() for STool-spawned
-- detonators and ENT:Build/ApplyDupeInfo() for duplicated ones
-- It's done this way because MakeWireDetonator() cannot distinguish whether
-- detonator was made by the STool or the duplicator; the duplicator-made
-- detonator tries to reference a non-existent target (TheApathetic)
function MakeWireDetonator(pl, Pos, Ang, model, damage, nocollide, frozen)
	if not pl:CheckLimit( "wire_detonators" ) then return false end

	local wire_detonator = ents.Create("gmod_wire_detonator")
	if not wire_detonator:IsValid() then return false end
		wire_detonator:SetAngles(Ang)
		wire_detonator:SetPos(Pos)
		wire_detonator:SetModel(model)
	wire_detonator:Spawn()

	wire_detonator:Setup(damage)
	wire_detonator:SetPlayer(pl)

	if nocollide == true then wire_detonator:GetPhysicsObject():EnableCollisions(false) end
	if wire_detonator:GetPhysicsObject():IsValid() then
		local Phys = wire_detonator:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	local ttable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_detonator, ttable)

	pl:AddCount("wire_detonators", wire_detonator)
	pl:AddCleanup("gmod_wire_detonator", wire_detonator)

	return wire_detonator
end

duplicator.RegisterEntityClass("gmod_wire_detonator", MakeWireDetonator, "Pos", "Ang", "Model", "damage", "nocollide", "frozen")

