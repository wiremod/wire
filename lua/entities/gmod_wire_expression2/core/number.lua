-- these upvalues (locals in an enclosing scope) are faster to access than globals.
local delta  = wire_expression2_delta

local math   = math
local random = math.random
local pi     = math.pi
local inf    = math.huge

local exp    = math.exp
local frexp  = math.frexp
local log    = math.log
local log10  = math.log10
local sqrt   = math.sqrt

local floor  = math.floor
local ceil   = math.ceil
local Round  = math.Round

local sin    = math.sin
local cos    = math.cos
local tan    = math.tan

local acos   = math.acos
local asin   = math.asin
local atan   = math.atan
local atan2  = math.atan2

local sinh   = math.sinh
local cosh   = math.cosh
local tanh   = math.tanh


--[[************************************************************************]]--
--  Numeric support
--[[************************************************************************]]--

registerType("normal", "n", 0,
	nil,
	nil,
	function(retval)
		if !isnumber(retval) then error("Return value is not a number, but a "..type(retval).."!",0) end
	end,
	function(v)
		return !isnumber(v)
	end
)

E2Lib.registerConstant("PI", pi)
E2Lib.registerConstant("E", exp(1))
E2Lib.registerConstant("PHI", (1+sqrt(5))/2)

--[[************************************************************************]]--

__e2setcost(2)

registerOperator("ass", "n", "n", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

__e2setcost(1.5)

registerOperator("inc", "n", "", function(self, args)
	local op1, scope = args[2], args[3]
	self.Scopes[scope][op1] = self.Scopes[scope][op1] + 1
	self.Scopes[scope].vclk[op1] = true
end)

registerOperator("dec", "n", "", function(self, args)
	local op1, scope = args[2], args[3]
	self.Scopes[scope][op1] = self.Scopes[scope][op1] - 1
	self.Scopes[scope].vclk[op1] = true
end)

--[[************************************************************************]]--

__e2setcost(1.5)

registerOperator("eq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd <= delta && -rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("neq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd > delta || -rvd > delta
	   then return 1 else return 0 end
end)

__e2setcost(1.25)

registerOperator("geq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if -rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("leq", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]

	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd <= delta
	   then return 1 else return 0 end
end)

registerOperator("gth", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if rvd > delta
	   then return 1 else return 0 end
end)

registerOperator("lth", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rvd      = op1[1](self, op1) - op2[1](self, op2)
	if -rvd > delta
	   then return 1 else return 0 end
end)

--[[************************************************************************]]--

__e2setcost(5)

registerOperator("dlt", "n", "n", function(self, args)
	local op1, scope = args[2], args[3]
	return self.Scopes[scope][op1] - self.Scopes[scope]["$" .. op1]
end)

__e2setcost(0.5) -- approximation

registerOperator("neg", "n", "n", function(self, args)
	local op1 = args[2]
	return -op1[1](self, op1)
end)

__e2setcost(1)

registerOperator("add", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) + op2[1](self, op2)
end)

registerOperator("sub", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) - op2[1](self, op2)
end)

registerOperator("mul", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) * op2[1](self, op2)
end)

registerOperator("div", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) / op2[1](self, op2)
end)

registerOperator("exp", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) ^ op2[1](self, op2)
end)

registerOperator("mod", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) % op2[1](self, op2)
end)

--[[************************************************************************]]--
-- TODO: select, average
-- TODO: is the shifting correct for rounding arbitrary decimals?

__e2setcost(1)

registerFunction("min", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 < rv2 then return rv1 else return rv2 end
end)

registerFunction("min", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local val
	if rv1 < rv2 then val = rv1 else val = rv2 end
	if rv3 < val then return rv3 else return val end
end)

registerFunction("min", "nnnn", "n", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local val
	if rv1 < rv2 then val = rv1 else val = rv2 end
	if rv3 < val then val = rv3 end
	if rv4 < val then return rv4 else return val end
end)

registerFunction("max", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 > rv2 then return rv1 else return rv2 end
end)

registerFunction("max", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	local val
	if rv1 > rv2 then val = rv1 else val = rv2 end
	if rv3 > val then return rv3 else return val end
end)

registerFunction("max", "nnnn", "n", function(self, args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3), op4[1](self, op4)
	local val
	if rv1 > rv2 then val = rv1 else val = rv2 end
	if rv3 > val then val = rv3 end
	if rv4 > val then return rv4 else return val end
end)

--[[************************************************************************]]--

__e2setcost(2) -- approximation

--- Returns true (1) if given value is a finite number; otherwise false (0).
e2function number isfinite(value)
	return (value > -inf and value < inf) and 1 or 0
end

--- Returns 1 if given value is a positive infinity or -1 if given value is a negative infinity; otherwise 0.
e2function number isinf(value)
	if value == inf then return 1 end
	if value == -inf then return -1 end
	return 0
end

--- Returns true (1) if given value is not a number (NaN); otherwise false (0).
e2function number isnan(value)
	return (value ~= value) and 1 or 0
end

--[[************************************************************************]]--

__e2setcost(2) -- approximation

e2function number abs(value)
	if value >= 0 then return value else return -value end
end

--- rounds towards +inf
e2function number ceil(rv1)
	return ceil(rv1)
end

e2function number ceil(value, decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return ceil(value * shf) / shf
end

--- rounds towards -inf
e2function number floor(rv1)
	return floor(rv1)
end

e2function number floor(value, decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return floor(value * shf) / shf
end

--- rounds to the nearest integer
e2function number round(rv1)
	return floor(rv1 + 0.5)
end

e2function number round(value, decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return floor(value * shf + 0.5) / shf
end

--- rounds towards zero
e2function number int(rv1)
	if rv1 >= 0 then return floor(rv1) else return ceil(rv1) end
end

--- returns the fractional part. (frac(-1.5) == 0.5 & frac(3.2) == 0.2)
e2function number frac(rv1)
	if rv1 >= 0 then return rv1 % 1 else return rv1 % -1 end
end

-- TODO: what happens with negative modulo?
registerFunction("mod", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 >= 0 then return rv1 % rv2 else return rv1 % -rv2 end
end)

-- TODO: change to a more suitable name? (cyclic modulo?)
--       add helpers for wrap90 wrap180, wrap90r wrap180r? or pointless?
--       wrap90(Pitch), wrap(Pitch, 90)
--       should be added...

registerFunction("wrap", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return (rv1 + rv2) % (rv2 * 2) - rv2
end)

registerFunction("clamp", "nnn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if rv1 < rv2 then return rv2 elseif rv1 > rv3 then return rv3 else return rv1 end
end)

--- Returns 1 if <value> is in the interval [<min>; <max>], 0 otherwise.
e2function number inrange(value, min, max)
	if value < min then return 0 end
	if value > max then return 0 end
	return 1
end

registerFunction("sign", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 > delta then return 1
	elseif rv1 < -delta then return -1
	else return 0 end
end)

--[[************************************************************************]]--

__e2setcost(2) -- approximation

registerFunction("random", "", "n", function(self, args)
	return random()
end)

registerFunction("random", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return random() * rv1
end)

registerFunction("random", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1 + random() * (rv2 - rv1)
end)

registerFunction("randint", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return random(rv1)
end)

registerFunction("randint", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local temp = rv1
	if (rv1 > rv2) then rv1 = rv2 rv2 = temp end
	return random(rv1, rv2)
end)

--[[************************************************************************]]--

__e2setcost(2) -- approximation

registerFunction("sqrt", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 ^ (1 / 2)
end)

registerFunction("cbrt", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 ^ (1 / 3)
end)

registerFunction("root", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1 ^ (1 / rv2)
end)

local const_e = exp(1)
registerFunction("e", "", "n", function(self, args)
	return const_e
end)

registerFunction("exp", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return exp(rv1)
end)

e2function vector2 frexp(x)
	local mantissa, exponent = frexp(x)
	return { mantissa, exponent }
end

registerFunction("ln", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return log(rv1)
end)

local const_log2 = log(2)
registerFunction("log2", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return log(rv1) / const_log2
end)

registerFunction("log10", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return log10(rv1)
end)

registerFunction("log", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return log(rv1) / log(rv2)
end)

--[[************************************************************************]]--

__e2setcost(2) -- approximation

local deg2rad = pi / 180
local rad2deg = 180 / pi

registerFunction("inf", "", "n", function(self, args)
	return inf
end)

registerFunction("pi", "", "n", function(self, args)
	return pi
end)

registerFunction("toRad", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 * deg2rad
end)

registerFunction("toDeg", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1 * rad2deg
end)

registerFunction("acos", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return acos(rv1) * rad2deg
end)

registerFunction("asin", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return asin(rv1) * rad2deg
end)

registerFunction("atan", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return atan(rv1) * rad2deg
end)

registerFunction("atan", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return atan2(rv1, rv2) * rad2deg
end)

registerFunction("cos", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return cos(rv1 * deg2rad)
end)

registerFunction("sec", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/cos(rv1 * deg2rad)
end)

registerFunction("sin", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return sin(rv1 * deg2rad)
end)

registerFunction("csc", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/sin(rv1 * deg2rad)
end)

registerFunction("tan", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return tan(rv1 * deg2rad)
end)

registerFunction("cot", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/tan(rv1 * deg2rad)
end)

registerFunction("cosh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return cosh(rv1)
end)

registerFunction("sech", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/cosh(rv1)
end)

registerFunction("sinh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return sinh(rv1)
end)

registerFunction("csch", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/sinh(rv1)
end)

registerFunction("tanh", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return tanh(rv1)
end)

registerFunction("coth", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/tanh(rv1)
end)

registerFunction("acosr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return acos(rv1)
end)

registerFunction("asinr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return asin(rv1)
end)

registerFunction("atanr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return atan(rv1)
end)

registerFunction("atanr", "nn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return atan2(rv1, rv2)
end)

registerFunction("cosr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return cos(rv1)
end)

registerFunction("secr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/cos(rv1)
end)

registerFunction("sinr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return sin(rv1)
end)

registerFunction("cscr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/sin(rv1)
end)

registerFunction("tanr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return tan(rv1)
end)

registerFunction("cotr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/tan(rv1)
end)

registerFunction("coshr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return cosh(rv1)
end)

registerFunction("sechr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/cosh(rv1)
end)

registerFunction("sinhr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return sinh(rv1)
end)

registerFunction("cschr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/sinh(rv1)
end)

registerFunction("tanhr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return tanh(rv1)
end)

registerFunction("cothr", "n", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return 1/tanh(rv1)
end)

--[[************************************************************************]]--

__e2setcost(15) -- approximation

e2function string toString(number number)
	return tostring(number)
end

e2function string number:toString()
	return tostring(this)
end

__e2setcost(25) -- approximation

local function tobase(number, base, self)
	local ret = ""
	if base < 2 or base > 36 or number == 0 then return "0" end
	if base == 10 then return tostring(number) end
	local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local loops = 0
	while number > 0 do
		loops = loops + 1
		number, d = math.floor(number/base),(number%base)+1
		ret = string.sub(chars,d,d)..ret
		if (loops > 32000) then break end
	end
	self.prf = self.prf + loops
	return ret
end

e2function string toString(number number, number base)
    return tobase(number, base, self)
end

e2function string number:toString(number base)
    return tobase(this, base, self)
end
