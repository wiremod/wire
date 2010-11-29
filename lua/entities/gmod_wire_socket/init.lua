
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Socket"

------------------------------------------------------------
-- Helper functions & variables
------------------------------------------------------------
local NEW_PLUG_WAIT_TIME = 2
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
function ENT:SetUp( ArrayInput, WeldForce, AttachRange )
	local old = self.ArrayInput
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

	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
	self:SetNWInt( "AttachRange", self.AttachRange )

	self:ShowOutput()
end

------------------------------------------------------------
-- TriggerInput
------------------------------------------------------------
function ENT:TriggerInput( name, value )
	if (self.Plug and self.Plug:IsValid()) then
		self.Plug:SetValue( name, value )
	end
	self:ShowOutput()
end

------------------------------------------------------------
-- SetValue
-- Recieve data from the plug
------------------------------------------------------------
function ENT:SetValue( name, value )
	if (!self.Plug or !self.Plug:IsValid()) then return end
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
-- Think
-- Find nearby plugs and connect to them
------------------------------------------------------------
function ENT:Think()
	self.BaseClass.Think(self)

	if (!self.Plug or !self.Plug:IsValid()) then
		local Pos, Ang = self:GetLinkPos()

		local Closest = self:GetClosestPlug()

		if (Closest and Closest:IsValid() and self:CanLink( Closest ) and !Closest:IsPlayerHolding() and Closest:GetClosestSocket() == self) then
			self.Plug = Closest
			Closest.Socket = self

			-- Move
			Closest:SetPos( Pos )
			Closest:SetAngles( Ang )

			-- Weld
			local weld = constraint.Weld( self, Closest, 0, 0, self.WeldForce, true )
			if (weld and weld:IsValid()) then
				Closest:DeleteOnRemove( weld )
				self:DeleteOnRemove( weld )
				self.Weld = weld
			end

			-- Reset all values
			Closest:ResetValues()
			self:ResetValues()

			self:SetNWBool( "Linked", true )
		end

		self:NextThink( CurTime() + 0.05 )
		return true
	else
		if (self.Weld and !self.Weld:IsValid()) then -- Plug was unplugged
			self.Weld = nil

			self.Plug.Socket = nil
			self.Plug:ResetValues()

			self.Plug = nil
			self:ResetValues()

			self:SetNWBool( "Linked", false )

			self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME )
			return true
		end
	end
end

------------------------------------------------------------
-- ShowOutput
-- Show all out and inputs
------------------------------------------------------------
function ENT:ShowOutput()
	local OutText = "Socket [" .. self:EntIndex() .. "]\n"
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
	if (self.Plug and self.Plug:IsValid()) then
		OutText = OutText .. "Linked to plug [" .. self.Plug:EntIndex() .. "]"
	end
	self:SetOverlayText(OutText)
end


------------------------------------------------------------
-- Adv Duplicator Support
------------------------------------------------------------
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.Socket = {}
	info.Socket.ArrayInput = self.ArrayInput
	info.Socket.WeldForce = self.WeldForce
	info.Socket.AttachRange = self.AttachRange
	if (self.Plug) then info.Socket.Plug = self.Plug:EntIndex() end

	return info
end

local function FindConstraint( ent, plug )
	timer.Simple(0.5,function( ent, plug )
		if (ent and ent:IsValid() and plug and plug:IsValid()) then
			local welds = constraint.FindConstraints( ent, "Weld" )
			for k,v in pairs( welds ) do
				if (v.Ent2 == plug) then
					ent.Weld = v.Constraint
					return
				end
			end
			local welds = constraint.FindConstraints( plug, "Weld" )
			for k,v in pairs( welds ) do
				if (v.Ent2 == ent) then
					ent.Weld = v.Constraint
					return
				end
			end
		end
	end, ent, plug )
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	if (!ply:CheckLimit("wire_sockets")) then
		ent:Remove()
		return
	end
	ply:AddCount( "wire_sockets", ent )

	if (info.Socket) then
		ent:SetUp( info.Socket.ArrayInput, info.Socket.WeldForce, info.Socket.AttachRange )
		if (info.Socket.Plug) then
			local plug = GetEntByID( info.Socket.Plug )
			if (plug and plug:IsValid()) then
				ent.Plug = plug
				plug.Socket = ent
				ent.Weld = { ["IsValid"] = function() return true end }

				if (GetConstByID) then
					if (info.Socket.Weld) then
						local weld = GetConstByID( info.Socket.Weld )
						if (weld and weld:IsValid()) then
							ent.Weld = weld
						end
					end
				else
					FindConstraint( ent, plug )
				end
			end
		end
	else -- OLD DUPES COMPATIBILITY
		ent:SetUp() -- default values

		-- Attempt to find connected plug
		timer.Simple(0.5,function(ent)
			local welds = constraint.FindConstraints( ent, "Weld" )
			for k,v in pairs( welds ) do
				if (v.Ent2:GetClass() == "gmod_wire_plug") then
					ent.Plug = v.Ent2
					v.Ent2.Socket = ent
					ent.Weld = v.Constraint
				end
			end
		end,ent)
	end -- /OLD DUPES COMPATIBILITY

	ent:SetPlayer( ply )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

-- OnRestore
function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
end
