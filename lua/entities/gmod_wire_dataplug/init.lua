
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local MODEL = Model( "models/hammy/pci_card.mdl" )

ENT.WireDebugName = "DataPlug"

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.MySocket = nil
	self.Memory = nil

	self.Inputs = Wire_CreateInputs(self.Entity, { "Memory" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Connected" })
	self:SetOverlayText( "Data plug" )
	Wire_TriggerOutput(self.Entity, "Connected", 0)
end

function ENT:ReadCell( Address )
        if (self.MySocket) and (self.MySocket:IsValid()) and (self.MySocket.OwnMemory) then
		if (self.MySocket.OwnMemory.ReadCell) then
			return self.MySocket.OwnMemory:ReadCell( Address )
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
        if (self.MySocket) and (self.MySocket:IsValid()) and (self.MySocket.OwnMemory) then
		if (self.MySocket.OwnMemory.WriteCell) then
			return self.MySocket.OwnMemory:WriteCell( Address, value )
		else
			return false
		end
	else
		return false
	end
end

function ENT:OnRemove()
	self.BaseClass.Think(self)

	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:Setup(a,ar,ag,ab,aa)
	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.Entity:SetColor(ar, ag, ab, aa)
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
		Wire_TriggerOutput(self.Entity, "Connected", 0)
	end
end

function ENT:AttachedToSocket(socket)
	socket:SetMemory(self.Memory)
	Wire_TriggerOutput(self.Entity, "Connected", 1)
end

function ENT:OnRestore()
	self.A = self.A or 0
	self.AR = self.AR or 255
	self.AG = self.AG or 0
	self.AB = self.AB or 0
	self.AA = self.AA or 255

    	self.BaseClass.OnRestore(self)
end
