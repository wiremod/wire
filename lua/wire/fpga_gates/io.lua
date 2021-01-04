FPGAGateActions("Input / Output")

FPGAGateActions["normal-input"] = {
	name = "Input",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  isInput = true,
	output = function(gate)
		return 0
	end
}

FPGAGateActions["normal-output"] = {
	name = "Output",
  inputs = {"A"},
  inputtypes = {"NORMAL"},
  outputs = {},
  isOutput = true,
	output = function(gate)
		return 0
	end
}