E2Lib.RegisterExtension("findquery", true, "Allows an E2 to efficiently search for entities using a builder pattern. More efficient, simpler version of the `find` library")

---@class FindQuery
---@field cost number # OPS per entity to filter
---@field filters (fun(e: Entity): boolean)[] # Functions that return whether entity fits criteria
local FindQuery = {}
FindQuery.__index = FindQuery

function FindQuery:__tostring()
	return "FindQuery"
end

registerType("findquery", "xfq", setmetatable({ cost = 0, filters = {} }, FindQuery),
	nil,
	nil,
	function(r)
		if type(r) ~= "table" or getmetatable(r) ~= FindQuery then
			error("Return value is not a FindQuery, but a " .. type(r) .. "!", 0)
		end
	end,
	function(v)
		return type(v) ~= "table" or getmetatable(v) ~= FindQuery
	end
)

registerOperator("ass", "xfq", "xfq", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

__e2setcost(1)

[nodiscard]
e2function findquery findQuery()
	return setmetatable({ filters = {}, cost = 0 }, FindQuery)
end

__e2setcost(3)

[nodiscard]
e2function findquery findquery:inList(array list)
	local lookup = {}
	for _, ent in ipairs(list) do
		self.prf = self.prf + 1
		if self.prf > e2_tickquota then error("perf", 0) end

		lookup[ent] = true
	end

	this.cost = this.cost + 1
	this.filters[#this.filters + 1] = function(e)
		return lookup[e]
	end

	return this
end

[nodiscard]
e2function findquery findquery:notInList(array list)
	local lookup = {}
	for _, ent in ipairs(list) do
		self.prf = self.prf + 1
		if self.prf > e2_tickquota then error("perf", 0) end

		lookup[ent] = true
	end

	this.cost = this.cost + 1
	this.filters[#this.filters + 1] = function(e)
		return lookup[e] == nil
	end

	return this
end

[nodiscard]
e2function findquery findquery:inSphere(vector pos, number radius)
	this.cost = this.cost + 2
	this.filters[#this.filters + 1] = function(e)
		return e:GetPos():DistToSqr(pos) <= radius * radius
	end

	return this
end

[nodiscard]
e2function findquery findquery:notInSphere(vector pos, number radius)
	this.cost = this.cost + 2
	this.filters[#this.filters + 1] = function(e)
		return e:GetPos():DistToSqr(pos) > radius * radius
	end

	return this
end

[nodiscard]
e2function findquery findquery:inCone(vector origin, vector axis, number rad, number length)
	this.cost = this.cost + 4

	local sine = math.cos(rad)
	this.filters[#this.filters + 1] = function(e)
		return util.IsPointInCone(e:GetPos(), origin, axis, sine, length)
	end

	return this
end

[nodiscard]
e2function findquery findquery:notInCone(vector origin, vector axis, number rad, number length)
	this.cost = this.cost + 4

	local sine = math.cos(rad)
	this.filters[#this.filters + 1] = function(e)
		return not util.IsPointInCone(e:GetPos(), origin, axis, sine, length)
	end

	return this
end

[nodiscard]
e2function findquery findquery:inBox(vector min, vector max)
	this.cost = this.cost + 2

	this.filters[#this.filters + 1] = function(e)
		return e:GetPos():WithinAABox(min, max)
	end

	return this
end

[nodiscard]
e2function findquery findquery:notInBox(vector pos, vector dir, number length, number rad)
	this.cost = this.cost + 2

	this.filters[#this.filters + 1] = function(e)
		return not e:GetPos():WithinAABox(min, max)
	end

	return this
end

[nodiscard]
e2function findquery findquery:withClass(string class)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetClass() == class
	end

	return this
end

[nodiscard]
e2function findquery findquery:withoutClass(string class)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetClass() ~= class
	end

	return this
end

[nodiscard]
e2function findquery findquery:withModel(string model)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetModel() == model
	end

	return this
end

[nodiscard]
e2function findquery findquery:withoutModel(string model)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetModel() ~= model
	end

	return this
end

[nodiscard]
e2function findquery findquery:withOwner(entity owner)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetOwner() == owner
	end

	return this
end

[nodiscard]
e2function findquery findquery:withoutOwner(entity owner)
	this.cost = this.cost + 0.125
	this.filters[#this.filters + 1] = function(e)
		return e:GetOwner() ~= owner
	end

	return this
end

__e2setcost(10)

[nodiscard]
e2function array findquery:query()
	local all = ents.GetAll()
	local out, nout, cost = {}, 0, this.cost

	for _, ent in ipairs(all) do
		self.prf = self.prf + 1 + cost
		if self.prf > e2_tickquota then error("perf", 0) end

		for _, filter in ipairs(this.filters) do
			if not filter(ent) then
				goto skip
			end
		end

		nout = nout + 1
		out[nout] = ent

		::skip::
	end

	return out
end

[nodiscard]
e2function array findquery:query(array entities)
	local out, nout, cost = {}, 0, this.cost

	for _, ent in ipairs(entities) do
		self.prf = self.prf + 1.5 + cost
		if self.prf > e2_tickquota then error("perf", 0) end

		if not IsValid(ent) then
			goto skip
		end

		for _, filter in ipairs(this.filters) do
			if not filter(ent) then
				goto skip
			end
		end

		nout = nout + 1
		out[nout] = ent

		::skip::
	end

	return out
end

[nodiscard]
e2function number findquery:cost()
	return this.cost
end