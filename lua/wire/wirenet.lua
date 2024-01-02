--[[
	Consolidated networking library for Wiremod.
	Trivial Networking - A wrapper for sending very small net messages that don't need a whole networkstring.
]]

local Net = WireLib.Net or {}
WireLib.Net = Net

-- Trivial Networking
Net.Trivial = {}
local SIZE = 10 -- 1023 names

local registered_handlers = {}

local update_handlers

local function msg_handler(len, ply)
	local handler = registered_handlers[net.ReadUInt(SIZE)]
	if handler then
		handler(len, ply)
	else
		error("WireLib.Net.Trivial tried to receive message that is not registered.")
	end
end

net.Receive("wirelib_net_message", msg_handler)

if SERVER then
	util.AddNetworkString("wirelib_net_message")

	local handler_names = {}
	local handler_queue = {}
	local queue_handler_firstidx, queue_handler_lastidx
	local function queue_handler_flush(ply, tbl, first, last)
		tbl = tbl or handler_queue
		first = first or queue_handler_firstidx
		last = last or queue_handler_lastidx

		if first and first <= last then
			net.Start("wirelib_net_message")
				net.WriteUInt(0, SIZE)
				net.WriteUInt(first, SIZE)
				net.WriteUInt(last, SIZE)

				for _, v in ipairs(tbl) do
					net.WriteUInt(#v, 8)
				end

				local data = table.concat(tbl)

				if #data < 4096 then
					data = util.Compress(data)
					net.WriteBool(false)
					net.WriteUInt(#data, 12)
					net.WriteData(data)
				else
					net.WriteBool(true)
					net.WriteStream(data, nil, false)
				end
			if ply then net.Send(ply) else net.Broadcast() end

			if tbl == handler_queue then queue_handler_firstidx, queue_handler_lastidx, handler_queue = nil, nil, {} end
		end
	end
	local function queue_handler_update(idx, name)
		if queue_handler_firstidx then
			if queue_handler_lastidx + 1 == idx then
				handler_queue[#handler_queue + 1] = name
				queue_handler_lastidx = idx
			else
				queue_handler_flush()

				queue_handler_firstidx, queue_handler_lastidx = idx, idx
				handler_queue[1] = name

				timer.Create("wirelib_net_flush", 0, 1, queue_handler_flush)
			end

		else
			queue_handler_firstidx, queue_handler_lastidx = idx, idx
			handler_queue[1] = name

			timer.Create("wirelib_net_flush", 0, 1, queue_handler_flush)
		end
	end

	local function nohandler()
		error("WireLib.Net.Trivial trying to call unimplemented handler on server")
	end

	---@param name string
	update_handlers = function(name, callback)
		local handler_idx = registered_handlers[name]
		if not handler_idx then
			local num_handlers = #registered_handlers
			if num_handlers > (2 ^ SIZE) - 1 then
				ErrorNoHalt("WireLib.Net is at maximum number of handlers")
			else
				num_handlers = num_handlers + 1
			end
			registered_handlers[name] = num_handlers
			registered_handlers[num_handlers] = callback
			handler_idx = num_handlers

			queue_handler_update(handler_idx, name)
		else
			registered_handlers[handler_idx] = callback
		end
		handler_names[handler_idx] = name
	end
	registered_handlers[0] = function(_, ply)
		error(string.format("WireLib.Net.Trivial received invalid message from %s (Player %d, Entity %d)", ply:SteamID(), ply:UserID(), ply:EntIndex()))
	end

	--- Starts a trivial net message within a normal Gmod net context.
	--- Use net functions normally after this.
	---@param name string
	---@param unreliable boolean?
	function Net.Trivial.Start(name, unreliable)
		name = name:lower()
		local idx = registered_handlers[name]
		if not idx then
			update_handlers(name, nohandler)
			queue_handler_flush() -- Force flush in case the client doesn't have this particular name
			idx = registered_handlers[name]
		end
		net.Start("wirelib_net_message", unreliable)
		net.WriteUInt(idx, SIZE)
	end

	--- Receives a trivial net message.
	--- Use net functions normally in the callback.
	---@param name string
	---@param callback fun(len:string, ply:Player)
	function Net.Trivial.Receive(name, callback)
		update_handlers(name:lower(), callback)
	end

	gameevent.Listen("player_activate")

	hook.Add("player_activate", "wirenet_ff_player", function(d)
		queue_handler_flush(Player(d.userid), handler_names, 1, #handler_names)
	end)
else -- CLIENT
	update_handlers = function(name, callback)
		local handler_idx = registered_handlers[name]
		if not handler_idx then
			registered_handlers[name] = callback
		else
			registered_handlers[handler_idx] = callback
		end
	end

	local function stripstrings(begin, last, lens, str)
		local lenIndex, lastIndex = 1, 1
		for i = begin, last do
			local len = lens[lenIndex]
			local name = string.sub(str, lastIndex, lastIndex + len - 1)
			registered_handlers[i] = registered_handlers[name] -- This is hacky but it works
			registered_handlers[name] = i
			lenIndex = lenIndex + 1
			lastIndex = lastIndex + len
		end
	end

	local function internal_update()
		local begin = net.ReadUInt(SIZE)
		local last = net.ReadUInt(SIZE)

		local lens = {}

		for i = 1, last - begin + 1 do
			lens[i] = net.ReadUInt(8)
		end

		if net.ReadBool() then
			net.ReadStream(nil, function(data)
				stripstrings(begin, last, lens, data)
			end)
		else
			stripstrings(begin, last, lens, util.Decompress(net.ReadData(net.ReadUInt(12))))
		end
	end

	registered_handlers[0] = internal_update

	--- Starts a trivial net message within a normal Gmod net context.
	--- Use net functions normally after this.
	---@param name string
	---@param unreliable boolean?
	function Net.Trivial.Start(name, unreliable)
		name = name:lower()
		local idx = registered_handlers[name]
		if not idx then
			error("WireLib.Net.Trivial trying to send message on client that isn't registered.")
		end
		net.Start("wirelib_net_message", unreliable)
		net.WriteUInt(idx, SIZE)
	end
end

--- Receives a trivial net message.
--- Use net functions normally in the callback.
---@param name string
---@param callback fun(len:string, ply:Player)
function Net.Trivial.Receive(name, callback)
	update_handlers(name:lower(), callback)
end

Net.Receivers = registered_handlers