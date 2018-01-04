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

	self.MyPlug = nil
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
		if (self.MyPlug) and (self.MyPlug:IsValid()) then
			self.MyPlug:SetSocket(nil)
			self.MyPlug = nil
		end

		self.Memory = nil --We're now getting no signal
		WireLib.TriggerOutput(self, "Memory", 0)

		self:NextThink( CurTime() + NEW_PLUG_WAIT_TIME ) --Give time before next grabbing a plug.
		return true
	end

	-- If we have no plug in us
	if (not self.MyPlug) or (not self.MyPlug:IsValid()) then

		-- Find entities near us
		local sockCenter = self:GetOffset( Vector(-1.75, 0, 0) )
		local local_ents = ents.FindInSphere( sockCenter, self.AttachRange )
		for key, plug in pairs(local_ents) do

			-- If we find a plug, try to attach it to us
			if ( plug:IsValid() && plug:GetClass() == "gmod_wire_dataplug" ) then

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

function ENT:Setup(WeldForce,AttachRange)
	self.WeldForce = WeldForce or 5000
	self.AttachRange = AttachRange or 5
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
	if (not self.NoCollideConst) then
		self.MyPlug = nil
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
		self.MyPlug = nil
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
