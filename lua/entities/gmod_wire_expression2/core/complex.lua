/******************************************************************************\
 Complex numbers support
\******************************************************************************/

-- faster access to some math library functions
local abs   = math.abs
local Round = math.Round
local sqrt  = math.sqrt
local exp   = math.exp
local log   = math.log
local sin   = math.sin
local cos   = math.cos
local sinh  = math.sinh
local cosh  = math.cosh
local acos  = math.acos
local atan2 = math.atan2

local function format(value)
	local dbginfo

	if abs(value[1]) < 0 then
		if abs(value[2]) < 0 then
			dbginfo = "0"
		else
			dbginfo = Round(value[2]*1000)/1000 .. "i"
		end
	else
		if value[2] > 0 then
			dbginfo = Round(value[1]*1000)/1000 .. "+" .. Round(value[2]*1000)/1000 .. "i"
		elseif abs(value[2]) <= 0 then
			dbginfo = Round(value[1]*1000)/1000
		elseif value[2] < 0 then
			dbginfo = Round(value[1]*1000)/1000 .. Round(value[2]*1000)/1000 .. "i"
		end
	end
	return dbginfo
end
WireLib.registerDebuggerFormat("COMPLEX", format)

/******************************************************************************/

__e2setcost(2)

registerType("complex", "c", { 0, 0 },
	function(self, input) return { input[1], input[2] } end,
	nil,
	nil,
	function(v)
		return !istable(v) or #v ~= 2
	end
)

/******************************************************************************/

__e2setcost(4)

local function cexp(x,y)
	return {exp(x)*cos(y), exp(x)*sin(y)}
end

local function clog(x,y)
        local r,i,l

        l = x*x+y*y

        if l < 0 then return {-1e+100, 0} end

        r = log(sqrt(l))

        local c,s
        c = x/sqrt(l)

        i = acos(c)
        if y<0 then i = -i end

        return {r, i}
end

local function cdiv(a,b)
	local l=b[1]*b[1]+b[2]*b[2]

	return {(a[1]*b[1]+a[2]*b[2])/l, (a[2]*b[1]-a[1]*b[2])/l}
end

/******************************************************************************/

__e2setcost(2)

e2function number operator_is(complex this)
	return (this[1] ~= 0 or this[2] ~= 0) and 1 or 0
end

e2function number operator==(complex lhs, complex rhs)
	return (lhs[1] == rhs[1]
		and lhs[2] == rhs[2])
		and 1 or 0
end

e2function number operator==(complex lhs, number rhs)
	return (lhs[1] == rhs
		and lhs[2] == 0)
		and 1 or 0
end

e2function number operator==(number lhs, complex rhs)
	return (lhs == rhs[1]
		and rhs[2] == 0)
		and 1 or 0
end

/******************************************************************************/

e2function complex operator_neg(complex z)
	return {-z[1], -z[2]}
end

e2function complex operator+(complex lhs, complex rhs)
	return {lhs[1]+rhs[1], lhs[2]+rhs[2]}
end

e2function complex operator+(number lhs, complex rhs)
	return {lhs+rhs[1], rhs[2]}
end

e2function complex operator+(complex lhs, number rhs)
	return {lhs[1]+rhs, lhs[2]}
end

e2function complex operator-(complex lhs, complex rhs)
	return {lhs[1]-rhs[1], lhs[2]-rhs[2]}
end

e2function complex operator-(number lhs, complex rhs)
	return {lhs-rhs[1], -rhs[2]}
end

e2function complex operator-(complex lhs, number rhs)
	return {lhs[1]-rhs, lhs[2]}
end

e2function complex operator*(complex lhs, complex rhs)
	return {lhs[1]*rhs[1]-lhs[2]*rhs[2], lhs[2]*rhs[1]+lhs[1]*rhs[2]}
end

e2function complex operator*(number lhs, complex rhs)
	return {lhs*rhs[1], lhs*rhs[2]}
end

e2function complex operator*(complex lhs, number rhs)
	return {lhs[1]*rhs, lhs[2]*rhs}
end

e2function complex operator/(complex lhs, complex rhs)
	local z = rhs[1]*rhs[1] + rhs[2]*rhs[2]
	return {(lhs[1]*rhs[1]+lhs[2]*rhs[2])/z, (lhs[2]*rhs[1]-lhs[1]*rhs[2])/z}
end

e2function complex operator/(number lhs, complex rhs)
	local z = rhs[1]*rhs[1] + rhs[2]*rhs[2]
	return {lhs*rhs[1]/z, -lhs*rhs[2]/z}
end

e2function complex operator/(complex lhs, number rhs)
	return {lhs[1]/rhs, lhs[2]/rhs}
end

e2function complex operator^(complex lhs, complex rhs)
	local l = clog(lhs[1], lhs[2])
	local e = {rhs[1]*l[1] - rhs[2]*l[2], rhs[1]*l[2] + rhs[2]*l[1]}
	return cexp(e[1], e[2])
end

e2function complex operator^(complex lhs, number rhs)
	local l = clog(lhs[1], lhs[2])
	return cexp(rhs*l[1], rhs*l[2])
end

/******************************** constructors ********************************/

--- Returns complex zero
e2function complex comp()
	return {0, 0}
end

--- Converts a real number to complex (returns complex number with real part <a> and imaginary part 0)
e2function complex comp(a)
	return {a, 0}
end

--- Returns <a>+<b>*i
e2function complex comp(a, b)
	return {a, b}
end

--- Returns the imaginary unit i
e2function complex i()
	return {0, 1}
end

--- Returns <b>*i
e2function complex i(b)
	return {0, b}
end

/****************************** helper functions ******************************/

--- Returns the absolute value of <z>
e2function number abs(complex z)
    return sqrt(z[1]*z[1] + z[2]*z[2])
end

--- Returns the argument of <z>
e2function number arg(complex z)
	local l = z[1]*z[1]+z[2]*z[2]
	if l==0 then return 0 end
	local c = z[1]/sqrt(l)
	local p = acos(c)
	if z[2]<0 then p = -p end
	return p
end

--- Returns the conjugate of <z>
e2function complex conj(complex z)
	return {z[1], -z[2]}
end

--- Returns the real part of <z>
e2function number real(complex z)
	return z[1]
end

--- Returns the imaginary part of <z>
e2function number imag(complex z)
	return z[2]
end

/***************************** exp and logarithms *****************************/

--- Raises Euler's constant e to the power of <z>
e2function complex exp(complex z)
	return cexp(z[1], z[2])
end

--- Calculates the natural logarithm of <z>
e2function complex log(complex z)
	return clog(z[1], z[2])
end

--- Calculates the logarithm of <z> to a complex base <base>
e2function complex log(complex base, complex z)
	return cdiv(clog(z),clog(base))
end

--- Calculates the logarithm of <z> to a real base <base>
e2function complex log(number base, complex z)
	local l=clog(z)
	return {l[1]/log(base), l[2]/log(base)}
end

--- Calculates the logarithm of <z> to base 2
e2function complex log2(complex z)
	local l=clog(z)
	return {l[1]/log(2), l[2]/log(2)}
end

--- Calculates the logarithm of <z> to base 10
e2function complex log10(complex z)
	local l=clog(z)
	return {l[1]/log(10), l[2]/log(10)}
end

/******************************************************************************/

--- Calculates the square root of <z>
e2function complex sqrt(complex z)
	local l = clog(z[1], z[2])
	return cexp(0.5*l[1], 0.5*l[2])
end

--- Calculates the complex square root of the real number <n>
e2function complex csqrt(n)
	if n<0 then
		return {0, sqrt(-n)}
	else
		return {sqrt(n), 0}
	end
end

/******************* trigonometric and hyperbolic functions *******************/

__e2setcost(3)

--- Calculates the sine of <z>
e2function complex sin(complex z)
	return {sin(z[1])*cosh(z[2]), sinh(z[2])*cos(z[1])}
end

--- Calculates the cosine of <z>
e2function complex cos(complex z)
	return {cos(z[1])*cosh(z[2]), -sin(z[1])*sinh(z[2])}
end

--- Calculates the hyperbolic sine of <z>
e2function complex sinh(complex z)
	return {sinh(z[1])*cos(z[2]), sin(z[2])*cosh(z[1])}
end

--- Calculates the hyperbolic cosine of <z>
e2function complex cosh(complex z)
	return {cosh(z[1])*cos(z[2]), sinh(z[1])*sin(z[2])}
end

--- Calculates the tangent of <z>
e2function complex tan(complex z)
    local s,c
        s = {sin(z[1])*cosh(z[2]), sinh(z[2])*cos(z[1])}
        c = {cos(z[1])*cosh(z[2]), -sin(z[1])*sinh(z[2])}
        return cdiv(s,c)
end

--- Calculates the cotangent of <z>
e2function complex cot(complex z)
    local s,c
        s = {sin(z[1])*cosh(z[2]), sinh(z[2])*cos(z[1])}
        c = {cos(z[1])*cosh(z[2]), -sin(z[1])*sinh(z[2])}
        return cdiv(c,s)
end

__e2setcost(5)

--- Calculates the inverse sine of <z>
e2function complex asin(complex z)
        local log1mz2 = clog(1-z[1]*z[1]+z[2]*z[2], 2*z[1]*z[2])
        local rt = cexp(log1mz2[1]*0.5,log1mz2[2]*0.5)
        local flog = clog(rt[1]-z[2], z[1]+rt[2])
        return {flog[2], -flog[1]}
end

--- Calculates the inverse cosine of <z>
e2function complex acos(complex z)
        local logz2m1 = clog(z[1]*z[1]-z[2]*z[2]-1, 2*z[1]*z[2])
        local rt = cexp(logz2m1[1]*0.5,logz2m1[2]*0.5)
        local flog = clog(z[1]+rt[1], z[2]+rt[2])
        return {flog[2], -flog[1]}
end

--- Calculates the inverse tangent of <z>
e2function complex atan(complex z)
        local frac = cdiv({-z[1],1-z[2]},{z[1],1+z[2]})
        local logfrac = clog(frac[1], frac[2])
        local rt = cexp(logfrac[1]*0.5,logfrac[2]*0.5)
        local flog = clog(rt[1], rt[2])
        return {flog[2], -flog[1]}
end

__e2setcost(2)

--- Calculates the principle value of <z>
e2function number atan2(complex z)
	return atan2(z[2], z[1])
end

-- ******************** hyperbolic functions *********************** --

__e2setcost(4)

--- Calculates the hyperbolic tangent of <z>
e2function complex tanh(complex z)
    local s,c
        s = {sinh(z[1])*cos(z[2]), sin(z[2])*cosh(z[1])}
        c = {cosh(z[1])*cos(z[2]), sinh(z[1])*sin(z[2])}
        return cdiv(s,c)
end

--- Calculates the hyperbolic cotangent of <z>
e2function complex coth(complex z)
    local s,c
        s = {sinh(z[1])*cos(z[2]), sin(z[2])*cosh(z[1])}
        c = {cosh(z[1])*cos(z[2]), sinh(z[1])*sin(z[2])}
        return cdiv(c,s)
end

__e2setcost(3)

--- Calculates the secant of <z>
e2function complex sec(complex z)
    local c
        c = {cos(z[1])*cosh(z[2]), -sin(z[1])*sinh(z[2])}
        return cdiv({1,0},c)
end

--- Calculates the cosecant of <z>
e2function complex csc(complex z)
    local s
        s = {sin(z[1])*cosh(z[2]), sinh(z[2])*cos(z[1])}
        return cdiv({1,0},s)
end

--- Calculates the hyperbolic secant of <z>
e2function complex sech(complex z)
    local c
        c = {cosh(z[1])*cos(z[2]), sinh(z[1])*sin(z[2])}
        return cdiv({1,0},c)
end

--- Calculates the hyperbolic cosecant of <z>
e2function complex csch(complex z)
    local s
        s = {sinh(z[1])*cos(z[2]), sin(z[2])*cosh(z[1])}
        return cdiv({1,0},s)
end

/******************************************************************************/

__e2setcost(15)

--- Formats <z> as a string.
e2function string toString(complex z)
	return format(z)
end
e2function string complex:toString()
	return format(this)
end
