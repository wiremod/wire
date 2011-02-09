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

GateActions["Definite Integral"] = {
	name = "Integral",
	inputs = { "A", "Points" },
	timed = true,
	output = function(gate, A, Points)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Points<=0) then
			Points=2
			data = {}
		end
		data = data or {}
		integral=A*DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Points
		end
		data[index]=integral
		i=0
		totalintegral=0
		while (i<Points) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Points
			whichIndex=whichIndex+1
			totalintegral=totalintegral+(data[whichIndex] or 0)
			i=i+1
		end
	return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Points)
		return "A: "..A.."   Points: "..Points.."   Output: "..Out
	end,
}

GateActions["Derivative"] = {
	name = "Derivative",
	inputs = { "A" },
	timed = true,
	output = function(gate, A)
		prev5Delta= (prev4Delta or .04)
		prev4Delta= (prev3Delta or .04)
		prev3Delta= (prev2Delta or .04)
		prev2Delta= (prevDelta or .04)
		prevDelta = (DeltaT or .04)
		-- begin block: set up DeltaValue time
		prevTime=currentTime
		currentTime=CurTime()
		if (prevTime==currentTime) then
			DeltaT=.04
		else
			DeltaT=currentTime-(prevTime or 0)
		end
		prev6Value=(prev5Value or A)
		prev5Value=(prev4Value or A)
		prev5Slope=(prev5Value-prev6Value)/prev5Delta
		prev4Value=(prev3Value or A)
		prev4Slope=(prev4Value-prev5Value)/prev4Delta
		prev3Value=(prev2Value or A)
		prev3Slope=(prev3Value-prev4Value)/prev3Delta
		prev2Value=(prevValue or A)
		prev2Slope=(prev2Value-prev3Value)/prev2Delta
		prevValue=(currentValue or A)
		prevSlope=(prevValue-prev2Value)/prevDelta
		currentValue=A
		currentSlope=(prevValue-currentValue)/DeltaT
		averageSlope=((currentSlope+prevSlope+prev2Slope+prev3Slope+prev4Slope+prev5Slope)/6)
		return averageSlope
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A)
		return "Input: "..currentValue.."   Previous: "..prevValue.."   Derivative: "..Out
	end,
}

GateActions["Indefinite Integral"] = {
	name = "Indefinite Integral",
	inputs = { "A", "Reset" },
	timed = true,
	output = function(gate, A, Reset)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Reset != 0) then
			totalintegral=0
		end
		integral=A*DeltaTime
		totalintegral = (totalintegral or 0) + integral
		if (totalintegral > 100000) then
			totalintegral = 100000
		end
		if (totalintegral < -100000) then
			totalintegral = -100000
		end
		return totalintegral or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Reset)
		return "A: "..A.."  Reset: "..Reset.."   Output: "..Out
	end,
}

GateActions["Average Derivative"] = {
	name = "Average Derivative",
	inputs = { "A", "Window" },
	timed = true,
	output = function(gate, A, Window)
		local DeltaTime = CurTime()-(gate.PrevTime or CurTime())
		gate.PrevTime = (gate.PrevTime or CurTime())+DeltaTime
		if(Window<=0) then
			Window=2
			data = {}
		end
		data = data or {}
		prevA=currentA or A
		currentA=A
		derivative=(currentA-prevA)/DeltaTime
		if (index == nil) then
			index=1
		else
			index=(index+1)%Window
		end
		data[index]=derivative
		i=0
		sum=0
		while (i<Window) do
			whichIndex=(index-i)
			whichIndex=whichIndex%Window
			whichIndex=whichIndex+1
			sum=sum+(data[whichIndex] or 0)
			i=i+1
		end
		averageDerivative=(sum/Window)
	return averageDerivative or 0
	end,
	reset = function(gate)
		gate.PrevTime = CurTime()
		data = {}
	end,
	label = function(Out, A, Window)
		return "A: "..A.."   Window: "..Window.."   Output: "..Out
	end,
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

GateActions["bstimer"] = {
	name = "BS_Timer",
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

		for i = 1,50 do
			local bs = gate.Entity:GetPos()
			local bs1 = gate.Entity:GetAngles()
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

GateActions()
