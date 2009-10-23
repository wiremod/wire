if (not EmuFox) then
	include('shared.lua')
end

ENT.RenderGroup    = RENDERGROUP_BOTH


function ENT:Initialize()
	self.Memory1 = {}
	self.Memory2 = {}

	self.LastClk = true
	self.NewClk = true
	self.Memory1[1048575] = 1
	self.Memory2[1048575] = 1
	self.NeedRefresh = true
	self.RefreshPixels = {}
	self.RefreshRows = {}

	self.ScreenWidth = 32
	self.ScreenHeight = 32

		for i=1,self.ScreenHeight do
			self.RefreshRows[i] = i-1
		end
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

	self.GPU = WireGPU(self.Entity)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

usermessage.Hook("hispeed_datamessage", function(um)
	local ent = ents.GetByIndex(um:ReadShort())
	local datasize = um:ReadChar()

	if ValidEntity(ent) and ent.Memory1 and ent.Memory2 then
		for i = 1,datasize do
			local address = um:ReadLong()
			local value = um:ReadLong()
			ent:WriteCell(address,value)
		end
	end
end)

function ENT:ReadCell(Address,value)
	if Address < 0 then return nil end
	if Address >= 1048576 then return nil end

	return self.Memory2[Address]
end

function ENT:WriteCell(Address,value)
	if Address < 0 then return false end
	if Address >= 1048576 then return false end

	if (Address == 1048575) then
		self.NewClk = value ~= 0
	end
	--print("recv: "..Address.." pixs: "..#self.RefreshPixels)
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
		--self.NeedRefresh = true
		--for i = 1,self.ScreenHeight do
		--	self.RefreshRows[i] = i-1
		--end
		self.GPU:Clear()
	elseif Address == 1048572 then
		self.ScreenHeight = value
		self.NeedRefresh = true
		for i = 1,self.ScreenHeight do
			self.RefreshRows[i] = i-1
		end
	elseif Address == 1048573 then
		self.ScreenWidth = value
		self.NeedRefresh = true
		for i = 1,self.ScreenHeight do
			self.RefreshRows[i] = i-1
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
	self.Entity:DrawModel()

	if self.NeedRefresh then
		self.NeedRefresh = false

		self.GPU:RenderToGPU(function()
			local pixels = 0
			local idx = 1

			if (#self.RefreshRows > 0) then
				idx = #self.RefreshRows
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawRow(self.RefreshRows[idx])
					self.RefreshRows[idx] = nil
					idx = idx - 1
					pixels = pixels + self.ScreenWidth
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			else
				idx = #self.RefreshPixels
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawPixel(self.RefreshPixels[idx])
					self.RefreshPixels[idx] = nil
					idx = idx - 1
					pixels = pixels + 1
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			end
		end)

	end

	if EmuFox then return end

	self.GPU:Render()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
