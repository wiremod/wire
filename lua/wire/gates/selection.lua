--[[
		Selection Gates
]]

GateActions("Selection")

GateActions["min"] = {
	name = "Minimum (Smallest)",
	description = "Outputs the least of 8 values.",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		return math.min(unpack({...}))
	end,
	label = function(Out, ...)
		local txt = "min("
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v..", " end
		end
		return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["max"] = {
	name = "Maximum (Largest)",
	description = "Outputs the greatest of 8 values.",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		return math.max(unpack({...}))
	end,
	label = function(Out, ...)
		local txt = "max("
		for k,v in ipairs({...}) do
			if (v) then txt = txt..v..", " end
		end
		return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["minmax"] = {
	name = "Value Range",
	description = "Clamps the value to between Min and Max.",
	inputs = { "Min", "Max", "Value" },
	output = function(gate, Min, Max, Value)
		local temp = Min
		if Min > Max then
			Min = Max
			Max = temp
		end
		if Value < Min then return Min end
		if Value > Max then return Max end
		return Value
	end,
	label = function(Out, Min, Max, Value)
		local temp = Min
		if Min > Max then
			Min = Max
			Max = temp
		end
		return "Min: "..Min.."  Max: "..Max.."  Value: "..Value.." = "..Out
	end
}

GateActions["if"] = {
	name = "If Then Else",
	inputs = { "A", "B", "C" },
	output = function(gate, A, B, C)
		if (A) and (A > 0) then return B end
		return C
	end,
	label = function(Out, A, B, C)
		return "if "..A.." then "..B.." else "..C.." = "..Out
	end
}

GateActions["select"] = {
	name = "Select (Choice)",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Choice, ...)
		local idx = math.floor(Choice)
		if (idx > 0) and (idx <= 8) then
			return ({...})[idx]
		end

		return 0
	end,
	label = function(Out, Choice)
		return "Select Choice:"..Choice.." Out:"..Out
	end
}

GateActions["router"] = {
	name = "Router",
	description = "Outputs the Data to the desired index (Path).",
	inputs = { "Path", "Data" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Path, Data)
		local result = { 0, 0, 0, 0, 0, 0, 0, 0 }

		local idx = math.floor(Path)
		if (idx > 0) and (idx <= 8) then
			result[idx] = Data
		end

		return unpack(result)
	end,
	label = function(Out, Path, Data)
		return "Router Path:"..Path.." Data:"..Data
	end
}

local SegmentInfo = {
	None = { 0, 0, 0, 0, 0, 0, 0 },
	[0]  = { 1, 1, 1, 1, 1, 1, 0 },
	[1]  = { 0, 1, 1, 0, 0, 0, 0 },
	[2]  = { 1, 1, 0, 1, 1, 0, 1 },
	[3]  = { 1, 1, 1, 1, 0, 0, 1 },
	[4]  = { 0, 1, 1, 0, 0, 1, 1 },
	[5]  = { 1, 0, 1, 1, 0, 1, 1 },
	[6]  = { 1, 0, 1, 1, 1, 1, 1 },
	[7]  = { 1, 1, 1, 0, 0, 0, 0 },
	[8]  = { 1, 1, 1, 1, 1, 1, 1 },
	[9]  = { 1, 1, 1, 1, 0, 1, 1 },
}

GateActions["7seg"] = {
	name = "7 Segment Decoder",
	description = "Converts a number to a 7-segment representation.",
	inputs = { "A", "Clear" },
	outputs = { "A", "B", "C", "D", "E", "F", "G" },
	output = function(gate, A, Clear)
		if (Clear > 0) then return unpack(SegmentInfo.None) end

		local idx = math.fmod(math.abs(math.floor(A)), 10)
		if idx > #SegmentInfo then return unpack(SegmentInfo.None) end
		return unpack(SegmentInfo[idx]) -- same as: return SegmentInfo[idx][1], SegmentInfo[idx][2], ...
	end,
	label = function(Out, A)
		return "7-Seg In:" .. A .. " Out:" .. Out.A .. Out.B .. Out.C .. Out.D .. Out.E .. Out.F .. Out.G
	end
}

GateActions["timedec"] = {
	name = "Time/Date decoder",
	description = "Converts a Time in seconds and a Date in years a human-readable format.",
	inputs = { "Time", "Date" },
	outputs = { "Hours","Minutes","Seconds","Year","Day" },
	output = function(gate, Time, Date)
		return math.floor(Time / 3600),math.floor(Time / 60) % 60,math.floor(Time) % 60,math.floor(Date / 366),math.floor(Date) % 366
	end,
	label = function(Out, A)
		return "Date decoder"
	end
}

GateActions()
