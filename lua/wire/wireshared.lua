WireLib = WireLib or {}

local pairs = pairs
local setmetatable = setmetatable
local rawget = rawget
local next = next
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local Entity = Entity

local string = string
local hook = hook

-- extra table functions

-- Returns a noniterable version of tbl. So indexing still works, but pairs(tbl) won't find anything
-- Useful for hiding entity lookup tables, since Garrydupe uses util.TableToJSON, which crashes on tables with entity keys
function table.MakeNonIterable(tbl)
    return setmetatable({}, { __index = tbl, __setindex = tbl})
end

-- Checks if the table is empty, it's faster than table.Count(Table) > 0
function table.IsEmpty(Table)
	return (next(Table) == nil)
end

-- Compacts an array by rejecting entries according to cb.
function table.Compact(tbl, cb, n)
	n = n or #tbl
	local cpos = 1
	for i = 1, n do
		if cb(tbl[i]) then
			tbl[cpos] = tbl[i]
			cpos = cpos + 1
		end
	end

	local new_n = cpos-1
	while (cpos <= n) do
		tbl[cpos] = nil
		cpos = cpos + 1
	end
end

-- I don't even know if I need this one.
-- HUD indicator needs this one
function table.MakeSortedKeys(tbl)
	local result = {}

	for k,_ in pairs(tbl) do table.insert(result, k) end
	table.sort(result)

	return result
end

-- works like pairs() except that it iterates sorted by keys.
-- criterion is optional and should be a function(a,b) returning whether a is less than b. (same as table.sort's criterions)
function pairs_sortkeys(tbl, criterion)
	tmp = {}
	for k,v in pairs(tbl) do table.insert(tmp,k) end
	table.sort(tmp, criterion)

	local iter, state, index, k = ipairs(tmp)
	return function()
		index,k = iter(state, index)
		if index == nil then return nil end
		return k,tbl[k]
	end
end

-- sorts by values
function pairs_sortvalues(tbl, criterion)
	local crit = criterion and
		function(a,b)
			return criterion(tbl[a],tbl[b])
		end
	or
		function(a,b)
			return tbl[a] < tbl[b]
		end

	tmp = {}
	tbl = tbl or {}
	for k,v in pairs(tbl) do table.insert(tmp,k) end
	table.sort(tmp, crit)

	local iter, state, index, k = ipairs(tmp)
	return function()
		index,k = iter(state, index)
		if index == nil then return nil end
		return k,tbl[k]
	end
end

--- Iterates over a table like `pairs`, but also removes each field from the
--- table as it does so. Adding to the table while iterating is allowed, and
--- each added entry will be consumed in some future iteration.
function pairs_consume(table)
	return function()
		local k, v = next(table)
		if k then table[k] = nil return k, v end
	end
end

-- like ipairs, except it maps the value with mapfunction before returning.
function ipairs_map(tbl, mapfunction)
	local iter, state, k = ipairs(tbl)
	return function(state, k)
		local v
		k,v = iter(state, k)
		if k == nil then return nil end
		return k,mapfunction(v)
	end, state, k
end

-- like pairs, except it maps the value with mapfunction before returning.
function pairs_map(tbl, mapfunction)
	local iter, state, k = pairs(tbl)
	return function(state, k)
		local v
		k,v = iter(state, k)
		if k == nil then return nil end
		return k,mapfunction(v)
	end, state, k
end

-- end extra table functions

local table = table
local pairs_sortkeys = pairs_sortkeys
local pairs_sortvalues = pairs_sortvalues
local ipairs_map = ipairs_map
local pairs_map = pairs_map

--------------------------------------------------------------------------------

do -- containers
	local function new(metatable, ...)
		local tbl = {}
		setmetatable(tbl, metatable)
		local init = metatable.Initialize
		if init then init(tbl, ...) end
		return tbl
	end

	local function newclass(container_name)
		meta = { new = new }
		meta.__index = meta
		WireLib.containers[container_name] = meta
		return meta
	end

	WireLib.containers = { new = new, newclass = newclass }

	do -- class deque
		local deque = newclass("deque")

		function deque:Initialize()
			self.offset = 0
		end

		function deque:size()
			return #self-self.offset
		end

		-- Prepends the given element.
		function deque:unshift(value)
			if offset < 1 then
				-- TODO: improve
				table.insert(self, 1, value)
				return
			end
			self.offset = self.offset - 1
			self[self.offset+1] = value
		end

		-- Removes the first element and returns it
		function deque:shift()
			--do return table.remove(self, 1) end
			local offset = self.offset + 1
			local ret = self[offset]
			if not ret then self.offset = offset-1 return nil end
			self.offset = offset
			if offset > 127 then
				for i = offset+1,#self-offset do
					self[i-offset] = self[i]
				end
				for i = #self-offset+1,#self do
					self[i-offset],self[i] = self[i],nil
				end
				self.offset = 0
			end
			return ret
		end

		-- Appends the given element.
		function deque:push(value)
			self[#self+1] = value
		end

		-- Removes the last element and returns it.
		function deque:pop()
			local ret = self[#self]
			self[#self] = nil
			return ret
		end

		-- Returns the last element.
		function deque:top()
			return self[#self]
		end

		-- Returns the first element.
		function deque:bottom()
			return self[self.offset+1]
		end
	end -- class deque

	do -- class autocleanup
		local autocleanup = newclass("autocleanup")

		function autocleanup:Initialize(depth, parent, parentindex)
			rawset(self, "depth", depth or 0)
			rawset(self, "parent", parent)
			rawset(self, "parentindex", parentindex)
			rawset(self, "data", {})
		end

		function autocleanup:__index(index)
			local data  = rawget(self, "data")

			local element = data[index]
			if element then return element end

			local depth = rawget(self, "depth")
			if depth == 0 then return nil end
			element = new(autocleanup, depth-1, self, index)

			return element
		end

		function autocleanup:__newindex(index, value)
			local data   = rawget(self, "data")
			local parent = rawget(self, "parent")
			local parentindex = rawget(self, "parentindex")

			if value ~= nil and not next(data) and parent then parent[parentindex] = self end
			data[index] = value
			if value == nil and not next(data) and parent then parent[parentindex] = nil end
		end

		function autocleanup:__pairs()
			local data = rawget(self, "data")

			return pairs(data)
		end

		pairs_ac = autocleanup.__pairs
	end -- class autocleanup
end -- containers

--------------------------------------------------------------------------------

--[[ wire_addnotify: send notifications to the client
	WireLib.AddNotify([ply, ]Message, Type, Duration[, Sound])
	If ply is left out, the notification is sent to everyone. If Sound is left out, no sound is played.
	On the client, only the local player can be notified.
]]
do
	-- The following sounds can be used:
	NOTIFYSOUND_NONE = 0 -- optional, default
	NOTIFYSOUND_DRIP1 = 1
	NOTIFYSOUND_DRIP2 = 2
	NOTIFYSOUND_DRIP3 = 3
	NOTIFYSOUND_DRIP4 = 4
	NOTIFYSOUND_DRIP5 = 5
	NOTIFYSOUND_ERROR1 = 6
	NOTIFYSOUND_CONFIRM1 = 7
	NOTIFYSOUND_CONFIRM2 = 8
	NOTIFYSOUND_CONFIRM3 = 9
	NOTIFYSOUND_CONFIRM4 = 10

	if CLIENT then

		local sounds = {
			[NOTIFYSOUND_DRIP1   ] = "ambient/water/drip1.wav",
			[NOTIFYSOUND_DRIP2   ] = "ambient/water/drip2.wav",
			[NOTIFYSOUND_DRIP3   ] = "ambient/water/drip3.wav",
			[NOTIFYSOUND_DRIP4   ] = "ambient/water/drip4.wav",
			[NOTIFYSOUND_DRIP5   ] = "ambient/water/drip5.wav",
			[NOTIFYSOUND_ERROR1  ] = "buttons/button10.wav",
			[NOTIFYSOUND_CONFIRM1] = "buttons/button3.wav",
			[NOTIFYSOUND_CONFIRM2] = "buttons/button14.wav",
			[NOTIFYSOUND_CONFIRM3] = "buttons/button15.wav",
			[NOTIFYSOUND_CONFIRM4] = "buttons/button17.wav",
		}

		function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
			if isstring(ply) then
				Message, Type, Duration, Sound = ply, Message, Type, Duration
			elseif ply ~= LocalPlayer() then
				return
			end
			GAMEMODE:AddNotify(Message, Type, Duration)
			if Sound and sounds[Sound] then surface.PlaySound(sounds[Sound]) end
		end

		net.Receive("wire_addnotify", function(netlen)
			local Message = net.ReadString()
			local Type = net.ReadUInt(8)
			local Duration = net.ReadFloat()
			local Sound = net.ReadUInt(8)

			WireLib.AddNotify(LocalPlayer(), Message, Type, Duration, Sound)
		end)

	elseif SERVER then

		NOTIFY_GENERIC = 0
		NOTIFY_ERROR = 1
		NOTIFY_UNDO = 2
		NOTIFY_HINT = 3
		NOTIFY_CLEANUP = 4

		util.AddNetworkString("wire_addnotify")
		function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
			if isstring(ply) then ply, Message, Type, Duration, Sound = nil, ply, Message, Type, Duration end
			if ply && !ply:IsValid() then return end
			net.Start("wire_addnotify")
				net.WriteString(Message)
				net.WriteUInt(Type or 0,8)
				net.WriteFloat(Duration)
				net.WriteUInt(Sound or 0,8)
			if ply then net.Send(ply) else net.Broadcast() end
		end

	end
end -- wire_addnotify

--[[ wire_clienterror: displays Lua errors on the client
	Usage: WireLib.ClientError("Hello", ply)
]]
if CLIENT then
	net.Receive("wire_clienterror", function(netlen)
		local message = net.ReadString()
		print("sv: "..message)
		local lines = string.Explode("\n", message)
		for i,line in ipairs(lines) do
			if i == 1 then
				WireLib.AddNotify(line, NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
			else
				WireLib.AddNotify(line, NOTIFY_ERROR, 7)
			end
		end
	end)
elseif SERVER then
	util.AddNetworkString("wire_clienterror")
	function WireLib.ClientError(message, ply)
		net.Start("wire_clienterror")
			net.WriteString(message)
		net.Send(ply)
	end
end

function WireLib.ErrorNoHalt(message)
	-- ErrorNoHalt clips messages to 512 characters, so chain calls if necessary
	for i=1,#message, 511 do
		ErrorNoHalt(message:sub(i,i+510))
	end
end

--- Generate a random version 4 UUID and return it as a string.
function WireLib.GenerateUUID()
	-- It would be easier to generate this by word rather than by byte, but
	-- MSVC's RAND_MAX = 0x7FFF, which means math.random(0, 0xFFFF) won't
	-- return all possible values.
	local bytes = {}
	for i = 1, 16 do bytes[i] = math.random(0, 0xFF) end
	bytes[7] = bit.bor(0x40, bit.band(bytes[7], 0x0F))
	bytes[9] = bit.bor(0x80, bit.band(bytes[7], 0x3F))
	return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", unpack(bytes))
end

local PERSISTENT_UUID_KEY = "WireLib.GetServerUUID"
if SERVER then
	--- Return a persistent UUID associated with the server.
	function WireLib.GetServerUUID()
		local uuid = cookie.GetString(PERSISTENT_UUID_KEY)
		if not uuid then
			uuid = WireLib.GenerateUUID()
			cookie.Set(PERSISTENT_UUID_KEY, uuid)
		end
		return uuid
	end

	util.AddNetworkString(PERSISTENT_UUID_KEY)

	hook.Add("PlayerInitialSpawn", PERSISTENT_UUID_KEY, function(player)
		net.Start(PERSISTENT_UUID_KEY)
		net.WriteString(WireLib.GetServerUUID())
		net.Send(player)
	end)

else
	local SERVER_UUID
	net.Receive(PERSISTENT_UUID_KEY, function() SERVER_UUID = net.ReadString() end)
	function WireLib.GetServerUUID() return SERVER_UUID end
end


--[[ wire_netmsg system
	A basic framework for entities that should send newly connecting players data

	Server requirements: ENT:Retransmit(ply) -- Should send all data to one player
	Client requirements:
		WireLib.netRegister(self) in ENT:Initialize()
		ENT:Receive()

	To send:
	function ENT:Retransmit(ply)
		WireLib.netStart(self) -- This automatically net.WriteEntity(self)'s
			net.Write*...
		WireLib.netEnd(ply) -- you can pass a Player or a table of players to only send to some clients, otherwise it broadcasts
	end

	To receive:
	function ENT:Receive()
		net.Read*...
	end

	To unregister: WireLib.netUnRegister(self) -- Happens automatically on entity removal
]]

if SERVER then
	util.AddNetworkString("wire_netmsg_register")
	util.AddNetworkString("wire_netmsg_registered")

	function WireLib.netStart(self)
		net.Start("wire_netmsg_registered")
		net.WriteEntity(self)
	end
	function WireLib.netEnd(ply)
		if ply then net.Send(ply) else net.Broadcast() end
	end

	net.Receive("wire_netmsg_register", function(netlen, ply)
		local self = net.ReadEntity()
		if IsValid(self) and self.Retransmit then self:Retransmit(ply) end
	end)
elseif CLIENT then
	function WireLib.netRegister(self)
		net.Start("wire_netmsg_register") net.WriteEntity(self) net.SendToServer()
	end

	net.Receive("wire_netmsg_registered", function(netlen)
		local self = net.ReadEntity()
		if IsValid(self) and self.Receive then self:Receive() end
	end)
end

--[[ wire_ports: client-side input/output names/types/descs
	umsg format:
	any number of the following:
		Char start
			start==0: break
			start==-1: delete inputs
			start==-2: delete outputs
			start==-3: set eid
			start==-4: connection state
			start > 0:
				Char amount
				abs(amount)*3 strings describing name, type, desc
]]

-- Checks if the entity has wire ports.
-- Works for every entity that has wire in-/output.
-- Very important and useful for checks!
function WireLib.HasPorts(ent)
	if (ent.IsWire) then return true end
	if (ent.Base == "base_wire_entity") then return true end

	-- Checks if the entity is in the list, it checks if the entity has self.in-/outputs too.
	local In, Out = WireLib.GetPorts(ent)
	if (In and (ent.Inputs or CLIENT)) then return true end
	if (Out and (ent.Outputs or CLIENT)) then return true end

	return false
end

if SERVER then
	local INPUT,OUTPUT = 1,-1
	local DELETE,PORT,LINK = 1,2,3

	local ents_with_inputs = {}
	local ents_with_outputs = {}
	--local IOlookup = { [INPUT] = ents_with_inputs, [OUTPUT] = ents_with_outputs }

	util.AddNetworkString("wire_ports")
	timer.Create("Debugger.PoolTypeStrings",1,1,function()
		if WireLib.Debugger and WireLib.Debugger.formatPort then
			for typename,_ in pairs(WireLib.Debugger.formatPort) do util.AddNetworkString(typename) end -- Reduce bandwidth
		end
	end)
	local queue = {}

	function WireLib.GetPorts(ent)
		local eid = ent:EntIndex()
		return ents_with_inputs[eid], ents_with_outputs[eid]
	end

	function WireLib._RemoveWire(eid, DontSend) -- To remove the inputs without to remove the entity. Very important for IsWire checks!
		local hasinputs, hasoutputs = ents_with_inputs[eid], ents_with_outputs[eid]
		if hasinputs or hasoutputs then
			ents_with_inputs[eid] = nil
			ents_with_outputs[eid] = nil
			if not DontSend then
				net.Start("wire_ports")
					net.WriteInt(-3, 8) -- set eid
					net.WriteUInt(eid, 16) -- entity id
					if hasinputs then net.WriteInt(-1, 8) end -- delete inputs
					if hasoutputs then net.WriteInt(-2, 8) end -- delete outputs
					net.WriteInt(0, 8) -- break
				net.Broadcast()
			end
		end
	end

	hook.Add("EntityRemoved", "wire_ports", function(ent)
		if not ent:IsPlayer() then
			WireLib._RemoveWire(ent:EntIndex())
		end
	end)

	function WireLib._SetInputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		if not ents_with_inputs[eid] then ents_with_inputs[eid] = {} end

		queue[#queue+1] = { eid, DELETE, INPUT }

		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_inputs[eid][#ents_with_inputs[eid]+1] = entry
			queue[#queue+1] = { eid, PORT, INPUT, entry, CurPort.Num }
		end
		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			WireLib._SetLink(CurPort, lqueue)
		end
	end

	function WireLib._SetOutputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		if not ents_with_outputs[eid] then ents_with_outputs[eid] = {} end

		queue[#queue+1] = { eid, DELETE, OUTPUT }

		for Name, CurPort in pairs_sortvalues(ent.Outputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_outputs[eid][#ents_with_outputs[eid]+1] = entry
			queue[#queue+1] = { eid, PORT, OUTPUT, entry, CurPort.Num }
		end
	end

	function WireLib._SetLink(input, lqueue)
		local ent = input.Entity
		local num = input.Num
		local state = input.SrcId and true or false

		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue[#queue+1] = {eid, LINK, num, state}
	end

	local eid = 0
	local numports, firstportnum, portstrings = {}, {}, {}
	local function writeCurrentStrings()
		-- Write the current (input or output) string information
		for IO=OUTPUT,INPUT,2 do -- so, k= -1 and k= 1
			if numports[IO] then
				net.WriteInt(firstportnum[IO], 8)	-- Control code for inputs/outputs is also the offset (the first port number we're writing over)
				net.WriteUInt(numports[IO], 8)		-- Send number of ports
				net.WriteBit(IO==OUTPUT)
				for i=1,numports[IO]*3 do net.WriteString(portstrings[IO][i] or "") end
				numports[IO] = nil
			end
		end
	end
	local function writemsg(msg)
		-- First write a signed int for the command code
		-- Then sometimes write extra data specific to the command (type varies)

		if msg[1] ~= eid then
			eid = msg[1]
			writeCurrentStrings() -- We're switching to talking about a different entity, lets send port information
			net.WriteInt(-3,8)
			net.WriteUInt(eid,16)
		end

		local msgtype = msg[2]

		if msgtype == DELETE then
			numports[msg[3]] = nil
			net.WriteInt(msg[3] == INPUT and -1 or -2, 8)
		elseif msgtype == PORT then
			local _,_,IO,entry,num = unpack(msg)

			if not numports[IO] then
				firstportnum[IO] = num
				numports[IO] = 0
				portstrings[IO] = {}
			end
			local i = numports[IO]*3
			portstrings[IO][i+1] = entry[1]
			portstrings[IO][i+2] = entry[2]
			portstrings[IO][i+3] = entry[3]
			numports[IO] = numports[IO]+1
		elseif msgtype == LINK then
			local _,_,num,state = unpack(msg)
			net.WriteInt(-4, 8)
			net.WriteUInt(num, 8)
			net.WriteBit(state)
		end
	end

	local function FlushQueue(lqueue, ply)
		// Zero these two for the writemsg function
		eid = 0
		numports = {}

		net.Start("wire_ports")
		for i=1,#lqueue do
			writemsg(lqueue[i])
		end
		writeCurrentStrings()
		net.WriteInt(0,8)
		if ply then net.Send(ply) else net.Broadcast() end
	end

	hook.Add("Think", "wire_ports", function()
		if not next(queue) then return end
		FlushQueue(queue)
		queue = {}
	end)

	hook.Add("PlayerInitialSpawn", "wire_ports", function(ply)
		local lqueue = {}
		for eid, entry in pairs(ents_with_inputs) do
			WireLib._SetInputs(Entity(eid), lqueue)
		end
		for eid, entry in pairs(ents_with_outputs) do
			WireLib._SetOutputs(Entity(eid), lqueue)
		end
		FlushQueue(lqueue, ply)
	end)

elseif CLIENT then
	local ents_with_inputs = {}
	local ents_with_outputs = {}

	net.Receive("wire_ports", function(netlen)
		local eid = 0
		local connections = {} -- In case any cmd -4's come in before link strings
		while true do
			local cmd = net.ReadInt(8)
			if cmd == 0 then
				break
			elseif cmd == -1 then
				ents_with_inputs[eid] = nil
			elseif cmd == -2 then
				ents_with_outputs[eid] = nil
			elseif cmd == -3 then
				eid = net.ReadUInt(16)
			elseif cmd == -4 then
				connections[#connections+1] = {eid, net.ReadUInt(8), net.ReadBit() ~= 0} -- Delay this process till after the loop
			elseif cmd > 0 then
				local entry

				local amount = net.ReadUInt(8)
				if net.ReadBit() ~= 0 then
					-- outputs
					entry = ents_with_outputs[eid]
					if not entry then
						entry = {}
						ents_with_outputs[eid] = entry
					end
				else
					-- inputs
					entry = ents_with_inputs[eid]
					if not entry then
						entry = {}
						ents_with_inputs[eid] = entry
					end
				end

				local endindex = cmd+amount-1
				for i = cmd,endindex do
					entry[i] = {net.ReadString(), net.ReadString(), net.ReadString()}
				end
			end
		end
		for i=1, #connections do
			local eid, num, state = unpack(connections[i])
			local entry = ents_with_inputs[eid]
			if not entry then
				entry = {}
				ents_with_inputs[eid] = entry
			elseif entry[num] then
				entry[num][4] = state
			end
		end
	end)

	function WireLib.GetPorts(ent)
		local eid = ent:EntIndex()
		return ents_with_inputs[eid], ents_with_outputs[eid]
	end

	function WireLib._RemoveWire(eid) -- To remove the inputs without to remove the entity.
		ents_with_inputs[eid] = nil
		ents_with_outputs[eid] = nil
	end

	local flag = false
	function WireLib.TestPorts()
		flag = not flag
		if flag then
			local lasteid = 0
			hook.Add("HUDPaint", "wire_ports_test", function()
				local ent = LocalPlayer():GetEyeTraceNoCursor().Entity
				--if not ent:IsValid() then return end
				local eid = IsValid(ent) and ent:EntIndex() or lasteid
				lasteid = eid

				local text = "ID "..eid.."\nInputs:\n"
				for num,name,tp,desc,connected in ipairs_map(ents_with_inputs[eid] or {}, unpack) do

					text = text..(connected and "-" or " ")
					text = text..string.format("%s (%s) [%s]\n", name, tp, desc)
				end
				text = text.."\nOutputs:\n"
				for num,name,tp,desc in ipairs_map(ents_with_outputs[eid] or {}, unpack) do
					text = text..string.format("%s (%s) [%s]\n", name, tp, desc)
				end
				draw.DrawText(text,"Trebuchet24",10,300,Color(255,255,255,255),0)
			end)
		else
			hook.Remove("HUDPaint", "wire_ports_test")
		end
	end
end

-- For transmitting the yellow lines showing links between controllers and ents, as used by the Adv Entity Marker
if SERVER then
	util.AddNetworkString("WireLinkedEnts")
	function WireLib.SendMarks(controller, marks)
		if not IsValid(controller) or not (controller.Marks or marks) then return end
		net.Start("WireLinkedEnts")
			net.WriteEntity(controller)
			net.WriteUInt(#(controller.Marks or marks), 16)
			for k,v in pairs(controller.Marks or marks) do
				net.WriteEntity(v)
			end
		net.Broadcast()
	end
else
	net.Receive("WireLinkedEnts", function(netlen)
		local Controller = net.ReadEntity()
		if IsValid(Controller) then
			Controller.Marks = {}
			for i=1, net.ReadUInt(16) do
				local link = net.ReadEntity()
				if IsValid(link) then
					table.insert(Controller.Marks, link)
				end
			end
		end
	end)
end

--[[
	Returns the "distance" between two strings
	ie the amount of character swaps you have to do to get the first string to equal the second
	Example:
		levenshtein( "test", "toast" ) returns 2, because two steps: 'e' swapped to 'o', and 'a' is added

	Very useful for searching algorithms
	Used by custom spawn menu search & gate tool search, for example
	Credits go to: http://lua-users.org/lists/lua-l/2009-07/msg00461.html
]]
function WireLib.levenshtein( s, t )
	local d, sn, tn = {}, #s, #t
	local byte, min = string.byte, math.min
	for i = 0, sn do d[i * tn] = i end
	for j = 0, tn do d[j] = j end
	for i = 1, sn do
		local si = byte(s, i)
		for j = 1, tn do
			d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
		end
	end
	return d[#d]
end

--[[
	nicenumber
	by Divran

	Adds several functions to format numbers into millions, billions, etc
	Adds a function to format a number (assumed seconds) into a duration (weeks, days, hours, minutes, seconds, etc)

	This is used, for example, by the wire screen.
]]

WireLib.nicenumber = {}
local nicenumber = WireLib.nicenumber

local numbers = {
	{
		name = "septillion",
		short = "sep",
		symbol = "Y",
		prefix = "yotta",
		zeroes = 10^24,
	},
	{
		name = "sextillion",
		short = "sex",
		symbol = "Z",
		prefix = "zetta",
		zeroes = 10^21,
	},
	{
		name = "quintillion",
		short = "quint",
		symbol = "E",
		prefix = "exa",
		zeroes = 10^18,
	},
	{
		name = "quadrillion",
		short = "quad",
		symbol = "P",
		prefix = "peta",
		zeroes = 10^15,
	},
	{
		name = "trillion",
		short = "T",
		symbol = "T",
		prefix = "tera",
		zeroes = 10^12,
	},
	{
		name = "billion",
		short = "B",
		symbol = "B",
		prefix = "giga",
		zeroes = 10^9,
	},
	{
		name = "million",
		short = "M",
		symbol = "M",
		prefix = "mega",
		zeroes = 10^6,
	},
	{
		name = "thousand",
		short = "K",
		symbol = "K",
		prefix = "kilo",
		zeroes = 10^3
	}
}

local one = {
	name = "ones",
	short = "",
	symbol = "",
	prefix = "",
	zeroes = 1
}

-- returns a table of tables that inherit from the above info
local floor = math.floor
local min = math.min
function nicenumber.info( n, steps )
	if not n or n < 0 then return {} end
	if n > 10 ^ 300 then n = 10 ^ 300 end

	local t = {}

	steps = steps or #numbers

	local displayones = true
	local cursteps = 0

	for i = 1, #numbers do
		local zeroes = numbers[i].zeroes

		local nn = floor(n / zeroes)
		if nn > 0 then
			cursteps = cursteps + 1
			if cursteps > steps then break end

			t[#t+1] = setmetatable({value = nn},{__index = numbers[i]})

			n = n % numbers[i].zeroes

			displayones = false
		end
	end

	if n >= 0 and displayones then
		t[#t+1] = setmetatable({value = n},{__index = one})
	end

	return t
end

local sub = string.sub

-- returns string
-- example 12B 34M
function nicenumber.format( n, steps )
	local t = nicenumber.info( n, steps )

	steps = steps or #numbers

	local str = ""
	for i=1,#t do
		if i > steps then break end
		str = str .. t[i].value .. t[i].symbol .. " "
	end

	return sub( str, 1, -2 ) -- remove trailing space
end

-- returns string with decimals
-- example 12.34B
local round = math.Round
function nicenumber.formatDecimal( n, decimals )
	local t = nicenumber.info( n, 1 )

	decimals = decimals or 2

	local largest = t[1]
	if largest then
		n = n / largest.zeroes
		return round( n, decimals ) .. largest.symbol
	else
		return "0"
	end
end

-------------------------
-- nicetime
-------------------------
local floor = math.floor
local times = {
	{ "y", 31556926 }, -- years
	{ "mon", 2629743.83 }, -- months
	{ "w", 604800 }, -- weeks
	{ "d", 86400 }, -- days
	{ "h", 3600 }, -- hours
	{ "m", 60 }, -- minutes
	{ "s", 1 }, -- seconds
}
function nicenumber.nicetime( n )
	n = math.abs( n )

	if n == 0 then return "0s" end

	local prev_name = ""
	local prev_val = 0
	for i=1,#times do
		local name = times[i][1]
		local num = times[i][2]

		local temp = floor(n / num)
		if temp > 0 or prev_name ~= "" then
			if prev_name ~= "" then
				return prev_val .. prev_name .. " " .. temp .. name
			else
				prev_name = name
				prev_val = temp
				n = n % num
			end
		end
	end

	if prev_name ~= "" then
		return prev_val .. prev_name
	else
		return "0s"
	end
end


-- Used by any applyForce function available to the user
-- Ensures that the force is within the range of a float, to prevent
-- physics engine crashes
local min_force = -3.4E+38
local max_force =  3.4E+38
function WireLib.checkForce(v)
	if isvector(v) then
		return 	min_force < v.x and v.x < max_force and
				min_force < v.y and v.y < max_force and
				min_force < v.z and v.z < max_force
	elseif isangle(v) then
		return 	min_force < v.p and v.p < max_force and
				min_force < v.y and v.y < max_force and
				min_force < v.r and v.r < max_force
	else -- E2 vectors/angles
		return 	min_force < v[1] and v[1] < max_force and
				min_force < v[2] and v[2] < max_force and
				min_force < v[3] and v[3] < max_force
	end
end
