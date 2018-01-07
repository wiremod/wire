AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_socket" )
ENT.PrintName       = "Wire Socket"
ENT.Purpose         = "Links with a plug"
ENT.Instructions    = "Move a plug close to a plug to link them, and data will be transferred through the link."
ENT.WireDebugName	= "Socket"


function ENT:GetPlugClass()
	return "gmod_wire_plug"
end

if CLIENT then
	hook.Add("HUDPaint","Wire_Socket_DrawLinkHelperLine",function()
		local sockets = ents.FindByClass("gmod_wire_socket")
		for k,self in pairs( sockets ) do
			local Pos, _ = self:GetLinkPos()

			local Closest = self:GetClosestPlug()

			if IsValid(Closest) and self:CanLink(Closest) and Closest:GetNWBool( "PlayerHolding", false ) and Closest:GetClosestSocket() == self then
				local plugpos = Closest:GetPos():ToScreen()
				local socketpos = Pos:ToScreen()
				surface.SetDrawColor(255,255,100,255)
				surface.DrawLine(plugpos.x, plugpos.y, socketpos.x, socketpos.y)
			end
		end
	end)
	return  -- No more client
end

local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }
local LETTERS_INV = {}
for k,v in pairs( LETTERS ) do
	LETTERS_INV[v] = k
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Memory = {}
end

function ENT:Setup( ArrayInput, WeldForce, AttachRange )
	BaseClass.Setup(self,WeldForce,AttachRange)

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
	if (self.Plug and self.Plug:IsValid()) then
		self.Plug:SetValue( name, value )
	end
	self:ShowOutput()
end

function ENT:SetValue( name, value )
	if not (self.Plug and self.Plug:IsValid()) then return end
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
	if (WriteToMe) then
		self.Memory[Address or 1] = Value or 0
		return true
	else
		if (self.Plug and self.Plug:IsValid()) then
			self.Plug:WriteCell( Address, Value, true )
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

function ENT:OnAttach()
	self:ResendValues()
end

function ENT:OnDetach()
	self:ResetValues()
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
	if (not self.Plug) then return end
	if (self.ArrayInput) then
		self.Plug:SetValue( "In", self.Inputs.In.Value )
	else
		for i=1,#LETTERS do
			self.Plug:SetValue( LETTERS[i], self.Inputs[LETTERS[i]].Value )
		end
	end
end

function ENT:ShowOutput()
	local OutText = "Socket [" .. self:EntIndex() .. "]\n"
	if (self.ArrayInput) then
		OutText = OutText .. "Array input/outputs."
	else
		OutText = OutText .. "Number input/outputs."
	end
	if (self.Plug and self.Plug:IsValid()) then
		OutText = OutText .. "\nLinked to plug [" .. self.Plug:EntIndex() .. "]"
	end
	self:SetOverlayText(OutText)
end

duplicator.RegisterEntityClass( "gmod_wire_socket", WireLib.MakeWireEnt, "Data", "ArrayInput", "WeldForce", "AttachRange" )

------------------------------------------------------------
-- Adv Duplicator Support
------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self)
	info.Socket.ArrayInput = self.ArrayInput
	return info
end


function ENT:GetSetupDupeInfo(info)
	return info.Socket.ArrayInput, info.Socket.WeldForce, info.Socket.AttachRange
end
