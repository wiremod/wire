FPGAGateActions("Constant Values")

FPGAGateActions["normal-constant"] = {
	name = "Normal Constant",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  isConstant = true
}

FPGAGateActions["vector-constant"] = {
	name = "Vector Constant",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  isConstant = true
}

FPGAGateActions["angle-constant"] = {
	name = "Angle Constant",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ANGLE"},
  isConstant = true
}

FPGAGateActions["string-constant"] = {
	name = "String Constant",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"STRING"},
  isConstant = true
}

FPGAGateActions["entity-self"] = {
	name = "Self",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ENTITY"},
  output = function(gate)
    return gate:GetSelf()
  end
}

FPGAGateActions["entity-owner"] = {
	name = "Owner",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ENTITY"},
  output = function(gate)
    return gate:GetPlayer()
  end
}
