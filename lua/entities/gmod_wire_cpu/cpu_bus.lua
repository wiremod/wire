function ENT:Write(value)
	if (tonumber(value) ~= nil) && (value) then
		if (self.UseROM == true) then
			if (self.WIP < 65536) then
				self.ROMMemory[self.WIP] = value
			end
		end

		self:WriteCell(self.WIP,value)
		if (self.Debug) && (value != 0) then
			Msg("-> ZyeliosASM: Wrote "..value.." at ["..self.WIP.."]\n")
		end
	end
	self.WIP = self.WIP + 1
end

function ENT:ReadCell(Address)
	if (not Address) then
		if (self.Debug) then
			print("Non-existant address fed into address bus (read)!")
		end
		return nil
	end

	Page = math.floor(Address / 128)
	if (not self:Is48bitInteger(Address)) then
		self:Interrupt(15,Address)
		return nil
	end

	if (self.BusLock == 1) then
		if (self.Debug) then self:DebugMessage("Warning: Bus was read while locked") end
		return nil
	end

	//Map address
	if ((self.Page[Page]) and (self.Page[Page].MappedTo) and (self.Page[Page].MappedTo ~= Page)) then
		Address = Address % 128 + self.Page[Page].MappedTo*128
	end

	if (Address < 0) then
		return self:ReadPort(-Address-1)
	end

	if ((self.EF == 1) && (self.Page[Page])
	 && (self.Page[Page].Read == 0) && (self.CurrentPage.RunLevel > self.Page[Page].RunLevel)) then //Page protection
		self:Interrupt(12,Address)
		return nil
	end

	if (Address < 65536) then
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	else
		if (self.Inputs.MemBus.Src) then
			if (self.Inputs.MemBus.Src.ReadCell) then
				local var = self.Inputs.MemBus.Src:ReadCell(Address-65536)
				if (var) then
					return var
				else
					self:Interrupt(7,Address)
					return nil
				end
			else
				self:Interrupt(8,Address)
				return nil
			end
		else
			self:Interrupt(7,Address)
			return nil
		end
	end
end

function ENT:WriteCell(Address, value)
	if (not Address) then
		if (self.Debug) then
			print("Non-existant address fed into address bus (write)!")
		end
		return nil
	end

	Page = math.floor(Address / 128)
	if (not self:Is48bitInteger(Address)) then
		self:Interrupt(15,Address)
		return false
	end

	if (self.BusLock == 1) then
		if (self.Debug) then self:DebugMessage("Warning: Bus was written while locked") end
		return false
	end

	//Map address
	if ((self.Page[Page]) and (self.Page[Page].MappedTo) and (self.Page[Page].MappedTo ~= Page)) then
		Address = Address % 128 + self.Page[Page].MappedTo*128
	end

	if (Address < 0) then
		return self:WritePort(-Address-1,value)
	end

	if (self.PrecompileMemory[Address]) then //If this byte was precompiled
		local xeip = self.PrecompileMemory[Address]
		self.PrecompileMemory[Address] = nil //Void precompile information
		self.PrecompileData[xeip] = nil
	end

	if ((self.EF == 1) && (self.Page[Page])
	 && (self.Page[Page].Write == 0) && (self.CurrentPage.RunLevel > self.Page[Page].RunLevel)) then //Page protection
		self:Interrupt(9,Address)
		return false
	end

	if (Address < 65536) then
		self.Memory[Address] = value
		return true
	else
		if (self.Inputs.MemBus.Src) then
			if (self.Inputs.MemBus.Src.WriteCell) then
				if (self.Inputs.MemBus.Src:WriteCell(Address-65536,value)) then
					return true
				else
					self:Interrupt(7,Address)
					return false
				end
			else
				self:Interrupt(8,Address)
				return false
			end
		else
			self:Interrupt(7,Address)
			return false
		end
	end
	return true
end

//TODO: Move readport and writeport in write and read

function ENT:ReadPort(Address)
	if (self.BusLock == 1) then
		if (self.Debug) then self:DebugMessage("Warning: IOBus was read while locked") end
		return nil
	end

	if (Address < 0) then
		self:Interrupt(10,Address)
		return nil
	end
	if (self.Inputs.IOBus.Src) then
		if (self.Inputs.IOBus.Src.ReadCell) then
			local var = self.Inputs.IOBus.Src:ReadCell(math.floor(Address))
			if (var) then
				return var
			else
				self:Interrupt(10,Address)
				return nil
			end
		else
			self:Interrupt(8,-Address)
			return nil
		end
	else
		return 0
	end
end

function ENT:WritePort(Address, value)
	if (self.BusLock == 1) then
		if (self.Debug) then self:DebugMessage("Warning: IOBus was written while locked") end
		return false
	end

	if (Address < 0) then
		self:Interrupt(10,Address)
		return false
	end
	if (self.Inputs.IOBus.Src) then
		if (self.Inputs.IOBus.Src.WriteCell) then
			if (self.Inputs.IOBus.Src:WriteCell(math.floor(Address),value)) then
				return true
			else
				self:Interrupt(10,Address)
				return false
			end
		else
			self:Interrupt(8,-Address)
			return false
		end
	else
		return true
	end
end

function ENT:Push(value)
	if (self.BusLock == 1) then
		if (self.Debug) then self:DebugMessage("Warning: Stack write while locked") end
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
		if (self.Debug) then self:DebugMessage("Warning: Stack read while locked") end
		return nil
	end

	self.ESP = self.ESP + 1
	if (self.ESP > self.ESZ) then
		self.ESP = self.ESZ
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
