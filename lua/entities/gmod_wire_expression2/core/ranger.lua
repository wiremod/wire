/******************************************************************************\
  Expression 2 built-in ranger/tracing extension
\******************************************************************************/

E2Lib.RegisterExtension("ranger", true)

-------------------
-- Main function --
-------------------

local function ResetRanger(self)
	local data = self.data
	data.rangerdefaultzero = false
	data.rangerignoreworld = false
	data.rangerwater = false
	data.rangerentities = true
	data.rangerfilter = { self.entity }
end

local function ranger(self, rangertype, range, p1, p2, hulltype, mins, maxs )
	local data = self.data
	local chip = self.entity

	local defaultzero = data.rangerdefaultzero
	local ignoreworld = data.rangerignoreworld
	local water = data.rangerwater
	local entities = data.rangerentities
	local filter = data.rangerfilter

	if not data.rangerpersist then ResetRanger(self) end

	-- begin building tracedata structure
	local tracedata = { filter = filter }
	if water then
		if entities then
			--(i)we
			tracedata.mask = -1
		elseif ignoreworld then
			--iw
			tracedata.mask = MASK_WATER
			ignoreworld = false
		else
			--w
			tracedata.mask = MASK_WATER | CONTENTS_SOLID
		end
	elseif not entities then
		if ignoreworld then
			--i
			tracedata.mask = 0
			ignoreworld = false
		else
			--no flags
			tracedata.mask = MASK_NPCWORLDSTATIC
		end
	--else
		--(i)e
	end

	-- calculate startpos and endpos
	if rangertype == 2 then
		tracedata.start = Vector( p1[1], p1[2], p1[3] )
		tracedata.endpos = Vector( p2[1], p2[2], p2[3] )
	elseif rangertype == 3 then
		tracedata.start = Vector( p1[1], p1[2], p1[3] )
		tracedata.endpos = tracedata.start + Vector( p2[1], p2[2], p2[3] ):Normalize()*range
	else
		tracedata.start = chip:GetPos()

		if rangertype == 1 && (p1!=0 || p2!=0) then
			p1 = math.rad(p1)
			p2 = math.rad(p2+270)
			local zoff = -math.cos(p1)*range
			local yoff = math.sin(p1)*range
			local xoff = math.cos(p2)*zoff
			zoff = math.sin(p2)*zoff
			tracedata.endpos = chip:LocalToWorld(Vector(xoff,yoff,zoff))
		elseif rangertype == 0 && (p1!=0 || p2!=0) then
			local skew = Vector(p2, -p1, 1)
			tracedata.endpos = chip:LocalToWorld(skew:Normalize()*range)
		else
			tracedata.endpos = tracedata.start + chip:GetUp()*range
		end
	end

	---------------------------------------------------------------------------------------
	local trace
	if (hulltype) then
		if (hulltype == 1) then
			local s = Vector(mins[1], mins[2], mins[3])
			tracedata.mins = s/2*-1
			tracedata.maxs = s/2
		elseif (hulltype == 2) then
			local s1 = Vector(mins[1], mins[2], mins[3])
			local s2 = Vector(maxs[1], maxs[2], maxs[3])
			tracedata.mins = s1
			tracedata.maxs = s2
		end

		trace = util.TraceHull( tracedata )
	else
		trace = util.TraceLine( tracedata )
	end
	---------------------------------------------------------------------------------------

	-- handle some ranger settings
	if ignoreworld and trace.HitWorld then
		trace.HitPos = defaultzero and tracedata.start or tracedata.endpos
		trace.Hit = false
	elseif defaultzero and not trace.Hit then
		trace.HitPos = tracedata.start
	end

	return trace
end

/******************************************************************************/

registerType("ranger", "xrd", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if type(retval) ~= "table" then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "table" or not v.HitPos
	end
)

/******************************************************************************/

__e2setcost(1) -- temporary

--- RD = RD
e2function ranger operator=(ranger lhs, ranger rhs)
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

e2function number operator_is(ranger walker)
	if walker then return 1 else return 0 end
end

/******************************************************************************/

__e2setcost(1) -- temporary

--- Passing 0 (the default) resets all ranger flags and filters every execution and after calling ranger/rangerOffset. Passing anything else will make the flags and filters persist until they're changed again.
e2function void rangerPersist(persist)
	self.data.rangerpersist = persist ~= 0
end

--- Resets all ranger flags and filters.
e2function void rangerReset()
	ResetRanger(self)
end

local flaglookup = {
	i = "rangerignoreworld",
	w = "rangerwater",
	e = "rangerentities",
	z = "rangerdefaultzero",
}

--- Returns the ranger flags as a string.
e2function string rangerFlags()
	local ret = ""
	for char,field in pairs(flaglookup) do
		if self.data[field] then ret = ret .. char end
	end
	return ret
end

--- Sets the ranger flags. <flags> can be any combination of I=ignore world, W=hit water, E=hit entities and Z=default to zero.
e2function void rangerFlags(string flags)
	flags = flags:lower()
	for char,field in pairs(flaglookup) do
		self.data[field] = flags:find(char) and true or false
	end
end

--- Default is 0, if any other value is given it will hit water
e2function void rangerHitWater(hitwater)
	self.data.rangerwater = hitwater ~= 0
end

--- Default is 1, if any other value is given it will hit entities
e2function void rangerHitEntities(hitentities)
	self.data.rangerentities = hitentities ~= 0
end

--- Default is 0, if any other value is given it will ignore world
e2function void rangerIgnoreWorld(ignoreworld)
	self.data.rangerignoreworld = ignoreworld ~= 0
end

--- If given any value other than 0 it will default the distance data to zero when nothing is hit
e2function void rangerDefaultZero(defaultzero)
	self.data.rangerdefaultzero = defaultzero ~= 0
end

--- Feed entities you don't want the trace to hit
e2function void rangerFilter(entity ent)
	if validEntity(ent) then
		table.insert(self.data.rangerfilter,ent)
	end
end

__e2setcost(5)

--- Feed an array of entities you don't want the trace to hit
e2function void rangerFilter(array filter)
	local rangerfilter = self.data.rangerfilter
	for _,ent in ipairs(filter) do
		if validEntity(ent) then
			table.insert(rangerfilter,ent)
		end
	end
end

/******************************************************************************/

e2function ranger noranger()
	return nil
end

__e2setcost(20) -- temporary

--- You input max range, it returns ranger data
e2function ranger ranger(distance)
	return ranger(self, 0, distance, 0, 0) -- type 0, no skew
end

--- Same as above with added inputs for X and Y skew
e2function ranger ranger(distance, xskew, yskew)
	return ranger(self, 0, distance, xskew, yskew) -- type 0, with skew
end

--- You input the distance, x-angle and y-angle (both in degrees) it returns ranger data
e2function ranger rangerAngle(distance, xangle, yangle)
	return ranger(self, 1, distance, xangle, yangle) -- type 1, with angles
end

--- You input two vector points, it returns ranger data
e2function ranger rangerOffset(vector from, vector to)
	return ranger(self, 2, 0, from, to) -- type 2, from one point to another
end

--- You input the range, a position vector, and a direction vector and it returns ranger data
e2function ranger rangerOffset(distance, vector from, vector direction)
	return ranger(self, 3, distance, from, direction) -- type 3, from one position into a specific direction, in a specific range
end

/******************************************************************************/

__e2setcost(2) -- temporary

--- Returns the distance from the rangerdata input, else depends on rangerDefault
e2function number ranger:distance()
	if not this then return 0 end
	if this.StartSolid then return this.StartPos:Distance(this.HitPos)*(1/(1-this.FractionLeftSolid)-1) end
	return this.StartPos:Distance(this.HitPos)
end

--- Returns the position of the input ranger data trace IF it hit anything, else returns vec(0,0,0)
e2function vector ranger:position()
	if not this then return { 0, 0, 0 } end
	if this.StartSolid then return this.StartPos end
	return this.HitPos
end

--- Returns the entity of the input ranger data trace IF it hit an entity, else returns nil
e2function entity ranger:entity()
	if not this then return nil end
	return this.Entity
end

--- Returns the bone of the input ranger data trace IF it hit an entity, else returns nil
e2function bone ranger:bone()
	if not this then return nil end

	local ent = this.Entity
	if not validEntity(ent) then return nil end
	return getBone(ent, this.PhysicsBone)
end

--- Returns 1 if the input ranger data hit anything and 0 if it didn't
e2function number ranger:hit()
	if not this then return 0 end
	if this.Hit then return 1 else return 0 end
end

--- Outputs a normalized vector perpendicular to the surface the ranger is pointed at.
e2function vector ranger:hitNormal()
	if not this then return { 0, 0, 0 } end
	return this.HitNormal
end

/******************************************************************************/
-- Hull traces

-- distance, size
e2function ranger rangerHull( number distance, vector size )
	return ranger( self, 0, distance, 0, 0, 1, size )
end

-- distance, mins, maxs
e2function ranger rangerHull(distance, vector mins, vector maxs)
	return ranger(self, 0, distance, 0, 0, 2, mins, maxs )
end

-- distance, xskew, yskew, size
e2function ranger rangerHull(distance, xskew, yskew, vector size)
	return ranger(self, 0, distance, xskew, yskew, 1, size)
end

-- distance, xskew, yskew, mins, maxs
e2function ranger rangerHull(distance, xskew, yskew, vector mins, vector maxs)
	return ranger(self, 0, distance, xskew, yskew, 2, mins, maxs)
end

-- distance, xangle, yangle, size
e2function ranger rangerAngleHull(distance, xangle, yangle, vector size)
	return ranger(self, 1, distance, xangle, yangle, 1, size)
end

-- distance, xangle, yangle, mins, maxs
e2function ranger rangerAngleHull(distance, xangle, yangle, vector mins, vector maxs)
	return ranger(self, 1, distance, xangle, yangle, 2, mins, maxs)
end

-- startpos, endpos, size
e2function ranger rangerOffsetHull( vector startpos, vector endpos, vector size )
	return ranger( self, 2, 0, startpos, endpos, 1, size )
end

-- startpos, endpos, mins, maxs
e2function ranger rangerOffsetHull( vector startpos, vector endpos, vector mins, vector maxs )
	return ranger( self, 2, 0, startpos, endpos, 2, mins, maxs )
end

-- distance, startpos, direction, size
e2function ranger rangerOffsetHull( number distance, vector startpos, vector direction, vector size )
	return ranger( self, 3, distance, startpos, direction, 1, size )
end

-- distance, startpos, direction mins, maxs
e2function ranger rangerOffsetHull( number distance, vector startpos, vector direction, vector mins, vector maxs )
	return ranger( self, 3, distance, startpos, direction, 2, mins, maxs )
end

/******************************************************************************/

registerCallback("construct", function(self)
	self.data.rangerpersist = false
end)

registerCallback("preexecute", function(self)
	if not self.data.rangerpersist then
		ResetRanger(self)
	end
end)

__e2setcost(nil) -- temporary
