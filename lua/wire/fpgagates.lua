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

function LoadFPGAGates()
	FPGAGateActions = {}
	setmetatable(FPGAGateActions,gamt)
	local entries = file.Find( "wire/fpga_gates/*.lua", "LUA" )
	for _,v in pairs(entries) do
		include("fpga_gates/"..v)
		if (SERVER) then AddCSLuaFile("fpga_gates/"..v) end
	end
	FPGAGateActions = gates

	FPGAGatesSorted = {}
	for name,gate in pairs(FPGAGateActions) do
		if not FPGAGatesSorted[gate.group] then
			FPGAGatesSorted[gate.group] = {}
		end
		FPGAGatesSorted[gate.group][name] = gate
	end
end
LoadFPGAGates()