local Q = WireLib.Quaternion

/******************************************************************************\
  Quaternion support
\******************************************************************************/

registerType("quaternion", "q", { 0, 0, 0, 0 },
	nil,
	nil,
	nil,
	function(v)
		return !istable(v) or #v ~= 4
	end
)
WireLib.registerDebuggerFormat("QUATERNION", Q.ToString)
/******************************************************************************/

__e2setcost(1)

--- Creates a zero quaternion
e2function quaternion quat()
	return Q.Zero()
end

--- Creates a quaternion with real part equal to <real>
e2function quaternion quat(real)
	return Q.New(real, 0, 0, 0)
end

--- Creates a quaternion with real and "i" parts equal to <c>
e2function quaternion quat(complex c)
	return Q.FromComplex(c)
end

--- Converts a vector to a quaternion (returns <imag>.x*i + <imag>.y*j + <imag>.z*k)
e2function quaternion quat(vector imag)
	return Q.FromVector(imag)
end

--- Returns <real>+<i>i+<j>j+<k>k
e2function quaternion quat(real, i, j, k)
	return Q.New(real, i, j, k)
end

__e2setcost(6)

--- Converts <ang> to a quaternion
e2function quaternion quat(angle ang)
	return Q.Quat(ang)
end

__e2setcost(15)

--- Creates a quaternion given forward (<forward>) and up (<up>) vectors
e2function quaternion quat(vector forward, vector up)
	return Q.QuatFromVectors(forward, up)
end

--- Converts angle of <ent> to a quaternion
e2function quaternion quat(entity ent)
	return Q.QuatFromEntity(ent)
end

__e2setcost(1)

--- Returns quaternion i
e2function quaternion qi()
	return Q.New(0, 1, 0, 0)
end

--- Returns quaternion <n>*i
e2function quaternion qi(n)
	return Q.New(0, n, 0, 0)
end

--- Returns j
e2function quaternion qj()
	return Q.New(0, 0, 1, 0)
end

--- Returns <n>*j
e2function quaternion qj(n)
	return Q.New(0, 0, n, 0)
end

--- Returns k
e2function quaternion qk()
	return Q.New(0, 0, 0, 1)
end

--- Returns <n>*k
e2function quaternion qk(n)
	return Q.New(0, 0, 0, n)
end

/******************************************************************************/

__e2setcost(4)

e2function quaternion operator_neg(quaternion q)
	return Q.Neg(q)
end

e2function quaternion operator+(quaternion lhs, quaternion rhs)
	return Q.Add(lhs, rhs)
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
	return Q.Sub(lhs, rhs)
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
	return Q.Scale(rhs, lhs)
end

e2function quaternion operator*(quaternion lhs, rhs)
	return Q.Scale(lhs, rhs)
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
	return Q.Mul(lhs, rhs)
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
	return Q.DivideByNumber(lhs, rhs)
end

e2function quaternion operator/(number lhs, quaternion rhs)
	return Q.NumberDivide(lhs, rhs)
end

e2function quaternion operator/(quaternion lhs, complex rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2 = rhs[1], rhs[2]
	local l = rhs1 * rhs1 + rhs2 * rhs2
	return {
		( lhs1 * rhs1 + lhs2 * rhs2) / l,
		(-lhs1 * rhs2 + lhs2 * rhs1) / l,
		( lhs3 * rhs1 - lhs4 * rhs2) / l,
		( lhs4 * rhs1 + lhs3 * rhs2) / l
	}
end

e2function quaternion operator/(complex lhs, quaternion rhs)
	local lhs1, lhs2 = lhs[1], lhs[2]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	local l = rhs1 * rhs1 + rhs2 * rhs2 + rhs3 * rhs3 + rhs4 * rhs4
	return {
		( lhs1 * rhs1 + lhs2 * rhs2) / l,
		(-lhs1 * rhs2 + lhs2 * rhs1) / l,
		(-lhs1 * rhs3 + lhs2 * rhs4) / l,
		(-lhs1 * rhs4 - lhs2 * rhs3) / l
	}
end

__e2setcost(10)

e2function quaternion operator/(quaternion lhs, quaternion rhs)
	return Q.Divide(lhs, rhs)
end

__e2setcost(4)

e2function quaternion operator^(number lhs, quaternion rhs)
	return Q.NumberPower(lhs, rhs)
end

e2function quaternion operator^(quaternion lhs, number rhs)
	return Q.Power(lhs, rhs)
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
	return Q.Abs(q)
end

--- Returns the conjugate of <q>
e2function quaternion conj(quaternion q)
	return Q.Conj(q)
end

--- Returns the inverse of <q>
e2function quaternion inv(quaternion q)
	return Q.Inv(q)
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
	return Q.Exp(q)
end

--- Calculates natural logarithm of <q>
e2function quaternion log(quaternion q)
	return Q.Log(q)
end

__e2setcost(2)

--- Changes quaternion <q> so that the represented rotation is by an angle between 0 and 180 degrees
e2function quaternion qMod(quaternion q)
	return Q.Mod(q)
end

__e2setcost(13)

--- Performs spherical linear interpolation between <q0> and <q1>. Returns <q0> for <t>=0, <q1> for <t>=1
e2function quaternion slerp(quaternion q0, quaternion q1, number t)
	return Q.Slerp(q0, q1, t)
end

--- Performs normalized linear interpolation between <q0> and <q1>. Returns normalized <q0> for <t>=0, normalized <q1> for <t>=1
e2function quaternion nlerp(quaternion q0, quaternion q1, number t)
	return Q.Nlerp(q0, q1, t)
end

/******************************************************************************/
__e2setcost(7)

--- Returns vector pointing forward for <this>
e2function vector quaternion:forward()
	return Q.Forward(this)
end

--- Returns vector pointing right for <this>
e2function vector quaternion:right()
	return Q.Right(this)
end

--- Returns vector pointing up for <this>
e2function vector quaternion:up()
	return Q.Up(this)
end

/******************************************************************************/
__e2setcost(9)

--- Returns quaternion for rotation about axis <axis> by angle <ang>
e2function quaternion qRotation(vector axis, ang)
	return Q.Rotation(axis, ang)
end

--- Construct a quaternion from the rotation vector <rv1>. Vector direction is axis of rotation, magnitude is angle in degress
e2function quaternion qRotation(vector rv1)
	return Q.RotationFromVector(rv1)
end

--- Returns the angle of rotation in degrees
e2function number rotationAngle(quaternion q)
	return Q.RotationAngle(q)
end

--- Returns the axis of rotation
e2function vector rotationAxis(quaternion q)
	return Q.RotationAxis(q)
end

--- Returns the rotation vector - rotation axis where magnitude is the angle of rotation in degress
e2function vector rotationVector(quaternion q)
	return Q.RotationVector(q)
end

/******************************************************************************/
__e2setcost(3)

--- Converts <q> to a vector by dropping the real component
e2function vector vec(quaternion q)
	return Q.ToVector(q)
end

__e2setcost(15)

--- Converts <q> to a transformation matrix
e2function matrix matrix(quaternion q)
	return Q.ToMatrix(q)
end

--- Returns angle represented by <this>
e2function angle quaternion:toAngle()
	return Q.ToAngle(this)
end

--- Returns new normalized quaternion
e2function quaternion quaternion:normalized()
	return Q.Normalized(this)
end

--- Returns dot product of two quaternion
e2function number quaternion:dot(quaternion q1)
	return Q.Dot(this, q1)
end

/******************************************************************************/
--- Formats <q> as a string.
e2function string toString(quaternion q)
	return Q.ToString(q)
end

e2function string quaternion:toString()
	return Q.ToString(this)
end
