/******************************************************************************\
  Expression 2 built-in ranger/tracing extension
\******************************************************************************/

E2Lib.RegisterExtension("ranger", true, "Lets E2 chips trace rays and check for collisions.")

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
	data.rangerfilter_lookup = table.MakeNonIterable{ [self.entity] = true }
end

local function ranger(self, rangertype, range, p1, p2, hulltype, mins, maxs, traceEntity )
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
			tracedata.mask = bit.bor(MASK_WATER, CONTENTS_SOLID)
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
		tracedata.endpos = tracedata.start + Vector( p2[1], p2[2], p2[3] ):GetNormalized()*range
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
			tracedata.endpos = chip:LocalToWorld(skew:GetNormalized()*range)
		else
			tracedata.endpos = tracedata.start + chip:GetUp()*range
		end
	end

	-- clamp positions
	tracedata.start = E2Lib.clampPos( tracedata.start )
	if tracedata.start:Distance( tracedata.endpos ) > 57000 then -- 57000 is slightly larger than the diagonal distance (min corner to max corner) of the source max map size
		tracedata.endpos = tracedata.start + (tracedata.endpos - tracedata.start):GetNormal() * 57000
	end

	---------------------------------------------------------------------------------------
	local trace
	if IsValid(traceEntity) then
		trace = util.TraceEntity( tracedata, traceEntity )
	elseif (hulltype) then
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

		if not entities then -- unfortunately we have to add tons of ops if this happens
							 -- If we didn't, it would be possible to crash servers with it.
			tracedata.mins = E2Lib.clampPos( tracedata.mins )
			tracedata.maxs = E2Lib.clampPos( tracedata.maxs )
			self.prf = self.prf + tracedata.mins:Distance(tracedata.maxs) * 0.5
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
		trace.HitWorld = false
	elseif defaultzero and not trace.Hit then
		trace.HitPos = tracedata.start
	end

	trace.RealStartPos = tracedata.start

	return trace
end

/******************************************************************************/

registerType("ranger", "xrd", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if !istable(retval) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return !istable(v) or not v.HitPos
	end
)

/******************************************************************************/

__e2setcost(1) -- temporary

--- RD = RD
registerOperator("ass", "xrd", "xrd", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)

	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

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

--- Default is 1, if any value other than 0 is is given, it will hit entities
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

__e2setcost(10)

--- Feed entities you don't want the trace to hit
e2function void rangerFilter(entity ent)
	if IsValid(ent) and not self.data.rangerfilter_lookup[ent] then
		local n = #self.data.rangerfilter+1
		self.data.rangerfilter[n] = ent
		self.data.rangerfilter_lookup[ent] = true
	end
end

__e2setcost(1)

--- Feed an array of entities you don't want the trace to hit
e2function void rangerFilter(array filter)
	local rangerfilter = self.data.rangerfilter
	local n = #rangerfilter
	for _,ent in ipairs(filter) do
		if IsValid(ent) and not self.data.rangerfilter_lookup[ent] then
			n = n + 1
			rangerfilter[n] = ent
			self.data.rangerfilter_lookup[ent] = true
		end
	end
	self.prf = self.prf + #filter * 10
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

-- Same as ranger(distance) but for another entity
e2function ranger ranger(entity ent, distance)
	if not IsValid( ent ) then return nil end
	if not self.data.rangerfilter_lookup[ent] then
		self.data.rangerfilter[#self.data.rangerfilter+1] = ent
		self.data.rangerfilter_lookup[ent] = true
	end
	return ranger(self,3,distance,ent:GetPos(),ent:GetUp())
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

	local startpos
	if (this.StartSolid) then
		startpos = this.RealStartPos
	else
		startpos = this.StartPos
	end

	--if this.StartSolid then return this.StartPos:Distance(this.HitPos)*(1/(1-this.FractionLeftSolid)-1) end
	return startpos:Distance(this.HitPos)
end

--- Returns the position of the input ranger data trace IF it hit anything, else returns vec(0,0,0)
e2function vector ranger:position()
	if not this then return { 0, 0, 0 } end
	if this.StartSolid then return this.StartPos end
	return this.HitPos
end

-- Returns the position of the input ranger data trace IF it it anything, else returns vec(0,0,0).
-- NOTE: This function works like Lua's trace, while the above "position" function returns the same as positionLeftSolid IF it was created inside the world.
e2function vector ranger:pos()
	if not this then return {0,0,0} end
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
	if not IsValid(ent) then return nil end
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

-- Returns a number between 0 and 1, ie R:distance()/maxdistance
e2function number ranger:fraction()
	if not this then return 0 end
	return this.Fraction
end

-- Returns 1 if the ranger hit the world, else 0
e2function number ranger:hitWorld()
	if not this then return 0 end
	return this.HitWorld and 1 or 0
end

-- Returns 1 if the ranger hit the skybox, else 0
e2function number ranger:hitSky()
	if not this then return 0 end
	return this.HitSky and 1 or 0
end

-- Returns the position at which the trace left the world if it was started inside the world
e2function vector ranger:positionLeftSolid()
	if not this then return { 0,0,0 } end
	return this.StartPos
end

e2function number ranger:distanceLeftSolid()
	if not this then return 0 end
	return this.RealStartPos:Distance(this.StartPos)
end

-- Returns a number between 0 and 1
e2function number ranger:fractionLeftSolid()
	if not this then return 0 end
	return this.FractionLeftSolid
end

-- Returns 1 if the trace started inside the world, else 0
e2function number ranger:startSolid()
	if not this then return 0 end
	return this.StartSolid and 1 or 0
end

local mat_enums = {}
local hitgroup_enums = {}
for k,v in pairs( _G ) do
	if (k:sub(1,4) == "MAT_") then
		mat_enums[v] = k:sub(5):lower()
	elseif (k:sub(1,9) == "HITGROUP_") then
		hitgroup_enums[v] = k:sub(10):lower()
	end
end

-- Returns the material type (ie "contrete", "dirt", "flesh", etc)
e2function string ranger:matType()
	if not this then return "" end
	if not this.MatType then return "" end
	return mat_enums[this.MatType] or ""
end

-- Returns the hit group if the trace hit a player (ie "chest", "stomach", "head", "leftarm", etc)
e2function string ranger:hitGroup()
	if not this then return "" end
	if not this.HitGroup then return "" end
	return hitgroup_enums[this.HitGroup] or ""
end

-- Returns the texture that the trace hits
e2function string ranger:hitTexture()
	if not this then return "" end
	return this.HitTexture or ""
end

-- Helper table used for toTable
local ids = {
	["FractionLeftSolid"] = "n",
	["HitNonWorld"] = "n",
	["Fraction"] = "n",
	["Entity"] = "e",
	["HitNoDraw"] = "n",
	["HitSky"] = "n",
	["HitPos"] = "v",
	["StartSolid"] = "n",
	["HitWorld"] = "n",
	["HitGroup"] = "n",
	["HitNormal"] = "v",
	["HitBox"] = "n",
	["Normal"] = "v",
	["Hit"] = "n",
	["MatType"] = "n",
	["StartPos"] = "v",
	["PhysicsBone"] = "n",
	["WorldToLocal"] = "v",
	["RealStartPos"] = "v",
	["HitTexture"] = "s",
	["HitBoxBone"] = "n"
}

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

-- Converts the ranger into a table. This allows you to manually get any and all raw data from the trace.
e2function table ranger:toTable()
	if not this then return {} end
	local ret = table.Copy(DEFAULT)
	local size = 0
	for k,v in pairs( this ) do
		if (ids[k]) then
			if isbool(v) then v = v and 1 or 0 end
			ret.s[k] = v
			ret.stypes[k] = ids[k]
			size = size + 1
		end
	end
	ret.size = size
	return ret
end

/******************************************************************************/
-- Hull traces

__e2setcost(20)

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

-- Use util.TraceEntity for collison box trace
e2function ranger rangerOffsetHull(entity ent, vector from, vector to)
	if IsValid(ent) and !ent:IsWorld() then
		return ranger(self, 2, 0, from, to, 0, 0, 0, ent)
	else
		return nil
	end
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
