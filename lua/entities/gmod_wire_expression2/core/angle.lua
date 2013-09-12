/******************************************************************************\
Angle support
\******************************************************************************/

// wow... this is basically just vector-support, but renamed angle-support :P
// pitch, yaw, roll
registerType("angle", "a", { 0, 0, 0 },
	function(self, input) return { input.p, input.y, input.r } end,
	function(self, output) return Angle(output[1], output[2], output[3]) end,
	function(retval)
		if !istable(retval) then error("Return value is not a table, but a "..type(retval).."!",0) end
		if #retval ~= 3 then error("Return value does not have exactly 3 entries!",0) end
	end,
	function(v)
		return !istable(v) or #v ~= 3
	end
)

local pi = math.pi
local floor, ceil = math.floor, math.ceil

/******************************************************************************/

__e2setcost(1) -- approximated

e2function angle ang()
	return { 0, 0, 0 }
end

__e2setcost(2)

e2function angle ang(rv1)
	return { rv1, rv1, rv1 }
end

e2function angle ang(rv1, rv2, rv3)
	return { rv1, rv2, rv3 }
end

// Convert Vector -> Angle
e2function angle ang(vector rv1)
	return {rv1[1],rv1[2],rv1[3]}
end

/******************************************************************************/

registerOperator("ass", "a", "a", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

/******************************************************************************/

e2function number operator_is(angle rv1)
	if rv1[1] != 0 || rv1[2] != 0 || rv1[3] != 0
	   then return 1 else return 0 end
end

__e2setcost(3)

e2function number operator==(angle rv1, angle rv2)
	if rv1[1] - rv2[1] <= delta && rv2[1] - rv1[1] <= delta &&
	   rv1[2] - rv2[2] <= delta && rv2[2] - rv1[2] <= delta &&
	   rv1[3] - rv2[3] <= delta && rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end

e2function number operator!=(angle rv1, angle rv2)
	if rv1[1] - rv2[1] > delta || rv2[1] - rv1[1] > delta ||
	   rv1[2] - rv2[2] > delta || rv2[2] - rv1[2] > delta ||
	   rv1[3] - rv2[3] > delta || rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end

e2function number operator>=(angle rv1, angle rv2)
	if rv2[1] - rv1[1] <= delta &&
	   rv2[2] - rv1[2] <= delta &&
	   rv2[3] - rv1[3] <= delta
	   then return 1 else return 0 end
end

e2function number operator<=(angle rv1, angle rv2)
	if rv1[1] - rv2[1] <= delta &&
	   rv1[2] - rv2[2] <= delta &&
	   rv1[3] - rv2[3] <= delta
	   then return 1 else return 0 end
end

e2function number operator>(angle rv1, angle rv2)
	if rv1[1] - rv2[1] > delta &&
	   rv1[2] - rv2[2] > delta &&
	   rv1[3] - rv2[3] > delta
	   then return 1 else return 0 end
end

e2function number operator<(angle rv1, angle rv2)
	if rv2[1] - rv1[1] > delta &&
	   rv2[2] - rv1[2] > delta &&
	   rv2[3] - rv1[3] > delta
	   then return 1 else return 0 end
end

/******************************************************************************/

registerOperator("dlt", "a", "a", function(self, args)
	local op1, scope = args[2], args[3]
	local rv1, rv2 = self.Scopes[scope][op1], self.Scopes[scope]["$" .. op1]
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end)

__e2setcost(2)

e2function angle operator_neg(angle rv1)
	return { -rv1[1], -rv1[2], -rv1[3] }
end

e2function angle operator+(rv1, angle rv2)
	return { rv1 + rv2[1], rv1 + rv2[2], rv1 + rv2[3] }
end

e2function angle operator+(angle rv1, rv2)
	return { rv1[1] + rv2, rv1[2] + rv2, rv1[3] + rv2 }
end

e2function angle operator+(angle rv1, angle rv2)
	return { rv1[1] + rv2[1], rv1[2] + rv2[2], rv1[3] + rv2[3] }
end

e2function angle operator-(rv1, angle rv2)
	return { rv1 - rv2[1], rv1 - rv2[2], rv1 - rv2[3] }
end

e2function angle operator-(angle rv1, rv2)
	return { rv1[1] - rv2, rv1[2] - rv2, rv1[3] - rv2 }
end

e2function angle operator-(angle rv1, angle rv2)
	return { rv1[1] - rv2[1], rv1[2] - rv2[2], rv1[3] - rv2[3] }
end

e2function angle operator*(angle rv1, angle rv2)
	return { rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] }
end

e2function angle operator*(rv1, angle rv2)
	return { rv1 * rv2[1], rv1 * rv2[2], rv1 * rv2[3] }
end

e2function angle operator*(angle rv1, rv2)
	return { rv1[1] * rv2, rv1[2] * rv2, rv1[3] * rv2 }
end

e2function angle operator/(rv1, angle rv2)
    return { rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] }
end

e2function angle operator/(angle rv1, rv2)
    return { rv1[1] / rv2, rv1[2] / rv2, rv1[3] / rv2 }
end

e2function angle operator/(angle rv1, angle rv2)
	return { rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3] }
end

e2function number angle:operator[](index)
	return this[floor(math.Clamp(index, 1, 3) + 0.5)]
end

e2function number angle:operator[](index, value)
	this[floor(math.Clamp(index, 1, 3) + 0.5)] = value
	return value
end

/******************************************************************************/

__e2setcost(5)

e2function angle angnorm(angle rv1)
	return {(rv1[1] + 180) % 360 - 180,(rv1[2] + 180) % 360 - 180,(rv1[3] + 180) % 360 - 180}
end

e2function number angnorm(rv1)
	return (rv1 + 180) % 360 - 180
end

__e2setcost(1)

e2function number angle:pitch()
	return this[1]
end

e2function number angle:yaw()
	return this[2]
end

e2function number angle:roll()
	return this[3]
end

__e2setcost(2)

// SET methods that returns angles
e2function angle angle:setPitch(rv2)
	return { rv2, this[2], this[3] }
end

e2function angle angle:setYaw(rv2)
	return { this[1], rv2, this[3] }
end

e2function angle angle:setRoll(rv2)
	return { this[1], this[2], rv2 }
end

/******************************************************************************/

__e2setcost(5)

e2function angle round(angle rv1)
	return {
		floor(rv1[1] + 0.5), 
		floor(rv1[2] + 0.5), 
		floor(rv1[3] + 0.5)
	}
end

e2function angle round(angle rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf + 0.5) / shf, 
		floor(rv1[2] * shf + 0.5) / shf, 
		floor(rv1[3] * shf + 0.5) / shf
	}
end

e2function angle ceil(angle rv1)
	return {
		ceil(rv1[1]), 
		ceil(rv1[2]), 
		ceil(rv1[3])
	}
end

e2function angle ceil(angle rv1, decimals)
	local shf = 10 ^ decimals
	return {
		ceil(rv1[1] * shf) / shf, 
		ceil(rv1[2] * shf) / shf, 
		ceil(rv1[3] * shf) / shf
	}
end

e2function angle floor(angle rv1)
	return {
		floor(rv1[1]), 
		floor(rv1[2]), 
		floor(rv1[3])
	}
end

e2function angle floor(angle rv1, decimals)
	local shf = 10 ^ decimals
	return {
		floor(rv1[1] * shf) / shf, 
		floor(rv1[2] * shf) / shf, 
		floor(rv1[3] * shf) / shf
	}
end

// Performs modulo on p,y,r separately
e2function angle mod(angle rv1, rv2)
	local p,y,r
	if rv1[1] >= 0 then
		p = rv1[1] % rv2
	else p = rv1[1] % -rv2 end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2
	else y = rv1[2] % -rv2 end
	if rv1[3] >= 0 then
		r = rv1[3] % rv2
	else r = rv1[3] % -rv2 end
	return {p, y, r}
end

// Modulo where divisors are defined as an angle
e2function angle mod(angle rv1, angle rv2)
	local p,y,r
	if rv1[1] >= 0 then
		p = rv1[1] % rv2[1]
	else p = rv1[1] % -rv2[1] end
	if rv1[2] >= 0 then
		y = rv1[2] % rv2[2]
	else y = rv1[2] % -rv2[2] end
	if rv1[3] >= 0 then
		y = rv1[3] % rv2[3]
	else y = rv1[3] % -rv2[3] end
	return {p, y, r}
end

// Clamp each p,y,r separately
e2function angle clamp(angle rv1, rv2, rv3)
	local p,y,r

	if rv1[1] < rv2 then p = rv2
	elseif rv1[1] > rv3 then p = rv3
	else p = rv1[1] end

	if rv1[2] < rv2 then y = rv2
	elseif rv1[2] > rv3 then y = rv3
	else y = rv1[2] end

	if rv1[3] < rv2 then r = rv2
	elseif rv1[3] > rv3 then r = rv3
	else r = rv1[3] end

	return {p, y, r}
end

// Clamp according to limits defined by two min/max angles
e2function angle clamp(angle rv1, angle rv2, angle rv3)
	local p,y,r

	if rv1[1] < rv2[1] then p = rv2[1]
	elseif rv1[1] > rv3[1] then p = rv3[1]
	else p = rv1[1] end

	if rv1[2] < rv2[2] then y = rv2[2]
	elseif rv1[2] > rv3[2] then y = rv3[2]
	else y = rv1[2] end

	if rv1[3] < rv2[3] then r = rv2[3]
	elseif rv1[3] > rv3[3] then r = rv3[3]
	else r = rv1[3] end

	return {p, y, r}
end

// Mix two angles by a given proportion (between 0 and 1)
e2function angle mix(angle rv1, angle rv2, rv3)
	local p = rv1[1] * rv3 + rv2[1] * (1-rv3)
	local y = rv1[2] * rv3 + rv2[2] * (1-rv3)
	local r = rv1[3] * rv3 + rv2[3] * (1-rv3)
	return {p, y, r}
end

__e2setcost(2)

// Circular shift function: shiftr(  p,y,r ) = ( r,p,y )
e2function angle shiftR(angle rv1)
	return {rv1[3], rv1[1], rv1[2]}
end

e2function angle shiftL(angle rv1)
	return {rv1[2], rv1[3], rv1[1]}
end

__e2setcost(5)

// Returns 1 if the angle lies between (or is equal to) the min/max angles
e2function normal inrange(angle rv1, angle rv2, angle rv3)
	if rv1[1] < rv2[1] then return 0 end
	if rv1[2] < rv2[2] then return 0 end
	if rv1[3] < rv2[3] then return 0 end

	if rv1[1] > rv3[1] then return 0 end
	if rv1[2] > rv3[2] then return 0 end
	if rv1[3] > rv3[3] then return 0 end

	return 1
end

// Rotate an angle around a vector by the given number of degrees
e2function angle angle:rotateAroundAxis(vector axis, degrees)
	local ang = Angle(this[1], this[2], this[3])
	local vec = Vector(axis[1], axis[2], axis[3]):GetNormal()

	ang:RotateAroundAxis(vec, degrees)
	return {ang.p, ang.y, ang.r}
end

// Convert the magnitude of the angle to radians
e2function angle toRad(angle rv1)
	return {rv1[1] * pi / 180, rv1[2] * pi / 180, rv1[3] * pi / 180}
end

// Convert the magnitude of the angle to degrees
e2function angle toDeg(angle rv1)
	return {rv1[1] * 180 / pi, rv1[2] * 180 / pi, rv1[3] * 180 / pi}
end

/******************************************************************************/

e2function vector angle:forward()
	return Angle(this[1], this[2], this[3]):Forward()
end

e2function vector angle:right()
	return Angle(this[1], this[2], this[3]):Right()
end

e2function vector angle:up()
	return Angle(this[1], this[2], this[3]):Up()
end

e2function string toString(angle a)
	return ("[%s,%s,%s]"):format(a[1],a[2],a[3])
end

e2function string angle:toString() = e2function string toString(angle a)
