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
		return string.format ("hit(%s) = %d", A, Out)
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

GateActions["rd_hull_pos"] = {
    name = "Hull Trace (By Position)",
    description = "Performs a box-shaped (hull) trace between two positions and outputs ranger data. If Parent is provided, StartPos and EndPos are treated as local offsets relative to that entity.",
    inputs = { "StartPos", "EndPos", "Size", "Filter", "Parent" },
    inputtypes = { "VECTOR", "VECTOR", "VECTOR", "ARRAY", "ENTITY" },
    outputtypes = { "RANGER" },
    timed = true,
    output = function(gate, StartPos, EndPos, Size, Filter, Entity)
        if not isvector(StartPos) then StartPos = vec0 end
        if not isvector(EndPos)   then EndPos   = vec0 end
        if not isvector(Size)     then Size     = vec1 end

        if IsValid(Entity) then
            StartPos = Entity:LocalToWorld(StartPos)
            EndPos   = Entity:LocalToWorld(EndPos)
        end

        local half   = Size * 0.5
        local filter = {}
        if istable(Filter) then
            for _, v in ipairs(Filter) do
                if IsValid(v) then filter[#filter + 1] = v end
            end
        end

        if IsValid(Entity) then
            filter[#filter + 1] = Entity
        end

        local tracedata = {
            start  = StartPos,
            endpos = EndPos,
            mins   = -half,
            maxs   = half,
            filter = (#filter > 0) and filter or nil,
        }
        return util.TraceHull(tracedata)
    end,
    label = function(Out, StartPos, EndPos, Size, Filter, Entity)
        return string.format("hullTrace(%s → %s)", tostring(StartPos), tostring(EndPos))
    end
}

GateActions["rd_hull_ang"] = {
    name = "Hull Trace (By Angle)",
    description = "Performs a box-shaped (hull) trace from a start position along an angle for a set distance, and outputs ranger data. If Parent is provided, StartPos and Angle are treated as local offset and local angle relative to that entity.",
    inputs = { "StartPos", "Angle", "Distance", "Size", "Filter", "Parent" },
    inputtypes = { "VECTOR", "ANGLE", "NORMAL", "VECTOR", "ARRAY", "ENTITY" },
    outputtypes = { "RANGER" },
    timed = true,
    output = function(gate, StartPos, Angle, Distance, Size, Filter, Entity)
        if not isvector(StartPos) then StartPos = vec0 end
        if not isangle(Angle)     then Angle    = ang0 end
        if not isvector(Size)     then Size     = vec1 end
        if not Distance or Distance == 0 then Distance = 4096 end

        if IsValid(Entity) then
            StartPos = Entity:LocalToWorld(StartPos)
            Angle    = Entity:LocalToWorldAngles(Angle)
        end

        local dir    = Angle:Forward()
        local endpos = StartPos + dir * Distance
        local half   = Size * 0.5

        local filter = {}
        if istable(Filter) then
            for _, v in ipairs(Filter) do
                if IsValid(v) then filter[#filter + 1] = v end
            end
        end

        if IsValid(Entity) then
            filter[#filter + 1] = Entity
        end

        local tracedata = {
            start  = StartPos,
            endpos = endpos,
            mins   = -half,
            maxs   = half,
            filter = (#filter > 0) and filter or nil,
        }
        return util.TraceHull(tracedata)
    end,
    label = function(Out, StartPos, Angle, Distance, Size, Filter, Entity)
        return string.format("hullTrace(%s, %s, dist=%s)", tostring(StartPos), tostring(Angle), tostring(Distance))
    end
}

GateActions()
