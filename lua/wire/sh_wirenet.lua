--[[
	Consolidated networking library for Wiremod.
	Trivial Networking - A wrapper for sending very small net messages that don't need a whole networkstring.
]]

local Net = WireLib.Net or {}
WireLib.Net = Net

-- Trivial Networking

if SERVER then
	util.AddNetworkString("wirelib_net_message")
end

local registered_handlers = {}

local function msg_handler(len, ply)
	local handler = registered_handlers[net.ReadString()]
	if handler then
		handler(len, ply)
	else
		error("WireLib.Net tried to receive message that is not registered.")
	end
end

net.Receive("wirelib_net_message", msg_handler)

--- Starts a trivial net message within a normal Gmod net context.
--- Use net functions normally after this. <br>
--- WARNING: the entire name string is networked to identify the message. Keep it simple. Names are case insensitive.
---@param name string
---@param unreliable boolean?
function Net.Start(name, unreliable)
	name = name:lower()
	net.Start("wirelib_net_message", unreliable)
	net.WriteString(name)
end

--- Receives a trivial net message.
--- Use net functions normally in the callback.
---@param name string
---@param callback fun(len:string, ply:Player)
function Net.Receive(name, callback)
	registered_handlers[name:lower()] = callback
end