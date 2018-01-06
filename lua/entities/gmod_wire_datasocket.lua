AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Socket"
ENT.WireDebugName = "Socket"

if CLIENT then return end -- No more client

--Time after loosing one plug to search for another
local NEW_PLUG_WAIT_TIME = 2


local SocketModels = {
	["models/props_lab/tpplugholder_single.mdl"] = "models/props_lab/tpplug.mdl",
	["models/bull/various/usb_socket.mdl"] = "models/bull/various/usb_stick.mdl",
	["models/hammy/pci_slot.mdl"] = "models/hammy/pci_card.mdl",
	["models/wingf0x/isasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/altisasocket.mdl"] = "models/wingf0x/isaplug.mdl",
	["models/wingf0x/ethernetsocket.mdl"] = "models/wingf0x/ethernetplug.mdl",
	["models/wingf0x/hdmisocket.mdl"] = "models/wingf0x/hdmiplug.mdl",
}

local SocketOffsets = {
	["models/props_lab/tpplugholder_single.mdl"] =Vector( 8, -13, -5),
	["models/bull/various/usb_socket.mdl"]  = Vector(-2,  0, -8),
	["models/wingf0x/altisasocket.mdl"]  =  Vector( 0.9,  0,  0),
	["models/wingf0x/ethernetsocket.mdl"] = Vector(-2.00,  0,  0),
	["models/wingf0x/hdmisocket.mdl"]  = Vector(-2.00,  0,  0),
}

function ENT:GetOffset( vec )
	local offset = vec

	local ang = self:GetAngles()
	local stackdir = ang:Up()
	offset = ang:Up() * offset.X + ang:Forward() * -1 * offset.Z + ang:Right() * offset.Y

	return self:GetPos() + stackdir * 2 + offset
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Plug = nil
	self.Memory = nil
	self.OwnMemory = nil
	self.Const = nil
	self.ReceivedValue = 0

	self.Inputs = WireLib.CreateInputs(self, { "Memory" })
	self.Outputs = WireLib.CreateOutputs(self, { "Memory" })
	WireLib.TriggerOutput(self, "Memory", 0)
end

function ENT:SetMemory(mement)
	self.Memory = mement
	WireLib.TriggerOutput(self, "Memory", 1)
end

function ENT:ReadCell( Address, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end

	if (self.Memory) then
		if (self.Memory.ReadCell) then
			return self.Memory:ReadCell( Address, infloop + 1 )
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell( Address, value, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end

	if (self.Memory) then
		if (self.Memory.WriteCell) then
			return self.Memory:WriteCell( Address, value, infloop + 1 )
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
	if (self.Const) and (not self.Const:IsValid()) then
		self.Const = nil
		self.NoCollideConst = nil
		if (self.Plug) and (self.Plug:IsValid()) then
			self.Plug:SetSocket(nil)
			self.Plug = nil
		end

		self.Memory = nil --We're now getting no signal
		WireLib.TriggerOutput(self, "Memory", 0)

		self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME ) --Give time before next grabbing a plug.
		return true
	end

	-- If we have no plug in us
	if (not self.Plug) or (not self.Plug:IsValid()) then

		local plug = self:GetClosestPlug()

		if IsValid(plug) and SocketModels[self:GetModel()] == plug:GetModel() and (not plug:IsPlayerHolding()) then
			self:AttachPlug(plug)
		end
	end
end

function ENT:GetClosestPlug()
	-- Find entities near us
	local sockCenter = self:GetOffset( SocketOffsets[self:GetModel()] or Vector(-1.75, 0, 0) )
	local local_ents = ents.FindInSphere( sockCenter, self.AttachRange )

	local ClosestDist
	local Closest

	for key, plug in pairs(local_ents) do
		if  plug:IsValid() and plug:GetClass() == "gmod_wire_dataplug" and plug.Socket == nil then
			local plugpos = plug:GetPos()
			local dist = (sockCenter-plugpos):Length()
			if (ClosestDist==nil or dist < ClosestDist) then
				Closest = plug
				ClosestDist = dist
			end
		end
	end
	return Closest
end

function ENT:Setup(WeldForce,AttachRange)
	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
end


function ENT:AttachPlug( plug )
	-- Set references between them
	plug:SetSocket(self)
	self.Plug = plug

	-- Position plug
	local newpos = self:GetOffset( SocketOffsets[self:GetModel()] or Vector(-1.75, 0, 0) )

	local socketAng = self:GetAngles()
	plug:SetPos( newpos )
	plug:SetAngles( socketAng )

	self.NoCollideConst = constraint.NoCollide(self, plug, 0, 0)
	if (not self.NoCollideConst) then
		self.Plug = nil
		plug:SetSocket(nil)
		self.Memory = nil
			WireLib.TriggerOutput(self, "Memory", 0)
		return
	end

	-- Constrain together
	self.Const = constraint.Weld( self, plug, 0, 0, self.WeldForce, true )
	if (not self.Const) then
		self.NoCollideConst:Remove()
		self.NoCollideConst = nil
		self.Plug = nil
		plug:SetSocket(nil)
		self.Memory = nil
		WireLib.TriggerOutput(self, "Memory", 0)
		return
	end

	-- Prepare clearup incase one is removed
	plug:DeleteOnRemove( self.Const )
	self:DeleteOnRemove( self.Const )
	self.Const:DeleteOnRemove( self.NoCollideConst )

	plug:AttachedToSocket(self)
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "Memory") then
		self.OwnMemory = self.Inputs.Memory.Src
	end
end

duplicator.RegisterEntityClass("gmod_wire_datasocket", WireLib.MakeWireEnt, "Data", "WeldForce", "AttachRange")
