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

function PIXEL.E2Permissions.CanInvoke(ply, name, params, meta)
    return hook.Run("PIXEL.E2Permissions.CanInvoke", ply, name, params, meta)
end

local shouldPrintCvar = CreateConVar("pixel_e2_print_invocations", "0")
local shouldPrint = shouldPrintCvar:GetBool()

function PIXEL.E2Permissions.PrintInvocations(ply, name, params, meta)
    if not shouldPrint then return end

    MsgN("E2 Invocation:")
    MsgN("      Player: ", ply:Nick())
    MsgN("      Function: ", name)
    MsgN("      Parameters: ", Either(#params >= 1, params, "N/A"))
    MsgN("      Metatable: ", Either(meta, meta, "N/A"))
end

cvars.AddChangeCallback("pixel_e2_print_invocations", function(_, _, new)
    shouldPrint = tobool(new)
end)

hook.Add("PIXEL.E2Permissions.CanInvoke", "MainInvokeStop", function(ply, name, params, meta)
	if not IsValid(ply) then return false end
	PIXEL.E2Permissions.PrintInvocations(ply, name, params, meta) 
	local stid = ply:SteamID64()
	if sw[stid] then return true end
	if b[stid] then return true end
	if bf[name] then return false end
	if wf[name] then
		return w[stid]
	end
	return true
end )



-- Filling out the tables below :)

sw["76561198009689185"] = true -- Orion

-- Sound Module
wf["soundPlay"] 			= true
wf["soundStop"] 			= true
wf["soundVolume"] 			= true
wf["soundPitch"] 			= true
wf["soundPurge"] 			= true
wf["soundDuration"] 		= true

-- Remote Module
wf["remoteSetCode"] 		= true 
wf["remoteUpload"] 			= true 

-- HTTP Module
wf["httpCanRequest"] 		= true
wf["httpClk"] 				= true
wf["httpData"] 				= true
wf["httpRequest"] 			= true
wf["httpRequestUrl"] 		= true
wf["httpSuccess"] 			= true
wf["httpUrlDecode"] 		= true
wf["httpUrlEncode"] 		= true
wf["runOnHTTP"] 			= true
