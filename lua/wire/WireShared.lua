-- $Rev: 1781 $
-- $LastChangedDate: 2009-10-05 04:19:53 -0700 (Mon, 05 Oct 2009) $
-- $LastChangedBy: TomyLobo $

WireLib = WireLib or {}

-- extra table functions

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
			if type(ply) == "string" then
				Message, Type, Duration, Sound = ply, Message, Type, Duration
			elseif ply ~= LocalPlayer() then
				return
			end
			GAMEMODE:AddNotify(Message, Type, Duration)
			if Sound and sounds[Sound] then surface.PlaySound(sounds[Sound]) end
		end

		usermessage.Hook("wire_addnotify", function(um)
			local Message = um:ReadString()
			local Type = um:ReadChar()
			local Duration = um:ReadFloat()
			local Sound = um:ReadChar()

			WireLib.AddNotify(LocalPlayer(), Message, Type, Duration, Sound)
		end)

	elseif SERVER then

		NOTIFY_GENERIC = 0
		NOTIFY_ERROR = 1
		NOTIFY_UNDO = 2
		NOTIFY_HINT = 3
		NOTIFY_CLEANUP = 4

		function WireLib.AddNotify(ply, Message, Type, Duration, Sound)
			if type(ply) == "string" then ply, Message, Type, Duration, Sound = nil, ply, Message, Type, Duration end
			umsg.Start("wire_addnotify", ply)
				umsg.String(Message)
				umsg.Char(Type)
				umsg.Float(Duration)
				umsg.Char(Sound or 0)
			umsg.End()
		end

	end
end -- wire_addnotify

--[[ wire_clienterror: displays Lua errors on the client
	Usage: WireLib.ClientError("Hello", ply)
]]
if CLIENT then
	usermessage.Hook("wire_clienterror", function(um)
		local message = um:ReadString()
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
	function WireLib.ClientError(message, player)
		umsg.Start("wire_clienterror", player)
			umsg.String(message)
		umsg.End()
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
]]
if SERVER then

	local registered_ents = {}

	hook.Add("EntityRemoved", "wire_umsg", function(ent)
		if not ent:IsValid() then return end
		if ent:IsPlayer() then
			for e,_ in pairs(registered_ents) do
				if e.wire_umsg_rp then e.wire_umsg_rp:RemovePlayer(ent) end
			end
		else
			registered_ents[ent] = nil
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

	concommand.Add("wire_umsg", function(ply, cmd, args)
		local self = Entity(tonumber(args[1]))
		if !self:IsValid() or !self.wire_umsg_rp then return end
		self.wire_umsg_rp:AddPlayer(ply)
		self:Retransmit(ply)
	end)

elseif CLIENT then

	function WireLib.umsgRegister(self)
		RunConsoleCommand("wire_umsg", self:EntIndex())
	end

	usermessage.Hook("wire_umsg", function(um)
		local self = Entity(um:ReadShort())
		if self:IsValid() and self.Receive then self:Receive(um) end
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

if SERVER then
	local INPUT,OUTPUT = 1,-1
	local DELETE,PORT,LINK = 1,2,3

	local ents_with_inputs = {}
	local ents_with_outputs = {}
	--local IOlookup = { [INPUT] = ents_with_inputs, [OUTPUT] = ents_with_outputs }

	local queue = WireLib.containers.deque:new()
	local rp = RecipientFilter()

	hook.Add("EntityRemoved", "wire_ports", function(ent)
		if not ent:IsValid() then return end
		if ent:IsPlayer() then
			rp:RemovePlayer(ent)
		else
			local eid = ent:EntIndex()
			local hasinputs, hasoutputs = ents_with_inputs[eid], ents_with_outputs[eid]
			if hasinputs or hasoutputs then
				ents_with_inputs[eid] = nil
				ents_with_outputs[eid] = nil
				umsg.Start("wire_ports", rp)
					umsg.Char(-3) -- set eid
					umsg.Short(eid)
					if hasinputs then umsg.Char(-1) end
					if hasoutputs then umsg.Char(-2) end
					umsg.Char(0) -- break
				umsg.End()
			end
		end
	end)

	function WireLib._SetInputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue:push({ eid, DELETE, INPUT })

		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_inputs[eid] = entry
			queue:push({ eid, PORT, INPUT, entry, CurPort.Num })
		end
		for Name, CurPort in pairs_sortvalues(ent.Inputs, WireLib.PortComparator) do
			WireLib._SetLink(CurPort, lqueue)
		end
	end

	function WireLib._SetOutputs(ent, lqueue)
		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue:push({ eid, DELETE, OUTPUT })

		for Name, CurPort in pairs_sortvalues(ent.Outputs, WireLib.PortComparator) do
			local entry = { Name, CurPort.Type, CurPort.Desc or "" }
			ents_with_outputs[eid] = entry
			queue:push({ eid, PORT, OUTPUT, entry, CurPort.Num })
		end
	end

	function WireLib._SetLink(input, lqueue)
		local ent = input.Entity
		local num = input.Num
		local state = input.SrcId and true or false

		local queue = lqueue or queue
		local eid = ent:EntIndex()

		queue:push({eid, LINK, num, state})
	end

	local function FlushQueue(lqueue, ply)
		ply = ply or rp
		local eid = 0
		local ports_msg = nil
		local function parsemsg(msg)
			local same_eid = msg[1] == eid
			local bytes, ret
			if same_eid then
				bytes = 0
				ret = {}
			else
				eid = msg[1]
				bytes = 3
				ret = { { umsg.Char, -3 }, { umsg.Short, eid } }
				ports_msg = nil
			end

			local msgtype = msg[2]

			if msgtype == DELETE then
				ports_msg = nil
				bytes = bytes + 1
				table.insert(ret, { umsg.Char, msg[3] == INPUT and -1 or -2 })

			elseif msgtype == PORT then
				local _,_,IO,entry,num = unpack(msg)

				if not ports_msg then
					bytes = bytes + 2
					table.insert(ret, { umsg.Char, num })
					ports_msg = { umsg.Char, 0 }
					table.insert(ret, ports_msg)
				end

				ports_msg[2] = ports_msg[2]+IO

				bytes = bytes + #entry[1] + #entry[2] + #entry[3]+3
				table.insert(ret, { umsg.String, entry[1] })
				table.insert(ret, { umsg.String, entry[2] })
				table.insert(ret, { umsg.String, entry[3] })

			elseif msgtype == LINK then
				local _,_,num,state = unpack(msg)
				bytes = bytes + 3
				table.insert(ret, { umsg.Char, -4 })
				table.insert(ret, { umsg.Char, num })
				table.insert(ret, { umsg.Bool, state })
			end
			return bytes, ret
		end

		umsg.Start("wire_ports", ply or rp)
		local maxsize = 240
		local bytes = 0
		local msgs = {}
		while lqueue:size()>0 do
			local msg = lqueue:bottom()
			local size,contents = parsemsg(msg)
			bytes = bytes+size
			if bytes>maxsize then break end

			table.insert(msgs, contents)
			lqueue:shift()
		end
		for _,contents in ipairs(msgs) do
			for _,func,value in ipairs_map(contents,unpack) do
				func(value)
			end
		end
		umsg.Char(0)
		umsg.End()

		if lqueue:size() == 0 then return end
		return FlushQueue(lqueue, ply)
	end

	hook.Add("Think", "wire_ports", function()
		if queue:size() == 0 then return end
		return FlushQueue(queue)
	end)

	hook.Add("PlayerInitialSpawn", "wire_ports", function(ply)
		rp:AddPlayer(ply)
		local lqueue = WireLib.containers.deque:new()
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

	usermessage.Hook("wire_ports", function(um)
		local eid = 0

		while not (function()
			local start = um:ReadChar()
			if start == 0 then
				-- break
				return true
			elseif start == -1 then
				-- delete input entry
				ents_with_inputs[eid] = nil
				return false
			elseif start == -2 then
				-- delete output entry
				ents_with_outputs[eid] = nil
				return false
			elseif start == -3 then
				-- set eid
				eid = um:ReadShort()
				return false
			elseif start == -4 then
				-- connection state
				local num = um:ReadChar()
				local state = um:ReadBool()

				local entry = ents_with_inputs[eid]
				if not entry then
					entry = {}
					ents_with_inputs[eid] = entry
				end

				if not entry[num] then return false end
				entry[num][4] = state

				return false
			elseif start > 0 then
				local entry

				local amount = um:ReadChar()
				if amount < 0 then
					-- outputs
					amount = -amount
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

				local endindex = start+amount-1
				for i = start,endindex do
					local name = um:ReadString()
					local tp = um:ReadString()
					local desc = um:ReadString()

					entry[i] = { name, tp, desc }
				end

				return false
			end

		end)() do end
	end)

	function WireLib.GetPorts(ent)
		local eid = ent:EntIndex()
		return ents_with_inputs[eid], ents_with_outputs[eid]
	end

	local flag = false
	function WireLib.TestPorts()
		flag = not flag
		if flag then
			local lasteid = 0
			hook.Add("HUDPaint", "wire_ports_test", function()
				local ent = LocalPlayer():GetEyeTraceNoCursor().Entity
				--if not ent:IsValid() then return end
				local eid = ent:IsValid() and ent:EntIndex() or lasteid
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
