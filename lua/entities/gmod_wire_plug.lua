AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Plug"
ENT.Author          = "Divran"
ENT.Purpose         = "Links with a socket"
ENT.Instructions    = "Move a plug close to a socket to link them, and data will be transferred through the link."
ENT.WireDebugName = "Plug"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "PlayerHolding" )
	self:NetworkVar( "Bool", 1, "Linked" )
end

function ENT:GetSocketClass()
	return "gmod_wire_socket"
end

function ENT:GetClosestSocket()
	local sockets = ents.FindInSphere( self:GetPos(), 100 )

	local ClosestDist
	local Closest

	for k,v in pairs( sockets ) do
		if (v:GetClass() == self:GetSocketClass() and not v:GetLinked()) then
			local pos, _ = v:GetLinkPos()
			local Dist = self:GetPos():Distance( pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end

if CLIENT then
	function ENT:DrawEntityOutline()
		if (GetConVar("wire_plug_drawoutline"):GetBool()) then
			BaseClass.DrawEntityOutline( self )
		end
	end
	return -- No more client
end

------------------------------------------------------------
-- Helper functions & variables
------------------------------------------------------------
local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }
local LETTERS_INV = {}
for k,v in pairs( LETTERS ) do
	LETTERS_INV[v] = k
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetLinked( false )

	self.Memory = {}
end

function ENT:Setup( ArrayInput )
	local old = self.ArrayInput
	self.ArrayInput = ArrayInput or false

	if not (self.Inputs and self.Outputs and self.ArrayInput == old) then
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

function ENT:TriggerInput( name, value )
	if (self.Socket and self.Socket:IsValid()) then
		self.Socket:SetValue( name, value )
	end
	self:ShowOutput()
end

function ENT:SetValue( name, value )
	if not (self.Socket and self.Socket:IsValid()) then return end
	if (name == "In") then
		if (self.ArrayInput) then -- Both have array
			WireLib.TriggerOutput( self, "Out", table.Copy( value ) )
		else -- Target has array, this does not
			for i=1,#LETTERS do
				local val = (value or {})[i]
				if isnumber(val) then
					WireLib.TriggerOutput( self, LETTERS[i], val )
				end
			end
		end
	else
		if (self.ArrayInput) then -- Target does not have array, this does
			if (value ~= nil) then
				local data = table.Copy( self.Outputs.Out.Value )
				data[LETTERS_INV[name]] = value
				WireLib.TriggerOutput( self, "Out", data )
			end
		else -- Niether have array
			if (value ~= nil) then
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
	Address = math.floor(Address)
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
	Address = math.floor(Address)
	return self.Memory[Address or 1] or 0
end

function ENT:Think()
	BaseClass.Think( self )
	self:SetPlayerHolding( self:IsPlayerHolding() )
end

function ENT:ResetValues()
	if (self.ArrayInput) then
		WireLib.TriggerOutput( self, "Out", {} )
	else
		for i=1,#LETTERS do
			WireLib.TriggerOutput( self, LETTERS[i], 0 )
		end
	end
	self.Memory = {}
	self:ShowOutput()
end

------------------------------------------------------------
-- ResendValues
-- Resends the values when plugging in
------------------------------------------------------------
function ENT:ResendValues()
	if (not self.Socket) then return end
	if (self.ArrayInput) then
		self.Socket:SetValue( "In", self.Inputs.In.Value )
	else
		for i=1,#LETTERS do
			self.Socket:SetValue( LETTERS[i], self.Inputs[LETTERS[i]].Value )
		end
	end
end

function ENT:ShowOutput()
	local OutText = "Plug [" .. self:EntIndex() .. "]\n"
	if (self.ArrayInput) then
		OutText = OutText .. "Array input/outputs."
	else
		OutText = OutText .. "Number input/outputs."
	end
	if (self.Socket and self.Socket:IsValid()) then
		OutText = OutText .. "\nLinked to socket [" .. self.Socket:EntIndex() .. "]"
	end
	self:SetOverlayText(OutText)
end

duplicator.RegisterEntityClass( "gmod_wire_plug", WireLib.MakeWireEnt, "Data", "ArrayInput" )

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (info.Plug ~= nil) then
		ent:Setup( info.Plug.ArrayInput )
	end

	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end
