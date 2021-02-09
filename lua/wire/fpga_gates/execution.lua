FPGAGateActions("Execution")

FPGAGateActions["execution-delta"] = {
  name = "Execution Delta",
  inputs = {},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  alwaysActive = true,
  output = function(gate)
    return gate:GetExecutionDelta()
  end,
}

FPGAGateActions["execution-last-normal"] = {
  name = "Last Normal",
  inputs = {"A"},
  inputtypes = {"NORMAL"},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = 0
    gate.memory = 0
  end,
  postCycle = function(gate)
    gate.value = gate.memory
  end,
}

FPGAGateActions["execution-last-vector"] = {
  name = "Last Vector",
  inputs = {"A"},
  inputtypes = {"VECTOR"},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = Vector(0, 0, 0)
    gate.memory = Vector(0, 0, 0)
  end,
  postCycle = function(gate)
    gate.value = gate.memory
  end,
}

FPGAGateActions["execution-last-angle"] = {
  name = "Last Angle",
  inputs = {"A"},
  inputtypes = {"ANGLE"},
  outputs = {"Out"},
  outputtypes = {"ANGLE"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = Angle(0, 0, 0)
    gate.memory = Angle(0, 0, 0)
  end,
  postCycle = function(gate)
    gate.value = gate.memory
  end,
}

FPGAGateActions["execution-last-string"] = {
  name = "Last String",
  inputs = {"A"},
  inputtypes = {"STRING"},
  outputs = {"Out"},
  outputtypes = {"STRING"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = ""
    gate.memory = ""
  end,
  postCycle = function(gate)
    gate.value = gate.memory
  end,
}

FPGAGateActions["execution-previous-normal"] = {
  name = "Previous Normal",
  inputs = {"A"},
  inputtypes = {"NORMAL"},
  outputs = {"Out"},
  outputtypes = {"NORMAL"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = 0
    gate.memory = 0
  end,
  postExecution = function(gate)
    local changed = gate.value != gate.memory
    gate.value = gate.memory
    return changed
  end,
}

FPGAGateActions["execution-previous-vector"] = {
  name = "Previous Vector",
  inputs = {"A"},
  inputtypes = {"VECTOR"},
  outputs = {"Out"},
  outputtypes = {"VECTOR"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = Vector(0, 0, 0)
    gate.memory = Vector(0, 0, 0)
  end,
  postExecution = function(gate)
    local changed = gate.value != gate.memory
    gate.value = gate.memory
    return changed
  end,
}

FPGAGateActions["execution-previous-angle"] = {
  name = "Previous Angle",
  inputs = {"A"},
  inputtypes = {"ANGLE"},
  outputs = {"Out"},
  outputtypes = {"ANGLE"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = Angle(0, 0, 0)
    gate.memory = Angle(0, 0, 0)
  end,
  postExecution = function(gate)
    local changed = gate.value != gate.memory
    gate.value = gate.memory
    return changed
  end,
}

FPGAGateActions["execution-previous-string"] = {
  name = "Previous String",
  inputs = {"A"},
  inputtypes = {"STRING"},
  outputs = {"Out"},
  outputtypes = {"STRING"},
  neverActive = true,
  output = function(gate, value)
    gate.memory = value
    return gate.value
  end,
  reset = function(gate)
    gate.value = ""
    gate.memory = ""
  end,
  postExecution = function(gate)
    local changed = gate.value != gate.memory
    gate.value = gate.memory
    return changed
  end,
}