--[[
	Expression 2 Permissions
	Originally Written by K4SU
	Finished by Orion
]]
AddCSLuaFile()

PIXEL = PIXEL or {}
PIXEL.E2Permissions = {}
PIXEL.E2Permissions.Whitelist = {}
PIXEL.E2Permissions.Blacklist = {}
PIXEL.E2Permissions.WhitelistOnlyFunctions = {}

function PIXEL.E2Permissions.CanInvoke(ply, name, params, meta)
    return not not hook.Run("PIXEL.E2Invoke", ply, name, params, meta) -- the !! is for boolean conversion, its just nicer
end
