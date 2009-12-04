/******************************************************************************\
  Server Information
\******************************************************************************/

e2function string map()
	return game.GetMap()
end

local hostname = GetConVar("hostname")
e2function string hostname()
	return hostname:GetString()
end

local sv_lan = GetConVar("sv_lan")
e2function number isLan()
	return sv_lan:GetBool() and 1 or 0
end

e2function string gamemode()
	return gmod.GetGamemode().Name
end

e2function number isSinglePlayer()
	return SinglePlayer() and 1 or 0
end

e2function number isDedicated()
	return isDedicatedServer() and 1 or 0
end

e2function number numPlayers()
	return #player.GetAll()
end

e2function number maxPlayers()
	return MaxPlayers()
end

local sv_gravity = GetConVar("sv_gravity")
e2function number gravity()
	return sv_gravity:GetFloat()
end

e2function number time(string component)
	local ostime = os.date("!*t")
	local ret = ostime[component]

	return tonumber(ret) or ret and 1 or 0 -- the later parts account for invalid components and isdst
end
