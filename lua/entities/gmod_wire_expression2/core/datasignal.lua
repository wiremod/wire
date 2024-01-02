--[[
dataSignal optimized
Made by Divran

dataSignals are a combination of signals and gvars.
Instead of using one to trigger the E2, and the other
to send the data, dataSignals can both trigger the E2 AND
send the data at the same time.

Have fun!
]]

E2Lib.RegisterExtension( "datasignal", true, "Allows users to trigger remote actions on other E2s to transmit data and actions.", "Superceded by event remote" )

local groups = {}
local queue = {}

local isOwner = E2Lib.isOwner
local isFriend = E2Lib.isFriend
local getHash = E2Lib.getHash
local copy = table.Copy
local remove = table.remove
local c = math.Clamp
local f = math.floor

---------------------------------------------
-- Lua helper functions
---------------------------------------------


---------------------------------------------
-- IsAllowed
-- Check if an E2 is allowed to send a signal to another E2
---------------------------------------------
--[[
	When sending:
		Scope = 0 -> Only send to E2s you own.
		Scope = 1 -> Send to E2s you own and to people who have you in their PP friends list.
		Scope = 2 -> Send to everyone.

	When receiving:
		Scope = 0 -> Only receive from E2s you own.
		Scope = 1 -> Receive from E2s you own and from people who have you in their PP friends list.
		Scope = 2 -> Receive from everyone.
]]

local function isOwner( froment, toent ) -- we need a more strict isOwner than E2's default implementation, which also checks isFriend
	return froment.player == toent.player
end

local function IsAllowed( froment, toent, fromscope, signaltype )
	if not froment or not froment:IsValid() or froment:GetClass() ~= "gmod_wire_expression2" then return false end
	if not toent or not toent:IsValid() or toent:GetClass() ~= "gmod_wire_expression2" then return false end

	if signaltype ~= "direct" and froment == toent then return false end -- Can't send to the same E2 (if it's a group signal)

	local toscope = toent.context.data.datasignal.scope

	if (fromscope == 2 and toscope == 2) or isOwner(froment, toent) then -- both scopes are 2 or the receiver E2 is yours
		return true
	elseif fromscope == 2 and toscope == 1 and isFriend( toent.player, froment.player ) then -- if sending to everyone, and receiving from only friends, check if receiver is friend with sender
		return true
	elseif fromscope == 1 then -- send only to friends
		if toscope == 2 then -- receiving from all, check only if sender is friend with receiver
			return isFriend( froment.player, toent.player )
		elseif toscope == 1 then -- receiving from friends, check both if sender is friend with receiver and if receiver is friend with sender
			return 	isFriend( froment.player, toent.player ) and
					isFriend( toent.player, froment.player )
		end
	end

	return false -- Any other outcome is false
end

---------------------------------------------
-- processQueue
---------------------------------------------

local function processQueue()
	if #queue == 0 then return end

	local temp = queue
	local size = #queue
	queue = {}

	for i=1,#temp do
		local currentsignal = temp[i]

		if not currentsignal.from or not currentsignal.from:IsValid() then continue end
		if not currentsignal.to or not currentsignal.to:IsValid() then continue end

		currentsignal.to.context.data.currentsignal = currentsignal
		currentsignal.to:Execute()
		currentsignal.to.context.data.currentsignal = nil
	end

	if next(queue) ~= nil then
		timer.Simple( 0, processQueue )
	end
end

registerCallback("postexecute",function(self)
	if self.entity.removing then
		processQueue()
	else
		timer.Simple( 0, processQueue )
	end
end)

---------------------------------------------
-- addQueue
-- Add an item to the queue
---------------------------------------------
local function addQueue( item )
	queue[#queue+1] = item
end


---------------------------------------------
-- sendSignalToE2
-- Check if any signals are in the queue, waiting to be sent
-- Returns true on success, false on failure
---------------------------------------------
local function sendSignalToE2( from, fromscope, to, signalname, groupname, var, vartype, signaltype )
	signaltype = signaltype or "direct" -- default to "direct"

	if not IsAllowed( from, to, fromscope, signaltype ) then return false end

	from.context.prf = from.context.prf + 80

	local item = {
		from = from,
		fromscope = fromscope,
		to = to,
		name = signalname,
		groupname = groupname,
		var = var,
		vartype = vartype,
		hash = getHash( from.context, from.buffer ),
	}

	addQueue( item )
	return true
end

---------------------------------------------
-- sendSignalToGroup
-- Sends a signal to every valid target in a group
-- Returns false if any one (or all) fails, else true
---------------------------------------------
local function sendSignalToGroup( from, fromscope, signalname, groupname, var, vartype )
	local group = groups[groupname]
	if not group then return 0 end

	local ret = true
	for e2,_ in pairs( group ) do
		if not sendSignalToE2( from, fromscope, e2, signalname, groupname, var, vartype, "group" ) then
			ret = false
		end
	end

	return ret
end

---------------------------------------------
-- probeGroup
-- Returns an array of E2s that would receive the signal if it was sent to the specified target
---------------------------------------------
local function probeGroup( from, fromscope, groupname )
	local ret = {}

	if groups[groupname] then
		for e2,_ in pairs( groups[groupname] ) do
			if IsAllowed( from, e2, fromscope, "group" ) then
				ret[#ret+1] = e2
			end
		end
	end

	return ret
end

---------------------------------------------
-- joinGroup
-- Make an e2 join a group
---------------------------------------------
local function joinGroup( self, groupname )
	-- Is the E2 already in that group?
	local grps = self.data.datasignal.groups
	for i=1,#grps do
		if grps[i] == groupname then return end
	end

	-- Else add it
	grps[#grps+1] = groupname

	-- If that group does not exist, create it
	if not groups[groupname] then
		groups[groupname] = {}
	end

	-- Add the E2 to that group
	groups[groupname][self.entity] = true
end

---------------------------------------------
-- leaveGroup
-- Make an e2 leave a group
---------------------------------------------
local function leaveGroup( self, groupname )
	-- Is the E2 in that group?
	local grps = self.data.datasignal.groups
	local found
	for i=1,#grps do
		if grps[i] == groupname then found = i break end
	end
	if not found then return end

	-- Else remove it
	remove( grps, found )

	-- Remove the E2 from the group
	groups[groupname][self.entity] = nil

	-- If there are no more E2s in this group, remove it
	if (next(groups[groupname]) == nil) then
		groups[groupname] = nil
	end
end

-- Upperfirst, used by the E2 functions below
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

---------------------------------------------
-- E2 functions
---------------------------------------------

local non_allowed_types = { xgt = true } -- If anyone can think of any other types that should never be allowed, enter them here.

local fixDefault = E2Lib.fixDefault

registerCallback("postinit",function()
	-- Add support for EVERY SINGLE type. Yeah!!
	for k,v in pairs( wire_expression_types ) do
		if not non_allowed_types[v[1]] then

			if (k == "NORMAL") then k = "NUMBER" end
			k = string.lower(k)

			__e2setcost(10)

			-- Send a signal directly to another E2
			registerFunction("dsSendDirect","se"..v[1],"n",function(self,args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local signalname, to, var = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)
				return sendSignalToE2( self.entity, 2, to, signalname, "", var, k ) and 1 or 0
			end)

			__e2setcost(15)

			registerFunction("dsSendDirect","sr"..v[1],"n",function(self,args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local signalname, array, var = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)
				local ret = 1
				for i=1,#array do
					if not sendSignalToE2( self.entity, 2, array[i], signalname, "", var, k ) then
						ret = 0
					end
				end
				return ret
			end)

			__e2setcost(20)

			-- Send a ds to the group <rv2> in the E2s scope
			registerFunction("dsSend","ss"..v[1],"n",function(self,args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local signalname, groupname, var = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3)

				return sendSignalToGroup( self.entity, self.data.datasignal.scope, signalname, groupname, var, k ) and 1 or 0
			end)

			-- Send a ds to the group <rv2> in scope <rv3>
			registerFunction("dsSend","ssn"..v[1],"n",function(self,args)
				local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
				local signalname, groupname, scope, var = op1[1](self, op1),op2[1](self, op2),op3[1](self,op3),op4[1](self,op4)

				return sendSignalToGroup( self.entity, scope, signalname, groupname, var, k ) and 1 or 0
			end)

			__e2setcost(5)

			-- Get variable
			registerFunction("dsGet" .. upperfirst( k ), "", v[1], function(self,args)
				if not self.data.currentsignal or self.data.currentsignal.vartype ~= k then return fixDefault(v[2]) end
				return self.data.currentsignal.var
			end)

		end -- allowed check
	end -- loop
end) -- postinit

__e2setcost(10)

-- Leave all groups
e2function void dsClearGroups()
	for i=1,#self.data.datasignal.groups do
		local name = self.data.datasignal.groups[i]
		if (groups[name]) then
			if (groups[name][self.entity] == true) then
				groups[name][self.entity] = nil
			end
			if (next(groups[name]) == nil) then
				groups[name] = nil
			end
		end
	end
	self.data.datasignal.groups = {}
end

-- Join group
e2function void dsJoinGroup( string groupname )
	joinGroup( self, groupname )
end

-- Leave group
e2function void dsLeaveGroup( string groupname )
	leaveGroup( self, groupname )
end

__e2setcost(5)

-- Get all groups in an array
e2function array dsGetGroups()
	return self.data.datasignal.groups or {}
end

-- 0 = only you, 1 = only pp friends, 2 = everyone
e2function void dsSetScope( number scope )
	self.data.datasignal.scope = c(f(scope),0,2)
end

-- Get current scope
e2function number dsGetScope()
	return self.data.datasignal.scope
end

__e2setcost(1)

-- Check if the current execution was caused by ANY datasignal
e2function number dsClk()
	return self.data.currentsignal ~= nil and 1 or 0
end

-- Check if the current execution was caused by a datasignal named <name>
e2function number dsClk( string name )
	if not self.data.currentsignal then return 0 end
	return self.data.currentsignal.name == name and 1 or 0
end

-- Returns the name of the current signal
e2function string dsClkName()
	if not self.data.currentsignal then return "" end
	return self.data.currentsignal.name
end

-- Get the type of the current data
e2function string dsGetType()
	if not self.data.currentsignal then return "" end
	return self.data.currentsignal.vartype
end

-- Get the E2 that sent the signal
e2function entity dsGetSender()
	if not self.data.currentsignal then return end
	return self.data.currentsignal.from
end

-- Get the group which the signal was sent to
e2function string dsGetGroup()
	if not self.data.currentsignal then return "" end
	return self.data.currentsignal.groupname
end

-- Get the hash of the sending E2
e2function number dsGetHash()
	if not self.data.currentsignal then return "" end
	return self.data.currentsignal.hash
end

__e2setcost(20)

-- Get all E2s which would have received a signal if you had sent it to this group and the E2s scope
e2function array dsProbe( string groupname )
	return probeGroup( self.entity, self.data.datasignal.scope, groupname )
end

-- Get all E2s which would have received a signal if you had sent it to this group and scope
e2function array dsProbe( string groupname, number scope )
	return probeGroup( self.entity, c(f(scope),0,2), groupname )
end


---------------------------------------------
-- Construct & Destruct
---------------------------------------------

-- When an E2 is removed, clear it from the groups table
registerCallback("destruct",function(self)
	if (self.data.datasignal.groups) then
		if (#self.data.datasignal.groups > 0) then
			for k,v in pairs( self.data.datasignal.groups ) do
				if (groups[v]) then
					groups[v][self.entity] = nil
					if (next(groups[v]) == nil) then
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
