AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.WireDebugName = "WireHDD"
ENT.OverlayDelay = 0

function ENT:OnRemove()
	self:SaveCachedBlock()
end

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetUseType(SIMPLE_USE)

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Data" })
	self.Inputs = Wire_CreateInputs(self.Entity, { "Clk", "AddrRead", "AddrWrite", "Data" })

	self.Clk = 0
	self.AWrite = 0
	self.ARead = 0
	self.Data = 0
	self.Out = 0

	self.BlockSize = 16

	//Hard drive id/folder id:
	self.DriveID = 0
	self.PrevDriveID = -1
	//Hard drive capicacity (loaded from hdd)
	self.DriveCap = 0

	//Cache for read/written values
	self.ReadCache = {}
	//Shows whether block is cached for reading
	self.BlockCached = {}

	//Current sector cache
	self.Cache = {}
	for i = 0,self.BlockSize-1 do
		self.Cache[i] = 0
	end
	//Block that is cached
	self.CachedBlock = -1
	self.CacheWrites = 0
	//Owners STEAMID
	self.owner_steamid = "SINGLEPLAYER"

	self:SetOverlayText("Flash memory")
end

function ENT:GetStructName(name)
	return "WireFlash\\"..(self.owner_steamid or "UNKNOWN").."\\HDD"..self.DriveID.."\\"..name..".txt"
end

function ENT:GetCap()
	//If hard drive exists
	if (file.Exists(self:GetStructName("drive"))) then
		//Read size cap
		local sizecap = file.Read(self:GetStructName("drive"))
		//If it is a number
		if (tonumber(sizecap)) then
			self.DriveCap = tonumber(sizecap)
		else
			file.Write(self:GetStructName("drive"), self.DriveCap)
		end
	else
		file.Write(self:GetStructName("drive"), self.DriveCap)
	end

	//Can't have cap bigger than 256 in MP
	if ((!SinglePlayer()) && (self.DriveCap > 256)) then
		self.DriveCap = 256
	end
end

function ENT:UpdateCap()
	//Can't have cap bigger than 256 in MP
	if ((!SinglePlayer()) && (self.DriveCap > 256)) then
		self.DriveCap = 256
	end
	file.Write(self:GetStructName("drive"), self.DriveCap)

	self:GetCap()
end

function ENT:GetFloatTable(Text)
	local text = Text
	local tbl = {}
	local ptr = 0
	while (string.len(text) > 0) do
		local value = string.sub(text,1,24)
		text = string.sub(text,24,string.len(text))
		tbl[ptr] = tonumber(value)
		ptr = ptr + 1
	end
	return tbl
end

function ENT:MakeFloatTable(Table)
	local text = ""
	for i=0,table.Count(Table)-1 do
		//Clamp size to 24 chars
		local floatstr = string.sub(tostring(Table[i]),1,24)
		//Make a string, and append missing spaces
		floatstr = floatstr .. string.rep(" ",24-string.len(floatstr))

		text = text..floatstr
	end

	return text
end

function ENT:ReadCell(Address)
	//DriveID should be > 0, and less than  4 in MP
	if ((self.DriveID < 0) || (!SinglePlayer() && (self.DriveID >= 4))) then
		return nil
	end

	local player = self.pl
	if (player:IsValid()) then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		if (steamid ~= "UNKNOWN") then
			self.owner_steamid = steamid
		else
			self.owner_steamid = "SINGLEPLAYER"
		end

		//If drive has changed, change cap
		if (self.DriveID ~= self.PrevDriveID) then
			self:GetCap()
			self.PrevDriveID = self.DriveID
		end

		//Check if address is valid
		if ((Address < self.DriveCap * 1024) && (Address >= 0)) then
			//1. Check if this address is cached for read
			if (self.ReadCache[Address]) then
				return self.ReadCache[Address]
			end

			//2. Read sector
			local block = math.floor(Address / self.BlockSize)
			local blockaddress = math.floor(Address) % self.BlockSize

			//If sector isn't created yet, return 0
			if (!file.Exists(self:GetStructName(block))) then
				for i=0,self.BlockSize-1 do
					self.ReadCache[block*self.BlockSize+i] = 0
				end
				self.BlockCached[block] = true
				return 0
			end

			//Read the block
			local blockdata = self:GetFloatTable(file.Read(self:GetStructName(block)))
			for i=0,self.BlockSize-1 do
				if (blockdata[i]) then
					self.ReadCache[block*self.BlockSize+i] = blockdata[i]
				else
					self.ReadCache[block*self.BlockSize+i] = 0
				end
			end
			self.BlockCached[block] = true

			return self.ReadCache[block*self.BlockSize+blockaddress]
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:SaveCachedBlock()
	if (self.CachedBlock != -1) then
		file.Write(self:GetStructName(self.CachedBlock),self:MakeFloatTable(self.Cache))
	end
	self.CacheWrites = 0
end

function ENT:WriteCell(Address, value)
	//DriveID should be > 0, and less than  4 in MP
	if ((self.DriveID < 0) || (!SinglePlayer() && (self.DriveID >= 4))) then
		return false
	end

	local player = self.pl
	if (player:IsValid()) then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		if (steamid ~= "UNKNOWN") then
			self.owner_steamid = steamid
		else
			self.owner_steamid = "SINGLEPLAYER"
		end

		//If drive has changed, change cap
		if (self.DriveID ~= self.PrevDriveID) then
			self:GetCap()
			self.PrevDriveID = self.DriveID
		end

		//Check if address is valid
		if ((Address < self.DriveCap * 1024) && (Address >= 0)) then
			local block = math.floor(Address / self.BlockSize)
			local blockaddress = math.floor(Address) % self.BlockSize

			//1. Check if this sector isn't the one which is cached
			//   If no, make it current block
			if (self.CachedBlock != block) then
				//Save previous one
				self:SaveCachedBlock()

				//Check if this block is cached for read
				if (!self.BlockCached[block]) then
					//If sector isn't created yet, return 0
					if (!file.Exists(self:GetStructName(block))) then
						for i=0,self.BlockSize-1 do
							self.ReadCache[block*self.BlockSize+i] = 0
						end
					else
						//Read the block
						local blockdata = self:GetFloatTable(file.Read(self:GetStructName(block)))
						for i=0,self.BlockSize-1 do
							if (blockdata[i]) then
								self.ReadCache[block*self.BlockSize+i] = blockdata[i]
							else
								self.ReadCache[block*self.BlockSize+i] = 0
							end
						end
					end
					self.BlockCached[block] = true
				end

				//Load it from readcache
				for i=0,self.BlockSize-1 do
					self.Cache[i] = self.ReadCache[block*self.BlockSize+i]
				end
				self.CachedBlock = block
			end

			//Write to the block
			self.Cache[blockaddress] = value
			self.ReadCache[Address] = value
			self.CacheWrites = self.CacheWrites + 1

			//If under 256 writes to same sector, dont dump sector to disk
			if (self.CacheWrites > 256) then
				self:SaveCachedBlock()
			end
			return true
		else
			return false
		end
	else
		return false
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
			if (self.ARead == self.AWrite) then
				local val = self:ReadCell(self.ARead)
				if (val) then
					Wire_TriggerOutput(self.Entity, "Data", val)
					self.Out = val
				end
			end
		end
	elseif (iname == "AddrRead") then
		self.ARead = value
		local val = self:ReadCell(value)
		if (val) then
			Wire_TriggerOutput(self.Entity, "Data", val)
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
					Wire_TriggerOutput(self.Entity, "Data", val)
					self.Out = val
				end
			end
		end
	end

	self:SetOverlayText("Flash memory  - "..self.DriveCap.."kb".."\nWriteAddr:"..self.AWrite.."  Data:"..self.Data.."  Clock:"..self.Clk..
        	                                                     "\nReadAddr:"..self.ARead.." = ".. self.Out)
end
