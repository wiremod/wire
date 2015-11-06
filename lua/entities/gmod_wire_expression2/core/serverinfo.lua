/******************************************************************************\
  Server Information
\******************************************************************************/

__e2setcost(1)

e2function string map()
	return game.GetMap()
end

local hostname = GetConVar("hostname")
e2function string hostname()
	return hostname:GetString()
end

local hostipnum = tonumber(GetConVar("hostip"):GetString())
local ipstructure = {}
ipstructure[1] = bit.rshift(bit.band(hostipnum, 0xFF000000), 24)
ipstructure[2] = bit.rshift(bit.band(hostipnum, 0x00FF0000), 16)
ipstructure[3] = bit.rshift(bit.band(hostipnum, 0x0000FF00), 8)
ipstructure[4] = bit.band(hostipnum, 0x000000FF)
local hostip = table.concat(ipstructure, ".")
e2function string hostip()
	return hostip
end

local sv_lan = GetConVar("sv_lan")
e2function number isLan()
	return sv_lan:GetBool() and 1 or 0
end

e2function string gamemode()
	return gmod.GetGamemode().Name
end

e2function number isSinglePlayer()
	return game.SinglePlayer() and 1 or 0
end

e2function number isDedicated()
	return game.IsDedicated() and 1 or 0
end

e2function number numPlayers()
	return #player.GetAll()
end

e2function number maxPlayers()
	return game.MaxPlayers()
end

local sv_gravity = GetConVar("sv_gravity")
e2function number gravity()
	return sv_gravity:GetFloat()
end

e2function vector propGravity()
	return physenv.GetGravity()
end

e2function number airDensity()
	return physenv.GetAirDensity()
end

e2function number maxFrictionMass()
	return physenv.GetPerformanceSettings()["MaxFrictionMass"]
end

e2function number minFrictionMass()
	return physenv.GetPerformanceSettings()["MinFrictionMass"]
end

e2function number speedLimit()
	return physenv.GetPerformanceSettings()["MaxVelocity"]
end

e2function number angSpeedLimit()
	return physenv.GetPerformanceSettings()["MaxAngularVelocity"]
end

e2function number tickInterval()
	return engine.TickInterval()
end
