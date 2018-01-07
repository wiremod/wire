AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_socket" )
ENT.PrintName		= "Wire Data Socket"
ENT.WireDebugName = "Socket"


function ENT:GetPlugClass()
	return "gmod_wire_dataplug"
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	BaseClass.Initialize(self)

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

function ENT:OnAttach()

end

function ENT:OnDetach()
	self.Memory = nil --We're now getting no signal
	WireLib.TriggerOutput(self, "Memory", 0)
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "Memory") then
		self.OwnMemory = self.Inputs.Memory.Src
	end
end

duplicator.RegisterEntityClass("gmod_wire_datasocket", WireLib.MakeWireEnt, "Data", "WeldForce", "AttachRange")
