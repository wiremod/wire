AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "ConsoleScreen"

function ENT:Initialize()

	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self.Entity, { "CharX", "CharY", "Char", "CharParam", "Clk", "Reset" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" })

	self.Memory = {}

	for i = 0, 2047 do
		self.Memory[i] = 0
	end

	self.CharX = 0
	self.CharY = 0
	self.Char = 0
	self.CharParam = 0

	self.Memory[2022] = 3/4
	self.Memory[2023] = 0
	self.Memory[2024] = 0
	self.Memory[2025] = 1
	self.Memory[2026] = 1
	self.Memory[2027] = 1
	self.Memory[2028] = 1
	self.Memory[2029] = 1
	self.Memory[2030] = 1
	self.Memory[2031] = 0
	self.Memory[2032] = 29
	self.Memory[2033] = 0
	self.Memory[2034] = 17
	self.Memory[2035] = 0
	self.Memory[2036] = 0

	self.Memory[2042] = 000
	self.Memory[2043] = 0.5
	self.Memory[2044] = 0.25
	self.Memory[2045] = 0
	self.Memory[2046] = 0
	self.Memory[2047] = 1 -- CLK

	self.IgnoreDataTransfer = false
	self:ResetCacheSystem()
end

function ENT:ResetCacheSystem()
	self.MemoryCache = {}
end

function ENT:SendToClient(Address, value)
	value = math.max(-99,value or 0)
	table.insert(self.MemoryCache, { Address, value })
end

local function calcoffset(offset)
	if offset < 0 then offset = 1048576 + offset end
	return -100-offset
end

function ENT:FlushCache()
	if not next(self.MemoryCache) then return end

	local bytes = 4+4
	umsg.Start("hispeed_datastream")
		umsg.Short(self:EntIndex())
		local last_address = -1

		for _,Address,value in ipairs_map(self.MemoryCache,unpack) do
			local gap = Address - (last_address+1)
			if gap ~= 0 then
				bytes = bytes + 8
			else
				bytes = bytes + 4
			end
			if bytes >= 200 then
				umsg.Float(-100)
				umsg.End()
				bytes = 4+4
				umsg.Start("hispeed_datastream")
				umsg.Short(self:EntIndex())

				last_address = -1
				gap = Address - (last_address+1)
			end
			if gap ~= 0 then
				umsg.Float(calcoffset(gap))
			end

			umsg.Float(value)
			last_address = Address
		end
		umsg.Float(-100)
	umsg.End()

	self:ResetCacheSystem()
end

function ENT:SendPixel()
	if (self.Memory[2047] ~= 0) && (self.CharX >= 0) && (self.CharX < 30) &&
	                               (self.CharY >= 0) && (self.CharY < 18) then
		local pixelno = math.floor(self.CharY)*30+math.floor(self.CharX)

		self:WriteCell(pixelno*2, self.Char)
		self:WriteCell(pixelno*2+1, self.CharParam)
	end
end

function ENT:ReadCell(Address)
	if Address < 0 then return nil end
	if Address >= 2048 then return nil end

	if Address == 2022 then return WireGPU_Monitors[self.Entity:GetModel()].RatioX end

	return self.Memory[Address]
end

function ENT:WriteCell(Address, value)
	if Address < 0 then return false end
	if Address >= 2048 then return false end

	if Address < 2000 then -- text/attribute data
		if self.Memory[Address] == value then return true end
	else
		self:ClientWriteCell(Address, value)
	end

	self.Memory[Address] = value

	self:SendToClient(Address, value)

	return true
end

function ENT:Think()
	if (self.IgnoreDataTransfer == true) then
		self.IgnoreDataTransfer = false
		self.Entity:NextThink(CurTime()+0.2)
	else
		self:FlushCache()
		self.Entity:NextThink(CurTime()+0.1)
	end
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "CharX") then
		self.CharX = value
		self:SendPixel()
	elseif (iname == "CharY") then
		self.CharY = value
		self:SendPixel()
	elseif (iname == "Char") then
		self.Char = value
		self:SendPixel()
	elseif (iname == "CharParam") then
		self.CharParam = value
		self:SendPixel()
	elseif (iname == "Clk") then
		self:WriteCell(2047, value)
		self:SendPixel()
	elseif (iname == "Reset") then
		self:WriteCell(2041,0)
		self:WriteCell(2046,0)
		self:WriteCell(2042,0)
	end
end

function ENT:ClientWriteCell(Address, value)
	if (Address == 2019) then -- Hardware Clear Viewport
		local low = math.floor(math.Clamp(self.Memory[2033],0,17))
		local high = math.floor(math.Clamp(self.Memory[2034],0,17))
		local lowc = math.floor(math.Clamp(self.Memory[2031],0,29))
		local highc = math.floor(math.Clamp(self.Memory[2032],0,29))
		for j = low, high do
			for i = 2*lowc, 2*highc+1 do
				self.Memory[i*60+value] = 0
			end
		end
	elseif (Address == 2037) then -- Shift cells (number of cells, >0 right, <0 left)
		local delta = math.abs(value)
		local low = math.floor(math.Clamp(self.Memory[2033],0,17))
		local high = math.floor(math.Clamp(self.Memory[2034],0,17))
		local lowc = math.floor(math.Clamp(self.Memory[2031],0,29))
		local highc = math.floor(math.Clamp(self.Memory[2032],0,29))
		if (value > 0) then
			for j = low,high do
				for i = highc,lowc+delta,-1 do
					self.Memory[j*60+i*2] = self.Memory[j*60+i*2-delta*2]
					self.Memory[j*60+i*2+1] = self.Memory[j*60+i*2+1-delta*2]
				end
			end
			for j = low,high do
				for i = lowc, lowc+delta-1 do
					self.Memory[j*60+i*2] = 0
					self.Memory[j*60+i*2+1] = 0
				end
			end
		else
			for j = low,high do
				for i = lowc,highc-delta do
					self.Memory[j*60+i*2] = self.Memory[j*60+i*2+delta*2]
					self.Memory[j*60+i*2+1] = self.Memory[j*60+i*2+1+delta*2]
				end
			end
			for j = low,high do
				for i = highc-delta+1,highc do
					self.Memory[j*60+i*2] = 0
					self.Memory[j*60+i*2+1] = 0
				end
			end
		end
	elseif (Address == 2038) then -- Shift rows (number of rows, >0 shift down, <0 shift up)
		local delta = math.abs(value)
		local low = math.floor(math.Clamp(self.Memory[2033],0,17))
		local high = math.floor(math.Clamp(self.Memory[2034],0,17))
		local lowc = math.floor(math.Clamp(self.Memory[2031],0,29))
		local highc = math.floor(math.Clamp(self.Memory[2032],0,29))
		if (value > 0) then
			for j = low, high-delta do
				for i = 2*lowc, 2*highc+1 do
					self.Memory[j*60+i] = self.Memory[(j+delta)*60+i]
				end
			end
			for j = high-delta+1,high do
				for i = 2*lowc, 2*highc+1 do
						self.Memory[j*60+i] = 0
				end
			end
		else
			for j = high,low+delta,-1 do
				for i = 2*lowc, 2*highc+1 do
					self.Memory[j*60+i] = self.Memory[(j-delta)*60+i]
				end
			end
			for j = low,low+delta-1 do
				for i = 2*lowc, 2*highc+1 do
					self.Memory[j*60+i] = 0
				end
			end
		end
	elseif (Address == 2039) then -- Hardware Clear Row (Writing clears row)
		for i = 0, 59 do
			self.Memory[value*60+i] = 0
		end
	elseif (Address == 2040) then -- Hardware Clear Column (Writing clears column)
		for i = 0, 17 do
			self.Memory[i*60+value] = 0
		end
	elseif (Address == 2041) then -- Hardware Clear Screen
		for i = 0, 18*30*2-1 do
			self.Memory[i] = 0
		end
		self:ResetCacheSystem() -- optimization
	end
end


function MakeWireconsoleScreen(pl, Pos, Ang, model)

	if (!pl:CheckLimit("wire_consolescreens")) then return false end

	local wire_consolescreen = ents.Create("gmod_wire_consolescreen")
	if (!wire_consolescreen:IsValid()) then return false end
	wire_consolescreen:SetModel(model)

	wire_consolescreen:SetAngles(Ang)
	wire_consolescreen:SetPos(Pos)
	wire_consolescreen:Spawn()

	wire_consolescreen:SetPlayer(pl)

	pl:AddCount("wire_consolescreens", wire_consolescreen)

	return wire_consolescreen
end

duplicator.RegisterEntityClass("gmod_wire_consolescreen", MakeWireconsoleScreen, "Pos", "Ang", "Model")
