AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "CharacterLcdScreen"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = WireLib.CreateInputs(self, { "CharAddress", "Char (ASCII/Unicode)", "Contrast", "Clk", "Reset" })
	self.Outputs = WireLib.CreateOutputs(self, { "Memory" })

	self.Memory = {}

	for i = 0, 1023 do
		self.Memory[i] = 0
	end

	self.CharAddress = 0
	self.Char = 0
	self.CharParam = 0
	self.Memory[1009] = 16
	self.Memory[1010] = 2
	self.Memory[1012] = 0
	self.Memory[1013] = 0
	self.Memory[1014] = 0
	self.Memory[1015] = 0
	self.Memory[1016] = 1
	self.Memory[1017] = 0
	self.Memory[1018] = 0
	self.Memory[1019] = 0.5
	self.Memory[1020] = 0.25
	self.Memory[1021] = 0
	self.Memory[1022] = 1
	self.Memory[1023] = 1

	self.ScreenWidth = 16
	self.ScreenHeight = 2

	self.Cache = GPUCacheManager(self,true)
end
function ENT:Setup(ScreenWidth, ScreenHeight, bgred,bggreen,bgblue,fgred,fggreen,fgblue)
	self:WriteCell(1010, tonumber(ScreenHeight) or 2)
	self:WriteCell(1009, tonumber(ScreenWidth) or 16)
	self:WriteCell(1008, tonumber(fgblue) or 45)
	self:WriteCell(1007, tonumber(fggreen) or 91)
	self:WriteCell(1006, tonumber(fgred) or 45)
	self:WriteCell(1005, tonumber(bgblue) or 15)
	self:WriteCell(1004, tonumber(bggreen) or 178)
	self:WriteCell(1003, tonumber(bgred) or 148)
	self:WriteCell(1023,1)
end
function ENT:SendPixel()
	if (self.Memory[1023] ~= 0) and (self.CharAddress >= 0) and (self.CharAddress < self.ScreenWidth*self.ScreenHeight) then
		local pixelno = math.floor(self.CharAddress)

		self:WriteCell(pixelno, self.Char)

	end
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	if Address < 0 then return nil end
	if Address >= 1024 then return nil end

	return self.Memory[Address]
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	if Address < 0 then return false end
	if Address >= 1024 then return false end
	if Address < 1003 then -- text/attribute data
		if self.Memory[Address] == value then return true end
	else
	if Address == 1009 and value*self.ScreenHeight < 1003 and value*18 <= 1024 then
		self.ScreenWidth = value
	end
	if Address == 1010 and value*self.ScreenWidth < 1003 and value*24 <= 1024 then
		self.ScreenHeight = value
	end
--		self.Memory[Address] = value
		self:ClientWriteCell(Address, value)
--		self.Cache:WriteNow(Address, value)
--		return true
	end

	self.Memory[Address] = value
	self.Cache:Write(Address,value)
	return true
end

function ENT:Think()
	self.Cache:Flush()
	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:Retransmit(ply)
	self.Cache:Flush()
	for address,value in pairs(self.Memory) do
		self.Cache:Write(address,value)
	end
	self.Cache:Flush(ply)
end

function ENT:TriggerInput(iname, value)
	if iname == "CharAddress" then
		self.CharAddress = value
		self:WriteCell(1021, value)
	elseif iname == "Char" then
		self.Char = value
		self:WriteCell(1011,value)
	elseif iname == "Contrast" then
		self.Contrast = value
		self:WriteCell(1016, self.Contrast)
	elseif iname == "Clk" then
		self:WriteCell(1023, value)
		self:SendPixel()
	elseif iname == "Reset" then
		self:WriteCell(1018,0)
	end
end

function ENT:ShiftScreenRight()
	for y=0,self.ScreenHeight-1 do
		for x=self.ScreenWidth-1,1 do
			self.Memory[x+y*self.ScreenWidth] = self.Memory[x+y*self.ScreenWidth-1]
		end
		self.Memory[y*self.ScreenWidth] = 0
	end
end

function ENT:ShiftScreenLeft()
	for y=0,self.ScreenHeight-1 do
		for x=0,self.ScreenWidth-2 do
			self.Memory[x+y*self.ScreenWidth] = self.Memory[x+y*self.ScreenWidth+1]
		end
		self.Memory[y*self.ScreenWidth+self.ScreenWidth-1] = 0
	end
end

function ENT:ClientWriteCell(Address, value)
	if Address == 1009 and (value*self.Memory[1010] > 1003 or value*18 > 1024) then return false end
	if Address == 1010 and (value*self.Memory[1009] > 1003 or value*24 > 1024) then return false end
	if Address == 1011 then

		if self.Memory[1015] >= 1 then
			if self.Memory[1014] >= 1 then
				self:ShiftScreenRight()
			else
				self:ShiftScreenLeft()
			end
			self.Memory[self.Memory[1021]] = value
		else
			self.Memory[self.Memory[1021]] = value
			if self.Memory[1014] >= 1 then
				self.Memory[1021] = math.max(0,self.Memory[1021] - 1)
			else
				self.Memory[1021] = math.min(1023,self.Memory[1021] + 1)
			end
		end

	end
	if Address == 1017 then
		for i = 0, self.ScreenWidth-1 do
			self.Memory[value*self.ScreenWidth+i] = 0
		end
		self.NeedRefresh = true
	end
	if Address == 1018 then
		for i = 0, self.ScreenWidth*self.ScreenHeight-1 do
			self.Memory[i] = 0
		end
		self.NeedRefresh = true
	end
end

duplicator.RegisterEntityClass("gmod_wire_characterlcd", WireLib.MakeWireEnt, "Data", "ScreenWidth", "ScreenHeight")
