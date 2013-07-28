--[[
		Bitwise Gates
]]

GateActions("Bitwise")

GateActions["bnot"] = {
	name = "Not",
	inputs = { "A" },
	output = function(gate, A)
		return bit.bnot(A)
	end,
	label = function(Out, A)
		return "not "..A.." = "..Out
	end
}

GateActions["bor"] = {
	name = "Or",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return bit.bor(A, B)
	end,
	label = function(Out, A, B)
		return A.." or "..B.." = "..Out
	end
}

GateActions["band"] = {
	name = "And",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return bit.band(A, B)
	end,
	label = function(Out, A, B)
		return A.." and "..B.." = "..Out
	end
}

GateActions["bxor"] = {
	name = "Xor",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return bit.bxor(A, B)
	end,
	label = function(Out, A, B)
		return A.." xor "..B.." = "..Out
	end
}

GateActions["bshr"] = {
	name = "Bit shift right",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return bit.rshift(A, B)
	end,
	label = function(Out, A, B)
		return A.." >> "..B.." = "..Out
	end
}

GateActions["bshl"] = {
	name = "Bit shift left",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		return bit.lshift(A, B)
	end,
	label = function(Out, A, B)
		return A.." << "..B.." = "..Out
	end
}

GateActions()
