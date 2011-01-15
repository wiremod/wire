
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Numpad"
ENT.OverlayDelay = 0

local keynames = {"0","1","2","3","4","5","6","7","8","9",".","enter","+","-","*","/"}
local lookupkeynames = {}
for k,v in ipairs(keynames) do
	lookupkeynames[v] = k-1
	lookupkeynames[k-1] = v
end
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.On = {}

	self.Inputs = Wire_CreateInputs(self, keynames)
	self.Outputs = Wire_CreateOutputs(self, keynames)

	self.Buffer = {}
	for i = 0,#keynames-1 do
		self.Buffer[i] = 0
	end
end


function ENT:ReadCell( Address )
	if (Address >= 0) && (Address < #keynames) then
		return self.Buffer[Address]
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if (Address >= 0) && (Address < #keynames) then
		self:TriggerInput(lookupkeynames[Address], value)
		return true
	else
		return false
	end
end

function ENT:TriggerInput(key, value)
	if value ~= 0 then
		numpad.Activate( self:GetPlayer(), nil, {key}, self:GetPlayerIndex() )
	else
		numpad.Deactivate( self:GetPlayer(), nil, {key}, self:GetPlayerIndex() )
	end
end

function ENT:Setup( toggle, value_off, value_on)
	self.Toggle = (toggle == 1)
	self.ValueOff = value_off
	self.ValueOn = value_on

	self:ShowOutput()
end

function ENT:NumpadActivate( key )
	if ( self.Toggle ) then
		return self:Switch( !self.On[ key ], key )
	end

	return self:Switch( true, key )
end

function ENT:NumpadDeactivate( key )
	if ( self.Toggle ) then return true end

	return self:Switch( false, key )
end

function ENT:Switch( on, key )
	if (!self:IsValid()) then return false end

	self.On[ key ] = on

	if (on) then
		self:ShowOutput()
		self.Value = self.ValueOn
	else
		self:ShowOutput()
		self.Value = self.ValueOff
	end

	Wire_TriggerOutput(self, lookupkeynames[key], self.Value)

	if ( on ) then
		self.Buffer[key] = 1
	else
		self.Buffer[key] = 0
	end

	return true
end

function ENT:ShowOutput()
	txt = "Numpad"
	for k = 0, #keynames-1 do
		if (self.On[k]) then
			txt = txt..", "..lookupkeynames[k]
		end
	end

	self:SetOverlayText( txt )
end

function ENT:OnRemove()
	for _,impulse in ipairs(self.impulses) do
		numpad.Remove(impulse)
	end
end

local function On( pl, ent, key )
	return ent:NumpadActivate( key )
end

local function Off( pl, ent, key )
	return ent:NumpadDeactivate( key )
end

numpad.Register( "WireNumpad_On", On )
numpad.Register( "WireNumpad_Off", Off )
