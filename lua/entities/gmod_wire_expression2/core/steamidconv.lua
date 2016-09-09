local util = util
local util_SteamIDFrom64 = util.SteamIDFrom64
local util_SteamIDTo64 = util.SteamIDTo64

__e2setcost(5) -- approximated

--- Given a 64bit SteamID will return a STEAM_0 style Steam ID.
e2function string steamIDFrom64(string community_id)
    return util_SteamIDFrom64(community_id)
end

--- Given a STEAM_0 style Steam ID will return a 64bit Steam ID.
e2function string steamIDTo64(string id)
    return util_SteamIDTo64(id)
end
