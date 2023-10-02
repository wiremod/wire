--[[
		Logic Gates
]]

GateActions("Logic")

GateActions["not"] = {
	name = "Not (Invert)",
	description = "Outputs 0 for inputs greater than 0, otherwise outputs 1.",
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
	name = "And (All)",
	description = "Outputs 1 if all inputs are greater than 0.",
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
	name = "Exclusive Or (Odd)",
	description = "Outputs 1 if there is an odd amount of nonzero inputs.",
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
	name = "Not And (Not All)",
	description = "Outputs 1 if there is 1 or 0 nonzero inputs.",
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
	name = "Not Or (None)",
	description = "Outputs 1 if there are no inputs greater than 0.",
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
	name = "Exclusive Not Or (Even)",
	description = "Outputs 1 if there are an even amount of nonzero inputs.",
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

GateActions()
