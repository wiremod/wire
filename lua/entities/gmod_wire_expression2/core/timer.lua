/******************************************************************************\
  Timer support
\******************************************************************************/

local wire_expression2_timers_limit = CreateConVar("wire_expression2_timers_limit", 100, FCVAR_ARCHIVE, "The maximum number of timers that can be created by an E2 chip")
local timerid = 0

local function Execute(self, name)
	self.data.timer.runner = name

	self.data['timer'].timers[name] = nil

	if(self.entity and self.entity.Execute) then
		self.entity:Execute()
	end

	if !self.data['timer'].timers[name] then
		timer.Remove("e2_" .. self.data['timer'].timerid .. "_" .. name)
	end

	self.data.timer.runner = nil
end

local function AddTimer(self, name, delay)
	if delay < 10 then delay = 10 end

	local timerName = "e2_" .. self.data.timer.timerid .. "_" .. name

	if self.data.timer.runner == name and timer.Exists(timerName) then
		timer.Adjust(timerName, delay / 1000, 2, function()
			Execute(self, name)
		end)
		timer.Start(timerName)
	elseif !self.data['timer'].timers[name] then
		timer.Create(timerName, delay / 1000, 2, function()
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

-- Lambda timers

local luaTimers = {
	/*EXAMPLE:
	'[342]e2entity' = {
		[342]e2entity_gmod_wire_expression2_luatimer_examplename = {
			context = {...} (e2 context),
			callback = {...} (e2 callback),
			delay = 1,
			repetitions = 1
		}
	}
	*/
}

local luaTimerIncrementalKeys = {}

local function luaTimerGetNextIncrementalKey(self)
	local key = (luaTimerIncrementalKeys[self.entity:EntIndex()] or 0)+1
	luaTimerIncrementalKeys[self.entity:EntIndex()] = key
	return key
end

local function luaTimerGetInternalName(entIndex, name)
	return entIndex .. '_gmod_wire_expression2_luatimer_' .. name
end

local function luaTimerExists(self, name)
	local tbl = luaTimers[self.entity:EntIndex()]
	return tbl and tbl[name] and true or false
end

local function luaTimerCreate(self, name, delay, repetitions, callback)
	local entIndex = self.entity:EntIndex()

	if not luaTimers[entIndex] then
		luaTimers[entIndex] = {}
	elseif luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " already exists", nil)
	end

	local timerLimit = wire_expression2_timers_limit:GetInt()
	if table.Count(luaTimers[entIndex]) >= timerLimit then
		return self:throw("Timer limit reached (" .. timerLimit .. ")", nil)
	end

	local internalName = luaTimerGetInternalName(self.entity:EntIndex(), name)
	local callback, ent = callback:Unwrap("", self), self.entity

	luaTimers[entIndex][name] = {
		ent = ent,
		callback = callback,
		delay = delay,
		repetitions = repetitions
	}

	timer.Create(internalName, delay, repetitions, function()
		ent:Execute(callback)

		if timer.RepsLeft(internalName) == 0 then
			luaTimers[entIndex][name] = nil
		end
	end)
end

local function luaTimerRemove(self, name)
	local entIndex = self.entity:EntIndex()
	if not luaTimers[entIndex] then
		luaTimers[entIndex] = {}
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	elseif not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	end

	timer.Remove(luaTimerGetInternalName(self.entity:EntIndex(), name))
	luaTimers[entIndex][name] = nil
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

	local entIndex = self.entity:EntIndex()
	for k, _ in pairs(luaTimers[entIndex] or {}) do
		timer.Remove(luaTimerGetInternalName(entIndex, k))
	end

	luaTimers[entIndex] = nil
end)

/******************************************************************************/

__e2setcost(20)
[deprecated = "Use lambda timers instead"]
e2function void interval(rv1)
	AddTimer(self, "interval", rv1)
end

[deprecated = "Use lambda timers instead"]
e2function void timer(string rv1, rv2)
	AddTimer(self, rv1, rv2)
end

__e2setcost(5)
e2function void stoptimer(string rv1)
	RemoveTimer(self, rv1)
	pcall(luaTimerRemove, self, rv1)
end

__e2setcost(1)

[nodiscard, deprecated = "Use lambda timers instead"]
e2function number clk()
	return self.data.timer.runner == "interval" and 1 or 0
end

[nodiscard, deprecated = "Use lambda timers instead"]
e2function number clk(string rv1)
	return self.data.timer.runner == rv1 and 1 or 0
end

[nodiscard, deprecated = "Use lambda timers instead"]
e2function string clkName()
	return self.data.timer.runner or ""
end

e2function array getTimers()
	local ret = {}
	local i = 0
	for name in pairs( self.data.timer.timers ) do
		i = i + 1
		ret[i] = name
	end

	for k, _ in pairs( luaTimers[self.entity:EntIndex()] or {} ) do
		i = i + 1
		ret[i] = k
	end

	self.prf = self.prf + i * 5
	return ret
end

e2function void stopAllTimers()
	for name in pairs(self.data.timer.timers) do
		self.prf = self.prf + 5
		RemoveTimer(self,name)
	end

	for k, _ in pairs(luaTimers[self.entity:EntIndex()] or {}) do
		self.prf = self.prf + 5
		luaTimerRemove(self, k)
	end
end

/******************************************************************************/
-- Lambda timers

__e2setcost(10)
e2function void timer(string name, number delay, number repetitions, function callback)
	luaTimerCreate(self, name, delay, repetitions, callback)
end

e2function string timer(number delay, number repetitions, function callback)
	local name = "simpletimer_"..luaTimerGetNextIncrementalKey(self)
	luaTimerCreate(self, name, delay, repetitions, callback)
	return name
end

e2function string timer(number delay, function callback)
	local name = "simpletimer_"..luaTimerGetNextIncrementalKey(self)
	luaTimerCreate(self, name, delay, 1, callback)
	return name
end

e2function void timer(string name, number delay, function callback)
	luaTimerCreate(self, name, delay, 1, callback)
end

__e2setcost(5)
e2function void timerSetDelay(string name, number delay)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	end

	local entIndex = self.entity:EntIndex()
	luaTimers[entIndex][name].delay = delay

	timer.Adjust(luaTimerGetInternalName(entIndex, name), delay)
end

e2function number timerSetReps(string name, number repetitions)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	end

	local entIndex = self.entity:EntIndex()
	luaTimers[entIndex][name].repetitions = repetitions
	timer.Adjust(luaTimerGetInternalName(entIndex, name), luaTimers[entIndex][name].delay, repetitions)
end

e2function void timerAdjust(string name, number delay, number repetitions)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	end

	local entIndex = self.entity:EntIndex()
	luaTimers[entIndex][name].delay = delay
	luaTimers[entIndex][name].repetitions = repetitions
	timer.Adjust(luaTimerGetInternalName(entIndex, name), delay, repetitions)
end


__e2setcost(1)
[nodiscard]
e2function number timerGetDelay(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	return luaTimers[self.entity:EntIndex()][name].delay
end

[nodiscard]
e2function number timerGetReps(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	return luaTimers[self.entity:EntIndex()][name].repetitions
end

[nodiscard]
e2function function timerGetCallback(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", "")
	end

	return luaTimers[self.entity:EntIndex()][name].callback
end

__e2setcost(5)
e2function void timerRestart(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", nil)
	end

	local entIndex = self.entity:EntIndex()
	local internalName = luaTimerGetInternalName(entIndex, name)

	timer.Adjust(internalName, luaTimers[entIndex][name].delay, luaTimers[entIndex][name].repetitions)
end

__e2setcost(1)
[nodiscard]
e2function number timerExists(string name)
	return luaTimerExists(self, name) and 1 or 0
end

e2function void timerPause(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	--return timer.Pause(luaTimerGetInternalName(self.entity:EntIndex(), name)) and 1 or 0 -- This is commented due to timer.Pause being broken for some reason. It just does not return anything.
	timer.Pause(luaTimerGetInternalName(self.entity:EntIndex(), name))
end

e2function void timerResume(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	-- return timer.UnPause(luaTimerGetInternalName(self.entity:EntIndex(), name)) and 1 or 0 -- This is commented due to timer.Pause being broken for some reason. It just does not return anything.
	timer.UnPause(luaTimerGetInternalName(self.entity:EntIndex(), name))
end

e2function number timerToggle(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	--return timer.Toggle(luaTimerGetInternalName(self.entity:EntIndex(), name)) and 1 or 0 -- This is commented due to timer.Pause being broken for some reason. It just does not return anything.
	timer.Toggle(luaTimerGetInternalName(self.entity:EntIndex(), name))
end

__e2setcost(5)
[nodiscard]
e2function number timerRepsLeft(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	return timer.RepsLeft(luaTimerGetInternalName(self.entity:EntIndex(), name))
end

[nodiscard]
e2function number timerTimeLeft(string name)
	if not luaTimerExists(self, name) then
		return self:throw("Timer with name " .. name .. " does not exist", 0)
	end

	return timer.TimeLeft(luaTimerGetInternalName(self.entity:EntIndex(), name))
end

/******************************************************************************/
__e2setcost(1)
[nodiscard]
e2function number curtime()
	return CurTime()
end

[nodiscard]
e2function number realtime()
	return RealTime()
end

[nodiscard]
e2function number systime()
	return SysTime()
end

-----------------------------------------------------------------------------------

local function luaDateToE2Table( time, utc )
	local ret = E2Lib.newE2Table()
	local time = os.date((utc and "!" or "") .. "*t",time)

	if not time then return ret end -- this happens if you give it a negative time

	for k,v in pairs( time ) do
		if k == "isdst" then
			ret.s.isdst = (v and 1 or 0)
			ret.stypes.isdst = "n"
		else
			ret.s[k] = v
			ret.stypes[k] = "n"
		end

		ret.size = ret.size + 1
	end

	return ret
end
__e2setcost(10)
-- Returns the server's current time formatted neatly in a table
e2function table date()
	return luaDateToE2Table()
end

-- Returns the specified time formatted neatly in a table
e2function table date( time )
	return luaDateToE2Table(time)
end

-- Returns the server's current time formatted neatly in a table using UTC
e2function table dateUTC()
	return luaDateToE2Table(nil,true)
end

-- Returns the specified time formatted neatly in a table using UTC
e2function table dateUTC( time )
	return luaDateToE2Table(time,true)
end

-- This function has a strange and slightly misleading name, but changing it might break older E2s, so I'm leaving it
-- It's essentially the same as the date function above
e2function number time(string component)
	local ostime = os.date("!*t")
	local ret = ostime[component]

	return tonumber(ret) or ret and 1 or 0 -- the later parts account for invalid components and isdst
end


-----------------------------------------------------------------------------------

__e2setcost(2)
-- Returns the time in seconds
[nodiscard]
e2function number time()
	return os.time()
end

-- Attempts to construct the time from the data in the given table (same as lua's os.time)
-- The table structure must be the same as in the above date functions
-- If any values are missing or of the wrong type, that value is ignored (it will be nil)
local validkeys = {hour = true, min = true, day = true, sec = true, yday = true, wday = true, month = true, year = true, isdst = true}
[nodiscard]
e2function number time(table data)
	local args = {}

	for k,v in pairs( data.s ) do
		if data.stypes[k] ~= "n" or not validkeys[k] then continue end

		if k == "isdst" then
			args.isdst = (v == 1)
		else
			args[k] = v
		end
	end

	return os.time( args )
end
