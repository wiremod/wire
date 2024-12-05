/******************************************************************************\
  Color support
\******************************************************************************/

local Clamp = math.Clamp
local floor = math.floor
local Round = math.Round

local function RGBClamp(r,g,b)
	return Clamp(r,0,255), Clamp(g,0,255), Clamp(b,0,255)
end

/******************************************************************************/

__e2setcost(2)

e2function vector entity:getColor()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end

	local c = this:GetColor()
	return Vector(c.r, c.g, c.b)
end

e2function vector4 entity:getColor4()
	if not IsValid(this) then return self:throw("Invalid entity!", {0, 0, 0, 0}) end
	local c = this:GetColor()
	return {c.r, c.g, c.b, c.a}
end

e2function number entity:getAlpha()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	return this:GetColor().a
end

e2function void entity:setColor(r,g,b)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	local color = this:GetColor()
	color.r, color.g, color.b = RGBClamp(r, g, b)

	WireLib.SetColor(this, color)
end

e2function void entity:setColor(r,g,b,a)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	WireLib.SetColor(this, Color(r, g, b, a))
end

e2function void entity:setColor(vector c)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	local color = this:GetColor()
	color.r, color.g, color.b = RGBClamp(c[1], c[2], c[3])

	WireLib.SetColor(this, color)
end

e2function void entity:setColor(vector c, a)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	WireLib.SetColor(this, Color(c[1], c[2], c[3], a))
end

e2function void entity:setColor(vector4 c)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end

	WireLib.SetColor(this, Color(c[1], c[2], c[3], c[4]))
end

e2function void entity:setAlpha(a)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	if this:IsPlayer() then return self:throw("You cannot set the alpha of a player!", nil) end

	local color = this:GetColor()
	color.a = Clamp(a, 0, 255)

	WireLib.SetColor(this, color)
end

e2function void entity:setRenderMode(mode)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this entity!", nil) end
	if this:IsPlayer() then return self:throw("You cannot set the render mode of a player!", nil) end

	this:SetRenderMode(mode)
	duplicator.StoreEntityModifier(this, "colour", { RenderMode = mode })
end

e2function vector entity:getPlayerColor()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	if not this:IsPlayer() then return self:throw("Expected player but got an entity", Vector(0, 0, 0)) end

	local c = this:GetPlayerColor()

	return Vector(RGBClamp(Round(c.r * 255), Round(c.g * 255), Round(c.b * 255)))
end

e2function vector entity:getWeaponColor()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	if not this:IsPlayer() then return self:throw("Expected player but got an entity", Vector(0, 0, 0)) end

	local c = this:GetWeaponColor()
	return Vector(RGBClamp(Round(c.r * 255), Round(c.g * 255), Round(c.b * 255)))
end

e2function void entity:setWeaponColor(vector c)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You cannot set other player's weapon colors!", nil) end
	if not this:IsPlayer() then return self:throw("You cannot set the weapon color of non-players!", nil) end

	local r, g, b = RGBClamp(c[1], c[2], c[3])
	this:SetWeaponColor( Vector(r / 255, g / 255, b / 255) )
end

e2function void entity:setPlayerColor(vector c)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You cannot set other player's colors!", nil) end
 	if not this:IsPlayer() then return self:throw("You cannot set the player color of non-players!", nil) end

	 local r, g, b = RGBClamp(c[1], c[2], c[3])
	this:SetPlayerColor( Vector(r / 255, g / 255, b / 255) )
end

--- HSV

--- Converts <hsv> from the [http://en.wikipedia.org/wiki/HSV_color_space HSV color space] to the [http://en.wikipedia.org/wiki/RGB_color_space RGB color space]
e2function vector hsv2rgb(vector hsv)
	local col = HSVToColor(math.Clamp(hsv[1] % 360, 0, 360), hsv[2], hsv[3])
	return Vector(col.r, col.g, col.b)
end

e2function vector hsv2rgb(h, s, v)
	local col = HSVToColor(math.Clamp(h % 360, 0, 360), s, v)
	return Vector(col.r, col.g, col.b)
end

--- Converts <rgb> from the [http://en.wikipedia.org/wiki/RGB_color_space RGB color space] to the [http://en.wikipedia.org/wiki/HSV_color_space HSV color space]
e2function vector rgb2hsv(vector rgb)
	return Vector(ColorToHSV(Color(rgb[1], rgb[2], rgb[3])))
end

e2function vector rgb2hsv(r, g, b)
	return Vector(ColorToHSV(Color(r, g, b)))
end

--- HSL

local function Convert_hue2rgb(p, q, t)
	if t < 0 then t = t + 1 end
	if t > 1 then t = t - 1 end
	if t < 1/6 then return p + (q - p) * 6 * t end
	if t < 1/2 then return q end
	if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
	return p
end

local function Convert_hsl2rgb(h, s, l)
	local r = 0
	local g = 0
	local b = 0

	if s == 0 then
		r = l
		g = l
		b = l
	else
		local q = l + s - l * s
		if l < 0.5 then q = l * (1 + s) end
		local p = 2 * l - q
		r = Convert_hue2rgb(p, q, h + 1/3)
		g = Convert_hue2rgb(p, q, h)
		b = Convert_hue2rgb(p, q, h - 1/3)
	end

	return floor(r * 255), floor(g * 255), floor(b * 255)
end

local function Convert_rgb2hsl(r, g, b)
	r = r / 255
	g = g / 255
	b = b / 255
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h = (max + min) / 2
	local s = h
	local l = h

	if max == min then
		h = 0
		s = 0
	else
		local d = max - min
		s =  d / (max + min)
		if l > 0.5 then s = d / (2 - max - min) end
		if max == r then
			if g < b then
				h = (g - b) / d + 6
			else
				h = (g - b) / d + 0
			end
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

--- Converts <hsl> HSL color space to RGB color space
e2function vector hsl2rgb(vector hsl)
	return Vector(RGBClamp(Convert_hsl2rgb(hsl[1] / 360, hsl[2], hsl[3])))
end

e2function vector hsl2rgb(h, s, l)
	return Vector(RGBClamp(Convert_hsl2rgb(h / 360, s, l)))
end

--- Converts <rgb> RGB color space to HSL color space
e2function vector rgb2hsl(vector rgb)
	local h,s,l = Convert_rgb2hsl(RGBClamp(rgb[1], rgb[2], rgb[3]))
	return Vector(floor(h * 360), s, l)
end

e2function vector rgb2hsl(r, g, b)
	local h,s,l = Convert_rgb2hsl(RGBClamp(r, g, b))
	return Vector(floor(h * 360), s, l)
end

--- DIGI

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
[nodiscard]
e2function number rgb2digi(vector rgb, mode)
	local conv = converters[mode]
	if not conv then return self:throw("Mode " .. mode .. " does not exist!", 0) end
	return conv(rgb[1], rgb[2], rgb[3])
end

--- Converts the RGB color (<r>,<g>,<b>) to a number in digital screen format. <mode> Specifies a mode, either 0, 2 or 3, corresponding to Digital Screen color modes.
[nodiscard]
e2function number rgb2digi(r, g, b, mode)
	local conv = converters[mode]
	if not conv then return self:throw("Mode " .. mode .. " does not exist!", 0) end
	return conv(r, g, b)
end
