FPGAGateActions("Constant Values")

FPGAGateActions["normal-constant"] = {
	name = "Constant Normal",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  isConstant = true
}

FPGAGateActions["vector-constant"] = {
	name = "Constant Vector",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  isConstant = true
}

FPGAGateActions["angle-constant"] = {
	name = "Constant Angle",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"ANGLE"},
  isConstant = true
}

FPGAGateActions["string-constant"] = {
	name = "Constant String",
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

FPGAGateActions["server-tickrate"] = {
	name = "Tickrate",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  output = function(gate)
    return 1 / FrameTime()
  end
}
