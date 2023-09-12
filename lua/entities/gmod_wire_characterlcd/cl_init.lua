include("shared.lua")

function ENT:Initialize()
	local mem = {}
	self.Memory = mem
	for i = 0, 1023 do
		mem[i] = 0
	end

	-- Screen control:
	-- [1003] - Background red
	-- [1004] - Background green
	-- [1005] - Background blue
	-- [1006] - Text red
	-- [1007] - Text green
	-- [1008] - Text blue
	-- [1009] - Width
	-- [1010] - Height

	-- Character control:
	-- [1011] - Write char at cursor (Writing puts character and shifts)
	--
	-- Caching control:
	-- [1012] - Force cache refresh
	-- [1013] - Cached blocks size (up to 28, 0 if disabled)
	--
	--
	-- Shifting control:
	-- [1014] - Shift cursor 1:backwards 0:forwards
	-- [1015] - Shift screen with cursor
	--
	-- Character output control:
	-- [1016] - Contrast
	--
	-- Control registers:
	-- [1017] - Hardware Clear Row (Writing clears row)
	-- [1018] - Hardware Clear Screen
	--
	-- Cursor control:
	-- [1019] - Cursor Blink Rate (0.50)
	-- [1020] - Cursor Size (0.25)
	-- [1021] - Cursor Address
	-- [1022] - Cursor Enabled
	--
	-- [1023] - Clk
	mem[1003] = 148
	mem[1004] = 178
	mem[1005] = 15
	mem[1006] = 45
	mem[1007] = 91
	mem[1008] = 45
	mem[1012] = 0
	mem[1013] = 0
	mem[1014] = 0
	mem[1015] = 0
	mem[1016] = 1
	mem[1017] = 0
	mem[1018] = 0
	mem[1019] = 0.5
	mem[1020] = 0.25
	mem[1021] = 0
	mem[1022] = 1
	mem[1023] = 1

	self.IntTimer = 0
	self.Flash = false
	self.CursorChar = 0

	self.GPU = WireGPU(self)
	mem[1009] = 16
	mem[1010] = 2

	-- Setup caching
	GPULib.ClientCacheCallback(self,function(Address,Value)
		self:WriteCell(Address,Value)
	end)

	WireLib.netRegister(self)
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

function ENT:ReadCell(Address,value)
	return self.Memory[math.floor(Address)]
end

function ENT:ShiftScreenRight()
	local mem = self.Memory
	for y=0,mem[1010]-1 do
		for x=mem[1009]-1,1,-1 do
			mem[x+y*mem[1009]] = mem[x+y*mem[1009]-1]
		end
		mem[y*mem[1009]] = 0
	end
end

function ENT:ShiftScreenLeft()
	local mem = self.Memory
	for y=0,mem[1010]-1 do
		for x=0,mem[1009]-2 do
			mem[x+y*mem[1009]] = mem[x+y*mem[1009]+1]
		end
		mem[y*mem[1009]+mem[1009]-1] = 0
	end
end

function ENT:WriteCell(Address,value)
	Address = math.floor(Address)
	if Address < 0 or Address >= 1024 then return false end
	if value ~= value then return false end

	local mem = self.Memory

	if Address == 1009 then -- Screen width
		value = math.floor(value)
		if (value*mem[1010] > 1003 or value*18 > 1024) then return false end
	elseif Address == 1010 then -- Screen height
		value = math.floor(value)
		if (value*mem[1009] > 1003 or value*24 > 1024) then return false end
	elseif Address == 1011 then -- Write char at cursor
		value = math.floor(value)
		if mem[1015] >= 1 then
			if mem[1014] >= 1 then
				self:ShiftScreenRight()
			else
				self:ShiftScreenLeft()
			end
			mem[mem[1021]%(mem[1010]*mem[1009])] = value
		else
			mem[mem[1021]%(mem[1010]*mem[1009])] = value
			if mem[1014] >= 1 then
				mem[1021] = (mem[1021] - 1)%(mem[1010]*mem[1009])
			else
				mem[1021] = (mem[1021] + 1)%(mem[1010]*mem[1009])
			end
		end
	elseif Address == 1017 then
		value = math.floor(value)
		if value<0 or value >= mem[1010] then return false end
		for i = 0, mem[1009]-1 do
			mem[value*mem[1009]+i] = 0
		end
	elseif Address == 1018 then
		for i = 0, mem[1009]*mem[1010]-1 do
			mem[i] = 0
		end
	elseif Address == 1021 then
		value = math.floor(value)%(mem[1010]*mem[1009])
	end

	mem[Address] = value

	return true
end

local specialCharacters = {
	[128] = {
		{ x = 0, y = 1 },
		{ x = 1, y = 1 },
		{ x = 1, y = 0 },
	},
	[129] = {
		{ x = 0, y = 1 },
		{ x = 0, y = 0 },
		{ x = 1, y = 1 },
	},
	[130] = {
		{ x = 0, y = 1 },
		{ x = 1, y = 0 },
		{ x = 0, y = 0 },
	},
	[131] = {
		{ x = 0, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 1 },
	},
	[132] = {
		{ x = 0, y = 0 },
		{ x = 0.5, y = 0 },
		{ x = 0.5, y = 0.5 },
		{ x = 0, y = 0.5 },
	},
	[133] = {
		{ x = 0.5, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 0.5 },
		{ x = 0.5, y = 0.5 },
	},
	[134] = {
		{ x = 0, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 0.5 },
		{ x = 0, y = 0.5 },
	},
	[135] = {
		{ x = 0, y = 0.5 },
		{ x = 0.5, y = 0.5 },
		{ x = 0.5, y = 1 },
		{ x = 0, y = 1 },
	},





	[136] = {
		{ x = 0, y = 0 },
		{ x = 0.5, y = 0 },
		{ x = 0.5, y = 1 },
		{ x = 0, y = 1 },
	},
	[137] = {
		{ x = 0.5, y = 0.5 },
		{ x = 0.5, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 0.5 },
		{ x = 0.5, y = 0.5 },
		{ x = 0.5, y = 1 },
		{ x = 0, y = 1 },
		{ x = 0, y = 0.5 },
	},
	[138] = {
		{ x = 0, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 0.5 },
		{ x = 0.5, y = 0.5 },
		{ x = 0.5, y = 1 },
		{ x = 0, y = 1 },
	},
	[139] = {
		{ x = 0.5, y = 0.5 },
		{ x = 1, y = 0.5 },
		{ x = 1, y = 1 },
		{ x = 0.5, y = 1 },
	},
	[140] = {
		{ x = 0.5, y = 0.5 },
		{ x = 1, y = 0.5 },
		{ x = 1, y = 1 },
		{ x = 0.5, y = 1 },
		{ x = 0.5, y = 0.5 },
		{ x = 0, y = 0.5 },
		{ x = 0, y = 0 },
		{ x = 0.5, y = 0 },
	},
	[141] = {
		{ x = 0.5, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 1 },
		{ x = 0.5, y = 1 },
	},
	[142] = {

		{ x = 1, y = 0 },
		{ x = 1, y = 1 },
		{ x = 0.5, y = 1 },
		{ x = 0.5, y = 0.5 },
		{ x = 0, y = 0.5},
		{ x = 0, y = 0 },
	},

	[143] = {
		{ x = 0, y = 0.5 },
		{ x = 1, y = 0.5 },
		{ x = 1, y = 1 },
		{ x = 0, y = 1 },
	},
	[144] = {
		{ x = 0, y = 1 },
		{ x = 0, y = 0 },
		{ x = 0.5, y = 0 },
		{ x = 0.5, y = 0.5 },
		{ x = 1, y = 0.5 },
		{ x = 1, y = 1 },
	},
	[145] = {
		{ x = 1, y = 1 },
		{ x = 0, y = 1 },
		{ x = 0, y = 0.5 },
		{ x = 0.5, y = 0.5 },
		{ x = 0.5, y = 0 },
		{ x = 1, y = 0 },
	},
	[146] = {
		{ x = 0, y = 0 },
		{ x = 1, y = 0 },
		{ x = 1, y = 1 },
		{ x = 0, y = 1 },
	},
	[147] = {
		{ x = 0.33, y = 0.66 },
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
		{ x = 0.66, y = 0.33 },
		{ x = 1, y = 0.33 },
		{ x = 1, y = 0.66 },
	},
	[148] = {
		{ x = 0.33, y = 0},
		{ x = 0.66, y = 0},
		{ x = 0.66, y = 1},
		{ x = 0.33, y = 1},
	},
	[149] = {
		{ x = 0.66, y = 0.66 },
		{ x = 0, y = 0.66 },
		{ x = 0, y = 0.33 },
		{ x = 0.33, y = 0.33 },
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
	},
	[150] = {
		{ x = 0, y = 0.33},
		{ x = 1, y = 0.33},
		{ x = 1, y = 0.66},
		{ x = 0, y = 0.66},
	},
	[151] = {
		{ x = 0.66, y = 0.33 },
		{ x = 1, y = 0.33 },
		{ x = 1, y = 0.66 },
		{ x = 0, y = 0.66 },
		{ x = 0, y = 0.33 },
		{ x = 0.33, y = 0.33 },
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
	},
	[152] = {
		{ x = 0.66, y = 0.33 },
		{ x = 1, y = 0.33 },
		{ x = 1, y = 0.66 },
		{ x = 0.66, y = 0.66 },
		{ x = 0.66, y = 1 },
		{ x = 0.33, y = 1 },
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
	},
	[153] = {
		{ x = 0.66, y = 0.66 },
		{ x = 1, y = 0.66 },
		{ x = 1, y = 0.33 },
		{ x = 0, y = 0.33 },
		{ x = 0, y = 0.66 },
		{ x = 0.33, y = 0.66 },
		{ x = 0.33, y = 1 },
		{ x = 0.66, y = 1 },
	},
	[154] = {
		{ x = 0.33, y = 0.33 },
		{ x = 0, y = 0.33 },
		{ x = 0, y = 0.66 },
		{ x = 0.33, y = 0.66 },
		{ x = 0.33, y = 1 },
		{ x = 0.66, y = 1 },
		{ x = 0.66, y = 0 },
		{ x = 0.33, y = 0 },
	},
	[155] = {
		{ x = 0.66, y = 0.33 },
		{ x = 1, y = 0.33 },
		{ x = 1, y = 0.66 },
		{ x = 0.66, y = 0.66 },
		{ x = 0.66, y = 1 },
		{ x = 0.33, y = 1 },
		{ x = 0.33, y = 0.66 },
		{ x = 0, y = 0.66 },
		{ x = 0, y = 0.33 },
		{ x = 0.33, y = 0.33 },
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
	},
	[156] = {
		{ x = 0.33, y = 0 },
		{ x = 0.66, y = 0 },
		{ x = 0.66, y = 0.33 },
		{ x = 0.33, y = 0.33 },
	},
	[157] = {
		{ x = 0.66, y = 0.33 },
		{ x = 1, y = 0.33 },
		{ x = 1, y = 0.66 },
		{ x = 0.66, y = 0.66 },
	},
	[158] = {
		{ x = 0.33, y = 0.66 },
		{ x = 0.66, y = 0.66 },
		{ x = 0.66, y = 1 },
		{ x = 0.33, y = 1 },
	},
	[159] = {
		{ x = 0, y = 0.33 },
		{ x = 0.33, y = 0.33 },
		{ x = 0.33, y = 0.66 },
		{ x = 0, y = 0.66 },
	},
	[160] = {
		{ x = 0.33, y = 0.33 },
		{ x = 0.66, y = 0.33 },
		{ x = 0.66, y = 0.66 },
		{ x = 0.33, y = 0.66 },
	}
}

function ENT:DrawSpecialCharacter(c,x,y,w,h,r,g,b)
	surface.SetDrawColor(r,g,b,255)
	surface.SetTexture(0)

	local vertices = specialCharacters[c]
	if vertices then
		local tf = Matrix() tf:SetScale(Vector(w, h, 1)) tf:SetTranslation(Vector(x, y, 0))
		cam.PushModelMatrix(tf, true)
		surface.DrawPoly(vertices)
		cam.PopModelMatrix()
	end
end

local VECTOR_1_1_1 = Vector(1, 1, 1)
function ENT:Draw()
	self:DrawModel()

	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(VECTOR_1_1_1)

	local szx = 18
	local szy = 24
	local mem = self.Memory

	if mem[1023] >= 1 then
		mem[1023] = 0

		self.GPU:RenderToGPU(function()
			-- Draw terminal here
			-- W/H = 16

			local bc = math.min(1,math.max(0,mem[1016]-1.8))
			local br = (1-bc)*mem[1003]+bc*mem[1006]
			local bg = (1-bc)*mem[1004]+bc*mem[1007]
			local bb = (1-bc)*mem[1005]+bc*mem[1008]

			local sqc = math.min(1,math.max(0,mem[1016]-0.9))
			local sqr = (1-sqc)*mem[1003]+sqc*mem[1006]
			local sqg = (1-sqc)*mem[1004]+sqc*mem[1007]
			local sqb = (1-sqc)*mem[1005]+sqc*mem[1008]

			local fc = math.min(1,math.max(sqc,mem[1016]))
			local fr = (1-fc)*mem[1003]+fc*mem[1006]
			local fg = (1-fc)*mem[1004]+fc*mem[1007]
			local fb = (1-fc)*mem[1005]+fc*mem[1008]
			surface.SetDrawColor(br,bg,bb,255)
			surface.DrawRect(0,0,1024,1024)

			for ty = 0, mem[1010]-1 do
				for tx = 0, mem[1009]-1 do
					local a = tx + ty*mem[1009]

					--if (self.Flash == true) then
					--	fb,bb = bb,fb
					--	fg,bg = bg,fg
					--	fr,br = br,fr
					--end
					local c1 = mem[a]

					if c1 >= 2097152 then c1 = 0 end
					if c1 < 0 then c1 = 0 end

					surface.SetDrawColor(sqr,sqg,sqb,255)
					surface.DrawRect(tx*szx+1,ty*szy+1,szx-2,szy-2)
					surface.SetDrawColor(sqr,sqg,sqb,127)
					surface.DrawRect(tx*szx+2,ty*szy+2,szx-2,szy-2)

					if (c1 ~= 0) then
						-- Note: the source engine does not handle unicode characters above 65535 properly.
						local utf8 = ""
						if c1 <= 127 then
							utf8 = string.char (c1)
						elseif c1 < 2048 then
							utf8 = string.format("%c%c", 192 + math.floor (c1 / 64), 128 + (c1 % 64))
						elseif c1 < 65536 then
							utf8 = string.format("%c%c%c", 224 + math.floor (c1 / 4096), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
						elseif c1 < 2097152 then
							utf8 = string.format("%c%c%c%c", 240 + math.floor (c1 / 262144), 128 + (math.floor (c1 / 4096) % 64), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
						end

						if specialCharacters[c1] then
							self:DrawSpecialCharacter(
								c1, tx*szx+1, ty*szy+1, szx-1, szy-1,
								fr,fg,fb
							)
						else
							draw.DrawText(
								utf8,
								"LCDFontBlur",
								tx * szx + 2, ty * szy,
								Color(fr,fg,fb,255),0
							)
							draw.DrawText(
								utf8,
								"LCDFont",
								tx * szx + 1, ty * szy -1 ,
								Color(fr,fg,fb,255),0
							)
						end
					end
				end
			end
		 end)
	end

	self.GPU:Render(0,0,1024,1024,nil,-(1024-mem[1009]*szx)/1024,-(1024-mem[1010]*szy)/1024)

	if mem[1022] >= 1 then
		self.IntTimer = self.IntTimer + FrameTime()
		if self.IntTimer >= mem[1019] then
			if self.IntTimer >= mem[1019]*2 then
				self.IntTimer = (self.IntTimer - mem[1019]*2) % math.max(mem[1019]*2,0.01)
				self.GPU:RenderToGPU(function()
					local bc = math.min(1,math.max(0,mem[1016]-1.8))
					local br = (1-bc)*mem[1003]+bc*mem[1006]
					local bg = (1-bc)*mem[1004]+bc*mem[1007]
					local bb = (1-bc)*mem[1005]+bc*mem[1008]

					local sqc = math.min(1,math.max(0,mem[1016]-0.9))
					local sqr = (1-sqc)*mem[1003]+sqc*mem[1006]
					local sqg = (1-sqc)*mem[1004]+sqc*mem[1007]
					local sqb = (1-sqc)*mem[1005]+sqc*mem[1008]

					local fc = math.min(1,math.max(sqc,mem[1016]))
					local fr = (1-fc)*mem[1003]+fc*mem[1006]
					local fg = (1-fc)*mem[1004]+fc*mem[1007]
					local fb = (1-fc)*mem[1005]+fc*mem[1008]

					local a = math.floor(mem[1021])
					local tx = a - math.floor(a / mem[1009])*mem[1009]
					local ty = math.floor(a / mem[1009])

					--if (self.Flash == true) then
					--	fb,bb = bb,fb
					--	fg,bg = bg,fg
					--	fr,br = br,fr
					--end
					surface.SetDrawColor(br,bg,bb,255)
					surface.DrawRect(tx*szx,ty*szy,szx,szy)
					local c1 = mem[a]

					if c1 >= 2097152 then c1 = 0 end
					if c1 < 0 then c1 = 0 end

					surface.SetDrawColor(sqr,sqg,sqb,255)
					surface.DrawRect(tx*szx+1,ty*szy+1,szx-2,szy-2)
					surface.SetDrawColor(sqr,sqg,sqb,127)
					surface.DrawRect(tx*szx+2,ty*szy+2,szx-2,szy-2)

					if (c1 ~= 0) then
						-- Note: the source engine does not handle unicode characters above 65535 properly.
						local utf8 = ""
						if c1 <= 127 then
							utf8 = string.char (c1)
						elseif c1 < 2048 then
							utf8 = string.format("%c%c", 192 + math.floor (c1 / 64), 128 + (c1 % 64))
						elseif c1 < 65536 then
							utf8 = string.format("%c%c%c", 224 + math.floor (c1 / 4096), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
						elseif c1 < 2097152 then
							utf8 = string.format("%c%c%c%c", 240 + math.floor (c1 / 262144), 128 + (math.floor (c1 / 4096) % 64), 128 + (math.floor (c1 / 64) % 64), 128 + (c1 % 64))
						end

						if specialCharacters[c1] then
							self:DrawSpecialCharacter(
								c1, tx*szx+1, ty*szy+1, szx-1, szy-1,
								fr,fg,fb
							)
						else
							draw.DrawText(
								utf8,
								"LCDFontBlur",
								tx * szx + 2, ty * szy,
								Color(fr,fg,fb,255),0
							)
							draw.DrawText(
								utf8,
								"LCDFont",
								tx * szx + 1, ty * szy -1 ,
								Color(fr,fg,fb,255),0
							)
						end
					end

				end, nil, true)
			else
				self.GPU:RenderToGPU(function()
					local a = math.floor(mem[1021])

					local tx = a - math.floor(a / mem[1009])*mem[1009]
					local ty = math.floor(a / mem[1009])

					local sqc = math.min(1,math.max(0,mem[1016]-0.9))
					local fc = math.min(1,math.max(sqc,mem[1016]))
					local fr = (1-fc)*mem[1003]+fc*mem[1006]
					local fg = (1-fc)*mem[1004]+fc*mem[1007]
					local fb = (1-fc)*mem[1005]+fc*mem[1008]

					surface.SetDrawColor(
						fr,
						fg,
						fb,
						255
					)

					surface.DrawRect(
						tx*szx+1,
						ty*szy+szy*(1-mem[1020])-1,
						szx-2,
						szy*mem[1020]
					)

				end, nil, true)
			end
		end
	end

	render.SetToneMappingScaleLinear(tone)
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return true
end
