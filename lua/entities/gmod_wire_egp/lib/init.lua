E2Lib = E2Lib or { EGP = {} }
--- The EGP library
local EGP = E2Lib.EGP
if not EGP then
	EGP = {}
	E2Lib.EGP = EGP
end

_G.EGP = EGP -- To be after refactor is done

EGP.ConVars = {
	MaxObjects = CreateConVar("wire_egp_max_objects", 300, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Maximum objects on EGP screen"),
	MaxPerSec = CreateConVar("wire_egp_max_bytes_per_sec", 10000, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Maximum amount of data to transfer for EGP updates"), -- Keep between 2500-40000
	MaxVertices = CreateConVar("wire_egp_max_poly_vertices", 1024, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }, "Maximum amount of vertices on a polygon"),
	AllowEmitter = CreateConVar("wire_egp_allow_emitter", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }, "Should EGP emitters be allowed?"),
	AllowHUD = CreateConVar("wire_egp_allow_hud", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }, "Should EGP HUDs be allowed?"),
	AllowScreen = CreateConVar("wire_egp_allow_screen", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }, "Should EGP screens be allowed?"),
}

-- Include all other files
local postinit = {}
--- Calls argument after EGP library finishes initializing. If initialization already finished, calls callback immediately.
---@param callback function
function EGP.HookPostInit(callback)
	if postinit then
		table.insert(postinit, callback)
	else
		callback()
	end
end

local FOLDER = "entities/gmod_wire_egp/lib/egplib/"
local entries = file.Find(FOLDER .. "*.lua", "LUA")

for _, entry in ipairs(entries) do
	local p = FOLDER .. entry
	if SERVER then
		AddCSLuaFile(p)
	end
	include(p)
end

-- Run PostInit callbacks
for _, v in ipairs(postinit) do
	v()
end
postinit = nil
