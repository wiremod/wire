--[[
		Time Gates
]]

GateActions("Time")

GateActions["accumulator"] = {
	name = "Accumulator",
	description = "Counts time while A is set and Hold is not set.",
	inputs = { "A", "Hold", "Reset" },
	timed = true,
	output = function(gate, A, Hold, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if (Reset > 0) then
			gate.Accum = 0
		elseif (Hold <= 0) then
			gate.Accum = gate.Accum+A*DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, A, Hold, Reset)
		return "A:"..A.." Hold:"..Hold.." Reset:"..Reset.." = "..Out
	end
}

GateActions["smoother"] = {
	name = "Smoother",
	description = "Smooths the change in a number.",
	inputs = { "A", "Rate" },
	timed = true,
	output = function(gate, A, Rate)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		local Delta = A-gate.Accum
		if (Delta > 0) then
			gate.Accum = gate.Accum+math.min(Delta, Rate*DeltaTime)
		elseif (Delta < 0) then
			gate.Accum = gate.Accum+math.max(Delta, -Rate*DeltaTime)
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, A, Rate)
		return "A:"..A.." Rate:"..Rate.." = "..Out
	end
}

GateActions["timer"] = {
	name = "Timer",
	description = "Counts time upward while Run is set.",
	inputs = { "Run", "Reset" },
	timed = true,
	output = function(gate, Run, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
		end
		return gate.Accum or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset)
		return "Run:"..Run.." Reset:"..Reset.." = "..Out
	end
}

GateActions["ostime"] = {
	name = "OS Time",
	description = "Outputs the time of day on the server in seconds.",
	inputs = { },
	timed = true,
	output = function(gate)
		return os.date("%H")*3600+os.date("%M")*60+os.date("%S")
	end,
	label = function(Out)
		return "OS Time = "..Out
	end
}

GateActions["osdate"] = {
	name = "OS Date",
	description = "Outputs the date on the server in days.",
	inputs = { },
	timed = true,
	output = function(gate)
		return os.date("%Y")*366+os.date("%j")
	end,
	label = function(Out)
		return "OS Date = "..Out
	end
}

GateActions["pulser"] = {
	name = "Pulser",
	description = "Activates for one tick every TickTime while Run is set.",
	inputs = { "Run", "Reset", "TickTime" },
	timed = true,
	output = function(gate, Run, Reset, TickTime)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( Run > 0 ) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= TickTime) then
				gate.Accum = gate.Accum - TickTime
				return 1
			end
		end
		return 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, TickTime)
		return "Run:"..Run.." Reset:"..Reset.."TickTime:"..TickTime.." = "..Out
	end
}

GateActions["squarepulse"] = {
	name = "Square Pulse",
	description = "Outputs Max during the PulseTime, Min during the GapTime, while Run is set.",
	inputs = { "Run", "Reset", "PulseTime", "GapTime", "Min", "Max" },
	timed = true,
	output = function(gate, Run, Reset, PulseTime, GapTime, Min, Max)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime

		if (Reset > 0) then
			gate.Accum = 0
		elseif (Run > 0) then
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum <= PulseTime) then
				return Max
			end
			if (gate.Accum >= PulseTime + GapTime) then
				gate.Accum = 0
			end
		end
		return Min
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, PulseTime, GapTime)
		return "Run:"..Run.." Reset:"..Reset.." PulseTime:"..PulseTime.." GapTime:"..GapTime.." = "..Out
	end
}

GateActions["sawpulse"] = {
	name = "Saw Pulse",
	description = "Outputs a value that linearly increases to Max and decreases to Min while Run is set.",
	inputs = { "Run", "Reset", "SlopeRaiseTime", "PulseTime", "SlopeDescendTime", "GapTime", "Min", "Max" },
	timed = true,
	output = function(gate, Run, Reset, SlopeRaiseTime, PulseTime, SlopeDescendTime, GapTime, Min, Max)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime

		if Reset > 0 then
			gate.Accum = 0
			return Min
		end
		if Run <= 0 then
			return Min
		end

		SlopeRaiseTime = math.max(SlopeRaiseTime, 0)
		PulseTime = math.max(PulseTime, 0)
		SlopeDescendTime = math.max(SlopeDescendTime, 0)
		GapTime = math.max(GapTime, 0)

		gate.Accum = (gate.Accum + DeltaTime) % (SlopeRaiseTime + PulseTime + SlopeDescendTime + GapTime)
		if gate.Accum < SlopeRaiseTime then
			return Min + (Max - Min) * gate.Accum / SlopeRaiseTime
		elseif gate.Accum < SlopeRaiseTime + PulseTime then
			return Max
		elseif gate.Accum < SlopeRaiseTime + PulseTime + SlopeDescendTime then
			return Max + (Min - Max) * (gate.Accum - SlopeRaiseTime - PulseTime) / SlopeDescendTime
		else
			return Min
		end
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Reset, PulseTime, GapTime)
		return "Run:"..Run.." Reset:"..Reset.." PulseTime:"..PulseTime.." GapTime:"..GapTime.." = "..Out
	end
}


GateActions["derive"] = {
	name = "Derivative",
	description = "Outputs the rate of change (derivative) of the number.",
	inputs = {"A"},
	timed = true,
	output = function(gate, A)
		local t = CurTime()
		local dT = t - gate.LastT
		gate.LastT = t
		local dA = A - gate.LastA
		gate.LastA = A
		if dT ~= 0 then
			return dA/dT
		else
			return 0;
		end
	end,
	reset = function(gate)
		gate.LastT = CurTime()
		gate.LastA = 0
	end,
	label = function(Out, A)
		return "d/dt["..A.."] = "..Out
	end
}

GateActions["delay"] = {
	name = "Delay",
	description = "Holds an output of 1 for Hold seconds after Delay seconds on Clk.",
	inputs = { "Clk", "Delay", "Hold", "Reset" },
	outputs = { "Out", "TimeElapsed", "Remaining" },
	timed = true,
	output = function(gate, Clk, Delay, Hold, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		local out = 0

		if ( Reset > 0 ) then
			gate.Stage = 0
			gate.Accum = 0
		end

		if ( gate.Stage == 1 ) then
			if ( gate.Accum >= Delay ) then
				gate.Stage = 2
				gate.Accum = 0
				out = 1
			else
				gate.Accum = gate.Accum+DeltaTime
			end
		elseif ( gate.Stage == 2 ) then
			if ( gate.Accum >= Hold ) then
				gate.Stage = 0
				gate.Accum = 0
				out = 0
			else
				out = 1
				gate.Accum = gate.Accum+DeltaTime
			end
		else
			if ( Clk > 0 ) then
				gate.Stage = 1
				gate.Accum = 0
			end
		end

		return out, gate.Accum, Delay-gate.Accum
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
		gate.Stage = 0
	end,
	label = function(Out, Clk, Delay, Hold, Reset)
		return "Clk: "..Clk.." Delay: "..Delay..
		"\nHold: "..Hold.." Reset: "..Reset..
		"\nTime Elapsed: "..Out.TimeElapsed.." = "..Out.Out
	end
}


GateActions["monostable"] = {
	name = "Monostable Timer",
	description = "Outputs 1 for Time duration and resets to 0 for a tick in between.",
	inputs = { "Run", "Time", "Reset" },
	timed = true,
	output = function(gate, Run, Time, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif gate.Accum > 0 or Run > 0 then
			gate.Accum = gate.Accum+DeltaTime
			if(gate.Accum > Time) then
				gate.Accum = 0
			end
		end
		if(gate.Accum > 0)then
			return 1
		else
			return 0
		end
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		gate.Accum = 0
	end,
	label = function(Out, Run, Time, Reset)
		return "Run:"..Run.." Time:"..Time.." Reset:"..Reset.." = "..Out
	end
}

GateActions()
