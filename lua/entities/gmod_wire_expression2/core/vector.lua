--------------------------------------------------------------------------------
--  Vector support                                                            --
--------------------------------------------------------------------------------

local random = math.random
local Vector = Vector
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil
local clamp = math.Clamp
local pi = math.pi
local cos = math.cos
local sin = math.sin
local atan2 = math.atan2
local asin = math.asin
local rad2deg = 180 / pi
local deg2rad = pi / 180

local LerpVector = LerpVector
local quadraticBezier = math.QuadraticBezier
local cubicBezier = math.CubicBezier

-- TODO: add reflect?
-- TODO: add absdotproduct?
-- TODO: add helper for angle and dotproduct? (just strange?)

--------------------------------------------------------------------------------

registerType("vector", "v", Vector(0, 0, 0),
	nil,
	function(self, output) return Vector(output) end,
	nil,
	function(v)
		return not isvector(v)
	end
)

E2Lib.registerConstant("VECTOR_ORIGIN", Vector(0, 0, 0), "Origin of the map. This is vec(0, 0, 0)")
E2Lib.registerConstant("VECTOR_UP", Vector(0, 0, 1), "Upward direction. This is vec(0, 0, 1)")

--------------------------------------------------------------------------------

__e2setcost(1) -- approximated

e2function vector vec()
	return Vector(0, 0, 0)
end

__e2setcost(2)

e2function vector vec(x)
	return Vector(x, x, x)
end

e2function vector vec(x, y, z)
	return Vector(x, y, z)
end

e2function vector vec(vector2 v2)
	return Vector(v2[1], v2[2], 0)
end

e2function vector vec(vector2 v2, z)
	return Vector(v2[1], v2[2], z)
end

e2function vector vec(vector4 v4)
	return Vector(v4[1], v4[2], v4[3])
end

--- Convert Angle -> Vector
e2function vector vec(angle ang)
	return Vector(ang:Unpack())
end

--------------------------------------------------------------------------------

e2function number operator_is(vector this)
	return this:IsZero() and 0 or 1
end

--------------------------------------------------------------------------------

__e2setcost(1)

e2function vector operator_neg(vector v)
	return -v
end

e2function vector operator+(lhs, vector rhs)
	local rx, ry, rz = rhs:Unpack()
	return Vector(lhs + rx, lhs + ry, lhs + rz)
end

e2function vector operator+(vector lhs, rhs)
	local lx, ly, lz = lhs:Unpack()
	return Vector(lx + rhs, ly + rhs, lz + rhs)
end

e2function vector operator+(vector lhs, vector rhs)
	return lhs + rhs
end

e2function vector operator-(lhs, vector rhs)
	local rx, ry, rz = rhs:Unpack()
	return Vector(lhs - rx, lhs - ry, lhs - rz)
end

e2function vector operator-(vector lhs, rhs)
	local lx, ly, lz = lhs:Unpack()
	return Vector(lx - rhs, ly - rhs, lz - rhs)
end

e2function vector operator-(vector lhs, vector rhs)
	return lhs - rhs
end

e2function vector operator*(lhs, vector rhs)
	return lhs * rhs
end

e2function vector operator*(vector lhs, rhs)
	return lhs * rhs
end

e2function vector operator*(vector lhs, vector rhs)
	local lx, ly, lz = lhs:Unpack()
	local rx, ry, rz = rhs:Unpack()

	return Vector(lx * rx, ly * ry, lz * rz)
end

-- Yes this needs to be in pure lua. Angle/Vector operations in reverse order act as Angle / Number rather than Number / Angle properly. Amazing.
e2function vector operator/(lhs, vector rhs)
	local rx, ry, rz = rhs:Unpack()
	return Vector(lhs / rx, lhs / ry, lhs / rz)
end

e2function vector operator/(vector lhs, rhs)
	return lhs / rhs
end

e2function vector operator/(vector lhs, vector rhs)
	local lx, ly, lz = lhs:Unpack()
	local rx, ry, rz = rhs:Unpack()

	return Vector(lx / rx, ly / ry, lz / rz)
end

registerOperator("indexget", "vn", "n", function(state, this, index)
	return this[floor(clamp(index, 1, 3) + 0.5)]
end)

registerOperator("indexset", "vnn", "", function(state, this, index, value)
	this[floor(clamp(index, 1, 3) + 0.5)] = value
	state.GlobalScope.vclk[this] = true
end)

e2function string operator+(string lhs, vector rhs)
	self.prf = self.prf + #lhs * 0.01
	return lhs .. string.format("vec(%g,%g,%g)", rhs:Unpack())
end

e2function string operator+(vector lhs, string rhs)
	self.prf = self.prf + #rhs * 0.01
	return string.format("vec(%g,%g,%g)", lhs:Unpack()) .. rhs
end

--------------------------------------------------------------------------------

__e2setcost(10) -- temporary

--- Returns a uniformly distributed, random, normalized direction vector.
e2function vector randvec()
	local s, a, x, y

	--[[
	  This is a variant of the algorithm for computing a random point
	  on the unit sphere; the algorithm is suggested in Knuth, v2,
	  3rd ed, p136; and attributed to Robert E Knop, CACM, 13 (1970),
	  326.
	]]
	-- translated to lua from http://mhda.asiaa.sinica.edu.tw/mhda/apps/gsl-1.6/randist/sphere.c

	-- Begin with the polar method for getting x,y inside a unit circle
	repeat
		x = random() * 2 - 1
		y = random() * 2 - 1
		s = x*x + y*y
	until s <= 1.0

	a = 2 * sqrt(1 - s) -- factor to adjust x,y so that x^2+y^2 is equal to 1-z^2
	return Vector(x*a, y*a, s * 2 - 1) -- z uniformly distributed from -1 to 1

	--[[
	-- This variant saves 2 multiplications per loop, woo. But it's not readable and not verified, thus commented out.
	-- I will also not add a cheaper non-uniform variant, as that can easily be derived from the other randvec functions and V:normalize().
	-- Begin with the polar method for getting x,y inside a (strangely skewed) unit circle
	repeat
		x = random()
		y = random()
		s = x*(x-1) + y*(y-1)
	until s <= -0.25

	a = sqrt(-16 - s*64) -- factor to adjust x,y so that x^2+y^2 is equal to 1-z^2
	return Vector((x-0.5)*a, (y-0.5)*a, s * 8 + 3) -- z uniformly distributed from -1 to 1
	]]
end

__e2setcost(5)

--- Returns a random vector with its components between <min> and <max>
e2function vector randvec(number min, number max)
	return VectorRand(min, max)
end

--- Returns a random vector between <min> and <max>
e2function vector randvec(vector min, vector max)
	local minx, miny, minz = min:Unpack()
	local maxx, maxy, maxz = max:Unpack()

	return Vector(minx + random() * (maxx - minx), miny + random() * (maxy - miny), minz + random() * (maxz - minz))
end

--------------------------------------------------------------------------------

__e2setcost(2)

e2function number vector:length()
	return this:Length()
end

e2function number vector:length2()
	return this:LengthSqr()
end

e2function number vector:distance(vector other)
	return this:Distance(other)
end

e2function number vector:distance2(vector other)
	return this:DistToSqr(other)
end

e2function vector vector:normalized()
	return this:GetNormalized()
end

e2function number vector:dot(vector other)
	return this:Dot(other)
end

e2function vector vector:cross(vector other)
	return this:Cross(other)
end

__e2setcost(10)

--- returns the outer product (tensor product) of two vectors
e2function matrix vector:outerProduct(vector other)
	local tx, ty, tz = this:Unpack()
	local ox, oy, oz = other:Unpack()

	return {
		tx * ox, tx * oy, tx * oz,
		ty * ox, ty * oy, ty * oz,
		tz * ox, tz * oy, tz * oz,
	}
end

__e2setcost(15)

e2function vector vector:rotateAroundAxis(vector axis, degrees)
	local x, y, z = axis:Unpack()
	local tx, ty, tz = this:Unpack()
	local ca, sa = cos(degrees * deg2rad), sin(degrees * deg2rad)

	local length = (x * x + y * y + z * z) ^ 0.5
	x, y, z = x / length, y / length, z / length

	return Vector(
		(ca + (x ^ 2) * (1 - ca)) * tx + (x * y * (1 - ca) - z * sa) * ty + (x * z * (1 - ca) + y * sa) * tz,
		(y * x * (1 - ca) + z * sa) * tx + (ca + (y ^ 2) * (1 - ca)) * ty + (y * z * (1 - ca) - x * sa) * tz,
		(z * x * (1 - ca) - y * sa) * tx + (z * y * (1 - ca) + x * sa) * ty + (ca + (z ^ 2) * (1 - ca)) * tz
	)
end

__e2setcost(5)

e2function vector vector:rotate(angle ang)
	local vec = Vector(this:Unpack())
	vec:Rotate(ang)

	return vec
end

e2function vector vector:rotate(normal pitch, normal yaw, normal roll)
	local vec = Vector(this:Unpack())
	vec:Rotate(Angle(pitch, yaw, roll))

	return vec
end

e2function vector2 vector:dehomogenized()
	local tx, ty, tz = this:Unpack()
	if tz == 0 then return { tx, ty } end

	return { tx / tz, ty / tz }
end

e2function vector positive(vector rv1)
	local rx1, ry1, rz1 = rv1:Unpack()
	return Vector(rx1 >= 0 and rx1 or -rx1, ry1 >= 0 and ry1 or -ry1, rz1 >= 0 and rz1 or -rz1)
end

__e2setcost(3)

--- Convert the magnitude of the vector to radians
e2function vector toRad(vector rv1)
	return rv1 * deg2rad
end

--- Convert the magnitude of the vector to degrees
e2function vector toDeg(vector rv1)
	return rv1 * rad2deg
end

--------------------------------------------------------------------------------

__e2setcost(5)

--- Returns a vector in the same direction as <vec>, with a length clamped between <min> and <max>
e2function vector clamp(vector vec, min, max)
	if min < 0 then min = 0 end

	local x, y, z = vec:Unpack()
	local length = x * x + y * y + z * z

	if length < min * min then
		length = min * (length ^ -0.5)
	elseif length > max * max then
		length = max * (length ^ -0.5)
	else
		return Vector(vec)
	end

	return vec * length
end

--------------------------------------------------------------------------------

__e2setcost(1)

e2function number vector:x()
	return this[1]
end

e2function number vector:y()
	return this[2]
end

e2function number vector:z()
	return this[3]
end

__e2setcost(2)

--- SET method that returns a new vector with x replaced
e2function vector vector:setX(x)
	local vec = Vector(this)
	vec.x = x

	return vec
end

--- SET method that returns a new vector with y replaced
e2function vector vector:setY(y)
	local vec = Vector(this)
	vec.y = y

	return vec
end

--- SET method that returns a new vector with z replaced
e2function vector vector:setZ(z)
	local vec = Vector(this)
	vec.z = z

	return vec
end

--------------------------------------------------------------------------------

__e2setcost(6)

e2function vector round(vector rv1)
	local rx1, ry1, rz1 = rv1:Unpack()
	return Vector(floor(rx1 + 0.5), floor(ry1 + 0.5), floor(rz1 + 0.5))
end

e2function vector round(vector rv1, decimals)
	local shf = 10 ^ decimals
	local rx1, ry1, rz1 = rv1:Unpack()

	return Vector(floor(rx1 * shf + 0.5) / shf, floor(ry1 * shf + 0.5) / shf, floor(rz1 * shf + 0.5) / shf)
end

e2function vector ceil(vector rv1)
	local rx1, ry1, rz1 = rv1:Unpack()
	return Vector(ceil(rx1), ceil(ry1), ceil(rz1))
end

e2function vector ceil(vector rv1, decimals)
	local shf = 10 ^ decimals
	local rx1, ry1, rz1 = rv1:Unpack()

	return Vector(ceil(rx1 * shf) / shf, ceil(ry1 * shf) / shf, ceil(rz1 * shf) / shf)
end

e2function vector floor(vector rv1)
	local rx1, ry1, rz1 = rv1:Unpack()
	return Vector(floor(rx1), floor(ry1), floor(rz1))
end

e2function vector floor(vector rv1, decimals)
	local shf = 10 ^ decimals
	local rx1, ry1, rz1 = rv1:Unpack()

	return Vector(floor(rx1 * shf) / shf, floor(ry1 * shf) / shf, floor(rz1 * shf) / shf)
end

__e2setcost(10)

--- min/max based on vector length - returns shortest/longest vector
e2function vector min(vector vec1, vector vec2)
	return vec1:LengthSqr() < vec2:LengthSqr() and vec1 or vec2
end

e2function vector max(vector vec1, vector vec2)
	return vec1:LengthSqr() > vec2:LengthSqr() and vec1 or vec2
end

--- component-wise min/max
e2function vector maxVec(vector rv1, vector rv2)
	local rx1, ry1, rz1 = rv1:Unpack()
	local rx2, ry2, rz2 = rv2:Unpack()

	return Vector(rx1 > rx2 and rx1 or rx2, ry1 > ry2 and ry1 or ry2, rz1 > rz2 and rz1 or rz2)
end

e2function vector minVec(vector rv1, vector rv2)
	local rx1, ry1, rz1 = rv1:Unpack()
	local rx2, ry2, rz2 = rv2:Unpack()

	return Vector(rx1 < rx2 and rx1 or rx2, ry1 < ry2 and ry1 or ry2, rz1 < rz2 and rz1 or rz2)
end

--- Performs modulo on x,y,z separately
e2function vector mod(vector rv1, rv2)
	local rx1, ry1, rz1 = rv1:Unpack()
	return Vector(rx1 % (rx1 >= 0 and rv2 or -rv2), ry1 % (ry1 >= 0 and rv2 or -rv2), rz1 % (rz1 >= 0 and rv2 or -rv2))
end

--- Modulo where divisors are defined as a vector
e2function vector mod(vector rv1, vector rv2)
	local rx1, ry1, rz1 = rv1:Unpack()
	local rx2, ry2, rz2 = rv2:Unpack()

	return Vector(rx1 % (rx1 >= 0 and rx2 or -rx2), ry1 % (ry1 >= 0 and ry2 or -ry2), rz1 % (rz1 >= 0 and rz2 or -rz2))
end

--- Clamp according to limits defined by two min/max vectors
e2function vector clamp(vector value, vector min, vector max)
	local x, y, z
	local rx1, ry1, rz1 = value:Unpack()
	local rx2, ry2, rz2 = min:Unpack()
	local rx3, ry3, rz3 = max:Unpack()

	if rx1 < rx2 then
		p = rx2
	elseif rx1 > rx3 then
		p = rx3
	else
		p = rx1
	end

	if ry1 < ry2 then
		y = ry2
	elseif ry1 > ry3 then
		y = ry3
	else
		y = ry1
	end

	if rz1 < rz2 then
		r = rz2
	elseif rz1 > rz3 then
		r = rz3
	else
		r = rz1
	end

	return Vector(x, y, z)
end

e2function vector lerp(vector from, vector to, fraction)
	return LerpVector(fraction, from, to)
end

[deprecated = "Use lerp instead"]
e2function vector mix(vector to, vector from, fraction)
	return LerpVector(fraction, from, to)
end

e2function vector bezier(vector startVec, vector tangent, vector endVec, ratio)
	return quadraticBezier(ratio, startVec, tangent, endVec)
end

e2function vector bezier(vector startVec, vector tangent1, vector tangent2, vector endVec, ratio)
	return cubicBezier(ratio, startVec, tangent1, tangent2, endVec)
end

__e2setcost(2)

--- Circular shift function: shiftR(vec(x,y,z)) = vec(z,x,y)
e2function vector shiftR(vector vec)
	local x, y, z = vec:Unpack()
	return Vector(z, x, y)
end

--- Circular shift function: shiftL(vec(x,y,z)) = vec(y,z,x)
e2function vector shiftL(vector vec)
	local x, y, z = vec:Unpack()
	return Vector(y, z, x)
end

__e2setcost(5)

--- Returns 1 if the vector lies between (or is equal to) the min/max vectors
e2function number inrange(vector vec, vector min, vector max)
	local rx1, ry1, rz1 = vec:Unpack()
	local rx2, ry2, rz2 = min:Unpack()

	if rx1 < rx2 then return 0 end
	if ry1 < ry2 then return 0 end
	if rz1 < rz2 then return 0 end

	local rx3, ry3, rz3 = max:Unpack()

	if rx1 > rx3 then return 0 end
	if ry1 > ry3 then return 0 end
	if rz1 > rz3 then return 0 end

	return 1
end

--------------------------------------------------------------------------------

__e2setcost(3)

e2function angle vector:toAngle()
	return this:Angle()
end

e2function angle vector:toAngle(vector up)
	return this:AngleEx(up)
end

--------------------------------------------------------------------------------

local contents = {
	[CONTENTS_EMPTY] = "empty",
	[CONTENTS_SOLID] = "solid",
	[CONTENTS_WINDOW] = "window",
	[CONTENTS_AUX] = "aux",
	[CONTENTS_GRATE] = "grate",
	[CONTENTS_SLIME] = "slime",
	[CONTENTS_WATER] = "water",
	[CONTENTS_BLOCKLOS] = "blocklos",
	[CONTENTS_OPAQUE] = "opaque",
	[CONTENTS_TESTFOGVOLUME] = "testfogvolume",
	[CONTENTS_TEAM4] = "team4",
	[CONTENTS_TEAM3] = "team3",
	[CONTENTS_TEAM1] = "team1",
	[CONTENTS_TEAM2] = "team2",
	[CONTENTS_IGNORE_NODRAW_OPAQUE] = "ignore_nodraw_opaque",
	[CONTENTS_MOVEABLE] = "moveable",
	[CONTENTS_AREAPORTAL] = "areaportal",
	[CONTENTS_PLAYERCLIP] = "playerclip",
	[CONTENTS_MONSTERCLIP] = "monsterclip",
	[CONTENTS_CURRENT_0] = "current_0",
	[CONTENTS_CURRENT_90] = "current_90",
	[CONTENTS_CURRENT_180] = "current_180",
	[CONTENTS_CURRENT_270] = "current_270",
	[CONTENTS_CURRENT_UP] = "current_up",
	[CONTENTS_CURRENT_DOWN] = "current_down",
	[CONTENTS_ORIGIN] = "origin",
	[CONTENTS_MONSTER] = "monster",
	[CONTENTS_DEBRIS] = "debris",
	[CONTENTS_DETAIL] = "detail",
	[CONTENTS_TRANSLUCENT] = "translucent",
	[CONTENTS_LADDER] = "ladder",
	[CONTENTS_HITBOX] = "hitbox"
}

local cachemeta = {}
local cache_parts_array = setmetatable({ [0] = {} }, cachemeta)
local cache_lookup_table = setmetatable({ [0] = { empty = true } }, cachemeta)
local cache_concatenated_parts = setmetatable({ [0] = "empty" }, cachemeta)

local function generateContents(n)
	local parts_array, lookup_table = {}, {}

	for i = 0, 30 do
		local v = bit.lshift(1, i)

		if bit.band(n, v) ~= 0 then
			local name = contents[v]
			lookup_table[name] = true
			parts_array[#parts_array+1] = name
		end
	end

	concatenated_parts = table.concat(parts_array, ",")
	cache_parts_array[n] = parts_array
	cache_lookup_table[n] = lookup_table
	cache_concatenated_parts[n] = concatenated_parts

	return concatenated_parts
end

function cachemeta:__index(n)
	generateContents(n)
	return rawget(self, n)
end

__e2setcost(20)

e2function number pointHasContent(vector point, string has)
	local contents = cache_lookup_table[util.PointContents(point)]
	has = string.lower(string.gsub(has, " ", "_"))

	for m in string.gmatch(has, "([^,]+),?") do
		if contents[m] then
			return 1
		end
	end

	return 0
end

__e2setcost(15)

e2function string pointContents(vector point)
	return cache_concatenated_parts[util.PointContents(point)]
end

e2function array pointContentsArray(vector point)
	return cache_parts_array[util.PointContents(point)]
end

--------------------------------------------------------------------------------

__e2setcost(15)

--- Converts a local position/angle to a world position/angle and returns the position
e2function vector toWorld(vector localpos, angle localang, vector worldpos, angle worldang)
	return LocalToWorld(localpos, localang, worldpos, worldang)
end

--- Converts a local position/angle to a world position/angle and returns the angle
e2function angle toWorldAng(vector localpos, angle localang, vector worldpos, angle worldang)
	local _, ang = LocalToWorld(localpos, localang, worldpos, worldang)
	return ang
end

--- Converts a local position/angle to a world position/angle and returns both in an array
e2function array toWorldPosAng(vector localpos, angle localang, vector worldpos, angle worldang)
	return { LocalToWorld(localpos, localang, worldpos, worldang) }
end

--- Converts a world position/angle to a local position/angle and returns the position
e2function vector toLocal(vector localpos, angle localang, vector worldpos, angle worldang)
	return WorldToLocal(localpos, localang, worldpos, worldang)
end

--- Converts a world position/angle to a local position/angle and returns the angle
e2function angle toLocalAng(vector localpos, angle localang, vector worldpos, angle worldang)
	local _, ang = WorldToLocal(localpos, localang, worldpos, worldang)
	return ang
end

--- Converts a world position/angle to a local position/angle and returns both in an array
e2function array toLocalPosAng(vector localpos, angle localang, vector worldpos, angle worldang)
	local pos, ang = WorldToLocal(localpos, localang, worldpos, worldang)
	return { pos, ang }
end

--------------------------------------------------------------------------------
-- Credits to Wizard of Ass for bearing(v,a,v) and elevation(v,a,v)

local angle_zero = angle_zero

e2function number bearing(vector originpos, angle originangle, vector pos)
	pos = WorldToLocal(pos, angle_zero, originpos, originangle)
	return rad2deg * -atan2(pos.y, pos.x)
end

e2function number elevation(vector originpos, angle originangle, vector pos)
	pos = WorldToLocal(pos, angle_zero, originpos, originangle)

	local len = pos:Length()
	if len < 0 then return 0 end

	return rad2deg * asin(pos.z / len)
end

e2function angle heading(vector originpos,angle originangle, vector pos)
	pos = WorldToLocal(pos, angle_zero, originpos, originangle)

	local len = pos:Length()
	local posx, posy, posz = pos:Unpack()
	local bearing = rad2deg * -atan2(posy, posx)
	if len < 0 then return Angle(0, bearing, 0) end

	return Angle(rad2deg * asin(posz / len), bearing, 0)
end

--------------------------------------------------------------------------------

__e2setcost(10)

e2function number vector:isInWorld()
	return util.IsInWorld(this) and 1 or 0
end

__e2setcost(5)

e2function string toString(vector vec)
	return string.format("vec(%g,%g,%g)", vec:Unpack())
end

--- Gets the vector nicely formatted as a string "[X,Y,Z]"
e2function string vector:toString() = e2function string toString(vector vec)
