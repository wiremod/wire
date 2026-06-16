--[[
	Angle gates
]]

GateActions("Angle")

-- Add
GateActions["angle_add"] = {
	name = "Addition",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE" },
	compact_inputs = 2,
	outputtypes = { "ANGLE" },
	output = function(gate, A , B , C , D , E , F , G , H)
		if !A then A = Angle (0, 0, 0) end
		if !B then B = Angle (0, 0, 0) end
		if !C then C = Angle (0, 0, 0) end
		if !D then D = Angle (0, 0, 0) end
		if !E then E = Angle (0, 0, 0) end
		if !F then F = Angle (0, 0, 0) end
		if !G then G = Angle (0, 0, 0) end
		if !H then H = Angle (0, 0, 0) end
		return (A + B + C + D + E + F + G + H)
	end,
	label = function(Out)
		return string.format ("Addition = (%d,%d,%d)",
			Out.p, Out.y, Out.r)
	end
}

-- Subtract
GateActions["angle_sub"] = {
	name = "Subtraction",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A, B)
		if !A then A = Angle (0, 0, 0) end
		if !B then B = Angle (0, 0, 0) end
		return (A - B)
	end,
	label = function(Out, A, B)
		return string.format ("%s - %s = (%d,%d,%d)", A, B, Out.p, Out.y, Out.r)
	end
}

-- Negate
GateActions["angle_neg"] = {
	name = "Negate",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return Angle (-A.p, -A.y, -A.r)
	end,
	label = function(Out, A)
		return string.format ("-%s = (%d,%d,%d)", A, Out.p, Out.y, Out.r)
	end
}

-- Multiply/Divide by constant
GateActions["angle_mul"] = {
	name = "Multiplication",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A, B)
		if !A then A = Angle (0, 0, 0) end
		if !B then B = Angle (0, 0, 0) end
		return Angle(A.p * B.p , A.y * B.y , A.r * B.r)
	end,
	label = function(Out, A, B)
		return string.format ("%s * %s = (%d,%d,%d)", A, B, Out.p, Out.y, Out.r)
	end
}

-- Component Derivative
GateActions["angle_derive"] = {
	name = "Delta",
	description = "Outputs the rate of change of the angle.",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if !A then A = Angle (0, 0, 0) end
		local dT, dA = t - gate.LastT, A - gate.LastA
		gate.LastT, gate.LastA = t, A
		if dT ~= 0 then
			return Angle (dA.p/dT, dA.y/dT, dA.r/dT)
		else
			return Angle (0, 0, 0)
		end
	end,
	reset = function(gate)
		gate.LastT, gate.LastA = CurTime (), Angle (0, 0, 0)
	end,
	label = function(Out, A)
		return string.format ("diff(%s) = (%d,%d,%d)", A, Out.p, Out.y, Out.r)
	end
}

GateActions["angle_divide"] = {
	name = "Division",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A, B)
		if !A then A = Angle (0, 0, 0) end
		if !B or B == Angle (0, 0, 0) then B = Angle (0, 0, 0) return B end
		return Angle(A.p / B.p , A.y / B.y , A.r / B.r)
	end,
	label = function(Out, A, B)
		return string.format ("%s / %s = (%d,%d,%d)", A, B, Out.p, Out.y, Out.r)
	end
}
-- Conversion To/From
GateActions["angle_convto"] = {
	name = "Compose",
	description = "Combines three numbers into an angle.",
	inputs = { "Pitch", "Yaw", "Roll" },
	inputtypes = { "NORMAL", "NORMAL", "NORMAL" },
	outputtypes = { "ANGLE" },
	output = function(gate, Pitch, Yaw, Roll)
		return Angle (Pitch, Yaw, Roll)
	end,
	label = function(Out, Pitch, Yaw, Roll)
		return string.format ("angle(%s,%s,%s) = (%d,%d,%d)", Pitch, Yaw, Roll, Out.p, Out.y, Out.r)
	end
}

GateActions["angle_convfrom"] = {
	name = "Decompose",
	description = "Splits an angle into three numbers.",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputs = { "Pitch", "Yaw", "Roll" },
	output = function(gate, A)
		if A then
			return A.p, A.y, A.r
		end
		return 0, 0, 0
	end,
	label = function(Out, A)
		return string.format ("%s -> Pitch:%d Yaw:%d Roll:%d", A, Out.Pitch, Out.Yaw, Out.Roll)
	end
}

-- Identity
GateActions["angle_ident"] = {
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return A
	end,
	label = function(Out, A)
		return string.format ("%s = (%d,%d,%d)", A, Out.p, Out.y, Out.r)
	end
}

-- Shifts the components left.
GateActions["angle_shiftl"] = {
	name = "Shift Components Left",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return Angle(A.y,A.r,A.p)
	end,
	label = function(Out, A )
		return string.format ("shiftL(%s) = (%d,%d,%d)", A , Out.p, Out.y, Out.r)
	end
}

-- Shifts the components right.
GateActions["angle_shiftr"] = {
	name = "Shift Components Right",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return Angle(A.r,A.p,A.y)
	end,
	label = function(Out, A )
		return string.format ("shiftR(%s) = (%d,%d,%d)", A , Out.p, Out.y, Out.r)
	end
}

GateActions["angle_fruvecs"] = {
	name = "Direction - (forward, up, right)",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputs = { "Forward", "Up" , "Right" },
	outputtypes = { "VECTOR" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, A )
		if !A then return Vector(0,0,0) , Vector(0,0,0) , Vector(0,0,0) else return A:Forward() , A:Up() , A:Right() end
	end,
	label = function(Out)
		return string.format ("Forward = (%f , %f , %f)\nUp = (%f , %f , %f)\nRight = (%f , %f , %f)", Out.Forward.x , Out.Forward.y , Out.Forward.z, Out.Up.x , Out.Up.y , Out.Up.z, Out.Right.x , Out.Right.y , Out.Right.z)
	end
}

GateActions["angle_norm"] = {
	name = "Normalize",
	description = "Makes the angle fit within +/-180 degrees.",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return Angle(math.NormalizeAngle(A.p),math.NormalizeAngle(A.y),math.NormalizeAngle(A.r))
	end,
	label = function(Out, A )
		return string.format ("normalize(%s) = (%d,%d,%d)", A , Out.p, Out.y, Out.r)
	end
}

GateActions["angle_tostr"] = {
	name = "To String",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return "["..tostring(A.p)..","..tostring(A.y)..","..tostring(A.r).."]"
	end,
	label = function(Out, A )
		return string.format ("toString(%s) = \""..Out.."\"", A)
	end
}


-- Equal
GateActions["angle_compeq"] = {
	name = "Equal",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "ANGLE" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if (A == B) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(%s == %s) = %d", A, B, Out)
	end
}

-- Not Equal
GateActions["angle_compineq"] = {
	name = "Not Equal",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "ANGLE" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if (A == B) then return 0 end
		return 1
	end,
	label = function(Out, A, B)
		return string.format ("(%s != %s) = %d", A, B, Out)
	end
}

-- Returns a rounded angle.
GateActions["angle_round"] = {
	name = "Round",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle(0, 0, 0) end
		return Angle(math.Round(A.p),math.Round(A.y),math.Round(A.r))
	end,
	label = function(Out, A)
		return string.format ("round(%s) = (%d,%d,%d)", A, Out.p, Out.y, Out.r)
	end
}

GateActions["angle_select"] = {
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, Choice, ...)
		Choice = math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}


GateActions["angle_mulcomp"] = {
	name = "Multiplication (component)",
	inputs = { "A", "B" },
	inputtypes = { "ANGLE", "NORMAL" },
	outputtypes = { "ANGLE" },
	output = function(gate, A, B)
		if !A then A = Angle(0, 0, 0) end
		if !B then B = 0 end
		return Angle( A.p * B, A.y * B, A.r * B )
	end,
	label = function(Out, A, B)
	    return string.format ("%s * %s = "..tostring(Out), A, B )
	end
}

GateActions["angle_clampn"] = {
	name = "Clamp (numbers)",
	inputs = { "A", "Min", "Max" },
	inputtypes = { "ANGLE", "NORMAL", "NORMAL" },
	outputtypes = { "ANGLE" },
	output = function( gate, A, Min, Max )
		if (Min > Max) then Min, Max = Max, Min end
		return Angle( math.Clamp(A.p,Min,Max), math.Clamp(A.y,Min,Max), math.Clamp(A.r,Min,Max) )
	end,
	label = function( Out, A, Min, Max )
		return "Clamp(" .. A .. "," .. Min .. "," .. Max .. ") = " .. tostring(Out)
	end
}

GateActions["angle_clampa"] = {
	name = "Clamp (angles)",
	inputs = { "A", "Min", "Max" },
	inputtypes = { "ANGLE", "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function( gate, A, Min, Max )
		if (Min.p > Max.p) then Min.p, Max.p = Max.p, Min.p end
		if (Min.y > Max.y) then Min.y, Max.y = Max.y, Min.y end
		if (Min.r > Max.r) then Min.r, Max.r = Max.r, Min.r end
		return Angle( math.Clamp(A.p,Min.p,Max.p), math.Clamp(A.y,Min.y,Max.y), math.Clamp(A.r,Min.r,Max.r) )
	end,
	label = function( Out, A, Min, Max )
		return "Clamp(" .. A .. "," .. Min .. "," .. Max .. ") = " .. tostring(Out)
	end
}

GateActions()
