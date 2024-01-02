AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Address Bus"
ENT.WireDebugName 	= "AddressBus"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self.Outputs = Wire_CreateOutputs(self, {"Memory"})
	self.Inputs = Wire_CreateInputs(self,{"Memory1","Memory2","Memory3","Memory4"})
	self.DataRate = 0
	self.DataBytes = 0

	self.Memory = {}
	self.MemStart = {}
	self.MemEnd = {}
	self.MemOffsets = {}
	for i = 1,4 do
		self.Memory[i] = nil
		self.MemStart[i] = 0
		self.MemEnd[i] = 0
		self.MemOffsets[i] = 0
	end
	self:SetOverlayText("Data rate: 0 bps")
end

function ENT:Setup(Mem1st, Mem2st, Mem3st, Mem4st, Mem1sz, Mem2sz, Mem3sz, Mem4sz, Mem1rw, Mem2rw, Mem3rw, Mem4rw)
	local starts = {Mem1st,Mem2st,Mem3st,Mem4st}
	local sizes =  {Mem1sz,Mem2sz,Mem3sz,Mem4sz}
	local offsets = {Mem1rw,Mem2rw,Mem3rw,Mem4rw}
	for i = 1,4 do
		starts[i] = tonumber(starts[i]) or 0
		sizes[i] = tonumber(sizes[i]) or 0

		self.MemStart[i] = starts[i]
		self.MemEnd[i] = starts[i] + sizes[i] - 1
		self.MemOffsets[i] = offsets[i] or 0
		self["Mem"..i.."st"] = starts[i]
		self["Mem"..i.."sz"] = sizes[i]
		self["Mem"..i.."rw"] = offsets[i]
	end
end

function ENT:Think()
	BaseClass.Think(self)

	self.DataRate = self.DataBytes
	self.DataBytes = 0

	Wire_TriggerOutput(self, "Memory", self.DataRate)
	self:SetOverlayText("Data rate: "..math.floor(self.DataRate*2).." bps")
	self:NextThink(CurTime()+0.5)
	return true
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	for i = 1,4 do
		if (Address >= self.MemStart[i]) and (Address <= self.MemEnd[i]) then
			if self.Memory[i] then
				if self.Memory[i].ReadCell then
					self.DataBytes = self.DataBytes + 1
					local val = self.Memory[i]:ReadCell(Address + self.MemOffsets[i] - self.MemStart[i])
					return val or 0
				end
			else
				return 0
			end
		end
	end
	return nil
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	local res = false
	for i = 1,4 do
		if (Address >= self.MemStart[i]) and (Address <= self.MemEnd[i]) then
			if self.Memory[i] then
				if self.Memory[i].WriteCell then
					self.Memory[i]:WriteCell(Address + self.MemOffsets[i] - self.MemStart[i], value)
				end
			end
			self.DataBytes = self.DataBytes + 1
			res = true
		end
	end
	return res
end

function ENT:TriggerInput(iname, value)
	for i = 1,4 do
		if iname == "Memory"..i then
			self.Memory[i] = self.Inputs["Memory"..i].Src
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_addressbus", WireLib.MakeWireEnt, "Data", "Mem1st", "Mem2st", "Mem3st", "Mem4st", "Mem1sz", "Mem2sz", "Mem3sz", "Mem4sz", "Mem1rw", "Mem2rw", "Mem3rw", "Mem4rw")
