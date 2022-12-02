AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Flash EEPROM"
ENT.WireDebugName 	= "WireHDD"

if CLIENT then return end -- No more client

function ENT:OnRemove()
	for k,v in pairs(self.CacheUpdated) do
		file.Write(self:GetStructName(k),self:MakeFloatTable(self.Cache[k]))
	end
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self.Outputs = Wire_CreateOutputs(self, { "Data", "Capacity", "DriveID" })
	self.Inputs = Wire_CreateInputs(self, { "Clk", "AddrRead", "AddrWrite", "Data" })

	self.Clk = 0
	self.AWrite = 0
	self.ARead = 0
	self.Data = 0
	self.Out = 0

	-- Flash type
	--   0: compatibility 16 values per block mode
	--   1: 128 values per block mode
	self.FlashType = 0
	self.BlockSize = 16

	-- Hard drive id/folder id:
	self.DriveID = 0
	self.PrevDriveID = nil

	-- Hard drive capicacity (loaded from hdd)
	self.DriveCap = 0
	self.MaxAddress = 0

	-- Current cache (array of blocks)
	self.Cache = {}
	self.CacheUpdated = {}

	-- Owners STEAMID
	self.Owner_SteamID = "SINGLEPLAYER"
	self:NextThink(CurTime()+1.0)
end

function ENT:Setup(DriveID, DriveCap)
	self.DriveID = DriveID
	self.DriveCap = DriveCap
	self:UpdateCap()
	self:SetOverlayText(self.DriveCap.."kb".."\nWriteAddr:"..self.AWrite.."  Data:"..self.Data.."  Clock:"..self.Clk.."\nReadAddr:"..self.ARead.." = ".. self.Out)
	Wire_TriggerOutput(self, "DriveID", self.DriveID)
end

function ENT:GetStructName(name)
	return "WireFlash/"..(self.Owner_SteamID or "UNKNOWN").."/HDD"..self.DriveID.."/"..name..".txt"
end

function ENT:GetCap()
	-- If hard drive exists
	if file.Exists(self:GetStructName("drive"),"DATA") then
		-- Read format data
		local formatData = file.Read(self:GetStructName("drive"),"DATA")

		if tonumber(formatData) then
			self.DriveCap = tonumber(formatData)
			self.FlashType = 0
			self.BlockSize = 16
			self.MaxAddress = self.DriveCap * 1024
		else
			local formatInfo = string.Explode("\n",formatData)
			if (formatInfo[1] == "FLASH1") then
				self.DriveCap = tonumber(formatInfo[2]) or 0
				self.MaxAddress = tonumber(formatInfo[3]) or (self.DriveCap * 1024)
				self.FlashType = 1
				self.BlockSize = 32
			else
				file.Write(self:GetStructName("drive"),"FLASH1\n"..self.DriveCap.."\n"..self.MaxAddress)
			end
		end
	else
		file.Write(self:GetStructName("drive"),"FLASH1\n"..self.DriveCap.."\n"..self.MaxAddress)
		self.FlashType = 1
		self.BlockSize = 32
		self.MaxAddress = 0
	end

	--Can't have cap bigger than 256 in MP
	if (not game.SinglePlayer()) and (self.DriveCap > 256) then
		self.DriveCap = 256
	end

	Wire_TriggerOutput(self, "Capacity", self.DriveCap)
end

function ENT:UpdateCap()
	--Can't have cap bigger than 256 in MP
	if (not game.SinglePlayer()) and (self.DriveCap > 256) then
		self.DriveCap = 256
	end
	if self.FlashType == 0 then
		file.Write(self:GetStructName("drive"),self.DriveCap)
	else
		file.Write(self:GetStructName("drive"),"FLASH1\n"..self.DriveCap.."\n"..self.MaxAddress)
	end

	self:GetCap()
end

function ENT:GetFloatTable(Text)
	local text = Text
	local tbl = {}
	local ptr = 0
	while (string.len(text) > 0) do
		local value = string.sub(text, 1, 24)
		text = string.sub(text, 25)
		tbl[ptr] = tonumber(value)
		ptr = ptr + 1
	end
	return tbl
end

function ENT:MakeFloatTable(Table)
	local text = ""
	for i=0,#Table-1 do
		--Clamp size to 24 chars
		local floatstr = string.sub(tostring(Table[i]),1,24)
		--Make a string, and append missing spaces
		floatstr = floatstr .. string.rep(" ",24-string.len(floatstr))

		text = text..floatstr
	end

	return text
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	--DriveID should be > 0, and less than  4 in MP
	if ((self.DriveID < 0) or (not game.SinglePlayer() and (self.DriveID >= 4))) then
		return nil
	end

	local player = self:GetPlayer()
	if player:IsValid() then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		if (steamid ~= "UNKNOWN") then
			self.Owner_SteamID = steamid
		else
			self.Owner_SteamID = "SINGLEPLAYER"
		end

		-- If drive has changed, change cap
		if self.DriveID ~= self.PrevDriveID then
			self:GetCap()
			self.PrevDriveID = self.DriveID
		end

		-- Check if address is valid
		if (Address < self.DriveCap * 1024) and (Address >= 0) then
			-- Compute address
			local block = math.floor(Address / self.BlockSize)
			local blockaddress = math.floor(Address) % self.BlockSize

			-- Check if this address is cached for read
			if self.Cache[block] then
				return self.Cache[block][blockaddress] or 0
			end

			-- If sector isn't created yet, return 0
			if not file.Exists(self:GetStructName(block),"DATA") then
				self.Cache[block] = {}
				self.CacheUpdated[block] = true
				for i=0,self.BlockSize-1 do
					self.Cache[block][i] = 0
				end
				return 0
			end

			-- Read the block
			local blockdata = self:GetFloatTable(file.Read(self:GetStructName(block)))
			self.Cache[block] = {}
			for i=0,self.BlockSize-1 do
				self.Cache[block][i] = blockdata[i] or 0
			end
			return self.Cache[block][blockaddress]
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	--DriveID should be > 0, and less than  4 in MP
	if ((self.DriveID < 0) or (not game.SinglePlayer() and (self.DriveID >= 4))) then
		return false
	end

	local player = self:GetPlayer()
	if (player:IsValid()) then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		if (steamid ~= "UNKNOWN") then
			self.Owner_SteamID = steamid
		else
			self.Owner_SteamID = "SINGLEPLAYER"
		end

		-- If drive has changed, change cap
		if self.DriveID ~= self.PrevDriveID then
			self:GetCap()
			self.PrevDriveID = self.DriveID
		end

		-- Check if address is valid
		if (Address < self.DriveCap * 1024) and (Address >= 0) then
			-- Compute address
			local block = math.floor(Address / self.BlockSize)
			local blockaddress = math.floor(Address) % self.BlockSize

			-- Check if this address is cached
			if self.Cache[block] then
				self.CacheUpdated[block] = true
				self.Cache[block][blockaddress] = value
				if Address > self.MaxAddress then
					self.MaxAddress = Address
				end
				return true
			end

			-- If sector isn't created yet, cache it
			if not file.Exists(self:GetStructName(block),"DATA") then
				self.Cache[block] = {}
				self.CacheUpdated[block] = true
				for i=0,self.BlockSize-1 do
					self.Cache[block][i] = 0
				end
				self.Cache[block][blockaddress] = value
				if Address > self.MaxAddress then
					self.MaxAddress = Address
				end
				return true
			end

			-- Read the block
			local blockdata = self:GetFloatTable(file.Read(self:GetStructName(block)))
			self.Cache[block] = {}
			for i=0,self.BlockSize-1 do
				self.Cache[block][i] = blockdata[i] or 0
			end
			self.CacheUpdated[block] = true
			self.Cache[block][blockaddress] = value
			if Address > self.MaxAddress then
				self.MaxAddress = Address
			end
			return true
		else
			return false
		end
	else
		return false
	end
end

function ENT:Think()
	local cachedBlockIndex = next(self.CacheUpdated)
	if cachedBlockIndex then
		self.CacheUpdated[cachedBlockIndex] = nil
		file.CreateDir(string.GetPathFromFilename(self:GetStructName(cachedBlockIndex)))
		file.Write(self:GetStructName(cachedBlockIndex),self:MakeFloatTable(self.Cache[cachedBlockIndex]))
		self:UpdateCap()
	end
	self:NextThink(CurTime()+0.25)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
			if (self.ARead == self.AWrite) then
				local val = self:ReadCell(self.ARead)
				if (val) then
					Wire_TriggerOutput(self, "Data", val)
					self.Out = val
				end
			end
		end
	elseif (iname == "AddrRead") then
		self.ARead = value
		local val = self:ReadCell(value)
		if (val) then
			Wire_TriggerOutput(self, "Data", val)
			self.Out = val
		end
	elseif (iname == "AddrWrite") then
		self.AWrite = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
		end
	elseif (iname == "Data") then
		self.Data = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
			if (self.ARead == self.AWrite) then
				local val = self:ReadCell(self.ARead)
				if (val) then
					Wire_TriggerOutput(self, "Data", val)
					self.Out = val
				end
			end
		end
	end

	self:SetOverlayText(self.DriveCap.."kb".."\nWriteAddr:"..self.AWrite.."  Data:"..self.Data.."  Clock:"..self.Clk.."\nReadAddr:"..self.ARead.." = ".. self.Out)
end

duplicator.RegisterEntityClass("gmod_wire_hdd", WireLib.MakeWireEnt, "Data", "DriveID", "DriveCap")
