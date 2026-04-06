--[[
	Quaternion gates
]]

GateActions("Quaternion")

local Round = math.Round
local unpack = unpack or table.unpack

local QZERO = { 0, 0, 0, 0 }
local QIDENT = { 1, 0, 0, 0 }

local function getQ()
	return WireLib and WireLib.Quaternion
end

local function isquat(q)
	local validator = WireLib and WireLib.DT and WireLib.DT.QUATERNION and WireLib.DT.QUATERNION.Validator
	if validator then return validator(q) end

	return istable(q)
		and isnumber(q[1])
		and isnumber(q[2])
		and isnumber(q[3])
		and isnumber(q[4])
end

local function qget(q, default)
	if isquat(q) then return q end
	return default or QZERO
end

local function qfmt(q)
	q = qget(q, QZERO)

	local Q = getQ()
	if Q and Q.ToString then
		return Q.ToString(q)
	end

	return string.format("(%s, %s, %s, %s)", tostring(q[1]), tostring(q[2]), tostring(q[3]), tostring(q[4]))
end

local function nfmt(n)
	if not isnumber(n) then return "0" end
	return tostring(Round(n * 1000) / 1000)
end

local function qnormalize_safe(q, fallback)
	q = qget(q, fallback or QIDENT)

	local Q = getQ()
	if not (Q and Q.Normalized) then
		return q
	end

	local normalized = Q.Normalized(q)
	if isquat(normalized) and (normalized[1] ~= 0 or normalized[2] ~= 0 or normalized[3] ~= 0 or normalized[4] ~= 0) then
		return normalized
	end

	return fallback or QIDENT
end

GateActions["quaternion_ident"] = {
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		return qget(A, QIDENT)
	end,
	label = function(Out, A)
		return qfmt(qget(A, QIDENT)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_add"] = {
	name = "Addition",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "QUATERNION", "QUATERNION", "QUATERNION", "QUATERNION", "QUATERNION", "QUATERNION", "QUATERNION", "QUATERNION" },
	compact_inputs = 2,
	outputtypes = { "QUATERNION" },
	output = function(gate, ...)
		local Q = getQ()
		if not Q then return QZERO end

		local sum = Q.Zero()
		for _, q in ipairs({ ... }) do
			if isquat(q) then
				sum = Q.Add(sum, q)
			end
		end
		return sum
	end,
	label = function(Out, ...)
		local tip = ""
		for _, q in ipairs({ ... }) do
			if isquat(q) then
				tip = tip .. " + " .. qfmt(q)
			end
		end
		if tip == "" then tip = "0" else tip = string.sub(tip, 4) end
		return tip .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_sub"] = {
	name = "Subtraction",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Sub(qget(A), qget(B))
	end,
	label = function(Out, A, B)
		return qfmt(qget(A)) .. " - " .. qfmt(qget(B)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_neg"] = {
	name = "Negate",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then
			A = qget(A)
			return { -(A[1] or 0), -(A[2] or 0), -(A[3] or 0), -(A[4] or 0) }
		end
		return Q.Neg(qget(A))
	end,
	label = function(Out, A)
		return "-" .. qfmt(qget(A)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_mul"] = {
	name = "Multiplication",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		if not Q then return QIDENT end
		return Q.Mul(qget(A, QIDENT), qget(B, QIDENT))
	end,
	label = function(Out, A, B)
		return qfmt(qget(A, QIDENT)) .. " * " .. qfmt(qget(B, QIDENT)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_scale"] = {
	name = "Scalar Multiplication",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Scale(qget(A), B or 0)
	end,
	label = function(Out, A, B)
		return qfmt(qget(A)) .. " * " .. nfmt(B or 0) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_divide"] = {
	name = "Division",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Divide(qget(A), qget(B))
	end,
	label = function(Out, A, B)
		return qfmt(qget(A)) .. " / " .. qfmt(qget(B)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_dividenum"] = {
	name = "Scalar Division",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		if not (Q and B and B ~= 0) then return QZERO end
		return Q.DivideByNumber(qget(A), B)
	end,
	label = function(Out, A, B)
		return qfmt(qget(A)) .. " / " .. nfmt(B or 0) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_power"] = {
	name = "Power",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		A = qget(A)
		B = B or 0

		if not (Q and isnumber(B)) then return QZERO end
		if Q.Abs(A) == 0 then return QZERO end

		return Q.Power(A, B)
	end,
	label = function(Out, A, B)
		return qfmt(qget(A)) .. " ^ " .. nfmt(B or 0) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_scalarpower"] = {
	name = "Scalar Power",
	inputs = { "A", "B" },
	inputtypes = { "NORMAL", "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B)
		local Q = getQ()
		A = A or 0
		B = qget(B)

		if not (Q and A ~= 0) then return QZERO end
		return Q.NumberPower(A, B)
	end,
	label = function(Out, A, B)
		return nfmt(A or 0) .. " ^ " .. qfmt(qget(B)) .. " = " .. qfmt(Out)
	end
}

GateActions["quaternion_abs"] = {
	name = "Magnitude",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return 0 end
		return Q.Abs(qget(A))
	end,
	label = function(Out, A)
		return "|" .. qfmt(qget(A)) .. "| = " .. nfmt(Out)
	end
}

GateActions["quaternion_conj"] = {
	name = "Conjugate",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then
			A = qget(A)
			return { A[1] or 0, -(A[2] or 0), -(A[3] or 0), -(A[4] or 0) }
		end
		return Q.Conj(qget(A))
	end,
	label = function(Out, A)
		return "conj(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_inv"] = {
	name = "Inverse",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Inv(qget(A))
	end,
	label = function(Out, A)
		return "inv(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_dot"] = {
	name = "Dot Product",
	inputs = { "A", "B" },
	inputtypes = { "QUATERNION", "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		local Q = getQ()
		if not Q then return 0 end
		return Q.Dot(qget(A), qget(B))
	end,
	label = function(Out, A, B)
		return "dot(" .. qfmt(qget(A)) .. ", " .. qfmt(qget(B)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_exp"] = {
	name = "Exp",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Exp(qget(A))
	end,
	label = function(Out, A)
		return "exp(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_log"] = {
	name = "Log",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Log(qget(A))
	end,
	label = function(Out, A)
		return "log(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_qmod"] = {
	name = "qMod",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return QZERO end
		return Q.Mod(qget(A))
	end,
	label = function(Out, A)
		return "qMod(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_normalized"] = {
	name = "Normalized",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A)
		return qnormalize_safe(qget(A), QIDENT)
	end,
	label = function(Out, A)
		return "normalized(" .. qfmt(qget(A)) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_slerp"] = {
	name = "Slerp",
	inputs = { "A", "B", "T" },
	inputtypes = { "QUATERNION", "QUATERNION", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B, T)
		local Q = getQ()
		if not Q then return QIDENT end
		A = qnormalize_safe(qget(A, QIDENT), QIDENT)
		B = qnormalize_safe(qget(B, QIDENT), QIDENT)
		return Q.Slerp(A, B, T or 0)
	end,
	label = function(Out, A, B, T)
		return "slerp(" .. qfmt(qget(A, QIDENT)) .. ", " .. qfmt(qget(B, QIDENT)) .. ", " .. nfmt(T or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_nlerp"] = {
	name = "Nlerp",
	inputs = { "A", "B", "T" },
	inputtypes = { "QUATERNION", "QUATERNION", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, A, B, T)
		local Q = getQ()
		if not Q then return QIDENT end
		A = qnormalize_safe(qget(A, QIDENT), QIDENT)
		B = qnormalize_safe(qget(B, QIDENT), QIDENT)
		return Q.Nlerp(A, B, T or 0)
	end,
	label = function(Out, A, B, T)
		return "nlerp(" .. qfmt(qget(A, QIDENT)) .. ", " .. qfmt(qget(B, QIDENT)) .. ", " .. nfmt(T or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_forward"] = {
	name = "Forward",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Vector(1, 0, 0) end
		return Q.Forward(qnormalize_safe(qget(A, QIDENT), QIDENT))
	end,
	label = function(Out, A)
		return "forward(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_right"] = {
	name = "Right",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Vector(0, -1, 0) end
		return Q.Right(qnormalize_safe(qget(A, QIDENT), QIDENT))
	end,
	label = function(Out, A)
		return "right(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_up"] = {
	name = "Up",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Vector(0, 0, 1) end
		return Q.Up(qnormalize_safe(qget(A, QIDENT), QIDENT))
	end,
	label = function(Out, A)
		return "up(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_qrotation"] = {
	name = "qRotation (Axis + Angle)",
	inputs = { "Axis", "Angle" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Axis, Angle)
		local Q = getQ()
		if not Q then return QIDENT end
		if not isvector(Axis) then Axis = Vector(0, 0, 1) end
		return Q.Rotation(Axis, Angle or 0)
	end,
	label = function(Out, Axis, Angle)
		return "qRotation(" .. tostring(Axis) .. ", " .. nfmt(Angle or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_qrotationvec"] = {
	name = "qRotation (Rotation Vector)",
	inputs = { "RV" },
	inputtypes = { "VECTOR" },
	outputtypes = { "QUATERNION" },
	output = function(gate, RV)
		local Q = getQ()
		if not Q then return QIDENT end
		if not isvector(RV) then RV = Vector(0, 0, 0) end
		return Q.RotationFromVector(RV)
	end,
	label = function(Out, RV)
		return "qRotation(" .. tostring(RV) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_rotationangle"] = {
	name = "Rotation Angle",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return 0 end
		return Q.RotationAngle(qget(A, QIDENT))
	end,
	label = function(Out, A)
		return "rotationAngle(" .. qfmt(qget(A, QIDENT)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_rotationaxis"] = {
	name = "Rotation Axis",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Vector(0, 0, 0) end
		return Q.RotationAxis(qget(A, QIDENT))
	end,
	label = function(Out, A)
		return "rotationAxis(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_rotationvector"] = {
	name = "Rotation Vector",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Vector(0, 0, 0) end
		return Q.RotationVector(qget(A, QIDENT))
	end,
	label = function(Out, A)
		return "rotationVector(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_vec"] = {
	name = "Vec",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		local Q = getQ()
		A = qget(A)
		if not Q then return Vector(A[2], A[3], A[4]) end
		return Q.ToVector(A)
	end,
	label = function(Out, A)
		return "vec(" .. qfmt(qget(A)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_toangle"] = {
	name = "To Angle",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return Angle(0, 0, 0) end
		return Q.ToAngle(qget(A, QIDENT))
	end,
	label = function(Out, A)
		return "toAngle(" .. qfmt(qget(A, QIDENT)) .. ") = " .. tostring(Out)
	end
}

GateActions["quaternion_tostring"] = {
	name = "To String",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		return qfmt(qget(A))
	end,
	label = function(Out, A)
		return "toString(" .. qfmt(qget(A)) .. ") = " .. Out
	end
}

GateActions["quaternion_matrix"] = {
	name = "Matrix",
	description = "Outputs the 3x3 rotation matrix as nine NORMAL outputs.",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputs = { "M11", "M12", "M13", "M21", "M22", "M23", "M31", "M32", "M33" },
	outputtypes = { "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL" },
	output = function(gate, A)
		local Q = getQ()
		if not Q then return 1,0,0,0,1,0,0,0,1 end
		return unpack(Q.ToMatrix(qget(A, QIDENT)))
	end,
	label = function(Out, A)
		return "matrix(" .. qfmt(qget(A, QIDENT)) .. ")"
	end
}

GateActions["quaternion_quat0"] = {
	name = "quat()",
	inputs = {},
	inputtypes = {},
	outputtypes = { "QUATERNION" },
	output = function(gate)
		local Q = getQ()
		return Q and Q.Zero() or QZERO
	end,
	label = function(Out)
		return "quat() = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_real"] = {
	name = "quat(real)",
	inputs = { "Real" },
	inputtypes = { "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Real)
		local Q = getQ()
		return Q and Q.New(Real or 0, 0, 0, 0) or { Real or 0, 0, 0, 0 }
	end,
	label = function(Out, Real)
		return "quat(" .. nfmt(Real or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_vec"] = {
	name = "quat(vector)",
	inputs = { "Imag" },
	inputtypes = { "VECTOR" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Imag)
		local Q = getQ()
		if not isvector(Imag) then Imag = Vector(0, 0, 0) end
		if not Q then return { 0, Imag.x, Imag.y, Imag.z } end
		return Q.FromVector(Imag)
	end,
	label = function(Out, Imag)
		return "quat(" .. tostring(Imag) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_compose"] = {
	name = "quat(real, i, j, k)",
	inputs = { "Real", "I", "J", "K" },
	inputtypes = { "NORMAL", "NORMAL", "NORMAL", "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Real, I, J, K)
		local Q = getQ()
		if not Q then return { Real or 0, I or 0, J or 0, K or 0 } end
		return Q.New(Real or 0, I or 0, J or 0, K or 0)
	end,
	label = function(Out, Real, I, J, K)
		return "quat(" .. nfmt(Real or 0) .. ", " .. nfmt(I or 0) .. ", " .. nfmt(J or 0) .. ", " .. nfmt(K or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_angle"] = {
	name = "quat(angle)",
	inputs = { "Angle" },
	inputtypes = { "ANGLE" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Ang)
		local Q = getQ()
		if not Q then return QIDENT end
		if not isangle(Ang) then Ang = Angle(0, 0, 0) end
		return Q.Quat(Ang)
	end,
	label = function(Out, Ang)
		return "quat(" .. tostring(Ang) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_vectors"] = {
	name = "quat(forward, up)",
	inputs = { "Forward", "Up" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "QUATERNION" },
	output = function(gate, Forward, Up)
		local Q = getQ()
		if not Q then return QIDENT end
		if not isvector(Forward) then Forward = Vector(1, 0, 0) end
		if not isvector(Up) then Up = Vector(0, 0, 1) end
		return Q.QuatFromVectors(Forward, Up)
	end,
	label = function(Out, Forward, Up)
		return "quat(" .. tostring(Forward) .. ", " .. tostring(Up) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_quat_entity"] = {
	name = "quat(entity)",
	inputs = { "Entity" },
	inputtypes = { "ENTITY" },
	outputtypes = { "QUATERNION" },
	timed = true,
	output = function(gate, Ent)
		local Q = getQ()
		return Q and Q.QuatFromEntity(Ent) or QIDENT
	end,
	label = function(Out, Ent)
		return "quat(" .. tostring(Ent) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_qi"] = {
	name = "qi()",
	inputs = {},
	inputtypes = {},
	outputtypes = { "QUATERNION" },
	output = function(gate)
		local Q = getQ()
		return Q and Q.New(0, 1, 0, 0) or { 0, 1, 0, 0 }
	end,
	label = function(Out)
		return "qi() = " .. qfmt(Out)
	end
}

GateActions["quaternion_qi_num"] = {
	name = "qi(n)",
	inputs = { "N" },
	inputtypes = { "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, N)
		local Q = getQ()
		return Q and Q.New(0, N or 0, 0, 0) or { 0, N or 0, 0, 0 }
	end,
	label = function(Out, N)
		return "qi(" .. nfmt(N or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_qj"] = {
	name = "qj()",
	inputs = {},
	inputtypes = {},
	outputtypes = { "QUATERNION" },
	output = function(gate)
		local Q = getQ()
		return Q and Q.New(0, 0, 1, 0) or { 0, 0, 1, 0 }
	end,
	label = function(Out)
		return "qj() = " .. qfmt(Out)
	end
}

GateActions["quaternion_qj_num"] = {
	name = "qj(n)",
	inputs = { "N" },
	inputtypes = { "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, N)
		local Q = getQ()
		return Q and Q.New(0, 0, N or 0, 0) or { 0, 0, N or 0, 0 }
	end,
	label = function(Out, N)
		return "qj(" .. nfmt(N or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_qk"] = {
	name = "qk()",
	inputs = {},
	inputtypes = {},
	outputtypes = { "QUATERNION" },
	output = function(gate)
		local Q = getQ()
		return Q and Q.New(0, 0, 0, 1) or { 0, 0, 0, 1 }
	end,
	label = function(Out)
		return "qk() = " .. qfmt(Out)
	end
}

GateActions["quaternion_qk_num"] = {
	name = "qk(n)",
	inputs = { "N" },
	inputtypes = { "NORMAL" },
	outputtypes = { "QUATERNION" },
	output = function(gate, N)
		local Q = getQ()
		return Q and Q.New(0, 0, 0, N or 0) or { 0, 0, 0, N or 0 }
	end,
	label = function(Out, N)
		return "qk(" .. nfmt(N or 0) .. ") = " .. qfmt(Out)
	end
}

GateActions["quaternion_real"] = {
	name = "Real",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		return qget(A)[1]
	end,
	label = function(Out, A)
		return "real(" .. qfmt(qget(A)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_i"] = {
	name = "I",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		return qget(A)[2]
	end,
	label = function(Out, A)
		return "i(" .. qfmt(qget(A)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_j"] = {
	name = "J",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		return qget(A)[3]
	end,
	label = function(Out, A)
		return "j(" .. qfmt(qget(A)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_k"] = {
	name = "K",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		return qget(A)[4]
	end,
	label = function(Out, A)
		return "k(" .. qfmt(qget(A)) .. ") = " .. nfmt(Out)
	end
}

GateActions["quaternion_convfrom"] = {
	name = "Decompose",
	description = "Splits a quaternion into four numbers.",
	inputs = { "A" },
	inputtypes = { "QUATERNION" },
	outputs = { "Real", "I", "J", "K" },
	outputtypes = { "NORMAL", "NORMAL", "NORMAL", "NORMAL" },
	output = function(gate, A)
		A = qget(A)
		return A[1], A[2], A[3], A[4]
	end,
	label = function(Out, A)
		return qfmt(qget(A)) .. " -> R:" .. nfmt(Out.Real) .. " I:" .. nfmt(Out.I) .. " J:" .. nfmt(Out.J) .. " K:" .. nfmt(Out.K)
	end
}

GateActions()
