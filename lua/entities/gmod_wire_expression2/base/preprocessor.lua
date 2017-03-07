--[[
  Expression 2 Pre-Processor for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

AddCSLuaFile()

PreProcessor = {}
PreProcessor.__index = PreProcessor

function PreProcessor.Execute(...)
	-- instantiate PreProcessor
	local instance = setmetatable({}, PreProcessor)

	-- and pcall the new instance's Process method.
	return xpcall(instance.Process, E2Lib.errorHandler, instance, ...)
end

function PreProcessor:Error(message, column)
	error(message .. " at line " .. self.readline .. ", char " .. (column or 1), 0)
end

local type_map = {
	v4 = "xv4",
	v2 = "xv2",
	m4 = "xm4",
	m2 = "xm2",
	rd = "xrd",
	wl = "xwl",
	number = "n",
}
local function gettype(tp)
	tp = tp:Trim():lower()
	local up = tp:upper()
	return type_map[tp] or (wire_expression_types[up] and wire_expression_types[up][1]) or tp
end

function PreProcessor:HandlePPCommand(comment)
	local command, args = comment:match("^([^ ]*) ?(.*)$")
	local handler = self["PP_" .. command]
	if handler then return handler(self, args) end
end

function PreProcessor:FindComments(line)
	local ret, count, pos, found = {}, 0, 1, nil
	repeat
		found = line:find('[#"\\]', pos)
		if found then -- We found something
			local char = line:sub(found, found)
			if char == "#" then -- We found a comment
				local before = line:sub(found - 1, found - 1)
				if before == "]" then -- We found an ending
					count = count + 1
					ret[count] = { type = "end", pos = found - 1 }
					pos = found + 1
				else
					local after = line:sub(found + 1, found + 1)
					if after == "[" then -- We found a start
						count = count + 1
						ret[count] = { type = "start", pos = found }
						pos = found + 2
					else -- We found a normal comment
						count = count + 1
						ret[count] = { type = "normal", pos = found }
						pos = found + 1
					end
				end
			elseif char == '"' then -- We found a string
				local before = line:sub(found - 1, found - 1)
				count = count + 1
				ret[count] = { type = "string", pos = found }
				pos = found + 1
			elseif char == '\\' then -- We found an escape character
				pos = found + 2 -- Skip the escape character and the character following it
			end
		end
		until (not found)
	return ret, count
end

function PreProcessor:RemoveComments(line)

	local comments, num = self:FindComments(line) -- Find all comments and strings on this line

	if num == 0 and self.blockcomment then
		return ""
	end

	local prev_disabled, ret, lastpos = self.disabled, "", 1

	for i = 1, num do
		local type = comments[i].type
		if type == "string" and not self.blockcomment then -- Is it a string?
			self.multilinestring = not self.multilinestring
		elseif not self.multilinestring then -- Else it's a comment if we're not inside a multiline string
			if self.blockcomment then -- Time to look for a ]#
				if type == "end" then -- We found one
					local pos = comments[i].pos
					ret = ret .. (" "):rep(pos - lastpos + 4) -- Replace the stuff in between with spaces
					lastpos = pos + 2
					self.blockcomment = nil -- We're no longer in a block comment
				end
			else -- Time to look for a #[
				if type == "start" then -- We found one
					local pos = comments[i].pos
					ret = ret .. line:sub(lastpos, pos - 1)
					lastpos = pos + 2
					self.blockcomment = true -- We're now inside a block comment
				elseif type == "normal" then -- We found a # instead
					local pos = comments[i].pos
					if line:sub(pos + 1, pos + 7) == "include" then
						ret = ret .. line:sub(lastpos)
					else
						ret = ret .. line:sub(lastpos, pos - 1)
						self:HandlePPCommand(line:sub(pos + 1))
					end

					lastpos = -1
					break -- Don't care what comes after
				end
			end
		end
	end

	if prev_disabled then
		return ""
	elseif lastpos ~= -1 and not self.blockcomment then
		return ret .. line:sub(lastpos, -1)
	else
		return ret
	end
end

function PreProcessor:ParseDirectives(line)
	if self.multilinestring then return line end

	-- parse directive
	local directive, value = line:match("^@([^ ]*) ?(.*)$")

	-- not a directive?
	if not directive then
		-- flag as "in code", if that is the case
		if string.Trim(line) ~= "" then
			self.incode = true
		end
		-- don't handle as a directive.
		return line
	end

	local col = directive:find("[A-Z]")
	if col then self:Error("Directive (@" .. E2Lib.limitString(directive, 10) .. ") must be lowercase", col + 1) end
	if self.incode then self:Error("Directive (@" .. E2Lib.limitString(directive, 10) .. ") must appear before code") end

	-- evaluate directive
	if directive == "name" then
		if not self.ignorestuff then
			if self.directives.name == nil then
				self.directives.name = value
			else
				self:Error("Directive (@name) must not be specified twice")
			end
		end
	elseif directive == "model" then
		if not self.ignorestuff then
			if self.directives.model == nil then
				self.directives.model = value
			else
				self:Error("Directive (@model) must not be specified twice")
			end
		end
	elseif directive == "inputs" then
		local retval, columns = self:ParsePorts(value, #directive + 2)

		for i, key in ipairs(retval[1]) do
			if self.directives.inputs[3][key] then
				self:Error("Directive (@input) contains multiple definitions of the same variable", columns[i])
			else
				local index = #self.directives.inputs[1] + 1
				self.directives.inputs[1][index] = key
				self.directives.inputs[2][index] = retval[2][i]
				self.directives.inputs[3][key] = retval[2][i]
			end
		end
	elseif directive == "outputs" then
		local retval, columns = self:ParsePorts(value, #directive + 2)

		for i, key in ipairs(retval[1]) do
			if self.directives.outputs[3][key] then
				self:Error("Directive (@output) contains multiple definitions of the same variable", columns[i])
			else
				local index = #self.directives.outputs[1] + 1
				self.directives.outputs[1][index] = key
				self.directives.outputs[2][index] = retval[2][i]
				self.directives.outputs[3][key] = retval[2][i]
			end
		end
	elseif directive == "persist" then
		local retval, columns = self:ParsePorts(value, #directive + 2)

		for i, key in ipairs(retval[1]) do
			if self.directives.persist[3][key] then
				self:Error("Directive (@persist) contains multiple definitions of the same variable", columns[i])
			else
				local index = #self.directives.persist[1] + 1
				self.directives.persist[1][index] = key
				self.directives.persist[2][index] = retval[2][i]
				self.directives.persist[3][key] = retval[2][i]
			end
		end
	elseif directive == "trigger" then
		local trimmed = string.Trim(value)
		if trimmed == "" then
		elseif trimmed == "all" then
			if self.directives.trigger[1] ~= nil then
				self:Error("Directive (@trigger) conflicts with previous directives")
			end
			self.directives.trigger[1] = true
		elseif trimmed == "none" then
			if self.directives.trigger[1] ~= nil then
				self:Error("Directive (@trigger) conflicts with previous directives")
			end
			self.directives.trigger[1] = false
		else
			if self.directives.trigger[1] ~= nil and #self.directives.trigger[2] == 0 then
				self:Error("Directive (@trigger) conflicts with previous directives")
			end

			self.directives.trigger[1] = false
			local retval, columns = self:ParsePorts(value, #directive + 2)

			for i, key in ipairs(retval[1]) do
				if self.directives.trigger[2][key] then
					self:Error("Directive (@trigger) contains multiple definitions of the same variable", columns[i])
				else
					self.directives.trigger[2][key] = true
				end
			end
		end
	elseif directive == "autoupdate" then
		if CLIENT then return "" end
		if not IsValid( self.ent ) or not self.ent.duped or not self.ent.filepath or self.ent.filepath == "" then return "" end
		WireLib.Expression2Upload( self.ent:GetPlayer(), self.ent, self.ent.filepath )
	else
		self:Error("Unknown directive found (@" .. E2Lib.limitString(directive, 10) .. ")", 2)
	end

	-- remove line from output
	return ""
end

function PreProcessor:Process(buffer, directives, ent)
	-- entity is needed for autoupdate
	self.ent = ent

	local lines = string.Explode("\n", buffer)

	if not directives then
		self.directives = {
			name = nil,
			model = nil,
			inputs = { {}, {}, {} },
			outputs = { {}, {}, {} },
			persist = { {}, {}, {} },
			delta = { {}, {}, {} },
			trigger = { nil, {} },
			rawinputs = {}
		}
	else
		self.directives = directives
		self.ignorestuff = true
	end

	for i, line in ipairs(lines) do
		self.readline = i
		line = string.TrimRight(line)

		line = self:RemoveComments(line)
		line = self:ParseDirectives(line)

		lines[i] = line
	end

	if self.directives.trigger[1] == nil then self.directives.trigger[1] = true end
	if not self.directives.name then self.directives.name = "" end

	return self.directives, string.Implode("\n", lines)
end

function PreProcessor:ParsePorts(ports, startoffset)
	local names = {}
	local types = {}
	local columns = {}

	-- Preprocess [Foo Bar]:entity into [Foo,Bar]:entity so we don't have to deal with split-up multi-variable definitions in the main loop
	ports = ports:gsub("%[.-%]", function(s)
		return s:gsub(" ", ",")
	end)

	for column, key in ports:gmatch("()([^ ]+)") do
		column = startoffset + column
		key = key:Trim()

		-------------------------------- variable names --------------------------------

		-- single-variable definition?
		local _, i, namestring = key:find("^([A-Z][A-Za-z0-9_]*)")
		if i then
			-- yes -> add the variable
			names[#names + 1] = namestring
		else
			-- no -> maybe a multi-variable definition?
			_, i, namestring = key:find("^%[([^]]+)%]")
			if not i then
				-- no -> malformed variable name
				self:Error("Variable name (" .. E2Lib.limitString(key, 10) .. ") must start with an uppercase letter", column)
			end
			-- yes -> add all variables.
			for column2, var in namestring:gmatch("()([^,]+)") do
				column2 = column + column2
				var = string.Trim(var)
				-- skip empty entries
				if var ~= "" then
					-- error on malformed variable names
					if not var:match("^[A-Z]") then self:Error("Variable name (" .. E2Lib.limitString(var, 10) .. ") must start with an uppercase letter", column2) end
					local errcol = var:find("[^A-Za-z0-9_]")
					if errcol then self:Error("Variable declaration (" .. E2Lib.limitString(var, 10) .. ") contains invalid characters", column2 + errcol - 1) end
					-- and finally add the variable.
					names[#names + 1] = var
				end
			end
		end

		-------------------------------- variable types --------------------------------

		local vtype
		local character = key:sub(i + 1, i + 1)
		if character == ":" then
			-- type is specified -> check for validity
			vtype = key:sub(i + 2)

			if vtype ~= vtype:lower() then
				self:Error("Variable type [" .. E2Lib.limitString(vtype, 10) .. "] must be lowercase", column + i + 1)
			end

			if vtype == "number" then vtype = "normal" end

			if not wire_expression_types[vtype:upper()] then
				self:Error("Unknown variable type [" .. E2Lib.limitString(vtype, 10) .. "] specified for variable(s) (" .. E2Lib.limitString(namestring, 10) .. ")", column + i + 1)
			end
		elseif character == "" then
			-- type is not specified -> default to NORMAL
			vtype = "NORMAL"
		else
			-- invalid -> raise an error
			self:Error("Variable declaration (" .. E2Lib.limitString(key, 10) .. ") contains invalid characters", column + i)
		end

		-- fill in the missing types
		for i = #types + 1, #names do
			types[i] = vtype:upper()
			columns[i] = column
		end
	end

	return { names, types }, columns
end

function PreProcessor:PP_ifdef(args)
	if self.disabled ~= nil then self:Error("Found nested #ifdef") end
	local thistype, colon, name, argtypes = args:match("([^:]-)(:?)([^:(]+)%(([^)]*)%)")
	if not thistype or (thistype ~= "") ~= (colon ~= "") then self:Error("Malformed #ifdef argument " .. args) end

	thistype = gettype(thistype)

	local tps = { thistype .. colon }
	for i, argtype in ipairs(string.Explode(",", argtypes)) do
		argtype = gettype(argtype)
		table.insert(tps, argtype)
	end
	local pars = table.concat(tps)
	local a = wire_expression2_funcs[name .. "(" .. pars .. ")"]

	self.disabled = not a
end

function PreProcessor:PP_ifndef(args)
	local ret = self:PP_ifdef(args)
	self.disabled = not self.disabled
	return ret
end

function PreProcessor:PP_else(args)
	if self.disabled == nil then self:Error("Found #else outside #ifdef block") end
	if args:Trim() ~= "" then self:Error("Must not pass an argument to #else") end
	self.disabled = not self.disabled
end

function PreProcessor:PP_endif(args)
	if self.disabled == nil then self:Error("Found #endif outside #ifdef block") end
	if args:Trim() ~= "" then self:Error("Must not pass an argument to #endif") end
	self.disabled = nil
end
