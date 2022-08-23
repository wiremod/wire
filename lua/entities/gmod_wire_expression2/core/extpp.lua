AddCSLuaFile()

-- some constants --

local p_typename = "[a-z][a-z0-9]*"
local p_typeid = "[a-z][a-z0-9]?[a-z0-9]?[a-z0-9]?[a-z0-9]?"
local p_argname = "[a-zA-Z][a-zA-Z0-9_]*"
local p_funcname = "[a-z][a-zA-Z0-9]*"
local p_func_operator = "[-a-zA-Z0-9+*/%%^=!><&|$_%[%]]*"

local OPTYPE_FUNCTION
local OPTYPE_NORMAL = 0
local OPTYPE_DONT_FETCH_FIRST = 1
local OPTYPE_ASSIGN = 2
local OPTYPE_APPEND_RET = 3

local optable = {
	["operator+"] = "add",
	["operator++"] = { "inc", OPTYPE_DONT_FETCH_FIRST },
	["operator-"] = "sub",
	["operator--"] = { "dec", OPTYPE_DONT_FETCH_FIRST },
	["operator*"] = "mul",
	["operator/"] = "div",
	["operator%"] = "mod",
	["operator^"] = "exp",
	["operator="] = { "ass", OPTYPE_ASSIGN },
	["operator=="] = "eq",
	["operator!"] = "not",
	["operator!="] = "neq",
	["operator>"] = "gth",
	["operator>="] = "geq",
	["operator<"] = "lth",
	["operator<="] = "leq",
	["operator&"] = "and",
	["operator&&"] = "and",
	["operator|"] = "or",
	["operator||"] = "or",
	["operator[]"] = "idx", -- typeless op[]
	["operator[T]"] = { "idx", OPTYPE_APPEND_RET }, -- typed op[]

	["operator_is"] = "is",
	["operator_neg"] = "neg",
	["operator_band"] = "band",
	["operator_bor"] = "bor",
	["operator_bxor"] = "bxor",
	["operator_bshl"] = "bshl",
	["operator_bshr"] = "bshr",
}

-- This is an array for types that were parsed from all E2 extensions.
local preparsed_types

E2Lib.ExtPP = {}

-- This function initialized extpp's dynamic fields
function E2Lib.ExtPP.Init()
	-- We initialize the array of preparsed types  with an alias "number" for "normal".
	preparsed_types = { ["NUMBER"] = "n" }
end

-- This function checks whether its argument is a valid type id.
local function isValidTypeId(typeid)
	return (typeid:match("^[a-wy-zA-WY-Z]$") or typeid:match("^[xX][a-wy-zA-WY-Z0-9][a-wy-zA-WY-Z0-9]$")) and true
end

-- Returns the typeid associated with the given typename
local function getTypeId(typename)
	local n = string.upper(typename)

	-- was the type registered with E-2?
	if wire_expression_types[n] then return wire_expression_types[n][1] end

	-- was the name found when looking for registerType lines?
	if preparsed_types[n] then return preparsed_types[n] end

	-- is the type name a valid typeid? use the type name as the typeid
	if isValidTypeId(typename) then return typename end
end

---@class ArgsKind
local ArgsKind = {
	None = 0,
	Static = 1,
	Variadic = 2,
	VariadicTbl = 3
}

-- parses an argument list
---@return { typeids: string[], argnames: string[] }, integer, string?
local function parseArgs(args)
	local argtable = { typeids = {}, argnames = {} }
	if args:find("%S") == nil then return argtable, ArgsKind.None end -- no arguments

	local args = args:Split(",")
	local len = #args

	for k, arg in ipairs(args) do
		-- is this argument an ellipsis?
		if arg:match( "^%s*%.%.%.%s*$") then
			assert(k == len, "PP syntax error: Ellipses (...) must be the last argument.")
			return argtable, ArgsKind.Variadic
		else
			local name = arg:match("^%s*%.%.%.(%w+)%s*$")
			if name then
				assert(k == len, "PP syntax error: Ellipses table (..." .. name .. ") must be the last argument.")

				-- assert(name ~= "args" and name ~= "typeids" and name ~= "self", "PP syntax error: Variadic table name shadows internal variable (" .. name .. ")")

				return argtable, ArgsKind.VariadicTbl, name
			end
		end

		-- assume a type name was given and split up the argument into type name and argument name.
		local typename, argname = string.match(arg, "^%s*(" .. p_typename .. ")%s+(" .. p_argname .. ")%s*$")

		-- the assumption failed
		if not typename then
			-- try looking for a argument name only and defaulting the type name to "number"
			argname = string.match(arg, "^%s*(" .. p_argname .. ")%s*$")
			typename = "number"
		end

		-- this failed as well? give up and print an error
		assert(argname, "PP syntax error: Invalid function parameter syntax.")

		local typeid = assert(getTypeId(typename), "PP syntax error: Invalid parameter type '" .. typename .. "' for argument '" .. argname .. "'.")

		argtable.typeids[k] = typeid
		argtable.argnames[k] = argname
	end

	return argtable, ArgsKind.Static
end

local function mangle(name, arg_typeids, op_type)
	if op_type then name = "operator_" .. name end
	local ret = "e2_" .. name
	if arg_typeids == "" then return ret end
	return ret .. "_" .. arg_typeids:gsub("[:=]", "_")
end

local function linenumber(s, i)
	local c = 1
	local line = 0
	while c and c < i do
		line = line + 1
		c = s:find("\n", c + 1, true)
	end
	return line
end

-- returns a name and a register function for the given name
-- also optionally returns a flag signaling how to treat the operator in question.
local function handleop(name)
	local operator = optable[name]

	if operator then
		local op_type = OPTYPE_NORMAL

		-- special treatment is needed for some operators.
		if istable(operator) then operator, op_type = unpack(operator) end

		-- return everything.
		return operator, "registerOperator", op_type
	elseif name:find("^" .. p_funcname .. "$") then
		return name, "registerFunction", OPTYPE_FUNCTION
	else
		error("PP syntax error: Invalid character in function name.", 0)
	end
end

local function makestringtable(tbl, i, j)
	if #tbl == 0 then return "{}" end
	if not i then i = 1
	elseif i < 0 then i = #tbl + i + 1
	elseif i < 1 then i = 1
	elseif i > #tbl then i = #tbl
	end

	if not j then j = #tbl
	elseif j < 0 then j = #tbl + j + 1
	elseif j < 1 then j = 1
	elseif j > #tbl then j = #tbl
	end

	--return string.format("{"..string.rep("%q,", math.max(0,j-i+1)).."}", unpack(tbl, i, j))
	local ok, ret = pcall(string.format, "{" .. string.rep("%q,", math.max(0, j - i + 1)) .. "}", unpack(tbl, i, j))
	if not ok then
		print(i, j, #tbl, "{" .. string.rep("%q,", math.max(0, j - i + 1)) .. "}")
		error(ret)
	end
	return ret
end

function E2Lib.ExtPP.Pass1(contents)
	-- look for registerType lines and fill preparsed_types with them
	for typename, typeid in string.gmatch("\n" .. contents, '%WregisterType%(%s*"(' .. p_typename .. ')"%s*,%s*"(' .. p_typeid .. ')"') do
		preparsed_types[string.upper(typename)] = typeid
	end
end

local fmt = string.format
--- Compact lua code to a single line to avoid changing lua's tracebacks.
local function compact(lua)
	return ( lua:gsub("\n\t*", " ") )
end

function E2Lib.ExtPP.Pass2(contents)
	-- We add some stuff to both ends of the string so we can look for %W (non-word characters) at the ends of the patterns.
	local prelude = "local tempcosts, registeredfunctions = {}, {};"
	contents = ("\n" .. prelude .. contents .. "\n     ")

	-- this is a list of pieces that make up the final code
	local output = {}
	-- this is a list of registerFunction lines that will be put at the end of the file.
	local function_register = {}
	-- We start from position 2, since char #1 is always the \n we added earlier
	local lastpos = 2

	local aliaspos, aliasdata = nil, nil

	-- This flag helps determine whether the preprocessor changed, so we can tell the environment about it.
	local changed = false
	for a_begin, attributes, h_begin, ret, thistype, colon, name, args, whitespace, equals, h_end in contents:gmatch("()(%[?[%l%d,_ =\"]*%]?)\r?\n?()e2function%s+(" .. p_typename .. ")%s+([a-z0-9]-)%s*(:?)%s*(" .. p_func_operator .. ")%(([^)]*)%)(%s*)(=?)()") do
		-- Convert attributes to a lookup table passed to registerFunction
		attributes = attributes ~= "" and attributes or nil
		-- attributes = attributes ~= ""
		local attributes_str

		if attributes and attributes:sub(1, 1) == "[" and attributes:sub(-1, -1) == "]" then
			attributes_str = attributes
			attributes = attributes:sub(2, -2) -- Remove surrounding brackets
			-- [deprecated, nodiscard]
			-- e2function void test()

			attributes = attributes:Split(",")

			local lookup = {}
			for _, tag in ipairs(attributes) do
				local k = tag:lower():Trim()
				if k:find("=", 1, true) then
					-- [xyz = 567, event = "Tick"]
					-- e2function number foo()
					local key, value = unpack( k:Split("="), 1, 2 )
					key, value = key:lower():Trim(), tonumber(value:match("%d+")) or value:Trim()

					lookup[key] = value
				else
					lookup[ tag:lower():Trim() ] = "true"
				end
			end

			local buf = "{"
			for attr, val in pairs(lookup) do
				buf = buf .. "['" .. attr .. "'] = " .. val .. ","
			end

			attributes = buf .. "}"
		else
			attributes = "{}"
		end

		changed = true

		local function handle_function()
			if contents:sub(h_begin - 1, h_begin - 1):match("%w") then return end
			local aliasflag = nil
			if equals == "" then
				if aliaspos then
					if contents:sub(aliaspos, h_begin - 1):find("%S") then error("PP syntax error: Malformed alias definition.", 0) end
					-- right hand side of an alias assignment
					aliasflag = 2
					aliaspos = nil
				end
			else
				if aliaspos then error("PP syntax error: Malformed alias definition.", 0) end
				-- left hand side of an alias assignment
				aliasflag = 1
				aliaspos = h_end
			end

			-- check for some obvious errors
			if thistype ~= "" and colon == "" then error("PP syntax error: Function names may not start with a number.", 0) end
			if thistype == "" and colon ~= "" then error("PP syntax error: No type for 'this' given.", 0) end
			if thistype:match("^[0-9]") then error("PP syntax error: Type names may not start with a number.", 0) end

			-- append everything since the last function to the output.
			if attributes_str then
				table.insert(output, contents:sub(lastpos, a_begin - 1))
				table.insert(output, "--" .. attributes_str .. "\n")
			else
				table.insert(output, contents:sub(lastpos, h_begin - 1))
			end

			-- advance lastpos to the end of the function header
			lastpos = h_end

			-- this table contains the arguments in the following form:
			-- argtable.argname[n] = "<argument #n name>"
			-- argtable.typeids[n] = "<argument #n typeid>"
			local argtable, args_kind, args_varname = parseArgs(args)

			-- take care of operators: give them a different name and register function
			-- op_type is nil if we register a function and a number if it as operator
			local name, regfn, op_type = handleop(name)

			-- return type (void means "returns nothing", i.e. "" in registerFunctionese)
			local ret_typeid = (ret == "void") and "" or getTypeId(ret)

			-- return type not found => throw an error
			if not ret_typeid then error("PP syntax error: Invalid return type: '" .. ret .. "'", 0) end

			-- if "typename:" was found in front of the function name
			if thistype ~= "" then
				-- evaluate the type name
				local this_typeid = getTypeId(thistype)

				-- the type was not found?
				if this_typeid == nil then
					-- is the type name a valid typeid?
					if isValidTypeId(thistype) then
						-- use the type name as the typeid
						this_typeid = thistype
					else
						-- type is not found and not a valid typeid => error
						error("PP syntax error: Invalid type for 'this': '" .. thistype .. "'", 0)
					end
				end

				-- prepend a "this" argument to the list, with the parsed type
				if op_type then
					-- allow pseudo-member-operators. example: e2function matrix:operator*(factor)
					table.insert(argtable.typeids, 1, this_typeid)
				else
					table.insert(argtable.typeids, 1, this_typeid .. ":")
				end
				table.insert(argtable.argnames, 1, "this")
			end -- if thistype ~= ""

			-- add a sub-table for flagging arguments as "no opfetch"
			argtable.no_opfetch = {}

			if op_type == OPTYPE_ASSIGN then -- assignment
				-- the assignment operator is registered with only argument typeid, hence we need a special case.
				-- we need to make sure the two types match:
				if argtable.typeids[1] ~= argtable.typeids[2] then error("PP syntax error: operator= needs two arguments of the same type.", 0) end

				-- remove the typeid of one of the arguments from the list
				argtable.typeids[1] = ""

				-- mark the argument as "no opfetch"
				argtable.no_opfetch[1] = true
			elseif op_type == OPTYPE_DONT_FETCH_FIRST then -- delta/increment/decrement
				-- mark the argument as "no opfetch"
				argtable.no_opfetch[1] = true
			elseif op_type == OPTYPE_APPEND_RET then
				table.insert(argtable.typeids, 1, ret_typeid .. "=")
			end

			-- -- prepare some variables needed to generate the function header and the registerFunction line -- --

			-- concatenated typeids. example: "s:nn"
			local arg_typeids = table.concat(argtable.typeids)

			-- generate a mangled name, which serves as the function's Lua name
			local mangled_name = mangle(name, arg_typeids, op_type)

			if aliasflag then
				if aliasflag == 1 then
					-- left hand side of an alias definition
					aliasdata = { regfn, name, arg_typeids, ret_typeid, attributes }
				elseif aliasflag == 2 then
					-- right hand side of an alias definition
					regfn, name, arg_typeids, ret_typeid, attributes = unpack(aliasdata)
					table.insert(function_register,
						string.format(
							'if registeredfunctions.%s then %s(%q, %q, %q, registeredfunctions.%s, tempcosts[%q], %s, %s) end\n',
							mangled_name, regfn, name, arg_typeids, ret_typeid, mangled_name, mangled_name, makestringtable(argtable.argnames, (thistype ~= "") and 2 or 1), attributes
						)
					)
				end
			else
				-- save tempcost
				table.insert(output, string.format("tempcosts[%q]=__e2getcost() ", mangled_name))
				if args_kind == ArgsKind.Variadic then
					-- generate a registerFunction line
					table.insert(function_register,
						string.format(
							'if registeredfunctions.%s then %s(%q, %q, %q, registeredfunctions.%s, tempcosts[%q], %s) end\n',
							mangled_name, regfn, name, arg_typeids .. "...", ret_typeid, mangled_name, mangled_name, makestringtable(argtable.argnames, (thistype ~= "") and 2 or 1), attributes
						)
					)

					table.insert(output, compact([[
						function registeredfunctions.]] .. mangled_name .. [[(self, args, typeids, ...)
							if not typeids then
								local arr, typeids, source_typeids, tmp = {}, {}, args[#args]
								for i = ]] .. 2 + #argtable.typeids .. [[, #args - 1 do
									tmp = args[i]

									arr[i - ]] .. 1 + #argtable.typeids .. [[] = tmp[1](self, tmp)
									typeids[i - ]] .. 1 + #argtable.typeids .. [[] = source_typeids[i - ]] .. (thistype ~= "" and 2 or 1) .. [[]
								end
								return registeredfunctions.]] .. mangled_name .. [[(self, args, typeids, unpack(arr))
							end
					]]))
				elseif args_kind == ArgsKind.VariadicTbl then
					-- generate a registerFunction line
					table.insert(function_register,
						string.format(
							'if registeredfunctions.%s then %s(%q, %q, %q, registeredfunctions.%s, tempcosts[%q], %s, %s) end\n',
							mangled_name, regfn, name, arg_typeids .. "...", ret_typeid, mangled_name, mangled_name, makestringtable(argtable.argnames, (thistype ~= "") and 2 or 1), attributes
						)
					)
					

					-- Using __varargs_priv to avoid shadowing variables like `args` and breaking this implementation.
					table.insert(output, compact([[
						function registeredfunctions.]] .. mangled_name .. [[(self, args, typeids, __varargs_priv)
							if not typeids then
								__varargs_priv, typeids = {}, {}
								local source_typeids, tmp = args[#args]
								for i = ]] .. 2 + #argtable.typeids .. [[, #args - 1 do
									tmp = args[i]
									__varargs_priv[i - ]] .. 1 + #argtable.typeids .. [[] = tmp[1](self, tmp)
									typeids[i - ]] .. 1 + #argtable.typeids .. [[] = source_typeids[i - ]] .. (thistype ~= "" and 2 or 1) .. [[]
								end
							end

							]] .. (#argtable.argnames == 0 and ("local " .. args_varname .. " = __varargs_priv") or "") .. [[
					]]))
				else
					-- generate a registerFunction line
					table.insert(function_register,
						string.format(
							'if registeredfunctions.%s then %s(%q, %q, %q, registeredfunctions.%s, tempcosts[%q], %s, %s) end\n',
							mangled_name, regfn, name, arg_typeids, ret_typeid, mangled_name, mangled_name, makestringtable(argtable.argnames, (thistype ~= "") and 2 or 1), attributes
						)
					)

					-- generate a new function header and append it to the output
					table.insert(output, 'function registeredfunctions.' .. mangled_name .. '(self, args)')
				end

				-- if the function has arguments, insert argument fetch code
				if #argtable.argnames ~= 0 then
					local argfetch, opfetch_l, opfetch_r = '', '', ''
					for i, name in ipairs(argtable.argnames) do
						if not argtable.no_opfetch[i] then
							-- generate opfetch code if not flagged as "no opfetch"
							opfetch_l = string.format('%s%s, ', opfetch_l, name)
							opfetch_r = string.format('%s%s[1](self, %s), ', opfetch_r, name, name)
						end
						argfetch = string.format('%sargs[%d], ', argfetch, i + 1)
					end

					-- remove the trailing commas
					argfetch = argfetch:sub(1, -3)
					opfetch_l = opfetch_l:sub(1, -3)
					opfetch_r = opfetch_r:sub(1, -3)

					-- fetch the rvs from the args
					table.insert(output, string.format(' local %s = %s %s = %s',
						table.concat(argtable.argnames, ', '),
						argfetch,
						opfetch_l,
						opfetch_r))

					-- Workaround if someone names their variadic args an internally used variable
					if args_kind == ArgsKind.VariadicTbl then
						table.insert(output, " local " .. args_varname .. " = __varargs_priv")
					end
				end -- if #argtable.argnames ~= 0
			end -- if aliasflag
			table.insert(output, whitespace)
		end

		-- use pcall, so we can add line numbers to all errors
		local ok, msg = pcall(handle_function)
		if not ok then
			if msg:sub(1, 2) == "PP" then
				error(":" .. linenumber(contents, h_begin) .. ": " .. msg, 0)
			else
				error(": PP internal error: " .. msg, 0)
			end
		end
	end -- for contents:gmatch(e2function)


	-- did the preprocessor change anything?
	if changed then
		-- yes => sweep everything together into a neat pile of hopefully valid lua code
		return table.concat(output) .. contents:sub(lastpos, -6) .. table.concat(function_register)
	else
		-- no => tell the environment about it, so it can include() the source file instead.
		return false
	end
end
