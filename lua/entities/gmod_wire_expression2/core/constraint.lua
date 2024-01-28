-----------------------------
----Helper Functions--
-----------------------------

-- caps("heLlO") == "Hello"
local function caps(text)
	local capstext = text:sub(1,1):upper() .. text:sub(2):lower()
	if capstext == "Nocollide" then return "NoCollide" end
	if capstext == "Advballsocket" then return "AdvBallsocket" end
	return capstext
end

-- Returns con.Ent1 or con.Ent2, whichever is not equivalent to ent. Optionally subscripts con with num beforehand.
local function ent1or2(ent,con,num)
	if not con then return nil end
	if num then
		con = con[num]
		if not con then return nil end
	end
	if con.Ent1==ent then return con.Ent2 end
	return con.Ent1
end

--[[
	-- buildFilters

	Special keywords for filtering include:
		'All'
		'Constraints'/'Constraint'
		'Parented'/'Parents'/'Parent'
		'Wires'/'Wire'
		or any constraint type names such as 'Weld', 'Axis', etc

	Prefixing any of the keywords (except 'All') with '-' or '!' will negate the filter
	Examples
		entity():getConnectedEntities("all") => entity():getConnectedEntities() => entity():getConnectedEntities("") => all three are the same
		entity():getConnectedEntities("all","-axis") => get all entities except those constrained via axis
		entity():getConnectedEntities("weld","parented") => get welded or parented entities
		entity():getConnectedEntities("all","-constraint") => is the same as entity():getConnectedEntities("parented")
		entity():getConnectedEntities("-weld") => Invalid. Trying to use a negated keyword without also using 'All' or 'Constraints' won't work.
	(if an entity is attached to your contraption in multiple ways and one of them match the filter, then it will be returned.)

	Keywords are not case sensitive.
]]
local function buildFilter(filters)
	local filter_lookup = {}

	if #filters == 0 or (#filters == 1 and filters[1] == "") then -- No filters given, same as "All"
		filter_lookup.Constraints = true
		filter_lookup.Parented = true
		filter_lookup.Wires = true
	else
		for i=1,#filters do
			local filter = filters[i]
			if type(filter) == "string" then
				local bool = true
				if string.sub(filter,1,1) == "-" or string.sub(filter,1,1) == "!" then -- check for negation
					bool = false
					filter = string.sub(filter,2)
				end

				filter = caps(filter)

				-- correct potential mistakes
				if filter == "Constraint" then filter = "Constraints"
				elseif filter == "Parent" or filter == "Parents" then filter = "Parented"
				elseif filter == "Wire" then filter = "Wires" end

				if filter == "All" then
					if bool then -- "all" can't be negated
						filter_lookup.Constraints = true
						filter_lookup.Parented = true
						filter_lookup.Wires = true
					end
				else
					filter_lookup[filter] = bool
				end
			end
		end
	end

	return filter_lookup
end

local function checkFilter(constraintType,filter_lookup)
	if filter_lookup.Constraints -- check if we allow all constraints
		and not (filter_lookup[constraintType] == false) -- but also if this specific constraint hasn't been negated
		then return true end

	return filter_lookup[constraintType] == true -- check if this specific constraint has been added to the filter
end

-- Custom version of constraint.GetTable, which is faster than garry's and supports filtering
local function constraint_GetTable(ent,filter_lookup)
	if not ent.Constraints then return {} end

	local result = {}

	for _, con in pairs( ent.Constraints ) do
		if IsValid(con) then
			if filter_lookup and not checkFilter(con.Type,filter_lookup) then continue end

			result[#result+1] = con
		end
	end

	return result
end

-- Alias, due to the fact that the custom version of GetTable already supports filtering
local constraint_FindConstraints = constraint_GetTable

-- Custom version of constraint.FindConstraint, which is faster than garry's
local function constraint_FindConstraint(ent,filter_lookup)
	if not ent.Constraints then return {} end

	for _, con in pairs( ent.Constraints ) do
		if IsValid(con) then
			if filter_lookup and not checkFilter(con.Type,filter_lookup) then continue end

			return con
		end
	end
end

local getConnectedEntities

-- small helper function for getConnectedEntities
local function getConnectedEx(e, filter_lookup, result, already_added)
	if IsValid(e) and not already_added[e] then
		getConnectedEntities(e, filter_lookup, result, already_added)
	end
end


-- custom version of constraint.GetAllConstrainedEntities, but is faster than garry's
-- and supports filtering and also parented entities
getConnectedEntities = function(ent, filter_lookup, result, already_added)
	result = result or {}
	already_added = already_added or {}

	result[#result+1] = ent
	already_added[ent] = true

	if filter_lookup then
		if filter_lookup.Parented then -- add parented entities
			getConnectedEx(ent:GetParent(),filter_lookup, result, already_added)
			for _, e in pairs(ent:GetChildren()) do
				getConnectedEx( e, filter_lookup, result, already_added )
			end
		end

		if filter_lookup.Wires then -- add wired entities
			for _, i in pairs(ent.Inputs or {}) do
				getConnectedEx( i.Src, filter_lookup, result, already_added )
			end

			for _, o in pairs(ent.Outputs or {}) do
				getConnectedEx( o.Src, filter_lookup, result, already_added )
			end
		end
	end

	for _, con in pairs( ent.Constraints or {} ) do -- add constrained entities
		if IsValid(con) then
			if filter_lookup and not checkFilter(con.Type,filter_lookup) then -- skip if it doesn't match the filter
				continue
			end

			for i=1, 6 do
				getConnectedEx( con["Ent"..i], filter_lookup, result, already_added )
			end
		end
	end

	return result
end

--******************************************************************************
__e2setcost(20)

--- Returns an '''array''' containing all entities directly or indirectly constrained to <this>, except <this> itself.
[deprecated, nodiscard]
e2function array entity:getConstraints()
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	if not constraint.HasConstraints(this) then return {} end

	local result = getConnectedEntities(this)
	table.remove(result,1) -- <this> is always in the first position
	self.prf = self.prf + #result * 30

	return result
end

--[[
	Returns an '''array''' constaining all entities directly or indirectly connected to <this>
	supports filtering, see buildFilter above
]]
[nodiscard]
e2function array entity:getConnectedEntities(...filters)
	if not IsValid(this) then return self:throw("Invalid entity!", {}) end
	local result = getConnectedEntities(this,buildFilter(filters))
	self.prf = self.prf + #result * 30
	return result
end

e2function array entity:getConnectedEntities(array filters)
	if not IsValid(this) then return {} end
	local result = getConnectedEntities(this,buildFilter(filters))
	self.prf = self.prf + #result * 30
	return result
end

__e2setcost(5)

--- Returns the number of constraints on <this>.
e2function number entity:hasConstraints()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end

	return #constraint_GetTable(this)
end

--- Returns the number of constraints of type <constraintType> on <this>.
e2function number entity:hasConstraints(string constraintType)
	if not IsValid(this) then return 0 end

	return #constraint_GetTable(this,buildFilter({constraintType}))
end

--- Returns 1 if <this> is constrained to anything, 0 otherwise.
e2function number entity:isConstrained()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not constraint.HasConstraints(this) then return 0 end

	return 1
end

--- Returns the first entity <this> was welded to.
e2function entity entity:isWeldedTo()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	local filter = {Weld=true} -- create filter directly, no need to call buildFilter here, since it's static
	return ent1or2(this,constraint_FindConstraint(this, filter))
end

--- Returns the <index>th entity <this> was welded to.
e2function entity entity:isWeldedTo(index)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	local filter = {Weld=true} -- create filter directly, no need to call buildFilter here, since it's static
	return ent1or2(this,constraint_FindConstraints(this, filter), math.floor(index))
end

--- Returns the first entity <this> was constrained to.
e2function entity entity:isConstrainedTo()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint_GetTable(this),1)
end

--- Returns the <index>th entity <this> was constrained to.
e2function entity entity:isConstrainedTo(index)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint_GetTable(this), math.floor(index))
end

--- Returns the first entity <this> was constrained to with the given constraint type <constraintType>.
e2function entity entity:isConstrainedTo(string constraintType)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint_FindConstraint(this, buildFilter({constraintType})))
end

--- Returns the <index>th entity <this> was constrained to with the given constraint type <constraintType>.
e2function entity entity:isConstrainedTo(string constraintType, index)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint_FindConstraints(this, buildFilter({constraintType})), math.floor(index))
end

--- Returns the '''entity''' <this> is parented to.
e2function entity entity:parent()
	if not IsValid(this) then return nil end
	return this:GetParent()
end

local getBone = E2Lib.getBone

--- Returns the '''bone''' <this> is parented to.
e2function bone entity:parentBone()
	if not IsValid(this) then return nil end

	local ent = this:GetParent()
	if not IsValid(ent) then return nil end
	local bonenum = this:GetParentPhysNum()
	return getBone(ent, bonenum)
end

__e2setcost(20)

--- Returns an '''array''' containing all the children of the entity - that is, every entity whose parent is this entity.
e2function array entity:children()
	if not IsValid(this) then return {} end

	local keytable = this:GetChildren()
	local array = {}
	local i = 1
	for _, ent in pairs(keytable) do
		array[i] = ent
		i = i + 1
	end
	return array
end
