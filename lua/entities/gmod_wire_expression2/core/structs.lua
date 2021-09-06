--[[============================================================
	E2 User Defined Types/Structs by Vurv
============================================================]]--

-- Structs are right inbetween a rework of the E2 type system and the current system.
-- They allow users to define their own custom types that are only used in E2, but are still a central 'struct' type that
-- can be used in other places like operators / functions.
-- This way we can have custom types but without really changing the current operator system
-- I also made field indexing open to be used in custom extensions and other types, so maybe in the future we could use them for namespacing / libraries?

__e2setcost(1)
registerOperator("struct", "", "", function(self, args)
	local name, fields = args[2], args[3]
	self.structs[name] = fields
end)

registerOperator("structbuild", "", "struct", function(self, args)
	local name, fields = args[2], args[3]

	local fs = {}
	for field, value in pairs(fields) do
		fs[field] = value[1](self, value)
	end

	return { name = name, fields = fs, struct = true }
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

registerOperator("fieldset", "struct", "", function(self, args)
	local op1, field_name, op2 = args[2], args[3], args[4]
	local obj = op1[1](self, op1)

	obj.fields[field_name] = op2[1](self, op2)
end)

registerOperator("fieldget", "struct", "n", function(self, args)
	local op1, field_name = args[2], args[3]
	local obj = op1[1](self, op1)

	return obj.fields[field_name]
end)

registerOperator("ass", "struct", "struct", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)