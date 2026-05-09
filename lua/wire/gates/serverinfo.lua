--[[
		Server Info
]]

local sv_map      = game.GetMap()
local sv_maxplayers = game.MaxPlayers()

GateActions("Server")

GateActions["sv_hostname"] = {
    name = "Hostname",
    description = "Returns the server's hostname.",
    inputs = {},
    outputtypes = { "STRING" },
    output = function(gate)
        return GetHostName()
    end,
    label = function(Out)
        return string.format("hostname = %q", Out)
    end
}

GateActions["sv_hostip"] = {
    name = "Host IP",
    description = "Returns the server's IP address.",
    inputs = {},
    outputtypes = { "STRING" },
    output = function(gate)
        return game.GetIPAddress()
    end,
    label = function(Out)
        return string.format("hostip = %q", Out)
    end
}

GateActions["sv_map"] = {
    name = "Map",
    description = "Returns the current map name.",
    inputs = {},
    outputtypes = { "STRING" },
    output = function(gate)
        return sv_map
    end,
    label = function(Out)
        return string.format("map = %q", Out)
    end
}

GateActions["sv_maxplayers"] = {
    name = "Max Players",
    description = "Returns the maximum number of players allowed on the server.",
    inputs = {},
    outputtypes = { "NORMAL" },
    output = function(gate)
        return sv_maxplayers
    end,
    label = function(Out)
        return string.format("maxPlayers = %d", Out)
    end
}

GateActions["sv_numplayers"] = {
    name = "Num Players",
    description = "Returns the current number of players on the server.",
    inputs = {},
    outputtypes = { "NORMAL" },
    timed = true,
    output = function(gate)
        return player.GetCount()
    end,
    label = function(Out)
        return string.format("numPlayers = %d", Out)
    end
}

GateActions["sv_airdensity"] = {
    name = "Air Density",
    description = "Returns the air density of the physics environment.",
    inputs = {},
    outputtypes = { "NORMAL" },
    output = function(gate)
        return physenv.GetAirDensity()
    end,
    label = function(Out)
        return string.format("airDensity = %f", Out)
    end
}


GateActions["sv_propgravity"] = {
    name = "Prop Gravity",
    description = "Returns the gravity vector of the physics environment.",
    inputs = {},
    outputtypes = { "VECTOR" },
    output = function(gate)
        return physenv.GetGravity()
    end,
    label = function(Out)
        return string.format("propGravity = (%d,%d,%d)", Out.x, Out.y, Out.z)
    end
}

GateActions["sv_tickinterval"] = {
    name = "Tick Interval",
    description = "Returns the server's tick interval in seconds.",
    inputs = {},
    outputtypes = { "NORMAL" },
    timed = true,
    output = function(gate)
        return engine.TickInterval()
    end,
    label = function(Out)
        return string.format("tickInterval = %f", Out)
    end
}

GateActions()