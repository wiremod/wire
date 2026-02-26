FPGAGateActions("Input & Output")
local i = 1

FPGAGateActions["normal-input"] = {
	order = i,
	name = "Normal Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	isInput = true
}

i = i + 1
FPGAGateActions["normal-output"] = {
	order = i,
	name = "Normal Output",
	inputs = {"A"},
	inputtypes = {"NORMAL"},
	outputs = {},
	isOutput = true
}

-- FPGAGateActions["vector2-input"] = {
-- 	name = "2D Vector Input",
--   inputs = {},
--   outputs = {"Out"},
--   outputtypes = {"VECTOR2"},
--   isInput = true
-- }

-- FPGAGateActions["vector2-output"] = {
-- 	name = "2D Vector Output",
--   inputs = {"A"},
--   inputtypes = {"VECTOR2"},
--   outputs = {},
--   isOutput = true
-- }

i = i + 1
FPGAGateActions["vector-input"] = {
	order = i,
	name = "Vector Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"VECTOR"},
	isInput = true
}

i = i + 1
FPGAGateActions["vector-output"] = {
	order = i,
	name = "Vector Output",
	inputs = {"A"},
	inputtypes = {"VECTOR"},
	outputs = {},
	isOutput = true
}

-- FPGAGateActions["vector4-input"] = {
-- 	name = "4D Vector Input",
--   inputs = {},
--   outputs = {"Out"},
--   outputtypes = {"VECTOR4"},
--   isInput = true
-- }

-- FPGAGateActions["vector4-output"] = {
-- 	name = "4D Vector Output",
--   inputs = {"A"},
--   inputtypes = {"VECTOR4"},
--   outputs = {},
--   isOutput = true
-- }

i = i + 1
FPGAGateActions["angle-input"] = {
	order = i,
	name = "Angle Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ANGLE"},
	isInput = true
}

i = i + 1
FPGAGateActions["angle-output"] = {
	order = i,
	name = "Angle Output",
	inputs = {"A"},
	inputtypes = {"ANGLE"},
	outputs = {},
	isOutput = true
}

i = i + 1
FPGAGateActions["string-input"] = {
	order = i,
	name = "String Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"STRING"},
	isInput = true
}

i = i + 1
FPGAGateActions["string-output"] = {
	order = i,
	name = "String Output",
	inputs = {"A"},
	inputtypes = {"STRING"},
	outputs = {},
	isOutput = true
}

i = i + 1
FPGAGateActions["entity-input"] = {
	order = i,
	name = "Entity Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ENTITY"},
	isInput = true
}

i = i + 1
FPGAGateActions["entity-output"] = {
	order = i,
	name = "Entity Output",
	inputs = {"A"},
	inputtypes = {"ENTITY"},
	outputs = {},
	isOutput = true
}

i = i + 1
FPGAGateActions["array-input"] = {
	order = i,
	name = "Array Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"ARRAY"},
	isInput = true
}

i = i + 1
FPGAGateActions["array-output"] = {
	order = i,
	name = "Array Output",
	inputs = {"A"},
	inputtypes = {"ARRAY"},
	outputs = {},
	isOutput = true
}

i = i + 1
FPGAGateActions["ranger-input"] = {
	order = i,
	name = "Ranger Input",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"RANGER"},
	isInput = true
}

i = i + 1
FPGAGateActions["ranger-output"] = {
	order = i,
	name = "Ranger Output",
	inputs = {"A"},
	inputtypes = {"RANGER"},
	outputs = {},
	isOutput = true
}

i = i + 1
FPGAGateActions["wirelink-input"] = {
	order = i,
	name = "Wirelink Input",
	inputs = {},
	outputs = {"Wirelink"},
	outputtypes = {"WIRELINK"},
	isInput = true
}