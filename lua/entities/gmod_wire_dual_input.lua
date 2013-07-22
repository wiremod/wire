
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "DualInput"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup(keygroup, keygroup2, toggle, value_off, value_on, value_on2)
	self.keygroup = keygroup
	self.keygroup2 = keygroup2
	self.toggle = (toggle == 1 || toggle == true)
	self.value_off = value_off
	self.value_on = value_on
	self.value_on2 = value_on2
	self.Value = value_off
	self.Select = 0

	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self, "Out", self.value_off)
end

function ENT:InputActivate( mul )
	if ( self.toggle && self.Select == mul ) then
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
	self.Select = mul

	if (on && mul == 1) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
	elseif (on && mul == -1) then
		self:ShowOutput(self.value_on2)
		self.Value = self.value_on2
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
	end

	Wire_TriggerOutput(self, "Out", self.Value)

	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.value_on2 .. " - " .. self.value_off .. " - " .. self.value_on .. ") = " .. value )
end

local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireDualInput_On", On )
numpad.Register( "WireDualInput_Off", Off )


function MakeWireDualInput( pl, Pos, Ang, model, keygroup, keygroup2, toggle, value_off, value_on, value_on2, frozen )
	if ( !pl:CheckLimit( "wire_dual_inputs" ) ) then return false end

	local wire_dual_input = ents.Create( "gmod_wire_dual_input" )
	if (!wire_dual_input:IsValid()) then return false end

	wire_dual_input:SetAngles( Ang )
	wire_dual_input:SetPos( Pos )
	wire_dual_input:SetModel( Model(model or "models/jaanus/wiretool/wiretool_input.mdl") )
	wire_dual_input:Spawn()

	if wire_dual_input:GetPhysicsObject():IsValid() then
		local Phys = wire_dual_input:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_dual_input:Setup( keygroup, keygroup2, toggle, value_off, value_on, value_on2 )
	wire_dual_input:SetPlayer( pl )

	numpad.OnDown( pl, keygroup, "WireDualInput_On", wire_dual_input, 1 )
	numpad.OnUp( pl, keygroup, "WireDualInput_Off", wire_dual_input, 1 )

	numpad.OnDown( pl, keygroup2, "WireDualInput_On", wire_dual_input, -1 )
	numpad.OnUp( pl, keygroup2, "WireDualInput_Off", wire_dual_input, -1 )

	pl:AddCount( "wire_dual_inputs", wire_dual_input )

	return wire_dual_input
end

duplicator.RegisterEntityClass("gmod_wire_dual_input", MakeWireDualInput, "Pos", "Ang", "Model", "keygroup", "keygroup2", "toggle", "value_off", "value_on", "value_on2", "frozen")
