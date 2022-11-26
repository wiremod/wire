--[[
		Comparison Gates
]]

GateActions("Comparison")

GateActions["="] = {
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
	name = "Is In Range (Inclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		if (Max < Min) then
			local temp = Max
			Max = Min
			Min = temp
		end
		if ((Value >= Min) and (Value <= Max)) then return 1 end
		return 0
	end,
	label = function(Out, Min, Max, Value)
		return Min.." <= "..Value.." <= "..Max.." = "..Out
	end
}

GateActions["inrangee"] = {
	name = "Is In Range (Exclusive)",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		if (Max < Min) then
			local temp = Max
			Max = Min
			Min = temp
		end
		if ((Value > Min) and (Value < Max)) then return 1 end
		return 0
	end,
	label = function(Out, Min, Max, Value)
		return Min.." < "..Value.." < "..Max.." = "..Out
	end
}

GateActions()
