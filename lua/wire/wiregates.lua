--[[
	Gate Loader

	Define gate behavior in gates/*.lua.
]]

-- This separate table makes __newindex get called every time a gate is added, even if that gate was already added previously
-- This fixes the bug where duplicate gate entries would cause an error
local gates = {}

local gamt
gamt = {
	curcat = "DEFAULT",
	__newindex = function(t,k,v)
		if not v.group then
			v.group = gamt.curcat
		end
		rawset(gates,k,v)
	end,
	__index = function(t,k)
		return rawget(gates,k)
	end,
	__call = function(t,s) --call the table to set a default category
		gamt.curcat = s or "DEFAULT"
	end
}

function LoadWireGates()
	GateActions = {}
	setmetatable(GateActions,gamt)
	local entries = file.Find( "wire/gates/*.lua", "LUA" )
	for _,v in pairs(entries) do
		include("gates/"..v)
		if (SERVER) then AddCSLuaFile("gates/"..v) end
	end
	GateActions = gates

	WireGatesSorted = {}
	for name,gate in pairs(GateActions) do
		if not WireGatesSorted[gate.group] then
			WireGatesSorted[gate.group] = {}
		end
		WireGatesSorted[gate.group][name] = gate
	end
end
LoadWireGates()

local banned_categories_convar = CreateConVar("wire_banned_gate_categories", "", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "For multiple categories, separate them with commas. If you change this, existing gates won't be affected.")
local function UpdateBannedGates(reload_spawnmenu)
	local as_list = string.Explode(",", banned_categories_convar:GetString())
	for _,v in pairs(GateActions) do
		v.is_banned = table.HasValue(as_list, v.group)
	end
	if CLIENT and reload_spawnmenu then RunConsoleCommand("spawnmenu_reload") end
end
cvars.AddChangeCallback("wire_banned_gate_categories", function() UpdateBannedGates(true) end, "UpdateBannedGates")
UpdateBannedGates(false)
