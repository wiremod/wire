--[[
	Expression 2 Permissions
	Originally Written by K4SU
	Finished by Orion
]]

AddCSLuaFile()

PIXEL = PIXEL or {}
PIXEL.E2Permissions = {}
PIXEL.E2Permissions.Whitelist = {} 				-- Access to normal functions and whitelisted functions
PIXEL.E2Permissions.SuperWhitelist = {} 		-- Access to EVERY function
PIXEL.E2Permissions.Blacklist = {}				-- Cannot access any E2 function
PIXEL.E2Permissions.WhitelistedFunctions = {}	-- Functions Whitelisted people can access
PIXEL.E2Permissions.BlacklistedFunctions = {} 	-- Functions Noone Except SuperWhitelisted Users can Access

local w, sw, b, wf, bf = PIXEL.E2Permissions.Whitelist, PIXEL.E2Permissions.SuperWhitelist, PIXEL.E2Permissions.Blacklist, PIXEL.E2Permissions.WhitelistedFunctions, PIXEL.E2Permissions.BlacklistedFunctions
local t, f = true, false

function PIXEL.E2Permissions.CanInvoke(ply, name, params, meta)
    return hook.Run("PIXEL.E2Permissions.CanInvoke", ply, name, params, meta)
end

hook.Add("PIXEL.E2Permissions.CanInvoke","MainInvokeStop", function(ply, name, params, meta)
	if not IsValid(ply) then return false end
	if PIXEL.E2Permissions.SuperWhitelist[ply:SteamID64()] then return true end
	if PIXEL.E2Permissions.Blacklist[ply:SteamID64()] then return true end
	if PIXEL.E2Permissions.BlacklistedFunctions[name] then return false end
	if PIXEL.E2Permissions.WhitelistedFunctions[name] then
		return PIXEL.E2Permissions.Whitelist[ply:SteamID64()]
	end
	return true
end )

-- Filling out the tables below :)
