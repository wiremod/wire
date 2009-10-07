function ENT:ReadCell(Address)
	if (not Address) then
		if (self.Debug) then
			print("Non-existant address fed into address bus (read)!")
		end
		return 0
	end


	if (not self:Is48bitInteger(Address)) then
		self:Interrupt(15,Address)
		return 0
	end

	if (Address < 0) || (Address > 65536) then
		return 0
	else
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	end
end

function ENT:WriteCell(Address, value)
	if (EmuFox and (Address ~= 65513)) then SendBytes(1) end

	if (not Address) then
		if (self.Debug) then
			print("Non-existant address fed into address bus (read)!")
		end
		return false
	end

	if (not self:Is48bitInteger(Address)) then
		self:Interrupt(15,Address)
		return false
	end

	if (self.PrecompileMemory[Address]) then //If this byte was precompiled
		local xeip = self.PrecompileMemory[Address]
		self.PrecompileMemory[Address] = nil //Void precompile information
		self.PrecompileData[xeip] = nil
	end


	if (Address < 0) || (Address > 65536) then
		return false
	else
		if (Address == 65534) then self:GPUHardReset() end
		if (Address == 65530) then self:GPURAMReset() end

		self.Memory[Address] = value
		return true
	end
end

function ENT:Push(value)
	if (self.BusLock == 1) then
		if (self.Debug) then DebugMessage("Warning: Stack write while locked") end
		return false
	end

	self:WriteCell(self.ESP+self.SS,value)
	self.ESP = self.ESP - 1
	if (self.ESP < 0) then
		self.ESP = 0
		self:Interrupt(6,self.ESP)
		return false
	end
	return true
end

function ENT:Pop()
	if (self.BusLock == 1) then
		if (self.Debug) then DebugMessage("Warning: Stack read while locked") end
		return nil
	end

	self.ESP = self.ESP + 1
	if (self.ESP > 32767) then
		self.ESP = 32767
		self:Interrupt(6,self.ESP)
		return 0
	end

	local popvalue = self:ReadCell(self.ESP+self.SS)
	if (popvalue) then
		return popvalue
	else
		self:Interrupt(6,self.ESP)
		return 0
	end
end
