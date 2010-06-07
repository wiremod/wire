--[[
dataSignal
Made by Divran
Thanks to Syranide for helping.

dataSignals are a combination of signals and gvars.
Instead of using one to trigger the E2, and the other
to send the data, dataSignals can both trigger the E2 AND
send the data at the same time.

Have fun!
]]

---------------------------------------------
-- Lua helper functions

local currentsignal
local runbydatasignal = 0

local groups = {}
local queue = {}

-----------------
-- Check if the signal should be allowed
local function IsAllowed( fromscope, froment, toscope, toent )
	if (fromscope == 0) then -- If scope is 0, only send to E2s you own
		return E2Lib.isOwner( froment, toent )
	elseif (fromscope == 1) then -- If scope is 1, send to people who have you in their PP friends list, and E2s you own
		return (E2Lib.isFriend( toent.player, froment.player ) and toscope > 0)
	elseif (fromscope == 2) then -- If scope is 2, send to everyone
		if (E2Lib.isOwner( froment, toent )) then -- If you are the owner, go ahead
			return true
		else -- else check if the recieving E2 allows your signal
			if (toscope == 1) then -- if recieving scope is 1, return true if they have you in their pp friends list
				return E2Lib.isFriend( toent.player, froment.player )
			elseif (toscope == 2) then -- if recieving scope is 2, return true
				return true
			end
		end
	end
	return false
end

--------------
-- Queue
local QueueIndex = 1

local function CheckQueue( ent )
	if (#queue == 0) then return end
	if (runbydatasignal == 1) then return end
	runbydatasignal = 1

	while true do
		if (QueueIndex > #queue) then break end
		if (queue[QueueIndex] == nil) then break end
		local s = queue[QueueIndex]
			if (s.to and s.to:IsValid()) then
				currentsignal = s
				s.to:Execute()
			end
		QueueIndex = QueueIndex + 1
	end

	currentsignal = nil
	runbydatasignal = 0
	QueueIndex = 1
	queue = {}
end

registerCallback("postexecute",function(self)
	CheckQueue(self.entity)
end)

------------
-- Sending from one E2 to another

local function E2toE2( signalname, fromscope, from, toscope, to, var, vartype, groupname ) -- For sending from an E2 to another E2
	if (!from or !from:IsValid() or from:GetClass() != "gmod_wire_expression2") then return 0 end -- Failed
	if (!to or !to:IsValid() or to:GetClass() != "gmod_wire_expression2") then return 0 end -- Failed
	if (!from.context or !to.context) then return 0 end -- OSHI-
	if (!fromscope) then fromscope = from.context.datasignal.scope end
	if (!toscope) then toscope = to.context.datasignal.scope end
	if (!IsAllowed( fromscope, from, toscope, to )) then return 0 end -- Not allowed.
	if (!var or !vartype) then return 0 end -- Failed

	queue[#queue+1] = { name = signalname, from = from, to = to, var = var, vartype = vartype, groupname = groupname } -- Add to queue
	from.context.prf = from.context.prf + 80 -- Add 80 to ops

	return 1 -- Transfer successful
end

---------------------
-- Send from one E2 to an entire group of E2s
local function E2toGroup( signalname, from, groupname, scope, var, vartype ) -- For sending from an E2 to an entire group. Returns 0 if ANY of the sends failed
	if (groupname == nil) then return 0 end
	if (scope == nil) then scope = from.context.datasignal.scope end

	local ret = 1
	if (groups[groupname]) then
		for k,v in pairs( groups[groupname] ) do
			local toent = k -- Get the entity
			if (!toent or !toent:IsValid()) then -- If the E2 was removed without calling destruct, clear it now.
				groups[groupname][k] = nil
			else
				if (toent != from) then
					local tempret = E2toE2( signalname, scope, from, toent.context.datasignal.scope, toent, var, vartype, groupname ) -- Send the signal
					if (tempret == 0) then -- Did the send fail?
						ret = 0
					end
				end
			end
		end
	else
		return 0
	end
	return ret
end

local function JoinGroup( self, groupname )
	-- Is the E2 already in that group?
	if (table.HasValue( self.data.datasignal.groups, groupname )) then return end

	-- Else add it
	table.insert( self.data.datasignal.groups, groupname )

	-- If that group does not exist, create it
	if (!groups[groupname]) then
		groups[groupname] = {}
	end

	-- Add the E2 to that group
	groups[groupname][self.entity] = true
end

local function LeaveGroup( self, groupname )
	-- Is the E2 in that group?
	if (!table.HasValue( self.data.datasignal.groups, groupname )) then return end

	-- Else remove it
	for k,v in pairs( self.data.datasignal.groups ) do
		if (v == groupname) then
			table.remove( self.data.datasignal.groups, k )
			break
		end
	end

	-- Remove the E2 from the group
	groups[groupname][self.entity] = nil

	-- If there are no more E2s in this group, remove it
	if (table.Count(groups[groupname]) == 0) then
		groups[groupname] = nil
	end
end

-- Get a table of E2s which the signal would have been sent to if it was sent
local function GetE2s( froment, groupname, scope )
	local ret = {}

	if (groups[groupname]) then
		for k,v in pairs( groups[groupname] ) do
			local ent = k
			if (!ent or !ent:IsValid()) then -- If the E2 was removed without calling destruct, clear it now.
				groups[groupname][k] = nil
			else
				if (froment != ent) then
					if (IsAllowed( scope, froment, ent.context.datasignal.scope, ent )) then
						table.insert( ret, ent )
					end
				end
			end
		end
	end

	return ret
end

-- Upperfirst, used by the E2 functions below
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

---------------------------------------------
-- E2 functions

registerCallback("postinit",function()

	-- Add support for EVERY SINGLE type. Yeah!!
	for k,v in pairs( wire_expression_types ) do
		if (k == "NORMAL") then k = "NUMBER" end
		k = string.lower(k)

		__e2setcost(10)

		-- Send a signal directly to another E2
		registerFunction("dsSendDirect","se"..v[1],"n",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)
			return E2toE2( rv1, 2, self.entity, nil, rv2, rv3, k )
		end)

		__e2setcost(15)

		registerFunction("dsSendDirect","sr"..v[1],"n",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)
			local ret = 1
			for _,e2 in ipairs( rv2 ) do
				local temp = E2toE2( rv1, 2, self.entity, nil, e2, rv3, k )
				if (temp == 0) then ret = 0 end
			end
			return ret
		end)

		__e2setcost(20)

		-- Send a ds to the group <rv2> in the E2s scope
		registerFunction("dsSend","ss"..v[1],"n",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)
			return E2toGroup( rv1, self.entity, rv2, nil, rv3, k )
		end)

		-- Send a ds to the group <rv2> in scope <rv3>
		registerFunction("dsSend","ssn"..v[1],"n",function(self,args)
			local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
			local rv1, rv2, rv3, rv4 = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3),op4[1](self,op4)
			return E2toGroup( rv1, self.entity, rv2, rv3, rv4, k )
		end)

		__e2setcost(5)

		-- Get variable
		registerFunction("dsGet" .. upperfirst( k ), "", v[1], function(self,args)
			if (!currentsignal) then return v[2] end -- If the current execution was not caused by a signal, return the type's default value
			if (!currentsignal.vartype or currentsignal.vartype != k) then return v[2] end -- If the type is not that type, return the type's default value
			return currentsignal.var or v[2]
		end)

	end -- loop

end) -- postinit

__e2setcost(10)

e2function void dsClearGroups()
	if (self.data.datasignal.groups) then
		if (#self.data.datasignal.groups>0) then
			for k,v in ipairs( self.data.datasignal.groups ) do
				if (groups[v]) then
					if (groups[v][self.entity] == true) then
						groups[v][self.entity] = nil
					end
					if (table.Count(groups[v]) == 0) then
						groups[v] = nil
					end
				end
			end
		end
	end
	self.data.datasignal.groups = {}
end

-- Join group
e2function void dsJoinGroup( string groupname )
	JoinGroup( self, groupname )
end

e2function void dsLeaveGroup( string groupname )
	LeaveGroup( self, groupname )
end

__e2setcost(5)

-- Get all groups in an array
e2function array dsGetGroups()
	return self.data.datasignal.groups or {}
end

-- 0 = only you, 1 = only pp friends, 2 = everyone
e2function void dsSetScope( number scope )
	self.data.datasignal.scope = math.Clamp(math.Round(scope),0,2)
end

-- Get current scope
e2function number dsGetScope()
	return self.data.datasignal.scope
end

----------------
-- Get functions

__e2setcost(1)

-- Check if the current execution was caused by ANY datasignal
e2function number dsClk()
	return runbydatasignal
end

-- Check if the current execution was caused by a datasignal named <name>
e2function number dsClk( string name )
	if (!currentsignal) then return 0 end
	if (currentsignal.name == name) then return runbydatasignal else return 0 end
end

-- Returns the name of the current signal
e2function string dsClkName()
	if (!currentsignal) then return "" end
	return currentsignal.name or ""
end

__e2setcost(4)

-- Get the type of the current data
e2function string dsGetType()
	if (!currentsignal) then return "" end
	return currentsignal.vartype or ""
end

-- Get which E2 sent the data
e2function entity dsGetSender()
	if (!currentsignal) then return nil end
	if (!currentsignal.sender or !currentsignal.sender:IsValid()) then return nil end
	return currentsignal.sender
end

-- Get the group which the signal was sent to
e2function string dsGetGroup()
	if (!currentsignal) then return "" end
	return currentsignal.groupname or ""
end

__e2setcost(20)

-- Get all E2s which would have recieved a signal if you had sent it to this group and the E2s scope
e2function array dsProbe( string groupname )
	return GetE2s( self.entity, groupname, self.data.datasignal.scope )
end

-- Get all E2s which would have recieved a signal if you had sent it to this group and scope
e2function array dsProbe( string groupname, number scope )
	return GetE2s( self.entity, groupname, math.Clamp(math.Round(scope),0,2) )
end

__e2setcost(nil)

---------------------------------------------
-- When an E2 is removed, clear it from the groups table
registerCallback("destruct",function(self)
	if (self.data.datasignal.groups) then
		if (#self.data.datasignal.groups > 0) then
			for k,v in pairs( self.data.datasignal.groups ) do
				if (groups[v]) then
					groups[v][self.entity] = nil
					if (table.Count(groups[v]) == 0) then
						groups[v] = nil
					end
				end
			end
		end
	end
end)

-- When an E2 is spawned, set its group and scope to the defaults
registerCallback("construct",function(self)
	self.data.datasignal = {}
	self.data.datasignal.groups = {}
	self.data.datasignal.scope = 0
end)
