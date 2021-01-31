FPGAGateActions("Input & Output")

FPGAGateActions["normal-input"] = {
	name = "Normal Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["normal-output"] = {
	name = "Normal Output",
  inputs = {"A"},
  inputtypes = {"NORMAL"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

-- FPGAGateActions["vector2-input"] = {
-- 	name = "2D Vector Input",
--   inputs = {},
--   outputs = {"Out"},
--   outputtypes = {"VECTOR2"},
--   isInput = true,
-- 	output = function(gate)
-- 		return 0
-- 	end
-- }

-- FPGAGateActions["vector2-output"] = {
-- 	name = "2D Vector Output",
--   inputs = {"A"},
--   inputtypes = {"VECTOR2"},
--   outputs = {},
--   isOutput = true,
-- 	output = function(gate)
-- 		return 0
-- 	end
-- }

FPGAGateActions["vector-input"] = {
	name = "3D Vector Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["vector-output"] = {
	name = "3D Vector Output",
  inputs = {"A"},
  inputtypes = {"VECTOR"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

-- FPGAGateActions["vector4-input"] = {
-- 	name = "4D Vector Input",
--   inputs = {},
--   outputs = {"Out"},
--   outputtypes = {"VECTOR4"},
--   isInput = true,
-- 	output = function(gate)
-- 		return 0
-- 	end
-- }

-- FPGAGateActions["vector4-output"] = {
-- 	name = "4D Vector Output",
--   inputs = {"A"},
--   inputtypes = {"VECTOR4"},
--   outputs = {},
--   isOutput = true,
-- 	output = function(gate)
-- 		return 0
-- 	end
-- }

FPGAGateActions["angle-input"] = {
	name = "Angle Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ANGLE"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["angle-output"] = {
	name = "Angle Output",
  inputs = {"A"},
  inputtypes = {"ANGLE"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["string-input"] = {
	name = "String Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"STRING"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["string-output"] = {
	name = "String Output",
  inputs = {"A"},
  inputtypes = {"STRING"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["array-input"] = {
	name = "Array Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ARRAY"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["array-output"] = {
	name = "Array Output",
  inputs = {"A"},
  inputtypes = {"ARRAY"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["entity-input"] = {
	name = "Entity Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ENTITY"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["entity-output"] = {
	name = "Entity Output",
  inputs = {"A"},
  inputtypes = {"ENTITY"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["ranger-input"] = {
	name = "Ranger Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"RANGER"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["ranger-output"] = {
	name = "Ranger Output",
  inputs = {"A"},
  inputtypes = {"RANGER"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["hispeed-input"] = {
	name = "Highspeed Input",
  inputs = {},
  outputs = {"Memory"},
  outputtypes = {"WIRELINK"},
  isInput = true,
	output = function(gate)
		return 0
	end
}