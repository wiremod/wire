CPUGateActions("Memory")
local i = 1

CPUGateActions["memory-program-counter-edge-trigger"] = {
	order = i,
	name = "Program Counter (Edge Triggered)",
	description = "A program counter that supports loading from addresses, resetting, and incrementing when Clock changes and isnt 0",
	inputs = {"Increment", "Load", "LoadAddress", "Reset", "Clock"},
	outputs = {"Address"},
	output = function(gate, Increment, Load, LoadAddress, Reset, Clock)
		local clock = (Clock ~= 0)
		if (gate.PrevClock ~= clock and clock) then
			if Increment ~= 0 then
				gate.Address = gate.Address + 1
			end
			if Load ~= 0 then
				gate.Address = math.floor(LoadAddress)
			end
			if Reset ~= 0 then
				gate.Address = 0
			end
		end

		gate.PrevClock = clock
		return gate.Address
	end,
	reset = function(gate)
		gate.Address = 0
		gate.PrevClock = nil
	end
}

i = i + 1
CPUGateActions["memory-register"] = {
	order = i,
	name = "Register",
	description = "Updates its value from Data when Clock isnt 0",
	inputs = {"Data", "Clock"},
	output = function(gate, Data, Clock)
		if (Clock ~= 0) then
			gate.Value = Data
		end
		return gate.Value
	end,
	reset = function(gate)
		gate.Value = 0
	end,
}

i = i + 1
CPUGateActions["memory-register-edge-trigger"] = {
	order = i,
	name = "Register (Edge Triggered)",
	description = "Updates its value from Data when Clock changes and isnt 0",
	inputs = {"Data", "Clock"},
	output = function(gate, Data, Clock)
		local clock = (Clock ~= 0)
		if (gate.PrevClock ~= clock) then
			gate.PrevClock = clock
			if (clock) then
				gate.Value = Data
			end
		end
		return gate.Value
	end,
	reset = function(gate)
		gate.Value = 0
		gate.PrevClock = nil
	end,
}