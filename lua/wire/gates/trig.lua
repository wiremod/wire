--[[
		Trig Gates
]]

GateActions("Trig")

GateActions["quadratic"] = {
	name = "Quadratic Formula",
	description = "Solves for X in the quadratic equation.",
	inputs = { "A", "B", "C" },
	outputs = { "Pos", "Neg" },
	output = function(gate, A, B, C)
		local temp = math.sqrt(B^2 - 4*A*C)
		return (-B + temp) / (2*A), (-B - temp) / (2*A)
	end,
	label = function(Out,A,B,C)
		return ("AX^2 + BX + C\n(-%s +/- sqrt(%s^2 - 4*%s*%s)) / (2*%s) = %s,%s"):format( B, B, A, C, A, Out.Pos, Out.Neg )
	end
}

GateActions["sin"] = {
	name = "Sin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.sin(A)
	end,
	label = function(Out, A)
		return "sin("..A.."rad) = "..Out
	end
}

GateActions["cos"] = {
	name = "Cos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.cos(A)
	end,
	label = function(Out, A)
		return "cos("..A.."rad) = "..Out
	end
}

GateActions["tan"] = {
	name = "Tan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.tan(A)
	end,
	label = function(Out, A)
		return "tan("..A.."rad) = "..Out
	end
}

GateActions["asin"] = {
	name = "Asin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.asin(A)
	end,
	label = function(Out, A)
		return "asin("..A..") = "..Out.."rad"
	end
}

GateActions["acos"] = {
	name = "Acos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.acos(A)
	end,
	label = function(Out, A)
		return "acos("..A..") = "..Out.."rad"
	end
}

GateActions["atan"] = {
	name = "Atan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
		return math.atan(A)
	end,
	label = function(Out, A)
		return "atan("..A..") = "..Out.."rad"
	end
}

GateActions["sin_d"] = {
	name = "Sin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.sin(math.rad(A))
	end,
	label = function(Out, A)
		return "sin("..A.."deg) = "..Out
	end
}

GateActions["cos_d"] = {
	name = "Cos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.cos(math.rad(A))
	end,
	label = function(Out, A)
		return "cos("..A.."deg) = "..Out
	end
}

GateActions["tan_d"] = {
	name = "Tan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.tan(math.rad(A))
	end,
	label = function(Out, A)
		return "tan("..A.."deg) = "..Out
	end
}

GateActions["asin_d"] = {
	name = "Asin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.deg(math.asin(A))
	end,
	label = function(Out, A)
		return "asin("..A..") = "..Out.."deg"
	end
}

GateActions["acos_d"] = {
	name = "Acos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.deg(math.acos(A))
	end,
	label = function(Out, A)
		return "acos("..A..") = "..Out.."deg"
	end
}

GateActions["atan_d"] = {
	name = "Atan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
		return math.deg(math.atan(A))
	end,
	label = function(Out, A)
		return "atan("..A..") = "..Out.."deg"
	end
}

GateActions["rad2deg"] = {
	name = "Radians to Degrees",
	inputs = { "A" },
	output = function(gate, A)
		return math.deg(A)
	end,
	label = function(Out, A)
		return A.."rad = "..Out.."deg"
	end
}

GateActions["deg2rad"] = {
	name = "Degrees to Radians",
	inputs = { "A" },
	output = function(gate, A)
		return math.rad(A)
	end,
	label = function(Out, A)
		return A.."deg = "..Out.."rad"
	end
}

GateActions["angdiff"] = {
	name = "Difference(rad)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return math.rad(math.AngleDifference(math.deg(A), math.deg(B)))
	end,
	label = function(Out, A, B)
		return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}

GateActions["angdiff_d"] = {
	name = "Difference(deg)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return math.AngleDifference(A, B)
	end,
	label = function(Out, A, B)
		return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}

GateActions["atan2"] = {
	name = "Atan2",
	inputs = { "A", "B" },
	output = function( gate, A, B )
		return math.atan2( A, B )
	end,
	label = function( Out, A, B )
		return "atan2(" .. A .. "," .. B .. ") = " .. Out
	end
}

GateActions()
