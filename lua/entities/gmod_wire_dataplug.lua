AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Plug"
ENT.WireDebugName = "DataPlug"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.MySocket = nil
	self.Memory = nil

	self.Inputs = WireLib.CreateInputs(self, { "Memory" })
	self.Outputs = WireLib.CreateOutputs(self, { "Connected" })
	WireLib.TriggerOutput(self, "Connected", 0)
end

function ENT:ReadCell( Address, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end

    if IsValid(self.MySocket) and self.MySocket.OwnMemory and self.MySocket.OwnMemory.ReadCell then
		return self.MySocket.OwnMemory:ReadCell( Address, infloop + 1 )
	end
	return nil
end

function ENT:WriteCell( Address, value, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end

	if IsValid(self.MySocket) and self.MySocket.OwnMemory and self.MySocket.OwnMemory.WriteCell then
		return self.MySocket.OwnMemory:WriteCell( Address, value, infloop + 1 )
	end
	return false
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if IsValid(self.MySocket) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "Memory") then
		self.Memory = self.Inputs.Memory.Src
		if (self.MySocket) and (self.MySocket:IsValid()) then
			self.MySocket:SetMemory(self.Memory)
		end
	end
end

function ENT:SetSocket(socket)
	self.MySocket = socket
	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket:SetMemory(self.Memory)
	else
		WireLib.TriggerOutput(self, "Connected", 0)
	end
end

function ENT:AttachedToSocket(socket)
	socket:SetMemory(self.Memory)
	WireLib.TriggerOutput(self, "Connected", 1)
end

duplicator.RegisterEntityClass("gmod_wire_dataplug", WireLib.MakeWireEnt, "Data")
