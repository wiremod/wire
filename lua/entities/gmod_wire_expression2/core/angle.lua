--[[
Angle support
--]]

registerType("angle", "a", Angle(0, 0, 0),
	nil,
	function(self, output) return Angle(output) end,
	nil,
	function(v)
		return not isangle(v)
	end
)

local floor, ceil, clamp = math.floor, math.ceil, math.Clamp

--------------------------------------------------------------------------------

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
e2function angle ang(vector vec)
	return Angle(vec:Unpack())
end

e2function number operator_is(angle this)
	return this:IsZero() and 0 or 1
end

__e2setcost(1)

e2function number operator>=(angle lhs, angle rhs)
	local lp, ly, lr = lhs:Unpack()
	local rp, ry, rr = rhs:Unpack()

	return lp >= rp and ly >= ry and lr >= rr and 1 or 0
end

e2function number operator<=(angle lhs, angle rhs)
	local lp, ly, lr = lhs:Unpack()
	local rp, ry, rr = rhs:Unpack()

	return lp <= rp and ly <= ry and lr <= rr and 1 or 0
end

e2function number operator>(angle lhs, angle rhs)
	local lp, ly, lr = lhs:Unpack()
	local rp, ry, rr = rhs:Unpack()

	return lp > rp and ly > ry and lr > rr and 1 or 0
end

e2function number operator<(angle lhs, angle rhs)
	local lp, ly, lr = lhs:Unpack()
	local rp, ry, rr = rhs:Unpack()

	return lp < rp and ly < ry and lr < rr and 1 or 0
end

__e2setcost(2)

e2function angle operator_neg(angle rv1)
	return -rv1
end

e2function angle operator+(rv1, angle rv2)
	local rp2, ry2, rr2 = rv2:Unpack()
	return Angle(rv1 + rp2, rv1 + ry2, rv1 + rr2)
end

e2function angle operator+(angle rv1, rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(rp1 + rv2, ry1 + rv2, rr1 + rv2)
end

e2function angle operator+(angle rv1, angle rv2)
	return rv1 + rv2
end

e2function angle operator-(rv1, angle rv2)
	local rp2, ry2, rr2 = rv2:Unpack()
	return Angle(rv1 - rp2, rv1 - ry2, rv1 - rr2)
end

e2function angle operator-(angle rv1, rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(rp1 - rv2, ry1 - rv2, rr1 - rv2)
end

e2function angle operator-(angle rv1, angle rv2)
	return rv1 - rv2
end

e2function angle operator*(angle rv1, angle rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()

	return Angle(rp1 * rp2, ry1 * ry2, rr1 * rr2)
end

e2function angle operator*(rv1, angle rv2)
	return rv1 * rv2
end

e2function angle operator*(angle rv1, rv2)
	return rv1 * rv2
end

-- Yes this needs to be in pure lua. Angle/Vector operations in reverse order act as Angle / Number rather than Number / Angle properly. Amazing.
e2function angle operator/(rv1, angle rv2)
	local rp2, ry2, rr2 = rv2:Unpack()
	return Angle(rv1 / rp2, rv1 / ry2, rv1 / rr2)
end

e2function angle operator/(angle rv1, rv2)
	return rv1 / rv2
end

e2function angle operator/(angle rv1, angle rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()

	return Angle(rp1 / rp2, ry1 / ry2, rr1 / rr2)
end

e2function angle operator%(rv1, angle rv2)
    return Angle( rv1 % rv2[1], rv1 % rv2[2], rv1 % rv2[3] )
end

e2function angle operator%(angle rv1, rv2)
	return Angle( rv1[1] % rv2, rv1[2] % rv2, rv1[3] % rv2 )
end

e2function angle operator%(angle rv1, angle rv2)
	return Angle( rv1[1] % rv2[1], rv1[2] % rv2[2], rv1[3] % rv2[3] )
end

registerOperator("indexget", "an", "n", function(state, this, index)
	return this[floor(clamp(index, 1, 3) + 0.5)]
end)

registerOperator("indexset", "ann", "", function(state, this, index, value)
	this[floor(clamp(index, 1, 3) + 0.5)] = value
	state.GlobalScope.vclk[this] = true
end)

e2function string operator+(string lhs, angle rhs)
	self.prf = self.prf + #lhs * 0.01
	return lhs .. string.format("ang(%g,%g,%g)", rhs:Unpack())
end

e2function string operator+(angle lhs, string rhs)
	self.prf = self.prf + #rhs * 0.01
	return string.format("ang(%g,%g,%g)", lhs:Unpack()) .. rhs
end

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

__e2setcost(5)

e2function angle round(angle rv1)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(floor(rp1 + 0.5), floor(ry1 + 0.5), floor(rr1 + 0.5))
end

e2function angle round(angle rv1, decimals)
	local shf = 10 ^ decimals
	local rp1, ry1, rr1 = rv1:Unpack()

	return Angle(floor(rp1 * shf + 0.5) / shf, floor(ry1 * shf + 0.5) / shf, floor(rr1 * shf + 0.5) / shf)
end

e2function angle ceil(angle rv1)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(ceil(rp1), ceil(ry1), ceil(rr1))
end

e2function angle ceil(angle rv1, decimals)
	local shf = 10 ^ decimals
	local rp1, ry1, rr1 = rv1:Unpack()

	return Angle(ceil(rp1 * shf) / shf, ceil(ry1 * shf) / shf, ceil(rr1 * shf) / shf)
end

e2function angle floor(angle rv1)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(floor(rp1), floor(ry1), floor(rr1))
end

e2function angle floor(angle rv1, decimals)
	local shf = 10 ^ decimals
	local rp1, ry1, rr1 = rv1:Unpack()

	return Angle(floor(rp1 * shf) / shf, floor(ry1 * shf) / shf, floor(rr1 * shf) / shf)
end

-- Performs modulo on p,y,r separately
e2function angle mod(angle rv1, rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(rp1 % (rp1 >= 0 and rv2 or -rv2), ry1 % (ry1 >= 0 and rv2 or -rv2), rr1 % (rr1 >= 0 and rv2 or -rv2))
end

-- Modulo where divisors are defined as an angle
e2function angle mod(angle rv1, angle rv2)
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()

	return Angle(rp1 % (rp1 >= 0 and rp2 or -rp2), ry1 % (ry1 >= 0 and ry2 or -ry2), rr1 % (rr1 >= 0 and rr2 or -rr2))
end

-- Clamp each p,y,r separately
e2function angle clamp(angle rv1, rv2, rv3)
	local p, y, r
	local rp1, ry1, rr1 = rv1:Unpack()

	if rp1 < rv2 then
		p = rv2
	elseif rp1 > rv3 then
		p = rv3
	else
		p = rp1
	end

	if ry1 < rv2 then
		y = rv2
	elseif ry1 > rv3 then
		y = rv3
	else
		y = ry1
	end

	if rr1 < rv2 then
		r = rv2
	elseif rr1 > rv3 then
		r = rv3
	else
		r = rr1
	end

	return Angle(p, y, r)
end

-- Clamp according to limits defined by two min/max angles
e2function angle clamp(angle rv1, angle rv2, angle rv3)
	local p, y, r
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()
	local rp3, ry3, rr3 = rv3:Unpack()

	if rp1 < rp2 then
		p = rp2
	elseif rp1 > rp3 then
		p = rp3
	else
		p = rp1
	end

	if ry1 < ry2 then
		y = ry2
	elseif ry1 > ry3 then
		y = ry3
	else
		y = ry1
	end

	if rr1 < rr2 then
		r = rr2
	elseif rr1 > rr3 then
		r = rr3
	else
		r = rr1
	end

	return Angle(p, y, r)
end

-- Mix two angles by a given proportion (between 0 and 1)
e2function angle mix(angle rv1, angle rv2, rv3)
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()

	return Angle(rp1 * rv3 + rp2 * (1 - rv3), ry1 * rv3 + ry2 * (1 - rv3), rr1 * rv3 + rr2 * (1 - rv3))
end

__e2setcost(2)

-- Circular shift function: shiftr(  p,y,r ) = ( r,p,y )
e2function angle shiftR(angle rv1)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(rr1, rp1, ry1)
end

e2function angle shiftL(angle rv1)
	local rp1, ry1, rr1 = rv1:Unpack()
	return Angle(ry1, rr1, rp1)
end

__e2setcost(5)

-- Returns 1 if the angle lies between (or is equal to) the min/max angles
e2function normal inrange(angle rv1, angle rv2, angle rv3)
	local rp1, ry1, rr1 = rv1:Unpack()
	local rp2, ry2, rr2 = rv2:Unpack()

	if rp1 < rp2 then return 0 end
	if ry1 < ry2 then return 0 end
	if rr1 < rr2 then return 0 end

	local rp3, ry3, rr3 = rv3:Unpack()

	if rp1 > rp3 then return 0 end
	if ry1 > ry3 then return 0 end
	if rr1 > rr3 then return 0 end

	return 1
end

-- Rotate an angle around a vector by the given number of degrees
e2function angle angle:rotateAroundAxis(vector axis, degrees)
	local ang = Angle(this)
	ang:RotateAroundAxis(axis:GetNormalized(), degrees)

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

--------------------------------------------------------------------------------

e2function vector angle:forward()
	return this:Forward()
end

e2function vector angle:right()
	return this:Right()
end

e2function vector angle:up()
	return this:Up()
end

e2function string toString(angle ang)
	return string.format("ang(%g,%g,%g)", ang:Unpack())
end

e2function string angle:toString() = e2function string toString(angle ang)
