/******************************************************************************\
  Server Information
\******************************************************************************/

local dedicated = game.IsDedicated() and 1 or 0
local gamemode_name = gmod.GetGamemode().Name
local map = game.GetMap()
local maxplayers = game.MaxPlayers()
local serveruuid = WireLib.GetServerUUID()
local singleplayer = game.SinglePlayer() and 1 or 0
local tickinterval = engine.TickInterval()

E2Lib.registerConstant("DEDICATED", dedicated)
E2Lib.registerConstant("GAMEMODE", gamemode_name)
E2Lib.registerConstant("MAP", map)
E2Lib.registerConstant("MAXPLAYERS", maxplayers)
E2Lib.registerConstant("SERVERUUID", serveruuid)
E2Lib.registerConstant("SINGLEPLAYER", singleplayer)
E2Lib.registerConstant("TICKINTERVAL", tickinterval)

__e2setcost(1)

[deprecated = "Use the constant MAP instead"]
e2function string map()
	return map
end

e2function string hostname()
	return GetHostName()
end

e2function string hostip()
	return game.GetIPAddress()
end

local sv_lan = GetConVar("sv_lan")
e2function number isLan()
	return sv_lan:GetBool() and 1 or 0
end

[deprecated = "Use the constant GAMEMODE instead"]
e2function string gamemode()
	return gamemode_name
end

[deprecated = "Use the constant SERVERUUID instead"]
e2function string serverUUID()
	return serveruuid
end

[deprecated = "Use the constant SINGLEPLAYER instead"]
e2function number isSinglePlayer()
	return singleplayer
end

[deprecated = "Use the constant DEDICATED instead"]
e2function number isDedicated()
	return dedicated
end

e2function number numPlayers()
	return player.GetCount()
end

[deprecated = "Use the constant MAXPLAYERS instead"]
e2function number maxPlayers()
	return maxplayers
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

[deprecated = "Use the constant TICKINTERVAL instead"]
e2function number tickInterval()
	return tickinterval
end

e2function number tickRealInterval()
	return engine.AbsoluteFrameTime()
end
