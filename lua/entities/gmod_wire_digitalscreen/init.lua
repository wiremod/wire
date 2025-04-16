AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')
DEFINE_BASECLASS( "base_wire_entity" )

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
	self.Memory[1048572] = 32
	self.Memory[1048573] = 32
	self.Memory[1048575] = 1

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	self.NumOfWrites = 0
	self.UpdateRate = 0.1

	self.ChangedCellRanges = {}
	self.ChangedStep = 1
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
	Address = math.floor(Address)
	if Address < 0 then return nil end
	if Address >= 1048577 then return nil end

	return self.Memory[Address] or 0
end

function ENT:MarkCellChanged(Address)
	self.NumOfWrites = self.NumOfWrites + 1

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
		str[j] = string.char(number % 256)
		number = math.floor(number / 256)
	end
	t[#t+1] = table.concat(str)
end

----------------------------------------------------
-- Processing limiters and global bandwidth limiters
local maxProcessingTime = engine.TickInterval() * 0.9
local defaultMaxBandwidth = 10000 -- 10k per screen max limit - is arbitrary. needs to be smaller than the global limit.
local defaultMaxGlobalBandwidth = 20000 -- 20k is a good global limit in my testing. higher than that seems to cause issues
local maxBandwidth = defaultMaxBandwidth
local globalBandwidthLookup = {}
local function calcGlobalBW()
	maxBandwidth = defaultMaxGlobalBandwidth
	local n = 0

	-- count the number of digi screens currently sending data
	for digi in pairs(globalBandwidthLookup) do
		if not IsValid(digi) then globalBandwidthLookup[digi] = nil end -- this most likely won't trigger due to OnRemove, but just in case
		n = n + 1
	end

	-- player count also seems to affect lag somewhat
	-- it seems logical that this would have something to do with the upload bandwidth of the server
	-- but that seems unlikely since testing shows that the amount of data sent isn't very high
	-- it's more likely that the net message library just isn't very efficient
	-- the numbers here are picked somewhat arbitrarily, with a bit of guessing.
	-- change in the future if necessary.
	n = n + math.max(0,player.GetCount()-2) / 4

	-- during testing, lag seems to increase somewhat faster as more net messages are sent at the same time
	-- so we double this value to compensate
	n = n * 2

	maxBandwidth = math.max(100,math.Round(math.min(defaultMaxBandwidth,maxBandwidth / n),2))
end
local function addGlobalBW(e)
	globalBandwidthLookup[e] = true
	calcGlobalBW()
end
local function removeGlobalBW(e) globalBandwidthLookup[e] = nil end
----------------------------------------------------

function ENT:OnRemove()
	BaseClass.OnRemove(self)
	removeGlobalBW(self)
end

local function buildData(datastr, memory, pixelbit, range, bytesRemaining, sTime)
	if bytesRemaining < 15 then return 0 end
	local lengthIndex = #datastr+1
	datastr[lengthIndex] = "000"
	numberToString(datastr,range.start,3) -- Address of range
	bytesRemaining = bytesRemaining - 6
	local i, iend = range.start, range.start + range.length
	while i<iend and bytesRemaining>0 and SysTime() - sTime < maxProcessingTime do
		if i>=1048500 then
			numberToString(datastr,memory[i],2)
			bytesRemaining = bytesRemaining - 2
		else
			numberToString(datastr,memory[i],pixelbit)
			bytesRemaining = bytesRemaining - pixelbit
		end
		i = i + 1
	end
	local lengthStr = {}
	numberToString(lengthStr,i - range.start,3) -- Length of range
	datastr[lengthIndex] = lengthStr[1]
	range.length = iend - i
	range.start = i

	return bytesRemaining
end

util.AddNetworkString("wire_digitalscreen")


local pixelbits = {3, 1, 3, 4, 1} --The compressed pixel formats are in bytes
function ENT:FlushCache(ply)
	if not next(self.ChangedCellRanges) then
		removeGlobalBW(self)
		return
	end

	local pixelformat = (math.floor(self.Memory[1048569]) or 0) + 1
	if pixelformat < 1 or pixelformat > #pixelbits then pixelformat = 1 end
	local pixelbit = pixelbits[pixelformat]
	local bytesRemaining = 32768
	local datastr = {}

	local range = self.ChangedCellRanges[self.ChangedStep]
	local sTime = SysTime()
	while range and bytesRemaining>0 and SysTime() - sTime < maxProcessingTime do
		bytesRemaining = buildData(datastr, self.Memory, pixelbit, range, bytesRemaining, sTime)
		if range.length==0 then
			self.ChangedStep = self.ChangedStep + 1
			range = self.ChangedCellRanges[self.ChangedStep]
		end
	end

	local n = #self.ChangedCellRanges

	self.deltaStep = (self.deltaStep or 0) * 0.5 + self.ChangedStep * 0.5
	self.deltaN = (self.deltaN or 0) * 0.5 + n * 0.5

	if
		-- reset queue if we've reached the end
		self.ChangedStep > n or

		-- if the queue length keeps growing faster than we can process it, just clear it
		-- this check is mostly to detect the worst possible case where the user spams single random pixels
		(n > self.ScreenWidth * self.ScreenHeight and self.deltaStep * 4 < self.deltaN) then

		self.ChangedCellRanges = {}
		self.ChangedStep = 1
	end

	numberToString(datastr,0,3)
	datastr = util.Compress(table.concat(datastr))
	local len = #datastr

	net.Start("wire_digitalscreen")
	net.WriteUInt(self:EntIndex(),16)
	net.WriteUInt(pixelformat, 5)
	net.WriteUInt(len, 32)
	net.WriteData(datastr,len)

	addGlobalBW(self)
	self.UpdateRate = math.Round(math.max(len / maxBandwidth, 0.05),2)

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
		i = i * 3
		self.Memory[i] = 0
		self.Memory[i+1] = 0
		self.Memory[i+2] = 0
		self:MarkCellChanged(i)
		self:MarkCellChanged(i+1)
		self:MarkCellChanged(i+2)
		return
	end

	-- other modes
	self.Memory[i] = 0
	self:MarkCellChanged(i)
end

function ENT:ClearCellRange(start, length)
	for i = start, start + length - 1 do
		self.Memory[i] = 0
		self:MarkCellChanged(i)
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor (Address)
	value = math.floor(value or 0)
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
			value = math.Clamp(value, 0, 9)
		elseif Address == 1048570 then -- Clear row
			local row = math.Clamp(value, 0, self.ScreenHeight-1)
			if self.Memory[1048569] == 1 then
				self:ClearCellRange(row*self.ScreenWidth*3, self.ScreenWidth*3)
			else
				self:ClearCellRange(row*self.ScreenWidth, self.ScreenWidth)
			end
		elseif Address == 1048571 then -- Clear column
			local col = math.Clamp(value, 0, self.ScreenWidth-1)
			for i = col,col+self.ScreenWidth*(self.ScreenHeight-1),self.ScreenWidth do
				self:ClearPixel(i)
			end
		elseif Address == 1048572 then -- Height
			self.ScreenHeight = math.Clamp(value, 1, 512)
		elseif Address == 1048573 then -- Width
			self.ScreenWidth  = math.Clamp(value, 1, 512)
		elseif Address == 1048574 then -- Hardware Clear Screen

			-- delete changed cells
			self.ChangedCellRanges = {}
			self.ChangedStep = 1

			-- copy every value above pixel data
			local mem = {}
			for addr = 1048500,1048575 do
				mem[addr] = self.Memory[addr]

				if self.Memory[addr] then
					-- re-mark cell changed
					self:MarkCellChanged(addr)
				end
			end

			-- reset memory
			self.Memory = mem
		elseif Address == 1048575 then -- CLK
			-- not needed atm
		end
	end

	self.Memory[Address] = value

	self:MarkCellChanged(Address)

	return true
end

function ENT:Think()
	self:FlushCache()
	self:NextThink(CurTime()+self.UpdateRate)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "PixelX") then
		self.PixelX = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelY") then
		self.PixelY = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelG") then
		self.PixelG = math.floor(value)
		self:SendPixel()
	elseif (iname == "Clk") then
		self:WriteCell(1048575, value)
		self:SendPixel()
	elseif (iname == "FillColor") then
		self:WriteCell(1048574,value)
	elseif (iname == "ClearCol") then
		self:WriteCell(1048571,math.Clamp( value, 0, 31 ))
	elseif (iname == "ClearRow") then
		self:WriteCell(1048570,math.Clamp( value, 0, 31 ))
	end
end

duplicator.RegisterEntityClass("gmod_wire_digitalscreen", WireLib.MakeWireEnt, "Data", "ScreenWidth", "ScreenHeight")
