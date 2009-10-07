
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

// wire debug and overlay crap.
ENT.WireDebugName = "Wire FX Emitter"
ENT.OverlayDelay  = 0
ENT.LastClear     = 0

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self.Entity:SetModel( "models/props_lab/tpplug.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Entity:DrawShadow( false )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self.Inputs = WireLib.CreateSpecialInputs( self.Entity, { "On", "Effect", "Delay", "Direction" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR" } )
	self:SetOverlayText( "Wire FX Emitter" )

	self.datanstuff = {
		pos = Vector(0,0,0),
		dir = Vector(0,0,0),
		delay = 0.05,
		effect = 0,
		on = 0
	}
end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------
function ENT:OnTakeDamage( dmginfo )
	self.Entity:TakePhysicsDamage( dmginfo )
end
*/

// trigger input
function ENT:TriggerInput( inputname, value, iter )
	// store values.
	if(not value) then
		if ( inputname == "On" ) then
			self:SetOn(0)
		end
		return
	end
	if (inputname == "Direction") then
		value = value:GetNormal()
		self:SetFXDir(value)
	elseif (inputname == "Effect")  then
		value = value - value % 1
		if (value < 1) then
			value = 1
		elseif (value > self.fxcount) then
			value=self.fxcount
		end
		self:SetEffect( value )
	elseif ( inputname == "On" ) then
		if value ~= 0 then
			self:SetOn(1)
		else
			self:SetOn(0)
		end
	elseif ( inputname == "Delay" ) then
		if (value < 0.05) then
			value=0.05
		elseif (value > 20) then
			value=20
		end
		self:SetDelay(value)
	--elseif (inputname == "Position") then -- removed for excessive mingability
	--	self:SetFXPos(value)
	end
end

/*---------------------------------------------------------
--Duplicator support
---------------------------------------------------------*/
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	info.Effect = self:GetEffect()
	info.Delay = self:GetDelay()
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	self:SetEffect(info.Effect)
	self:SetDelay(info.Delay)
end
