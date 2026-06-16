--[[
	Vector gates
]]

GateActions("Vector")

-- Add
GateActions["vector_add"] = {
	name = "Addition",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	compact_inputs = 2,
	outputtypes = { "VECTOR" },
	output = function(gate, ...)
		local sum = Vector (0, 0, 0)
		for _, v in pairs ({...}) do
			if (v and isvector (v)) then
				sum = sum + v
			end
		end
		return sum
	end,
	label = function(Out, ...)
		local tip = ""
		for _, v in ipairs ({...}) do
			if (v) then tip = tip .. " + " .. v end
		end
		return string.format ("%s = (%d,%d,%d)", string.sub (tip, 3),
			Out.x, Out.y, Out.z)
	end
}

-- Subtract
GateActions["vector_sub"] = {
	name = "Subtraction",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		return (A - B)
	end,
	label = function(Out, A, B)
		return string.format ("%s - %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

-- Negate
GateActions["vector_neg"] = {
	name = "Negate",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return Vector (-A.x, -A.y, -A.z)
	end,
	label = function(Out, A)
		return string.format ("-%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Multiply/Divide by constant
GateActions["vector_mul"] = {
	name = "Multiplication",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not A then A = Vector(0, 0, 0) end
		if not B then B = Vector(0, 0, 0) end
		return Vector( A.x * B.x, A.y * B.y, A.z * B.z )
	end,
	label = function(Out, A, B)
		return string.format ("%s * %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

GateActions["vector_divide"] = {
	name = "Division",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if (B) then
			return (A / B)
		end
		return Vector (0, 0, 0)
	end,
	label = function(Out, A, B)
		return string.format ("%s / %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

-- Dot/Cross Product
GateActions["vector_dot"] = {
	name = "Dot Product",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		return A:Dot (B)
	end,
	label = function(Out, A, B)
		return string.format ("dot(%s, %s) = %d", A, B, Out)
	end
}

GateActions["vector_cross"] = {
	name = "Cross Product",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		return A:Cross (B)
	end,
	label = function(Out, A, B)
		return string.format ("cross(%s, %s) = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

-- Yaw/Pitch
GateActions["vector_ang"] = {
	name = "Angles (Degree)",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputs = { "Yaw", "Pitch" },
	outputtypes = { "NORMAL", "NORMAL" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		local ang = A:Angle ()
		return ang.y, ang.p
	end,
	label = function(Out, A)
		return string.format ("ang(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
	end
}

-- Yaw/Pitch (Radian)
GateActions["vector_angrad"] = {
	name = "Angles (Radian)",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputs = { "Yaw", "Pitch" },
	outputtypes = { "NORMAL", "NORMAL" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		local ang = A:Angle ()
		return (ang.y * math.pi / 180), (ang.p * math.pi / 180)
	end,
	label = function(Out, A)
		return string.format ("angr(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
	end
}

-- Magnitude
GateActions["vector_mag"] = {
	name = "Magnitude",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return A:Length ()
	end,
	label = function(Out, A)
		return string.format ("|%s| = %d", A, Out)
	end
}

-- Conversion To/From
GateActions["vector_convto"] = {
	name = "Compose",
	description = "Combines three numbers into a vector.",
	inputs = { "X", "Y", "Z" },
	inputtypes = { "NORMAL", "NORMAL", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, X, Y, Z)
		return Vector (X, Y, Z)
	end,
	label = function(Out, X, Y, Z)
		return string.format ("vector(%s,%s,%s) = (%d,%d,%d)", X, Y, Z, Out.x, Out.y, Out.z)
	end
}

GateActions["vector_convfrom"] = {
	name = "Decompose",
	inputs = { "A" },
	description = "Splits an vector into three numbers.",
	inputtypes = { "VECTOR" },
	outputs = { "X", "Y", "Z" },
	outputtypes = { "NORMAL", "NORMAL", "NORMAL" },
	output = function(gate, A)
		if (A and isvector (A)) then
			return A.x, A.y, A.z
		end
		return 0, 0, 0
	end,
	label = function(Out, A)
		return string.format ("%s -> X:%d Y:%d Z:%d", A, Out.X, Out.Y, Out.Z)
	end
}

-- Normalise
GateActions["vector_norm"] = {
	name = "Normalise",
	description = "Outputs the vector adjusted to have a magnitude of 1.",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return A:GetNormal()
	end,
	label = function(Out, A)
		return string.format( "norm(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z )
		--return "norm(" .. A .. ") = [" .. math.Round(Out.x,3) .. "," .. math.Round(Out.y,3) .. "," .. math.Round(Out.z,3) .. "]"
	end
}

-- Identity
GateActions["vector_ident"] = {
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return A
	end,
	label = function(Out, A)
		return string.format ("%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Random (really needed?)
GateActions["vector_rand"] = {
	name = "Random",
	inputs = { },
	inputtypes = { },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate)
		local vec = Vector (math.random (), math.random (), math.random ())
		vec:Normalize()
		return vec
	end,
	label = function(Out)
		return "Random Vector"
	end
}

-- Component Derivative
GateActions["vector_derive"] = {
	name = "Delta",
	description = "Outputs the rate of change of the vector.",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if not isvector (A) then A = Vector (0, 0, 0) end
		local dT, dA = t - gate.LastT, A - gate.LastA
		gate.LastT, gate.LastA = t, A
		if dT ~= 0 then
			return Vector (dA.x/dT, dA.y/dT, dA.z/dT)
		else
			return Vector (0, 0, 0)
		end
	end,
	reset = function(gate)
		gate.LastT, gate.LastA = CurTime (), Vector (0, 0, 0)
	end,
	label = function(Out, A)
		return string.format ("diff(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Component Integral
GateActions["vector_cint"] = {
	name = "Component Integral",
	description = "Integrates the vector.",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if not isvector (A) then A = Vector (0, 0, 0) end
		local dT = t - (gate.LastT or t)
		gate.LastT, gate.Integral = t, (gate.Integral or Vector (0, 0, 0)) + A * dT
		-- Lifted (kinda) from wiregates.lua to prevent massive values
		local TempInt = gate.Integral:Length ()
		if (TempInt > 100000) then
			gate.Integral = gate.Integral:GetNormalized() * 100000
		end
		if (TempInt < -100000) then
			gate.Integral = gate.Integral:GetNormalized() * -100000
		end
		return gate.Integral
	end,
	reset = function(gate)
		gate.Integral, gate.LastT = Vector (0, 0, 0), CurTime()
	end,
	label = function(Out, A)
		return string.format ("int(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Multiplexer
GateActions["vector_mux"] = {
	name = "Multiplexer",
	description = "Selects between 8 different vectors based on a number.",
	inputs = { "Sel", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	compact_inputs = 3,
	outputtypes = { "VECTOR" },
	output = function(gate, Sel, ...)
		if isnumber(Sel) then -- If Sel is unwired, because of compact_inputs 3, it will become the first vector input, so just return Vector(0,0,0)
			Sel = math.floor(Sel)
			if Sel > 0 and Sel <= 8 then
				return ({...})[Sel]
			end
		end
		return Vector (0, 0, 0)
	end,
	label = function(Out, Sel, ...)
		return string.format ("Select: %s  Out: (%d,%d,%d)",
			Sel, Out.x, Out.y, Out.z)
	end
}

-- Demultiplexer
GateActions["vector_dmx"] = {
	name = "Demultiplexer",
	description = "Outputs a vector to one of 8 outputs based on a number.",
	inputs = { "Sel", "In" },
	inputtypes = { "NORMAL", "VECTOR" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	output = function(gate, Sel, In)
		local Out = { Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0),
			Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0) }
		Sel = math.floor (Sel)
		if (Sel > 0 and Sel <= 8) then
			Out[Sel] = In
		end
		return unpack (Out)
	end,
	label = function(Out, Sel, In)
		if not isvector (In) then In = Vector (0, 0, 0) end
		if not Sel then Sel = 0 end
		return string.format ("Select: %s, In: (%d,%d,%d)",
			Sel, In.x, In.y, In.z)
	end
}

-- Latch
GateActions["vector_latch"] = {
	name = "Latch",
	description = "Stores a vector when Clk is nonzero.",
	inputs = { "In", "Clk" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, In, Clk)
		Clk = (Clk > 0)
		if (gate.PrevClk ~= Clk) then
			gate.PrevClk = Clk
			if (Clk) then
				if not isvector (In) then In = Vector (0, 0, 0) end
				gate.LatchStore = In
			end
		end
		return gate.LatchStore or Vector (0, 0, 0)
	end,
	reset = function(gate)
		gate.LatchStore = Vector (0, 0, 0)
		gate.PrevValue = 0
	end,
	label = function(Out, In, Clk)
		return string.format ("Latch Data: %s  Clock: %s  Out: (%d,%d,%d)",
			In, Clk, Out.x, Out.y, Out.z)
	end
}

-- D-latch
GateActions["vector_dlatch"] = {
	name = "D-Latch",
	description = "Stores a vector when Clk changes and is nonzero.",
	inputs = { "In", "Clk" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, In, Clk)
		if (Clk > 0) then
			if not isvector (In) then In = Vector (0, 0, 0) end
			gate.LatchStore = In
		end
		return gate.LatchStore or Vector (0, 0, 0)
	end,
	reset = function(gate)
		gate.LatchStore = Vector (0, 0, 0)
	end,
	label = function(Out, In, Clk)
		return string.format ("Latch Data: %s  Clock: %s  Out: (%d,%d,%d)",
			In, Clk, Out.x, Out.y, Out.z)
	end
}

-- Equal
GateActions["vector_compeq"] = {
	name = "Equal",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
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
GateActions["vector_compineq"] = {
	name = "Not Equal",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if (A == B) then return 0 end
		return 1
	end,
	label = function(Out, A, B)
		return string.format ("(%s != %s) = %d", A, B, Out)
	end
}

-- Less-than
GateActions["vector_complt"] = {
	name = "Less Than",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if (A:Length () < B:Length ()) then return 1 end
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| < |%s|) = %d", A, B, Out)
	end
}

-- Less-than or Equal-to
GateActions["vector_complteq"] = {
	name = "Less Than or Equal To",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if (A:Length () <= B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| <= |%s|) = %d", A, B, Out)
	end
}

-- Greater-than
GateActions["vector_compgt"] = {
	name = "Greater Than",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if (A:Length () > B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| > |%s|) = %d", A, B, Out)
	end
}

-- Greater-than or Equal-to
GateActions["vector_compgteq"] = {
	name = "Greater Than or Equal To",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	output = function(gate, A, B)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if (A:Length () >= B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| >= |%s|) = %d", A, B, Out)
	end
}

-- Returns a positive vector.
GateActions["vector_positive"] = {
	name = "Positive",
	description = "Outputs a vector with its components converted to positive numbers.",
	inputs = { "A" },
	inputtypes = { "VECTOR"},
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return Vector(math.abs(A.x),math.abs(A.y),math.abs(A.z))
	end,
	label = function(Out, A)
		return string.format ("abs(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}


-- Returns a rounded vector.
GateActions["vector_round"] = {
	name = "Round",
	inputs = { "A" },
	inputtypes = { "VECTOR"},
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return Vector(math.Round(A.x),math.Round(A.y),math.Round(A.z))
	end,
	label = function(Out, A)
		return string.format ("round(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}


-- Returns the largest vector.
GateActions["vector_max"] = {
	name = "Largest",
	inputs = { "A" , "B" },
	inputtypes = { "VECTOR" , "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if A:Length() > B:Length() then return A else return B end
	end,
	label = function(Out, A , B)
		return string.format ("max(%s , %s) = (%d,%d,%d)", A , B, Out.x, Out.y, Out.z)
	end
}

-- Returns the smallest vector.
GateActions["vector_min"] = {
	name = "Smallest",
	inputs = { "A" , "B" },
	inputtypes = { "VECTOR" , "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if not isvector (B) then B = Vector (0, 0, 0) end
		if A:Length() < B:Length() then return A else return B end
	end,
	label = function(Out, A , B)
		return string.format ("min(%s , %s) = (%d,%d,%d)", A , B, Out.x, Out.y, Out.z)
	end
}

-- Shifts the components left.
GateActions["vector_shiftl"] = {
	name = "Shift Components Left",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return Vector(A.y,A.z,A.x)
	end,
	label = function(Out, A )
		return string.format ("shiftL(%s) = (%d,%d,%d)", A , Out.x, Out.y, Out.z)
	end
}

-- Shifts the components right.
GateActions["vector_shiftr"] = {
	name = "Shift Components Right",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		return Vector(A.z,A.x,A.y)
	end,
	label = function(Out, A )
		return string.format ("shiftR(%s) = (%d,%d,%d)", A , Out.x, Out.y, Out.z)
	end
}


-- Returns 1 if a vector is on world.
GateActions["vector_isinworld"] = {
	name = "Is In World",
	description = "Outputs 1 if a vector is within the world bounds.",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	output = function(gate, A)
		if not isvector (A) then A = Vector (0, 0, 0) end
		if util.IsInWorld(A) then return 1 else return 0 end
	end,
	label = function(Out, A )
		return string.format ("isInWorld(%s) = %d", A , Out)
	end
}

GateActions["vector_tostr"] = {
	name = "To String",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not isvector(A) then A = Vector (0, 0, 0) end
		return "["..tostring(A.x)..","..tostring(A.y)..","..tostring(A.z).."]"
	end,
	label = function(Out, A )
		return string.format ("toString(%s) = \""..Out.."\"", A)
	end
}

GateActions["vector_select"] = {
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, Choice, ...)
		Choice = math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}

GateActions["vector_rotate"] = {
	name = "Rotate",
	description = "Rotates a vector by the given angle.",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "ANGLE" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not A then A = Vector(0, 0, 0) end
		if not B then B = Angle(0, 0, 0) end
		A = Vector(A[1],A[2],A[3])
		A:Rotate(B)
		return A
	end,
	label = function(Out, A, B)
	    return string.format ("rotate(%s, %s) = "..tostring(Out), A, B )
	end
}

GateActions["vector_mulcomp"] = {
	name = "Multiplication (component)",
	description = "Multiplies a vector by a number.",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if not A then A = Vector(0, 0, 0) end
		if not B then B = 0 end
		return Vector( A.x * B, A.y * B, A.z * B )
	end,
	label = function(Out, A, B)
	    return string.format ("%s * %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z )
	end
}

GateActions["vector_clampn"] = {
	name = "Clamp (numbers)",
	description = "Clamps the vector's components between numbers Min and Max.",
	inputs = { "A", "Min", "Max" },
	inputtypes = { "VECTOR", "NORMAL", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function( gate, A, Min, Max )
		if (Min > Max) then Min, Max = Max, Min end
		return Vector( math.Clamp(A.x,Min,Max), math.Clamp(A.y,Min,Max), math.Clamp(A.z,Min,Max) )
	end,
	label = function( Out, A, Min, Max )
		return "Clamp(" .. A .. "," .. Min .. "," .. Max .. ") = " .. tostring(Out)
	end
}

GateActions["vector_clampv"] = {
	name = "Clamp (vectors)",
	description = "Clamps the vector between vectors Min and Max.",
	inputs = { "A", "Min", "Max" },
	inputtypes = { "VECTOR", "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function( gate, A, Min, Max )
		for i=1,3 do
			if (Min[i] > Max[i]) then
				Min[i], Max[i] = Max[i], Min[i]
			end
		end
		return Vector( math.Clamp(A.x,Min.x,Max.x), math.Clamp(A.y,Min.y,Max.y), math.Clamp(A.z,Min.z,Max.z) )
	end,
	label = function( Out, A, Min, Max )
		return "Clamp(" .. A .. "," .. Min .. "," .. Max .. ") = " .. tostring(Out)
	end
}

GateActions()
