
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Input"
ENT.OverlayDelay = 0

local function keyname(keygroup)
	return tostring(keygroup) -- TODO figure out how to get the name of a key (the old way wasn't working)
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	// Used to keep track of numpad.OnUp/Down returns
	// Fixes bug where player cannot change numpad key (TheApathetic)
	self.OnUpImpulse = nil
	self.OnDownImpulse = nil

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup(keygroup, toggle, value_off, value_on)
	self.keygroup = keygroup
	self.toggle = (toggle == 1 || toggle == true)
	self.value_off = value_off
	self.value_on = value_on
	self.Value = value_off

	if (self.OnUpImpulse) then
		numpad.Remove(self.OnUpImpulse)
		numpad.Remove(self.OnDownImpulse)
	end

	local pl = self:GetPlayer()
	self.OnDownImpulse = numpad.OnDown( pl, keygroup, "WireInput_On", self, 1 )
	self.OnUpImpulse = numpad.OnUp( pl, keygroup, "WireInput_Off", self, 1 )


	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self, "Out", self.value_off)
end

function ENT:InputActivate( mul )
	if ( self.toggle ) then
		return self:Switch( !self.On, mul )
	end

	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if ( self.toggle ) then return true end

	return self:Switch( false, mul )
end

function ENT:Switch( on, mul )
	if (!self:IsValid()) then return false end

	self.On = on

	if (on) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
	end

	Wire_TriggerOutput(self, "Out", self.Value)

	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Numpad Input ("..keyname(self.keygroup)..")\n(" .. tostring(self.value_off) .. " - " .. tostring(self.value_on) .. ") = " .. tostring(value) )
end

local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireInput_On", On )
numpad.Register( "WireInput_Off", Off )

function MakeWireInput( pl, Pos, Ang, model, keygroup, toggle, value_off, value_on, frozen )
	if (pl!=nil) then if ( !pl:CheckLimit( "wire_inputs" ) ) then return false end end

	local wire_input = ents.Create( "gmod_wire_input" )
	if (!wire_input:IsValid()) then return false end

	wire_input:SetAngles( Ang )
	wire_input:SetPos( Pos )
	wire_input:SetModel( Model(model or "models/jaanus/wiretool/wiretool_input.mdl") )
	wire_input:Spawn()

	if wire_input:GetPhysicsObject():IsValid() then
		wire_input:GetPhysicsObject():EnableMotion(!frozen)
	end

	wire_input:SetPlayer( pl )
	wire_input:Setup( keygroup, toggle, value_off, value_on )
	wire_input.pl = pl

	if (pl!=nil) then pl:AddCount( "wire_inputs", wire_input ) end
	if (pl!=nil) then pl:AddCleanup( "gmod_wire_input", wire_input ) end

	return wire_input
end
duplicator.RegisterEntityClass("gmod_wire_input", MakeWireInput, "Pos", "Ang", "Model", "keygroup", "toggle", "value_off", "value_on", "frozen")
