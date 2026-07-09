FPGAGateActions("Execution")
local i = 1

i = i + 1
FPGAGateActions["execution-delta"] = {
	order = i,
	name = "Execution Delta",
	description = "Gets the time since the last execution of this FPGA",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	alwaysActive = true,
	specialFunctions = true,
	output = function(gate)
		return gate:GetExecutionDelta()
	end,
}

i = i + 1
FPGAGateActions["execution-count"] = {
	order = i,
	name = "Execution Count",
	description = "Gets the amount of times this FPGA has executed",
	inputs = {},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	alwaysActive = true,
	specialFunctions = true,
	output = function(gate)
		return gate:GetExecutionCount()
	end,
}

i = i + 1
FPGAGateActions["execution-last-normal"] = {
	order = i,
	name = "Last Normal",
	description = "Outputs what A was last execution",
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

i = i + 1
FPGAGateActions["execution-last-vector"] = {
	order = i,
	name = "Last Vector",
	description = "Outputs what A was last execution",
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

i = i + 1
FPGAGateActions["execution-last-angle"] = {
	order = i,
	name = "Last Angle",
	description = "Outputs what A was last execution",
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

i = i + 1
FPGAGateActions["execution-last-string"] = {
	order = i,
	name = "Last String",
	description = "Outputs what A was last execution",
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

i = i + 1
FPGAGateActions["execution-timed-last-normal"] = {
	order = i,
	name = "Timed Last Normal",
	description = "Outputs what A was last execution",
	inputs = {"A"},
	inputtypes = {"NORMAL"},
	outputs = {"Out"},
	outputtypes = {"NORMAL"},
	timed = true,
	neverActive = true,
	output = function(gate, value)
		local oldValue = gate.value
		gate.value = value
		return oldValue
	end,
	reset = function(gate)
		gate.value = 0
	end
}

i = i + 1
FPGAGateActions["execution-timed-last-vector"] = {
	order = i,
	name = "Timed Last Vector",
	description = "Outputs what A was last execution",
	inputs = {"A"},
	inputtypes = {"VECTOR"},
	outputs = {"Out"},
	outputtypes = {"VECTOR"},
	timed = true,
	neverActive = true,
	output = function(gate, value)
		local oldValue = gate.value
		gate.value = value
		return oldValue
	end,
	reset = function(gate)
		gate.value = Vector(0, 0, 0)
		gate.memory = Vector(0, 0, 0)
	end
}

i = i + 1
FPGAGateActions["execution-timed-last-angle"] = {
	order = i,
	name = "Timed Last Angle",
	description = "Outputs what A was last execution",
	inputs = {"A"},
	inputtypes = {"ANGLE"},
	outputs = {"Out"},
	outputtypes = {"ANGLE"},
	timed = true,
	neverActive = true,
	output = function(gate, value)
		local oldValue = gate.value
		gate.value = value
		return oldValue
	end,
	reset = function(gate)
		gate.value = Angle(0, 0, 0)
		gate.memory = Angle(0, 0, 0)
	end
}

i = i + 1
FPGAGateActions["execution-timed-last-string"] = {
	order = i,
	name = "Timed Last String",
	description = "Outputs what A was last execution",
	inputs = {"A"},
	inputtypes = {"STRING"},
	outputs = {"Out"},
	outputtypes = {"STRING"},
	timed = true,
	neverActive = true,
	output = function(gate, value)
		local oldValue = gate.value
		gate.value = value
		return oldValue
	end,
	reset = function(gate)
		gate.value = ""
		gate.memory = ""
	end
}

i = i + 1
FPGAGateActions["execution-previous-normal"] = {
	order = i,
	name = "Previous Normal",
	description = "Outputs what A was last tick",
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

i = i + 1
FPGAGateActions["execution-previous-vector"] = {
	order = i,
	name = "Previous Vector",
	description = "Outputs what A was last tick",
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

i = i + 1
FPGAGateActions["execution-previous-angle"] = {
	order = i,
	name = "Previous Angle",
	description = "Outputs what A was last tick",
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

i = i + 1
FPGAGateActions["execution-previous-string"] = {
	order = i,
	name = "Previous String",
	description = "Outputs what A was last tick",
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