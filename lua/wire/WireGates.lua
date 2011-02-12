--[[
	Gate Loader

	Define gate behavior in gates/*.lua.
]]

local gamt
gamt = {
	curcat = "DEFAULT",
	__newindex = function(t,k,v)
		if not v.group then
			v.group = gamt.curcat
		end
		rawset(t,k,v)
	end,
	__call = function(t,s) --call the table to set a default category
		gamt.curcat = s or "DEFAULT"
	end
}

function LoadWireGates()
	GateActions = {}
	setmetatable(GateActions,gamt)
	local entries = file.FindInLua( "wire/gates/*.lua" )
	for _,v in pairs(entries) do
		include("gates/"..v)
		if (SERVER) then AddCSLuaFile("gates/"..v) end
	end

	WireGatesSorted = {}
	for name,gate in pairs(GateActions) do
		if not WireGatesSorted[gate.group] then WireGatesSorted[gate.group] = {} end
		WireGatesSorted[gate.group][name] = gate
	end
end
LoadWireGates()
