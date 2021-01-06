FPGAGateActions("Input / Output")

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

FPGAGateActions["vector-input"] = {
	name = "Vector Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["vector-output"] = {
	name = "Vector Output",
  inputs = {"A"},
  inputtypes = {"VECTOR"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}