include('shared.lua')

function ENT:Initialize()
	self.Memory1 = {}
	self.Memory2 = {}

	self.LastClk = true
	self.NewClk = true
	self.Memory1[1048575] = 1
	self.Memory2[1048575] = 1
	self.NeedRefresh = true
	self.IsClear = true
	self.ClearQueued = false
	self.RefreshPixels = {}
	self.RefreshRows = {}

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	for i=1,self.ScreenHeight do
		self.RefreshRows[i] = i-1
	end

	//0..786431 - RGB data

	//1048569 - Color mode (0: RGBXXX; 1: R G B)
	//1048570 - Clear row
	//1048571 - Clear column
	//1048572 - Screen Height
	//1048573 - Screen Width
	//1048574 - Hardware Clear Screen
	//1048575 - CLK

	self.GPU = WireGPU(self)

	self.buffer = {}
	
	WireLib.netRegister(self)
end

function ENT:OnRemove()
	self.GPU:Finalize()
	self.NeedRefresh = true
end

local function stringToNumber(index, str, bytes)
	local newpos = index+bytes
	str = str:sub(index,newpos-1)
	local n = 0
	for j=1,bytes do
		n = n + str:byte(j)*(256^(j-1))
    end
	return n, newpos
end

local pixelbits = {3, 1, 3, 4, 1}
net.Receive("wire_digitalscreen", function(netlen)
	local ent = Entity(net.ReadUInt(16))
	
	if IsValid(ent) and ent.Memory1 and ent.Memory2 then
		local pixelformat = net.ReadUInt(5)
		local pixelbit = pixelbits[pixelformat]
		local readData
		
		local datastr = util.Decompress(net.ReadData((netlen-21)/8))
		if not datastr then return end
		local readIndex = 1

		ent:AddBuffer(datastr,pixelbit)
	end
end)

function ENT:AddBuffer(datastr,pixelbit)
	self.buffer[#self.buffer+1] = {datastr=datastr,readIndex=1,pixelbit=pixelbit}
end

function ENT:ProcessBuffer()
	if not self.buffer[1] then return end

	local datastr = self.buffer[1].datastr
	local readIndex = self.buffer[1].readIndex
	local pixelbit = self.buffer[1].pixelbit

	local length
	length, readIndex = stringToNumber(readIndex,datastr,3)
	if length == 0 then
		table.remove( self.buffer, 1 )
		return
	end
	local address
	address, readIndex = stringToNumber(readIndex,datastr,3)
	for i = address, address + length - 1 do
		if i>=1048500 then
			local data
			data, readIndex = stringToNumber(readIndex,datastr,2)
			self:WriteCell(i, data)
		else
			local data
			data, readIndex = stringToNumber(readIndex,datastr,pixelbit)
			self:WriteCell(i, data)
		end
	end

	self.buffer[1].readIndex = readIndex
end

function ENT:Think()
	self:ProcessBuffer()
	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:ReadCell(Address,value)
	if Address < 0 then return nil end
	if Address >= 1048577 then return nil end

	return self.Memory2[Address]
end

function ENT:WriteCell(Address,value)
	if Address < 0 then return false end
	if Address >= 1048577 then return false end

	if Address == 1048575 then
		self.NewClk = value ~= 0
	elseif Address < 1048500 then
		self.IsClear = false
	end

	if (self.NewClk) then
		self.Memory1[Address] = value -- visible buffer
		self.NeedRefresh = true
		if self.Memory1[1048569] == 1 then -- R G B mode
			local pixelno = math.floor(Address/3)
			if self.RefreshPixels[#self.RefreshPixels] ~= pixelno then
				self.RefreshPixels[#self.RefreshPixels+1] = pixelno
			end
		else -- other modes
			self.RefreshPixels[#self.RefreshPixels+1] = Address
		end
	end
	self.Memory2[Address] = value -- invisible buffer

	if Address == 1048574 then
		local mem1,mem2 = {},{}
		for addr = 1048500,1048575 do
			mem1[addr] = self.Memory1[addr]
			mem2[addr] = self.Memory2[addr]
		end
		self.Memory1,self.Memory2 = mem1,mem2
		self.IsClear = true
		self.ClearQueued = true
		self.NeedRefresh = true
	elseif Address == 1048572 then
		self.ScreenHeight = value
		if not self.IsClear then
			self.NeedRefresh = true
			for i = 1,self.ScreenHeight do
				self.RefreshRows[i] = i-1
			end
		end
	elseif Address == 1048573 then
		self.ScreenWidth = value
		if not self.IsClear then
			self.NeedRefresh = true
			for i = 1,self.ScreenHeight do
				self.RefreshRows[i] = i-1
			end
		end
	end

	if self.LastClk ~= self.NewClk then
		-- swap the memory if clock changes
		self.LastClk = self.NewClk
		self.Memory1 = table.Copy(self.Memory2)

		self.NeedRefresh = true
		for i=1,self.ScreenHeight do
			self.RefreshRows[i] = i-1
		end
	end
	return true
end

local transformcolor = {}
transformcolor[0] = function(c) -- RGBXXX
	local crgb = math.floor(c / 1000)
	local cgray = c - math.floor(c / 1000)*1000

	cb = cgray+28*math.fmod(crgb, 10)
	cg = cgray+28*math.fmod(math.floor(crgb / 10), 10)
	cr = cgray+28*math.fmod(math.floor(crgb / 100), 10)

	return cr, cg, cb
end
transformcolor[2] = function(c) -- 24 bit mode
	cb = math.fmod(c, 256)
	cg = math.fmod(math.floor(c / 256), 256)
	cr = math.fmod(math.floor(c / 65536), 256)

	return cr, cg, cb
end
transformcolor[3] = function(c) -- RRRGGGBBB
	cb = math.fmod(c, 1000)
	cg = math.fmod(math.floor(c / 1e3), 1000)
	cr = math.fmod(math.floor(c / 1e6), 1000)

	return cr, cg, cb
end
transformcolor[4] = function(c) -- XXX
	return c, c, c
end

local floor = math.floor

function ENT:RedrawPixel(a)
	if a >= self.ScreenWidth*self.ScreenHeight then return end

	local cr,cg,cb

	local x = a % self.ScreenWidth
	local y = math.floor(a / self.ScreenWidth)

	local colormode = self.Memory1[1048569] or 0

	if colormode == 1 then
		cr = self.Memory1[a*3  ] or 0
		cg = self.Memory1[a*3+1] or 0
		cb = self.Memory1[a*3+2] or 0
	else
		local c = self.Memory1[a] or 0
		cr, cg, cb = (transformcolor[colormode] or transformcolor[0])(c)
	end

	local xstep = (512/self.ScreenWidth)
	local ystep = (512/self.ScreenHeight)

	surface.SetDrawColor(cr,cg,cb,255)
	local tx, ty = floor(x*xstep), floor(y*ystep)
	surface.DrawRect( tx, ty, floor((x+1)*xstep-tx), floor((y+1)*ystep-ty) )
end

function ENT:RedrawRow(y)
	local xstep = (512/self.ScreenWidth)
	local ystep = (512/self.ScreenHeight)
	if y >= self.ScreenHeight then return end
	local a = y*self.ScreenWidth

	local colormode = self.Memory1[1048569] or 0

	for x = 0,self.ScreenWidth-1 do
		local cr,cg,cb

		if (colormode == 1) then
			cr = self.Memory1[(a+x)*3  ] or 0
			cg = self.Memory1[(a+x)*3+1] or 0
			cb = self.Memory1[(a+x)*3+2] or 0
		else
			local c = self.Memory1[a+x] or 0
			cr, cg, cb = (transformcolor[colormode] or transformcolor[0])(c)
		end

		surface.SetDrawColor(cr,cg,cb,255)
		local tx, ty = floor(x*xstep), floor(y*ystep)
		surface.DrawRect( tx, ty, floor((x+1)*xstep-tx), floor((y+1)*ystep-ty) )
	end
end

function ENT:Draw()
	self:DrawModel()

	if self.NeedRefresh then
		self.NeedRefresh = false

		self.GPU:RenderToGPU(function()
			local pixels = 0
			local idx = 0

			if self.ClearQueued then
				surface.SetDrawColor(0,0,0,255)
				surface.DrawRect(0,0, 512,512)
				self.ClearQueued = false
			end

			if (#self.RefreshRows > 0) then
				idx = #self.RefreshRows
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawRow(self.RefreshRows[idx])
					self.RefreshRows[idx] = nil
					idx = idx - 1
					pixels = pixels + self.ScreenWidth
				end
			else
				idx = #self.RefreshPixels
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawPixel(self.RefreshPixels[idx])
					self.RefreshPixels[idx] = nil
					idx = idx - 1
					pixels = pixels + 1
				end
			end
			if idx ~= 0 then
				self.NeedRefresh = true
			end
		end)
	end

	self.GPU:Render()
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end
