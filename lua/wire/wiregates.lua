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

			-- Create limit specific to each gate group (and language.add it)
			local gr = string.lower(gate.group)
			CreateConVar("sbox_maxwire_gate_" .. gr .. "s", 30 )
			if CLIENT then language.Add( "sboxlimit_wire_gate_" .. gr .. "s", "You've hit your " .. gr .. " gates limit!" ) end
		end
		WireGatesSorted[gate.group][name] = gate
	end

	-- Create gate limit
	CreateConVar("sbox_maxwire_gates",30)

end
LoadWireGates()
