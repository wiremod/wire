/******************************************************************************\
  Colour support
\******************************************************************************/

local Clamp = math.Clamp
local floor = math.floor
local abs = math.abs

local function ColorClamp(col1, col2, col3, col4)
	return Clamp(col1, 0, 255), Clamp(col2, 0, 255), Clamp(col3, 0, 255), Clamp(col4, 0, 255)
end

/******************************************************************************/

e2function vector entity:getColor()
	if !validEntity(this) then return {0,0,0} end

	local r,g,b = this:GetColor()
	return { r, g, b }
end

e2function vector4 entity:getColor4()
	if !validEntity(this) then return {0,0,0,0} end

	return { this:GetColor() }
end

e2function number entity:getAlpha()
	if !validEntity(this) then return 0 end

	local _,_,_,alpha = this:GetColor()
	return alpha
end

e2function void entity:setColor(rv2, rv3, rv4)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	local _,_,_,alpha = this:GetColor()
	this:SetColor(ColorClamp(rv2, rv3, rv4, alpha))
end

e2function void entity:setColor(rv2, rv3, rv4, rv5)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	if this:IsPlayer() --[[or this:IsWeapon()]] then rv5 = 255 end

	this:SetColor(ColorClamp(rv2, rv3, rv4, rv5))
end

e2function void entity:setColor(vector rv2)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	local _,_,_,alpha = this:GetColor()
	this:SetColor(ColorClamp(rv2[1], rv2[2], rv2[3], alpha))
end

e2function void entity:setColor(vector rv2, rv3)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	if this:IsPlayer() --[[or this:IsWeapon()]] then rv3 = 255 end

	this:SetColor(ColorClamp(rv2[1], rv2[2], rv2[3], rv3))
end

e2function void entity:setColor(vector4 rv2)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	local alpha
	if this:IsPlayer() --[[or this:IsWeapon()]] then
		alpha = 255
	else
		alpha = rv2[4]
	end

	this:SetColor(ColorClamp(rv2[1], rv2[2], rv2[3], alpha))
end

e2function void entity:setAlpha(rv2)
	if !validEntity(this) then return end
	if !isOwner(self, this) then return end

	if this:IsPlayer() --[[or this:IsWeapon()]] then return end

	local r,g,b = this:GetColor()
	this:SetColor(r, g, b, Clamp(rv2, 0, 255))
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
