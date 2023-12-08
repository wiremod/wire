--[[
	Consolidated networking library for Wiremod.
	Trivial Networking - A wrapper for sending very small net messages that don't need a whole networkstring.
]]

local Net = WireLib.Net or {}
WireLib.Net = Net

-- Trivial Networking
local SIZE = 10 -- 1023 names

local registered_handlers = {}

local update_handlers

local function msg_handler(len, ply)
	local handler = registered_handlers[net.ReadUInt(SIZE)]
	if handler then
		handler(len, ply)
	else
		error("WireLib.Net tried to receive message that is not registered.")
	end
end

net.Receive("wirelib_net_message", msg_handler)

if SERVER then
	util.AddNetworkString("wirelib_net_message")

	local handler_queue = {}
	local queue_handler_firstidx, queue_handler_lastidx

	local function queue_handler_flush(ply)
		local restart, lastidx = false, queue_handler_lastidx
		if queue_handler_firstidx then
			net.Start("wirelib_net_message")

				local data, len = "", 0
				for i, v in ipairs(handler_queue) do
					len = len + #v + 1
					data = data .. v .. "\0"
					if len > 2048 then
						lastidx = i
						restart = true
						break
					end
				end

				net.WriteUInt(0, SIZE)
				net.WriteUInt(queue_handler_firstidx, SIZE)
				net.WriteUInt(lastidx, SIZE)

				data = util.Compress(data)
				local datalen = #data
				net.WriteUInt(datalen, 16)
				net.WriteData(data, datalen)

			if ply then net.Send(ply) else net.Broadcast() end
		end

		if restart and queue_handler_firstidx < queue_handler_lastidx then
			queue_handler_firstidx = lastidx + 1
			timer.Create("wirelib_net_flush", 0, 2, queue_handler_flush)
		else
			handler_queue = {}
			queue_handler_firstidx, queue_handler_lastidx = nil, nil
			timer.Remove("wirelib_net_flush")
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

				timer.Adjust("wirelib_net_flush", 1, 2)
			end

		else
			queue_handler_firstidx, queue_handler_lastidx = idx, idx
			handler_queue[1] = name

			timer.Create("wirelib_net_flush", 1, 2, queue_handler_flush)
		end
	end

	local function nohandler()
		error("WireLib.Net trying to call unimplemented handler on server")
	end

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
	end
	registered_handlers[0] = function(_, ply)
		error(string.format("WireLib.Net received invalid message from %s (Player %d, Entity %d)", ply:SteamID(), ply:UserID(), ply:EntIndex()))
	end

	--- Starts a trivial net message within a normal Gmod net context.
	--- Use net functions normally after this.
	---@param name string
	---@param unreliable boolean?
	function Net.Start(name, unreliable)
		name = name:lower()
		local idx = registered_handlers[name]
		if not idx then
			if SERVER then
				update_handlers(name, nohandler)
				queue_handler_flush() -- Force flush in case the client doesn't have this particular name
				idx = registered_handlers[name]
			else
				error("WireLib.Net trying to send message on client that isn't registered.")
			end
		end
		net.Start("wirelib_net_message", unreliable)
		net.WriteUInt(idx, SIZE)
	end

	--- Receives a trivial net message.
	--- Use net functions normally in the callback.
	---@param name string
	---@param callback fun(len:string, ply:Player)
	function Net.Receive(name, callback)
		update_handlers(name:lower(), callback)
	end

else
	update_handlers = function(name, callback)
		local handler_idx = registered_handlers[name]
		if not handler_idx then
			registered_handlers[name] = callback
		else
			registered_handlers[handler_idx] = callback
		end
	end

	local function internal_update()
		local begin = net.ReadUInt(SIZE)
		local last = net.ReadUInt(SIZE)
		local data = util.Decompress(net.ReadData(net.ReadUInt(16)))

		local charstart, charend = 1, 0
		for i = begin, last do
			charend = string.find(data, "\0", charstart, true)
			local name = string.sub(data, charstart, charend - 1)
			registered_handlers[i] = registered_handlers[name] -- This is hacky but it works
			registered_handlers[name] = i
			charstart = charend + 1
		end
	end

	registered_handlers[0] = internal_update

	--- Starts a trivial net message within a normal Gmod net context.
	--- Use net functions normally after this.
	---@param name string
	---@param unreliable boolean?
	function Net.Start(name, unreliable)
		name = name:lower()
		local idx = registered_handlers[name]
		if not idx then
			error("WireLib.Net trying to send message on client that isn't registered.")
		end
		net.Start("wirelib_net_message", unreliable)
		net.WriteUInt(idx, SIZE)
	end
end

--- Receives a trivial net message.
--- Use net functions normally in the callback.
---@param name string
---@param callback fun(len:string, ply:Player)
function Net.Receive(name, callback)
	update_handlers(name:lower(), callback)
end

function Net.Receivers()
	return registered_handlers
end