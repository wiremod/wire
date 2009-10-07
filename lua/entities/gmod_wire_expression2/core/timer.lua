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
		timer.Destroy("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end

	runner = nil
end

local function AddTimer(self, name, delay)
	if delay < 10 then delay = 10 end

	if runner == name then
		timer.Adjust("e2_" .. self.data['timer'].timerid .. "_" .. name, delay/1000, 1, Execute, self, name)
		timer.Start("e2_" .. self.data['timer'].timerid .. "_" .. name)
	elseif !self.data['timer'].timers[name] then
		timer.Create("e2_" .. self.data['timer'].timerid .. "_" .. name, delay/1000, 1, Execute, self, name)
	end

	self.data['timer'].timers[name] = true
end

local function RemoveTimer(self, name)
	if self.data['timer'].timers[name] then
		timer.Destroy("e2_" .. self.data['timer'].timerid .. "_" .. name)
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

registerFunction("interval", "n", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	AddTimer(self, "interval", rv1)
end)

registerFunction("timer", "sn", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	AddTimer(self, rv1, rv2)
end)

registerFunction("stoptimer", "s", "", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	RemoveTimer(self, rv1)
end)

registerFunction("clk", "", "n", function(self, args)
	if runner == "interval"
	   then return 1 else return 0 end
end)

registerFunction("clk", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if runner == rv1
	   then return 1 else return 0 end
end)

registerFunction("curtime", "", "n", function(self, args)
	return CurTime()
end)

registerFunction("realtime", "", "n", function(self, args)
	return SysTime()
end)

__e2setcost(nil)
