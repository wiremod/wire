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

e2function string clkName()
	return runner or ""
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

-----------------------------------------------------------------------------------

local function luaDateToE2Table( time, utc )
	local ret = {n={},ntypes={},s={},stypes={},size=0}
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

-- Returns the time in seconds
e2function number time()
	return os.time()
end

-- Attempts to construct the time from the data in the given table (same as lua's os.time)
-- The table structure must be the same as in the above date functions
-- If any values are missing or of the wrong type, that value is ignored (it will be nil)
local validkeys = {hour = true, min = true, day = true, sec = true, yday = true, wday = true, month = true, year = true, isdst = true}
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
