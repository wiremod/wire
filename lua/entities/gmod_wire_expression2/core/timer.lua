--[[
	Timers
]]

---@type table<Entity, { lookup: table<string, true>, count: integer }>
local Timers = {}

--- Max timers that can exist at one time per chip.
local MAX_TIMERS = CreateConVar("wire_expression2_timer_max", 100)

local function addTimer(self, name, delay, reps, callback)
	local timers = Timers[self]
	if not timers.lookup[name] then
		timers.lookup[name] = true
		timers.count = timers.count + 1

		if timers.count > MAX_TIMERS:GetInt() then
			return self:throw("Hit per-chip timer limit of " .. MAX_TIMERS:GetInt() .. "!", nil)
		end
	end

	timer.Create(("e2timer_%p_%s"):format(self, name), math.max(delay, 1e-2), reps, callback)
end

local function removeTimer(self, name)
	local timers = Timers[self]
	if timers.lookup[name] then
		timers.lookup[name] = nil
		timers.count = timers.count - 1

		timer.Remove(("e2timer_%p_%s"):format(self, name))
	end
end

registerCallback("construct", function(self)
	Timers[self] = { lookup = {}, count = 0 }
end)

registerCallback("destruct", function(self)
	for name in pairs(Timers[self].lookup) do
		removeTimer(self, name)
	end

	Timers[self] = nil
end)

__e2setcost(25)

---@param self RuntimeContext
local function MAKE_TRIGGER(id, self)
	return function()
		self.data.timer = id

		Timers[self].lookup[id] = nil

		if self.entity and self.entity.Execute then
			self.entity:Execute()
		end

		if
			Timers[self] -- This case is needed if chip tick quotas, which would call destruct hook on :Execute().
			and not Timers[self].lookup[id]
		then
			removeTimer(self, id) -- only remove if not immediately re-created
		end

		self.data.timer = nil
	end
end

[deprecated = "Use the timer function with callbacks instead"]
e2function void interval(rv1)
	addTimer(self, "interval", rv1 / 1000, 1, MAKE_TRIGGER("interval", self))
end

[deprecated = "Use the timer function with callbacks instead"]
e2function void timer(string rv1, rv2)
	addTimer(self, rv1, rv2 / 1000, 1, MAKE_TRIGGER(rv1, self))
end

__e2setcost(5)

e2function void stoptimer(string rv1)
	removeTimer(self, rv1)
end

__e2setcost(1)

[nodiscard, deprecated = "Use the timer function with callbacks instead"]
e2function number clk()
	return self.data.timer == "interval" and 1 or 0
end

[nodiscard, deprecated = "Use the timer function with callbacks instead"]
e2function number clk(string rv1)
	return self.data.timer == rv1 and 1 or 0
end

[nodiscard, deprecated = "Use the timer function with callbacks instead"]
e2function string clkName()
	return self.data.timer or ""
end

__e2setcost(5)

[nodiscard, deprecated = "You should keep track of timers with callbacks instead"]
e2function array getTimers()
	local ret, timers = {}, Timers[self]
	self.prf = self.prf + timers.count * 2

	local i = 0
	for name in pairs(timers.lookup) do
		i = i + 1
		ret[i] = name
	end

	return ret
end

e2function void stopAllTimers()
	local timers = Timers[self]
	self.prf = self.prf + timers.count * 2

	for name in pairs(timers.lookup) do
		removeTimer(self, name)
	end
end

--[[
	Timers 2.0
]]

__e2setcost(15)

local simpletimer = 1

e2function void timer(number delay, function callback)
	local fn, ent = callback:Unwrap("", self), self.entity

	simpletimer = (simpletimer + 1) % (MAX_TIMERS:GetInt() * 100000000) -- if this ends up overwriting other timers you have a much bigger problem. wrap to avoid inf.
	local name = tostring(simpletimer)

	addTimer(self, name, delay, 1, function()
		removeTimer(self, name)
		ent:Execute(fn)
	end)
end

e2function void timer(string name, number delay, function callback)
	local fn, ent = callback:Unwrap("", self), self.entity
	addTimer(self, name, delay, 1, function()
		removeTimer(self, name)
		ent:Execute(fn)
	end)
end

e2function void timer(string name, number delay, number reps, function callback)
	local fn, ent, rep = callback:Unwrap("", self), self.entity, 0
	addTimer(self, name, delay, reps, function()
		rep = rep + 1
		if rep == reps then
			removeTimer(self, name)
		end

		ent:Execute(fn)
	end)
end

--[[
	Time Monitoring
]]

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

--[[
	Datetime
]]

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

[nodiscard]
e2function table dateUTC( time )
	return luaDateToE2Table(time,true)
end

-- This function has a strange and slightly misleading name, but changing it might break older E2s, so I'm leaving it
-- It's essentially the same as the date function above
[nodiscard]
e2function number time(string component)
	local ostime = os.date("!*t")
	local ret = ostime[component]

	return tonumber(ret) or ret and 1 or 0 -- the later parts account for invalid components and isdst
end


-----------------------------------------------------------------------------------

__e2setcost(2)

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
