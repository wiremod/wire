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
local usermessage = usermessage
local umsg = umsg

-- extra table functions

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

--[[ wire_umsg: self:umsg() system
	Shared requirements: WireLib.umsgRegister(self) in ENT:Initialize()
	Server requirements: ENT:Retransmit(ply)
	Client requirements: ENT:Receive(um)

	To send:
	self:umsg() -- you can pass a Player or a RecipientFilter here to only send to some clients.
		umsg.Whatever(whatever)
	umsg.End()

	To unregister: WireLib.umsgUnRegister(self)
]]
if SERVER then
	local registered_ents = {}

	hook.Add("EntityRemoved", "wire_umsg", function(ent)
		if not IsValid(ent) then return end
		if ent:IsPlayer() then
			for e,_ in pairs(registered_ents) do
				if e.wire_umsg_rp then e.wire_umsg_rp:RemovePlayer(ent) end
			end
		else
			WireLib.umsgUnRegister(ent)
		end
	end)

	local wire_umsg = table.Copy(umsg)--{} -- TODO: replace
	WireLib.wire_umsg = wire_umsg
	setmetatable(wire_umsg, wire_umsg)

	function wire_umsg:__call(ent, receiver)
		umsg.Start("wire_umsg", receiver or ent.rp)
		umsg.Short(ent:EntIndex())
	end

	function WireLib.umsgRegister(self)
		registered_ents[self] = true
		self.umsg = wire_umsg
		self.wire_umsg_rp = RecipientFilter()
	end

	function WireLib.umsgUnRegister(self)
		registered_ents[self] = nil
		self.umsg = nil
		self.wire_umsg_rp = nil
	end

	concommand.Add("wire_umsg", function(ply, cmd, args)
		local self = Entity(tonumber(args[1]))
		if !IsValid(self) or !self.wire_umsg_rp then return end
		self.wire_umsg_rp:AddPlayer(ply)
		self:Retransmit(ply)
	end)
elseif CLIENT then
	function WireLib.umsgRegister(self)
		RunConsoleCommand("wire_umsg", self:EntIndex())
	end

	usermessage.Hook("wire_umsg", function(um)
		local self = Entity(um:ReadShort())
		if IsValid(self) and self.Receive then self:Receive(um) end
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
		if not IsValid(ent) then return end
		if not ent:IsPlayer() then
			WireLib._RemoveWire(ent:EntIndex())
		end
	end)

	function WireLib._SetInputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue[#queue+1] = { eid, DELETE, INPUT }

		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_inputs[eid] = entry
			queue[#queue+1] = { eid, PORT, INPUT, entry, CurPort.Num }
		end
		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			WireLib._SetLink(CurPort, lqueue)
		end
	end

	function WireLib._SetOutputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue[#queue+1] = { eid, DELETE, OUTPUT }

		for Name, CurPort in pairs_sortvalues(ent.Outputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_outputs[eid] = entry
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
		ply = ply or rp
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
