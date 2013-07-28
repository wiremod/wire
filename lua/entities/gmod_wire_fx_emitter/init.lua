
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

// wire debug and overlay crap.
ENT.WireDebugName = "Wire FX Emitter"
ENT.LastClear     = 0

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self:SetModel( "models/props_lab/tpplug.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self.Inputs = WireLib.CreateSpecialInputs( self, { "On", "Effect", "Delay", "Direction" }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR" } )

	self.datanstuff = {
		pos = Vector(0,0,0),
		dir = Vector(0,0,0),
		on = 0
	}
end

function ENT:Setup(delay, effect)
	self:SetDelay( delay )
	self:SetEffect( effect )
end

function ENT:TriggerInput( inputname, value, iter )
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

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	-- Old dupes stored this info here rather than as RegisterEntityClass vars
	if info.Effect then self:SetEffect(info.Effect) end
	if info.Delay then self:SetDelay(info.Delay) end
end

function MakeWireFXEmitter( ply, Pos, Ang, model, delay, effect )
	if ( !ply:CheckLimit( "wire_fx_emitters" ) ) then return nil end

	local wire_fx_emitter = ents.Create( "gmod_wire_fx_emitter" )
	if (!wire_fx_emitter:IsValid()) then return false end

	wire_fx_emitter:SetAngles( Ang )
	wire_fx_emitter:SetPos( Pos )
	wire_fx_emitter:SetModel(model or "models/props_lab/tpplug.mdl")
	wire_fx_emitter:Spawn()

	wire_fx_emitter:Setup( delay, effect )
	wire_fx_emitter:SetPlayer( ply )

	ply:AddCount( "wire_fx_emitters", wire_fx_emitter )
	ply:AddCleanup( "wire_fx_emitters", wire_fx_emitter )

	return wire_fx_emitter
end
duplicator.RegisterEntityClass( "gmod_wire_fx_emitter", MakeWireFXEmitter, "Pos", "Ang", "Model", "delay", "effect" )
