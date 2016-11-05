AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Socket"
ENT.WireDebugName = "Socket"

if CLIENT then return end -- No more client

-- Time after loosing one plug to search for another
local NEW_PLUG_WAIT_TIME = 2
local PLUG_IN_SOCKET_CONSTRAINT_POWER = 5000
local PLUG_IN_ATTACH_RANGE = 3

local SocketModels = {
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl",
}

function ENT:GetOffset( vec )
	local offset = vec

	local ang = self:GetAngles()
	local stackdir = ang:Up()
	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return self:GetPos() + stackdir * 2 + offset
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.MyPlug = nil
	self.Memory = nil
	self.OwnMemory = nil
	self.Const = nil
	self.ReceivedValue = 0

	self.Inputs = Wire_CreateInputs(self, { "Memory" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })
	Wire_TriggerOutput(self, "Memory", 0)
end

function ENT:SetMemory(mement)
	self.Memory = mement
	Wire_TriggerOutput(self, "Memory", 1)
end

function ENT:ReadCell( Address )
	if self.Memory then
		if self.Memory.ReadCell then
			return self.Memory:ReadCell( Address )
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if self.Memory then
		if self.Memory.WriteCell then
			return self.Memory:WriteCell( Address, value )
		else
			return false
		end
	else
		return false
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	-- If we were unplugged, reset the plug and socket to accept new ones.
	if self.Const) and (not self.Const:IsValid() then
		self.Const = nil
		self.NoCollideConst = nil
		if self.MyPlug) and (self.MyPlug:IsValid() then
			self.MyPlug:SetSocket(nil)
			self.MyPlug = nil
		end

		self.Memory = nil -- We're now getting no signal
		Wire_TriggerOutput(self, "Memory", 0)

		self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME ) -- Give time before next grabbing a plug.
		return true
	end

	-- If we have no plug in us
	if not self.MyPlug) or (not self.MyPlug:IsValid() then

		-- Find entities near us
		local sockCenter = self:GetOffset( Vector(-1.75, 0, 0) )
		local local_ents = ents.FindInSphere( sockCenter, PLUG_IN_ATTACH_RANGE )
		for key, plug in pairs(local_ents) do

			-- If we find a plug, try to attach it to us
			if plug:IsValid() && plug:GetClass() == "gmod_wire_dataplug" then

				-- If no other sockets are using it
				if plug.MySocket == nil then
					local plugpos = plug:GetPos()
					local dist = (sockCenter-plugpos):Length()

					-- If model matches up
					if SocketModels[self:GetModel()] == plug:GetModel() then
						self:AttachPlug(plug)
					end
				end
			end
		end
	end
end

function ENT:AttachPlug( plug )
	-- Set references between them
	plug:SetSocket(self)
	self.MyPlug = plug

	-- Position plug
	local newpos = self:GetOffset( Vector(-1.75, 0, 0) )
	if self:GetModel() == "models/props_lab/tpplugholder_single.mdl" then newpos = self:GetOffset( Vector( 8, -13, -5) )
	elseif self:GetModel() == "models/bull/various/usb_socket.mdl" then   newpos = self:GetOffset( Vector(-2,  0, -8) )
	elseif self:GetModel() == "models/wingf0x/altisasocket.mdl" then      newpos = self:GetOffset( Vector( 0.9,  0,  0) )
	elseif self:GetModel() == "models/wingf0x/ethernetsocket.mdl" then    newpos = self:GetOffset( Vector(-2.00,  0,  0) )
	elseif self:GetModel() == "models/wingf0x/hdmisocket.mdl" then        newpos = self:GetOffset( Vector(-2.00,  0,  0) )
	end

	local socketAng = self:GetAngles()
	plug:SetPos( newpos )
	plug:SetAngles( socketAng )

	self.NoCollideConst = constraint.NoCollide(self, plug, 0, 0)
	if not self.NoCollideConst then
		self.MyPlug = nil
		plug:SetSocket(nil)
		self.Memory = nil
			Wire_TriggerOutput(self, "Memory", 0)
		return
	end

	-- Constrain together
	self.Const = constraint.Weld( self, plug, 0, 0, PLUG_IN_SOCKET_CONSTRAINT_POWER, true )
	if not self.Const then
		self.NoCollideConst:Remove()
		self.NoCollideConst = nil
		self.MyPlug = nil
		plug:SetSocket(nil)
		self.Memory = nil
		Wire_TriggerOutput(self, "Memory", 0)
		return
	end

	-- Prepare clearup incase one is removed
	plug:DeleteOnRemove( self.Const )
	self:DeleteOnRemove( self.Const )
	self.Const:DeleteOnRemove( self.NoCollideConst )

	plug:AttachedToSocket(self)
end

function ENT:TriggerInput(iname, value, iter)
	if iname == "Memory" then
		self.OwnMemory = self.Inputs.Memory.Src
	end
end

duplicator.RegisterEntityClass("gmod_wire_datasocket", WireLib.MakeWireEnt, "Data")
