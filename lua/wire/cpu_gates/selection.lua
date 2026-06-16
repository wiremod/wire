CPUGateActions("Selection")
local i = 1

CPUGateActions["selection-2-mux"] = {
	order = i,
	name = "2-to-1 Mux",
	description = "Selects a value out of 2 choices and outputs 1",
	inputs = {"Select", "A", "B"},
	output = function(gate, S, ...)
		local s = math.floor(S)

		if (s >= 0) and (s < 2) then
			return ({...})[s+1]
		end

		return 0
	end
}

i = i + 1
CPUGateActions["selection-4-mux"] = {
	order = i,
	name = "4-to-1 Mux",
	description = "Selects a value out of 4 choices and outputs 1",
	inputs = {"Select", "A", "B", "C", "D"},
	output = function(gate, S, ...)
		local s = math.floor(S)

		if (s >= 0) and (s < 4) then
			return ({...})[s+1]
		end

		return 0
	end
}

i = i + 1
CPUGateActions["selection-8-mux"] = {
	order = i,
	name = "8-to-1 Mux",
	description = "Selects a value out of 8 choices and outputs 1",
	inputs = {"Select", "A", "B", "C", "D", "E", "F", "G", "H"},
	output = function(gate, S, ...)
		local s = math.floor(S)

		if (s >= 0) and (s < 8) then
			return ({...})[s+1]
		end

		return 0
	end
}

i = i + 1
CPUGateActions["selection-16-mux"] = {
	order = i,
	name = "16-to-1 Mux",
	description = "Selects a value out of 16 choices and outputs 1",
	inputs = {"Select", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"},
	output = function(gate, S, ...)
		local s = math.floor(S)

		if (s >= 0) and (s < 16) then
			return ({...})[s+1]
		end

		return 0
	end
}

i = i + 1
CPUGateActions["selection-2-demux"] = {
	order = i,
	name = "1-to-2 Demux",
	description = "Depending on what Select is, routes In to a specific output",
	inputs = {"Select", "In"},
	outputs = {"A", "B"},
	output = function(gate, S, I)
		local s = math.floor(S)

		local result = {0, 0}

		if (s >= 0) and (s < 2) then
			result[s+1] = I
		end

		return unpack(result)
	end
}

i = i + 1
CPUGateActions["selection-4-demux"] = {
	order = i,
	name = "1-to-4 Demux",
	description = "Depending on what Select is, routes In to a specific output",
	inputs = {"Select", "In"},
	outputs = {"A", "B", "C", "D"},
	output = function(gate, S, I)
		local s = math.floor(S)

		local result = {0, 0, 0, 0}

		if (s >= 0) and (s < 4) then
			result[s+1] = I
		end

		return unpack(result)
	end
}

i = i + 1
CPUGateActions["selection-8-demux"] = {
	order = i,
	name = "1-to-8 Demux",
	description = "Depending on what Select is, routes In to a specific output",
	inputs = {"Select", "In"},
	outputs = {"A", "B", "C", "D", "E", "F", "G", "H"},
	output = function(gate, S, I)
		local s = math.floor(S)

		local result = {0, 0, 0, 0, 0, 0, 0, 0}

		if (s >= 0) and (s < 8) then
			result[s+1] = I
		end

		return unpack(result)
	end
}

i = i + 1
CPUGateActions["selection-16-demux"] = {
	order = i,
	name = "1-to-16 Demux",
	description = "Depending on what Select is, routes In to a specific output",
	inputs = {"Select", "In"},
	outputs = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"},
	output = function(gate, S, I)
		local s = math.floor(S)

		local result = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

		if (s >= 0) and (s < 16) then
			result[s+1] = I
		end

		return unpack(result)
	end
}