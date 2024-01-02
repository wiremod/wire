--[[
	Rangerdata gates
]]

GateActions("Ranger")

GateActions["rd_trace"] = {
	name = "Trace",
	description = "Traces a line between two positions and outputs a ranger data.",
	inputs = { "Startpos", "Endpos" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "RANGER" },
	timed = true,
	output = function(gate, Startpos, Endpos)
		if not isvector(Startpos) then Startpos = Vector (0, 0, 0) end
		if not isvector(Endpos) then Endpos = Vector (0, 0, 0) end
		local tracedata = {}
		tracedata.start = Startpos
		tracedata.endpos = Endpos
		return util.TraceLine(tracedata)
	end,
	label = function(Out, Startpos, Endpos)
		return string.format ("trace(%s , %s)", Startpos, Endpos)
	end
}

GateActions["rd_hitpos"] = {
	name = "Hit Position",
	description = "Outputs the hit position of the ranger.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if not A then return Vector(0,0,0) end
		if A.StartSolid then return A.StartPos end
		return A.HitPos
	end,
	label = function(Out, A)
		return string.format ("hitpos(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_hitnorm"] = {
	name = "Hit Normal",
	description = "Outputs the direction of the hit surface.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if not A then return Vector(0,0,0) end
		return A.HitNormal
	end,
	label = function(Out, A)
		return string.format ("hitnormal(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_entity"] = {
	name = "Entity",
	description = "Outputs the entity that the ranger hit, if it did.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, A)
		if not A then return NULL end
		return A.Entity
	end,
	label = function(Out, A)
		return string.format ("hitentity(%s) = %s", A, tostring(Out))
	end
}

GateActions["rd_hitworld"] = {
	name = "Hit World",
	description = "Outputs 1 if the ranger hit the world.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if not A then return 0 end
		return A.HitWorld and 1 or 0
	end,
	label = function(Out, A)
		return string.format ("hitworld(%s) = %d", A, Out and 1 or 0)
	end
}

GateActions["rd_hit"] = {
	name = "Hit",
	description = "Outputs 1 if the ranger hit anything.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if not A then return 0 end
		return A.Hit and 1 or 0
	end,
	label = function(Out, A)
		return string.format ("hit(%s) = %d", A, Out and 1 or 0)
	end
}

GateActions["rd_distance"] = {
	name = "Distance",
	description = "Outputs the distance of the ranger hit.",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if not A then return 0 end
		if A.StartSolid then return A.StartPos:Distance(A.HitPos)*(1/(1-A.FractionLeftSolid)-1) end
		return A.StartPos:Distance(A.HitPos)
	end,
	label = function(Out, A)
		return string.format ("distance(%s) = %d", A, Out)
	end
}

GateActions()
