AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Socket"
ENT.Purpose         = "Links with a plug"
ENT.Instructions    = "Move a plug close to a plug to link them, and data will be transferred through the link."
ENT.WireDebugName	= "Socket"
local base = scripted_ents.Get("base_wire_entity")

local PositionOffsets = {
	["models/wingf0x/isasocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Vector(0,0,2.6),
	["models/wingf0x/ethernetsocket.mdl"] = Vector(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Vector(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Vector(5, 13, 10),
	["models/bull/various/usb_socket.mdl"] = Vector(8,0,0),
	["models/hammy/pci_slot.mdl"] = Vector(0,0,0),
	["models//hammy/pci_slot.mdl"] = Vector(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local AngleOffsets = {
	["models/wingf0x/isasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/altisasocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/ethernetsocket.mdl"] = Angle(0,0,0),
	["models/wingf0x/hdmisocket.mdl"] = Angle(0,0,0),
	["models/props_lab/tpplugholder_single.mdl"] = Angle(0,0,0),
	["models/bull/various/usb_socket.mdl"] = Angle(0,0,0),
	["models/hammy/pci_slot.mdl"] = Angle(0,0,0),
	["models//hammy/pci_slot.mdl"] = Angle(0,0,0), -- For some reason, GetModel on this model has two / on the client... Bug?
}
local SocketModels = {
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl",
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models//hammy/pci_slot.mdl"] = "models//hammy/pci_card.mdl", -- For some reason, GetModel on this model has two / on the client... Bug?
}

function ENT:GetLinkPos()
	return self:LocalToWorld(PositionOffsets[self:GetModel()] or Vector(0,0,0)), self:LocalToWorldAngles(AngleOffsets[self:GetModel()] or Angle(0,0,0))
end

function ENT:CanLink( Target )
	if (Target.Socket and Target.Socket:IsValid()) then return false end
	if (SocketModels[self:GetModel()] ~= Target:GetModel()) then return false end
	return true
end

function ENT:GetClosestPlug()
	local Pos, _ = self:GetLinkPos()

	local plugs = ents.FindInSphere( Pos, (CLIENT and self:GetNWInt( "AttachRange", 5 ) or self.AttachRange) )

	local ClosestDist
	local Closest

	for k,v in pairs( plugs ) do
		if (v:GetClass() == self:GetPlugClass() and not v:GetNWBool( "Linked", false )) then
			local Dist = v:GetPos():Distance( Pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end

function ENT:GetPlugClass()
	return "gmod_wire_plug"
end

if CLIENT then 
	function ENT:DrawEntityOutline()
		if (GetConVar("wire_plug_drawoutline"):GetBool()) then
			base.DrawEntityOutline( self )
		end
	end

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


local NEW_PLUG_WAIT_TIME = 2
local LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H" }
local LETTERS_INV = {}
for k,v in pairs( LETTERS ) do
	LETTERS_INV[v] = k
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetNWBool( "Linked", false )

	self.Memory = {}
end

function ENT:Setup( ArrayInput, WeldForce, AttachRange )
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

	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
	self:SetNWInt( "AttachRange", self.AttachRange )

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

------------------------------------------------------------
-- Think
-- Find nearby plugs and connect to them
------------------------------------------------------------
function ENT:Think()
	base.Think(self)

	if not (self.Plug and self.Plug:IsValid()) then -- Has not been linked or plug was deleted
		local Pos, Ang = self:GetLinkPos()

		local Closest = self:GetClosestPlug()

		self:SetNWBool( "Linked", false )

		if (Closest and Closest:IsValid() and self:CanLink( Closest ) and not Closest:IsPlayerHolding() and Closest:GetClosestSocket() == self) then
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

			-- Resend all values
			Closest:ResendValues()
			self:ResendValues()

			Closest:SetNWBool( "Linked", true )
			self:SetNWBool( "Linked", true )
		end

		self:NextThink( CurTime() + 0.05 )
		return true
	else
		if (self.Weld and not self.Weld:IsValid()) then -- Plug was unplugged
			self.Weld = nil

			self.Plug:SetNWBool( "Linked", false )
			self:SetNWBool( "Linked", false )

			self.Plug.Socket = nil
			self.Plug:ResetValues()

			self.Plug = nil
			self:ResetValues()

			self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME )
			return true
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
	local info = base.BuildDupeInfo(self) or {}

	info.Socket = {}
	info.Socket.ArrayInput = self.ArrayInput
	info.Socket.WeldForce = self.WeldForce
	info.Socket.AttachRange = self.AttachRange
	if (self.Plug) then info.Socket.Plug = self.Plug:EntIndex() end

	return info
end

local function FindConstraint( ent, plug )
	timer.Simple(0.5,function()
		if IsValid(ent) and IsValid(plug) then
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
	end)
end

function ENT:GetApplyDupeInfoParams(info)
	return info.Socket.ArrayInput, info.Socket.WeldForce, info.Socket.AttachRange
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	base.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.Socket) then
		ent:Setup( self:GetApplyDupeInfoParams(info) )
		local plug = GetEntByID( info.Socket.Plug )
		if IsValid(plug) then
			ent.Plug = plug
			plug.Socket = ent
			ent.Weld = { ["IsValid"] = function() return true end }

			plug:SetNWBool( "Linked", true )
			ent:SetNWBool( "Linked", true )
			-- Resend all values
			plug:ResendValues()
			ent:ResendValues()

			if GetConstByID then
				if info.Socket.Weld then
					ent.Weld = GetConstByID( info.Socket.Weld )
				end
			else
				FindConstraint( ent, plug )
			end
		end
	else -- OLD DUPES COMPATIBILITY
		ent:Setup() -- default values

		-- Attempt to find connected plug
		timer.Simple(0.5,function()
			local welds = constraint.FindConstraints( ent, "Weld" )
			for k,v in pairs( welds ) do
				if (v.Ent2:GetClass() == self:GetPlugClass()) then
					ent.Plug = v.Ent2
					v.Ent2.Socket = ent
					ent.Weld = v.Constraint
					ent.Plug:SetNWBool( "Linked", true )
					ent:SetNWBool( "Linked", true )

					ent.Plug:ResendValues()
					ent:ResendValues()
				end
			end
		end)
	end -- /OLD DUPES COMPATIBILITY
end
