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
net.Receive("wire_digitalscreen", function()
	local ent = Entity(net.ReadUInt(16))

	if IsValid(ent) and ent.Memory1 and ent.Memory2 then
		local pixelbit = pixelbits[net.ReadUInt(5)]
		local len = net.ReadUInt(32)
		local datastr = util.Decompress(net.ReadData(len))
		if #datastr>0 then
			ent:AddBuffer(datastr,pixelbit)
		end
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
		return false
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

		coroutine.yield(true)
	end

	self.buffer[1].readIndex = readIndex
	return false
end

function ENT:Think()
	if self.buffer[1] ~= nil then
		local maxtime = SysTime() + RealFrameTime() * 0.05 -- do more depending on client FPS. Higher fps = more work

		while SysTime() < maxtime and self.buffer[1] do
			if not self.co or coroutine.status(self.co) == "dead" then
				self.co = coroutine.create( function()
					 self:ProcessBuffer()
				end )
			end

			coroutine.resume(self.co)
		end
	end

	self:NextThink(CurTime()+0.1)
	return true
end

function ENT:ReadCell(Address,value)
	Address = math.floor(Address)
	if Address < 0 then return nil end
	if Address >= 1048577 then return nil end

	return self.Memory2[Address]
end

function ENT:WriteCell(Address,value)
	Address = math.floor(Address)
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

	if Address == 1048574 then -- Hardware Clear Screen
		local mem1,mem2 = {},{}
		for addr = 1048500,1048575 do
			mem1[addr] = self.Memory1[addr]
			mem2[addr] = self.Memory2[addr]
		end
		self.Memory1,self.Memory2 = mem1,mem2
		self.IsClear = true
		self.ClearQueued = true
		self.NeedRefresh = true
		self.RefreshRows = {}
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


	surface.SetDrawColor(cr,cg,cb,255)
	surface.DrawRect( x, y, 1, 1 )
end

function ENT:RedrawRow(y)
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
		surface.DrawRect( x, y, 1, 1 )
	end
end

local VECTOR_1_1_1 = Vector(1, 1, 1)
function ENT:Draw()
	self:DrawModel()

	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(VECTOR_1_1_1)

	if self.NeedRefresh then
		self.NeedRefresh = false
		local maxtime = SysTime() + RealFrameTime() * 0.01

		self.GPU:RenderToGPU(function()
			local idx = 0

			if self.ClearQueued then
				surface.SetDrawColor(0,0,0,255)
				surface.DrawRect(0,0, 1024,1024)
				self.ClearQueued = false
				return
			end

			if (#self.RefreshRows > 0) then
				idx = #self.RefreshRows
				while ((idx > 0) and (SysTime() < maxtime)) do
					self:RedrawRow(self.RefreshRows[idx])
					self.RefreshRows[idx] = nil
					idx = idx - 1
				end
			else
				idx = #self.RefreshPixels
				while ((idx > 0) and (SysTime() < maxtime)) do
					self:RedrawPixel(self.RefreshPixels[idx])
					self.RefreshPixels[idx] = nil
					idx = idx - 1
				end
			end
			if idx ~= 0 then
				self.NeedRefresh = true
			end
		end)
	end

	self.GPU:Render(0,0,1024,1024,nil,-(1024-self.ScreenWidth)/1024,-(1024-self.ScreenHeight)/1024)
	render.SetToneMappingScaleLinear(tone)
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end
