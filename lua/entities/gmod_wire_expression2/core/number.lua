-- these upvalues (locals in an enclosing scope) are faster to access than globals.
local math   = math
local abs    = math.abs
local random = math.random
local pi     = math.pi
local inf    = math.huge
local nan    = 0 / 0

local exp    = math.exp
local frexp  = math.frexp
local log    = math.log
local log10  = math.log10
local sqrt   = math.sqrt

local floor  = math.floor
local ceil   = math.ceil

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
	nil,
	function(v)
		return not isnumber(v)
	end
)

E2Lib.registerConstant("PI", pi)
E2Lib.registerConstant("INF", inf)
E2Lib.registerConstant("E", exp(1))
E2Lib.registerConstant("PHI", (1+sqrt(5))/2)
E2Lib.registerConstant("TAU", math.pi * 2)

--[[************************************************************************]]--

__e2setcost(1.5)

--[[************************************************************************]]--

e2function number operator>=(number lhs, number rhs)
	return lhs >= rhs and 1 or 0
end

e2function number operator<=(number lhs, number rhs)
	return lhs <= rhs and 1 or 0
end

e2function number operator>(number lhs, number rhs)
	return lhs > rhs and 1 or 0
end

e2function number operator<(number lhs, number rhs)
	return lhs < rhs and 1 or 0
end

--[[************************************************************************]]--

__e2setcost(0.5) -- approximation

e2function number operator_neg(number n)
	return -n
end

__e2setcost(1)

e2function number operator+(number lhs, number rhs)
	return lhs + rhs
end

e2function number operator-(number lhs, number rhs)
	return lhs - rhs
end

e2function number operator*(number lhs, number rhs)
	return lhs * rhs
end

e2function number operator/(number lhs, number rhs)
	return lhs / rhs
end

e2function number operator^(number lhs, number rhs)
	return lhs ^ rhs
end

e2function number operator%(number lhs, number rhs)
	return lhs % rhs
end

--[[************************************************************************]]--

__e2setcost(1)

local min, max = math.min, math.max

[nodiscard]
e2function number min(number a, number b)
	return min(a, b)
end

[nodiscard]
e2function number min(number a, number b, number c)
	return min(a, b, c)
end

[nodiscard]
e2function number min(number a, number b, number c, number d)
	return min(a, b, c, d)
end

[nodiscard]
e2function number max(number a, number b)
	return max(a, b)
end

[nodiscard]
e2function number max(number a, number b, number c)
	return max(a, b, c)
end

[nodiscard]
e2function number max(number a, number b, number c, number d)
	return max(a, b, c, d)
end

--[[************************************************************************]]--

__e2setcost(2) -- approximation

--- Returns true (1) if given value is a finite number; otherwise false (0).
[nodiscard]
e2function number isfinite(number value)
	return (value > -inf and value < inf) and 1 or 0
end

--- Returns 1 if given value is a positive infinity or -1 if given value is a negative infinity; otherwise 0.
[nodiscard]
e2function number isinf(number value)
	if value == inf then return 1 end
	if value == -inf then return -1 end
	return 0
end

--- Returns true (1) if given value is not a number (NaN); otherwise false (0).
[nodiscard]
e2function number isnan(number value)
	return (value ~= value) and 1 or 0
end

--[[************************************************************************]]--

__e2setcost(2)

[nodiscard]
e2function number remap(number value, number in_min, number in_max, number out_min, number out_max)
	return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

__e2setcost(2) -- approximation

[nodiscard]
e2function number abs(number n)
	return abs(n)
end

--- rounds towards +inf
[nodiscard]
e2function number ceil(number n)
	return ceil(n)
end

[nodiscard]
e2function number ceil(number value, number decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return ceil(value * shf) / shf
end

--- rounds towards -inf
[nodiscard]
e2function number floor(number n)
	return floor(n)
end

[nodiscard]
e2function number floor(number value, number decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return floor(value * shf) / shf
end

--- rounds to the nearest integer
[nodiscard]
e2function number round(number n)
	return floor(n + 0.5)
end

[nodiscard]
e2function number round(number value, number decimals)
	local shf = 10 ^ floor(decimals + 0.5)
	return floor(value * shf + 0.5) / shf
end

--- rounds towards zero
[nodiscard]
e2function number int(number n)
	return n >= 0
		and floor(n)
		or ceil(n)
end

--- returns the fractional part. (frac(-1.5) == 0.5 & frac(3.2) == 0.2)
[nodiscard]
e2function number frac(number n)
	return n >= 0
		and n % 1
		or n % -1
end

[nodiscard]
e2function number mod(number lhs, number rhs)
	return lhs >= 0
		and lhs % rhs
		or lhs % -rhs
end

-- TODO: change to a more suitable name? (cyclic modulo?)
--       add helpers for wrap90 wrap180, wrap90r wrap180r? or pointless?
--       wrap90(Pitch), wrap(Pitch, 90)
--       should be added...

[nodiscard]
e2function number wrap(number lhs, number rhs)
	return (lhs + rhs) % (rhs * 2) - rhs
end

[nodiscard]
e2function number clamp(number n, number low, number high)
	return min( max(n, low), high )
end

[nodiscard]
e2function number inrange(number value, number min, number max)
	return (min <= value and value <= max) and 1 or 0
end

[nodiscard]
e2function number lerp(number from, number to, number fraction)
	return Lerp(fraction, from, to)
end

[nodiscard]
e2function number sign(number n)
	return n > 0 and 1 or (n < 0 and -1 or 0)
end

--[[************************************************************************]]--

__e2setcost(2) -- approximation

[nodiscard]
e2function number random()
	return random()
end

[nodiscard]
e2function number random(number n)
	return random() * n
end

[nodiscard]
e2function number random(number low, number high)
	return low + random() * (high - low)
end

[nodiscard]
e2function number randint(number n)
	return random(n)
end

-- WTF. Who implemented it like this? Why. Shame on you.
[nodiscard]
e2function number randint(number a, number b)
	if a > b then
		return random(b, a)
	else
		return random(a, b)
	end
end

--[[************************************************************************]]--

__e2setcost(10)

[nodiscard]
e2function number factorial(number n)
	if n < 0 then return nan end
	if n > 170 then return inf end

	local res = 1
	for i = 2, n do res = res * i end
	return res
end

__e2setcost(2) -- approximation

[nodiscard]
e2function number sqrt(number n)
	return sqrt(n)
end

[nodiscard]
e2function number cbrt(number n)
	return n ^ (1 / 3)
end

[nodiscard]
e2function number root(number n, number pow)
	return n ^ (1 / pow)
end

local const_e = exp(1)
[nodiscard, deprecated = "Use the constant E instead"]
e2function number e()
	return const_e
end

[nodiscard]
e2function number exp(number n)
	return exp(n)
end

[nodiscard]
e2function vector2 frexp(number n)
	return { frexp(n) }
end

[nodiscard]
e2function number ln(number n)
	return log(n)
end

local const_log2 = log(2)

[nodiscard]
e2function number log2(number n)
	return log(n) / const_log2
end

[nodiscard]
e2function number log10(number n)
	return log10(n)
end

[nodiscard]
e2function number log(number a, number b)
	return log(a) / log(b)
end

--[[************************************************************************]]--

__e2setcost(1) -- approximation

local deg = math.deg
local rad = math.rad

[nodiscard, deprecated = "Use the constant INF instead"]
e2function number inf()
	return inf
end

[nodiscard, deprecated = "Use the constant PI instead"]
e2function number pi()
	return pi
end

[nodiscard]
e2function number toRad(number n)
	return rad(n)
end

[nodiscard]
e2function number toDeg(number n)
	return deg(n)
end

__e2setcost(2)

[nodiscard]
e2function number acos(number n)
	return deg(acos(n))
end

[nodiscard]
e2function number asin(number n)
	return deg(asin(n))
end

[nodiscard]
e2function number atan(number n)
	return deg(atan(n))
end

[nodiscard, deprecated = "Use atan2 instead which returns radians"]
e2function number atan(number x, number y)
	return deg(atan2(x, y))
end

[nodiscard]
e2function number atan2(number x, number y)
	return atan2(x, y)
end

[nodiscard]
e2function number cos(number n)
	return cos(rad(n))
end

[nodiscard]
e2function number sec(number n)
	return 1 / cos(rad(n))
end

[nodiscard]
e2function number sin(number n)
	return sin(rad(n))
end

[nodiscard]
e2function number csc(number n)
	return 1 / sin(rad(n))
end

[nodiscard]
e2function number tan(number n)
	return tan(rad(n))
end

[nodiscard]
e2function number cot(number n)
	return 1 / tan(rad(n))
end

__e2setcost(1.5) -- These don't convert degrees to radians, so cheaper.

[nodiscard]
e2function number cosh(number n)
	return cosh(n)
end

[nodiscard]
e2function number sech(number n)
	return 1/cosh(n)
end

[nodiscard]
e2function number sinh(number n)
	return sinh(n)
end

[nodiscard]
e2function number csch(number n)
	return 1/sinh(n)
end

[nodiscard]
e2function number tanh(number n)
	return tanh(n)
end

[nodiscard]
e2function number coth(number n)
	return 1/tanh(n)
end

[nodiscard]
e2function number acosr(number n)
	return acos(n)
end

[nodiscard]
e2function number asinr(number n)
	return asin(n)
end

[nodiscard]
e2function number atanr(number n)
	return atan(n)
end

[nodiscard]
e2function number cosr(number n)
	return cos(n)
end

[nodiscard]
e2function number secr(number n)
	return 1/cos(n)
end

[nodiscard]
e2function number sinr(number n)
	return sin(n)
end

[nodiscard]
e2function number cscr(number n)
	return 1/sin(n)
end

[nodiscard]
e2function number tanr(number n)
	return tan(n)
end

[nodiscard]
e2function number cotr(number n)
	return 1/tan(n)
end

[nodiscard]
e2function number coshr(number n)
	return cosh(n)
end

[nodiscard]
e2function number sechr(number n)
	return 1/cosh(n)
end

[nodiscard]
e2function number sinhr(number n)
	return sinh(n)
end

[nodiscard]
e2function number cschr(number n)
	return 1/sinh(n)
end

[nodiscard]
e2function number tanhr(number n)
	return tanh(n)
end

[nodiscard]
e2function number cothr(number n)
	return 1/tanh(n)
end

--[[************************************************************************]]--

__e2setcost(5)

[nodiscard]
e2function string toString(number number)
	return tostring(number)
end

[nodiscard]
e2function string number:toString()
	return tostring(this)
end

__e2setcost(10)

local CHARS = string.Split("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", "")

local function tobase(number, base, self)
	if base < 2 or base > 36 or number == 0 then return "0" end
	if base == 10 then return tostring(number) end

	local out, loops, d = {}, ceil(log(number) / log(base)), 0
	if loops == inf then return "inf" end

	for i = loops, 1, -1 do
		number, d = math.floor(number / base), number % base + 1
		out[i] = CHARS[d]
	end

	self.prf = self.prf + loops * 4

	return table.concat(out, "", 1, loops)
end

[nodiscard]
e2function string toString(number number, number base)
	return tobase(number, base, self)
end

[nodiscard]
e2function string number:toString(number base)
	return tobase(this, base, self)
end
