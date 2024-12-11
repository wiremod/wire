/******************************************************************************\
Angle support
\******************************************************************************/

registerType("angle", "a", Angle(0, 0, 0),
	nil,
	function(self, output) return Angle(output) end,
	nil,
	function(v)
		return not isangle(v)
	end
)

local floor, ceil = math.floor, math.ceil

/******************************************************************************/

__e2setcost(1) -- approximated

e2function angle ang()
	return Angle(0, 0, 0)
end

__e2setcost(2)

e2function angle ang(rv1)
	return Angle(rv1, rv1, rv1)
end

e2function angle ang(rv1, rv2, rv3)
	return Angle(rv1, rv2, rv3)
end

-- Convert Vector -> Angle
e2function angle ang(vector rv1)
	return Angle(rv1[1], rv1[2], rv1[3])
end

e2function number operator_is(angle this)
	return this:IsZero() and 0 or 1
end

__e2setcost(1)

e2function number operator>=(angle lhs, angle rhs)
	return (lhs[1] >= rhs[1]
		and lhs[2] >= rhs[2]
		and lhs[3] >= rhs[3])
		and 1 or 0
end

e2function number operator<=(angle lhs, angle rhs)
	return (lhs[1] <= rhs[1]
		and lhs[2] <= rhs[2]
		and lhs[3] <= rhs[3])
		and 1 or 0
end

e2function number operator>(angle lhs, angle rhs)
	return (lhs[1] > rhs[1]
		and lhs[2] > rhs[2]
		and lhs[3] > rhs[3])
		and 1 or 0
end

e2function number operator<(angle lhs, angle rhs)
	return (lhs[1] < rhs[1]
		and lhs[2] < rhs[2]
		and lhs[3] < rhs[3])
		and 1 or 0
end

__e2setcost(2)

e2function angle operator_neg(angle rv1)
	return -rv1
end

e2function angle operator+(rv1, angle rv2)
	return Angle(rv1 + rv2[1], rv1 + rv2[2], rv1 + rv2[3])
end

e2function angle operator+(angle rv1, rv2)
	return Angle(rv1[1] + rv2, rv1[2] + rv2, rv1[3] + rv2)
end

e2function angle operator+(angle rv1, angle rv2)
	return rv1 + rv2
end

e2function angle operator-(rv1, angle rv2)
	return Angle(rv1 - rv2[1], rv1 - rv2[2], rv1 - rv2[3])
end

e2function angle operator-(angle rv1, rv2)
	return Angle(rv1[1] - rv2, rv1[2] - rv2, rv1[3] - rv2)
end

e2function angle operator-(angle rv1, angle rv2)
	return rv1 - rv2
end

e2function angle operator*(angle rv1, angle rv2)
	return Angle( rv1[1] * rv2[1], rv1[2] * rv2[2], rv1[3] * rv2[3] )
end

e2function angle operator*(rv1, angle rv2)
	return rv1 * rv2
end

e2function angle operator*(angle rv1, rv2)
	return rv1 * rv2
end

-- Yes this needs to be in pure lua. Angle/Vector operations in reverse order act as Angle / Number rather than Number / Angle properly. Amazing.
e2function angle operator/(rv1, angle rv2)
    return Angle( rv1 / rv2[1], rv1 / rv2[2], rv1 / rv2[3] )
end

e2function angle operator/(angle rv1, rv2)
    return  rv1 / rv2
end

e2function angle operator/(angle rv1, angle rv2)
	return Angle( rv1[1] / rv2[1], rv1[2] / rv2[2], rv1[3] / rv2[3] )
end

registerOperator("indexget", "an", "n", function(state, this, index)
	return this[floor(math.Clamp(index, 1, 3) + 0.5)]
end)

registerOperator("indexset", "ann", "", function(state, this, index, value)
	this[floor(math.Clamp(index, 1, 3) + 0.5)] = value
	state.GlobalScope.vclk[this] = true
end)

e2function string operator+(string lhs, angle rhs)
	self.prf = self.prf + #lhs * 0.01
	return lhs .. ("ang(%g,%g,%g)"):format(rhs[1], rhs[2], rhs[3])
end

e2function string operator+(angle lhs, string rhs)
	self.prf = self.prf + #rhs * 0.01
	return ("ang(%g,%g,%g)"):format(lhs[1], lhs[2], lhs[3]) .. rhs
end

/******************************************************************************/

__e2setcost(5)

e2function angle angnorm(angle rv1)
	local ang = Angle(rv1)
	ang:Normalize()

	return ang
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

-- SET methods that returns angles
e2function angle angle:setPitch(rv2)
	local ang = Angle(this)
	ang.pitch = rv2

	return ang
end

e2function angle angle:setYaw(rv2)
	local ang = Angle(this)
	ang.yaw = rv2

	return ang
end

e2function angle angle:setRoll(rv2)
	local ang = Angle(this)
	ang.roll = rv2

	return ang
end

/******************************************************************************/

__e2setcost(5)

e2function angle round(angle rv1)
	return Angle(
		floor(rv1[1] + 0.5),
		floor(rv1[2] + 0.5),
		floor(rv1[3] + 0.5)
	)
end

e2function angle round(angle rv1, decimals)
	local shf = 10 ^ decimals
	return Angle(
		floor(rv1[1] * shf + 0.5) / shf,
		floor(rv1[2] * shf + 0.5) / shf,
		floor(rv1[3] * shf + 0.5) / shf
	)
end

e2function angle ceil(angle rv1)
	return Angle(
		ceil(rv1[1]),
		ceil(rv1[2]),
		ceil(rv1[3])
	)
end

e2function angle ceil(angle rv1, decimals)
	local shf = 10 ^ decimals
	return Angle(
		ceil(rv1[1] * shf) / shf,
		ceil(rv1[2] * shf) / shf,
		ceil(rv1[3] * shf) / shf
	)
end

e2function angle floor(angle rv1)
	return Angle(
		floor(rv1[1]),
		floor(rv1[2]),
		floor(rv1[3])
	)
end

e2function angle floor(angle rv1, decimals)
	local shf = 10 ^ decimals
	return Angle(
		floor(rv1[1] * shf) / shf,
		floor(rv1[2] * shf) / shf,
		floor(rv1[3] * shf) / shf
	)
end

-- Performs modulo on p,y,r separately
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
	return Angle(p, y, r)
end

-- Modulo where divisors are defined as an angle
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
	return Angle(p, y, r)
end

-- Clamp each p,y,r separately
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

	return Angle(p, y, r)
end

-- Clamp according to limits defined by two min/max angles
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

	return Angle(p, y, r)
end

-- Mix two angles by a given proportion (between 0 and 1)
e2function angle mix(angle rv1, angle rv2, rv3)
	local p = rv1[1] * rv3 + rv2[1] * (1-rv3)
	local y = rv1[2] * rv3 + rv2[2] * (1-rv3)
	local r = rv1[3] * rv3 + rv2[3] * (1-rv3)
	return Angle(p, y, r)
end

__e2setcost(2)

-- Circular shift function: shiftr(  p,y,r ) = ( r,p,y )
e2function angle shiftR(angle rv1)
	return Angle(rv1[3], rv1[1], rv1[2])
end

e2function angle shiftL(angle rv1)
	return Angle(rv1[2], rv1[3], rv1[1])
end

__e2setcost(5)

-- Returns 1 if the angle lies between (or is equal to) the min/max angles
e2function normal inrange(angle rv1, angle rv2, angle rv3)
	if rv1[1] < rv2[1] then return 0 end
	if rv1[2] < rv2[2] then return 0 end
	if rv1[3] < rv2[3] then return 0 end

	if rv1[1] > rv3[1] then return 0 end
	if rv1[2] > rv3[2] then return 0 end
	if rv1[3] > rv3[3] then return 0 end

	return 1
end

-- Rotate an angle around a vector by the given number of degrees
e2function angle angle:rotateAroundAxis(vector axis, degrees)
	local ang = Angle(this)
	ang:RotateAroundAxis( axis:GetNormalized(), degrees )
	return ang
end

-- Convert the magnitude of the angle to radians
local deg2rad = math.pi / 180
local rad2deg = 180 / math.pi

e2function angle toRad(angle rv1)
	return rv1 * deg2rad
end

-- Convert the magnitude of the angle to degrees
e2function angle toDeg(angle rv1)
	return rv1 * rad2deg
end

/******************************************************************************/

e2function vector angle:forward()
	return this:Forward()
end

e2function vector angle:right()
	return this:Right()
end

e2function vector angle:up()
	return this:Up()
end

e2function string toString(angle a)
	return ("ang(%g,%g,%g)"):format(a[1], a[2], a[3])
end

e2function string angle:toString() = e2function string toString(angle a)
