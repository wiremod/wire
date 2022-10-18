AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Transferrer"
ENT.WireDebugName = "DataTransfer"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.Outputs = Wire_CreateOutputs(self, {"Output","HiSpeed_DataRate","Wire_DataRate"})
	self.Inputs = Wire_CreateInputs(self,{"Input","Smooth", "Interval"})

	self.Memory = nil
	self.Smooth = 0.1
	self.Interval = 0.25

	self.WDataRate = 0
	self.WDataBytes = 0
	self.HDataRate = 0
	self.HDataBytes = 0

	self:SetOverlayText("Hi-Speed data rate: 0 bps\nWire data rate: 0 bps")
end

function ENT:Think()
	BaseClass.Think(self)

	self.WDataRate = (self.WDataRate*(2-self.Smooth) + self.WDataBytes * (1/self.Interval) * (self.Smooth)) / 2
	self.WDataBytes = 0

	self.HDataRate = (self.HDataRate*(2-self.Smooth) + self.HDataBytes * (1/self.Interval) * (self.Smooth)) / 2
	self.HDataBytes = 0

	Wire_TriggerOutput(self, "HiSpeed_DataRate", self.HDataRate)
	Wire_TriggerOutput(self, "Wire_DataRate", self.WDataRate)

	self:SetOverlayText("Hi-Speed data rate: "..math.floor(self.HDataRate).." bps\nWire data rate: "..math.floor(self.WDataRate).." bps")
	self:NextThink(CurTime()+self.Interval)

	return true
end

function ENT:ReadCell( Address )
	Address = math.floor(Address)
	if (self.Memory) then
		if (self.Memory.LatchStore and self.Memory.LatchStore[math.floor(Address)]) then
			self.HDataBytes = self.HDataBytes + 1
			return self.Memory.LatchStore[math.floor(Address)]
		elseif (self.Memory.ReadCell) then
			self.HDataBytes = self.HDataBytes + 1
			local val = self.Memory:ReadCell(Address)
			if (val) then return val
			else return 0 end
		end
	end
	return nil
end

function ENT:WriteCell( Address, value )
	Address = math.floor(Address)
	if (self.Memory) then
		if (self.Memory.LatchStore and self.Memory.LatchStore[math.floor(Address)]) then
			self.Memory.LatchStore[math.floor(Address)] = value
			self.HDataBytes = self.HDataBytes + 1
			return true
		elseif (self.Memory.WriteCell) then
			local res = self.Memory:WriteCell(Address, value)
			self.HDataBytes = self.HDataBytes + 1
			return res
		end
	end
	return false
end

function ENT:TriggerInput(iname, value)
	if (iname == "Input") then
		self.Memory = self.Inputs.Input.Src
		self.WDataBytes = self.WDataBytes + 1
		Wire_TriggerOutput(self, "Output", value)
	elseif (iname == "Smooth") then
		self.Smooth = 2*(1-math.Clamp(value,0,1))
	elseif (iname == "Interval") then
		self.Interval = math.Clamp(value,0.1,2)
	end
end

duplicator.RegisterEntityClass("gmod_wire_datarate", WireLib.MakeWireEnt, "Data")
