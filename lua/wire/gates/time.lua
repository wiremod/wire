--[[
		Time Gates
]]

GateActions("Time")

GateActions["accumulator"] = {
	name = "Accumulator",
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
	inputs = { "Run", "Reset", "SlopeRaiseTime", "PulseTime", "SlopeDescendTime", "GapTime", "Min", "Max" },
	timed = true,
	output = function(gate, Run, Reset, SlopeRaiseTime, PulseTime, SlopeDescendTime, GapTime, Min, Max)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime

		if (Reset > 0) then
			gate.Accum = 0
		elseif (Run > 0) then
			local val = Min
			gate.Accum = gate.Accum+DeltaTime
			if (gate.Accum >= 0) && (gate.Accum < SlopeRaiseTime) then
				if (SlopeRaiseTime != 0) then
					val = Min + (Max-Min) * (gate.Accum-0) / SlopeRaiseTime
				end
			end
			if (gate.Accum >= SlopeRaiseTime) && (gate.Accum < SlopeRaiseTime+PulseTime) then
				return Max
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime) && (gate.Accum < SlopeRaiseTime+PulseTime+SlopeDescendTime) then
				if (SlopeDescendTime != 0) then
					val = Min + (Max-Min) * (gate.Accum-SlopeRaiseTime+PulseTime) / SlopeDescendTime
				end
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime+SlopeDescendTime) then
			end
			if (gate.Accum >= SlopeRaiseTime+PulseTime+SlopeDescendTime+GapTime) then
				gate.Accum = 0
			end
			return val
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


GateActions["derive"] = {
	name = "Derivative",
	inputs = {"A"},
	timed = false,
	output = function(gate, A)
		local t = CurTime()
		local dT = t - gate.LastT
		gate.LastT = t
		local dA = A - gate.LastA
		gate.LastA = A
		if (dT != 0) then
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
	inputs = { "Run", "Time", "Reset" },
	timed = true,
	output = function(gate, Run, Time, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if ( Reset > 0 ) then
			gate.Accum = 0
		elseif ( gate.Accum > 0 || Run > 0 ) then
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
