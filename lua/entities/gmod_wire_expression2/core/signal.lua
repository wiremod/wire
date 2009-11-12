--[[
Original idea: Gwahir
Original implementation: Gwahir
Rewrite that made it work: TomyLobo
]]

-- holds the currently registered signal handlers. Format:
-- scopes[player|1|2][group][name][context] = true|nil
local scopes = {{}, {}}

-- holds the currently queued signals. Format:
-- signal_queue[group][name][receiverid] = { group, name, scope, sender, senderid }
local signal_queue = {}

-- holds the current signal data. Format:
-- currentSignal = nil|{ group, name, scope, sender, senderid }
local currentSignal = nil

--[[************************************************************************]]--

-- executes a chip's code
local function triggerSignal(receiverid, signaldata)
	currentSignal = signaldata
	Entity(receiverid):Execute()
	currentSignal = nil
end

local timerRunning = false

local function checkSignals()
	timerRunning = false

	-- make a copy of the signal queue so we can add new signals safely while iterating through the existing array
	local queue = signal_queue

	-- clear the signal queue
	signal_queue = {}

	-- loop through all queued signal groups
	for group,signals in pairs(queue) do
		-- loop through all queued signals in the group
		for name,receivers in pairs(signals) do
			-- ... and all receivers
			for receiverid,signaldata in pairs(receivers) do
				-- and trigger all signals on the queue
				triggerSignal(receiverid, signaldata)
			end
		end
	end

end

-- queues a chip's code for execution after at most
local function postSignal(receiverid, group, name, scope, sender, senderid)
	-- don't send the signal back to the sender
	if senderid == receiverid then return end

	-- create signal's spot on the queue, if it doesnt exist
	if not signal_queue[group] then signal_queue[group] = {} end
	if not signal_queue[group][name] then signal_queue[group][name] = {} end

	-- add the given signal to the queue
	signal_queue[group][name][receiverid] = { group, name, scope, sender, senderid }

	-- set a timer if it isnt already set
	if not timerRunning then
		timerRunning = true
		timer.Simple(0.01, checkSignals)
	end
end

-- Sends the given signal group/name combination to everyone listening
local function broadcastSignal(group, name, scope, sender, filter_player)

	local sender_player = sender.player

	local groups
	if scope == 0 then
		-- scope 0 => read from scopes[sender.player]
		groups = scopes[sender_player]
	else
		-- scope 1/2 => read from scopes[scope]
		groups = scopes[scope]
	end

	if not groups[group] then return end
	local contexts = groups[group][name]

	-- there was no signal registered for the selected scope/group/name combination.
	if not contexts then return end

	local senderid = sender:EntIndex()

	for receiverid,_ in pairs(contexts) do
		local receiver_player = Entity(receiverid).player
		if (not filter_player or receiver_player == filter_player) and (scope ~= 2 or receiver_player ~= sender_player) then
			postSignal(receiverid, group, name, scope, sender, senderid)
		end
	end
end

--local function table_IsEmpty(t) return not pairs(t)(t) end
local function table_IsEmpty(t) return not next(t) end

local function setGroup(self, group)
	local oldgroup = self.data.signalgroup

	-- no change? don't waste precious cycles and get out here
	if oldgroup == group then return end

	-- get the signal scope
	local s = scopes[self.player]
	-- remove the old group, if empty
	if s[oldgroup] and table_IsEmpty(s[oldgroup]) then s[oldgroup] = nil end
	-- set up the new group
	if not s[group] then s[group] = {} end

	-- same for scope 1
	local s = scopes[1]
	if s[oldgroup] and table_IsEmpty(s[oldgroup]) then s[oldgroup] = nil end
	if not s[group] then s[group] = {} end

	-- same for scope 2
	local s = scopes[2]
	if s[oldgroup] and table_IsEmpty(s[oldgroup]) then s[oldgroup] = nil end
	if not s[group] then s[group] = {} end

	-- set the current group to the new group
	self.data.signalgroup = group
end

--[[************************************************************************]]--

--- Sets the E-2's current signal group to <group>, this is applied during runOnSignal, signalSend, and signalSetOnRemove calls, so call it first.
e2function void signalSetGroup(string group)
	setGroup(self, group)
end

--- Gets the E-2's current signal group
e2function string signalGetGroup()
	return self.data.signalgroup
end

--- If <activate> == 0 the chip will no longer run on this signal, otherwise it makes this chip execute when signal <name> is sent by someone in scope <scope>.
e2function void runOnSignal(string name, scope, activate)
	-- sanitize inputs
	if scope >= 3 or scope < 0 then return end
	scope = math.floor(scope)

	-- process inputs
	activate = activate ~= 0 or nil
	if scope == 0 then scope = self.player end

	-- fetch the signal group
	local signals = scopes[scope][self.data.signalgroup]

	-- if there is no entry for the signal in the group yet, create it
	if not signals[name] then signals[name] = {} end

	-- (un-)register signal
	signals[name][self.entity:EntIndex()] = activate
end

--[[************************************************************************]]--

--- Returns 1 if the chip was executed because of any signal, regardless of name, group or scope. Returns 0 otherwise.
e2function number signalClk()
	return currentSignal and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent, regardless of group or scope. Returns 0 otherwise.
e2function number signalClk(string name)
	return (currentSignal and currentSignal[2] == name) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent to the scope <scope>, regardless of group. Returns 0 otherwise.
e2function number signalClk(string name, scope)
	return (currentSignal and currentSignal[2] == name and currentSignal[3] == scope) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent in the group <group>, regardless of scope. Returns 0 otherwise.
e2function number signalClk(string group, string name)
	return (currentSignal and currentSignal[1] == group and currentSignal[2] == name) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent in the group <group> to the scope <scope>. Returns 0 otherwise.
e2function number signalClk(string group, string name, scope)
	return (currentSignal and currentSignal[1] == group and currentSignal[2] == name and currentSignal[3] == scope) and 1 or 0
end

--- Returns the name of the received signal.
e2function string signalName()
	if not currentSignal then return "" end
	return currentSignal[2]
end

--- Returns the group name of the received signal.
e2function string signalGroup()
	if not currentSignal then return "" end
	return currentSignal[1]
end

--- Returns the entity of the chip that sent the signal.
e2function entity signalSender()
	if not currentSignal then return nil end
	return currentSignal[4]
end

--- Returns the entity ID of the chip that sent the signal. Useful if the entity doesn't exist anymore.
e2function number signalSenderId()
	if not currentSignal then return 0 end
	return currentSignal[5]
end

--[[************************************************************************]]--

--- Sets the signal that the chip sends when it is removed from the world.
e2function void signalSetOnRemove(string name, scope)
	self.data.removeSignal = { self.data.signalgroup, name, scope, self.entity }
end

--- Clears the signal that the chip sends when it is removed from the world.
e2function void signalClearOnRemove()
	self.data.removeSignal = nil
end

--- Sends signal <name> to scope <scope>. Additional calls to this function with the same signal will overwrite the old call until the signal is issued.
e2function void signalSend(string name, scope)
	broadcastSignal(self.data.signalgroup, name, scope, self.entity)
end

--- Sends signal S to the given chip. Multiple calls for different chips do not overwrite each other.
e2function void signalSendDirect(string name, entity receiver)
	if not validEntity(receiver) then return end

	local receiverid = receiver:EntIndex()

	-- filter out non-E2 entities
	if not receiver.context then return end

	-- dont send back to ourselves
	if receiver.context == self then return end

	local group = self.data.signalgroup

	-- check whether the target entity accepts signals from the "anyone" scope.
	if not scopes[1][group][name] then return end
	if not scopes[1][group][name][receiverid] then return end

	-- send the signal
	postSignal(receiverid, group, name, 1, self.entity, self.entity:EntIndex())
end

--- sends signal S to chips owned by the given player, multiple calls for different players do not overwrite each other
e2function void signalSendToPlayer(string name, entity player)
	if not validEntity(player) then return end
	broadcastSignal(self.data.signalgroup, name, 1, self.entity, player)
end

--[[************************************************************************]]--

registerCallback("construct",function(self)
	-- if there is no personal scope for us yet, create it.
	if not scopes[self.player] then scopes[self.player] = {} end

	-- place a bogus group into the personal scope to mark it as used.
	scopes[self.player][self] = {{{}}}
	--                          ^^^-- context
	--                          |+-- signal
	--                          +-- group

	-- set a default group
	setGroup(self, "default")
end)

registerCallback("destruct",function(self)
	-- loop through all scopes, ...
	for scope,groups in pairs(scopes) do
		-- ... all groups ...
		for group, signals in pairs(groups) do
			-- ... and all signals ...
			for name, contexts in pairs(signals) do
				-- to remove all signals the chip registered for.
				contexts[self] = nil

				-- are we the last chip that received this signal?
				if table_IsEmpty(contexts) then signals[name] = nil end
			end

			-- was this the last signal in this group?
			if table_IsEmpty(signals) then groups[group] = nil end
		end
	end

	-- remove the bogus group from the personal scope
	if (scopes[self.player]) then
		scopes[self.player][self] = nil

		-- and check whether this was the last group
		if table_IsEmpty(scopes[self.player]) then scopes[self.player] = nil end
	end

	-- broadcast the on-remove signal, if one was registered
	if self.data.removeSignal then broadcastSignal(unpack(self.data.removeSignal)) end

	-- clean up (not actually necessary since the context is destroyed anyway)
	self.data.signalgroup = nil
	self.data.removeSignal = nil
end)
