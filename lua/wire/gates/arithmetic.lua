--[[
		Arithmetic Gates
]]

GateActions("Arithmetic")

GateActions["increment"] = {
	name = "Increment",
	dsecription = "Increases its value by a number on every clk.",
	inputs = { "A", "Clk", "Reset" },
	output = function(gate, A, Clk, Reset)
		local clk = ( Clk > 0 )
		local reset = ( Reset > 0 )

		if ( gate.PrevValue ~= clk ) then
			gate.PrevValue = clk
			if ( clk ) then
				if ( gate.Memory == nil ) then
					gate.Memory = A
				else
					gate.Memory = gate.Memory + A
				end
			end
		end

		if( gate.PrevReset ~= reset ) then
			gate.PrevReset = reset
			if ( reset ) then
				gate.Memory = 0
			end
		end

		return gate.Memory
	end,
	label = function(Out, A)
		return "LastNum += " .. A .. " = " .. Out
	end
}

GateActions["identity"] = {
	name = "Identity (No change)",
	inputs = { "A" },
	output = function(gate, A)
		return A
	end,
	label = function(Out, A)
		return A.." = "..Out
	end
}

GateActions["negate"] = {
	name = "Negate",
	inputs = { "A" },
	output = function(gate, A)
		return -A
	end,
	label = function(Out, A)
		return "-"..A.." = "..Out
	end
}

GateActions["inverse"] = {
	name = "Inverse",
	inputs = { "A" },
	output = function(gate, A)
		if (A) and (math.abs(A) >= 0.0001) then return 1/A end
		return 0
	end,
	label = function(Out, A)
		return "1/"..A.." = "..Out
	end
}

GateActions["sqrt"] = {
	name = "Square Root",
	inputs = { "A" },
	output = function(gate, A)
		return math.sqrt(math.abs(A)) -- Negatives are possible, use absolute value
	end,
	label = function(Out, A)
		--[[if ( A < 0 ) then
			return "sqrt("..A..") = i"..Out -- Display as imaginary if A is negative
		else]]
			return "sqrt("..A..") = "..Out
		--end
	end
}

GateActions["log"] = {
	name = "Log",
	inputs = { "A" },
	output = function(gate, A)
		return math.log(A)
	end,
	label = function(Out, A)
		return "log("..A..") = "..Out
	end
}

GateActions["log10"] = {
	name = "Log 10",
	inputs = { "A" },
	output = function(gate, A)
		return math.log10(A)
	end,
	label = function(Out, A)
		return "log10("..A..") = "..Out
	end
}

GateActions["abs"] = {
	name = "Absolute",
	inputs = { "A" },
	output = function(gate, A)
		return math.abs(A)
	end,
	label = function(Out, A)
		return "abs("..A..") = "..Out
	end
}

GateActions["sgn"] = {
	name = "Sign (-1,0,1)",
	inputs = { "A" },
	output = function(gate, A)
		if (A > 0) then return 1 end
		if (A < 0) then return -1 end
		return 0
	end,
	label = function(Out, A)
		return "sgn("..A..") = "..Out
	end
}

GateActions["floor"] = {
	name = "Floor (Round down)",
	inputs = { "A" },
	output = function(gate, A)
		return math.floor(A)
	end,
	label = function(Out, A)
		return "floor("..A..") = "..Out
	end
}

GateActions["round"] = {
	name = "Round",
	inputs = { "A" , "B" },
	output = function(gate, A, B)
		if B then
			B=math.Clamp(B,-50,50)
			return math.Round(A,B)
		else
			return math.Round(A)
		end
	end,
	label = function(Out, A , B)
		return "round("..A..","..B..") = "..Out
	end
}

GateActions["ceil"] = {
	name = "Ceiling (Round up)",
	inputs = { "A" },
	output = function(gate, A)
		return math.ceil(A)
	end,
	label = function(Out, A)
		return "ceil("..A..") = "..Out
	end
}

GateActions["+"] = {
	name = "Add",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 0
		for k,v in ipairs({...}) do
			if (v) then result = result+v end
		end
		return result
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." + " end
		end
		return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["-"] = {
	name = "Subtract",
	inputs = { "A", "B" },
	colors = { Color(255, 0, 0, 255), Color(0, 0, 255, 255) },
	output = function(gate, A, B)
		return A-B
	end,
	label = function(Out, A, B)
		return A.." - "..B.." = "..Out
	end
}

GateActions["*"] = {
	name = "Multiply",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 1
		for k,v in ipairs({...}) do
			if (v) then result = result*v end
		end
		return result
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." * " end
		end
		return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["/"] = {
	name = "Divide",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (math.abs(B) < 0.0001) then return 0 end
		return A/B
	end,
	label = function(Out, A, B)
		return A.." / "..B.." = "..Out
	end
}

GateActions["%"] = {
	name = "Modulo",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if ( B == 0 ) then return 0 end
		return math.fmod(A,B)
	end,
	label = function(Out, A, B)
		return A.." % "..B.." = "..Out
	end
}

GateActions["rand"] = {
	name = "Random",
	inputs = { "A", "B" },
	timed = true,
	output = function(gate, A, B)
		return math.random()*(B-A)+A
	end,
	label = function(Out, A, B)
		return "random("..A.." - "..B..") = "..Out
	end
}

GateActions["PI"] = {
	name = "PI",
	inputs = { },
	output = function(gate)
		return math.pi
	end,
	label = function(Out)
		return "PI = "..Out
	end
}

GateActions["exp"] = {
	name = "Exp",
	description = "Outputs e to the power of A.",
	inputs = { "A" },
	output = function(gate, A)
		return math.exp(A)
	end,
	label = function(Out, A)
		return "exp("..A..") = "..Out
	end
}

GateActions["pow"] = {
	name = "Exponential Powers",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return A ^ B
	end,
	label = function(Out, A, B)
		return "pow("..A..", "..B..") = "..Out
	end
}

GateActions["and/add"] = {
	name = "And/Add",
	inputs = { "A", "B"},
	output = function(gate, A, B)
		if ((A) and (A <= 0)) or ((B) and (B <= 0)) then return 0 end
		return A+B
	end,
	label = function(Out, A, B)
		return A.." and/and "..B.." = "..Out
	end
}

GateActions["Percent"] = {
	name = "Percent",
	inputs = { "Value", "Max" },
	compact_inputs = 2,
	output = function(gate, Value, Max)
		if (math.abs(Max) < 0.0001) then return 0 end
		return Value / Max * 100
	end,
	label = function(Out, Value, Max)
		return Value.." / "..Max.." * 100 = "..Out.."%"
	end
}

GateActions["Delta"] = {
	name = "Delta",
	description = "Gets the rate of change of the number.",
	inputs = { "A" },
	output = function(gate, A)
		gate.PrevValue = gate.PrevValue or 0
		local delta = A - gate.PrevValue
		gate.PrevValue = A
		return delta
	end,
	reset = function(gate)
		gate.PrevValue = 0
	end,
	label = function(Out, A)
		return "Delta("..A..") "
	end
}

GateActions["Delta360"] = {
	name = "Delta (Rectified)",
	inputs = { "A" },
	output = function(gate, A)
		gate.PrevValue = gate.PrevValue or 0
		local delta = A - gate.PrevValue
		gate.PrevValue = A
		return ( math.fmod( (math.fmod( delta, 360 ) + 540 ), 360 ) - 180 )
	end,
	reset = function(gate)
		gate.PrevValue = 0
	end,
	label = function(Out, A)
		return "Delta("..A..") "
	end
}

GateActions["Average"] = {
	name = "Average",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local vals = 0
		local value = 0
		for k,v in ipairs({...}) do
			vals = vals + 1
			value = value + v
		end
		return value / vals
	end,
	label = function(Out, ...)
		local vals = 0
		local message = "("
		for k,v in ipairs({...}) do
			vals = vals + 1
			message = message .. v .. " + "
		end
		message = string.sub(message,1,-4)
		message = message .. ") / " .. vals .. " = " .. Out
		return message
	end
}


GateActions["increment/decrement"] = {
	name = "Increment/Decrement",
	description = "Increases and decreases its value by a number.",
	inputs = { "A", "Increment", "Decrement", "Reset" },
	output = function(gate, A, Increment, Decrement, Reset)
		local increment = ( Increment > 0 )
		local decrement = ( Decrement > 0 )
		local reset = (Reset > 0)

		if ( gate.PrevValue ~= increment ) then
			gate.PrevValue = increment
			if ( increment ) then
				gate.Memory = (gate.Memory or 0) + A
			end
		end

		if ( gate.PrevValue ~= decrement ) then
			gate.PrevValue = decrement
			if ( decrement ) then
				gate.Memory = (gate.Memory or 0) - A
			end
		end

		if( gate.PrevReset ~= reset ) then
			gate.PrevReset = reset
			if ( reset ) then
				gate.Memory = 0
			end
		end

		return gate.Memory
	end,
	label = function(Out, A)
		return "(" .. A .. " +/- LastNum) = " .. Out
	end
}

GateActions["clamp"] = {
	group = "Arithmetic",
	name = "Clamp",
	inputs = { "A", "Min", "Max" },
	output = function( gate, A, Min, Max )
		return math.Clamp( A, Min, Max )
	end,
	label = function( Out, A, Min, Max )
		return "Clamp(" .. A .. "," .. Min .. "," .. Max .. ") = " .. Out
	end
}

GateActions()
