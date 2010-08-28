/******************************************************************************\
  Vector support
\******************************************************************************/

local delta  = wire_expression2_delta

local random = math.random
local Vector = Vector
local sqrt = math.sqrt
local floor = math.floor
local pi = math.pi

// TODO: add reflect?
// TODO: add absdotproduct?
// TODO: add helper for angle and dotproduct? (just strange?)

/******************************************************************************/

registerType("vector", "v", { 0, 0, 0 },
	nil,
	function(self, output) return Vector(output[1], output[2], output[3]) end,
	function(retval)
		if type(retval) == "Vector" then return end
		if type(retval) ~= "table" then error("Return value is neither a Vector nor a table, but a "..type(retval).."!",0) end
		if #retval ~= 3 then error("Return value does not have exactly 3 entries!",0) end
	end,
	function(v)
		return type(v) ~= "Vector" and (type(v) ~= "table" or #v ~= 3)
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("vec", "", "v", function(self, args)
	return { 0, 0, 0 }
end)

__e2setcost(3) -- temporary

registerFunction("vec", "nnn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1, rv2, rv3 }
end)

registerFunction("vec", "xv2", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0 }
end)

registerFunction("vec", "xv2n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2 }
end)

registerFunction("vec", "xv4", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3] }
end)

// Convert Angle -> Vector
registerFunction("vec", "a", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3] }
end)

/******************************************************************************/

registerOperator("ass", "v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "v", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "vv", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1, rv2 = self.vars[op1], self.vars["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("neg", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end)

registerOperator("add", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 + rv2[1], rv1 + rv2[2], rv1 + rv2[3] }
end)

registerOperator("add", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2, rv1[2] + rv2, rv1[3] + rv2 }
end)

registerOperator("add", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end)

registerOperator("sub", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 - rv2[1], rv1 - rv2[2], rv1 - rv2[3] }
end)

registerOperator("sub", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2, rv1[2] - rv2, rv1[3] - rv2 }
end)

registerOperator("sub", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

registerOperator("mul", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end)

registerOperator("mul", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end)

registerOperator("mul", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] }
end)

registerOperator("div", "nv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end)

registerOperator("div", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end)

registerOperator("div", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3] }
end)

e2function normal vector:operator[](index)
	index = math.Round(math.Clamp(index,1,3))
	return this[index]
end

/******************************************************************************/

__e2setcost(10) -- temporary

--- Returns a uniformly distributed, random, normalized direction vector.
e2function vector randvec()
	local s,a, x,y

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
e2function vector randvec(min, max)
	local range = max-min
	return Vector(min+random()*range, min+random()*range, min+random()*range)
end

--- Returns a random vector between <min> and <max>
e2function vector randvec(vector min, vector max)
	local minx, miny, minz = min[1], min[2], min[3]
	return Vector(minx+random()*(max[1]-minx), miny+random()*(max[2]-miny), minz+random()*(max[3]-minz))
end

/******************************************************************************/

__e2setcost(5)

registerFunction("length", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
end)

registerFunction("length2", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]
end)

registerFunction("distance", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return (rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3) ^ 0.5
end)

registerFunction("distance2", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3]
	return rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3
end)

registerFunction("normalized", "v:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]) ^ 0.5
	if len > delta then
		return { rv1[1] / len, rv1[2] / len, rv1[3] / len }
	else
		return { 0, 0, 0 }
	end
end)

// TODO: map these are EXP (dot) and MOD (cross) or something?
registerFunction("dot", "v:v", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3]
end)

registerFunction("cross", "v:v", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return {
		rv1[2] * rv2[3] - rv1[3] * rv2[2],
		rv1[3] * rv2[1] - rv1[1] * rv2[3],
		rv1[1] * rv2[2] - rv1[2] * rv2[1]
	}
end)

registerFunction("rotate", "v:a", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local v = Vector(rv1[1], rv1[2], rv1[3])
	v:Rotate(Angle(rv2[1], rv2[2], rv2[3]))
	return { v.x, v.y, v.z }
end)

registerFunction("rotate", "v:nnn", "v", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local v = Vector(rv1[1], rv1[2], rv1[3])
	v:Rotate(Angle(rv2, rv3, rv4))
	return { v.x, v.y, v.z }
end)

registerFunction("dehomogenized", "v:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local w = rv1[3]
	if w == 0 then return { rv1[1], rv1[2] } end
	return { rv1[1]/w, rv1[2]/w }
end)

registerFunction("positive", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x, y, z
	if rv1[1] >= 0 then x = rv1[1] else x = -rv1[1] end
	if rv1[2] >= 0 then y = rv1[2] else y = -rv1[2] end
	if rv1[3] >= 0 then z = rv1[3] else z = -rv1[3] end
	return { x, y, z }
end)

// Convert the magnitude of the vector to radians
e2function vector toRad(vector rv1)
	return Vector(rv1[1] * pi / 180, rv1[2] * pi / 180, rv1[3] * pi / 180)
end

// Convert the magnitude of the vector to degrees
e2function vector toDeg(vector rv1)
	return Vector(rv1[1] * 180 / pi, rv1[2] * 180 / pi, rv1[3] * 180 / pi)
end

/******************************************************************************/

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

	return { x*length, y*length, z*length }
end

/******************************************************************************/

__e2setcost(2)

registerFunction("x", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("z", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

// SET methods that returns vectors
registerFunction("setX", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2, rv1[2], rv1[3] }
end)

registerFunction("setY", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2, rv1[3] }
end)

registerFunction("setZ", "v:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2 }
end)

/******************************************************************************/

__e2setcost(10)

registerFunction("round", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - (rv1[1] + 0.5) % 1 + 0.5
	local y = rv1[2] - (rv1[2] + 0.5) % 1 + 0.5
	local z = rv1[3] - (rv1[3] + 0.5) % 1 + 0.5
	return {x, y, z}
end)

registerFunction("round", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	local shf = 10 ^ rv2
	local x,y,z = rv1[1], rv1[2], rv1[3]

	return {
		floor(x*shf+0.5)/shf,
		floor(y*shf+0.5)/shf,
		floor(z*shf+0.5)/shf,
	}
end)

registerFunction("ceil", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % -1
	local y = rv1[2] - rv1[2] % -1
	local z = rv1[3] - rv1[3] % -1
	return {x, y, z}
end)

registerFunction("ceil", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % -1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % -1) / shf
	local z = rv1[3] - ((rv1[3] * shf) % -1) / shf
	return {x, y, z}
end)

registerFunction("floor", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x = rv1[1] - rv1[1] % 1
	local y = rv1[2] - rv1[2] % 1
	local z = rv1[3] - rv1[3] % 1
	return {x, y, z}
end)

registerFunction("floor", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local shf = 10 ^ rv2
	local x = rv1[1] - ((rv1[1] * shf) % 1) / shf
	local y = rv1[2] - ((rv1[2] * shf) % 1) / shf
	local z = rv1[3] - ((rv1[3] * shf) % 1) / shf
	return {x, y, z}
end)

// min/max based on vector length - returns shortest/longest vector
registerFunction("min", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] ) ^ 0.5
	if length1 < length2 then return rv1 else return rv2 end
end)

registerFunction("max", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] ) ^ 0.5
	if length1 > length2 then return rv1 else return rv2 end
end)

// component-wise min/max
registerFunction("maxVec", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y, z
	if rv1[1] > rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] > rv2[2] then y = rv1[2] else y = rv2[2] end
    if rv1[3] > rv2[3] then z = rv1[3] else z = rv2[3] end
    return {x, y, z}
end)

registerFunction("minVec", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y, z
	if rv1[1] < rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] < rv2[2] then y = rv1[2] else y = rv2[2] end
    if rv1[3] < rv2[3] then z = rv1[3] else z = rv2[3] end
    return {x, y, z}
end)

// Performs modulo on x,y,z separately
registerFunction("mod", "vn", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z
	if rv1[1] >= 0 then
		x = rv1[1] % rv2
	else x = rv1[1] % -rv2 end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2
	else z = rv1[3] % -rv2 end
	return {x, y, z}
end)

// Modulo where divisors are defined as a vector
registerFunction("mod", "vv", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z
	if rv1[1] >= 0 then
		x = rv1[1] % rv2[1]
	else x = rv1[1] % -rv2[1] end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2[3]
	else z = rv1[3] % -rv2[3] end
	return {x, y, z}
end)

// Clamp according to limits defined by two min/max vectors
registerFunction("clamp", "vvv", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local x,y,z

	if rv1[1] < rv2[1] then x = rv2[1]
	elseif rv1[1] > rv3[1] then x = rv3[1]
	else x = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	if rv1[3] < rv2[3] then z = rv2[3]
	elseif rv1[3] > rv3[3] then z = rv3[3]
	else z = rv1[3] end

	return {x, y, z}
end)

// Mix two vectors by a given proportion (between 0 and 1)
registerFunction("mix", "vvn", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local n
	if rv3 < 0 then n = 0
	elseif rv3 > 1 then n = 1
	else n = rv3 end
	local x = rv1[1] * n + rv2[1] * (1-n)
	local y = rv1[2] * n + rv2[2] * (1-n)
	local z = rv1[3] * n + rv2[3] * (1-n)
	return {x, y, z}
end)

// Circular shift function: shiftr( x,y,z ) = ( z,x,y )
registerFunction("shiftR", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[3], rv1[1], rv1[2]}
end)

registerFunction("shiftL", "v", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[2], rv1[3], rv1[1]}
end)

// Returns 1 if the vector lies between (or is equal to) the min/max vectors
registerFunction("inrange", "vvv", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	if rv1[1] < rv2[1] then return 0 end
	if rv1[2] < rv2[2] then return 0 end
	if rv1[3] < rv2[3] then return 0 end

	if rv1[1] > rv3[1] then return 0 end
	if rv1[2] > rv3[2] then return 0 end
	if rv1[3] > rv3[3] then return 0 end

	return 1
end)

/******************************************************************************/

registerFunction("toAngle", "v:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local angle = Vector(rv1[1], rv1[2], rv1[3]):Angle()
	return { angle.p, angle.y, angle.r }
end)

/******************************************************************************/

local contents = {}
for k,v in pairs(_E) do
	if (k:sub(1,9) == "CONTENTS_") then
		contents[v] = k:sub(10):lower()
	end
end

local contents_numerical_cache = {}

local function getcontents( n )
	if n == 0 then return "empty" end -- = CONTENTS_EMPTY

	if (contents_numerical_cache[n]) then
		return contents_numerical_cache[n]
	else
		local ret, s = "", math.IntToBin(n):reverse()
		local w = s:find("1")
		local skipfirstcomma = true
		while w do
			if (skipfirstcomma) then
				ret = ret .. contents[2^(w-1)]
				skipfirstcomma = false
			else
				ret = ret .. "," .. contents[2^(w-1)]
			end
			w = s:find("1",w+1)
		end
		contents_numerical_cache[n] = ret
		return ret
	end
end

__e2setcost( 50 )

e2function number pointHasContent( vector point, string has )
	local finds, found = {}, 0
	has:gsub(" ","_"):lower():gsub("([^,]+),?", function(m) finds[#finds+1] = m end)

	local cont = getcontents( util.PointContents( Vector(point[1],point[2],point[3]) ) )

	for i=1,#finds do
		if (cont:find(finds[i],1,true)) then return 1 end
	end

	return 0
end

__e2setcost( 35 )

e2function string pointContents( vector point )
	return getcontents( util.PointContents( Vector(point[1],point[2],point[3]) ) )
end

/******************************************************************************/

__e2setcost( 10 )


registerFunction("isInWorld", "v:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if util.IsInWorld(Vector(rv1[1], rv1[2], rv1[3])) then return 1 else return 0 end
end)

__e2setcost( 5 )

--- Gets the vector nicely formatted as a string "[X,Y,Z]"
e2function string toString(vector v)
	return "[" .. tostring(v[1]) .. "," .. tostring(v[2]) .. "," .. tostring(v[3]) .. "]"
end

--- Gets the vector nicely formatted as a string "[X,Y,Z]"
e2function string vector:toString() = e2function string toString(vector v)

__e2setcost(nil)
