/******************************************************************************\
  Server Information
\******************************************************************************/

E2Lib.registerConstant("DEDICATED", game.IsDedicated() and 1 or 0)
E2Lib.registerConstant("GAMEMODE", gmod.GetGamemode().Name)
E2Lib.registerConstant("MAP", game.GetMap())
E2Lib.registerConstant("MAXPLAYERS", game.MaxPlayers())
E2Lib.registerConstant("SERVERUUID", WireLib.GetServerUUID())
E2Lib.registerConstant("SINGLEPLAYER", game.SinglePlayer() and 1 or 0)
E2Lib.registerConstant("TICKINTERVAL", engine.TickInterval())

__e2setcost(1)

[deprecated = "Use the constant MAP instead"]
e2function string map()
	return game.GetMap()
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
	return gmod.GetGamemode().Name
end

[deprecated = "Use the constant SERVERUUID instead"]
e2function string serverUUID()
	return WireLib.GetServerUUID()
end

[deprecated = "Use the constant SINGLEPLAYER instead"]
e2function number isSinglePlayer()
	return game.SinglePlayer() and 1 or 0
end

[deprecated = "Use the constant DEDICATED instead"]
e2function number isDedicated()
	return game.IsDedicated() and 1 or 0
end

e2function number numPlayers()
	return player.GetCount()
end

[deprecated = "Use the constant MAXPLAYERS instead"]
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

[deprecated = "Use the constant TICKINTERVAL instead"]
e2function number tickInterval()
	return engine.TickInterval()
end

e2function number tickRealInterval()
	return engine.AbsoluteFrameTime()
end
