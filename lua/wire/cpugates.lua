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

function LoadCPUGates()
	CPUGateActions = {}
	setmetatable(CPUGateActions,gamt)
	local entries = file.Find( "wire/cpu_gates/*.lua", "LUA" )
	for _,v in pairs(entries) do
		include("cpu_gates/"..v)
		if (SERVER) then AddCSLuaFile("cpu_gates/"..v) end
	end
	CPUGateActions = gates

	CPUGatesSorted = {}
	for name,gate in pairs(CPUGateActions) do
		if not CPUGatesSorted[gate.group] then
			CPUGatesSorted[gate.group] = {}
		end
		CPUGatesSorted[gate.group][name] = gate
	end
end
LoadCPUGates()