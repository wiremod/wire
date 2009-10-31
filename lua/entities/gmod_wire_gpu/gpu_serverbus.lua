function ENT:InitializeBus()
	self.CachingEnabled = true
	self.MemoryCache = {}
	self.MemoryCacheBase = 0
	self.MemoryCachePos = 0
	self.MemoryCacheSize = 0
	for i=0,31 do
		self.MemoryCache[i] = 0
	end
end

function ENT:Write(value)
	if (tonumber(value) ~= nil) && (value) then
		self:WriteCell(self.WIP,value)
	end
	self.WIP = self.WIP + 1
end

function ENT:Notify(message, value)
	local rp = RecipientFilter()
	if (self.ForcePlayer) then
		rp:AddPlayer(self.ForcePlayer)
		if not self.ForcePlayer:IsValid() then rp = false end -- player left => abort send
	else
		rp:AddAllPlayers()
	end

	if rp then
		umsg.Start(message, rp)
			umsg.Long(self:EntIndex())
			umsg.Long(value)
		umsg.End()
	end
end

function ENT:FlushCache()
	local rp = RecipientFilter()
	if (self.ForcePlayer) then
		rp:AddPlayer(self.ForcePlayer)
		if not self.ForcePlayer:IsValid() then rp = false end -- player left => abort send
	else
		rp:AddAllPlayers()
	end

	if rp then
		umsg.Start("wiregpu_memorymessage", rp)
			umsg.Long(self:EntIndex())
			umsg.Long(self.MemoryCacheBase)
			umsg.Long(self.MemoryCacheSize)
			for i=0,self.MemoryCacheSize-1 do
				if (self.MemoryCache[i]) then
					umsg.Float(self.MemoryCache[i])
				else
					umsg.Float(0)
				end
			end
		umsg.End()
	end

	self.MemoryCacheSize = 0
	self.MemoryCacheBase = 0
end

function ENT:ReadCell(Address)
	if (Address < 0) || (Address > 65536) then
		return nil
	else
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	end
end

function ENT:WriteCell(Address, value)
	if (Address < 0) || (Address > 65536) then
		return false
	else
		//0. Write it to internal memory
		self.Memory[Address] = value

		if (self.CachingEnabled == true) && (Address ~= 65535) && (Address ~= 65534) then
			//1. Check if address recieved is in current memory cache
			if ((Address >= self.MemoryCacheBase) &&
			    (Address < self.MemoryCacheBase+self.MemoryCacheSize)) then
				//1a. Address is inside memory cache. Just alter cache
				self.MemoryCache[Address - self.MemoryCacheBase] = value
				return true
			end

			//2. Check if address is on boundary of current memory cache, and we can still add to cache
			if ((Address == self.MemoryCacheBase+self.MemoryCacheSize) &&
			    (self.MemoryCacheSize <= 32)) then
				self.MemoryCacheSize = self.MemoryCacheSize + 1
				self.MemoryCache[Address - self.MemoryCacheBase] = value
				return true
			end

			//3. It did not write to cache. Purge old cache, and create new one
			self:FlushCache()
			self.MemoryCacheSize = 1
			self.MemoryCacheBase = Address
			self.MemoryCache[0] = value
		else
			local rp = RecipientFilter()
			if (self.ForcePlayer) then
				rp:AddPlayer(self.ForcePlayer)
				if not self.ForcePlayer:IsValid() then rp = false end -- player left => abort send
			else
				rp:AddAllPlayers()
			end

			if rp then
				umsg.Start("wiregpu_memorymessage", rp)
					umsg.Long(self:EntIndex())
					umsg.Long(Address)
					umsg.Long(1)
					umsg.Float(value)
				umsg.End()
			end
		end
		return true
	end
end
