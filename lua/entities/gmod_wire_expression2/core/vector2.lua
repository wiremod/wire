/******************************************************************************\
  2D Vector support
\******************************************************************************/

local delta  = wire_expression2_delta

local floor = math.floor
local ceil = math.ceil
local random = math.random
local pi = math.pi

/******************************************************************************/

registerType("vector2", "xv2", { 0, 0 },
	function(self, input) return { input[1], input[2] } end,
	nil,
	function(retval)
		if !istable(retval) then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 2 then error("Return value does not have exactly 2 entries!",0) end
	end,
	function(v)
		return !istable(v) or #v ~= 2
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("vec2", "", "xv2", function(self, args)
	return { 0, 0 }
end)

__e2setcost(2)

registerFunction("vec2", "nn", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1, rv2 }
end)

registerFunction("vec2", "n", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1, rv1 }
end)

registerFunction("vec2", "v", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2] }
end)

registerFunction("vec2", "xv4", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2] }
end)

/******************************************************************************/

registerOperator("ass", "xv2", "xv2", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "xv2", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xv2xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xv2xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "xv2", "xv2", function(self, args)
	local op1, scope = args[2], args[3]
	local rv1, rv2 = self.Scopes[scope][op1], self.Scopes[scope]["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2] }
end)

registerOperator("neg", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2] }
end)

registerOperator("add", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2] }
end)

registerOperator("sub", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2] }
end)

registerOperator("mul", "nxv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2] }
end)

registerOperator("mul", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2 }
end)

registerOperator("mul", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2] }
end)

registerOperator("div", "nxv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2] }
end)

registerOperator("div", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2 }
end)

registerOperator("div", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2] }
end)

e2function number vector2:operator[](index)
	return this[floor(math.Clamp(index, 1, 2) + 0.5)]
end

e2function number vector2:operator[](index, value)
	this[floor(math.Clamp(index, 1, 2) + 0.5)] = value
	return value
end

/******************************************************************************/

__e2setcost(3)

registerFunction("length", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
end)

registerFunction("length2", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2]
end)

registerFunction("distance", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2 = rv1[1] - rv2[1], rv1[2] - rv2[2]
	return (rvd1 * rvd1 + rvd2 * rvd2 ) ^ 0.5
end)

registerFunction("distance2", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2 = rv1[1] - rv2[1], rv1[2] - rv2[2]
	return rvd1 * rvd1 + rvd2 * rvd2
end)

registerFunction("normalized", "xv2:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	if len > delta then
		return { rv1[1] / len, rv1[2] / len }
	else
		return { 0, 0 }
	end
end)

registerFunction("dot", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2]
end)

registerFunction("cross", "xv2:xv2", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[2] - rv1[2] * rv2[1]
end)

-- returns the outer product (tensor product) of two vectors
registerFunction("outerProduct", "xv2:xv2", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv1[1], rv1[1] * rv2[2],
			 rv1[2] * rv1[1], rv1[2] * rv2[2] }
end)

registerFunction("rotate", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local a = rv2 * pi / 180
	local x = math.cos(a) * rv1[1] - math.sin(a) * rv1[2]
	local y = math.sin(a) * rv1[1] + math.cos(a) * rv1[2]
	return { x, y }
end)

registerFunction("positive", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x, y
	if rv1[1] >= 0 then x = rv1[1] else x = -rv1[1] end
	if rv1[2] >= 0 then y = rv1[2] else y = -rv1[2] end
	return { x, y }
end)

__e2setcost(2)

// Convert the magnitude of the vector to radians
e2function vector2 toRad(vector2 xv2)
	return {xv2[1] * pi / 180, xv2[2] * pi / 180}
end

// Convert the magnitude of the vector to degrees
e2function vector2 toDeg(vector2 xv2)
	return {xv2[1] * 180 / pi, xv2[2] * 180 / pi}
end

/******************************************************************************/

__e2setcost(3)

--- Returns a vector in the same direction as <Input>, with a length clamped between <Min> (min) and <Max> (max)
e2function vector2 clamp(vector2 Input, Min, Max)
	if Min < 0 then Min = 0 end
	local x,y = Input[1], Input[2]
	local length = x*x+y*y
	if length < Min*Min then
		length = Min*(length ^ -0.5) -- Min*(length ^ -0.5) <=> Min/sqrt(length)
	elseif length > Max*Max then
		length = Max*(length ^ -0.5) -- Max*(length ^ -0.5) <=> Max/sqrt(length)
	else
		return Input
	end

	return { x*length, y*length }
end

/******************************************************************************/

__e2setcost(1)

registerFunction("x", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

// SET methods that returns vectors - you shouldn't need these for 2D vectors, but I've added them anyway for consistency
// NOTE: does not change the original vector!
registerFunction("setX", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2, rv1[2] }
end)

registerFunction("setY", "xv2:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2 }
end)

/******************************************************************************/

__e2setcost(4)

e2function vector2 round(vector2 rv1)
	return {
		floor(rv1[1] + 0.5), 
		floor(rv1[2] + 0.5)
	}
end

e2function vector2 round(vector2 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf + 0.5) / shf, 
		floor(rv1[2] * shf + 0.5) / shf
	}
end

e2function vector2 ceil( vector2 rv1 )
	return {
		ceil(rv1[1]), 
		ceil(rv1[2])
	}
end

e2function vector2 ceil(vector2 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		ceil(rv1[1] * shf) / shf, 
		ceil(rv1[2] * shf) / shf
	}
end

e2function vector2 floor(vector2 rv1)
	return {
		floor(rv1[1]), 
		floor(rv1[2])
	}
end

e2function vector2 floor(vector2 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf) / shf, 
		floor(rv1[2] * shf) / shf
	}
end

// min/max based on vector length - returns shortest/longest vector
registerFunction("min", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] ) ^ 0.5
	if length1 < length2 then return rv1 else return rv2 end
end)

registerFunction("max", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] ) ^ 0.5
	if length1 > length2 then return rv1 else return rv2 end
end)

// component-wise min/max
registerFunction("maxVec", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y
	if rv1[1] > rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] > rv2[2] then y = rv1[2] else y = rv2[2] end
    return {x, y}
end)

registerFunction("minVec", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y
	if rv1[1] < rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] < rv2[2] then y = rv1[2] else y = rv2[2] end
    return {x, y}
end)

// Performs modulo on x,y separately
registerFunction("mod", "xv2n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x, y

	if rv1[1] >= 0 then
		x = rv1[1] % rv2
	else x = rv1[1] % -rv2 end

	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end

	return { x, y }
end)

// Modulo where divisors are defined as a vector
registerFunction("mod", "xv2xv2", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x, y

	if rv1[1] >= 0 then
		x = rv1[1] % rv2[1]
	else x = rv1[1] % -rv2[1] end

	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end

	return { x, y }
end)

// Clamp according to limits defined by two min/max vectors
registerFunction("clamp", "xv2xv2xv2", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local x, y

	if rv1[1] < rv2[1] then x = rv2[1]
	elseif rv1[1] > rv3[1] then x = rv3[1]
	else x = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	return { x, y }
end)

// Mix two vectors by a given proportion (between 0 and 1)
registerFunction("mix", "xv2xv2n", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	local x = rv1[1] * rv3 + rv2[1] * (1-rv3)
	local y = rv1[2] * rv3 + rv2[2] * (1-rv3)
	return { x, y }
end)

e2function vector2 bezier(vector2 startVec, vector2 control, vector2 endVec, ratio)
	return {
		(1-ratio)^2 * startVec[1] + (2 * (1-ratio) * ratio * control[1]) + ratio^2 * endVec[1],
		(1-ratio)^2 * startVec[2] + (2 * (1-ratio) * ratio * control[2]) + ratio^2 * endVec[2]
	}
end

__e2setcost(2)

// swap x/y
registerFunction("shift", "xv2", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[2], rv1[1] }
end)

// Returns 1 if the vector lies between (or is equal to) the min/max vectors
registerFunction("inrange", "xv2xv2xv2", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	if rv1[1] < rv2[1] then return 0 end
	if rv1[2] < rv2[2] then return 0 end
	if rv1[1] > rv3[1] then return 0 end
	if rv1[2] > rv3[2] then return 0 end

	return 1
end)

/******************************************************************************/

registerFunction("toAngle", "xv2:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local angle = math.atan2( rv1[2], rv1[1] ) * 180 / pi
	--if (angle < 0) then angle = angle + 180 end
	return angle
end)

__e2setcost(5)

e2function string toString(vector2 v)
	return ("[%s,%s]"):format(v[1],v[2])
end

e2function string vector2:toString() = e2function string toString(vector2 v)

-- register a formatter for the debugger
WireLib.registerDebuggerFormat("VECTOR2", function(value)
	return string.format("(%.2f, %.2f)", value[1], value[2])
end)

/******************************************************************************/

__e2setcost(5)

-- Returns a random vector2 between -1 and 1
e2function vector2 randvec2()
	local randomang = random() * pi * 2
	return { math.cos( randomang ), math.sin( randomang ) }
end

-- Returns a random vector2 between min and max
e2function vector2 randvec2(min,max)
	return { min+random()*(max-min), min+random()*(max-min) }
end

-- Returns a random vector2 between vec2 min and vec2 max
e2function vector2 randvec2( vector2 min, vector2 max )
	return { min[1]+random()*(max[1]-min[1]), min[2]+random()*(max[2]-min[2]) }
end

/******************************************************************************\
  4D Vector support
\******************************************************************************/

//NOTE: These are purely cartesian 4D vectors, so "w" denotes the 4th coordinate rather than a scaling factor as with an homogeneous coordinate system

/******************************************************************************/

registerType("vector4", "xv4", { 0, 0, 0, 0 },
	function(self, input) return { input[1], input[2], input[3], input[4] } end,
	nil,
	function(retval)
		if !istable(retval) then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 4 then error("Return value does not have exactly 4 entries!",0) end
	end,
	function(v)
		return !istable(v) or #v ~= 4
	end
)

/******************************************************************************/

__e2setcost(1) -- approximated

registerFunction("vec4", "", "xv4", function(self, args)
	return { 0, 0, 0, 0 }
end)

__e2setcost(4)

registerFunction("vec4", "n", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1, rv1, rv1, rv1 }
end)

registerFunction("vec4", "nnnn", "xv4", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	return { rv1, rv2, rv3, rv4 }
end)

registerFunction("vec4", "xv2", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], 0, 0 }
end)

registerFunction("vec4", "xv2nn", "xv4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return { rv1[1], rv1[2], rv2, rv3 }
end)

registerFunction("vec4", "xv2xv2", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2[1], rv2[2] }
end)

registerFunction("vec4", "v", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { rv1[1], rv1[2], rv1[3], 0 }
end)

registerFunction("vec4", "vn", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv1[3], rv2 }
end)

/******************************************************************************/

registerOperator("ass", "xv4", "xv4", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "xv4", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1[1] > delta || -rv1[1] > delta ||
	   rv1[2] > delta || -rv1[2] > delta ||
	   rv1[3] > delta || -rv1[3] > delta ||
	   rv1[4] > delta || -rv1[4] > delta
	   then return 1 else return 0 end
end)

registerOperator("eq", "xv4xv4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta &&
	   rv1[4] - rv2[4] <= delta && rv2[4] - rv1[4] <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "xv4xv4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta ||
	   rv1[4] - rv2[4] > delta || rv2[4] - rv1[4] > delta
	   then return 1 else return 0 end
end)

/******************************************************************************/

registerOperator("dlt", "xv4", "xv4", function(self, args)
	local op1, scope = args[2], args[3]
	local rv1, rv2 = self.Scopes[scope][op1], self.Scopes[scope]["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("neg", "xv4", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return { -rv1[1], -rv1[2], -rv1[3], -rv[4] }
end)

registerOperator("add", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3], rv1[4] + rv2[4] }
end)

registerOperator("sub", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4] }
end)

registerOperator("mul", "nxv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3], rv1 * rv2[4] }
end)

registerOperator("mul", "xv4n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2, rv1[4] * rv2 }
end)

registerOperator("mul", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3], rv1[4] * rv2[4] }
end)

registerOperator("div", "nxv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3], rv1 / rv2[4] }
end)

registerOperator("div", "xv4n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2, rv1[4] / rv2 }
end)

registerOperator("div", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3], rv1[4] / rv2[4] }
end)

e2function number vector4:operator[](index)
	return this[floor(math.Clamp(index, 1, 4) + 0.5)]
end

e2function number vector4:operator[](index, value)
	this[floor(math.Clamp(index, 1, 4) + 0.5)] = value
	return value
end

/******************************************************************************/

__e2setcost(7)

registerFunction("length", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] + rv1[4] * rv1[4]) ^ 0.5
end)

registerFunction("length2", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] + rv1[4] * rv1[4]
end)

registerFunction("distance", "xv4:xv4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3, rvd4 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4]
	return (rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3 + rvd4 * rvd4) ^ 0.5
end)

registerFunction("distance2", "xv4:xv4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local rvd1, rvd2, rvd3 = rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3], rv1[4] - rv2[4]
	return rvd1 * rvd1 + rvd2 * rvd2 + rvd3 * rvd3 + rvd4 * rvd4
end)

registerFunction("dot", "xv4:xv4", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1[1] * rv2[1] + rv1[2] * rv2[2] + rv1[3] * rv2[3] + rv1[4] * rv2[4]
end)

__e2setcost(15)

-- returns the outer product (tensor product) of two vectors
registerFunction("outerProduct", "xv4:xv4", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1] * rv1[1], rv1[1] * rv2[2], rv1[1] * rv2[3], rv1[1] * rv2[4],
			 rv1[2] * rv1[1], rv1[2] * rv2[2], rv1[2] * rv2[3], rv1[2] * rv2[4],
			 rv1[3] * rv1[1], rv1[3] * rv2[2], rv1[3] * rv2[3], rv1[3] * rv2[4],
			 rv1[4] * rv1[1], rv1[4] * rv2[2], rv1[4] * rv2[3], rv1[4] * rv2[4] }
end)

__e2setcost(7)

registerFunction("normalized", "xv4:", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local len = (rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] + rv1[4] * rv1[4]) ^ 0.5
	if len > delta then
		return { rv1[1] / len, rv1[2] / len, rv1[3] / len, rv1[4] / len }
	else
		return { 0, 0, 0, 0 }
	end
end)

__e2setcost(3)

registerFunction("dehomogenized", "xv4:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local w = rv1[4]
	if w == 0 then return { rv1[1], rv1[2], rv1[3] } end
	return { rv1[1]/w, rv1[2]/w, rv1[3]/w }
end)

__e2setcost(4)

registerFunction("positive", "xv4", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local x, y, z, w
	if rv1[1] >= 0 then x = rv1[1] else x = -rv1[1] end
	if rv1[2] >= 0 then y = rv1[2] else y = -rv1[2] end
	if rv1[3] >= 0 then z = rv1[3] else z = -rv1[3] end
	if rv1[4] >= 0 then w = rv1[4] else w = -rv1[4] end
	return { x, y, z, w }
end)

/******************************************************************************/

__e2setcost(2)

registerFunction("x", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[1]
end)

registerFunction("y", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[2]
end)

registerFunction("z", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[3]
end)

registerFunction("w", "xv4:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1[4]
end)

__e2setcost(3)

// SET methods that returns vectors
// NOTE: does not change the original vector!
registerFunction("setX", "xv4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv2, rv1[2], rv1[3], rv1[4] }
end)

registerFunction("setY", "xv4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv2, rv1[3], rv1[4] }
end)

registerFunction("setZ", "xv4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv2, rv1[4] }
end)

registerFunction("setW", "xv4:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return { rv1[1], rv1[2], rv1[3], rv2 }
end)

/******************************************************************************/

__e2setcost(8)

e2function vector4 round(vector4 rv1)
	return {
		floor(rv1[1] + 0.5),
		floor(rv1[2] + 0.5),
		floor(rv1[3] + 0.5),
		floor(rv1[4] + 0.5)
	}
end

e2function vector4 round(vector4 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf + 0.5) / shf, 
		floor(rv1[2] * shf + 0.5) / shf,
		floor(rv1[3] * shf + 0.5) / shf, 
		floor(rv1[4] * shf + 0.5) / shf
	}
end

e2function vector4 ceil( vector4 rv1 )
	return {
		ceil(rv1[1]),
		ceil(rv1[2]),
		ceil(rv1[3]),
		ceil(rv1[4]),
	}
end

e2function vector4 ceil(vector4 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		ceil(rv1[1] * shf) / shf,
		ceil(rv1[2] * shf) / shf,
		ceil(rv1[3] * shf) / shf,
		ceil(rv1[4] * shf) / shf
	}
end

e2function vector4 floor(vector4 rv1)
	return {
		floor(rv1[1]),
		floor(rv1[2]),
		floor(rv1[3]),
		floor(rv1[4])
	}
end

e2function vector4 floor(vector4 rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf) / shf,
		floor(rv1[2] * shf) / shf,
		floor(rv1[3] * shf) / shf,
		floor(rv1[4] * shf) / shf
	}
end

__e2setcost(13)

// min/max based on vector length - returns shortest/longest vector
registerFunction("min", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] + rv1[4] * rv1[4] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] + rv2[4] * rv2[4] ) ^ 0.5
	if length1 < length2 then return rv1 else return rv2 end
end)

registerFunction("max", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local length1 = ( rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3] + rv1[4] * rv1[4] ) ^ 0.5
	local length2 = ( rv2[1] * rv2[1] + rv2[2] * rv2[2] + rv2[3] * rv2[3] + rv2[4] * rv2[4] ) ^ 0.5
	if length1 > length2 then return rv1 else return rv2 end
end)

// component-wise min/max
registerFunction("maxVec", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y, z, w
	if rv1[1] > rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] > rv2[2] then y = rv1[2] else y = rv2[2] end
	if rv1[3] > rv2[3] then z = rv1[3] else z = rv2[3] end
    if rv1[4] > rv2[4] then w = rv1[4] else w = rv2[4] end
    return {x, y, z, w}
end)

registerFunction("minVec", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
    local x, y, z, w
	if rv1[1] < rv2[1] then x = rv1[1] else x = rv2[1] end
    if rv1[2] < rv2[2] then y = rv1[2] else y = rv2[2] end
	if rv1[3] < rv2[3] then z = rv1[3] else z = rv2[3] end
    if rv1[4] < rv2[4] then w = rv1[4] else w = rv2[4] end
    return {x, y, z, w}
end)

// Performs modulo on x,y,z separately
registerFunction("mod", "xv4n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z,w
	if rv1[1] >= 0 then
		x = rv1[1] % rv2
	else x = rv1[1] % -rv2 end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2
	else z = rv1[3] % -rv2 end
	if rv1[4] >= 0 then
		w = rv1[4] % rv2
	else w = rv1[4] % -rv2 end
	return {x, y, z, w}
end)

// Modulo where divisors are defined as a vector
registerFunction("mod", "xv4xv4", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local x,y,z,w
	if rv1[1] >= 0 then
		x = rv1[1] % rv2[1]
	else x = rv1[1] % -rv2[1] end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	if rv1[3] >= 0 then
		z = rv1[3] % rv2[3]
	else z = rv1[3] % -rv2[3] end
	if rv1[4] >= 0 then
		w = rv1[4] % rv2[3]
	else w = rv1[4] % -rv2[3] end
	return {x, y, z, w}
end)

// Clamp according to limits defined by two min/max vectors
registerFunction("clamp", "xv4xv4xv4", "xv4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local x,y,z,w

	if rv1[1] < rv2[1] then x = rv2[1]
	elseif rv1[1] > rv3[1] then x = rv3[1]
	else x = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	if rv1[3] < rv2[3] then z = rv2[3]
	elseif rv1[3] > rv3[3] then z = rv3[3]
	else z = rv1[3] end

	if rv1[4] < rv2[4] then w = rv2[4]
	elseif rv1[4] > rv3[4] then w = rv3[4]
	else w = rv1[4] end

	return {x, y, z, w}
end)

--- Returns a vector in the same direction as <Input>, with a length clamped between <Min> (min) and <Max> (max)
e2function vector4 clamp(vector4 Input, Min, Max)
	if Min < 0 then Min = 0 end
	local x,y,z,w = Input[1], Input[2], Input[3], Input[4]
	local length = x*x+y*y+z*z+w*w
	if length < Min*Min then
		length = Min*(length ^ -0.5) -- Min*(length ^ -0.5) <=> Min/sqrt(length)
	elseif length > Max*Max then
		length = Max*(length ^ -0.5) -- Max*(length ^ -0.5) <=> Max/sqrt(length)
	else
		return Input
	end

	return { x*length, y*length, z*length, w*length }
end

// Mix two vectors by a given proportion (between 0 and 1)
registerFunction("mix", "xv4xv4n", "xv4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	local x = rv1[1] * rv3 + rv2[1] * (1-rv3)
	local y = rv1[2] * rv3 + rv2[2] * (1-rv3)
	local z = rv1[3] * rv3 + rv2[3] * (1-rv3)
	local w = rv1[4] * rv3 + rv2[4] * (1-rv3)
	return {x, y, z, w}
end)

__e2setcost(4)

// Circular shift function: shiftR( x,y,z,w ) = ( w,x,y,z )
registerFunction("shiftR", "xv4", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[4], rv1[1], rv1[2], rv1[3]}
end)

registerFunction("shiftL", "xv4", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return {rv1[2], rv1[3], rv1[4], rv1[1]}
end)

// Returns 1 if the vector lies between (or is equal to) the min/max vectors
registerFunction("inrange", "xv4xv4xv4", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	if rv1[1] < rv2[1] then return 0 end
	if rv1[2] < rv2[2] then return 0 end
	if rv1[3] < rv2[3] then return 0 end
	if rv1[4] < rv2[4] then return 0 end

	if rv1[1] > rv3[1] then return 0 end
	if rv1[2] > rv3[2] then return 0 end
	if rv1[3] > rv3[3] then return 0 end
	if rv1[4] > rv3[4] then return 0 end

	return 1
end)

__e2setcost(5)

// Convert the magnitude of the vector to radians
e2function vector4 toRad(vector4 xv4)
	return {xv4[1] * pi / 180, xv4[2] * pi / 180, xv4[3] * pi / 180, xv4[4] * pi / 180}
end

// Convert the magnitude of the vector to degrees
e2function vector4 toDeg(vector4 xv4)
	return {xv4[1] * 180 / pi, xv4[2] * 180 / pi, xv4[3] * 180 / pi, xv4[4] * 180 / pi}
end

/******************************************************************************/

__e2setcost(7)

-- Returns a random vector4 between -1 and 1
e2function vector4 randvec4()
	local vec = { random()*2-1, random()*2-1, random()*2-1, random()*2-1 }
	local length = ( vec[1]^2+vec[2]^2+vec[3]^2+vec[4]^2 ) ^ 0.5 -- x ^ 0.5 <=> math.sqrt( x )
	return { vec[1] / length, vec[2] / length, vec[3] / length, vec[4] / length }
end

-- Returns a random vector4 between min and max
e2function vector4 randvec4(min,max)
	return { min+random()*(max-min), min+random()*(max-min), min+random()*(max-min), min+random()*(max-min) }
end

-- Returns a random vector4 between vec4 min and vec4 max
e2function vector4 randvec4( vector4 min, vector4 max )
	local minx, miny, minz, minw = min[1], min[2], min[3], min[4]
	return { minx+random()*(max[1]-minx), miny+random()*(max[2]-miny), minz+random()*(max[2]-minz), minw+random()*(max[2]-minw) }
end

/******************************************************************************/

e2function string toString(vector4 v)
	return ("[%s,%s,%s,%s]"):format(v[1],v[2],v[3],v[4])
end
e2function string vector4:toString() = e2function string toString(vector4 v)

-- register a formatter for the debugger
WireLib.registerDebuggerFormat("VECTOR4", function(value)
	return string.format("(%.2f, %.2f, %.2f, %.2f)", value[1], value[2], value[3], value[4])
end)
