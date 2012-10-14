/******************************************************************************\
  Colour support
\******************************************************************************/

local Clamp = math.Clamp
local floor = math.floor
local abs = math.abs

local function ColorClamp(c)
	c.r = Clamp(c.r,0,255)
	c.g = Clamp(c.g,0,255)
	c.b = Clamp(c.b,0,255)
	c.a = Clamp(c.a,0,255)
	return c
end

/******************************************************************************/

e2function vector entity:getColor()
	if !validEntity(this) then return {0,0,0} end

	local c = this:GetColor()
	return { c.r, c.g, c.b }
end

e2function vector4 entity:getColor4()
	if not validEntity(this) then return {0,0,0,0} end
	local c = this:GetColor()
	return {c.r,c.g,c.b,c.a}
end

e2function number entity:getAlpha()
	return validEntity(this) and this:GetColor().a or 0
end

e2function void entity:setColor(r,g,b)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	this:SetColor(ColorClamp(Color(r,g,b,this:GetColor().a)))
end

e2function void entity:setColor(r,g,b,a)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	this:SetColor(ColorClamp(Color(r, g, b, this:IsPlayer() and this:GetColor().a or a)))
	this:SetRenderMode(this:GetColor().a == 255 and 0 or 1)
end

e2function void entity:setColor(vector c)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	this:SetColor(ColorClamp(Color(c[1],c[2],c[3],this:GetColor().a)))
end

e2function void entity:setColor(vector c, a)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	this:SetColor(ColorClamp(Color(c[1],c[2],c[3], this:IsPlayer() and this:GetColor().a or a)))
	this:SetRenderMode(this:GetColor().a == 255 and 0 or 1)
end

e2function void entity:setColor(vector4 c)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	this:SetColor(ColorClamp(Color(c[1],c[2],c[3], this:IsPlayer() and this:GetColor().a or c[4])))
	this:SetRenderMode(this:GetColor().a == 255 and 0 or 1)
end

e2function void entity:setAlpha(a)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	if this:IsPlayer() then return end
	
	local c = this:GetColor()
	c.a = Clamp(a, 0, 255)
	this:SetColor(c)
	this:SetRenderMode(c.a == 255 and 0 or 1)
end

--- Converts <hsv> from the [http://en.wikipedia.org/wiki/HSV_color_space HSV color space] to the [http://en.wikipedia.org/wiki/RGB_color_space RGB color space]
e2function vector hsv2rgb(vector hsv)
	local col = HSVToColor(hsv[1], hsv[2], hsv[3])
	return { col.r, col.g, col.b }
end

e2function vector hsv2rgb(h, s, v)
	local col = HSVToColor(h, s, v)
	return { col.r, col.g, col.b }
end

--- Converts <rgb> from the [http://en.wikipedia.org/wiki/RGB_color_space RGB color space] to the [http://en.wikipedia.org/wiki/HSV_color_space HSV color space]
e2function vector rgb2hsv(vector rgb)
	return { ColorToHSV(Color(rgb[1], rgb[2], rgb[3])) }
end

e2function vector hsl2rgb(hue, saturation, lightness)
	local chroma = (1 - abs(2*lightness - 1)) * saturation * 255
	local m = lightness*255 - chroma * 0.5
	local hue_quadrant = hue/60
	local x_m = chroma * (1 - abs(hue_quadrant % 2 - 1)) + m

	if hue_quadrant < 3 then
		-- hue_quadrant < 3
		if hue_quadrant < 2 then
			-- hue_quadrant < 2
			if hue_quadrant < 1 then
				-- hue_quadrant < 1
				return { chroma + m, x_m, m }
			else
				-- 1 <= hue_quadrant < 2
				return { x_m, chroma + m, m }
			end
		else
			-- 2 <= hue_quadrant < 3
			return { m, chroma + m, x_m }
		end
	else
		-- 3 <= hue_quadrant
		if 4 <= hue_quadrant then
			-- 4 <= hue_quadrant
			if 5 <= hue_quadrant then
				-- 5 <= hue_quadrant
				return { chroma + m, m, x_m }
			else
				-- 4 <= hue_quadrant < 5
				return { x_m, m, chroma + m }
			end
		else
			-- 3 <= hue_quadrant < 4
			return { m, x_m, chroma + m }
		end
	end
end

e2function vector hsl2rgb(vector hsl)
	local hue, saturation, lightness = hsl[1], hsl[2], hsl[3]

	local chroma = (1 - abs(2*lightness - 1)) * saturation * 255
	local m = lightness*255 - chroma * 0.5
	local hue_quadrant = hue/60
	local x_m = chroma * (1 - abs(hue_quadrant % 2 - 1)) + m

	if hue_quadrant < 3 then
		-- hue_quadrant < 3
		if hue_quadrant < 2 then
			-- hue_quadrant < 2
			if hue_quadrant < 1 then
				-- hue_quadrant < 1
				return { chroma + m, x_m, m }
			else
				-- 1 <= hue_quadrant < 2
				return { x_m, chroma + m, m }
			end
		else
			-- 2 <= hue_quadrant < 3
			return { m, chroma + m, x_m }
		end
	else
		-- 3 <= hue_quadrant
		if 4 <= hue_quadrant then
			-- 4 <= hue_quadrant
			if 5 <= hue_quadrant then
				-- 5 <= hue_quadrant
				return { chroma + m, m, x_m }
			else
				-- 4 <= hue_quadrant < 5
				return { x_m, m, chroma + m }
			end
		else
			-- 3 <= hue_quadrant < 4
			return { m, x_m, chroma + m }
		end
	end
end

local converters = {}
converters[0] = function(r, g, b)
	local r = Clamp(floor(r/28),0,9)
	local g = Clamp(floor(g/28),0,9)
	local b = Clamp(floor(b/28),0,9)

	return r*100000+g*10000+b*1000
end
converters[1] = false
converters[2] = function(r, g, b)
	return floor(r)*65536+floor(g)*256+floor(b)
end
converters[3] = function(r, g, b)
	return floor(r)*1000000+floor(g)*1000+floor(b)
end

--- Converts an RGB vector <rgb> to a number in digital screen format. <mode> Specifies a mode, either 0, 2 or 3, corresponding to Digital Screen color modes.
e2function number rgb2digi(vector rgb, mode)
	local conv = converters[mode]
	if not conv then return 0 end
	return conv(rgb[1], rgb[2], rgb[3])
end

--- Converts the RGB color (<r>,<g>,<b>) to a number in digital screen format. <mode> Specifies a mode, either 0, 2 or 3, corresponding to Digital Screen color modes.
e2function number rgb2digi(r, g, b, mode)
	local conv = converters[mode]
	if not conv then return 0 end
	return conv(r, g, b)
end
