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
			if ply and not ply:IsValid() then return end
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
		for _, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
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
		-- Zero these two for the writemsg function
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
		for eid, _ in pairs(ents_with_inputs) do
			WireLib._SetInputs(Entity(eid), lqueue)
		end
		for eid, _ in pairs(ents_with_outputs) do
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
	pos = Vector(pos)
	pos.x = clamp(pos.x, minx, maxx)
	pos.y = clamp(pos.y, miny, maxy)
	pos.z = clamp(pos.z, minz, maxz)
	return pos
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
	return Vector(
		v[1] == v[1] and math.Clamp( v[1], min_force, max_force ) or 0,
		v[2] == v[2] and math.Clamp( v[2], min_force, max_force ) or 0,
		v[3] == v[3] and math.Clamp( v[3], min_force, max_force ) or 0
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

do
--- StringStream type
-- @name StringStream
-- @class type
-- @libtbl ss_methods

local ss_methods = {}
local ss_meta = {
	__index = ss_methods,
	__metatable = "StringStream",
	__tostring = function(self)
		return string.format("Stringstream [%u,%u]", self:tell(), self:size())
	end
}
local ss_methods_big = setmetatable({},{__index=ss_methods})
local ss_meta_big = {
	__index = ss_methods_big,
	__metatable = "StringStream",
	__tostring = function(self)
		return string.format("Stringstream [%u,%u]", self:tell(), self:size())
	end
}

function WireLib.StringStream(stream, i, endian)
	local ret = setmetatable({
		index = 1,
		subindex = 1
	}, ss_meta)

	if stream ~= nil then
		checkluatype(stream, TYPE_STRING)
		ret:write(stream)
		if i~=nil then checkluatype(i, TYPE_NUMBER) ret:seek(i) else ret:seek(1) end
	end
	if endian ~= nil then
		checkluatype(endian, TYPE_STRING)
		ret:setEndian(endian)
	end

	return ret
end

--Credit https://stackoverflow.com/users/903234/rpfeltz
--Bugfixes and IEEE754Double credit to me
local function PackIEEE754Float(number)
	if number == 0 then
		return 0x00, 0x00, 0x00, 0x00
	elseif number == math_huge then
		return 0x00, 0x00, 0x80, 0x7F
	elseif number == -math_huge then
		return 0x00, 0x00, 0x80, 0xFF
	elseif number ~= number then
		return 0x00, 0x00, 0xC0, 0xFF
	else
		local sign = 0x00
		if number < 0 then
			sign = 0x80
			number = -number
		end
		local mantissa, exponent = math_frexp(number)
		exponent = exponent + 0x7F
		if exponent <= 0 then
			mantissa = math_ldexp(mantissa, exponent - 1)
			exponent = 0
		elseif exponent > 0 then
			if exponent >= 0xFF then
				return 0x00, 0x00, 0x80, sign + 0x7F
			elseif exponent == 1 then
				exponent = 0
			else
				mantissa = mantissa * 2 - 1
				exponent = exponent - 1
			end
		end
		mantissa = math_floor(math_ldexp(mantissa, 23) + 0.5)
		return mantissa % 0x100,
				bit_rshift(mantissa, 8) % 0x100,
				(exponent % 2) * 0x80 + bit_rshift(mantissa, 16),
				sign + bit_rshift(exponent, 1)
	end
end
local function UnpackIEEE754Float(b4, b3, b2, b1)
	local exponent = (b1 % 0x80) * 0x02 + bit_rshift(b2, 7)
	local mantissa = math_ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
	if exponent == 0xFF then
		if mantissa > 0 then
			return 0 / 0
		else
			if b1 >= 0x80 then
				return -math_huge
			else
				return math_huge
			end
		end
	elseif exponent > 0 then
		mantissa = mantissa + 1
	else
		exponent = exponent + 1
	end
	if b1 >= 0x80 then
		mantissa = -mantissa
	end
	return math_ldexp(mantissa, exponent - 0x7F)
end
local function PackIEEE754Double(number)
	if number == 0 then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	elseif number == math_huge then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x7F
	elseif number == -math_huge then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xFF
	elseif number ~= number then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xFF
	else
		local sign = 0x00
		if number < 0 then
			sign = 0x80
			number = -number
		end
		local mantissa, exponent = math_frexp(number)
		exponent = exponent + 0x3FF
		if exponent <= 0 then
			mantissa = math_ldexp(mantissa, exponent - 1)
			exponent = 0
		elseif exponent > 0 then
			if exponent >= 0x7FF then
				return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, sign + 0x7F
			elseif exponent == 1 then
				exponent = 0
			else
				mantissa = mantissa * 2 - 1
				exponent = exponent - 1
			end
		end
		mantissa = math_floor(math_ldexp(mantissa, 52) + 0.5)
		return mantissa % 0x100,
				math_floor(mantissa / 0x100) % 0x100,  --can only rshift up to 32 bit numbers. mantissa is too big
				math_floor(mantissa / 0x10000) % 0x100,
				math_floor(mantissa / 0x1000000) % 0x100,
				math_floor(mantissa / 0x100000000) % 0x100,
				math_floor(mantissa / 0x10000000000) % 0x100,
				(exponent % 0x10) * 0x10 + math_floor(mantissa / 0x1000000000000),
				sign + bit_rshift(exponent, 4)
	end
end
local function UnpackIEEE754Double(b8, b7, b6, b5, b4, b3, b2, b1)
	local exponent = (b1 % 0x80) * 0x10 + bit_rshift(b2, 4)
	local mantissa = math_ldexp(((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8, -52)
	if exponent == 0x7FF then
		if mantissa > 0 then
			return 0 / 0
		else
			if b1 >= 0x80 then
				return -math_huge
			else
				return math_huge
			end
		end
	elseif exponent > 0 then
		mantissa = mantissa + 1
	else
		exponent = exponent + 1
	end
	if b1 >= 0x80 then
		mantissa = -mantissa
	end
	return math_ldexp(mantissa, exponent - 0x3FF)
end

--- Sets the endianness of the string stream
-- @param string endian The endianness of number types. "big" or "little" (default "little")
function ss_methods:setEndian(endian)
	if endian == "little" then
		debug.setmetatable(self, ss_meta)
	elseif endian == "big" then
		debug.setmetatable(self, ss_meta_big)
	else
		error("Invalid endian specified", 2)
	end
end

--- Writes the given string and advances the buffer pointer.
-- @param string data A string of data to write
function ss_methods:write(data)
	if self.index > #self then -- Most often case
		self[self.index] = data
		self.index = self.index + 1
		self.subindex = 1
	else
		local i = 1
		local length = #data
		while length > 0 do
			if self.index > #self then -- End of buffer
				self[self.index] = string.sub(data, i)
				self.index = self.index + 1
				self.subindex = 1
				break
			else
				local cur = self[self.index]
				local sublength = math_min(#cur - self.subindex + 1, length)
				self[self.index] = string.sub(cur,1,self.subindex-1) .. string.sub(data,i,i+sublength-1) .. string.sub(cur,self.subindex+sublength)
				length = length - sublength
				i = i + sublength
				if length > 0 then
					self.index = self.index + 1
					self.subindex = 1
				else
					self.subindex = self.subindex + sublength
				end
			end
		end
	end
end

--- Reads the specified number of bytes from the buffer and advances the buffer pointer.
-- @param number length How many bytes to read
-- @return string A string containing the bytes
function ss_methods:read(length)
	local ret = {}
	while length > 0 do
		local cur = self[self.index]
		if cur then
			if self.subindex == 1 and length >= #cur then
				ret[#ret+1] = cur
				self.index = self.index + 1
				length = length - #cur
			else
				local sublength = math_min(#cur - self.subindex + 1, length)
				ret[#ret+1] = string.sub(cur, self.subindex, self.subindex + sublength - 1)
				length = length - sublength
				if length > 0 then
					self.index = self.index + 1
					self.subindex = 1
				else
					self.subindex = self.subindex + sublength
				end
			end
		else
			break
		end
	end
	return table.concat(ret)
end

--- Sets internal pointer to pos. The position will be clamped to [1, buffersize+1]
-- @param number pos Position to seek to
function ss_methods:seek(pos)
	if pos < 1 then error("Index must be 1 or greater", 2) end
	self.index = #self+1
	self.subindex = 1

	local length = 0
	for i, v in ipairs(self) do
		length = length + #v
		if length >= pos then
			self.index = i
			self.subindex = pos - (length - #v)
			break
		end
	end
end

--- Move the internal pointer by amount i
-- @param number length The offset
function ss_methods:skip(length)
	while length>0 do
		local cur = self[self.index]
		if cur then
			local sublength = math_min(#cur - self.subindex + 1, length)
			length = length - sublength
			self.subindex = self.subindex + sublength
			if self.subindex>#cur then
				self.index = self.index + 1
				self.subindex = 1
			end
		else
			self.index = self.index + 1
			self.subindex = 1
			break
		end
	end
	while length<0 do
		local cur = self[self.index]
		if cur then
			local sublength = math_max(-self.subindex, length)
			length = length - sublength
			self.subindex = self.subindex + sublength
			if self.subindex<1 then
				self.index = self.index - 1
				self.subindex = self[self.index] and #self[self.index] or 1
			end
		else
			self.index = 1
			self.subindex = 1
			break
		end
	end
end

--- Returns the internal position of the byte reader.
-- @return number The buffer position
function ss_methods:tell()
	local length = 0
	for i=1, self.index-1 do
		length = length + #self[i]
	end
	return length + self.subindex
end

--- Tells the size of the byte stream.
-- @return number The buffer size
function ss_methods:size()
	local length = 0
	for i, v in ipairs(self) do
		length = length + #v
	end
	return length
end

--- Reads an unsigned 8-bit (one byte) integer from the byte stream and advances the buffer pointer.
-- @return number UInt8 at this position
function ss_methods:readUInt8()
	return string.byte(self:read(1))
end
function ss_methods_big:readUInt8()
	return string.byte(self:read(1))
end

--- Reads an unsigned 16 bit (two byte) integer from the byte stream and advances the buffer pointer.
-- @return number UInt16 at this position
function ss_methods:readUInt16()
	local a,b = string.byte(self:read(2), 1, 2)
	return b * 0x100 + a
end
function ss_methods_big:readUInt16()
	local a,b = string.byte(self:read(2), 1, 2)
	return a * 0x100 + b
end

--- Reads an unsigned 32 bit (four byte) integer from the byte stream and advances the buffer pointer.
-- @return number UInt32 at this position
function ss_methods:readUInt32()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return d * 0x1000000 + c * 0x10000 + b * 0x100 + a
end
function ss_methods_big:readUInt32()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return a * 0x1000000 + b * 0x10000 + c * 0x100 + d
end

--- Reads a signed 8-bit (one byte) integer from the byte stream and advances the buffer pointer.
-- @return number Int8 at this position
function ss_methods:readInt8()
	local x = self:readUInt8()
	if x>=0x80 then x = x - 0x100 end
	return x
end

--- Reads a signed 16-bit (two byte) integer from the byte stream and advances the buffer pointer.
-- @return number Int16 at this position
function ss_methods:readInt16()
	local x = self:readUInt16()
	if x>=0x8000 then x = x - 0x10000 end
	return x
end

--- Reads a signed 32-bit (four byte) integer from the byte stream and advances the buffer pointer.
-- @return number Int32 at this position
function ss_methods:readInt32()
	local x = self:readUInt32()
	if x>=0x80000000 then x = x - 0x100000000 end
	return x
end

--- Reads a 4 byte IEEE754 float from the byte stream and advances the buffer pointer.
-- @return number Float32 at this position
function ss_methods:readFloat()
	return UnpackIEEE754Float(string.byte(self:read(4), 1, 4))
end
function ss_methods_big:readFloat()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return UnpackIEEE754Float(d, c, b, a)
end

--- Reads a 8 byte IEEE754 double from the byte stream and advances the buffer pointer.
-- @return number Double at this position
function ss_methods:readDouble()
	return UnpackIEEE754Double(string.byte(self:read(8), 1, 8))
end
function ss_methods_big:readDouble()
	local a,b,c,d,e,f,g,h = string.byte(self:read(8), 1, 8)
	return UnpackIEEE754Double(h, g, f, e, d, c, b, a)
end

--- Reads until the given byte and advances the buffer pointer.
-- @param number byte The byte to read until (in number form)
-- @return string The string of bytes read
function ss_methods:readUntil(byte)
	byte = string.char(byte)
	local ret = {}
	for i=self.index, #self do
		local cur = self[self.index]
		local find = string.find(cur, byte, self.subindex, true)
		if find then
			ret[#ret+1] = string.sub(cur, self.subindex, find)
			self.subindex = find+1
			if self.subindex > #cur then
				self.index = self.index + 1
				self.subindex = 1
			end
			break
		else
			if self.subindex == 1 then
				ret[#ret+1] = cur
			else
				ret[#ret+1] = string.sub(cur, self.subindex)
			end
			self.index = self.index + 1
			self.subindex = 1
		end
	end
	return table.concat(ret)
end

--- Returns a null terminated string, reads until "\x00" and advances the buffer pointer.
-- @return string The string of bytes read
function ss_methods:readString()
	local s = self:readUntil(0)
	return string.sub(s, 1, #s-1)
end

--- Writes a byte to the buffer and advances the buffer pointer.
-- @param number x Int8 to write
function ss_methods:writeInt8(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100 end
	self:write(string.char(x%0x100))
end

--- Writes a unsigned byte to the buffer and advances the buffer pointer.
-- @name ss_methods.writeUInt8
-- @class function
-- @param number x UInt8 to write
ss_methods.writeUInt8 = ss_methods.writeInt8

--- Writes a short to the buffer and advances the buffer pointer.
-- @param number x Int16 to write
function ss_methods:writeInt16(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x10000 end
	self:write(string.char(x%0x100, bit_rshift(x, 8)%0x100))
end
function ss_methods_big:writeInt16(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x10000 end
	self:write(string.char(bit_rshift(x, 8)%0x100, x%0x100))
end

--- Writes a unsigned short to the buffer and advances the buffer pointer.
-- @name ss_methods.writeUInt16
-- @class function
-- @param number x UInt16 to write
ss_methods.writeUInt16 = ss_methods.writeInt16

--- Writes an int to the buffer and advances the buffer pointer.
-- @param number x Int32 to write
function ss_methods:writeInt32(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100000000 end
	self:write(string.char(x%0x100, bit_rshift(x, 8)%0x100, bit_rshift(x, 16)%0x100, bit_rshift(x, 24)%0x100))
end
function ss_methods_big:writeInt32(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100000000 end
	self:write(string.char(bit_rshift(x, 24)%0x100, bit_rshift(x, 16)%0x100, bit_rshift(x, 8)%0x100, x%0x100))
end

--- Writes a unsigned long to the buffer and advances the buffer pointer.
-- @name ss_methods.writeUInt32
-- @class function
-- @param number x UInt32 to write
ss_methods.writeUInt32 = ss_methods.writeInt32

--- Writes a 4 byte IEEE754 float to the byte stream and advances the buffer pointer.
-- @param number x The float to write
function ss_methods:writeFloat(x)
	self:write(string.char(PackIEEE754Float(x)))
end
function ss_methods_big:writeFloat(x)
	local a,b,c,d = PackIEEE754Float(x)
	self:write(string.char(d,c,b,a))
end

--- Writes a 8 byte IEEE754 double to the byte stream and advances the buffer pointer.
-- @param number x The double to write
function ss_methods:writeDouble(x)
	self:write(string.char(PackIEEE754Double(x)))
end
function ss_methods_big:writeDouble(x)
	local a,b,c,d,e,f,g,h = PackIEEE754Double(x)
	self:write(string.char(h,g,f,e,d,c,b,a))
end

--- Writes a string to the buffer putting a null at the end and advances the buffer pointer.
-- @param string str The string of bytes to write
function ss_methods:writeString(str)
	self:write(str)
	self:write("\0")
end

--- Returns the buffer as a string
-- @return string The buffer as a string
function ss_methods:getString()
	return table.concat(self)
end
end

