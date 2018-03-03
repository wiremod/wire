--[[
Original idea: Gwahir
Original implementation: Gwahir
Rewrite that made it work: TomyLobo
Minor rewrite that made it work even if the player disconnected: Lexi
]]

-- holds the currently registered signal handlers. Format:
-- scopes[uniqueID|1|2][group][name][context] = true|nil
local scopes = WireLib.containers.autocleanup:new(3)

-- holds the currently queued signals. Format:
-- signal_queue[group][name][receiverid] = { group, name, scope, sender, senderid }
local signal_queue = WireLib.containers.autocleanup:new(2)

-- holds the current signal data. Format:
-- currentSignal = nil|{ group, name, scope, sender, senderid }

--[[************************************************************************]]--

-- executes a chip's code
local function triggerSignal(receiverid, signaldata)
	local receiver = Entity(receiverid)
	if not IsValid(receiver) or not receiver.Execute then return end
	receiver.context.data.currentSignal = signaldata
	receiver:Execute()
	receiver.context.data.currentSignal = nil
	if (signaldata.sender and signaldata.sender:IsValid()) then signaldata.sender.context.prf = signaldata.sender.context.prf + 80 end
end

local timerRunning = false

local function checkSignals()
	timerRunning = false

	-- make a copy of the signal queue so we can add new signals safely while iterating through the existing array
	local queue = signal_queue

	-- clear the signal queue
	signal_queue = WireLib.containers.autocleanup:new(2)

	-- loop through all queued signal groups
	for group,signals in pairs_ac(queue) do
		-- loop through all queued signals in the group
		for name,receivers in pairs_ac(signals) do
			-- ... and all receivers
			for receiverid,signaldata in pairs_ac(receivers) do
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

	-- add the given signal to the queue
	signal_queue[group][name][receiverid] = { group, name, scope, sender, senderid }

	-- set a timer if it isnt already set
	if not timerRunning then
		timerRunning = true
		timer.Simple(0.01, checkSignals)
	end
end

-- Sends the given signal group/name combination to everyone listening
-- Note: filter_player is a UNIQUE ID!
local function broadcastSignal(group, name, scope, sender, filter_player)

	local sender_player = sender.uid

	-- scope 0 => read from scopes[sender.uid]
	-- scope 1/2 => read from scopes[scope]
	local contexts = scopes[scope == 0 and sender_player or scope][group][name]

	-- there was no signal registered for the selected scope/group/name combination.
	if not contexts then return end

	local senderid = sender:EntIndex()

	for receiverid,_ in pairs_ac(contexts) do
		local receiver_player = Entity(receiverid).uid
		if (not filter_player or receiver_player == filter_player) and (scope ~= 2 or receiver_player ~= sender_player) then
			postSignal(receiverid, group, name, scope, sender, senderid)
		end
	end
end

--local function table_IsEmpty(t) return not pairs(t)(t) end
local function table_IsEmpty(t) return not next(t) end

local function setGroup(self, group)
	-- set the current group to the new group
	self.data.signalgroup = group
end

--[[************************************************************************]]--

__e2setcost(5)

--- Sets the E-2's current signal group to <group>, this is applied during runOnSignal, signalSend, and signalSetOnRemove calls, so call it first.
e2function void signalSetGroup(string group)
	setGroup(self, group)
end

--- Gets the E-2's current signal group
e2function string signalGetGroup()
	return self.data.signalgroup
end

__e2setcost(5)

--- If <activate> == 0 the chip will no longer run on this signal, otherwise it makes this chip execute when signal <name> is sent by someone in scope <scope>.
e2function void runOnSignal(string name, scope, activate)
	-- sanitize inputs
	--if scope >= 3 or scope < 0 then return end
	scope = math.Clamp(math.floor(scope), 0, 2)

	-- process inputs
	activate = activate ~= 0 or nil
	if scope == 0 then scope = self.uid end

	-- (un-)register signal
	scopes[scope][self.data.signalgroup][name][self.entity:EntIndex()] = activate
end

--[[************************************************************************]]--

__e2setcost(1)

--- Returns 1 if the chip was executed because of any signal, regardless of name, group or scope. Returns 0 otherwise.
e2function number signalClk()
	if not self.data.currentSignal then return 0 end
	return self.data.currentSignal and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent, regardless of group or scope. Returns 0 otherwise.
e2function number signalClk(string name)
	if not self.data.currentSignal then return 0 end
	local currentSignal = self.data.currentSignal
	return (currentSignal and currentSignal[2] == name) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent to the scope <scope>, regardless of group. Returns 0 otherwise.
e2function number signalClk(string name, scope)
	if not self.data.currentSignal then return 0 end
	local currentSignal = self.data.currentSignal
	return (currentSignal and currentSignal[2] == name and currentSignal[3] == scope) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent in the group <group>, regardless of scope. Returns 0 otherwise.
e2function number signalClk(string group, string name)
	if not self.data.currentSignal then return 0 end
	local currentSignal = self.data.currentSignal
	return (currentSignal and currentSignal[1] == group and currentSignal[2] == name) and 1 or 0
end

--- Returns 1 if the chip was executed because the signal <name> was sent in the group <group> to the scope <scope>. Returns 0 otherwise.
e2function number signalClk(string group, string name, scope)
	if not self.data.currentSignal then return 0 end
	local currentSignal = self.data.currentSignal
	return (currentSignal and currentSignal[1] == group and currentSignal[2] == name and currentSignal[3] == scope) and 1 or 0
end

__e2setcost(4)

--- Returns the name of the received signal.
e2function string signalName()
	if not self.data.currentSignal then return "" end
	return self.data.currentSignal[2]
end

--- Returns the group name of the received signal.
e2function string signalGroup()
	if not self.data.currentSignal then return "" end
	return self.data.currentSignal[1]
end

--- Returns the entity of the chip that sent the signal.
e2function entity signalSender()
	if not self.data.currentSignal then return nil end
	return self.data.currentSignal[4]
end

--- Returns the entity ID of the chip that sent the signal. Useful if the entity doesn't exist anymore.
e2function number signalSenderId()
	if not self.data.currentSignal then return 0 end
	return self.data.currentSignal[5]
end

--[[************************************************************************]]--

__e2setcost(10)

--- Sets the signal that the chip sends when it is removed from the world.
e2function void signalSetOnRemove(string name, scope)
	self.data.removeSignal = { self.data.signalgroup, name, scope, self.entity }
end

--- Clears the signal that the chip sends when it is removed from the world.
e2function void signalClearOnRemove()
	self.data.removeSignal = nil
end

__e2setcost(20)

--- Sends signal <name> to scope <scope>. Additional calls to this function with the same signal will overwrite the old call until the signal is issued.
e2function void signalSend(string name, scope)
	broadcastSignal(self.data.signalgroup, name, scope, self.entity)
end

__e2setcost(10)

--- Sends signal S to the given chip. Multiple calls for different chips do not overwrite each other.
e2function void signalSendDirect(string name, entity receiver)
	if not IsValid(receiver) then return end

	local receiverid = receiver:EntIndex()

	-- filter out non-E2 entities
	if not receiver.context then return end

	-- dont send back to ourselves
	if receiver.context == self then return end

	local group = self.data.signalgroup

	-- check whether the target entity accepts signals from the "anyone" scope.
	if not scopes[1][group][name][receiverid] then return end

	-- send the signal
	postSignal(receiverid, group, name, 1, self.entity, self.entity:EntIndex())
end

__e2setcost(20)

--- sends signal S to chips owned by the given player, multiple calls for different players do not overwrite each other
e2function void signalSendToPlayer(string name, entity player)
	if not IsValid(player) then return end
	broadcastSignal(self.data.signalgroup, name, 1, self.entity, player)
end

--[[************************************************************************]]--

registerCallback("construct",function(self)
	-- set a default group
	setGroup(self, "default")
end)

registerCallback("destruct",function(self)
	-- loop through all scopes, ...
	for scope,groups in pairs_ac(scopes) do
		-- ... all groups ...
		for group, signals in pairs_ac(groups) do
			-- ... and all signals ...
			for name, contexts in pairs_ac(signals) do
				-- to remove all signals the chip registered for.
				contexts[self] = nil
			end
		end
	end

	-- broadcast the on-remove signal, if one was registered
	if self.data.removeSignal then broadcastSignal(unpack(self.data.removeSignal)) end

	-- clean up (not actually necessary since the context is destroyed anyway)
	self.data.signalgroup = nil
	self.data.removeSignal = nil
end)
