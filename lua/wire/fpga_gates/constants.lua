FPGAGateActions("Constant Values")
local i = 1

FPGAGateActions["normal-constant"] = {
	order = i,
	name = "Constant Normal",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	isConstant = true
}

i = i + 1
FPGAGateActions["vector-constant"] = {
	order = i,
	name = "Constant Vector",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"VECTOR"},
	isConstant = true
}

i = i + 1
FPGAGateActions["angle-constant"] = {
	order = i,
	name = "Constant Angle",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ANGLE"},
	isConstant = true
}

i = i + 1
FPGAGateActions["string-constant"] = {
	order = i,
	name = "Constant String",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"STRING"},
	isConstant = true
}

i = i + 1
FPGAGateActions["entity-self"] = {
	order = i,
	name = "Self",
	description = "Gets this FPGA",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ENTITY"},
	specialFunctions = true,
	output = function(gate)
		return gate:GetSelf()
	end
}

i = i + 1
FPGAGateActions["entity-owner"] = {
	order = i,
	name = "Owner",
	description = "Gets you!",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ENTITY"},
	output = function(gate)
		return gate:GetPlayer()
	end
}

i = i + 1
FPGAGateActions["server-tickrate"] = {
	order = i,
	name = "Tickrate",
	description = "Gets the server tickrate",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	output = function(gate)
		return 1 / FrameTime()
	end
}
