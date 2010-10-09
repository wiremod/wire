local function table_IsEmpty(t) return not next(t) end

/******************************************************************************\
  Table support
\******************************************************************************/

registerType("table", "t", {},
	function(self, input)
		local ret = {}
		local c = 0
		for k,v in pairs(input) do c = c + 1 ret[k] = v end
		self.prf = self.prf + c / 3
		return ret
	end,
	nil,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "table"
	end
)

-- these postexecute and construct hooks handle changes to both tables and arrays.
registerCallback("postexecute", function(self)
	local vars, vclk, lookup = self.vars, self.vclk, self.data.lookup

	-- Go through all registered values of the types table and array.
	for value,varnames in pairs(lookup) do
		local clk = vclk[value]

		local still_assigned = false
		-- For each value, go through the variables they're assigned to and trigger them.
		for varname,_ in pairs(varnames) do
			if value == vars[varname] then
				-- The value is still assigned to the variable? => trigger it.
				if clk then vclk[varname] = true end
				still_assigned = true
			else
				-- The value is no longer assigned to the variable? => remove the lookup table entry.
				varnames[varname] = nil
			end
		end

		-- if the value is no longer assigned to anything, remove all references to it.
		if not still_assigned then
			lookup[value] = nil
		end
		-- If the value has no more variable names associated, remove the value's place in the lookup table.
		if table_IsEmpty(varnames) then lookup[value] = nil end
	end
end)

local tbls = {
	ARRAY = true,
	TABLE = true,
	MTABLE = true,
}

registerCallback("construct", function(self)
	self.data.lookup = {}

	for k,v in pairs( self.vars ) do
		local datatype = self.entity.outports[3][k]
		if (tbls[datatype]) then
			if (!self.data.lookup[v]) then self.data.lookup[v] = {} end
			self.data.lookup[v][k] = true
		end
	end
end)

/******************************************************************************/

__e2setcost(5) -- temporary

e2function table operator=(table lhs, table rhs)

	local lookup = self.data.lookup

	-- remove old lookup entry
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end

	-- add new
	if (!lookup[rhs]) then
		lookup[rhs] = {}
	end
	lookup[rhs][lhs] = true

	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

/******************************************************************************/

e2function number operator_is(table tbl)
	if table_IsEmpty(tbl) then return 0 else return 1 end
end

/******************************************************************************/

e2function table table()
	return {}
end

e2function table table:clear()
	self.prf = self.prf + table.Count(this) / 3
	table.Empty(this)
end

e2function table table:clone()
	local ret = {}
	local c = 0
	for k,v in pairs(this) do c = c + 1 ret[k] = v end
	self.prf = self.prf + c / 3
	return ret
end

e2function number table:count()
	local c = table.Count(this)
	self.prf = self.prf + c / 3
	return c
end

/******************************************************************************/

-- for invert(R)
local tostrings = {
	number=tostring,
	string=tostring,
	Entity=tostring,
	Weapon=tostring,
	Player=tostring,
	Vehicle=tostring,
	NPC=tostring,
	PhysObj=e2_tostring_bone,
	["nil"] = function() return "(null)" end
}

function tostrings.table(t)
	return "["..table.concat(t, ",").."]"
end

function tostrings.Vector(v)
	return "[" .. tostring(v[1]) .. "," .. tostring(v[2]) .. "," .. tostring(v[3]) .. "]"
end

-- for invert(T)
local tostring_typeid = {
	n=tostring,
	s=tostring,
	e=tostring,
	xv2=tostrings.table,
	v=tostrings.Vector,
	xv4=tostrings.table,
	a=tostrings.table,
	b=e2_tostring_bone,
}

--- Returns a lookup table for <arr>. Usage: Index = T:number(toString(Value)).
--- Don't overuse this function, as it can become expensive for arrays with > 10 entries!
e2function table invert(array arr)
	local ret = {}
	local c = 0
	for i,v in ipairs(arr) do
		c = c + 1
		local tostring_this = tostrings[type(v)]
		if tostring_this then
			ret["n"..tostring_this(v)] = i
		else
			self.player:ChatPrint("E2: invert(R): Invalid type ("..type(v)..") in array. Ignored.")
		end
	end
	self.prf = self.prf + c / 2
	return ret
end

--- Returns a lookup table for <tbl>. Usage: Key = T:string(toString(Value)).
--- Don't overuse this function, as it can become expensive for tables with > 10 entries!
e2function table invert(table tbl)
	local ret = {}
	local c = 0
	for i,v in pairs(tbl) do
		c = c + 1
		local long_typeid = string.sub(i,1,1) == "x"
		local typeid = string.sub(i,1,long_typeid and 3 or 1)

		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret["s"..tostring_this(v)] = i:sub(long_typeid and 4 or 2)
		else
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	self.prf = self.prf + c / 2
	return ret
end

e2function array table:keys()
	local ret = {}
	local c = 0
	for index,value in pairs(this) do
		c = c + 1
		local long_typeid = index:sub(1,1) == "x"
		--local typeid = index:sub(1,long_typeid and 3 or 1)
		local key = index:sub(long_typeid and 4 or 2)

		ret[#ret+1] = key
	end
	self.prf = self.prf + c / 2
	return ret
end

e2function array table:values()
	local ret = {}
	local c = 0
	for index,value in pairs(this) do
		c = c + 1
		--local long_typeid = index:sub(1,1) == "x"
		--local typeid = index:sub(1,long_typeid and 3 or 1)
		--local key = index:sub(long_typeid and 4 or 2)

		ret[#ret+1] = value
	end
	self.prf = self.prf + c / 2
	return ret
end

e2function array table:typeids()
	local ret = {}
	local c = 0
	for index,value in pairs(this) do
		c = c + 1
		local long_typeid = index:sub(1,1) == "x"
		local typeid = index:sub(1,long_typeid and 3 or 1)
		--local key = index:sub(long_typeid and 4 or 2)

		ret[#ret+1] = typeid
	end
	self.prf = self.prf + c / 2
	return ret
end

/******************************************************************************/

registerCallback("postinit", function()

	-- retrieve information about all registered types
	local types = table.Copy(wire_expression_types)

	-- change the name for numbers from "NORMAL" to "NUMBER"
	types["NUMBER"] = types["NORMAL"]
	types["NORMAL"] = nil

	-- we don't want tables and arrays as table elements, so get rid of them
	types["TABLE"] = nil
	types["ARRAY"] = nil
	types["GTABLE"] = nil
	types["MTABLE"] = nil

	local getf, setf
	-- generate getters and setters for all types
	for name,id,zero in pairs_map(types, unpack) do

		-- for T:number() etc
		local getter = name:lower()

		-- for T:setNumber() etc
		local setter = "set"..name:sub(1,1):upper()..name:sub(2):lower()

		if zero ~= nil then
			-- getters for everything but entity, bone, wirelink and ranger
			function getf(self, args)
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
				local ret = rv1[id .. rv2]
				if ret then return ret end
				return zero
			end
			if type(zero) == "table" then
				if table_IsEmpty(zero) then
					-- setters for array and table (currently unused)
					function setf(self, args)
						local op1, op2, op3 = args[2], args[3], args[4]
						local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
						if table_IsEmpty(rv3) then
							rv1[id .. rv2] = nil
						else
							rv1[id .. rv2] = rv3
						end
						self.vclk[rv1] = true
						return rv3
					end
				elseif #zero ~= table.Count(zero) then
					-- setters for tables with named entries. currently unused
					function setf(self, args)
						local op1, op2, op3 = args[2], args[3], args[4]
						local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
						local val = nil
						for i,v in pairs(zero) do if rv3[i] ~= v then val = rv3 break end end
						rv1[id .. rv2] = val
						self.vclk[rv1] = true
						return rv3
					end
				else
					-- setters for vector*, matrix* and angle
					function setf(self, args)
						local op1, op2, op3 = args[2], args[3], args[4]
						local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
						local val = nil
						for i,v in ipairs(zero) do if rv3[i] ~= v then val = rv3 break end end
						rv1[id .. rv2] = val
						self.vclk[rv1] = true
						return rv3
					end
				end
			else
				-- setters for number and string
				function setf(self, args)
					local op1, op2, op3 = args[2], args[3], args[4]
					local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
					if rv3 == zero then
						rv1[id .. rv2] = nil
					else
						rv1[id .. rv2] = rv3
					end
					self.vclk[rv1] = true
					return rv3
				end
			end
		else
			-- getters and setters for entity, bone, wirelink and ranger
			function getf(self, args)
				local op1, op2 = args[2], args[3]
				local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
				return rv1[id .. rv2]
			end

			function setf(self, args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
				rv1[id .. rv2] = rv3
				self.vclk[rv1] = true
				return rv3
			end
		end
		registerFunction(getter, "t:s", id, getf)
		registerOperator("idx", id.."=ts", id, getf)
		registerFunction(setter, "t:s"..id, id, setf)
		registerOperator("idx", id.."=ts"..id, id, setf)
	end
	-- all types not mentioned and custom types have their getters and setters generated like those of the built-in type that is most similar to them.
end) -- registerCallback("postinit")

__e2setcost(nil) -- temporary
