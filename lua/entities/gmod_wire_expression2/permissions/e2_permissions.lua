--[[
	Expression 2 Permissions
	Originally Written by K4SU
	Finished by Orion
]]

AddCSLuaFile()

PIXEL = PIXEL or {}
PIXEL.E2Permissions = PIXEL.E2Permissions or {
	Whitelist = {}, 			-- Access to normal functions and whitelisted functions
	SuperWhitelist = {},		-- Access to EVERY function
	Blacklist = {},				-- Cannot access any E2 function
	WhitelistedFunctions = {},	-- Functions Whitelisted people can access
	BlacklistedFunctions = {} 	-- Functions Noone Except SuperWhitelisted Users can Access
}

local w, sw, b, wf, bf = PIXEL.E2Permissions.Whitelist, PIXEL.E2Permissions.SuperWhitelist, PIXEL.E2Permissions.Blacklist, PIXEL.E2Permissions.WhitelistedFunctions, PIXEL.E2Permissions.BlacklistedFunctions
local t, f = true, false

function PIXEL.E2Permissions.CanInvoke(ply, name, params, meta)
    return hook.Run("PIXEL.E2Permissions.CanInvoke", ply, name, params, meta)
end

hook.Add("PIXEL.E2Permissions.CanInvoke", "MainInvokeStop", function(ply, name, params, meta)
	if not IsValid(ply) then return f end
	local stid = ply:SteamID64()
	if sw[stid] then return t end
	if b[stid] then return t end
	if bf[name] then return f end
	if wf[name] then
		return w[stid]
	end
	return t
end )

-- Filling out the tables below :)
