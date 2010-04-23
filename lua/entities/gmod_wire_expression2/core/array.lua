/******************************************************************************\
  Array support
\******************************************************************************/

E2_MAX_ARRAY_SIZE = 1024*1024	// 1MB

/******************************************************************************/

registerType("array", "r", {},
	function(self, input)
		local ret = {}
		self.prf = self.prf + #input / 3
		for k,v in pairs(input) do ret[k] = v end
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

/******************************************************************************/

__e2setcost(5) -- temporary

e2function array array()
	return {}
end

--- Constructs an array with the given values as elements. If you specify types that are not supported by the array data type, the behaviour is undefined.
e2function array array(...)
	local ret = { ... }
	for i,v in ipairs(ret) do
		if typeids[i] == "r" or typeids[i] == "t" then ret[i] = nil end
	end
	return ret
end

/******************************************************************************/

e2function array operator=(array lhs, array rhs)
	local lookup = self.data.lookup

	-- remove old lookup entry
	if lookup[rhs] then lookup[rhs][lhs] = nil end

	-- add new lookup entry
	local lookup_entry = lookup[rhs]
	if not lookup_entry then
		lookup_entry = {}
		lookup[rhs] = lookup_entry
	end
	lookup_entry[lhs] = true

	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

/******************************************************************************/

e2function number operator_is(array arr)
	return type(arr) == "table" and 1 or 0
end

registerCallback("postinit", function()
	-- retrieve information about all registered types
	local types = table.Copy(wire_expression_types)

	-- change the name for numbers from "NORMAL" to "NUMBER"
	types["NUMBER"] = types["NORMAL"]
	types["NORMAL"] = nil

	-- we don't want tables and arrays as array elements, so get rid of them
	types["TABLE"] = nil
	types["ARRAY"] = nil

	-- generate op[] for all types
	for name,id in pairs_map(types, unpack) do

		-- R:number() etc
		local getter = name:lower()

		-- R:setNumber() etc
		local setter = "set"..name:sub(1,1):upper()..name:sub(2):lower()

		local getf = wire_expression2_funcs[getter.."(r:n)"]
		local setf = wire_expression2_funcs[setter.."(r:n"..id..")"]

		if getf then
			local f = getf.oldfunc or getf[3] -- use oldfunc if present, else func
			if getf then
				registerOperator("idx", id.."=rn", id, f, getf[4], getf[5])
			end
		end
		if setf then
			local f = setf.oldfunc or setf[3] -- use oldfunc if present, else func
			if setf then
				registerOperator("idx", id.."=rn"..id, id, f, setf[4], setf[5])
			end
		end
	end
end)

/******************************************************************************/

e2function number array:count()
	return #this
end

/******************************************************************************/

e2function void array:clear()

	self.prf = self.prf + #this / 3

	table.Empty(this)
end

e2function array array:clone()
	local ret = {}

	self.prf = self.prf + #this / 3

	for k,v in pairs(this) do
		ret[k] = v
	end

	return ret
end

/********************* The Old, Haunted Part of array.lua *********************/

registerFunction("number", "r:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tonumber(ret) or 0 end
	return 0
end)

registerFunction("setNumber", "r:nn", "n", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	--if rv3 == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("vector2", "r:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 2 then return ret end
	return { 0, 0 }
end)

registerFunction("setVector2", "r:nxv2", "xv2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("vector", "r:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if (type(ret) == "table" and table.getn(ret) == 3) or type(ret) == "Vector" then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setVector", "r:nv", "v", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	--if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("vector4", "r:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0, 0, 0 }
end)

registerFunction("setVector4", "r:nxv4", "xv4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("angle", "r:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("setAngle", "r:na", "a", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	--if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("matrix2", "r:n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0,
			 0, 0 }
end)

registerFunction("setMatrix2", "r:nxm2", "xm2", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("matrix", "r:n", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 9 then return ret end
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

registerFunction("setMatrix", "r:nm", "m", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("matrix4", "r:n", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if type(ret) == "table" and table.getn(ret) == 16 then return ret end
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end)

registerFunction("setMatrix4", "r:nxm4", "xm4", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("string", "r:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("setString", "r:ns", "s", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	--if rv3 == "" then rv3 = nil end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

registerFunction("entity", "r:n", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = rv1[rv2]
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("setEntity", "r:ne", "e", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if(rv2 >= E2_MAX_ARRAY_SIZE) then return end
	rv1[rv2] = rv3
	self.vclk[rv1] = true
	return rv3
end)

/******************************************************************************/

registerFunction("pushNumber", "r:n", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if (rv2 == 0) then rv2 = nil end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popNumber", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if ret then return tonumber(ret) or 0 end
	return 0
end)

registerFunction("pushVector2", "r:xv2", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popVector2", "r:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 2 then return ret end
	return { 0, 0 }
end)

registerFunction("pushVector", "r:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popVector", "r:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if (type(ret) == "table" and table.getn(ret) == 3) or type(ret) == "Vector" then return ret end
	return { 0, 0, 0 }
end)

registerFunction("pushVector4", "r:xv4", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popVector4", "r:", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0, 0, 0 }
end)

registerFunction("pushAngle", "r:a", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popAngle", "r:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("pushMatrix2", "r:xm2", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popMatrix2", "r:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0,
			 0, 0 }
end)

registerFunction("pushMatrix", "r:m", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popMatrix", "r:", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 9 then return ret end
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

registerFunction("pushMatrix4", "r:xm4", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popMatrix4", "r:", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 16 then return ret end
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end)

registerFunction("pushString", "r:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if (rv2 == "") then rv2 = nil end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popString", "r:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("pushEntity", "r:e", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popEntity", "r:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("pushComplex", "r:c", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 then rv2 = nil end
	table.insert(rv1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("popComplex", "r:", "c", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1)
	self.vclk[rv1] = true
	if (type(ret) == "table" and table.getn(ret) == 2) then return ret end
	return { 0, 0, 0 }
end)

registerFunction("pop", "r:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	table.remove(rv1)
	self.vclk[rv1] = true
end)

/******************************************************************************/

registerFunction("insertNumber", "r:nn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	--if (rv3 == 0) then rv3 = nil end
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeNumber", "r:n", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if ret then return tonumber(ret) or 0 end
	return 0
end)

registerFunction("insertVector2", "r:nxv2", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeVector2", "r:n", "xv2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 2 then return ret end
	return { 0, 0 }
end)

registerFunction("insertVector", "r:nv", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	--if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeVector", "r:n", "v", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if (type(ret) == "table" and table.getn(ret) == 3) or type(ret) == "Vector" then return ret end
	return { 0, 0, 0 }
end)

registerFunction("insertVector4", "r:nxv4", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeVector4", "r:n", "xv4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0, 0, 0 }
end)

registerFunction("insertAngle", "r:na", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	--if rv3[1] == 0 and rv3[2] == 0 and rv3[3] == 0 then rv3 = nil end
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeAngle", "r:n", "a", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("insertMatrix2", "r:nxm2", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeMatrix2", "r:n", "xm2", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0,
			 0, 0 }
end)

registerFunction("insertMatrix", "r:nm", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeMatrix", "r:n", "m", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 9 then return ret end
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

registerFunction("insertMatrix4", "r:nxm4", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeMatrix4", "r:n", "xm4", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 16 then return ret end
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end)

registerFunction("insertString", "r:ns", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	--if (rv3 == "") then rv3 = nil end
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeString", "r:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("insertEntity", "r:ne", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	if rv2 < 0 then return end --table.insert won't work for negative numbers
	table.insert(rv1,rv2,rv3)
	self.vclk[rv1] = true
end)

registerFunction("removeEntity", "r:n", "e", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	local ret = table.remove(rv1,rv2)
	self.vclk[rv1] = true
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("remove", "r:n", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	table.remove(rv1,rv2)
	self.vclk[rv1] = true
end)

/******************************************************************************/

registerFunction("unshiftNumber", "r:n", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if (rv2 == 0) then rv2 = nil end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftNumber", "r:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if ret then return tonumber(ret) or 0 end
	return 0
end)

registerFunction("unshiftVector2", "r:xv2", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftVector2", "r:", "xv2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 2 then return ret end
	return { 0, 0 }
end)

registerFunction("unshiftVector", "r:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftVector", "r:", "v", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if (type(ret) == "table" and table.getn(ret) == 3) or type(ret) == "Vector" then return ret end
	return { 0, 0, 0 }
end)

registerFunction("unshiftVector4", "r:xv4", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftVector4", "r:", "xv4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0, 0, 0 }
end)

registerFunction("unshiftAngle", "r:a", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 and rv2[3] == 0 then rv2 = nil end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftAngle", "r:", "a", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 3 then return ret end
	return { 0, 0, 0 }
end)

registerFunction("unshiftMatrix2", "r:xm2", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftMatrix2", "r:", "xm2", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 4 then return ret end
	return { 0, 0,
			 0, 0 }
end)

registerFunction("unshiftMatrix", "r:m", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftMatrix", "r:", "m", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 9 then return ret end
	return { 0, 0, 0,
			 0, 0, 0,
			 0, 0, 0 }
end)

registerFunction("unshiftMatrix4", "r:xm4", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftMatrix4", "r:", "xm4", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if type(ret) == "table" and table.getn(ret) == 16 then return ret end
	return { 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0,
			 0, 0, 0, 0 }
end)

registerFunction("unshiftString", "r:s", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if (rv2 == "") then rv2 = nil end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftString", "r:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if ret then return tostring(ret) end
	return ""
end)

registerFunction("unshiftEntity", "r:e", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftEntity", "r:", "e", function(self, args)
	local op1 = args[2]
	local rv1= op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if validEntity(ret) then return ret end
	return nil
end)

registerFunction("shift", "r:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	table.remove(rv1,1)
	self.vclk[rv1] = true
end)

registerFunction("unshiftComplex", "r:c", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if ((table.getn(rv1)+1) >= E2_MAX_ARRAY_SIZE) then return end
	--if rv2[1] == 0 and rv2[2] == 0 then rv2 = nil end
	table.insert(rv1,1,rv2)
	self.vclk[rv1] = true
end)

registerFunction("shiftComplex", "r:", "c", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local ret = table.remove(rv1,1)
	self.vclk[rv1] = true
	if (type(ret) == "table" and table.getn(ret) == 2) then return ret end
	return { 0, 0, 0 }
end)

/*********************** Now leaving the code of horror ***********************/

e2function number array:sum()
	local out = 0

	self.prf = self.prf + #this / 2

	for _,value in ipairs(this) do
		out = out + (tonumber(value) or 0)
	end
	return out
end

e2function number array:average()
	local totalValue = 0
	local totalIndex = 0
	local averageValue = 0

	self.prf = self.prf + #this / 2

	for k,v in ipairs(this) do
		if type( v ) == "number" then
			totalValue = totalValue + this[k]
			totalIndex = totalIndex + 1
		end
	end
	averageValue = totalValue / totalIndex
	return averageValue
end

e2function number array:min()
	local min = nil

	self.prf = self.prf + #this / 2

	for k,v in ipairs(this) do
		if type( v ) == "number" then
			if min == nil || v < min then
				min = this[k]
			end
		end
	end
	if min == nil then min = 0 end
	local ret = min
	min = nil
	return ret
end

e2function number array:minIndex()
	local minIndex = 0
	local min = nil

	self.prf = self.prf + #this / 2

	for k,v in ipairs(this) do
		if type( v ) == "number" then
			if min == nil || v < min then
				min = this[k]
				minIndex = k
			end
		end
	end
	if min == nil then min = 0 end
	local ret = minIndex
	min = nil
	return ret
end

e2function number array:max()
	local ret = 0

	self.prf = self.prf + #this / 2

	for k,v in ipairs(this) do
		if type( v ) == "number" then
			if v > ret then
				ret = this[k]
			end
		end
	end
	return ret
end

e2function number array:maxIndex()
	local retIndex = 0
	local ret = 0

	self.prf = self.prf + #this / 2

	for k,v in ipairs(this) do
		if type( v ) == "number" then
			if v > ret then
				ret = this[k]
				retIndex = k
			end
		end
	end
	return retIndex
end

/******************************************************************************/

e2function string array:concat()
	local out = ""

	self.prf = self.prf + #this

	for _,value in ipairs(this) do
		out = out .. tostring(value)
	end
	return out
end

e2function string array:concat(string delimiter)
	local out = ""

	self.prf = self.prf + #this

	for _,value in ipairs(this) do
		out = out .. tostring(value) .. delimiter
	end
	return string.Left(out, string.len(out) - string.len(delimiter))
end

__e2setcost(nil) -- temporary
