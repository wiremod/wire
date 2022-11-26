AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Dual Input"
ENT.WireDebugName = "Dual Input"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

function ENT:Setup(keygroup, keygroup2, toggle, value_off, value_on, value_on2)
	self.keygroup = keygroup
	self.keygroup2 = keygroup2

	local pl = self:GetPlayer()
	numpad.OnDown( pl, keygroup, "WireDualInput_On", self, 1 )
	numpad.OnUp( pl, keygroup, "WireDualInput_Off", self, 1 )
	numpad.OnDown( pl, keygroup2, "WireDualInput_On", self, -1 )
	numpad.OnUp( pl, keygroup2, "WireDualInput_Off", self, -1 )

	self.toggle = (toggle == 1 or toggle == true)
	self.value_off = value_off
	self.value_on = value_on
	self.value_on2 = value_on2
	self.Value = value_off
	self.Select = 0

	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self, "Out", self.value_off)
end

function ENT:InputActivate( mul )
	if ( self.toggle and self.Select == mul ) then
		return self:Switch( not self.On, mul )
	end

	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if ( self.toggle ) then return true end

	return self:Switch( false, mul )
end

function ENT:Switch( on, mul )
	if (not self:IsValid()) then return false end

	self.On = on
	self.Select = mul

	if (on and mul == 1) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
	elseif (on and mul == -1) then
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
	if (not ent:IsValid()) then return false end
	if not gamemode.Call("PlayerUse", pl, ent) then return end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (not ent:IsValid()) then return false end
	if not gamemode.Call("PlayerUse", pl, ent) then return end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireDualInput_On", On )
numpad.Register( "WireDualInput_Off", Off )

duplicator.RegisterEntityClass("gmod_wire_dual_input", WireLib.MakeWireEnt, "Data", "keygroup", "keygroup2", "toggle", "value_off", "value_on", "value_on2", "frozen")
