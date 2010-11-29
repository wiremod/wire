
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Plug"

------------------------------------------------------------
-- Helper functions & variables
------------------------------------------------------------
local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }
local LETTERS_INV = {}
for k,v in pairs( LETTERS ) do
	LETTERS_INV[v] = k
end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Memory = {}
end

------------------------------------------------------------
-- SetUp
------------------------------------------------------------
function ENT:SetUp( ArrayInput )
	self.ArrayInput = ArrayInput or false

	if (!self.Inputs or !self.Outputs or self.ArrayInput != old) then
		if (self.ArrayInput) then
			self.Inputs = WireLib.CreateInputs( self, { "In [ARRAY]" } )
			self.Outputs = WireLib.CreateOutputs( self, { "Out [ARRAY]" } )
		else
			self.Inputs = WireLib.CreateInputs( self, LETTERS )
			self.Outputs = WireLib.CreateOutputs( self, LETTERS )
		end
	end

	self:ShowOutput()
end

------------------------------------------------------------
-- TriggerInput
------------------------------------------------------------
function ENT:TriggerInput( name, value )
	if (self.Socket and self.Socket:IsValid()) then
		self.Socket:SetValue( name, value )
	end
	self:ShowOutput()
end

------------------------------------------------------------
-- SetValue
-- Recieve data from the socket
------------------------------------------------------------
function ENT:SetValue( name, value )
	if (!self.Socket or !self.Socket:IsValid()) then return end
	if (name == "In") then
		if (self.ArrayInput) then -- Both have array
			WireLib.TriggerOutput( self, "Out", table.Copy( value ) )
		else -- Target has array, this does not
			for i=1,#LETTERS do
				local val = (value or {})[i]
				if (val != nil and type(val) == "number") then
					WireLib.TriggerOutput( self, LETTERS[i], val )
				end
			end
		end
	else
		if (self.ArrayInput) then -- Target does not have array, this does
			if (value != nil) then
				local data = table.Copy( self.Outputs.Out.Value )
				data[LETTERS_INV[name]] = value
				WireLib.TriggerOutput( self, "Out", data )
			end
		else -- Niether have array
			if (value != nil) then
				WireLib.TriggerOutput( self, name, value )
			end
		end
	end
	self:ShowOutput()
end

------------------------------------------------------------
-- WriteCell
-- Hi-speed support
------------------------------------------------------------
function ENT:WriteCell( Address, Value, WriteToMe )
	if (WriteToMe) then
		self.Memory[Address or 1] = Value or 0
		return true
	else
		if (self.Socket and self.Socket:IsValid()) then
			self.Socket:WriteCell( Address, Value, true )
			return true
		else
			return false
		end
	end
end

------------------------------------------------------------
-- ReadCell
-- Hi-speed support
------------------------------------------------------------
function ENT:ReadCell( Address )
	return self.Memory[Address or 1] or 0
end

------------------------------------------------------------
-- Think
-- Set PlayerHolding
------------------------------------------------------------
function ENT:Think()
	self.BaseClass.Think( self )
	self:SetNWBool( "PlayerHolding", self:IsPlayerHolding() )
end

------------------------------------------------------------
-- ResetValues
-- Resets all values
------------------------------------------------------------
function ENT:ResetValues()
	if (self.ArrayInput) then
		WireLib.TriggerOutput( self, "Out", {} )
		WireLib.TriggerInput( self, "In", {} )
	else
		for i=1,#LETTERS do
			WireLib.TriggerOutput( self, LETTERS[i], 0 )
			WireLib.TriggerInput( self, LETTERS[i], 0 )
		end
	end
	self.Memory = {}
	self:ShowOutput()
end

------------------------------------------------------------
-- ShowOutput
-- Show all out and inputs
------------------------------------------------------------
function ENT:ShowOutput()
	local OutText = "Plug [" .. self:EntIndex() .. "]\n"
	if (self.ArrayInput) then
		OutText = OutText .. "Array input/output. Showing the first 8 values.\nInputs:\n"
		local n = 0
		for k,v in pairs( self.Inputs.In.Value ) do
			n = n + 1
			if (n > 8) then break end
			OutText = OutText .. k .. " = " .. v .. "\n"
		end

		OutText = OutText .. "Outputs:\n"
		local n = 0
		for k,v in pairs( self.Outputs.Out.Value ) do
			n = n + 1
			if (n > 8) then break end
			OutText = OutText .. k .. " = " .. v .. "\n"
		end
	else
		OutText = OutText .. "Inputs:\n"
		for i=1,8 do
			OutText = OutText .. LETTERS[i] .. " = " .. self.Inputs[LETTERS[i]].Value .. "\n"
		end

		OutText = OutText .. "Outputs:\n"
		for i=1,8 do
			OutText = OutText .. LETTERS[i] .. " = " .. self.Outputs[LETTERS[i]].Value .. "\n"
		end
	end
	if (self.Socket and self.Socket:IsValid()) then
		OutText = OutText .. "Linked to socket [" .. self.Socket:EntIndex() .. "]"
	end
	self:SetOverlayText(OutText)
end

------------------------------------------------------------
-- Adv Duplicator Support
------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.Plug = {}
	info.Plug.ArrayInput = self.ArrayInput

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (!ply:CheckLimit("wire_plugs")) then
		ent:Remove()
		return
	end
	ply:AddCount( "wire_plugs", ent )

	if (info.Plug) then
		ent:SetUp( info.Plug.ArrayInput )
	else
		ent:SetUp() -- default values
	end

	ent:SetPlayer( ply )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

-- OnRestore
function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end
