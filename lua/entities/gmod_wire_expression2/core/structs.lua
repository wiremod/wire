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

--[[wire_expression_types["STRUCT"] = {
	[1] = "struct",
	[2] = { fields = setmetatable({}, { __index = function() return 59 end }) },
	[4] = function(self, output) return output end,
	[5] = function(retval)
		if not istable(retval) then return end
		if not retval.struct then error("Return value is neither nil nor a Struct, but a " .. type(retval) .. "!",0) end
	end,
	[6] = function(v)
		return not v.struct
	end
}]]


__e2setcost(1)
registerOperator("struct", "", "", function(self, args)
	self.structs[args[2]] = args[3]
end)

registerOperator("structbuild", "", "struct", function(self, args)
	local name, fields = args[2], args[3]

	local fs = {}
	for field, value in pairs(fields) do
		fs[field] = value[1](self, value)
	end

	return { name = name, fields = fs, struct = true, initialized = true }
end)

registerOperator("eq", "structstruct", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local lhs, rhs = op1[1](self, op1), op2[1](self, op2)
	if lhs == rhs then return 1 else return 0 end
end)

-- Defining field(get|set) for types other than struct would look like this:
--[[
	registerOperator("fieldset", "vectorn", "", function(self, args)
		local op1, field_name, op2 = args[2], args[3], args[4]
		local obj = op1[1](self, op1)

		obj[field_name] = op2[1](self, op2)
	end)
]]

-- A.B
registerOperator("fieldset", "struct=<T>", "", function(self, args)
	local op1, field_name, op2 = args[2], args[3], args[4]
	local obj = op1[1](self, op1)

	obj.fields[field_name] = op2[1](self, op2)
end)

registerOperator("fieldget", "struct", "n", function(self, args)
	local op1, field_name = args[2], args[3]
	local obj = op1[1](self, op1)

	return obj.fields[field_name]
end)

-- Logical Ops
registerOperator("ass", "struct", "struct", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local rv2 = op2[1](self, op2, "AAAAAAAA")
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

registerOperator("is", "struct", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)
	if struct.initialized then return 1 else return 0 end
end)

registerOperator("not", "struct", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)

	if struct.initialized then return 0 else return 1 end
end)

registerOperator("and", "structstruct", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)
	if not struct.initialized then return 0 end

	op = args[3]
	struct = op[1](self, op)
	if not struct2.initialized then return 0 end

	return 1
end)

registerOperator("or", "structstruct", "n", function(self, args)
	local op = args[2]
	local struct = op[1](self, op)

	if struct.initialized then return 1 end

	op = args[3]
	struct = op[1](self, op)
	if struct.initialized then return 1 end

	return 0
end)

-- We know the default value will always be a table, so we use table.Copy directly instead of E2Lib.fixDefault
local tbl_copy = table.Copy
registerOperator("idx", "struct=tn", "struct", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]:sub(8, -2)

	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if not rv1.n[rv2] or rv1.ntypes[rv2] ~= id then return tbl_copy(self.structs[inner_t][2]) end
	if v[6] and v[6](rv1.n[rv2]) then return tbl_copy(self.structs[inner_t][2]) end
	return rv1.n[rv2]
end)

registerOperator("idx", "struct=ts", "struct", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]:sub(8, -2)
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if not rv1.s[rv2] or rv1.stypes[rv2] ~= id then return tbl_copy(self.structs[inner_t][2]) end
	if v[6] and v[6](rv1.s[rv2]) then return tbl_copy(self.structs[inner_t][2]) end
	return rv1.s[rv2]
end)

local math_floor = math.floor
registerOperator("idx", "struct=rn", "struct", function(self, args)
	local op1, op2, inner_t = args[2], args[3], args[4]:sub(8, -2)
	local array, index = op1[1](self, op1), op2[1](self, op2)

	if array == nil or index == nil then return tbl_copy(self.structs[inner_t][2]) end -- Make sure array and index are value
	local val = array[math_floor(index)]

	if not istable(val) then return tbl_copy(self.structs[inner_t][2]) end -- Not a table
	if not val.struct then return tbl_copy(self.structs[inner_t][2]) end -- Not a struct
	if val.name ~= inner_t then return tbl_copy(self.structs[inner_t][2]) end -- Not an instanceof <T>
	return val
end)