--[[
	Rangerdata gates
]]

GateActions("Ranger")

GateActions["rd_trace"] = {
	name = "Trace",
	inputs = { "Startpos", "Endpos" },
	inputtypes = { "VECTOR", "VECTOR" },
	outputtypes = { "RANGER" },
	timed = true,
	output = function(gate, Startpos, Endpos)
		if !isvector(Startpos) then Startpos = Vector (0, 0, 0) end
		if !isvector(Endpos) then Endpos = Vector (0, 0, 0) end
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
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if !A then return Vector(0,0,0) end
		if A.StartSolid then return A.StartPos end
		return A.HitPos
	end,
	label = function(Out, A)
		return string.format ("hitpos(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_hitnorm"] = {
	name = "Hit Normal",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "VECTOR" },
	timed = true,
	output = function(gate, A)
		if !A then return Vector(0,0,0) end
		return A.HitNormal
	end,
	label = function(Out, A)
		return string.format ("hitnormal(%s) = (%d,%d,%d)", A, Out.x, Out.y, Out.z)
	end
}

GateActions["rd_entity"] = {
	name = "Entity",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "ENTITY" },
	timed = true,
	output = function(gate, A)
		if !A then return NULL end
		return A.Entity
	end,
	label = function(Out, A)
		return string.format ("hitentity(%s) = %s", A, tostring(Out))
	end
}

GateActions["rd_hitworld"] = {
	name = "Hit World",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		return A.HitWorld and 1 or 0
	end,
	label = function(Out, A)
		return string.format ("hitworld(%s) = %d", A, Out and 1 or 0)
	end
}

GateActions["rd_hit"] = {
	name = "Hit",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		return A.Hit and 1 or 0
	end,
	label = function(Out, A)
		return string.format ("hit(%s) = %d", A, Out and 1 or 0)
	end
}

GateActions["rd_distance"] = {
	name = "Distance",
	inputs = { "A" },
	inputtypes = { "RANGER" },
	outputtypes = { "NORMAL" },
	timed = true,
	output = function(gate, A)
		if !A then return 0 end
		if A.StartSolid then return A.StartPos:Distance(A.HitPos)*(1/(1-A.FractionLeftSolid)-1) end
		return A.StartPos:Distance(A.HitPos)
	end,
	label = function(Out, A)
		return string.format ("distance(%s) = %d", A, Out)
	end
}

GateActions()
