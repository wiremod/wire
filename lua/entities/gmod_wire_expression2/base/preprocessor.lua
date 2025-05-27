--[[
	Expression 2 Pre-Processor
	Andreas "Syranide" Svensson, me@syranide.com
]]

AddCSLuaFile()

local Warning, Error, Trace = E2Lib.Debug.Warning, E2Lib.Debug.Error, E2Lib.Debug.Trace

---@class PreProcessor
---@field blockcomment boolean # Whether preprocessor is inside a block comment
---@field multilinestring boolean # Whether preprocessor is inside a multiline string
---@field readline integer
---@field warnings Warning[]
---@field errors Error[]
local PreProcessor = {}
PreProcessor.__index = PreProcessor

E2Lib.PreProcessor = PreProcessor

---@overload fun(buffer: string, directives: PPDirectives, ent: userdata?): nil, Error[]
---@overload fun(buffer: string, directives: PPDirectives, ent: userdata?): boolean, PPDirectives, string, PreProcessor
function PreProcessor.Execute(buffer, directives, ent)
	-- instantiate PreProcessor
	local instance = setmetatable({}, PreProcessor)

	-- and pcall the new instance's Process method.
	local directives, newcode = instance:Process(buffer, directives, ent)
	local ok = #instance.errors == 0
	return ok, ok and directives or instance.errors, newcode, instance
end

---@param message string
---@param trace Trace?
---@param quick_fix { replace: string, at: Trace }[]?
function PreProcessor:Error(message, trace, quick_fix)
	self.errors[#self.errors + 1] = Error.new(
		message,
		trace or Trace.new(self.readline, 1, self.readline, 1),
		nil,
		quick_fix
	)
end

---@param message string
---@param trace Trace?
---@param quick_fix { replace: string, at: Trace }[]?
function PreProcessor:Warning(message, trace, quick_fix)
	self.warnings[#self.warnings + 1] = Warning.new(
		message,
		trace or Trace.new(self.readline, 1, self.readline, 1),
		quick_fix
	)
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

function PreProcessor:GetType(tp, trace)
	tp = tp:Trim():lower()
	local up = tp:upper()

	if tp == "normal" then
		self:Warning("Use of deprecated type [normal]", trace, { { at = trace, replace = "number" } })
	end

	return type_map[tp] or (wire_expression_types[up] and wire_expression_types[up][1]) or tp
end

function PreProcessor:HandlePPCommand(comment, col)
	local command, args = comment:match("^([^ ]*) ?(.*)$")

	local handler = self["PP_" .. command]
	if handler then
		return handler(self, args, Trace.new(self.readline, col, self.readline, col + 1 + #command))
	end
end

function PreProcessor:FindComments(line)
	local isinput = not self.blockcomment and not self.multilinestring and line:match("^@inputs") ~= nil
	local isoutput = not self.blockcomment and not self.multilinestring and line:match("^@outputs") ~= nil

	local ret, count, pos, found = {}, 0, 1
	repeat
		found = line:find((isinput or isoutput) and '[#"\\A-Z]' or '[#"\\]', pos)
		if found then -- We found something
			local char = line:sub(found, found)
			if (isinput or isoutput) and char:match("[A-Z]") ~= nil then -- we found the start of an input/output variable definition
				local varname, endpos = line:match("^([A-Z][A-Za-z0-9_]*)()",found)
				count = count + 1
				ret[count] = {type = isinput and "inputs" or "outputs", name=varname, pos=found, blockcomment = {}}
				pos = endpos
			elseif char == "#" then -- We found a comment
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
		if self.description_cache then
			table.insert(self.description_cache.blockcomment, line)
		end
		return ""
	end

	if not self.blockcomment then
		self.description_cache = nil
	end

	local prev_disabled, ret, lastpos = self:Disabled(), "", 1

	for i = 1, num do
		local type = comments[i].type
		if type == "string" and not self.blockcomment then -- Is it a string?
			self.multilinestring = not self.multilinestring
		elseif not self.multilinestring then -- Else it's a comment if we're not inside a multiline string
			if self.blockcomment then -- Time to look for a ]#
				if type == "end" then -- We found one
					local pos = comments[i].pos
					local comment_str = line:sub(lastpos,pos-1)
					ret = ret .. (" "):rep(pos - lastpos + 4) -- Replace the stuff in between with spaces
					lastpos = pos + 2
					self.blockcomment = nil -- We're no longer in a block comment

					if self.description_cache then
						table.insert(self.description_cache.blockcomment,comment_str)
						self.directives[self.description_cache.type][4][self.description_cache.name] = table.concat(self.description_cache.blockcomment,"\n")
						self.description_cache = nil
					end
				end
			else -- Time to look for a #[
				if type == "inputs" or type == "outputs" then -- an input/output definition
					self.description_cache = comments[i]
				else
					if type == "start" then -- We found a #[
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
							self:HandlePPCommand(line:sub(pos + 1), pos)
						end

						if self.description_cache then
							self.directives[self.description_cache.type][4][self.description_cache.name] = line:sub(pos+1)
							self.description_cache = nil
						end

						lastpos = -1
						break -- Don't care what comes after
					end
				end
			end
		end
	end

	if prev_disabled then
		return ""
	elseif lastpos ~= -1 and not self.blockcomment then
		return ret .. line:sub(lastpos, -1)
	elseif lastpos ~= -1 and self.blockcomment then
		if self.description_cache then
			table.insert(self.description_cache.blockcomment,line:sub(lastpos))
		end
		return ret
	else
		return ret
	end
end

-- Handle inputs, outputs & persist, name is "inputs", "outputs", etc.
local function handleIO(name)
	return function(self, value)
		local ports = self.directives[name]
		local retval, columns, lines = self:ParsePorts(value, #name + 2)

		for i, key in ipairs(retval[1]) do
			local tr = Trace.new(lines[i], columns[i], lines[i], columns[i])

			if ports[3][key] then
				if ports[3][key] ~= retval[2][i] then
					self:Error("Directive (@" .. name .. ") contains multiple definitions of the same variable with differing types", tr)
				else
					self:Warning("Directive (@" .. name .. ") contains multiple definitions of the same variable", tr)
				end
			else
				local index = #ports[1] + 1
				ports[1][index] = key -- Index: Name
				ports[2][index] = retval[2][i] -- Index: Type
				ports[3][key] = retval[2][i] -- Name: Type
				ports[5][key] = tr -- Name: Trace
			end
		end
	end
end

---@type fun(PreProcessor, string, Trace):string?[]
local directive_handlers = {
	["name"] = function(self, value)
		if not self.ignorestuff then
			if self.directives.name == nil then
				self.directives.name = value
			else
				self:Error("Directive (@name) must not be specified twice")
			end
		end
	end,

	["model"] = function(self, value, trace)
		if not self.ignorestuff then
			if self.directives.model == nil then
				if not util.IsValidModel(value) then
					self:Warning("Directive (@model) has an invalid model: " .. value)
				end

				self.directives.model = value
			else
				self:Error("Directive (@model) must not be specified twice")
			end
		end
	end,

	["inputs"] = handleIO("inputs"),
	["outputs"] = handleIO("outputs"),
	["persist"] = handleIO("persist"),

	["trigger"] = function(self, value, trace)
		local trimmed = string.Trim(value)
		if trimmed == "all" then
			if self.directives.trigger[1] ~= nil then
				self:Error("Directive (@trigger) conflicts with previous directives", trace)
			end
			self.directives.trigger[1] = true
		elseif trimmed == "none" then
			if self.directives.trigger[1] ~= nil then
				self:Error("Directive (@trigger) conflicts with previous directives", trace)
			end
			self.directives.trigger[1] = false
		elseif trimmed ~= "" then
			if self.directives.trigger[1] ~= nil and #self.directives.trigger[2] == 0 then
				self:Error("Directive (@trigger) conflicts with previous directives", trace)
			end

			self.directives.trigger[1] = false
			local retval, columns, lines = self:ParsePorts(value, 9)

			for i, key in ipairs(retval[1]) do
				if self.directives.trigger[2][key] then
					self:Error("Directive (@trigger) contains multiple definitions of the same variable", Trace.new(lines[i], columns[i], lines[i], columns[i]))
				else
					self.directives.trigger[2][key] = true
				end
			end
		end
	end,

	["autoupdate"] = function(self, arg, trace)
		if not self.directives.autoupdate then
			self.directives.autoupdate = true
		else
			if not self.ignorestuff then -- Assume includes are in good faith and ignore them
				local quickfix
				if CLIENT then -- Only do quickfix on the client for optimization
					trace.end_line = trace.start_line + 1 -- Modify this trace to avoid creating new ones. Hacky but resourceful(?)
					trace.end_col = 1
					quickfix = { { at = trace, replace = "" } }
				end
				self:Error("Directive (@autoupdate) cannot be defined twice", trace, quickfix)
			end
			return ""
		end

		if CLIENT then
			if #string.Trim(arg) > 0 then
				trace.start_col = trace.end_col + 1
				trace.end_line = trace.start_line + 1
				trace.end_col = 1
				self:Warning("Directive (@autoupdate) takes no arguments", trace, { { at = trace, replace = "\n" } })
			end
			return ""
		end

		if not IsValid( self.ent ) or not self.ent.duped or not self.ent.filepath or self.ent.filepath == "" then return "" end
		WireLib.Expression2Upload( self.ent:GetPlayer(), self.ent, self.ent.filepath )
	end,

	-- Maybe it can have multiple levels in the future but I think one is fine for now.
	["strict"] = function(self)
		self.directives.strict = true
	end
}

function PreProcessor:HandleDirective(name, value, trace --[[@param trace Trace]])
	local handler = directive_handlers[name]
	if handler then
		return handler(self, value, trace)
	else
		self:Error("Unknown directive found (@" .. E2Lib.limitString(name, 10) .. ")", trace)
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

	if directive:lower() ~= directive then
		local tr = Trace.new(self.readline, 2, self.readline, 2 + #directive)
		self:Error("Directive (@" .. E2Lib.limitString(directive, 10) .. ") must be lowercase", tr, { { at = tr, replace = string.lower(directive) } })
	end

	local tr = Trace.new(self.readline, 1, self.readline, #directive + 1)

	if self.incode then
		self:Error("Directive (@" .. E2Lib.limitString(directive, 10) .. ") must appear before code", tr)
	end

	-- evaluate directive
	self:HandleDirective(directive, value, tr)

	-- remove line from output
	return ""
end


---@alias IODirective { [1]: string[], [2]: TypeSignature[], [3]: table<string, TypeSignature>, [4]: table<string, string>, [5]: table<string, Trace>  }
---@alias PPDirectives { inputs: IODirective, outputs: IODirective, persist: IODirective, name: string?, model: string?, trigger: { [1]: boolean?, [2]: table<string, boolean> }, strict: boolean?, autoupdate: true? }

---@param buffer string
---@param directives PPDirectives
---@param ent userdata?
---@return PPDirectives directives, string buf
function PreProcessor:Process(buffer, directives, ent)
	-- entity is needed for autoupdate
	self.ent = ent
	self.ifdefStack = {}
	self.warnings, self.errors = {}, {}

	local lines = string.Explode("\n", buffer)

	if not directives then
		self.directives = {
			name = nil,
			model = nil,
			inputs = { {}, {}, {}, {}, {} }, -- 1: names, 2: types, 3: names=types lookup, 4: descriptions, 5: names={line, column} lookup
			outputs = { {}, {}, {}, {}, {} }, -- 1: names, 2: types, 3: names=types lookup, 4: descriptions, 5: names={line, column} lookup
			persist = { {}, {}, {}, nil, {} },
			trigger = { nil, {} },
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

	-- convert description lookup table into an array that WireLib understands
	self:ConvertDescriptions(self.directives.inputs)
	self:ConvertDescriptions(self.directives.outputs)

	if self.directives.trigger[1] == nil then self.directives.trigger[1] = true end
	if not self.directives.name then self.directives.name = "" end

	return self.directives, table.concat(lines, "\n")
end

function PreProcessor:ParsePorts(ports, startoffset)
	local names, types, columns, lines = {}, {}, {}, {}

	-- Preprocess [Foo Bar]:entity into [Foo,Bar]:entity so we don't have to deal with split-up multi-variable definitions in the main loop
	ports = ports:gsub("%[.-%]", function(s)
		return string.Replace(s, " ", ",")
	end)

	for column, key in ports:gmatch("()(%S+)") do
		---@cast column integer
		---@cast key string

		column = startoffset + column
		local tr = Trace.new(self.readline, column, self.readline, column + #key)

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
				self:Error("Variable name (" .. E2Lib.limitString(key, 10) .. ") must start with an uppercase letter", tr, { { at = tr, replace = key:sub(1, 1):upper() .. key:sub(2) } })
				goto cont
			else
				-- yes -> add all variables.
				for column2, var in namestring:gmatch("()([^,]+)") do
					column2 = column + column2
					local tr = Trace.new(self.readline, column2, self.readline, column2 + #var)

					var = string.Trim(var)
					-- skip empty entries
					if var ~= "" then
						-- error on malformed variable names
						if not var:match("^[A-Z]") then
							self:Error("Variable name (" .. E2Lib.limitString(var, 10) .. ") must start with an uppercase letter", tr, { { at = tr, replace = var:sub(1, 1):upper() .. var:sub(2) } })
							goto cont
						else
							local errcol = var:find("[^A-Za-z0-9_]")
							if errcol then
								self:Error("Variable declaration (" .. E2Lib.limitString(var, 10) .. ") contains invalid characters", Trace.new(self.readline, column2 + errcol - 1, self.readline, column2 + errcol - 1))
								goto cont
							else
								-- and finally add the variable.
								names[#names + 1] = var
							end
						end
					end
				end
			end
		end

		-------------------------------- variable types --------------------------------

		local vtype
		local character = key:sub(i + 1, i + 1)
		if character == ":" then
			-- type is specified -> check for validity
			vtype = key:sub(i + 2)

			local tr = Trace.new(self.readline, column + i + 1, self.readline, column + i + 1 + #vtype)

			if vtype ~= vtype:lower() then
				self:Error("Variable type [" .. E2Lib.limitString(vtype, 10) .. "] must be lowercase", tr, { { at = tr, replace = vtype:lower() } })
				goto cont
			elseif vtype == "number" then
				vtype = "normal"
			elseif vtype == "normal" then
				self:Warning("Variable type [normal] is deprecated", tr, { { at = tr, replace = "number" } })
			end
		elseif character == "" then
			-- type is not specified -> default to number
			vtype = "normal"
		else
			-- invalid -> raise an error
			self:Error("Variable declaration (" .. E2Lib.limitString(key, 10) .. ") contains invalid characters", tr)
			goto cont
		end

		-- fill in the missing types
		for i = #types + 1, #names do
			local ty = wire_expression_types[vtype:upper()]
			if ty then
				types[i] = ty[1]
				columns[i] = column
				lines[i] = self.readline
			else
				self:Error("Unknown variable type [" .. E2Lib.limitString(vtype, 10) .. "]", Trace.new(self.readline, column + i + 1, self.readline, column + i + 1 + #vtype))
			end
		end

		::cont::
	end

	return { names, types }, columns, lines
end

function PreProcessor:ConvertDescriptions(portstbl)
	local ports = portstbl[1]
	local lookup = portstbl[4]

	local new = {}
	for i=1,#ports do
		local port = ports[i]
		if lookup[port] then
			new[i] = lookup[port]
		end
	end

	portstbl[4] = new
end

function PreProcessor:Disabled()
	return self.ifdefStack[#self.ifdefStack] == false
end

function PreProcessor:GetFunction(args, type, trace --[[@param trace Trace]])
	local thistype, colon, name, argtypes = args:match("([^:]-)(:?)([^:(]+)%(([^)]*)%)")

	local col, line = trace.end_col + 1, trace.end_line

	if thistype and (thistype ~= "") == (colon ~= "") then
		local start = col
		col = col + #thistype

		thistype = self:GetType(thistype, Trace.new(line, start, line, col))
		col = col + 1 -- skip colon
	else
		self:Error("Malformed " .. type .. " argument " .. args, trace)
		return
	end

	col = col + #name -- skip name and paren

	local tps = {thistype .. colon}

	argtypes = string.Explode(",", argtypes)
	local last = #argtypes

	for l, argtype in ipairs(argtypes) do
		local start = col
		col = col + #argtype + (l ~= last and 1 or 0)

		argtype = self:GetType(argtype, Trace.new(line, start, line, col))
		table.insert(tps, argtype)
	end

	local pars = table.concat(tps)
	return wire_expression2_funcs[name .. "(" .. pars .. ")"]
end

function PreProcessor:PP_ifdef(args, trace)
	local func = self:GetFunction(args, "#ifdef", trace)

	if self:Disabled() then
		table.insert(self.ifdefStack, false)
	else
		table.insert(self.ifdefStack, func ~= nil)
	end
end

function PreProcessor:PP_ifndef(args, trace)
	local func = self:GetFunction(args, "#ifndef", trace)

	if self:Disabled() then
		table.insert(self.ifdefStack, false)
	else
		table.insert(self.ifdefStack, func == nil)
	end
end

function PreProcessor:PP_else(args, trace)
	local state = table.remove(self.ifdefStack)
	if state == nil then self:Error("Found #else outside #ifdef/#ifndef block", trace) end

	if args:Trim() ~= "" then self:Error("Must not pass an argument to #else", trace) end

	if self:Disabled() then
		table.insert(self.ifdefStack, false)
	else
		table.insert(self.ifdefStack, not state)
	end
end

function PreProcessor:PP_endif(args, trace)
	local state = table.remove(self.ifdefStack)
	if state == nil then self:Error("Found #endif outside #ifdef/#ifndef block", trace) end

	if args:Trim() ~= "" then self:Error("Must not pass an argument to #endif", trace) end
end

function PreProcessor:PP_error(args, trace)
	if not self:Disabled() then
		self:Error(args, trace)
	end
end

function PreProcessor:PP_warning(args, trace)
	if not self:Disabled() then
		self:Warning(args, trace)
	end
end
