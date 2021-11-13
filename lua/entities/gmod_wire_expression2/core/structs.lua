--[[============================================================
	E2 User Defined Types/Structs by Vurv
============================================================]]--

--[[
	Structs are right inbetween a rework of the E2 type system and the current system.
	They allow users to define their own custom types that are only used in E2, but are still a central 'struct' type that
	can be used in other places like operators / functions.

	This way we can have custom types but without really changing the current operator system
	I also made field indexing open to be used in custom extensions and other types, so maybe in the future we could use them for namespacing / libraries?

	Further Explanations:
		Structs are defined by the user in the E2 code, and are used in the E2 code.
		The ``initialized`` field in a struct instance represents whether the struct was created or if it came from a default value (when we get those)
		This is used for if(X), &, |, etc.
]]

registerType("struct", "xst", E2Lib.newStruct("struct"), nil, nil, function(i)
	return istable(i) and i.struct
end)

-- Put these so we don't have to check if the fields exist at runtime.
-- Hack to save perf.
wire_expression_types["struct"].fields = {}
wire_expression_types2["xst"].fields = {}

local newStruct = E2Lib.newStruct

registerOperator("structbuild", "", "struct", function(self, args)
	local name, fields = args[2], args[3]

	local fs = {}
	for field, value in pairs(fields) do
		fs[field] = value[1](self, value)
	end

	return newStruct(name, fs, args[4], true)
end)

e2function number operator==( struct rv1, struct rv2 )
	if rv1 == rv2 then return 1 else return 0 end
end

-- Defining field(get|set) for types other than struct would look like this:
--[[
	registerOperator("fieldset", "vectorn", "", function(self, args)
		local op1, field_name, op2 = args[2], args[3], args[4]
		local obj = op1[1](self, op1)

		obj[field_name] = op2[1](self, op2)
	end)
]]

-- A.B
registerOperator("fieldset", "xst=<T>", "", function(self, args)
	local op1, field_name, op2 = args[2], args[3], args[4]
	local obj = op1[1](self, op1)

	obj.fields[field_name] = op2[1](self, op2)
end)

registerOperator("fieldget", "xst", "n", function(self, args)
	local op1, field_name = args[2], args[3]
	local obj = op1[1](self, op1)

	return obj.fields[field_name]
end)

-- Logical Ops
registerOperator("ass", "xst", "xst", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

registerOperator("is", "xst", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)
	if struct.initialized then return 1 else return 0 end
end)

registerOperator("not", "xst", "n", function(self, args)
	local op = args[2]
	if op[1](self, op).initialized then return 0 else return 1 end
end)

registerOperator("and", "xstxst", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)
	if not struct.initialized then return 0 end

	op = args[3]
	struct = op[1](self, op)
	if not struct.initialized then return 0 end

	return 1
end)

registerOperator("or", "xstxst", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)

	if struct.initialized then return 1 end

	op = args[3]
	struct = op[1](self, op)
	if struct.initialized then return 1 end

	return 0
end)

-- We know the default value will always be a table, so we use table.Copy directly instead of E2Lib.fixDefault
local table_copy, string_sub = table.Copy, string.sub
local function struct_default(self, typeid)
	return table_copy(self.typeid_lookup[typeid][2])
end

-- table()[1, <struct_name>]
registerOperator("idx", "xst=tn", "xst", function(self, args)
	local op1, op2, typeid = args[2], args[3], args[4]

	local tbl, index = op1[1](self, op1), op2[1](self, op2)
	local set_val = tbl.n[index]
	if set_val == nil or tbl.ntypes[index] ~= typeid then return struct_default(self, typeid) end
	return set_val
end)

-- table()[1, <struct_name>] = Var
registerOperator("idx", "xst=tnxst", "xst", function(self, args)
	local op1, op2, op3, inner_t = args[2], args[3], args[4], args[5]
	local tbl, index, value = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	local num_tbl = tbl.n

	if num_tbl[index] == nil then
		if value ~= nil then
			tbl.size = tbl.size + 1
		end
	elseif value == nil then
		tbl.size = tbl.size - 1
	end

	num_tbl[index] = value
	tbl.ntypes[index] = inner_t
	self.GlobalScope.vclk[tbl] = true
	return value
end)

-- table()["index", <struct_name>]
registerOperator("idx", "xst=ts", "xst", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]

	local tbl, index = op1[1](self, op1), op2[1](self, op2)

	local set_val = tbl.s[index]
	if set_val == nil or tbl.stypes[index] ~= inner_t then return struct_default(self, inner_t) end
	return set_val
end)

-- table()["index", <struct_name>] = Var
registerOperator("idx", "xst=tsxst", "xst", function(self, args)
	local op1, op2, op3, inner_t = args[2], args[3], args[4], args[5]
	local tbl, index, value = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	local string_tbl = tbl.s

	if string_tbl[index] == nil then
		if value ~= nil then
			tbl.size = tbl.size + 1
		end
	elseif value == nil then
		tbl.size = tbl.size - 1
	end

	string_tbl[index] = value
	tbl.stypes[index] = inner_t
	self.GlobalScope.vclk[tbl] = true
	return value
end)

local math_floor = math.floor
-- array()[1, <struct_name>]
registerOperator("idx", "xst=rn", "xst", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]
	local array, index = op1[1](self, op1), op2[1](self, op2)

	if array == nil or index == nil then return struct_default(self, inner_t) end -- Make sure array and index are value
	local val = array[math_floor(index)]

	if not istable(val) then return struct_default(self, inner_t) end -- Not a table
	if not val.struct then return struct_default(self, inner_t) end -- Not a struct

	-- We know it's a struct now, so we can use some extra cpu to string.sub in here. Also inlining what struct_default does since we've already done string.sub
	inner_t = string_sub(inner_t, 8, -2)
	if val.name ~= inner_t then return table_copy(self.types[inner_t][2]) end -- Different struct type

	return val
end)

-- array()[1, <struct_name>] = Var
registerOperator("idx", "xst=rnxst", "xst", function(self, args)
	local op1, op2, op3, inner_t = args[2], args[3], args[4], args[5]
	local array, index, val = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	if not array or not index then return struct_default(self, inner_t) end -- Make sure array and index are valid
	if not istable(val) then return struct_default(self, inner_t) end -- Not a table
	if not val.struct or val.name ~= inner_t then return struct_default(self, inner_t) end

	array[floor(index)] = val
	self.GlobalScope.vclk[array] = true
	return val
end)

e2function string struct:name()
	return this.name
end

e2function table struct:fields()
	local t, size = E2Lib.newE2Table(), 0

	local s, stypes = t.s, t.stypes
	local ftypes = this.ftypes
	for k, v in pairs(this.fields) do
		s[k] = v
		stypes[k] = ftypes[k]
		size = size + 1
	end

	t.size = size

	return t
end

--[[
	This is commented out because gtables would be type unsafe.
	You could make a gtable with a struct named 'human' or something, and if someone else made another struct with the same name,
	the compiler / editor would be happy, however it'd lead to undefined behavior since we assume the fields are the same just because the struct name is the same.

	In the future we could scan to make sure the fields are equivalent or have a sort of hash for each one, but cba to right now.

-- gTable(...)[1, <struct_name>]
registerOperator("idx", "struct=xgtn", "struct", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	if isnumber(rv2) then rv2 = tostring(rv2) end
	local val = rv1["struct" .. rv2]
	if val then
		return val
	end
	return struct_default(self, inner_t)
end)

-- gTable(...)[1, <struct_name>] = Var
registerOperator("idx", "struct=xgtnstruct", "struct", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local gtable, index, val = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	gtable["struct" .. index] = val
	return val
end)

-- gTable(...)["index", <struct_name>] = Var
registerOperator("idx", "struct=xgtsstruct", "struct", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local gtable, index, val = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)

	gtable["struct" .. index] = val
	return val
end)
]]