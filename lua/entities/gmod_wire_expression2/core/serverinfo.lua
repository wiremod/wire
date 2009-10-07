/******************************************************************************\
  Server Information
\******************************************************************************/

local ostime_arguments = {
	year = true,
	month = true,
	day = true,
	hour = true,
	min = true,
	sec = true,
	wday = true,
	yday = true,
	isdst = true
}

registerFunction("map", "", "s", function(self, args)
	return string.Replace(game.GetMap(),".bsp","")
end)

registerFunction("hostname", "", "s", function(self, args)
	if(SinglePlayer()) then return "" end
	return GetConVarString("hostname")
end)

registerFunction("isLan", "", "n", function(self, args)
	if(GetConVar("sv_lan"):GetBool()) then return 1 else return 0 end
end)

registerFunction("gamemode", "", "s", function(self, args)
	return gmod.GetGamemode().Name
end)

registerFunction("isSinglePlayer", "", "n", function(self, args)
	if(SinglePlayer()) then return 1 else return 0 end
end)

registerFunction("isDedicated", "", "n", function(self, args)
	if(SinglePlayer()) then return 0 end
	if(isDedicatedServer()) then return 1 else return 0 end
end)

registerFunction("numPlayers", "", "n", function(self, args)
	return table.Count(player.GetAll())
end)

registerFunction("maxPlayers", "", "n", function(self, args)
	return MaxPlayers()
end)

registerFunction("gravity", "", "n", function(self, args)
	return GetConVarNumber("sv_gravity")
end)

registerFunction("time", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)

	if not ostime_arguments[rv1] then return 0 end
	local ostime = os.date("!*t")
	local ret = ostime[rv1]

	if tonumber(ret) then
		return ret
	elseif ret == true then		-- Occurs if input string is "isdst"
		return 1
	else
		return 0
	end
end)
