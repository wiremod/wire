WireLib = WireLib or {}

local pairs = pairs
local setmetatable = setmetatable
local rawget = rawget
local next = next
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local Entity = Entity

local string = string
local string_gsub = string.gsub
local string_char = string.char
local string_match = string.match
local string_sub = string.sub
local utf8_char = utf8.char
local hook = hook

MAX_EDICT_BITS = MAX_EDICT_BITS or 13 -- Delete once MAX_EDICT_BITS is fully out in base GMod

-- extra table functions

-- Returns a noniterable version of tbl. So indexing still works, but pairs(tbl) won't find anything
-- Useful for hiding entity lookup tables, since Garrydupe uses util.TableToJSON, which crashes on tables with entity keys
function table.MakeNonIterable(tbl) -- luacheck: ignore
    return setmetatable({}, { __index = tbl, __setindex = tbl})
end

-- Compacts an array by rejecting entries according to cb.
function table.Compact(tbl, cb, n) -- luacheck: ignore
	n = n or #tbl
	local cpos = 1
	for i = 1, n do
		if cb(tbl[i]) then
			tbl[cpos] = tbl[i]
			cpos = cpos + 1
		end
	end

	while (cpos <= n) do
		tbl[cpos] = nil
		cpos = cpos + 1
	end
end

-- Removes `value` from `tbl` by shifting last element of `tbl` to its place.
-- Returns index of `value` if it was removed, nil otherwise.
function table.RemoveFastByValue(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            tbl[i] = tbl[#tbl]
            tbl[#tbl] = nil

            return i
        end
    end
end

function string.GetNormalizedFilepath( path ) -- luacheck: ignore
	local null = string.find(path, "\x00", 1, true)
	if null then path = string.sub(path, 1, null-1) end

	local tbl = string.Explode( "[/\\]+", path, true )
	local i = 1
	while i <= #tbl do
		if tbl[i] == "." or tbl[i]=="" then
			table.remove(tbl, i)
		elseif tbl[i] == ".." then
			table.remove(tbl, i)
			if i>1 then
				i = i - 1
				table.remove(tbl, i)
			end
		else
			i = i + 1
		end
	end
	return table.concat(tbl, "/")
end

-- works like pairs() except that it iterates sorted by keys.
-- criterion is optional and should be a function(a,b) returning whether a is less than b. (same as table.sort's criterions)
function pairs_sortkeys(tbl, criterion)
	local tmp = {}
	for k, _ in pairs(tbl) do table.insert(tmp,k) end
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

	local tmp = {}
	tbl = tbl or {}
	for k, _ in pairs(tbl) do table.insert(tmp,k) end
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
local pairs_sortvalues = pairs_sortvalues
local ipairs_map = ipairs_map

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
		local meta = { new = new }
		meta.__index = meta
		WireLib.containers[container_name] = meta
		return meta
	end

	WireLib.containers = { new = new, newclass = newclass }

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
			[NOTIFYSOUND_DRIP5   ] = "ambient/water/drip4.wav", -- Non-existent sound, left for compatibility
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
			local Type = net.ReadUInt(3)
			local Duration = net.ReadFloat()
			local Sound = net.ReadUInt(4)

			WireLib.AddNotify(LocalPlayer(), Message, Type, Duration, Sound)
		end)
	else
		util.AddNetworkString("wire_addnotify")

		function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
			if isstring(ply) then ply, Message, Type, Duration, Sound = nil, ply, Message, Type, Duration end
			if ply and not ply:IsValid() then return end

			net.Start("wire_addnotify")
				net.WriteString(Message)
				net.WriteUInt(Type or 0, 3)
				net.WriteFloat(Duration)
				net.WriteUInt(Sound or 0, 4)
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

do
local max_items_per_flush = 1024
local queue_limit = 65536
local ack_timeout = 30

local function PlyQueue()
	return {
		__flushing = false,
		__ack_timeout = 0,
		add = function(self, item)
			local n=#self+1
			if n>queue_limit then return end
			self[n]=item
		end
	}
end

local net_Send = SERVER and net.Send or net.SendToServer
WireLib.NetQueue = {
	__index = {
		add = SERVER and function(self, item, ply)
			if ply==nil then
				for _, ply in player.Iterator() do self.plyqueues[ply]:add(item) end
			else
				self.plyqueues[ply]:add(item)
			end
			self:notifyFlush()
		end or function(self, item)
			self.plyqueues[NULL]:add(item)
			self:notifyFlush()
		end,
		cleanup = function(self, ply)
			self.plyqueues[ply] = nil
		end,
		notifyFlush = function(self)
			if self.flushing then return end
			self.flushing = true
			timer.Simple(0, function() self:flush() end)
		end,
		flush = function(self)
			for ply, queue in pairs(self.plyqueues) do self:flushQueue(ply, queue) end
			self.flushing = false
		end,
		flushQueue = function(self, ply, queue)
			if queue[1]==nil then return end
			local t = CurTime()
			if queue.__flushing and t<queue.__ack_timeout then return end
			queue.__flushing = true
			queue.__ack_timeout = t+ack_timeout

			net.Start(self.name)
				local written = 0
				while written < #queue and written < max_items_per_flush and net.BytesWritten() < 32768 do
					net.WriteUInt(1, 1)
					written = written + 1
					queue[written]()
				end
				net.WriteUInt(0, 1)
			net_Send(ply)
			for i=1,#queue do queue[i]=queue[i+written] end
		end,
		receive = function(self, ply)
			if net.ReadUInt(1)==0 then -- An empty message indicates a receive Ack
				local plyqueue = self.plyqueues[ply]
				plyqueue.__flushing = false
				self:flushQueue(ply, plyqueue)
			else
				if self.receivecb then
					for i=1, max_items_per_flush do
						if net.BytesLeft()<=0 then break end
						self.receivecb()
						if net.ReadUInt(1)==0 then break end
					end
				end
				net.Start(self.name) net.WriteUInt(0, 1) net_Send(ply) -- Send an empty message to Ack
			end
		end,
	},
	__call = function(t, name, receivecb)
		if SERVER then util.AddNetworkString(name) end

		local queue = setmetatable({
			name = name,
			receivecb = receivecb,
			flushing = false,
			plyqueues = setmetatable({},{__index = function(t,k) local v=PlyQueue() t[k]=v return v end})
		}, t)

		net.Receive(name, function(len, ply) queue:receive(ply or NULL) end)

		return queue
	end
}
setmetatable(WireLib.NetQueue, WireLib.NetQueue)
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
	local entTbl = ent:GetTable()
	if entTbl.IsWire then return true end
	if entTbl.Base == "base_wire_entity" then return true end

	-- Checks if the entity is in the list, it checks if the entity has self.in-/outputs too.
	local In, Out = WireLib.GetPorts(ent)
	if In and (entTbl.Inputs or CLIENT) then return true end
	if Out and (entTbl.Outputs or CLIENT) then return true end

	return false
end

local WirePortQueue = WireLib.NetQueue("wire_ports")
local CMD_DELETE,CMD_PORT,CMD_LINK = 0,1,2
local PORT_TYPE_INPUT,PORT_TYPE_OUTPUT = 0,1
if SERVER then

	local ents_with_inputs = {}
	local ents_with_outputs = {}
	--local IOlookup = { [INPUT] = ents_with_inputs, [OUTPUT] = ents_with_outputs }

	timer.Create("Debugger.PoolTypeStrings",1,1,function()
		if WireLib.Debugger and WireLib.Debugger.formatPort then
			for typename,_ in pairs(WireLib.Debugger.formatPort) do util.AddNetworkString(typename) end -- Reduce bandwidth
		end
	end)

	function WireLib.GetPorts(ent)
		local eid = ent:EntIndex()
		return ents_with_inputs[eid], ents_with_outputs[eid]
	end

	function WireLib.RemoveOutPort(ent, name)
		local outputs = ents_with_outputs[ent:EntIndex()]
		if outputs then
			for k, v in ipairs(outputs) do
				if v[1] == name then
					table.remove(outputs, k)
				end
			end
		end
	end

	local function SendDeletePort(queue, eid, porttype)
		queue:add(function()
			net.WriteUInt(CMD_DELETE, 2)
			net.WriteUInt(eid, MAX_EDICT_BITS)
			net.WriteUInt(porttype, 1)
		end)
	end

	local function SendPortInfo(queue, eid, porttype, ports)
		queue:add(function()
			net.WriteUInt(CMD_PORT, 2)
			net.WriteUInt(eid, MAX_EDICT_BITS)
			net.WriteUInt(porttype, 1)

			net.WriteUInt(table.Count(ports), 8)
			for Name, CurPort in pairs_sortvalues(ports, WireLib.PortComparator) do
				net.WriteString(Name)
				net.WriteString(CurPort.Type)
				net.WriteString(CurPort.Desc or "")
				if porttype==PORT_TYPE_INPUT then
					net.WriteBool(CurPort.SrcId and true or false)
				end
			end
		end)
	end

	local function SendLinkInfo(queue, eid, num, state)
		queue:add(function()
			net.WriteUInt(CMD_LINK, 2)
			net.WriteUInt(eid, MAX_EDICT_BITS)
			net.WriteUInt(1, 8)
			net.WriteUInt(num, 8)
			net.WriteBool(state)
		end)
	end

	function WireLib._RemoveWire(eid, DontSend) -- To remove the inputs without to remove the entity. Very important for IsWire checks!
		if ents_with_inputs[eid] then
			ents_with_inputs[eid] = nil
			if not DontSend then SendDeletePort(WirePortQueue, eid, PORT_TYPE_INPUT) end
		end
		if ents_with_outputs[eid] then
			ents_with_outputs[eid] = nil
			if not DontSend then SendDeletePort(WirePortQueue, eid, PORT_TYPE_OUTPUT) end
		end
	end

	function WireLib._SetInputs(ent)
		local eid = ent:EntIndex()
		local inputs = ent.Inputs
		if not inputs then return end

		local ent_input_array = {}
		ents_with_inputs[eid] = ent_input_array

		for Name, CurPort in pairs_sortvalues(inputs, WireLib.PortComparator) do
			ent_input_array[#ent_input_array+1] = { Name, CurPort.Type, CurPort.Desc or "", CurPort.Num }
		end
		SendPortInfo(WirePortQueue, eid, PORT_TYPE_INPUT, inputs)
	end

	function WireLib._SetOutputs(ent)
		local eid = ent:EntIndex()
		local outputs = ent.Outputs
		if not outputs then return end

		local ent_output_array = {}
		ents_with_outputs[eid] = ent_output_array

		for Name, CurPort in pairs_sortvalues(outputs, WireLib.PortComparator) do
			ent_output_array[#ent_output_array+1] = { Name, CurPort.Type, CurPort.Desc or "", CurPort.Num }
		end
		SendPortInfo(WirePortQueue, eid, PORT_TYPE_OUTPUT, outputs)
	end

	function WireLib._SetLink(input)
		SendLinkInfo(WirePortQueue, input.Entity:EntIndex(), input.Num, input.SrcId and true or false)
	end

	hook.Add("PlayerInitialSpawn", "wire_ports", function(ply)
		local queue = WirePortQueue.plyqueues[ply]
		for eid, _ in pairs(ents_with_inputs) do
			local ports = Entity(eid).Inputs
			if not ports then continue end
			SendPortInfo(queue, eid, PORT_TYPE_INPUT, ports)
		end
		for eid, _ in pairs(ents_with_outputs) do
			local ports = Entity(eid).Outputs
			if not ports then continue end
			SendPortInfo(queue, eid, PORT_TYPE_OUTPUT, ports)
		end
		WirePortQueue:flushQueue(ply, queue)
	end)

	hook.Add("EntityRemoved", "wire_ports", function(ent)
		if ent:IsPlayer() then
			WirePortQueue:cleanup(ent)
		else
			WireLib._RemoveWire(ent:EntIndex())
		end
	end)

elseif CLIENT then
	local ents_with_inputs = {}
	local ents_with_outputs = {}

	function WirePortQueue.receivecb()
		local cmd, eid = net.ReadUInt(2), net.ReadUInt(MAX_EDICT_BITS)
		if cmd == CMD_DELETE then
			if net.ReadUInt(1)==PORT_TYPE_INPUT then
				-- print("Delete",eid,"input")
				ents_with_inputs[eid] = nil
			else
				-- print("Delete",eid,"output")
				ents_with_outputs[eid] = nil
			end
		elseif cmd == CMD_PORT then
			if net.ReadUInt(1)==PORT_TYPE_INPUT then
				local entry = {}
				for i=1, net.ReadUInt(8) do
					entry[i] = {net.ReadString(), net.ReadString(), net.ReadString(), net.ReadBool()}
					-- print("Port",eid,entry[i][1],entry[i][2],entry[i][3],entry[i][4])
				end
				ents_with_inputs[eid]=entry
			else
				local entry = {}
				for i=1, net.ReadUInt(8) do
					entry[i] = {net.ReadString(), net.ReadString(), net.ReadString()}
					-- print("Port",eid,entry[i][1],entry[i][2],entry[i][3])
				end
				ents_with_outputs[eid]=entry
			end
		elseif cmd == CMD_LINK then
			for i=1, net.ReadUInt(8) do
				local num, state = net.ReadUInt(8), net.ReadBool()
				-- print("Link",eid,num, state)
				local entry = ents_with_inputs[eid]
				if entry and entry[num] then
					entry[num][4] = state
				end
			end
		end
	end

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
				for _,name,tp,desc,connected in ipairs_map(ents_with_inputs[eid] or {}, unpack) do

					text = text..(connected and "-" or " ")
					text = text..string.format("%s (%s) [%s]\n", name, tp, desc)
				end
				text = text.."\nOutputs:\n"
				for _,name,tp,desc in ipairs_map(ents_with_outputs[eid] or {}, unpack) do
					text = text..string.format("%s (%s) [%s]\n", name, tp, desc)
				end
				draw.DrawText(text,"Trebuchet24",10,300,Color(255,255,255,255),0)
			end)
		else
			hook.Remove("HUDPaint", "wire_ports_test")
		end
	end
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

function WireLib.isnan(n)
	return n ~= n
end
local isnan = WireLib.isnan

-- This function clamps the position before moving the entity
local minx, miny, minz = -16384, -16384, -16384
local maxx, maxy, maxz = 16384, 16384, 16384
local clamp = math.Clamp
function WireLib.clampPos(pos)
	local x, y, z = pos:Unpack()

	return Vector(clamp(x, minx, maxx), clamp(y, miny, maxy), clamp(z, minz, maxz))
end

function WireLib.setPos(ent, pos)
	if isnan(pos.x) or isnan(pos.y) or isnan(pos.z) then return end
	return ent:SetPos(WireLib.clampPos(pos))
end

function WireLib.setLocalPos(ent, pos)
	if isnan(pos.x) or isnan(pos.y) or isnan(pos.z) then return end
	return ent:SetLocalPos(WireLib.clampPos(pos))
end

function WireLib.setAng(ent, ang)
	if isnan(ang.pitch) or isnan(ang.yaw) or isnan(ang.roll) then return end
	return ent:SetAngles(ang)
end

function WireLib.setLocalAng(ent, ang)
	if isnan(ang.pitch) or isnan(ang.yaw) or isnan(ang.roll) then return end
	return ent:SetLocalAngles(ang)
end

local escapeChars = { n = "\n", r = "\r", t = "\t", ["\\"] = "\\", ["'"] = "'", ["\""] = "\"", a = "\a",
b = "\b", f = "\f", v = "\v" }

--- Replaces escape sequences with the appropriate character. Uses Lua escape sequences. Invalid sequences are skipped.
--- @param str string
function WireLib.ParseEscapes(str)
	str = string_gsub(str, "\\(.?)([^\\]?[^\\]?[^\\]?[^\\]?[^\\]?[^\\]?[^\\]?}?)", function(i, arg)
		if escapeChars[i] then
			return escapeChars[i] .. arg
		elseif i == "x" then
			local num = string_match(arg, "^(%x%x)")
			if not num then return false end
			return string_char(tonumber(num, 16)) .. string_sub(arg, #num + 1)
		elseif i >= "0" and i <= "9" then
			local num = string_match(arg, "^(%d?%d?)")
			if not num then return false end
			local tonum = tonumber(i .. num)
			return tonum < 256 and (string_char(tonum) .. string_sub(arg, #num + 1))
		elseif i == "u" then
			local num = string_match(arg, "^{(%x%x?%x?%x?%x?%x?)}")
			if not num then return false end
			local tonum = tonumber(num, 16)
			return tonum <= 0x10ffff and utf8_char(tonum) .. string_sub(arg, #num + 3)
		else
			return false
		end
	end)
	return str
end

-- Used by any applyForce function available to the user
-- Ensures that the force is within the range of a float, to prevent
-- physics engine crashes
-- 2*maxmass*maxvelocity should be enough impulse to do whatever you want.
-- Timer resolves issue with table not existing until next tick on Linux
local max_force, min_force
hook.Add("InitPostEntity","WireForceLimit",function()
	timer.Simple(0, function()
		max_force = 100000*physenv.GetPerformanceSettings().MaxVelocity
		min_force = -max_force
	end)
end)

-- Nan never equals itself, so if the value doesn't equal itself replace it with 0.
function WireLib.clampForce( v )
	local x, y, z = v:Unpack()

	return Vector(
		clamp( x, min_force, max_force ),
		clamp( y, min_force, max_force ),
		clamp( z, min_force, max_force )
	)
end


--[[----------------------------------------------
	GetClosestRealVehicle
	This function checks if the provided entity is a "real" vehicle
	If it is, it does nothing and returns the same entity back.
	If it isn't, it scans the contraption of said vehicle, and
	finds the closest one to the specified location
	and returns it
------------------------------------------------]]

-- this helper function attempts to determine if the vehicle is actually a real vehicle
-- and not a "fake" vehicle created by an 'scars'-like addon
local valid_vehicles = {
	prop_vehicle = true,
	prop_vehicle_airboat = true,
	prop_vehicle_apc = true,
	prop_vehicle_cannon = true,
	prop_vehicle_choreo_generic = true,
	prop_vehicle_crane = true,
	prop_vehicle_driveable = true,
	prop_vehicle_jeep = true,
	prop_vehicle_prisoner_pod = true
}
local function IsRealVehicle(pod)
	return valid_vehicles[pod:GetClass()]
end

-- Helper function for GetClosestRealVehicle
-- we don't use constraint.GetAllConstrainedEntities here because it's far worse for performance
local function getContraption(ent, already_checked, callback)
	for _, con in pairs( ent.Constraints or {} ) do
		if IsValid(con) then
			for i=1, 6 do
				local e = con["Ent" .. i]
				if e and not already_checked[e] then
					already_checked[e] = true
					callback(e)
					getContraption(e,already_checked,callback)
				end
			end
		end
	end
end

-- GetClosestRealVehicle
-- Args:
--  vehicle; the vehicle that the user would like to link a controller to
--  position; the position to find the closest vehicle to. If unspecified, uses the vehicle's position
--  notify_this_player; notifies this player if a different vehicle was selected. If unspecified, notifies no one.
function WireLib.GetClosestRealVehicle(vehicle,position,notify_this_player)
	if not IsValid(vehicle) then return vehicle end
	if not position then position = vehicle:GetPos() end

	-- If this is a valid entity, but not a real vehicle, then let's get started
	if IsValid(vehicle) and not IsRealVehicle(vehicle) then
		local distance = math.huge

		getContraption(vehicle,{[vehicle]=true},
			function(ent)
				if IsRealVehicle(ent) then
					local dist = position:DistToSqr(ent:GetPos())
					if dist < distance then
						distance = dist
						vehicle = ent
					end
				end
			end
		)

		-- if vehicle is now a real vehicle, and we wanted to notify a player, do so now
		if IsRealVehicle(vehicle) and IsValid(notify_this_player) and notify_this_player:IsPlayer() then
			WireLib.AddNotify(notify_this_player,
				"That wasn't a vehicle!\n"..
				"The contraption has been scanned and this entity has instead been linked to the closest vehicle in this contraption.\n"..
				"Hover your cursor over the controller to view the yellow line, which indicates the selected vehicle.",
				NOTIFY_GENERIC,14,NOTIFYSOUND_DRIP1)
		end
	end

	-- If the selected vehicle is still not a real vehicle even after all of the above, notify the user of this
	if not IsRealVehicle(vehicle) and IsValid(notify_this_player) and notify_this_player:IsPlayer() then
		WireLib.AddNotify(notify_this_player,
			"The entity you linked to is not a 'real' vehicle, " ..
			"and we were unable to find any 'real' vehicles attached to it. This controller might not work.",
			NOTIFY_GENERIC,14,NOTIFYSOUND_DRIP1)
	end

	return vehicle
end

-- Garry's Mod lets serverside Lua check whether the key associated with a particular bind is
-- pressed or not via the KeyPress and KeyRelease hooks, and the KeyDown function. However, this
-- is only available for a small number of binds (mostly ones related to movement), which are
-- exposed via the IN_ enums. It's possible to check any key manually serverside (with the
-- player.keystate table), but that doesn't handle rebinding so isn't very friendly to users with
-- non-QWERTY keyboard layouts. This system lets us extend arbitrarily the set of binds that the
-- serverside knows about.
do
	local MESSAGE_NAME = "WireLib.SyncBinds"

	local interestingBinds = {
		"invprev",
		"invnext",
		"impulse 100",
		"attack",
		"jump",
		"noclip",
		"duck",
		"forward",
		"back",
		"use",
		"left",
		"right",
		"moveleft",
		"moveright",
		"attack2",
		"reload",
		"alt1",
		"alt2",
		"showscores",
		"speed",
		"walk",
		"zoom",
		"grenade1",
		"grenade2",
	}
	local interestingBindsLookup = {}
	for k, v in pairs(interestingBinds) do interestingBindsLookup[v] = k end

	if CLIENT then
		hook.Add("InitPostEntity", MESSAGE_NAME, function()
			local data = {}
			for button = BUTTON_CODE_NONE, BUTTON_CODE_LAST do
				local binding = input.LookupKeyBinding(button)
				if binding ~= nil then
					if string.sub(binding, 1, 1) == "+" then binding = string.sub(binding, 2) end
					local bindingIndex = interestingBindsLookup[binding]
					if bindingIndex ~= nil then
						table.insert(data, { Button = button, BindingIndex = bindingIndex })
					end
				end
			end

			-- update net integer precisions if interestingBinds exceeds 32
			if (BUTTON_CODE_COUNT >= 65536) then ErrorNoHalt("ERROR! BUTTON_CODE_COUNT exceeds 65536!") end
			if (#interestingBinds >= 32) then ErrorNoHalt("ERROR! Interesting binds exceeds 32!") end

			net.Start(MESSAGE_NAME)
			net.WriteUInt(#data, 8)
			for _, datum in pairs(data) do
				net.WriteUInt(datum.Button, 16)
				net.WriteUInt(datum.BindingIndex, 5)
			end
			net.SendToServer()
		end)
	elseif SERVER then
		util.AddNetworkString(MESSAGE_NAME)
		net.Receive(MESSAGE_NAME, function(_, player)
			player.SyncedBindings = {}
			local count = net.ReadUInt(8)
			for _ = 1, count do
				local button = net.ReadUInt(16)
				local bindingIndex = net.ReadUInt(5)
				if button > BUTTON_CODE_NONE and button <= BUTTON_CODE_LAST then
					local binding = interestingBinds[bindingIndex]
					player.SyncedBindings[button] = binding
				end
			end
		end)

		hook.Add("PlayerButtonDown", MESSAGE_NAME, function(player, button)
			if not player.SyncedBindings then return end
			local binding = player.SyncedBindings[button]
			hook.Run("PlayerBindDown", player, binding, button)
		end)

		hook.Add("PlayerButtonUp", MESSAGE_NAME, function(player, button)
			if not player.SyncedBindings then return end
			local binding = player.SyncedBindings[button]
			hook.Run("PlayerBindUp", player, binding, button)
		end)
	end
end

-- Generic clean-up system for tables with players as keys
WireLib.PlayerTables = setmetatable({}, {__mode = "kv"})

function WireLib.RegisterPlayerTable(tbl)
    tbl = tbl or {}
    WireLib.PlayerTables[tbl] = tbl
    return tbl
end

hook.Add("PlayerDisconnected", "WireLib_PlayerDisconnect", function(ply)
  for _,tbl in pairs(WireLib.PlayerTables) do
    tbl[ply] = nil
  end
end)


local EntityMeta   = FindMetaTable("Entity") -- direct references are faster
local GetPos       = EntityMeta.GetPos
local GetAngles    = EntityMeta.GetAngles

function WireLib.GetComputeIfEntityTransformDirty(compute)
	return setmetatable({}, {
		__index=function(t,ent) local r={Vector(math.huge), Angle()} t[ent]=r return r end,
		__call=function(t,ent)
			local data = t[ent]
			local pos, ang = GetPos(ent), GetAngles(ent)
			if pos~=data[1] or ang~=data[2] then
				data[1] = pos
				data[2] = ang
				data[3] = compute(ent)
			end
			return data[3]
		end
	})
end

-- Notify --

---@alias WireLib.NotifySeverity
---| 0 # None
---| 1 # Info
---| 2 # Warning
---| 3 # Error

local severity2color = {
	[0] = color_white,
	[1] = color_white,
	[2] = Color(255, 88, 1),
	[3] = Color(255, 32, 0)
}

local WIREMOD_COLOR = Color(1, 168, 255)

local severity2title = {
	[0] = { "" },
	[1] = { WIREMOD_COLOR, "[Wiremod]: " },
	[2] = { WIREMOD_COLOR, "[Wiremod ", severity2color[2], "WARNING", WIREMOD_COLOR, "]: " },
	[3] = { WIREMOD_COLOR, "[Wiremod ", severity2color[3], "ERROR", WIREMOD_COLOR, "]: " },
}

--- Internal. Creates a table for MsgC/chat.AddText.
function WireLib.NotifyBuilder(msg, severity, color)
	local ret = {}
	for k, v in ipairs(severity2title[severity]) do
		ret[k] = v
	end
	local n = #ret
	ret[n + 1] = color or severity2color[severity]
	ret[n + 2] = msg
	return ret
end

local typeIDToStringTable = {
	[TYPE_NONE] = "none",
	[TYPE_NIL] = "nil",
	[TYPE_BOOL] = "boolean",
	[TYPE_LIGHTUSERDATA] = "lightuserdata",
	[TYPE_NUMBER] = "number",
	[TYPE_STRING] = "string",
	[TYPE_TABLE] = "table",
	[TYPE_FUNCTION] = "function",
	[TYPE_USERDATA] = "userdata",
	[TYPE_THREAD] = "thread",
	[TYPE_ENTITY] = "entity",
	[TYPE_VECTOR] = "vector",
	[TYPE_ANGLE] = "angle",
	[TYPE_PHYSOBJ] = "physobj",
	[TYPE_SAVE] = "save",
	[TYPE_RESTORE] = "restore",
	[TYPE_DAMAGEINFO] = "damageinfo",
	[TYPE_EFFECTDATA] = "effectdata",
	[TYPE_MOVEDATA] = "movedata",
	[TYPE_RECIPIENTFILTER] = "recipientfilter",
	[TYPE_USERCMD] = "usercmd",
	[TYPE_SCRIPTEDVEHICLE] = "scriptedvehicle",
	[TYPE_MATERIAL] = "material",
	[TYPE_PANEL] = "panel",
	[TYPE_PARTICLE] = "particle",
	[TYPE_PARTICLEEMITTER] = "particleemitter",
	[TYPE_TEXTURE] = "texture",
	[TYPE_USERMSG] = "usermsg",
	[TYPE_CONVAR] = "convar",
	[TYPE_IMESH] = "imesh",
	[TYPE_MATERIAL] = "matrix",
	[TYPE_SOUND] = "sound",
	[TYPE_PIXELVISHANDLE] = "pixelvishandle",
	[TYPE_DLIGHT] = "dlight",
	[TYPE_VIDEO] = "video",
	[TYPE_FILE] = "file",
	[TYPE_LOCOMOTION] = "locomotion",
	[TYPE_PATH] = "path",
	[TYPE_NAVAREA] = "navarea",
	[TYPE_SOUNDHANDLE] = "soundhandle",
	[TYPE_NAVLADDER] = "navladder",
	[TYPE_PARTICLESYSTEM] = "particlesystem",
	[TYPE_PROJECTEDTEXTURE] = "projectedtexture",
	[TYPE_PHYSCOLLIDE] = "physcollide",
	[TYPE_SURFACEINFO] = "surfaceinfo",
	[TYPE_COUNT] = "count",
	[TYPE_COLOR] = "color",
}

-- Silly function to make printouts more userfriendly.
function WireLib.typeIDToString(typeID)
	return typeIDToStringTable[typeID] or "unregistered type"
end
