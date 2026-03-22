--[[
	Potato gates
]]

GateActions("Картошечка")

GateActions["potato_player_IsBuild"] = {
	name = "Is Build",
	inputs = { "Ply" },
	inputtypes = { "ENTITY" },
	output = function(gate, Ply)
		if not Ply:IsValid() or not Ply:IsPlayer() then return 0 else return Ply:IsBuild() and 1 or 0 end
	end,
	label = function(Out)
		return string.format ("IsBuild = %q", Out)
	end
}

GateActions["potato_player_IsSafe"] = {
	name = "Is In Safe Zone",
	inputs = { "Ply" },
	inputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, Ply)
		if not Ply:IsValid() or not Ply:IsPlayer() then return 0 else return SafeZones:PlayerSafe(Ply) and 1 or 0 end
	end,
	label = function(Out)
		return string.format ("Is In Safe Zone = %q", Out)
	end
}

GateActions()