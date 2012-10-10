/******************************************************************************\
  Timer support
\******************************************************************************/

local timerid = 0
local runner

local function Execute(self, name)
	runner = name

	self.data['timer'].timers[name] = nil

	if(self.entity and self.entity.Execute) then
		self.entity:Execute()
	end

	if !self.data['timer'].timers[name] then
		timer.Remove("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end

	runner = nil
end

local function AddTimer(self, name, delay)
	if delay < 10 then delay = 10 end

	if runner == name then
		timer.Adjust("e2_" .. self.data['timer'].timerid .. "_" .. name, delay/1000, 1, function()
			Execute(self, name)
		end)
		timer.Start("e2_" .. self.data['timer'].timerid .. "_" .. name)
	elseif !self.data['timer'].timers[name] then
		timer.Create("e2_" .. self.data['timer'].timerid .. "_" .. name, delay/1000, 1, function()
			Execute(self, name)
		end)
	end

	self.data['timer'].timers[name] = true
end

local function RemoveTimer(self, name)
	if self.data['timer'].timers[name] then
		timer.Remove("e2_" .. self.data['timer'].timerid .. "_" .. name)
		self.data['timer'].timers[name] = nil
	end
end

/******************************************************************************/

registerCallback("construct", function(self)
	self.data['timer'] = {}
	self.data['timer'].timerid = timerid
	self.data['timer'].timers = {}

	timerid = timerid + 1
end)

registerCallback("destruct", function(self)
	for name,_ in pairs(self.data['timer'].timers) do
		RemoveTimer(self, name)
	end
end)

/******************************************************************************/

__e2setcost(5) -- approximation

e2function void interval(rv1)
	AddTimer(self, "interval", rv1)
end

e2function void timer(string rv1, rv2)
	AddTimer(self, rv1, rv2)
end

e2function void stoptimer(string rv1)
	RemoveTimer(self, rv1)
end

e2function number clk()
	if runner == "interval"
	   then return 1 else return 0 end
end

e2function number clk(string rv1)
	if runner == rv1
	   then return 1 else return 0 end
end

e2function array getTimers()
	local ret = {}
	local i = 0
	for name,_ in pairs( self.data.timer.timers ) do
		i = i + 1
		ret[i] = name
	end
	self.prf = self.prf + i * 5
	return ret
end

e2function void stopAllTimers()
	for name,_ in pairs(self.data.timer.timers) do
		self.prf = self.prf + 5
		RemoveTimer(self,name)
	end
end

/******************************************************************************/

e2function number curtime()
	return CurTime()
end

e2function number realtime()
	return RealTime()
end

e2function number systime()
	return SysTime()
end

__e2setcost(nil)
