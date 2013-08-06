local eliminate_varname_conflicts = true

if not e2_parse_args then include("extpp.lua") end

local readfile = readfile or function(filename)
	return file.Read("entities/gmod_wire_expression2/core/" .. filename, "LUA")
end
local writefile = writefile or function(filename, contents)
	print("--- Writing to file 'data/e2doc/" .. filename .. "' ---")
	return file.Write("e2doc/" .. filename, contents)
end
local p_typename = "[a-z][a-z0-9]*"
local p_typeid = "[a-z][a-z0-9]?[a-z0-9]?[a-z0-9]?[a-z0-9]?"
local p_argname = "[a-zA-Z][a-zA-Z0-9]*"
local p_funcname = "[a-z][a-zA-Z0-9]*"
local p_func_operator = "[-a-zA-Z0-9+*/%%^=!><&|$_]*"

local function ltrim(s)
	return string.match(s, "^%s*(.-)$")
end

local function rtrim(s)
	return string.match(s, "^(.-)%s*$")
end

local function trim(s)
	return string.match(s, "^%s*(.-)%s*$")
end

local mess_with_args

function mess_with_args(args, desc, thistype)
	local args_referenced = string.match(desc, "<" .. p_argname .. ">")
	local argtable, ellipses = e2_parse_args(args)
	local indices = {}
	if thistype ~= "" then indices[string.upper(e2_get_typeid(thistype))] = 2 end
	args = ''
	for i, name in ipairs(argtable.argnames) do
		local typeid = string.upper(argtable.typeids[i])

		local index = ""
		if args_referenced then
			index = indices[typeid]
			if index then
				indices[typeid] = index + 1
			else
				index = ""
				indices[typeid] = 2
			end
		end
		local newname = typeid .. "<sub>" .. index .. "</sub>"
		if index == "" then newname = typeid end

		desc = desc:gsub("<" .. name .. ">", "''" .. newname .. "''")
		if i ~= 1 then args = args .. "," end
		args = args .. newname
	end
	if ellipses then
		if #argtable.argnames ~= 0 then args = args .. "," end
		args = args .. "..."
	end
	return args, desc
end

local function e2doc(filename, outfile)
	if not outfile then
		outfile = string.match(filename, "^.*%.") .. "txt"
	end
	local current = {}
	local output = { '====Commands====\n:{|style="background:#E6E6FA"\n!align="left" width="150"| Function\n!align="left" width="60"| Returns\n!align="left" width="1000"| Description\n' }
	local insert_line = true
	for line in string.gmatch(readfile(filename), "%s*(.-)%s*\n") do
		if line:sub(1, 3) == "---" then
			if line:match("[^-%s]") then table.insert(current, ltrim(line:sub(4))) end
		elseif line:sub(1, 3) == "///" then
			table.insert(current, ltrim(line:sub(4)))
		elseif line:sub(1, 12) == "--[[********" or line:sub(1, 9) == "/********" then
			if line:find("^%-%-%[%[%*%*%*%*%*%*%*%*+%]%]%-%-$") or line:find("^/%*%*%*%*%*%*%*%*+/$") then
				insert_line = true
			end
		elseif line:sub(1, 10) == "e2function" then
			local ret, thistype, colon, name, args = line:match("e2function%s+(" .. p_typename .. ")%s+([a-z0-9]-)%s*(:?)%s*(" .. p_func_operator .. ")%(([^)]*)%)")
			if thistype ~= "" and colon == "" then error("E2doc syntax error: Function names may not start with a number.", 0) end
			if thistype == "" and colon ~= "" then error("E2doc syntax error: No type for 'this' given.", 0) end
			if thistype:sub(1, 1):find("[0-9]") then error("E2doc syntax error: Type names may not start with a number.", 0) end

			desc = table.concat(current, "<br />")
			current = {}

			if name:sub(1, 8) ~= "operator" and not desc:match("@nodoc") then
				if insert_line then
					table.insert(output, '|-\n| bgcolor="SteelBlue" |  || bgcolor="SteelBlue" |  || bgcolor="SteelBlue" | \n')
					insert_line = false
				end
				args, desc = mess_with_args(args, desc, thistype)

				if ret == "void" then
					ret = ""
				else
					ret = string.upper(e2_get_typeid(ret))
				end

				if thistype ~= "" then
					thistype = string.upper(e2_get_typeid(thistype))
					desc = desc:gsub("<this>", "''" .. thistype .. "''")
					thistype = thistype .. ":"
				end
				table.insert(output, string.format("|-\n|%s%s(%s) || %s || ", thistype, name, args, ret))
				--desc = desc:gsub("<([^<>]+)>", "''%1''")
				table.insert(output, desc)
				table.insert(output, "\n")
			end
		end
	end -- for line
	output = table.concat(output) .. "|}\n"
	print(output)
	writefile(outfile, output)
end

-- Add a client-side "e2doc" console command
if SERVER then
	AddCSLuaFile()
	e2doc = nil
elseif CLIENT then
	concommand.Add("e2doc",
		function(player, command, args)
			if not file.IsDir("e2doc", "DATA") then file.CreateDir("e2doc") end
			if not file.IsDir("e2doc/custom", "DATA") then file.CreateDir("e2doc/custom") end

			local path = string.match(args[2] or args[1], "^%s*(.+)/")
			if path and not file.IsDir("e2doc/" .. path, "DATA") then file.CreateDir("e2doc/" .. path) end

			e2doc(args[1], args[2])
		end,
		function(commandName, args) -- autocomplete function
			args = string.match(args, "^%s*(.-)%s*$")
			local path = string.match(args, "^%s*(.+/)") or ""
			local files = file.Find("entities/gmod_wire_expression2/core/" .. args .. "*", "LUA")
			local ret = {}
			for _, v in ipairs(files) do
				if string.sub(v, 1, 1) ~= "." then
					if file.IsDir("entities/gmod_wire_expression2/core/" .. path .. v, "LUA") then
						table.insert(ret, "e2doc " .. path .. v .. "/")
					else
						table.insert(ret, "e2doc " .. path .. v)
					end
				end
			end
			return ret
		end)
end