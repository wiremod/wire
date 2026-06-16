--------------------------------------------------------------------------------
--  Vector support                                                            --
--------------------------------------------------------------------------------

local random = math.random
local Vector = Vector
local sqrt = math.sqrt
local floor = math.floor
local ceil = math.ceil
local pi = math.pi
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
	return Vector(ang[1], ang[2], ang[3])
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
	return Vector(lhs + rhs[1], lhs + rhs[2], lhs + rhs[3])
end

e2function vector operator+(vector lhs, rhs)
	return Vector(lhs[1] + rhs, lhs[2] + rhs, lhs[3] + rhs)
end

e2function vector operator+(vector lhs, vector rhs)
	return lhs + rhs
end

e2function vector operator-(lhs, vector rhs)
	return Vector(lhs - rhs[1], lhs - rhs[2], lhs - rhs[3])
end

e2function vector operator-(vector lhs, rhs)
	return Vector(lhs[1] - rhs, lhs[2] - rhs, lhs[3] - rhs)
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
	return Vector( lhs[1] * rhs[1], lhs[2] * rhs[2], lhs[3] * rhs[3] )
end

-- Yes this needs to be in pure lua. Angle/Vector operations in reverse order act as Angle / Number rather than Number / Angle properly. Amazing.
e2function vector operator/(lhs, vector rhs)
	return Vector( lhs / rhs[1], lhs / rhs[2], lhs / rhs[3] )
end

e2function vector operator/(vector lhs, rhs)
	return lhs / rhs
end

e2function vector operator/(vector lhs, vector rhs)
	return Vector( lhs[1] / rhs[1], lhs[2] / rhs[2], lhs[3] / rhs[3] )
end

registerOperator("indexget", "vn", "n", function(state, this, index)
	return this[floor(math.Clamp(index, 1, 3) + 0.5)]
end)

registerOperator("indexset", "vnn", "", function(state, this, index, value)
	this[floor(math.Clamp(index, 1, 3) + 0.5)] = value
	state.GlobalScope.vclk[this] = true
end)

e2function string operator+(string lhs, vector rhs)
	self.prf = self.prf + #lhs * 0.01
	return lhs .. ("vec(%g,%g,%g)"):format(rhs[1], rhs[2], rhs[3])
end

e2function string operator+(vector lhs, string rhs)
	self.prf = self.prf + #rhs * 0.01
	return ("vec(%g,%g,%g)"):format(lhs[1], lhs[2], lhs[3]) .. rhs
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
	local v = Vector()
	v:Random(min, max)
	return v
end

--- Returns a random vector between <min> and <max>
e2function vector randvec(vector min, vector max)
	local minx, miny, minz = min[1], min[2], min[3]
	return Vector(minx+random()*(max[1]-minx), miny+random()*(max[2]-miny), minz+random()*(max[3]-minz))
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

e2function number vector:distance2( vector other )
	return this:DistToSqr(other)
end

e2function vector vector:normalized()
	return this:GetNormalized()
end

e2function number vector:dot( vector other )
	return this:Dot(other)
end

e2function vector vector:cross( vector other )
	return this:Cross(other)
end

__e2setcost(10)

--- returns the outer product (tensor product) of two vectors
e2function matrix vector:outerProduct( vector other )
	return {
		this[1] * this[1], this[1] * other[2], this[1] * other[3],
		this[2] * this[1], this[2] * other[2], this[2] * other[3],
		this[3] * this[1], this[3] * other[2], this[3] * other[3],
	}
end

__e2setcost(15)
e2function vector vector:rotateAroundAxis(vector axis, degrees)
	local ca, sa = math.cos(degrees*deg2rad), math.sin(degrees*deg2rad)
	local x,y,z = axis[1], axis[2], axis[3]
	local length = (x*x+y*y+z*z)^0.5
	x,y,z = x/length, y/length, z/length

	return Vector((ca + (x^2)*(1-ca)) * this[1] + (x*y*(1-ca) - z*sa) * this[2] + (x*z*(1-ca) + y*sa) * this[3],
			(y*x*(1-ca) + z*sa) * this[1] + (ca + (y^2)*(1-ca)) * this[2] + (y*z*(1-ca) - x*sa) * this[3],
			(z*x*(1-ca) - y*sa) * this[1] + (z*y*(1-ca) + x*sa) * this[2] + (ca + (z^2)*(1-ca)) * this[3])
end

__e2setcost(5)

e2function vector vector:rotate( angle ang )
	local v = Vector(this[1], this[2], this[3])
	v:Rotate(ang)
	return v
end

e2function vector vector:rotate( normal pitch, normal yaw, normal roll )
	local v = Vector(this[1], this[2], this[3])
	v:Rotate(Angle(pitch, yaw, roll))
	return v
end

e2function vector2 vector:dehomogenized()
	local w = this[3]
	if w == 0 then return { this[1], this[2] } end
	return { this[1]/w, this[2]/w }
end

e2function vector positive(vector rv1)
	return Vector(
		rv1[1] >= 0 and rv1[1] or -rv1[1],
		rv1[2] >= 0 and rv1[2] or -rv1[2],
		rv1[3] >= 0 and rv1[3] or -rv1[3]
	)
end

__e2setcost(3)

--- Convert the magnitude of the vector to radians
e2function vector toRad(vector rv1)
	return Vector(rv1[1] * deg2rad, rv1[2] * deg2rad, rv1[3] * deg2rad)
end

--- Convert the magnitude of the vector to degrees
e2function vector toDeg(vector rv1)
	return Vector(rv1[1] * rad2deg, rv1[2] * rad2deg, rv1[3] * rad2deg)
end

--------------------------------------------------------------------------------

__e2setcost(5)

--- Returns a vector in the same direction as <Input>, with a length clamped between <Min> (min) and <Max> (max)
e2function vector clamp(vector Input, Min, Max)
	if Min < 0 then Min = 0 end
	local x,y,z = Input[1], Input[2], Input[3]
	local length = x*x+y*y+z*z
	if length < Min*Min then
		length = Min*(length ^ -0.5) -- Min*(length ^ -0.5) <=> Min/sqrt(length)
	elseif length > Max*Max then
		length = Max*(length ^ -0.5) -- Max*(length ^ -0.5) <=> Max/sqrt(length)
	else
		return Input
	end

	return Vector(x*length, y*length, z*length)
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
	return Vector(x, this[2], this[3])
end

--- SET method that returns a new vector with y replaced
e2function vector vector:setY(y)
	return Vector(this[1], y, this[3])
end

--- SET method that returns a new vector with z replaced
e2function vector vector:setZ(z)
	return Vector(this[1], this[2], z)
end

--------------------------------------------------------------------------------

__e2setcost(6)

e2function vector round(vector rv1)
	return Vector(
		floor(rv1[1] + 0.5),
		floor(rv1[2] + 0.5),
		floor(rv1[3] + 0.5)
	)
end

e2function vector round(vector rv1, decimals)
	local shf = 10 ^ decimals
	return Vector(
		floor(rv1[1] * shf + 0.5) / shf,
		floor(rv1[2] * shf + 0.5) / shf,
		floor(rv1[3] * shf + 0.5) / shf
	)
end

e2function vector ceil( vector rv1 )
	return Vector(
		ceil(rv1[1]),
		ceil(rv1[2]),
		ceil(rv1[3])
	)
end

e2function vector ceil(vector rv1, decimals)
	local shf = 10 ^ decimals
	return Vector (
		ceil(rv1[1] * shf) / shf,
		ceil(rv1[2] * shf) / shf,
		ceil(rv1[3] * shf) / shf
	)
end

e2function vector floor(vector rv1)
	return Vector(
		floor(rv1[1]),
		floor(rv1[2]),
		floor(rv1[3])
	)
end

e2function vector floor(vector rv1, decimals)
	local shf = 10 ^ decimals
	return Vector(
		floor(rv1[1] * shf) / shf,
		floor(rv1[2] * shf) / shf,
		floor(rv1[3] * shf) / shf
	)
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
	return Vector(
		rv1[1] > rv2[1] and rv1[1] or rv2[1],
		rv1[2] > rv2[2] and rv1[2] or rv2[2],
		rv1[3] > rv2[3] and rv1[3] or rv2[3]
	)
end

e2function vector minVec(vector rv1, vector rv2)
	return Vector(
		rv1[1] < rv2[1] and rv1[1] or rv2[1],
		rv1[2] < rv2[2] and rv1[2] or rv2[2],
		rv1[3] < rv2[3] and rv1[3] or rv2[3]
	)
end

--- Performs modulo on x,y,z separately
e2function vector mod(vector rv1, rv2)
	return Vector(
		rv1[1] >= 0 and rv1[1] % rv2 or rv1[1] % -rv2,
		rv1[2] >= 0 and rv1[2] % rv2 or rv1[2] % -rv2,
		rv1[3] >= 0 and rv1[3] % rv2 or rv1[3] % -rv2
	)
end

--- Modulo where divisors are defined as a vector
e2function vector mod(vector rv1, vector rv2)
	return Vector(
		rv1[1] >= 0 and rv1[1] % rv2[1] or rv1[1] % -rv2[1],
		rv1[2] >= 0 and rv1[2] % rv2[2] or rv1[2] % -rv2[2],
		rv1[3] >= 0 and rv1[3] % rv2[3] or rv1[3] % -rv2[3]
	)
end

--- Clamp according to limits defined by two min/max vectors
e2function vector clamp(vector value, vector min, vector max)
	local x,y,z

	if value[1] < min[1] then x = min[1]
	elseif value[1] > max[1] then x = max[1]
	else x = value[1] end

	if value[2] < min[2] then y = min[2]
	elseif value[2] > max[2] then y = max[2]
	else y = value[2] end

	if value[3] < min[3] then z = min[3]
	elseif value[3] > max[3] then z = max[3]
	else z = value[3] end

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
	return Vector(vec[3], vec[1], vec[2])
end

--- Circular shift function: shiftL(vec(x,y,z)) = vec(y,z,x)
e2function vector shiftL(vector vec)
	return Vector(vec[2], vec[3], vec[1])
end

__e2setcost(5)

--- Returns 1 if the vector lies between (or is equal to) the min/max vectors
e2function number inrange(vector vec, vector min, vector max)
	if vec[1] < min[1] then return 0 end
	if vec[2] < min[2] then return 0 end
	if vec[3] < min[3] then return 0 end

	if vec[1] > max[1] then return 0 end
	if vec[2] > max[2] then return 0 end
	if vec[3] > max[3] then return 0 end

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

local contents = {}
for k,v in pairs(_G) do
	if (k:sub(1,9) == "CONTENTS_") then
		contents[v] = k:sub(10):lower()
	end
end

local cachemeta = {}

local cache_parts_array = setmetatable({ [0] = {} }, cachemeta)
local cache_lookup_table = setmetatable({ [0] = { empty = true } }, cachemeta)
local cache_concatenated_parts = setmetatable({ [0] = "empty" }, cachemeta)

local function generateContents( n )
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

__e2setcost( 20 )

e2function number pointHasContent( vector point, string has )
	local cont = cache_lookup_table[util.PointContents(Vector(point[1], point[2], point[3]))]

	has = has:gsub(" ", "_"):lower()

	for m in has:gmatch("([^,]+),?") do
		if cont[m] then return 1 end
	end

	return 0
end

__e2setcost( 15 )

e2function string pointContents( vector point )
	return cache_concatenated_parts[util.PointContents(point)]
end

e2function array pointContentsArray( vector point )
	return cache_parts_array[util.PointContents(point)]
end

--------------------------------------------------------------------------------

__e2setcost(15)

--- Converts a local position/angle to a world position/angle and returns the position
e2function vector toWorld( vector localpos, angle localang, vector worldpos, angle worldang )
	return LocalToWorld(localpos, localang, worldpos, worldang)
end

--- Converts a local position/angle to a world position/angle and returns the angle
e2function angle toWorldAng( vector localpos, angle localang, vector worldpos, angle worldang )
	local _, ang = LocalToWorld(localpos, localang, worldpos, worldang)
	return ang
end

--- Converts a local position/angle to a world position/angle and returns both in an array
e2function array toWorldPosAng( vector localpos, angle localang, vector worldpos, angle worldang )
	return { LocalToWorld(localpos,localang,worldpos,worldang) }
end

--- Converts a world position/angle to a local position/angle and returns the position
e2function vector toLocal( vector localpos, angle localang, vector worldpos, angle worldang )
	return WorldToLocal(localpos,localang,worldpos,worldang)
end

--- Converts a world position/angle to a local position/angle and returns the angle
e2function angle toLocalAng( vector localpos, angle localang, vector worldpos, angle worldang )
	local _, ang = WorldToLocal(localpos, localang, worldpos, worldang)
	return ang
end

--- Converts a world position/angle to a local position/angle and returns both in an array
e2function array toLocalPosAng( vector localpos, angle localang, vector worldpos, angle worldang )
	local pos, ang = WorldToLocal(localpos,localang,worldpos,worldang)
	return {pos, ang}
end

--------------------------------------------------------------------------------
-- Credits to Wizard of Ass for bearing(v,a,v) and elevation(v,a,v)

local ANG_ZERO = angle_zero
e2function number bearing(vector originpos, angle originangle, vector pos)
	pos = WorldToLocal(pos, ANG_ZERO, originpos, originangle)
	return rad2deg * -atan2(pos.y, pos.x)
end

e2function number elevation(vector originpos, angle originangle, vector pos)
	pos = WorldToLocal(pos, ANG_ZERO, originpos, originangle)
	local len = pos:Length()
	if len < 0 then return 0 end
	return rad2deg * asin(pos.z / len)
end

e2function angle heading(vector originpos,angle originangle, vector pos)
	pos = WorldToLocal(pos, ANG_ZERO, originpos, originangle)

	local bearing = rad2deg*-atan2(pos.y, pos.x)

	local len = pos:Length()
	if len < 0 then return Angle(0, bearing, 0) end
	return Angle(rad2deg*asin(pos.z / len), bearing, 0)
end

--------------------------------------------------------------------------------

__e2setcost( 10 )


e2function number vector:isInWorld()
	if util.IsInWorld(this) then return 1 else return 0 end
end

__e2setcost( 5 )

e2function string toString(vector v)
	return ("vec(%g,%g,%g)"):format(v[1], v[2], v[3])
end

--- Gets the vector nicely formatted as a string "[X,Y,Z]"
e2function string vector:toString() = e2function string toString(vector v)
