AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "AddressBus"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self.Outputs = Wire_CreateOutputs(self, {"Memory"})
	self.Inputs = Wire_CreateInputs(self,{"Memory1","Memory2","Memory3","Memory4"})
	self.Memory = {}
	self.MemStart = {}
	self.MemEnd = {}
	self.DataRate = 0
	self.DataBytes = 0
	for i = 1,4 do
		self.Memory[i] = nil
		self.MemStart[i] = 0
		self.MemEnd[i] = 0
	end
	self:SetOverlayText( "Address bus\nData rate: 0 bps" )
end

function ENT:Think()
	self.BaseClass.Think(self)

	self.DataRate = (self.DataRate*1.2 + self.DataBytes * 4 * 0.8) / 2
	self.DataBytes = 0

	Wire_TriggerOutput(self, "Memory", self.DataRate)

	self:SetOverlayText("Address bus\nData rate: "..math.floor(self.DataRate).." bps")
	self:NextThink(CurTime()+0.25)
end

function ENT:ReadCell( Address )
	for i = 1,4 do
		if (Address >= self.MemStart[i]) && (Address <= self.MemEnd[i]) then
			if (self.Memory[i]) then
				if (self.Memory[i].ReadCell) then
					self.DataBytes = self.DataBytes + 1
					local val = self.Memory[i]:ReadCell( Address - self.MemStart[i] )
					if (val) then
						return val
					else
						return 0
					end
				end
			else
				return 0
			end
		end
	end
	return nil
end

function ENT:WriteCell( Address, value )
	local res = false
	for i = 1,4 do
		if (Address >= self.MemStart[i]) && (Address <= self.MemEnd[i]) then
			if (self.Memory[i]) then
				if (self.Memory[i].WriteCell) then
					self.Memory[i]:WriteCell( Address - self.MemStart[i], value )
				end
			end
			self.DataBytes = self.DataBytes + 1
			res = true
		end
	end
	return res
end


function ENT:TriggerInput(iname, value)
	if (iname == "Memory1") then
		self.Memory[1] = self.Inputs.Memory1.Src
	elseif (iname == "Memory2") then
		self.Memory[2] = self.Inputs.Memory2.Src
	elseif (iname == "Memory3") then
		self.Memory[3] = self.Inputs.Memory3.Src
	elseif (iname == "Memory4") then
		self.Memory[4] = self.Inputs.Memory4.Src
	end
end
