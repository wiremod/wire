/******************************************************************************\
  Quaternion support
\******************************************************************************/

// TODO: implement more!

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

local deg2rad = math.pi/180
local rad2deg = 180/math.pi

registerType("quaternion", "q", { 0, 0, 0, 0 },
	nil,
	nil,
	nil,
	function(v)
		return !istable(v) or #v ~= 4
	end
)

local function format(value)
	local r,i,j,k,dbginfo

	r = ""
	i = ""
	j = ""
	k = ""

	if abs(value[1]) > 0.0005 then
		r = Round(value[1]*1000)/1000
	end
	dbginfo = r
	if abs(value[2]) > 0.0005 then
		i = tostring(Round(value[2]*1000)/1000)
		if string.sub(i,1,1)~="-" and dbginfo ~= "" then i = "+"..i end
		i = i .. "i"
	end
	dbginfo = dbginfo .. i
	if abs(value[3]) > 0.0005 then
		j = tostring(Round(value[3]*1000)/1000)
		if string.sub(j,1,1)~="-" and dbginfo ~= "" then j = "+"..j end
		j = j .. "j"
	end
	dbginfo = dbginfo .. j
	if abs(value[4]) > 0.0005 then
		k = tostring(Round(value[4]*1000)/1000)
		if string.sub(k,1,1)~="-" and dbginfo ~= "" then k = "+"..k end
		k = k .. "k"
	end
	dbginfo = dbginfo .. k
	if dbginfo == "" then dbginfo = "0" end
	return dbginfo
end

WireLib.registerDebuggerFormat("QUATERNION", format)

/****************************** Helper functions ******************************/

local function qmul(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return {
		lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
		lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
		lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
	}
end

local function qexp(q)
	local m = sqrt(q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	local u
	if m ~= 0 then
		u = { q[2]*sin(m)/m, q[3]*sin(m)/m, q[4]*sin(m)/m }
	else
		u = { 0, 0, 0 }
	end
	local r = exp(q[1])
	return { r*cos(m), r*u[1], r*u[2], r*u[3] }
end

local function qlog(q)
	local l = sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	if l == 0 then return { -1e+100, 0, 0, 0 } end
	local u = { q[1]/l, q[2]/l, q[3]/l, q[4]/l }
	local a = acos(u[1])
	local m = sqrt(u[2]*u[2] + u[3]*u[3] + u[4]*u[4])
	if abs(m) > 0 then
		return { log(l), a*u[2]/m, a*u[3]/m, a*u[4]/m }
	else
		return { log(l), 0, 0, 0 }  --when m is 0, u[2], u[3] and u[4] are 0 too
	end
end

local function qDot(q1, q2)
	return q1[1]*q2[1] + q1[2]*q2[2] + q1[3]*q2[3] + q1[4]*q2[4]
end

local function qGetNormalized(q)
	local len = sqrt(q[1]^2 + q[2]^2 + q[3]^2 + q[4]^2)
	return {q[1]/len, q[2]/len, q[3]/len, q[4]/len}
end

local function qNormalize(q)
	local len = sqrt(q[1]^2 + q[2]^2 + q[3]^2 + q[4]^2)
	q[1] = q[1]/len
	q[2] = q[2]/len
	q[3] = q[3]/len
	q[4] = q[4]/len
end

/******************************************************************************/

__e2setcost(1)

--- Creates a zero quaternion
e2function quaternion quat()
	return { 0, 0, 0, 0 }
end

--- Creates a quaternion with real part equal to <real>
e2function quaternion quat(real)
	return { real, 0, 0, 0 }
end

--- Creates a quaternion with real and "i" parts equal to <c>
e2function quaternion quat(complex c)
	return { c[1], c[2], 0, 0 }
end

--- Converts a vector to a quaternion (returns <imag>.x*i + <imag>.y*j + <imag>.z*k)
e2function quaternion quat(vector imag)
	return { 0, imag[1], imag[2], imag[3] }
end

--- Returns <real>+<i>i+<j>j+<k>k
e2function quaternion quat(real, i, j, k)
	return { real, i, j, k }
end

__e2setcost(6)

--- Converts <ang> to a quaternion
e2function quaternion quat(angle ang)
	local p, y, r = ang[1], ang[2], ang[3]
	p = p*deg2rad*0.5
	y = y*deg2rad*0.5
	r = r*deg2rad*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end

__e2setcost(15)

--- Creates a quaternion given forward (<forward>) and up (<up>) vectors
e2function quaternion quat(vector forward, vector up)
	local x = Vector(forward[1], forward[2], forward[3])
	local z = Vector(up[1], up[2], up[3])
	local y = z:Cross(x):GetNormalized() --up x forward = left

	local ang = x:Angle()
	if ang.p > 180 then ang.p = ang.p - 360 end
	if ang.y > 180 then ang.y = ang.y - 360 end

	local yyaw = Vector(0,1,0)
	yyaw:Rotate(Angle(0,ang.y,0))

	local roll = acos(math.Clamp(y:Dot(yyaw), -1, 1))*rad2deg

	local dot = y.z
	if dot < 0 then roll = -roll end

	local p, y, r = ang.p, ang.y, roll
	p = p*deg2rad*0.5
	y = y*deg2rad*0.5
	r = r*deg2rad*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end

--- Converts angle of <ent> to a quaternion
e2function quaternion quat(entity ent)
	if(!IsValid(ent)) then
		return { 0, 0, 0, 0 }
	end
	local ang = ent:GetAngles()
	local p, y, r = ang.p, ang.y, ang.r
	p = p*deg2rad*0.5
	y = y*deg2rad*0.5
	r = r*deg2rad*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end

__e2setcost(1)

--- Returns quaternion i
e2function quaternion qi()
	return {0, 1, 0, 0}
end

--- Returns quaternion <n>*i
e2function quaternion qi(n)
	return {0, n, 0, 0}
end

--- Returns j
e2function quaternion qj()
	return {0, 0, 1, 0}
end

--- Returns <n>*j
e2function quaternion qj(n)
	return {0, 0, n, 0}
end

--- Returns k
e2function quaternion qk()
	return {0, 0, 0, 1}
end

--- Returns <n>*k
e2function quaternion qk(n)
	return {0, 0, 0, n}
end

/******************************************************************************/

__e2setcost(2)

/******************************************************************************/
// TODO: define division as multiplication with (1/x), or is it not useful?

__e2setcost(4)

e2function quaternion operator_neg(quaternion q)
	return { -q[1], -q[2], -q[3], -q[4] }
end

e2function quaternion operator+(quaternion lhs, quaternion rhs)
	return { lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3], lhs[4] + rhs[4] }
end

e2function quaternion operator+(number lhs, quaternion rhs)
	return { lhs + rhs[1], rhs[2], rhs[3], rhs[4] }
end

e2function quaternion operator+(quaternion lhs, number rhs)
	return { lhs[1] + rhs, lhs[2], lhs[3], lhs[4] }
end

e2function quaternion operator+(complex lhs, quaternion rhs)
	return { lhs[1] + rhs[1], lhs[2] + rhs[2], rhs[3], rhs[4] }
end

e2function quaternion operator+(quaternion lhs, complex rhs)
	return { lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3], lhs[4] }
end

e2function quaternion operator-(quaternion lhs, quaternion rhs)
	return { lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4] }
end

e2function quaternion operator-(number lhs, quaternion rhs)
	return { lhs - rhs[1], -rhs[2], -rhs[3], -rhs[4] }
end

e2function quaternion operator-(quaternion lhs, number rhs)
	return { lhs[1] - rhs, lhs[2], lhs[3], lhs[4] }
end

e2function quaternion operator-(complex lhs, quaternion rhs)
	return { lhs[1] - rhs[1], lhs[2] - rhs[2], -rhs[3], -rhs[4] }
end

e2function quaternion operator-(quaternion lhs, complex rhs)
	return { lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3], lhs[4] }
end

e2function quaternion operator*(lhs, quaternion rhs)
	return { lhs * rhs[1], lhs * rhs[2], lhs * rhs[3], lhs * rhs[4] }
end

e2function quaternion operator*(quaternion lhs, rhs)
	return { lhs[1] * rhs, lhs[2] * rhs, lhs[3] * rhs, lhs[4] * rhs }
end

__e2setcost(6)

e2function quaternion operator*(complex lhs, quaternion rhs)
	local lhs1, lhs2 = lhs[1], lhs[2]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return {
		lhs1 * rhs1 - lhs2 * rhs2,
		lhs1 * rhs2 + lhs2 * rhs1,
		lhs1 * rhs3 - lhs2 * rhs4,
		lhs1 * rhs4 + lhs2 * rhs3
	}
end

e2function quaternion operator*(quaternion lhs, complex rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2 = rhs[1], rhs[2]
	return {
		lhs1 * rhs1 - lhs2 * rhs2,
		lhs1 * rhs2 + lhs2 * rhs1,
		lhs3 * rhs1 + lhs4 * rhs2,
		lhs4 * rhs1 - lhs3 * rhs2
	}
end

__e2setcost(9)

e2function quaternion operator*(quaternion lhs, quaternion rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return {
		lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
		lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
		lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
	}
end

e2function quaternion operator*(quaternion lhs, vector rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3]
	return {
		-lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		 lhs1 * rhs2 + lhs3 * rhs4 - lhs4 * rhs3,
		 lhs1 * rhs3 + lhs4 * rhs2 - lhs2 * rhs4,
		 lhs1 * rhs4 + lhs2 * rhs3 - lhs3 * rhs2
	}
end

e2function quaternion operator*(vector lhs, quaternion rhs)
	local lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return {
		-lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		 lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
		 lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
		 lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
	}
end

e2function quaternion operator/(quaternion lhs, number rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	return {
		lhs1/rhs,
		lhs2/rhs,
		lhs3/rhs,
		lhs4/rhs
	}
end

e2function quaternion operator/(number lhs, quaternion rhs)
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	local l = rhs1*rhs1 + rhs2*rhs2 + rhs3*rhs3 + rhs4*rhs4
	return {
		( lhs * rhs1)/l,
		(-lhs * rhs2)/l,
		(-lhs * rhs3)/l,
		(-lhs * rhs4)/l
	}
end

e2function quaternion operator/(quaternion lhs, complex rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2 = rhs[1], rhs[2]
	local l = rhs1*rhs1 + rhs2*rhs2
	return {
		( lhs1 * rhs1 + lhs2 * rhs2)/l,
		(-lhs1 * rhs2 + lhs2 * rhs1)/l,
		( lhs3 * rhs1 - lhs4 * rhs2)/l,
		( lhs4 * rhs1 + lhs3 * rhs2)/l
	}
end

e2function quaternion operator/(complex lhs, quaternion rhs)
	local lhs1, lhs2 = lhs[1], lhs[2]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	local l = rhs1*rhs1 + rhs2*rhs2 + rhs3*rhs3 + rhs4*rhs4
	return {
		( lhs1 * rhs1 + lhs2 * rhs2)/l,
		(-lhs1 * rhs2 + lhs2 * rhs1)/l,
		(-lhs1 * rhs3 + lhs2 * rhs4)/l,
		(-lhs1 * rhs4 - lhs2 * rhs3)/l
	}
end

__e2setcost(10)
e2function quaternion operator/(quaternion lhs, quaternion rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	local l = rhs1*rhs1 + rhs2*rhs2 + rhs3*rhs3 + rhs4*rhs4
	return {
		( lhs1 * rhs1 + lhs2 * rhs2 + lhs3 * rhs3 + lhs4 * rhs4)/l,
		(-lhs1 * rhs2 + lhs2 * rhs1 - lhs3 * rhs4 + lhs4 * rhs3)/l,
		(-lhs1 * rhs3 + lhs3 * rhs1 - lhs4 * rhs2 + lhs2 * rhs4)/l,
		(-lhs1 * rhs4 + lhs4 * rhs1 - lhs2 * rhs3 + lhs3 * rhs2)/l
	}
end

__e2setcost(4)

e2function quaternion operator^(number lhs, quaternion rhs)
	if lhs == 0 then return { 0, 0, 0, 0 } end
	local l = log(lhs)
	return qexp({ l*rhs[1], l*rhs[2], l*rhs[3], l*rhs[4] })
end

e2function quaternion operator^(quaternion lhs, number rhs)
	local l = qlog(lhs)
	return qexp({ l[1]*rhs, l[2]*rhs, l[3]*rhs, l[4]*rhs })
end

registerOperator("indexget", "qn", "n", function(state, this, index)
	return this[math.Round(math.Clamp(index, 1, 4))]
end)

registerOperator("indexset", "qnn", "", function(state, this, index, value)
	this[math.Round(math.Clamp(index, 1, 4))] = value
	state.GlobalScope.vclk[this] = true
end)

__e2setcost(6)

e2function number operator==(quaternion lhs, quaternion rhs)
	return (lhs[1] == rhs[1]
		and lhs[2] == rhs[2]
		and lhs[3] == rhs[3]
		and lhs[4] == rhs[4])
		and 1 or 0
end

/******************************************************************************/

__e2setcost(4)

--- Returns absolute value of <q>
e2function number abs(quaternion q)
	return sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
end

--- Returns the conjugate of <q>
e2function quaternion conj(quaternion q)
	return {q[1], -q[2], -q[3], -q[4]}
end

--- Returns the inverse of <q>
e2function quaternion inv(quaternion q)
	local l = q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
	if l == 0 then return {0,0,0,0} end
	return { q[1]/l, -q[2]/l, -q[3]/l, -q[4]/l }
end

__e2setcost(1)

--- Returns the real component of the quaternion
e2function number quaternion:real()
	return this[1]
end

--- Returns the i component of the quaternion
e2function number quaternion:i()
	return this[2]
end

--- Returns the j component of the quaternion
e2function number quaternion:j()
	return this[3]
end

--- Returns the k component of the quaternion
e2function number quaternion:k()
	return this[4]
end

/******************************************************************************/

__e2setcost(7)

--- Raises Euler's constant e to the power <q>
e2function quaternion exp(quaternion q)
	return qexp(q)
end

--- Calculates natural logarithm of <q>
e2function quaternion log(quaternion q)
	return qlog(q)
end

__e2setcost(2)

--- Changes quaternion <q> so that the represented rotation is by an angle between 0 and 180 degrees (by coder0xff)
e2function quaternion qMod(quaternion q)
	if q[1]<0 then return {-q[1], -q[2], -q[3], -q[4]} else return {q[1], q[2], q[3], q[4]} end
end

__e2setcost(13)

--- Performs spherical linear interpolation between <q0> and <q1>. Returns <q0> for <t>=0, <q1> for <t>=1
--- Derived from c++ source on https://en.wikipedia.org/wiki/Slerp
e2function quaternion slerp(quaternion q0, quaternion q1, number t)
	local dot = qDot(q0, q1)

	if dot < 0 then
		q1 = {-q1[1], -q1[2], -q1[3], -q1[4]}
		dot = -dot
	end

	-- Really small theta, transcendental functions approximate to linear
	if dot > 0.9995 then
		local lerped = {
			q0[1] + t*(q1[1] - q0[1]),
			q0[2] + t*(q1[2] - q0[2]),
			q0[3] + t*(q1[3] - q0[3]),
			q0[4] + t*(q1[4] - q0[4]),
		}
		qNormalize(lerped)
		return lerped
	end

	local theta_0 = acos(dot)
	local theta = theta_0*t
	local sin_theta = sin(theta)
	local sin_theta_0 = sin(theta_0)

	local s0 = cos(theta) - dot * sin_theta / sin_theta_0
	local s1 = sin_theta / sin_theta_0

	local slerped = {
		q0[1]*s0 + q1[1]*s1,
		q0[2]*s0 + q1[2]*s1,
		q0[3]*s0 + q1[3]*s1,
		q0[4]*s0 + q1[4]*s1,
	}
	qNormalize(slerped)
	return slerped
end

--- Performs normalized linear interpolation between <q0> and <q1>. Returns normalized <q0> for <t>=0, normalized <q1> for <t>=1
e2function quaternion nlerp(quaternion q0, quaternion q1, number t)
	local t1 = 1 - t
	local q2
	if qDot(q0, q1) < 0 then
		q2 = { q0[1] * t1 - q1[1] * t, q0[2] * t1 - q1[2] * t, q0[3] * t1 - q1[3] * t, q0[4] * t1 - q1[4] * t }
	else
		q2 = { q0[1] * t1 + q1[1] * t, q0[2] * t1 + q1[2] * t, q0[3] * t1 + q1[3] * t, q0[4] * t1 + q1[4] * t }
	end

	qNormalize(q2)
	return q2
end

/******************************************************************************/
__e2setcost(7)

--- Returns vector pointing forward for <this>
e2function vector quaternion:forward()
	local this1, this2, this3, this4 = this[1], this[2], this[3], this[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector(
		this1 * this1 + this2 * this2 - this3 * this3 - this4 * this4,
		t3 * this2 + t4 * this1,
		t4 * this2 - t3 * this1
	)
end

--- Returns vector pointing right for <this>
e2function vector quaternion:right()
	local this1, this2, this3, this4 = this[1], this[2], this[3], this[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector(
		t4 * this1 - t2 * this3,
		this2 * this2 - this1 * this1 + this4 * this4 - this3 * this3,
		- t2 * this1 - t3 * this4
	)
end

--- Returns vector pointing up for <this>
e2function vector quaternion:up()
	local this1, this2, this3, this4 = this[1], this[2], this[3], this[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector(
		t3 * this1 + t2 * this4,
		t3 * this4 - t2 * this1,
		this1 * this1 - this2 * this2 - this3 * this3 + this4 * this4
	)
end

/******************************************************************************/
__e2setcost(9)

--- Returns quaternion for rotation about axis <axis> by angle <ang>
e2function quaternion qRotation(vector axis, ang)
	local ax = Vector(axis[1], axis[2], axis[3])
	ax:Normalize()
	local ang2 = ang*deg2rad*0.5
	return { cos(ang2), ax.x*sin(ang2), ax.y*sin(ang2), ax.z*sin(ang2) }
end

--- Construct a quaternion from the rotation vector <rv1>. Vector direction is axis of rotation, magnitude is angle in degress (by coder0xff)
e2function quaternion qRotation(vector rv1)
	local angSquared = rv1[1] * rv1[1] + rv1[2] * rv1[2] + rv1[3] * rv1[3]
	if angSquared == 0 then return { 1, 0, 0, 0 } end
	local len = sqrt(angSquared)
	local ang = (len + 180) % 360 - 180
	local ang2 = ang*deg2rad*0.5
	local sang2len = sin(ang2) / len
	return { cos(ang2), rv1[1] * sang2len , rv1[2] * sang2len, rv1[3] * sang2len }
end

--- Returns the angle of rotation in degrees (by coder0xff)
e2function number rotationAngle(quaternion q)
	local l2 = q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
	if l2 == 0 then return 0 end
	local l = sqrt(l2)
	local ang = 2*acos(math.Clamp(q[1]/l, -1, 1))*rad2deg  //this returns angle from 0 to 360
	if ang > 180 then ang = ang - 360 end  //make it -180 - 180
	return ang
end

--- Returns the axis of rotation (by coder0xff)
e2function vector rotationAxis(quaternion q)
	local m2 = q[2] * q[2] + q[3] * q[3] + q[4] * q[4]
	if m2 == 0 then return Vector(0, 0, 1) end
	local m = sqrt(m2)
	return Vector(q[2] / m, q[3] / m, q[4] / m)
end

--- Returns the rotation vector - rotation axis where magnitude is the angle of rotation in degress (by coder0xff)
e2function vector rotationVector(quaternion q)
	local l2 = q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4]
	local m2 = math.max( q[2]*q[2] + q[3]*q[3] + q[4]*q[4], 0 )
	if l2 == 0 or m2 == 0 then return Vector(0, 0, 0) end
	local s = 2 * acos( math.Clamp( q[1] / sqrt(l2), -1, 1 ) ) * rad2deg
	if s > 180 then s = s - 360 end
	s = s / sqrt(m2)
	return Vector( q[2] * s, q[3] * s, q[4] * s )
end

/******************************************************************************/
__e2setcost(3)

--- Converts <q> to a vector by dropping the real component
e2function vector vec(quaternion q)
	return Vector(q[2], q[3], q[4])
end

__e2setcost(15)

--- Converts <q> to a transformation matrix
e2function matrix matrix(quaternion q)
	local w,x,y,z = q[1],q[2],q[3],q[4]
	return {
		1 - 2*y*y - 2*z*z	 , 2*x*y - 2*z*w        , 2*x*z + 2*y*w,
		2*x*y + 2*z*w        , 1 - 2*x*x - 2*z*z	, 2*y*z - 2*x*w,
		2*x*z - 2*y*w        , 2*y*z + 2*x*w        , 1 - 2*x*x - 2*y*y
	}
end

--- Returns angle represented by <this>
e2function angle quaternion:toAngle()
	local l = sqrt(this[1]*this[1]+this[2]*this[2]+this[3]*this[3]+this[4]*this[4])
	if l == 0 then return Angle(0, 0, 0) end
	local q1, q2, q3, q4 = this[1]/l, this[2]/l, this[3]/l, this[4]/l

	local x = Vector(q1*q1 + q2*q2 - q3*q3 - q4*q4,
		2*q3*q2 + 2*q4*q1,
		2*q4*q2 - 2*q3*q1)

	local y = Vector(2*q2*q3 - 2*q4*q1,
		q1*q1 - q2*q2 + q3*q3 - q4*q4,
		2*q2*q1 + 2*q3*q4)

	local ang = x:Angle()
	if ang.p > 180 then ang.p = ang.p - 360 end
	if ang.y > 180 then ang.y = ang.y - 360 end

	local yyaw = Vector(0,1,0)
	yyaw:Rotate(Angle(0,ang.y,0))

	local roll = acos(math.Clamp(y:Dot(yyaw), -1, 1))*rad2deg

	local dot = q2*q1 + q3*q4
	if dot < 0 then roll = -roll end

	return Angle(ang.p, ang.y, roll)
end

--- Returns new normalized quaternion
e2function quaternion quaternion:normalized()
	return qGetNormalized(this)
end

--- Returns dot product of two quaternion
e2function number quaternion:dot(quaternion q1)
	return qDot(this, q1)
end

/******************************************************************************/
--- Formats <q> as a string.
e2function string toString(quaternion q)
	return format(q)
end

e2function string quaternion:toString()
	return format(this)
end
