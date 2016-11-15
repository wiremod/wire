AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

function ENT:Initialize()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self, { "PixelX", "PixelY", "PixelG", "Clk", "FillColor", "ClearRow", "ClearCol" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })

	self.Memory = {}

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Memory[1048569] = 0
	self.Memory[1048575] = 1

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	self.ChangedCellRanges = {}
end

function ENT:Setup(ScreenWidth, ScreenHeight)
	self:WriteCell(1048572, ScreenHeight or 32)
	self:WriteCell(1048573, ScreenWidth or 32)
end

function ENT:SendPixel()
	if self.Memory[1048575] == 0 then return end -- why?
	if self.PixelX < 0 then return end
	if self.PixelY < 0 then return end
	if self.PixelX >= self.ScreenWidth then return end
	if self.PixelY >= self.ScreenHeight then return end

	local address = self.PixelY*self.ScreenWidth + self.PixelX
	self:WriteCell(address, self.PixelG)
end

function ENT:ReadCell(Address)
	if Address < 0 then return nil end
	if Address >= 1048577 then return nil end

	return self.Memory[Address] or 0
end

function ENT:MarkCellChanged(Address)
	local lastrange = self.ChangedCellRanges[#self.ChangedCellRanges]
	if lastrange then
		if Address == lastrange.start + lastrange.length then
			-- wrote just after the end of the range, append
			lastrange.length = lastrange.length + 1
		elseif Address == lastrange.start - 1 then
			-- wrote just before the start of the range, prepend
			lastrange.start = lastrange.start - 1
			lastrange.length = lastrange.length + 1
		elseif Address < lastrange.start - 1 or Address > lastrange.start + lastrange.length then
			-- wrote outside the range
			lastrange = nil
		end
	end
	if not lastrange then
		lastrange = {
			start = Address,
			length = 1
		}
		self.ChangedCellRanges[#self.ChangedCellRanges + 1] = lastrange
	end
end

local function numberToString(t, number, bytes)
	local str = {}
	for j=1,bytes do
		str[#str+1] = string.char(number % 256)
		number = math.floor(number / 256)
    end
	t[#t+1] = table.concat(str)
end

util.AddNetworkString("wire_digitalscreen")

local pixelbits = {20, 8, 24, 30, 8, 3, 1, 3, 4, 1} --The compressed pixel formats are in bytes
function ENT:FlushCache(ply)
	if not next(self.ChangedCellRanges) then return end
	
	local compression = self.Memory[1048576] or 1
	local pixelformat = (self.Memory[1048569] or 0) + 1
	local pixelbit = pixelbits[pixelformat]
	local bitsremaining = 480000
	local buildData
	local datastr
	
	if compression==0 then
		buildData = function(start, length)
			net.WriteUInt(length, 20) -- Length of range
			net.WriteUInt(start, 20) -- Address of range
			for i = start, start + length - 1 do
				if i>=1048500 then
					net.WriteUInt(self.Memory[i], 10)
				else
					net.WriteUInt(self.Memory[i], pixelbit)
				end
			end
		end
	else
		datastr = {}
		pixelbit = pixelbits[pixelformat+5]
		
		buildData = function(start, length)
			numberToString(datastr,length,3) -- Length of range
			numberToString(datastr,start,3) -- Address of range
			for i = start, start + length - 1 do
				if i>=1048500 then
					numberToString(datastr,self.Memory[i],2)
				else
					numberToString(datastr,self.Memory[i],pixelbit)
				end
			end
		end
	end
	
	net.Start("wire_digitalscreen")
	net.WriteUInt(self:EntIndex(),16)
	net.WriteUInt(compression,1)
	net.WriteUInt(pixelformat, 5)
	bitsremaining = bitsremaining - 22
	
	while bitsremaining>0 and next(self.ChangedCellRanges) do
		local range = self.ChangedCellRanges[1]
		local start = range.start
		local length = math.min(range.length, math.ceil(bitsremaining/pixelbit)) --Estimate how many numbers to read from the range
		
		range.length = range.length - length --Update the range and remove it if its empty
		range.start = start + length
		if range.length==0 then table.remove(self.ChangedCellRanges, 1) end
		
		buildData(start, length)
		
		bitsremaining = bitsremaining - length*pixelbit
	end
		
	if compression==0 then
		net.WriteUInt(0, 20)
	else
		numberToString(datastr,0,3)
		local compressed = util.Compress(table.concat(datastr))
		net.WriteData(compressed,#compressed)
	end
	
	if ply then net.Send(ply) else net.Broadcast() end
end

function ENT:Retransmit(ply)
	self:FlushCache() -- Empty the cache
	
	self:MarkCellChanged(1048569) -- Colormode
	self:MarkCellChanged(1048572) -- Screen Width
	self:MarkCellChanged(1048573) -- Screen Height
	self:MarkCellChanged(1048575) -- Clk
	self:FlushCache(ply)
	
	local memory = self.Memory
	for addr=0, self.ScreenWidth*self.ScreenHeight do
		if memory[addr] then
			self:MarkCellChanged(addr)
		end
	end
	self:MarkCellChanged(1048575) -- Clk
	self:FlushCache(ply)
end

function ENT:ClearPixel(i)
	if self.Memory[1048569] == 1 then
		-- R G B mode
		self.Memory[i*3] = 0
		self.Memory[i*3+1] = 0
		self.Memory[i*3+2] = 0
		return
	end

	-- other modes
	self.Memory[i] = 0
end

function ENT:ClearCellRange(start, length)
	for i = start, start + length - 1 do
		self.Memory[i] = 0
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	if Address < 0 then return false end
	if Address >= 1048577 then return false end

	if Address < 1048500 then -- RGB data
		if self.Memory[Address] == value or
		   (value == 0 and self.Memory[Address] == nil) then
			return true
		end
	else
		if Address == 1048569 then 
			-- Color mode (0: RGBXXX; 1: R G B; 2: 24 bit RGB; 3: RRRGGGBBB; 4: XXX)
			value = math.Clamp(math.floor(value or 0), 0, 9)
		elseif Address == 1048570 then -- Clear row
			local row = math.Clamp(math.floor(value), 0, self.ScreenHeight-1)
			if self.Memory[1048569] == 1 then
				self:ClearCellRange(row*self.ScreenWidth*3, self.ScreenWidth*3)
			else
				self:ClearCellRange(row*self.ScreenWidth, self.ScreenWidth)
			end
		elseif Address == 1048571 then -- Clear column
			local col = math.Clamp(math.floor(value), 0, self.ScreenWidth-1)
			for i = col,col+self.ScreenWidth*(self.ScreenHeight-1),self.ScreenWidth do
				self:ClearPixel(i)
			end
		elseif Address == 1048572 then -- Height
			self.ScreenHeight = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048573 then -- Width
			self.ScreenWidth  = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048574 then -- Hardware Clear Screen
			local mem = {}
			for addr = 1048500,1048575 do
				mem[addr] = self.Memory[addr]
			end
			self.Memory = mem
			-- clear pixel data from usermessage queue
			local i = 1
			while self.ChangedCellRanges[i] ~= nil do
				if self.ChangedCellRanges[i].start + self.ChangedCellRanges[i].length < 1048500 then
					table.remove(self.ChangedCellRanges, i)
				else
					i = i + 1
				end
			end
		--elseif Address == 1048575 then -- CLK
			-- not needed atm
		end
	end

	self.Memory[Address] = value

	self:MarkCellChanged(Address)

	return true
end

function ENT:Think()
	self:FlushCache()
	self:NextThink(CurTime()+0.2)
	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "PixelX" then
		self.PixelX = math.floor(value)
		self:SendPixel()
	elseif iname == "PixelY" then
		self.PixelY = math.floor(value)
		self:SendPixel()
	elseif iname == "PixelG" then
		self.PixelG = math.floor(value)
		self:SendPixel()
	elseif iname == "Clk" then
		self:WriteCell(1048575, value)
		self:SendPixel()
	elseif iname == "FillColor" then
		self:WriteCell(1048574,value)
	elseif iname == "ClearCol" then
		self:WriteCell(1048571,math.Clamp( value, 0, 31 ))
	elseif iname == "ClearRow" then
		self:WriteCell(1048570,math.Clamp( value, 0, 31 ))
	end
end

duplicator.RegisterEntityClass("gmod_wire_digitalscreen", WireLib.MakeWireEnt, "Data", "ScreenWidth", "ScreenHeight")
