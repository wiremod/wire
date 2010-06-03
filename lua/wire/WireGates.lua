--***********************************************************
--		Gate Action Functions Module
--			define all gate actions here
--	TODO: loader function to grab external gate action defines
--***********************************************************
GateActions = {}




--***********************************************************
--		Arithmetic Gates
--***********************************************************
GateActions["increment"] = {
	group = "Arithmetic",
	name = "Increment",
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
					gate.Memory = gate.Memory + 1
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
		return "(" .. A .. " + LastNum)++ = " .. Out
	end
}

GateActions["identity"] = {
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
	name = "Round",
	inputs = { "A" },
	output = function(gate, A)
		return math.Round(A)
	end,
	label = function(Out, A)
		return "round("..A..") = "..Out
	end
}

GateActions["ceil"] = {
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
	name = "Exp",
	inputs = { "A" },
	output = function(gate, A)
		return math.exp(A)
	end,
	label = function(Out, A)
		return "exp("..A..") = "..Out
	end
}

GateActions["pow"] = {
	group = "Arithmetic",
	name = "Exponential Powers",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return math.pow(A, B)
	end,
	label = function(Out, A, B)
		return "pow("..A..", "..B..") = "..Out
	end
}

GateActions["and/add"] = {
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
	name = "Delta",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
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
	group = "Arithmetic",
	name = "Increment/Decrement",
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




--***********************************************************
--		Comparison Gates
--***********************************************************
GateActions["="] = {
	group = "Comparison",
	name = "Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (math.abs(A-B) < 0.001) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return A.." == "..B.." = "..Out
	end
}

GateActions["!="] = {
	group = "Comparison",
	name = "Not Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (math.abs(A-B) < 0.001) then return 0 end
		return 1
	end,
	label = function(Out, A, B)
		return A.." ~= "..B.." = "..Out
	end
}

GateActions["<"] = {
	group = "Comparison",
	name = "Less Than",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (A < B) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return A.." < "..B.." = "..Out
	end
}

GateActions[">"] = {
	group = "Comparison",
	name = "Greater Than",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (A > B) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return A.." > "..B.." = "..Out
	end
}

GateActions["<="] = {
	group = "Comparison",
	name = "Less or Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (A <= B) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return A.." <= "..B.." = "..Out
	end
}

GateActions[">="] = {
	group = "Comparison",
	name = "Greater or Equal",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if (A >= B) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return A.." >= "..B.." = "..Out
	end
}

GateActions["inrangei"] = {
	group = "Comparison",
	name = "Is In Range (Inclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		if (Max < Min) then
			local temp = Max
			Max = Min
			Min = temp
		end
		if ((Value >= Min) && (Value <= Max)) then return 1 end
		return 0
	end,
	label = function(Out, Min, Max, Value)
		return Min.." <= "..Value.." <= "..Max.." = "..Out
	end
}

GateActions["inrangee"] = {
	group = "Comparison",
	name = "Is In Range (Exclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		if (Max < Min) then
			local temp = Max
			Max = Min
			Min = temp
		end
		if ((Value > Min) && (Value < Max)) then return 1 end
		return 0
	end,
	label = function(Out, Min, Max, Value)
		return Min.." < "..Value.." < "..Max.." = "..Out
	end
}




--***********************************************************
--		Bitwise Gates
--***********************************************************

GateActions["bnot"] = {
	group = "Bitwise",
	name = "Not",
	inputs = { "A" },
	output = function(gate, A)
		return (-1)-A
	end,
	label = function(Out, A)
		return "not "..A.." = "..Out
	end
}

GateActions["bor"] = {
	group = "Bitwise",
	name = "Or",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return (A | B)
	end,
	label = function(Out, A, B)
		return A.." or "..B.." = "..Out
	end
}

GateActions["band"] = {
	group = "Bitwise",
	name = "And",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return (A & B)
	end,
	label = function(Out, A, B)
		return A.." and "..B.." = "..Out
	end
}

GateActions["bxor"] = {
	group = "Bitwise",
	name = "Xor",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return (A | B) & (-1-(A & B))
	end,
	label = function(Out, A, B)
		return A.." xor "..B.." = "..Out
	end
}

GateActions["bshr"] = {
	group = "Bitwise",
	name = "Bit shift right",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		RunString(string.format("garry_sucks = %d >> %d", A, B))
		return garry_sucks
	end,
	label = function(Out, A, B)
		return A.." >> "..B.." = "..Out
	end
}

GateActions["bshl"] = {
	group = "Bitwise",
	name = "Bit shift left",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		RunString(string.format("garry_sucks = %d << %d", A, B))
		return garry_sucks
	end,
	label = function(Out, A, B)
		return A.." << "..B.." = "..Out
	end
}

--***********************************************************
--		Logic Gates
--***********************************************************
GateActions["not"] = {
	group = "Logic",
	name = "Not (Invert)",
	inputs = { "A" },
	output = function(gate, A)
		if (A > 0) then return 0 end
		return 1
	end,
	label = function(Out, A)
		return "not "..A.." = "..Out
	end
}

GateActions["and"] = {
	group = "Logic",
	name = "And (All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		for k,v in ipairs({...}) do
			if (v) and (v <= 0) then return 0 end
		end
		return 1
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." and " end
		end
		return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["or"] = {
	group = "Logic",
	name = "Or (Any)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		for k,v in ipairs({...}) do
			if (v) and (v > 0) then return 1 end
		end
		return 0
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." or " end
		end
		return string.sub(txt, 1, -5).." = "..Out
	end
}

GateActions["xor"] = {
	group = "Logic",
	name = "Exclusive Or (Odd)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 0
		for k,v in ipairs({...}) do
			if (v) and (v > 0) then result = (1-result) end
		end
		return result
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." xor " end
		end
		return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["nand"] = {
	group = "Logic",
	name = "Not And (Not All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		for k,v in ipairs({...}) do
			if (v) and (v <= 0) then return 1 end
		end
		return 0
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." nand " end
		end
		return string.sub(txt, 1, -7).." = "..Out
	end
}

GateActions["nor"] = {
	group = "Logic",
	name = "Not Or (None)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		for k,v in ipairs({...}) do
			if (v) and (v > 0) then return 0 end
		end
		return 1
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." nor " end
		end
		return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["xnor"] = {
	group = "Logic",
	name = "Exclusive Not Or (Even)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 1
		for k,v in ipairs({...}) do
			if (v) and (v > 0) then result = (1-result) end
		end
		return result
	end,
	label = function(Out, ...)
		local txt = ""
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v.." xnor " end
		end
		return string.sub(txt, 1, -7).." = "..Out
	end
}




--***********************************************************
--		Memory Gates
--***********************************************************
GateActions["latch"] = {
	group = "Memory",
	name = "Latch (Edge triggered)",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = Data
			end
		end
		return gate.LatchStore or 0
	end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Data, Clk)
		return "Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["dlatch"] = {
	group = "Memory",
	name = "D-Latch",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		if (Clk > 0) then
			gate.LatchStore = Data
		end
		return gate.LatchStore or 0
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, Data, Clk)
		return "D-Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["srlatch"] = {
	group = "Memory",
	name = "SR-Latch",
	inputs = { "S", "R" },
	output = function(gate, S, R)
		if (S > 0) and (R <= 0) then
			gate.LatchStore = 1
		elseif (S <= 0) and (R > 0) then
			gate.LatchStore = 0
		end
		return gate.LatchStore
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, S, R)
		return "S:"..S.." R:"..R.." == "..Out
	end
}

GateActions["rslatch"] = {
	group = "Memory",
	name = "RS-Latch",
	inputs = { "S", "R" },
	output = function(gate, S, R)
		if (S > 0) and (R < 1) then
			gate.LatchStore = 1
		elseif (R > 0) then
			gate.LatchStore = 0
		end
		return gate.LatchStore
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, S, R)
		return "S:"..S.." R:"..R.." == "..Out
	end
}

GateActions["toggle"] = {
	group = "Memory",
	name = "Toggle (Edge triggered)",
	inputs = { "Clk", "OnValue", "OffValue" },
	output = function(gate, Clk, OnValue, OffValue)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = (not gate.LatchStore)
			end
		end

		if (gate.LatchStore) then return OnValue end
		return OffValue
	end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Clk, OnValue, OffValue)
		return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["wom4"] = {
	group = "Memory",
	name = "Write Only Memory(4 store)",
	inputs = { "Clk", "AddrWrite", "Data" },
	output = function( gate, Clk, AddrWrite, Data )
		AddrWrite = math.floor(tonumber(AddrWrite))
		if ( Clk > 0 ) then
			if ( AddrWrite >= 0 ) and ( AddrWrite < 4 ) then
				gate.LatchStore[AddrWrite] = Data
			end
		end
		return 0
	end,
	reset = function( gate )
		gate.LatchStore = {}
		for i = 0, 3 do
			gate.LatchStore[i] = 0
		end
	end,
	label = function()
		return "Write Only Memory - 4 store"
	end
}

GateActions["ram8"] = {
	group = "Memory",
	name = "RAM(8 store)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
			gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))

		if (Clk > 0) then
			if (AddrWrite >= 0) and (AddrWrite < 8) then
				gate.LatchStore[AddrWrite] = Data
			end
		end

		if (AddrRead < 0) or (AddrRead >= 8) then return 0 end

		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
		"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || (Address >= 8) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) || (Address >= 8) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram64"] = {
	group = "Memory",
	name = "RAM(64 store)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 64) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || (Address >= 64) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) || (Address >= 64) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram32k"] = {
	group = "Memory",
	name = "RAM(32kb)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 32768) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset )
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || (Address >= 32768) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) || (Address >= 32768) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram128k"] = {
	group = "Memory",
	name = "RAM(128kb)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 131072) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || (Address >= 131072) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) || (Address >= 131072) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram64x64"] = {
	group = "Memory",
	name = "RAM(64x64 store)",
	inputs = { "Clk", "AddrReadX", "AddrReadY", "AddrWriteX", "AddrWriteY", "Data", "Reset" },
	output = function(gate, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrReadX = math.floor(tonumber(AddrReadX))
		AddrReadY = math.floor(tonumber(AddrReadY))
		AddrWriteX = math.floor(tonumber(AddrWriteX))
		AddrWriteY = math.floor(tonumber(AddrWriteY))
		if (Clk > 0) then
			if (AddrWriteX >= 0) and (AddrWriteX < 64) or (AddrWriteY >= 0) and (AddrWriteY < 64) then
				gate.LatchStore[AddrWriteX + AddrWriteY*64] = Data
			end
		end

		if (AddrReadX < 0) or (AddrReadX >= 64) or (AddrReadY < 0) or (AddrReadY >= 64) then
			return 0
		end

		return gate.LatchStore[AddrReadX + AddrReadY*64] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data, Reset)
		return "WriteAddr:"..AddrWriteX..", "..AddrWriteY.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
		"\nReadAddr:"..AddrReadX..", "..AddrReadY.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) || (Address >= 4096) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) || (Address >= 4096) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["udcounter"] = {
	group = "Memory",
	name = "Up/Down Counter",
	inputs = { "Increment", "Decrement", "Clk", "Reset"},
	output = function(gate, Inc, Dec, Clk, Reset)
		local lInc = (Inc > 0)
		local lDec = (Dec > 0)
		local lClk = (Clk > 0)
		local lReset = (Reset > 0)
		if ((gate.PrevInc ~= lInc || gate.PrevDec ~= lDec || gate.PrevClk ~= lClk) && lClk) then
			if (lInc) and (!lDec) and (!lReset) then
				gate.countStore = (gate.countStore or 0) + 1
			elseif (!lInc) and (lDec) and (!lReset) then
				gate.countStore = (gate.countStore or 0) - 1
			end
			gate.PrevInc = lInc
			gate.PrevDec = lDec
			gate.PrevClk = lClk
		end
		if (lReset) then
			gate.countStore = 0
		end
		return gate.countStore
	end,
	label = function(Out, Inc, Dec, Clk, Reset)
		return "Increment:"..Inc.." Decrement:"..Dec.." Clk:"..Clk.." Reset:"..Reset.." = "..Out
	end
}

GateActions["togglewhile"] = {
	group = "Memory",
	name = "Toggle While(Edge triggered)",
	inputs = { "Clk", "OnValue", "OffValue", "While" },
	output = function(gate, Clk, OnValue, OffValue, While)
		local clk = (Clk > 0)

		if (While <= 0) then
			clk = false
			gate.LatchStore = false
		end

		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = (not gate.LatchStore)
			end
		end

		if (gate.LatchStore) then return OnValue end
		return OffValue
	end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Clk, OnValue, OffValue, While)
		return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.."  While:"..While.." = "..Out
	end
}




--***********************************************************
--		Selection Gates
--***********************************************************
GateActions["min"] = {
	group = "Selection",
	name = "Minimum (Smallest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		return math.min(unpack({...}))
	end,
	label = function(Out, ...)
		local txt = "min("
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v..", " end
		end
		return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["max"] = {
	group = "Selection",
	name = "Maximum (Largest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		return math.max(unpack({...}))
	end,
	label = function(Out, ...)
		local txt = "max("
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v..", " end
		end
		return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["minmax"] = {
	group = "Selection",
	name = "Value Range",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		local temp = Min
		if Min > Max then
			Min = Max
			Max = temp
		end
		if Value < Min then return Min end
		if Value > Max then return Max end
		return Value
	end,
	label = function(Out, Min, Max, Value)
		local temp = Min
		if Min > Max then
			Min = Max
			Max = temp
		end
		return "Min: "..Min.."  Max: "..Max.."  Value: "..Value.." = "..Out
	end
}

GateActions["if"] = {
	group = "Selection",
	name = "If Then Else",
	inputs = { "A", "B", "C" },
	output = function(gate, A, B, C)
		if (A) and (A > 0) then return B end
		return C
	end,
	label = function(Out, A, B, C)
		return "if "..A.." then "..B.." else "..C.." = "..Out
	end
}

GateActions["select"] = {
	group = "Selection",
	name = "Select (Choice)",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Choice, ...)
		local idx = math.floor(Choice)
		if (idx > 0) and (idx <= 8) then
			return ({...})[idx]
		end

		return 0
	end,
	label = function(Out, Choice)
		return "Select Choice:"..Choice.." Out:"..Out
	end
}

GateActions["router"] = {
	group = "Selection",
	name = "Router",
	inputs = { "Path", "Data" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Path, Data)
		local result = { 0, 0, 0, 0, 0, 0, 0, 0 }

		local idx = math.floor(Path)
		if (idx > 0) and (idx <= 8) then
			result[idx] = Data
		end

		return unpack(result)
	end,
	label = function(Out, Path, Data)
		return "Router Path:"..Path.." Data:"..Data
	end
}

local SegmentInfo = {
	None = { 0, 0, 0, 0, 0, 0, 0 },
	[0]  = { 1, 1, 1, 1, 1, 1, 0 },
	[1]  = { 0, 1, 1, 0, 0, 0, 0 },
	[2]  = { 1, 1, 0, 1, 1, 0, 1 },
	[3]  = { 1, 1, 1, 1, 0, 0, 1 },
	[4]  = { 0, 1, 1, 0, 0, 1, 1 },
	[5]  = { 1, 0, 1, 1, 0, 1, 1 },
	[6]  = { 1, 0, 1, 1, 1, 1, 1 },
	[7]  = { 1, 1, 1, 0, 0, 0, 0 },
	[8]  = { 1, 1, 1, 1, 1, 1, 1 },
	[9]  = { 1, 1, 1, 1, 0, 1, 1 },
}

GateActions["7seg"] = {
	group = "Selection",
	name = "7 Segment Decoder",
	inputs = { "A", "Clear" },
	outputs = { "A", "B", "C", "D", "E", "F", "G" },
	output = function(gate, A, Clear)
		if (Clear > 0) then return unpack(SegmentInfo.None) end

		local idx = math.fmod(math.abs(math.floor(A)), 10)
		if idx > #SegmentInfo then return unpack(SegmentInfo.None) end
		return unpack(SegmentInfo[idx]) -- same as: return SegmentInfo[idx][1], SegmentInfo[idx][2], ...
	end,
	label = function(Out, A)
		return "7-Seg In:" .. A .. " Out:" .. Out.A .. Out.B .. Out.C .. Out.D .. Out.E .. Out.F .. Out.G
	end
}

GateActions["timedec"] = {
	group = "Selection",
	name = "Time/Date decoder",
	inputs = { "Time", "Date" },
	outputs = { "Hours","Minutes","Seconds","Year","Day" },
	output = function(gate, Time, Date)
		return math.floor(Time / 3600),math.floor(Time / 60) % 60,math.floor(Time) % 60,math.floor(Date / 366),math.floor(Date) % 366
	end,
	label = function(Out, A)
		return "Date decoder"
	end
}


--***********************************************************
--		Time Gates
--***********************************************************
GateActions["accumulator"] = {
	group = "Time",
	name = "Accumulator",
	inputs = { "A", "Hold", "Reset" },
	timed = true,
	output = function(gate, A, Hold, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if (Reset > 0) then
			gate.Accum = 0
		elseif (Hold <= 0) then
			gate.Accum = gate.Accum+A*DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, A, Hold, Reset)
		return "A:"..A.." Hold:"..Hold.." Reset:"..Reset.." = "..Out
	end
}

GateActions["smoother"] = {
	group = "Time",
	name = "Smoother",
	inputs = { "A", "Rate" },
	timed = true,
	output = function(gate, A, Rate)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		local Delta = A-gate.Accum
		if (Delta > 0) then
			gate.Accum = gate.Accum+math.min(Delta, Rate*DeltaTime)
		elseif (Delta < 0) then
			gate.Accum = gate.Accum+math.max(Delta, -Rate*DeltaTime)
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, A, Rate)
		return "A:"..A.." Rate:"..Rate.." = "..Out
	end
}

GateActions["timer"] = {
	group = "Time",
	name = "Timer",
	inputs = { "Run", "Reset" },
	timed = true,
	output = function(gate, Run, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset)
		return "Run:"..Run.." Reset:"..Reset.." = "..Out
	end
}

GateActions["ostime"] = {
	group = "Time",
	name = "OS Time",
	inputs = { },
	timed = true,
	output = function(gate)
		return os.date("%H")*3600+os.date("%M")*60+os.date("%S")
	end,
	label = function(Out)
		return "OS Time = "..Out
	end
}

GateActions["osdate"] = {
	group = "Time",
	name = "OS Date",
	inputs = { },
	timed = true,
	output = function(gate)
		return os.date("%Y")*366+os.date("%j")
	end,
	label = function(Out)
		return "OS Date = "..Out
	end
}

GateActions["pulser"] = {
	group = "Time",
	name = "Pulser",
	inputs = { "Run", "Reset", "TickTime" },
	timed = true,
	output = function(gate, Run, Reset, TickTime)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= TickTime) then
				gate.Accum = gate.Accum - TickTime
				return 1
			end
		end
		return 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, TickTime)
		return "Run:"..Run.." Reset:"..Reset.."TickTime:"..TickTime.." = "..Out
	end
}

GateActions["squarepulse"] = {
	group = "Time",
	name = "Square Pulse",
	inputs = { "Run", "Reset", "PulseTime", "GapTime", "Min", "Max" },
	timed = true,
	output = function(gate, Run, Reset, PulseTime, GapTime, Min, Max)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime

		if (Reset > 0) then
			gate.Accum = 0
		elseif (Run > 0) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum <= PulseTime) then
				return Max
			end
			if (gate.Accum >= PulseTime + GapTime) then
				gate.Accum = 0
			end
		end
		return Min
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, PulseTime, GapTime)
		return "Run:"..Run.." Reset:"..Reset.." PulseTime:"..PulseTime.." GapTime:"..GapTime.." = "..Out
	end
}

GateActions["sawpulse"] = {
	group = "Time",
	name = "Saw Pulse",
	inputs = { "Run", "Reset", "SlopeRaiseTime", "PulseTime", "SlopeDescendTime", "GapTime", "Min", "Max" },
	timed = true,
	output = function(gate, Run, Reset, SlopeRaiseTime, PulseTime, SlopeDescendTime, GapTime, Min, Max)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime

		if (Reset > 0) then
			gate.Accum = 0
		elseif (Run > 0) then
			local val = Min
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= 0) && (gate.Accum < SlopeRaiseTime) then
				if (SlopeRaiseTime != 0) then
					val = Min + (Max-Min) * (gate.Accum-0) / SlopeRaiseTime
				end
			end
			if (gate.Accum >= SlopeRaiseTime) && (gate.Accum < SlopeRaiseTime+PulseTime) then
				return Max
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime) && (gate.Accum < SlopeRaiseTime+PulseTime+SlopeDescendTime) then
				if (SlopeDescendTime != 0) then
					val = Min + (Max-Min) * (gate.Accum-SlopeRaiseTime+PulseTime) / SlopeDescendTime
				end
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime+SlopeDescendTime) then
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime+SlopeDescendTime+GapTime) then
				gate.Accum = 0
			end
			return val
		end
		return Min
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, PulseTime, GapTime)
		return "Run:"..Run.." Reset:"..Reset.." PulseTime:"..PulseTime.." GapTime:"..GapTime.." = "..Out
	end
}


GateActions["derive"] = {
	group = "Time",
	name = "Derivative",
	inputs = {"A"},
	timed = false,
	output = function(gate, A)
		local t = CurTime()
		local dT = t - gate.LastT
		gate.LastT = t
		local dA = A - gate.LastA
		gate.LastA = A
		if (dT != 0) then
			return dA/dT
		else
			return 0;
		end
	end,
	reset = function(gate)
		gate.LastT = CurTime()
		gate.LastA = 0
	end,
	label = function(Out, A)
		return "d/dt["..A.."] = "..Out
	end
}

GateActions["delay"] = {
	group = "Time",
	name = "Delay",
	inputs = { "Clk", "Delay", "Hold", "Reset" },
	outputs = { "Out", "TimeElapsed", "Remaining" },
	timed = true,
	output = function(gate, Clk, Delay, Hold, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		local out = 0

		if ( Reset > 0 ) then
			gate.Stage = 0
			gate.Accum = 0
		end

		if ( gate.Stage == 1 ) then
			if ( gate.Accum >= Delay ) then
				gate.Stage = 2
				gate.Accum = 0
				out = 1
			else
				gate.Accum = gate.Accum+DeltaTime
			end
		elseif ( gate.Stage == 2 ) then
			if ( gate.Accum >= Hold ) then
				gate.Stage = 0
				gate.Accum = 0
				out = 0
			else
				out = 1
				gate.Accum = gate.Accum+DeltaTime
			end
		else
			if ( Clk > 0 ) then
				gate.Stage = 1
				gate.Accum = 0
			end
		end

		return out, gate.Accum, Delay-gate.Accum
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
		gate.Stage = 0
	end,
	label = function(Out, Clk, Delay, Hold, Reset)
		return "Clk: "..Clk.." Delay: "..Delay..
		"\nHold: "..Hold.." Reset: "..Reset..
		"\nTime Elapsed: "..Out.TimeElapsed.." = "..Out.Out
	end
}

GateActions["Definite Integral"] = {
	group = "Time",
	name = "Integral",
	inputs = { "A", "Points" },
	timed = true,
	output = function(gate, A, Points)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Points<=0) then
			Points=2
			data = {}
		end
		data = data or {}
		integral=A*DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Points
		end
		data[index]=integral
		i=0
		totalintegral=0
		while (i<Points) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Points
			whichIndex=whichIndex+1
			totalintegral=totalintegral+(data[whichIndex] or 0)
			i=i+1
		end
	return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Points)
		return "A: "..A.."   Points: "..Points.."   Output: "..Out
	end,
}

GateActions["Derivative"] = {
	group = "Time",
	name = "Derivative",
	inputs = { "A" },
	timed = true,
	output = function(gate, A)
		prev5Delta= (prev4Delta or .04)
		prev4Delta= (prev3Delta or .04)
		prev3Delta= (prev2Delta or .04)
		prev2Delta= (prevDelta or .04)
		prevDelta = (DeltaT or .04)
		-- begin block: set up DeltaValue time
		prevTime=currentTime
		currentTime=CurTime()
		if (prevTime==currentTime) then
			DeltaT=.04
		else
			DeltaT=currentTime-(prevTime or 0)
		end
		prev6Value=(prev5Value or A)
		prev5Value=(prev4Value or A)
		prev5Slope=(prev5Value-prev6Value)/prev5Delta
		prev4Value=(prev3Value or A)
		prev4Slope=(prev4Value-prev5Value)/prev4Delta
		prev3Value=(prev2Value or A)
		prev3Slope=(prev3Value-prev4Value)/prev3Delta
		prev2Value=(prevValue or A)
		prev2Slope=(prev2Value-prev3Value)/prev2Delta
		prevValue=(currentValue or A)
		prevSlope=(prevValue-prev2Value)/prevDelta
		currentValue=A
		currentSlope=(prevValue-currentValue)/DeltaT
		averageSlope=((currentSlope+prevSlope+prev2Slope+prev3Slope+prev4Slope+prev5Slope)/6)
		return averageSlope
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A)
		return "Input: "..currentValue.."   Previous: "..prevValue.."   Derivative: "..Out
	end,
}

GateActions["Indefinite Integral"] = {
	group = "Time",
	name = "Indefinite Integral",
	inputs = { "A", "Reset" },
	timed = true,
	output = function(gate, A, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Reset != 0) then
			totalintegral=0
		end
		integral=A*DeltaTime
		totalintegral = (totalintegral or 0) + integral
		if (totalintegral > 100000) then
			totalintegral = 100000
		end
		if (totalintegral < -100000) then
			totalintegral = -100000
		end
		return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Reset)
		return "A: "..A.."  Reset: "..Reset.."   Output: "..Out
	end,
}

GateActions["Average Derivative"] = {
	group = "Time",
	name = "Average Derivative",
	inputs = { "A", "Window" },
	timed = true,
	output = function(gate, A, Window)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Window<=0) then
			Window=2
			data = {}
		end
		data = data or {}
		prevA=currentA or A
		currentA=A
		derivative=(currentA-prevA)/DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Window
		end
		data[index]=derivative
		i=0
		sum=0
		while (i<Window) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Window
			whichIndex=whichIndex+1
			sum=sum+(data[whichIndex] or 0)
			i=i+1
		end
		averageDerivative=(sum/Window)
	return averageDerivative or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Window)
		return "A: "..A.."   Window: "..Window.."   Output: "..Out
	end,
}


GateActions["monostable"] = {
	group = "Time",
	name = "Monostable Timer",
	inputs = { "Run", "Time", "Reset" },
	timed = true,
	output = function(gate, Run, Time, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( gate.Accum > 0 || Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
			if(gate.Accum > Time) then
				gate.Accum = 0
			end
		end
		if(gate.Accum > 0)then
			return 1
		else
			return 0
		end
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Time, Reset)
		return "Run:"..Run.." Time:"..Time.." Reset:"..Reset.." = "..Out
	end
}

GateActions["bstimer"] = {
	group = "Time",
	name = "BS_Timer",
	inputs = { "Run", "Reset" },
	timed = true,
	output = function(gate, Run, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
		end

		for i = 1,50 do
			local bs = gate.Entity:GetPos()
			local bs1 = gate.Entity:GetAngles()
		end

		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset)
		return "Run:"..Run.." Reset:"..Reset.." = "..Out
	end
}

--***********************************************************
--		Trig Gates
--***********************************************************
GateActions["quadratic"] = {
	group = "Trig",
	name = "Quadratic Formula",
	inputs = { "A", "B", "C" },
	outputs = { "Pos", "Neg" },
	output = function(gate, A, B, C)
		return ( -B + ( math.sqrt( math.abs( math.exp( B, 2 ) - ( 4*A )*C ) ) ) / 2*A )
	end,
	output = function(gate, A, B, C)
		return ( -B - ( math.sqrt( math.abs( math.exp( B, 2 ) - ( 4*A )*C ) ) ) / 2*A )
	end,
	label = function(Out, A, B, C)
		return "-" .. A .. " +/- sqrt( " ..  B .. "^2 - ( 4*" .. A .. " )*" .. C .. " )  / 2*" .. A
	end
}

GateActions["sin"] = {
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
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
	group = "Trig",
	name = "Difference(deg)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return math.AngleDifference(A, B)
	end,
	label = function(Out, A, B)
		return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
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

GateActions["atan2"] = {
	group = "Trig",
	name = "Atan2",
	inputs = { "A", "B" },
	output = function( gate, A, B )
		return math.atan2( A, B )
	end,
	label = function( Out, A, B )
		return "atan2(" .. A .. "," .. B .. ") = " .. Out
	end
}


--***********************************************************
--		Array Gates
--***********************************************************

GateActions["table_8merge"] = {
	group = "Array",
	name = "8x merger",
	timed = true,
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputs = { "Tbl" },
	outputtypes = { "ARRAY" },
	output = function(gate, A, B, C, D, E, F, G, H)
		if A then return { A, B, C, D, E, F, G, H }
		else return {}
		end
	end,
}

GateActions["table_8split"] = {
	group = "Array",
	name = "8x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "ARRAY" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0,0,0,0,0
		end
	end,
}

GateActions["table_8duplexer"] = {
	group = "Array",
	name = "8x duplexer",
	timed = true,
	inputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "BIDIRARRAY" },
	outputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "BIDIRARRAY" },
	output = function(gate, Tbl, A, B, C, D, E, F, G, H)
		local t,v = {0,0,0,0,0,0,0,0}, {}
		if Tbl then t = Tbl end
		if A then v = { A, B, C, D, E, F, G, H } end
		return v, unpack( t )
	end,
}

GateActions["table_valuebyidx"] = {
	group = "Array",
	name = "Value retriever",
	timed = true,
	inputs = { "Tbl", "Index" },
	inputtypes = { "ARRAY" },
	outputs = { "Data" },
	output = function(gate, Tbl, idx)
		if Tbl && idx && Tbl[idx] then return Tbl[idx]
		else return 0
		end
	end,
}




-------------------------------------------------------------------------------
-- Vector gates
-------------------------------------------------------------------------------

-- Add
GateActions["vector_add"] = {
	group = "Vector",
	name = "Addition",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	compact_inputs = 2,
	outputtypes = { "VECTOR" },
	output = function(gate, ...)
		local sum = Vector (0, 0, 0)
		for _, v in pairs ({...}) do
			if (v and IsVector (v)) then
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
	group = "Vector",
	name = "Subtraction",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		return (A - B)
	end,
	label = function(Out, A, B)
		return string.format ("%s - %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

-- Negate
GateActions["vector_neg"] = {
	group = "Vector",
	name = "Negate",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return Vector (-A.x, -A.y, -A.z)
	end,
	label = function(Out, A)
		return string.format ("-%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Multiply/Divide by constant
GateActions["vector_mul"] = {
	group = "Vector",
	name = "Multiplication",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return (A * B)
	end,
	label = function(Out, A, B)
		return string.format ("%s * %s = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

GateActions["vector_divide"] = {
	group = "Vector",
	name = "Division",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
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
	group = "Vector",
	name = "Dot Product",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		return A:Dot (B)
	end,
	label = function(Out, A, B)
		return string.format ("dot(%s, %s) = %d", A, B, Out)
	end
}

GateActions["vector_cross"] = {
	group = "Vector",
	name = "Cross Product",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		return A:Cross (B)
	end,
	label = function(Out, A, B)
		return string.format ("cross(%s, %s) = (%d,%d,%d)", A, B, Out.x, Out.y, Out.z)
	end
}

-- Yaw/Pitch
GateActions["vector_ang"] = {
	group = "Vector",
	name = "Angles (Degree)",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputs = { "Yaw", "Pitch" },
	outputtypes = { "NORMAL", "NORMAL" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		local ang = A:Angle ()
		return ang.y, ang.p
	end,
	label = function(Out, A)
		return string.format ("ang(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
	end
}

-- Yaw/Pitch (Radian)
GateActions["vector_angrad"] = {
	group = "Vector",
	name = "Angles (Radian)",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputs = { "Yaw", "Pitch" },
	outputtypes = { "NORMAL", "NORMAL" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		local ang = A:Angle ()
		return (ang.y * math.pi / 180), (ang.p * math.pi / 180)
	end,
	label = function(Out, A)
		return string.format ("angr(%s) = %d, %d", A, Out.Yaw, Out.Pitch)
	end
}

-- Magnitude
GateActions["vector_mag"] = {
	group = "Vector",
	name = "Magnitude",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return A:Length ()
	end,
	label = function(Out, A)
		return string.format ("|%s| = %d", A, Out)
	end
}

-- Conversion To/From
GateActions["vector_convto"] = {
	group = "Vector",
	name = "Compose",
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
	group = "Vector",
	name = "Decompose",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputs = { "X", "Y", "Z" },
	outputtypes = { "NORMAL", "NORMAL", "NORMAL" },
	output = function(gate, A)
		if (A and IsVector (A)) then
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
	group = "Vector",
	name = "Normalise",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return A:GetNormal()
	end,
	label = function(Out, A)
		return string.format( "norm(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z )
		--return "norm(" .. A .. ") = [" .. math.Round(Out.x,3) .. "," .. math.Round(Out.y,3) .. "," .. math.Round(Out.z,3) .. "]"
	end
}

-- Identity
GateActions["vector_ident"] = {
	group = "Vector",
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return A
	end,
	label = function(Out, A)
		return string.format ("%s = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Random (really needed?)
GateActions["vector_rand"] = {
	group = "Vector",
	name = "Random",
	inputs = { },
	inputtypes = { },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate)
		local vec = Vector (math.random (), math.random (), math.random ())
		return vec:Normalize ()
	end,
	label = function(Out)
		return "Random Vector"
	end
}

-- Component Derivative
GateActions["vector_derive"] = {
	group = "Vector",
	name = "Delta",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if !IsVector (A) then A = Vector (0, 0, 0) end
		local dT, dA = t - gate.LastT, A - gate.LastA
		gate.LastT, gate.LastA = t, A
		if (dT) then
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
	group = "Vector",
	name = "Component Integral",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if !IsVector (A) then A = Vector (0, 0, 0) end
		local dT = t - (gate.LastT or t)
		gate.LastT, gate.Integral = t, (gate.Integral or Vector (0, 0, 0)) + A * dT
		-- Lifted (kinda) from wiregates.lua to prevent massive values
		local TempInt = gate.Integral:Length ()
		if (TempInt > 100000) then
			gate.Integral = gate.Integral:Normalize () * 100000
		end
		if (TempInt < -100000) then
			gate.Integral = gate.Integral:Normalize () * -100000
		end
		return gate.Integral
	end,
	reset = function(gate)
		gate.Integral, gate.LastT = Vector (0, 0, 0), CurTime ()
	end,
	label = function(Out, A)
		return string.format ("int(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

-- Multiplexer
GateActions["vector_mux"] = {
	group = "Vector",
	name = "Multiplexer",
	inputs = { "Sel", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	compact_inputs = 3,
	outputtypes = { "VECTOR" },
	output = function(gate, Sel, ...)
		Sel = math.floor(Sel)
		if (Sel > 0 && Sel <= 8) then
			return ({...})[Sel]
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
	group = "Vector",
	name = "Demultiplexer",
	inputs = { "Sel", "In" },
	inputtypes = { "NORMAL", "VECTOR" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	output = function(gate, Sel, In)
		local Out = { Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0),
			Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0), Vector (0, 0, 0) }
		Sel = math.floor (Sel)
		if (Sel > 0 && Sel <= 8) then
			Out[Sel] = In
		end
		return unpack (Out)
	end,
	label = function(Out, Sel, In)
		if !IsVector (In) then In = Vector (0, 0, 0) end
		if !Sel then Sel = 0 end
		return string.format ("Select: %s, In: (%d,%d,%d)",
			Sel, In.x, In.y, In.z)
	end
}

-- Latch
GateActions["vector_latch"] = {
	group = "Vector",
	name = "Latch",
	inputs = { "In", "Clk" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, In, Clk)
		Clk = (Clk > 0)
		if (gate.PrevClk != Clk) then
			gate.PrevClk = Clk
			if (Clk) then
				if !IsVector (In) then In = Vector (0, 0, 0) end
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
	group = "Vector",
	name = "D-Latch",
	inputs = { "In", "Clk" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, In, Clk)
		if (Clk > 0) then
			if !IsVector (In) then In = Vector (0, 0, 0) end
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
	group = "Vector",
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

-- Inequal
GateActions["vector_compineq"] = {
	group = "Vector",
	name = "Inequal",
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
	group = "Vector",
	name = "Less Than",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if (A:Length () < B:Length ()) then return 1 end
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| < |%s|) = %d", A, B, Out)
	end
}

-- Less-than or Equal-to
GateActions["vector_complteq"] = {
	group = "Vector",
	name = "Less Than or Equal To",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "NORMAL" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if (A:Length () <= B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| <= |%s|) = %d", A, B, Out)
	end
}

-- Greater-than
GateActions["vector_compgt"] = {
	group = "Vector",
	name = "Greater Than",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if (A:Length () > B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| > |%s|) = %d", A, B, Out)
	end
}

-- Greater-than or Equal-to
GateActions["vector_compgteq"] = {
	group = "Vector",
	name = "Greater Than or Equal To",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "VECTOR" },
	output = function(gate, A, B)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if (A:Length () < B:Length ()) then return 1 end
		return 0
	end,
	label = function(Out, A, B)
		return string.format ("(|%s| >= |%s|) = %d", A, B, Out)
	end
}

-- Returns a positive vector.
GateActions["vector_positive"] = {
	group = "Vector",
	name = "Positive",
	inputs = { "A" },
	inputtypes = { "VECTOR"},
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return Vector(math.abs(A.x),math.abs(A.y),math.abs(A.z))
	end,
	label = function(Out, A)
		return string.format ("abs(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}


-- Returns a rounded vector.
GateActions["vector_round"] = {
	group = "Vector",
	name = "Round",
	inputs = { "A" },
	inputtypes = { "VECTOR"},
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return Vector(math.Round(A.x),math.Round(A.y),math.Round(A.z))
	end,
	label = function(Out, A)
		return string.format ("round(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}


-- Returns the largest vector.
GateActions["vector_max"] = {
	group = "Vector",
	name = "Largest",
	inputs = { "A" , "B" },
	inputtypes = { "VECTOR" , "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if A:Length() > B:Length() then return A else return B end
	end,
	label = function(Out, A , B)
		return string.format ("max(%s , %s) = (%d,%d,%d)", A , B, Out.x, Out.y, Out.z)
	end
}

-- Returns the smallest vector.
GateActions["vector_min"] = {
	group = "Vector",
	name = "Smallest",
	inputs = { "A" , "B" },
	inputtypes = { "VECTOR" , "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if !IsVector (B) then B = Vector (0, 0, 0) end
		if A:Length() < B:Length() then return A else return B end
	end,
	label = function(Out, A , B)
		return string.format ("min(%s , %s) = (%d,%d,%d)", A , B, Out.x, Out.y, Out.z)
	end
}

-- Shifts the components left.
GateActions["vector_shiftl"] = {
	group = "Vector",
	name = "Shift Components Left",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return Vector(A.y,A.z,A.x)
	end,
	label = function(Out, A )
		return string.format ("shiftL(%s) = (%d,%d,%d)", A , Out.x, Out.y, Out.z)
	end
}

-- Shifts the components right.
GateActions["vector_shiftr"] = {
	group = "Vector",
	name = "Shift Components Right",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		return Vector(A.z,A.x,A.y)
	end,
	label = function(Out, A )
		return string.format ("shiftR(%s) = (%d,%d,%d)", A , Out.x, Out.y, Out.z)
	end
}


-- Returns 1 if a vector is on world.
GateActions["vector_isinworld"] = {
	group = "Vector",
	name = "Is In World",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	output = function(gate, A)
		if !IsVector (A) then A = Vector (0, 0, 0) end
		if util.IsInWorld(A) then return 1 else return 0 end
	end,
	label = function(Out, A )
		return string.format ("isInWorld(%s) = %d", A , Out)
	end
}

GateActions["vector_tostr"] = {
	group = "Vector",
	name = "To String",
	inputs = { "A" },
	inputtypes = { "VECTOR" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !IsVector(A) then A = Vector (0, 0, 0) end
		return "["..tostring(A.x)..","..tostring(A.y)..","..tostring(A.z).."]"
	end,
	label = function(Out, A )
		return string.format ("toString(%s) = \""..Out.."\"", A)
	end
}

GateActions["vector_select"] = {
	group = "Vector",
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR", "VECTOR" },
	outputtypes = { "VECTOR" },
	output = function(gate, Choice, ...)
		math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}

GateActions["vector_rotate"] = {
	group = "Vector",
	name = "Rotate",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "ANGLE" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !A then A = Vector(0, 0, 0) end
		if !B then B = Angle(0, 0, 0) end
		A:Rotate(B)
		return A
	end,
	label = function(Out, A, B)
	    return string.format ("rotate(%s, %s) = "..tostring(Out), A, B )
	end
}

GateActions["vector_mulcomp"] = {
	group = "Vector",
	name = "Multiplication (component)",
	inputs = { "A", "B" },
	inputtypes = { "VECTOR", "NORMAL" },
	outputtypes = { "VECTOR" },
	output = function(gate, A, B)
		if !A then A = Vector(0, 0, 0) end
		if !B then B = 0 end
		return Vector( A.x * B, A.y * B, A.z * B )
	end,
	label = function(Out, A, B)
	    return string.format ("%s * %s = "..tostring(Out), A, B )
	end
}

GateActions["vector_clampn"] = {
	group = "Vector",
	name = "Clamp (numbers)",
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
	group = "Vector",
	name = "Clamp (vectors)",
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

-------------------------------------------------------------------------------
-- Entity gates
-------------------------------------------------------------------------------


GateActions["entity_applyf"] = {
	group = "Entity",
	name = "Apply Force",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if !(E2Lib.getOwner(gate, Ent) == E2Lib.getOwner(gate, gate)) then return end
		if !IsVector(Vec) then Vec = Vector (0, 0, 0) end
		Ent:GetPhysicsObject():ApplyForceCenter(Vec)
	end,
	label = function()
		return ""
	end
}

GateActions["entity_applyof"] = {
	group = "Entity",
	name = "Apply Offset Force",
	inputs = { "Ent" , "Vec" , "Offset" },
	inputtypes = { "ENTITY" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec , Offset )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if !(E2Lib.getOwner(gate, Ent) == E2Lib.getOwner(gate, gate)) then return end
		if !IsVector(Vec) then Vec = Vector (0, 0, 0) end
		if !IsVector(Offset) then Offset = Vector (0, 0, 0) end
		Ent:GetPhysicsObject():ApplyForceOffset(Vec, Offset)
	end,
	label = function()
		return ""
	end
}

-- Base code taken from Expression 2

GateActions["entity_applyaf"] = {
	group = "Entity",
	name = "Apply Angular Force",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	timed = true,
	output = function(gate, Ent , Ang )
		if !Ent then return end
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return end
		if !(E2Lib.getOwner(gate, Ent) == E2Lib.getOwner(gate, gate)) then return end
		if !Ang then Ang = Angle (0, 0, 0) end
			local phys = Ent:GetPhysicsObject()
			local pos = Ent:LocalToWorld(phys:GetMassCenter())
			local up = Ent:GetUp()
			local right = Ent:GetRight()
			local forward = Ent:GetForward()

			local pitch = up      * (Ang.p*0.5)
			local yaw   = forward * (Ang.y*0.5)
			local roll  = right   * (Ang.r*0.5)

			if not phys:IsValid() then return end
			-- apply pitch force
			phys:ApplyForceOffset( forward, pos + pitch )
			phys:ApplyForceOffset( forward * -1, pos - pitch )

			-- apply yaw force
			phys:ApplyForceOffset( right, pos - yaw )
			phys:ApplyForceOffset( right * -1, pos + yaw )

			-- apply roll force
			phys:ApplyForceOffset( up, pos - roll )
			phys:ApplyForceOffset( up * -1, pos + roll )

	end,
	label = function()
		return ""
	end
}


-- Taken from Expression 2

GateActions["entity_applytorq"] = {
	group = "Entity",
	name = "Apply Torque",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if !Ent then return end
		if not Ent:IsValid() then return end
		if !(E2Lib.getOwner(gate, Ent) == E2Lib.getOwner(gate, gate)) then return end
		local phys = Ent:GetPhysicsObject()
		if not phys:IsValid() then return end

		if not !IsVector(Vec) then Vec = Vector( 0, 0, 0 ) end

		local tq = Vec
		local torqueamount = tq:Length()
		local off
		if abs(torque[3]) > torqueamount*0.1 or abs(Vec.x) > torqueamount*0.1 then
			off = Vector(-Vec.z, 0, Vec.x)
		else
			off = Vector(-Vec.y, Vec.x, 0)
		end
		off:Normalize()
		local dir = tq:Cross(off)

		dir = phys:LocalToWorld(dir)-phys:GetPos()
		local masscenter = phys:GetMassCenter()
		phys:ApplyForceOffset( dir * 0.5, phys:LocalToWorld(masscenter+off) )
		phys:ApplyForceOffset( dir * -0.5, phys:LocalToWorld(masscenter-off) )
	end,
	label = function()
		return ""
	end
}



GateActions["entity_class"] = {
	group = "Entity",
	name = "Class",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetClass() end
	end,
	label = function(Out)
		return string.format ("Class = %q", Out)
	end
}

GateActions["entity_entid"] = {
	group = "Entity",
	name = "Entity ID",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	output = function(gate, A)
		if (A and A:IsValid()) then return A:EntIndex() end
		return 0
	end,
	label = function(Out, A)
		return string.format ("entID(%s) = %d", A, Out)
	end
}

GateActions["entity_id2ent"] = {
	group = "Entity",
	name = "ID to Entity",
	inputs = { "A" },
	outputtypes = { "ENTITY" },
	output = function(gate, A)
		local Ent = Entity(A)
		if !Ent:IsValid() then return NULL end
		return Ent
	end,
	label = function(Out, A)
		return string.format ("Entity(%s) = %s", A, tostring(Out))
	end
}


GateActions["entity_model"] = {
	group = "Entity",
	name = "Model",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetModel() end
	end,
	label = function(Out)
		return string.format ("Model = %q", Out)
	end
}

GateActions["entity_steamid"] = {
	group = "Entity",
	name = "SteamID",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return "" else return Ent:SteamID() end
	end,
	label = function(Out)
		return string.format ("SteamID = %q", Out)
	end
}

GateActions["entity_pos"] = {
	group = "Entity",
	name = "Position",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:GetPos() end
	end,
	label = function(Out)
		return string.format ("Position = (%d,%d,%d)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_fruvecs"] = {
	group = "Entity",
	name = "Direction - (forward, right, up)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputs = { "Forward", "Right" , "Up" },
	outputtypes = { "VECTOR" , "VECTOR" , "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) , Vector(0,0,0) , Vector(0,0,0) else return Ent:GetForward() , Ent:GetRight() , Ent:GetUp() end
	end,
	label = function(Out)
		return string.format ("Forward = (%f , %f , %f)\nUp = (%f , %f , %f)\nRight = (%f , %f , %f)", Out.Forward.x , Out.Forward.y , Out.Forward.z, Out.Up.x , Out.Up.y , Out.Up.z, Out.Right.x , Out.Right.y , Out.Right.z)
	end
}

GateActions["entity_isvalid"] = {
	group = "Entity",
	name = "Is Valid",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, A)
		if (A and IsEntity (A) and A:IsValid ()) then
			return 1
		end
		return 0
	end,
	label = function(Out, A)
		return string.format ("isValid(%s) = %s", A, Out)
	end
}

GateActions["entity_vell"] = {
	group = "Entity",
	name = "Velocity (local)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:WorldToLocal(Ent:GetVelocity() + Ent:GetPos()) end
	end,
	label = function(Out)
		return string.format ("Velocity (local) = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_vel"] = {
	group = "Entity",
	name = "Velocity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) else return Ent:GetVelocity() end
	end,
	label = function(Out)
		return string.format ("Velocity = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_angvel"] = {
	group = "Entity",
	name = "Angular Velocity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent)
		local Vec
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then Vec = Vector(0,0,0) else Vec = Ent:GetPhysicsObject():GetAngleVelocity() end
		return Angle(Vec.y, Vec.z, Vec.x)
	end,
	label = function(Out)
		return string.format ("Angular Velocity = (%f , %f , %f)", Out.p , Out.y , Out.r )
	end
}

GateActions["entity_angvelvec"] = {
	group = "Entity",
	name = "Angular Velocity (vector)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		local phys = this:GetPhysicsObject()
		if not phys:IsValid() then return Vector( 0, 0, 0 ) end
		return phys:GetAngleVelocity()
	end,
	label = function(Out)
		return string.format ("Angular Velocity = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_wor2loc"] = {
	group = "Entity",
	name = "World To Local (vector)",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if Ent:IsValid() and IsVector(Vec) then return Ent:WorldToLocal(Vec) else return Vector(0,0,0) end
	end,
	label = function(Out)
		return string.format ("World To Local = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_loc2wor"] = {
	group = "Entity",
	name = "Local To World",
	inputs = { "Ent" , "Vec" },
	inputtypes = { "ENTITY" , "VECTOR" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent , Vec )
		if Ent:IsValid() and IsVector(Vec) then return Ent:LocalToWorld(Vec) else return Vector(0,0,0) end
	end,
	label = function(Out)
		return string.format ("Local To World = (%f , %f , %f)", Out.x , Out.y , Out.z )
	end
}

GateActions["entity_loc2worang"] = {
	group = "Entity",
	name = "World To Local (angle)",
	inputs = { "Ent" , "Ang" },
	inputtypes = { "ENTITY" , "ANGLE" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent , Ang )
		if Ent:IsValid() and Ang then return Ent:LocalToWorldAngles(Ang) else return Angle(0,0,0) end
	end,
	label = function(Out)
		return string.format ("localToWorld = (%d,%d,%d)", Out.p , Out.y , Out.r )
	end
}

GateActions["entity_health"] = {
	group = "Entity",
	name = "Health",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 else return Ent:Health() end
	end,
	label = function(Out)
		return string.format ("Health = %d", Out)
	end
}

GateActions["entity_radius"] = {
	group = "Entity",
	name = "Radius",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 else return Ent:BoundingRadius() end
	end,
	label = function(Out)
		return string.format ("Radius = %d", Out)
	end
}

GateActions["entity_mass"] = {
	group = "Entity",
	name = "Mass",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return 0 else return Ent:GetPhysicsObject():GetMass() end
	end,
	label = function(Out)
		return string.format ("Mass = %d", Out)
	end
}

GateActions["entity_masscenter"] = {
	group = "Entity",
	name = "Mass Center",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) else return Ent:LocalToWorld(Ent:GetPhysicsObject():GetMassCenter()) end
	end,
	label = function(Out)
		return string.format ("Mass Center = (%d,%d,%d)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_masscenterlocal"] = {
	group = "Entity",
	name = "Mass Center (local)",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) else return Ent:GetPhysicsObject():GetMassCenter() end
	end,
	label = function(Out)
		return string.format ("Mass Center (local) = (%d,%d,%d)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_isplayer"] = {
	group = "Entity",
	name = "Is Player",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Player = %d", Out)
	end
}

GateActions["entity_isnpc"] = {
	group = "Entity",
	name = "Is NPC",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsNPC() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is NPC = %d", Out)
	end
}

GateActions["entity_isvehicle"] = {
	group = "Entity",
	name = "Is Vehicle",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsVehicle() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Vehicle = %d", Out)
	end
}

GateActions["entity_isworld"] = {
	group = "Entity",
	name = "Is World",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsWorld() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is World = %d", Out)
	end
}

GateActions["entity_isongrnd"] = {
	group = "Entity",
	name = "Is On Ground",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsOnGround() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is On Ground = %d", Out)
	end
}

GateActions["entity_isunderwater"] = {
	group = "Entity",
	name = "Is Under Water",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:WaterLevel() > 0 then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Under Water = %d", Out)
	end
}

GateActions["entity_angles"] = {
	group = "Entity",
	name = "Angles",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Angle(0,0,0) else return Ent:GetAngles() end
	end,
	label = function(Out)
		return string.format ("Angles = (%d,%d,%d)", Out.p , Out.y , Out.r)
	end
}

GateActions["entity_material"] = {
	group = "Entity",
	name = "Material",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return "" else return Ent:GetMaterial() end
	end,
	label = function(Out)
		return string.format ("Material = %q", Out)
	end
}

GateActions["entity_owner"] = {
	group = "Entity",
	name = "Owner",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return E2Lib.getOwner(gate,gate)	 end
		return E2Lib.getOwner(gate,Ent)
	end,
	label = function(Out,Ent)
		return string.format ("owner(%s) = %s", Ent, tostring(Out))
	end
}
GateActions["entity_player"] = GateActions["entity_owner"]

GateActions["entity_isheld"] = {
	group = "Entity",
	name = "Is Player Holding",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayerHolding() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Player Holding = %d", Out)
	end
}

GateActions["entity_isonfire"] = {
	group = "Entity",
	name = "Is On Fire",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsOnFire()then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is On Fire = %d", Out)
	end
}

GateActions["entity_isweapon"] = {
	group = "Entity",
	name = "Is Weapon",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsWeapon() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is Weapon = %d", Out)
	end
}

GateActions["player_invehicle"] = {
	group = "Entity",
	name = "Is In Vehicle",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() and Ent:InVehicle() then return 1 else return 0 end
	end,
	label = function(Out)
		return string.format ("Is In Vehicle = %d", Out)
	end
}

GateActions["player_connected"] = {
	group = "Entity",
	name = "Time Connected",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return 0 end
		if Ent:IsPlayer() then return Ent:TimeConnected() else return 0 end
	end,
	label = function(Out)
		return string.format ("Time Connected = %d", Out)
	end
}
GateActions["entity_aimentity"] = {
	group = "Entity",
	name = "AimEntity",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return NULL end
		local EntR = Ent:GetEyeTraceNoCursor().Entity
		if !EntR:IsValid() then return NULL end
		return EntR
	end,
	label = function(Out)
		return string.format ("Aim Entity = %s", tostring(Out))
	end
}

GateActions["entity_aimenormal"] = {
	group = "Entity",
	name = "AimNormal",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return end
		if (Ent:IsPlayer()) then
			return Ent:GetAimVector()
		else
			return Ent:GetForward()
		end
	end,
	label = function(Out, A)
		return string.format ("Aim Normal (%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_aimedirection"] = {
	group = "Entity",
	name = "AimDirection",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return Vector(0,0,0) end
		return Ent:GetEyeTraceNoCursor().Normal
	end,
	label = function(Out, A)
		return string.format ("Aim Direction (%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_inertia"] = {
	group = "Entity",
	name = "Inertia",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:GetPhysicsObject():IsValid() then return Vector(0,0,0) end
		return Ent:GetPhysicsObject():GetInertia()
	end,
	label = function(Out, A)
		return string.format ("inertia(%s) = (%d,%d,%d)", Ent, Out.x, Out.y, Out.z)
	end
}

GateActions["entity_setmass"] = {
	group = "Entity",
	name = "Set Mass",
	inputs = { "Ent" , "Val" },
	inputtypes = { "ENTITY" , "NORMAL" },
	timed = true,
	output = function(gate, Ent, Val )
		if !Ent:IsValid() then return end
		if !Ent:GetPhysicsObject():IsValid() then return end
		if !(E2Lib.getOwner(gate, gate) == E2Lib.getOwner(gate, Ent)) then return end
		if !Val then Val = Ent:GetPhysicsObject():GetMass() end
		Val = math.Clamp(Val, 0.001, 50000)
		Ent:GetPhysicsObject():SetMass(Val)
	end,
	label = function(Out, Ent , Val)
		return string.format ("setMass(%s , %s)", Ent, Val)
	end
}

GateActions["entity_equal"] = {
	group = "Entity",
	name = "Equal",
	inputs = { "A" , "B" },
	inputtypes = { "ENTITY" , "ENTITY" },
	output = function(gate, A, B )
		if A == B then return 1 else return 0 end
	end,
	label = function(Out, A , B)
		return string.format ("(%s  = =  %s) = %d", A, B, Out)
	end
}

GateActions["entity_inequal"] = {
	group = "Entity",
	name = "Inequal",
	inputs = { "A" , "B" },
	inputtypes = { "ENTITY" , "ENTITY" },
	output = function(gate, A, B )
		if A ~= B then return 1 else return 0 end
	end,
	label = function(Out, A , B)
		return string.format ("(%s  ! =  %s) = %d", A, B, Out)
	end
}

GateActions["entity_setcol"] = {
	group = "Entity",
	name = "Set Color",
	inputs = { "Ent" , "Col" },
	inputtypes = { "ENTITY" , "VECTOR" },
	timed = true,
	output = function(gate, Ent, Col )
		if !Ent:IsValid() then return end
		if !(E2Lib.getOwner(gate, gate) == E2Lib.getOwner(gate, Ent)) then return end
		if !IsVector(Col) then Col = Vector(255,255,255) end
		Ent:SetColor(Col.x,Col.y,Col.z,255)
	end,
	label = function(Out, Ent , Col)
		if !IsVector(Col) then Col = Vector(0,0,0) end
		return string.format ("setColor(%s ,(%d,%d,%d) )", Ent , Col.x, Col.y, Col.z)
	end
}

GateActions["entity_driver"] = {
	group = "Entity",
	name = "Driver",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsVehicle() then return NULL end
		return Ent:GetDriver()
	end,
	label = function(Out, A)
		local Name = "NULL"
		if Out:IsValid() then Name = Out:Nick() end
		return string.format ("Driver: %s", Name)
	end
}


GateActions["entity_clr"] = {
	group = "Entity",
	name = "Color",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() then return Vector(0,0,0) end
		local r,g,b = Ent:GetColor()
		if !Vector(r,g,b) then return Vector(0,0,0) end
		return Vector(r,g,b)
	end,
	label = function(Out, Ent)
		return string.format ("color(%s) = (%d,%d,%d)", Ent , Out.x, Out.y, Out.z)
	end
}



GateActions["entity_name"] = {
	group = "Entity",
	name = "Name",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "STRING" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return "" else return Ent:Nick() end
	end,
	label = function(Out, Ent)
		return string.format ("name(%s) = %s", Ent, Out)
	end
}

GateActions["entity_aimpos"] = {
	group = "Entity",
	name = "AimPosition",
	inputs = { "Ent" },
	inputtypes = { "ENTITY" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, Ent)
		if !Ent:IsValid() or !Ent:IsPlayer() then return Vector(0,0,0) else return Ent:GetEyeTraceNoCursor().HitPos end
	end,
	label = function(Out)
		return string.format ("Aim Position = (%f , %f , %f)", Out.x , Out.y , Out.z)
	end
}

GateActions["entity_select"] = {
	group = "Entity",
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY" },
	outputtypes = { "ENTITY" },
	output = function(gate, Choice, ...)
		math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}

-- Bearing and Elevation, copied from E2

GateActions["entity_bearing"] = {
	group = "Entity",
	name = "Bearing",
	inputs = { "Entity", "Position", "Clk" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputtypes = { "NORMAL" },
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0 end
		Position = Entity:WorldToLocal(Position)
		return 180 / math.pi * math.atan2( Position.y, Position.x )
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Bearing(" .. Position .. ") = " .. Out
	end
}

GateActions["entity_elevation"] = {
	group = "Entity",
	name = "Elevation",
	inputs = { "Entity", "Position", "Clk" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputtypes = { "NORMAL" },
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0 end
		Position = Entity:WorldToLocal(Position)
		local len = Position:Length()
		return 180 / math.pi * math.asin(Position.z / len)
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Elevation(" .. Position .. ") = " .. Out
	end
}

GateActions["entity_heading"] = {
	group = "Entity",
	name = "Heading",
	inputs = { "Entity", "Position", "Clk" },
	inputtypes = { "ENTITY", "VECTOR", "NORMAL" },
	outputs = { "Bearing", "Elevation", "Heading" },
	outputtypes = { "NORMAL", "NORMAL", "ANGLE" },
	output = function( gate, Entity, Position )
		if (!Entity:IsValid()) then return 0, 0, Angle(0,0,0) end
		Position = Entity:WorldToLocal(Position)

		-- Bearing
		local bearing = 180 / math.pi * math.atan2( Position.y, Position.x )

		-- Elevation
		local len = Position:Length()
		elevation = 180 / math.pi * math.asin( Position.z / len )

		return bearing, elevation, Angle(bearing,elevation,0)
	end,
	label = function( Out, Entity, Position )
		return Entity .. ":Heading(" .. Position .. ") = " .. tostring(Out.Heading)
	end
}


-------------------------------------------------------------------------------
-- Angle gates
-------------------------------------------------------------------------------

-- Add
GateActions["angle_add"] = {
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
	name = "Delta",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	timed = true,
	output = function(gate, A)
		local t = CurTime ()
		if !A then A = Angle (0, 0, 0) end
		local dT, dA = t - gate.LastT, A - gate.LastA
		gate.LastT, gate.LastA = t, A
		if (dT) then
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
	group = "Angle",
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
	group = "Angle",
	name = "Compose",
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
	group = "Angle",
	name = "Decompose",
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
	group = "Angle",
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

GateActions["angle_round"] = {
	group = "Angle",
	name = "Round",
	inputs = { "A" },
	inputtypes = { "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, A)
		if !A then A = Angle (0, 0, 0) end
		return Angle(math.Round(A.p),math.Round(A.y),math.Round(A.r))
	end,
	label = function(Out, A)
		return string.format ("%s = (%d,%d,%d)", A, Out.p, Out.y, Out.r)
	end
}

-- Shifts the components left.
GateActions["angle_shiftl"] = {
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
	name = "Normalize",
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
	group = "Angle",
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
	group = "Angle",
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

-- Inequal
GateActions["angle_compineq"] = {
	group = "Angle",
	name = "Inequal",
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
	group = "Angle",
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
	group = "Angle",
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE", "ANGLE" },
	outputtypes = { "ANGLE" },
	output = function(gate, Choice, ...)
		math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}


GateActions["angle_mulcomp"] = {
	group = "Angle",
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
	group = "Angle",
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
	group = "Angle",
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


-------------------------------------------------------------------------------
-- Rangerdata gates
-------------------------------------------------------------------------------
GateActions["rd_trace"] = {
	group = "Ranger",
	name = "Trace",
	inputs = { "Startpos", "Endpos" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "RANGER" },
	timed = true,
	output = function(gate, Startpos, Endpos)
		if !IsVector(Startpos) then Startpos = Vector (0, 0, 0) end
		if !IsVector(Endpos) then Endpos = Vector (0, 0, 0) end
		local tracedata = {}
		tracedata.start = Startpos
		tracedata.endpos = Endpos
		return util.TraceLine(tracedata)
	end,
	label = function(Out, Startpos, Endpos)
		return string.format ("trace(%s , %s)", Startpos, Endpos)
	end
}

GateActions["rd_hitpos"] = {
	group = "Ranger",
	name = "Hit Position",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if !A then return Vector(0,0,0) end
		if A.StartSolid then return A.StartPos end
		return A.HitPos
	end,
	label = function(Out, A)
		return string.format ("hitpos(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_hitnorm"] = {
	group = "Ranger",
	name = "Hit Normal",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if !A then return Vector(0,0,0) end
		return A.HitNormal
	end,
	label = function(Out, A)
		return string.format ("hitnormal(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_entity"] = {
	group = "Ranger",
	name = "Entity",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, A)
		if !A then return NULL end
		return A.Entity
	end,
	label = function(Out, A)
		return string.format ("hitentity(%s) = %s", A, Out)
	end
}

GateActions["rd_hitworld"] = {
	group = "Ranger",
	name = "Hit World",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NUMBER" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		return A.HitWorld
	end,
	label = function(Out, A)
		return string.format ("hitworld(%s) = %d", A, Out)
	end
}

GateActions["rd_hit"] = {
	group = "Ranger",
	name = "Hit",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NUMBER" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		return A.Hit
	end,
	label = function(Out, A)
		return string.format ("hit(%s) = %d", A, Out)
	end
}

GateActions["rd_distance"] = {
	group = "Ranger",
	name = "Distance",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NUMBER" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		if A.StartSolid then return A.StartPos:Distance(A.HitPos)*(1/(1-A.FractionLeftSolid)-1) end
		return A.StartPos:Distance(A.HitPos)
	end,
	label = function(Out, A)
		return string.format ("distance(%s) = %d", A, Out)
	end
}

-------------------------------------------------------------------------------
-- String gates  !  :P
-------------------------------------------------------------------------------
GateActions["string_ceq"] = {
	group = "String",
	name = "Equal",
	inputs = { "A" , "B" },
	inputtypes = { "STRING" , "STRING" },
	output = function(gate, A, B)
		if A == B then return 1 else return 0 end
	end,
	label = function(Out, A, B)
		return string.format ("(%s == %s) = %d", A, B, Out)
	end
}

GateActions["string_cineq"] = {
	group = "String",
	name = "Inequal",
	inputs = { "A" , "B" },
	inputtypes = { "STRING" , "STRING" },
	output = function(gate, A, B)
		if A ~= B then return 1 else return 0 end
	end,
	label = function(Out, A, B)
		return string.format ("(%s != %s) = %d", A, B, Out)
	end
}

GateActions["string_index"] = {
	group = "String",
	name = "Index",
	inputs = { "A" , "Index" },
	inputtypes = { "STRING" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B)
		if !A then A = "" end
		if !B then B = 0 end
		return string.sub(A,B,B)
	end,
	label = function(Out, A, B)
		return string.format ("index(%s , %s) = %q", A, B, Out)
	end
}

GateActions["string_length"] = {
	group = "String",
	name = "Length",
	inputs = { "A" },
	inputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = "" end
		if string.len(A) then return string.len(A) else return 0 end
	end,
	label = function(Out, A)
		return string.format ("length(%s) = %d", A, Out)
	end
}

GateActions["string_upper"] = {
	group = "String",
	name = "Uppercase",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = "" end
		return string.upper(A)
	end,
	label = function(Out, A)
		return string.format ("upper(%s) = %q", A, Out)
	end
}

GateActions["string_lower"] = {
	group = "String",
	name = "Lowercase",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = "" end
		return string.lower(A)
	end,
	label = function(Out, A)
		return string.format ("lower(%s) = %q", A, Out)
	end
}

GateActions["string_sub"] = {
	group = "String",
	name = "Substring",
	inputs = { "A" , "Start" , "End" },
	inputtypes = { "STRING" , "NORMAL" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C)
		if !A then A = "" end
		if !B then B = 1 end  -- defaults to start of string
		if !C then C = -1 end -- defaults to end of string
		return string.sub(A,B,C)
	end,
	label = function(Out, A, B, C)
		return string.format ("%s:sub(%s , %s) = %q", A, B, C, Out)
	end
}

GateActions["string_explode"] = {
	group = "String",
	name = "Explode",
	inputs = { "A" , "Separator" },
	inputtypes = { "STRING" , "STRING" },
	outputtypes = { "ARRAY" },
	output = function(gate, A, B)
		if !A then A = "" end
		if !B then B = "" end
		return string.Explode(B,A)
	end,
	label = function(Out, A, B)
		return string.format ("explode(%s , %s)", A, B)
	end
}

GateActions["string_find"] = {
	group = "String",
	name = "Find",
	inputs = { "A", "B", "StartIndex" },
	inputtypes = { "STRING", "STRING" },
	outputs = { "Out" },
	output = function(gate, A, B, StartIndex)
		local r = string.find(A,B,StartIndex)
		if r==nil then r=0 end
		return r
	end,
	label = function(Out, A, B)
	    return string.format ("find(%s , %s) = %d", A, B, Out)
	end
}


GateActions["string_concat"] = {
	group = "String",
	name = "Concatenate",
	inputs = { "A" , "B" , "C" , "D" , "E" , "F" , "G" , "H" },
	inputtypes = { "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C, D, E, F, G, H)
		local T = {A,B,C,D,E,F,G,H}
		return table.concat(T)
	end,
	label = function(Out)
		return string.format ("concat = %q", Out)
	end
}

GateActions["string_trim"] = {
	group = "String",
	name = "Trim",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = "" end
		return string.Trim(A)
	end,
	label = function(Out, A)
		return string.format ("trim(%s) = %q", A, Out)
	end
}

GateActions["string_replace"] = {
	group = "String",
	name = "Replace",
	inputs = { "String" , "ToBeReplaced" , "Replacer" },
	inputtypes = { "STRING" , "STRING" , "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C)
		if !A then A = "" end
		if !B then B = "" end
		if !C then C = "" end
		return string.gsub(A,B,C)
	end,
	label = function(Out, A, B, C)
		return string.format ("%s:replace(%s , %s) = %q", A, B, C, Out)
	end
}

GateActions["string_reverse"] = {
	group = "String",
	name = "Reverse",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = "" end
		return string.reverse(A)
	end,
	label = function(Out, A)
		return string.format ("reverse(%s) = %q", A, Out)
	end
}

GateActions["string_tonum"] = {
	group = "String",
	name = "To Number",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if !A then A = "" end
		return tonumber(A)
	end,
	label = function(Out, A)
		return string.format ("tonumber(%s) = %d", A, Out)
	end
}

GateActions["string_tostr"] = {
	group = "String",
	name = "Number to String",
	inputs = { "A" },
	inputtypes = { "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = 0 end
		return tostring(A)
	end,
	label = function(Out, A)
		return string.format ("tostring(%s) = %q", A, Out)
	end
}

GateActions["string_tobyte"] = {
	group = "String",
	name = "To Byte",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if !A then A = "" end
		return string.byte(A)
	end,
	label = function(Out, A)
		return string.format ("tobyte(%s) = %d", A, Out)
	end
}

GateActions["string_tochar"] = {
	group = "String",
	name = "To Character",
	inputs = { "A" },
	inputtypes = { "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if !A then A = 0 end
		return string.char(A)
	end,
	label = function(Out, A)
		return string.format ("tochar(%s) = %q", A, Out)
	end
}

GateActions["string_repeat"] = {
	group = "String",
	name = "Repeat",
	inputs = { "A" , "Num"},
	inputtypes = { "STRING" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B)
		if !A then A = "" end
		if !B or B<1 then B = 1 end
		return string.rep(A,B)
	end,
	label = function(Out, A)
		return string.format ("repeat(%s) = %q", A, Out)
	end
}

GateActions["string_find"] = {
	group = "String",
	name = "Find",
	inputs = { "A", "B", "StartIndex" },
	inputtypes = { "STRING", "STRING" },
	output = function(gate, A, B, C)
		local R = string.find(A, B, C)
		if !R then R = 0 end
		return R
	end,
	label = function(Out, A, B)
	    return string.format ("find(%s , %s) = %d", A, B, Out)
	end
}

GateActions["string_ident"] = {
	group = "String",
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A )
		return A
	end,
	label = function(Out, A)
	    return string.format ("%s = %s", A, Out)
	end
}

GateActions["string_select"] = {
	group = "String",
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, Choice, ...)
		math.Clamp(Choice,1,8)
		return ({...})[Choice]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}


WireGatesSorted = {}
for name,gate in pairs(GateActions) do
	if !WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
	WireGatesSorted[gate.group][name] = gate
end
