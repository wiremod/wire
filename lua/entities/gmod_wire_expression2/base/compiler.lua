--[[
	Expression 2 Compiler
		by Vurv
]]

AddCSLuaFile()

local Warning, Error = E2Lib.Debug.Warning, E2Lib.Debug.Error
local Token, TokenVariant = E2Lib.Tokenizer.Token, E2Lib.Tokenizer.Variant
local Node, NodeVariant = E2Lib.Parser.Node, E2Lib.Parser.Variant
local Operator = E2Lib.Operator

local pairs, ipairs = pairs, ipairs

local TickQuota = GetConVar("wire_expression2_quotatick"):GetInt()

cvars.RemoveChangeCallback("wire_expression2_quotatick", "compiler_quota_check")
cvars.AddChangeCallback("wire_expression2_quotatick", function(_, old, new)
	TickQuota = tonumber(new)
end, "compiler_quota_check")

---@class ScopeData
---@field dead "ret"|true?
---@field loop boolean?
---@field switch_case boolean?
---@field function { [1]: string, [2]: EnvFunction}?
---@field ops integer

---@alias VarData { type: string, trace_if_unused: Trace?, const: boolean, initialized: boolean, depth: integer }

---@class Scope
---@field parent Scope?
---@field data ScopeData
---@field vars table<string, VarData>
local Scope = {}
Scope.__index = Scope

---@param parent Scope?
function Scope.new(parent)
	return setmetatable({ data = { ops = 0 }, vars = {}, parent = parent }, Scope)
end

function Scope:Depth()
	return self.parent and (1 + self.parent:Depth()) or 0
end

---@param name string
---@param data VarData
function Scope:DeclVar(name, data)
	if name ~= "_" then
		data.depth = self:Depth()
		self.vars[name] = data
	end
end

function Scope:IsGlobalScope()
	return self.parent == nil
end

---@param name string
---@return VarData?
function Scope:LookupVar(name)
	return self.vars[name] or (self.parent and self.parent:LookupVar(name))
end

---@param field string
function Scope:ResolveData(field)
	return self.data[field] or (self.parent and self.parent:ResolveData(field))
end

---@class Compiler
--- Base Data
---@field warnings table<number|string, Warning> # Array of warnings (main file) with keys to included file warnings.
---@field global_scope Scope
---@field scope Scope
--- Below is analyzed data
---@field include string? # Current include file or nil if main file
---@field registered_events table<string, function>
---@field user_functions table<string, table<string, EnvFunction>> # applyForce -> v
---@field user_methods table<string, table<string, table<string, EnvFunction>>> # e: -> applyForce -> vava
--- External Data
---@field includes table<string, { [1]: Node, [2]: boolean }>
---@field delta_vars table<string, true> # Variable: True
---@field persist IODirective
---@field inputs IODirective
---@field outputs IODirective
---@field strict boolean
local Compiler = {}
Compiler.__index = Compiler

E2Lib.Compiler = Compiler

function Compiler.new()
	local global_scope = Scope.new()
	return setmetatable({
		global_scope = global_scope, scope = global_scope, warnings = {}, registered_events = {},
		user_functions = {}, user_methods = {}, delta_vars = {}
	}, Compiler)
end

---@param directives PPDirectives
---@param dvars table<string, true>?
---@param includes table<string, Node>?
function Compiler.from(directives, dvars, includes)
	local global_scope = Scope.new()
	return setmetatable({
		persist = directives.persist, inputs = directives.inputs, outputs = directives.outputs, strict = directives.strict,
		global_scope = global_scope, scope = global_scope, warnings = {}, registered_events = {}, user_functions = {}, user_methods = {},
		delta_vars = dvars or {}, includes = includes or {}
	}, Compiler)
end

local BLOCKED_ARRAY_TYPES = E2Lib.blocked_array_types

---@param ast Node
---@param directives PPDirectives
---@param dvars table<string, boolean>
---@param includes table<string, Node>
---@return boolean ok, function|Error script, Compiler self
function Compiler.Execute(ast, directives, dvars, includes)
	local instance = Compiler.from(directives, dvars, includes)
	local ok, script = xpcall(Compiler.Process, E2Lib.errorHandler, instance, ast)
	return ok, script, instance
end

---@param message string
---@param trace Trace
---@param quick_fix { replace: string, at: Trace }[]?
function Compiler:Error(message, trace, quick_fix)
	error( Error.new(message, trace, nil, quick_fix), 0)
end

---@generic T
---@param v? T
---@param message string
---@param trace Trace
---@return T
function Compiler:Assert(v, message, trace)
	if not v then self:Error(message, trace) end
	return v
end

---@generic T
---@param v? T
---@param message string
---@param trace Trace
---@return T
function Compiler:AssertW(v, message, trace)
	if not v then self:Warning(message, trace) end
	return v
end


---@param message string
---@param trace Trace
---@param quick_fix { replace: string, at: Trace }[]?
function Compiler:Warning(message, trace, quick_fix)
	if self.include then
		local tbl = self.warnings[self.include]
		tbl[#tbl + 1] = Warning.new(message, trace, quick_fix)
	else
		self.warnings[#self.warnings + 1] = Warning.new(message, trace, quick_fix)
	end
end

---@generic T
---@generic T2
---@generic T3
---@param fn fun(scope: Scope): T?, T2?, T3?
---@return T?, T2?, T3?
function Compiler:Scope(fn)
	self.scope = Scope.new(self.scope)
	local ret, ret2, ret3 = fn(self.scope)
	self.scope = self.scope.parent
	return ret, ret2, ret3
end

---@generic T
---@generic T2
---@generic T3
---@param fn fun(scope: Scope): T?, T2?, T3?
---@return T?, T2?, T3?
function Compiler:IsolatedScope(fn)
	local old = self.scope
	self.scope = Scope.new(self.global_scope)
	local ret, ret2, ret3 = fn(self.scope)
	self.scope = old
	return ret, ret2, ret3
end

--- Ensure that a token of variant LowerIdent is a valid type
---@param ty Token<string>
---@return string? type_id # Type id or nil if void
function Compiler:CheckType(ty)
	if ty.value == "number" then return "n" end
	if ty.value == "void" then return end
	return self:Assert(wire_expression_types[ty.value:upper()], "Invalid type (" .. ty.value .. ")", ty.trace)[1]
end

---@alias RuntimeOperator fun(self: RuntimeContext, ...): any

---@type fun(self: Compiler, trace: Trace, data: { [1]: Node, [2]: Operator, [3]: self }): RuntimeOperator, string?
local function handleInfixOperation(self, trace, data)
	local lhs, lhs_ty = self:CompileExpr(data[1])
	local rhs, rhs_ty = self:CompileExpr(data[3])

	local op, op_ret, legacy = self:GetOperator(E2Lib.OperatorNames[data[2]]:lower(), { lhs_ty, rhs_ty }, trace)

	if legacy then
		local largs = { [1] = {}, [2] = { lhs }, [3] = { rhs }, [4] = { lhs_ty, rhs_ty } }
		return function(state)
			return op(state, largs)
		end, op_ret
	else
		return function(state)
			return op(state, lhs(state), rhs(state))
		end, op_ret
	end
end

---@type table<NodeVariant, fun(self: Compiler, trace: Trace, data: table, used_as_stmt: boolean): RuntimeOperator|nil, string?>
local CompileVisitors = {
	---@param data Node[]
	[NodeVariant.Block] = function(self, trace, data)
		local stmts, traces = {}, {}
		for _, node in ipairs(data) do
			if not self.scope.data.dead then
				local trace, stmt = node.trace, self:CompileStmt(node)
				if stmt then -- Need to append because Compile* can return nil (despite me not annotating it as such) for compile time constructs
					local i = #stmts + 1
					stmts[i], traces[i] = stmt, trace

					if node:isExpr() and node.variant ~= NodeVariant.ExprDynCall and node.variant ~= NodeVariant.ExprCall and node.variant ~= NodeVariant.ExprMethodCall then
						self:Warning("This expression has no effect", node.trace, { { replace = "", at = node.trace } })
					end
				end
			else
				self:Warning("Unreachable code detected", node.trace, { { replace = "", at = node.trace } })
				break
			end
		end

		for name, var in pairs(self.scope.vars) do
			if name ~= "_" and var.trace_if_unused then
				self:Warning("Unused variable: " .. name, var.trace_if_unused)
			end
		end

		local cost, nstmts = self.scope.data.ops, #stmts
		self.scope.data.ops = 0

		if self.scope:ResolveData("loop") or self.scope:ResolveData("switch_case") then -- Inside loop or switch case, check if continued or broken
			return function(state) ---@param state RuntimeContext
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for i = 1, nstmts do
					state.trace = traces[i]
					stmts[i](state)
					if state.__break__ or state.__return__ or state.__continue__ then break end
				end
			end
		elseif self.scope:ResolveData("function") then -- If inside a function, check if returned.
			return function(state) ---@param state RuntimeContext
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for i = 1, nstmts do
					state.trace = traces[i]
					stmts[i](state)
					if state.__return__ then break end
				end
			end
		else -- Most optimized case, not inside a function or loop.
			return function(state) ---@param state RuntimeContext
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for i = 1, nstmts do
					state.trace = traces[i]
					stmts[i](state)
				end
			end
		end
	end,

	---@param data { [1]: Node?, [2]: Node }[]
	[NodeVariant.If] = function (self, trace, data)
		local chain = {} ---@type { [1]: RuntimeOperator?, [2]: RuntimeOperator }[]
		local dead, els = true, false

		for i, ifeif in ipairs(data) do
			self:Scope(function(scope)
				if ifeif[1] then -- if or elseif
					local expr, expr_ty = self:CompileExpr(ifeif[1])

					if expr_ty == "n" then -- Optimization: Don't need to run operator_is on number (since we already check if ~= 0 here.)
						chain[i] = {
							expr,
							self:CompileStmt(ifeif[2])
						}
					else
						local op = self:GetOperator("is", { expr_ty }, trace)

						chain[i] = {
							function(state)
								return op(state, expr(state))
							end,
							self:CompileStmt(ifeif[2])
						}
					end

					dead = dead and scope.data.dead
				else -- else block
					chain[i] = { nil, self:CompileStmt(ifeif[2]) }
					dead, els = dead and scope.data.dead, true
				end
			end)
		end

		if els and dead then -- if (0) { return } else { return } mark any code after as dead
			self.scope.data.dead = "ret"
		end

		return function(state) ---@param state RuntimeContext
			for _, data in ipairs(chain) do
				local cond, block = data[1], data[2]
				if cond then
					if cond(state) ~= 0 then
						state:PushScope()
						block(state)
						state:PopScope()
						break
					end
				else
					-- Else block
					state:PushScope()
					block(state)
					state:PopScope()
					break
				end
			end
		end
	end,

	---@param data { [1]: Node, [2]: Node, [3]: boolean }
	[NodeVariant.While] = function(self, trace, data)
		local expr, block = self:Scope(function(scope)
			scope.data.loop = true
			return self:CompileExpr(data[1]), self:CompileStmt(data[2])
		end)

		if data[3] then
			-- do while
			return function(state) ---@param state RuntimeContext
				state:PushScope()
				repeat
					state.prf = state.prf + 1 / 20

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				until expr(state) == 0
				state:PopScope()
			end
		else
			return function(state) ---@param state RuntimeContext
				state:PushScope()
				while expr(state) ~= 0 do
					state.prf = state.prf + 1 / 20

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				end
				state:PopScope()
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Node, [3]: Node, [4]: Node?, [5]: Node } var start stop step block
	[NodeVariant.For] = function (self, trace, data)
		local var, start, stop, step = data[1], self:CompileExpr(data[2]), self:CompileExpr(data[3]), data[4] and self:CompileExpr(data[4]) or data[4]

		local block = self:Scope(function(scope)
			scope.data.loop = true
			scope:DeclVar(var.value, { initialized = true, type = "n", trace_if_unused = var.trace })

			return self:CompileStmt(data[5])
		end)

		local var = var.value
		if var == "_" then -- Discarded for loop value
			return function(state) ---@param state RuntimeContext
				state:PushScope() -- Push scope only first time, compiler should enforce not using variables ahead of time.
				local step = step and step(state) or 1
				for _ = start(state), stop(state), step do
					state.prf = state.prf + 1 / 20

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				end
				state:PopScope()
			end
		else
			return function(state) ---@param state RuntimeContext
				state:PushScope() -- Push scope only first time, compiler should enforce not using variables ahead of time.
				local step, scope = step and step(state) or 1, state.Scope
				for i = start(state), stop(state), step do
					state.prf = state.prf + 1 / 20
					scope[var] = i

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				end
				state:PopScope()
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Token<string>?, [3]: Token<string>, [4]: Token<string>, [5]: Node, [6]: Node } key key_type value value_type iterator block
	[NodeVariant.Foreach] = function (self, trace, data)
		local key, key_type, value, value_type = data[1], data[2] and self:CheckType(data[2]), data[3], self:CheckType(data[4])

		local item, item_ty = self:CompileExpr(data[5])

		if not key_type then -- If no key type specified, fall back to string for tables and number for everything else.
			if item_ty == "t" then
				self:Warning("This key will default to type (string). Annotate it with :string or :number", key.trace)
				key_type = "s"
			else
				self:Warning("This key will default to type (number). Annotate it with :number / :type", key.trace)
				key_type = "n"
			end
		end

		local block, cost = self:Scope(function(scope)
			scope.data.loop = true

			scope:DeclVar(key.value, { initialized = true, trace_if_unused = key.trace, type = key_type })
			scope:DeclVar(value.value, { initialized = true, trace_if_unused = value.trace, type = value_type })

			return self:CompileStmt(data[6]), 1 / 15
		end)

		local into_iter = self:GetOperator("iter", { key_type, value_type, "=", item_ty }, trace)
		local key, value = key.value, value.value

		if key == "_" then -- Not using key
			return function(state) ---@param state RuntimeContext
				local iter = into_iter(state, item(state))

				state:PushScope() -- Only push scope once as an optimization, compiler should disallow using variable ahead of time anyway.
				local scope = state.Scope
				for _, v in iter() do
					state.prf = state.prf + cost
					scope[value] = v

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				end
				state:PopScope()
			end
		else -- todo: optimize for discard value case
			return function(state) ---@param state RuntimeContext
				local iter = into_iter(state, item(state))

				state:PushScope() -- Only push scope once as an optimization, compiler should disallow using variable ahead of time anyway.
				local scope = state.Scope
				for k, v in iter() do
					state.prf = state.prf + cost
					scope[key], scope[value] = k, v

					block(state)

					if state.__break__ then
						state.__break__ = false
						break
					elseif state.__return__ then
						break
					elseif state.__continue__ then
						state.__continue__ = false
					end
				end
				state:PopScope()
			end
		end
	end,

	---@param data { [1]: Node, [2]: {[1]: Node, [2]: Node}[], [3]: Node? }
	[NodeVariant.Switch] = function (self, trace, data)
		local expr, expr_ty = self:CompileExpr(data[1])
		local dead = true

		local cases = {} ---@type { [1]: RuntimeOperator, [2]: RuntimeOperator }[]
		for i, case in ipairs(data[2]) do
			local cond, cond_ty = self:CompileExpr(case[1])
			local block = self:Scope(function(scope)
				scope.data.switch_case = true
				local b = self:CompileStmt(case[2])
				dead = dead and scope.data.dead == "ret"
				return b
			end)

			local eq =  self:GetOperator("eq", { expr_ty, cond_ty }, case[1].trace)
			cases[i] = {
				function(state, expr)
					return eq(state, cond(state), expr)
				end,
				block
			}
		end

		local default = data[3] and self:Scope(function(scope)
			scope.data.switch_case = true
			local b = self:CompileStmt(data[3])
			dead = dead and scope.data.dead == "ret"
			return b
		end)

		if dead and default then -- if all cases dead and has default case, mark scope as dead.
			self.scope.data.dead = true
		end

		local ncases = #cases

		return function(state) ---@param state RuntimeContext
			local expr = expr(state)
			state:PushScope()

			for i = 1, ncases do
				local case = cases[i]
				if case[1](state, expr) ~= 0 then
					case[2](state)

					if state.__break__ then
						state.__break__ = false
						goto exit
					elseif state.__return__ then -- Yes this should only be checked if the switch is inside a function, but I don't care enough about the performance of switch case to add another duplicated 30 lines to the file
						goto exit
					else -- Fallthrough, run every case until break found.
						for j = i + 1, ncases do
							cases[j][2](state)
							if state.__break__ then
								state.__break__ = false
								goto exit
							elseif state.__return__ then
								goto exit
							end
						end
					end
				end
			end

			if default then
				default(state)
				state.__break__ = false
			end

			::exit::
			state:PopScope()
		end
	end,

	---@param data { [1]: Node, [2]: Token<string>, [3]: Token<string>?, [4]: Node }
	[NodeVariant.Try] = function (self, trace, data)
		local try_block, catch_block, err_var, err_ty = nil, nil, data[2], data[3]
		self:Scope(function(scope)
			try_block = self:CompileStmt(data[1])
		end)

		if err_ty then
			self:Assert(err_ty.value == "string", "Error type can only be string, for now", err_ty.trace)
		else
			self:Warning("You should explicitly annotate the error type as :string", err_var.trace, { { replace = err_var.value .. ":string", at = err_var.trace } })
		end

		self:Scope(function (scope)
			scope:DeclVar(err_var.value, { initialized = true, trace_if_unused = err_var.trace, type = "s" })
			catch_block = self:CompileStmt(data[4])
		end)

		self.scope.data.ops = self.scope.data.ops + 5

		return function(state) ---@param state RuntimeContext
			local scope, scope_id = state.Scope, state.ScopeID
			state:PushScope()
				local ok, err = pcall(try_block, state)
			if ok then
				state:PopScope()
			else
				state.Scope, state.ScopeID = scope, scope_id -- Skip back any scopes that may have been created in try_block
				local catchable, msg = E2Lib.unpackException(err)
				if catchable then
					state:PushScope()
						state.Scope[err_var.value] = (type(msg) == "string") and msg or ""
						catch_block(state)
					state:PopScope()
				else
					error(err, 0)
				end
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Token<string>?, [3]: Token<string>, [4]: Parameter[], [5]: Node }
	[NodeVariant.Function] = function (self, trace, data)
		local name = data[3]

		local return_type
		if data[1] then
			return_type = self:CheckType(data[1])
		end

		local meta_type
		if data[2] then
			meta_type = self:Assert(self:CheckType(data[2]), "Cannot use void as meta type", trace)
		end

		local param_types, param_names, variadic_ind, variadic_ty = {}, {}, nil, nil
		if data[4] then -- Has parameters
			local existing = {}
			for i, param in ipairs(data[4]) do
				if param.type then
					local t = self:Assert(self:CheckType(param.type), "Cannot use void as parameter type", param.name.trace)
					if param.variadic then
						self:Assert(t == "r" or t == "t", "Variadic parameter must be of type array or table", param.type.trace)
						variadic_ind, variadic_ty = i, t
					end
					param_types[i] = t
				elseif param.variadic then
					self:Error("Variadic parameter requires explicit type", param.name.trace)
				else
					param_types[i] = "n"
					self:Warning("Use of implicit parameter type is deprecated (add :number)", param.name.trace, { { replace = param.name.value .. ":number", at = param.name.trace } })
				end

				if param.name.value ~= "_" and existing[param.name.value] then
					self:Error("Variable '" .. param.name.value .. "' is already used as a parameter", param.name.trace)
				else
					param_names[i] = param.name.value
					existing[param.name.value] = true
				end
			end
		end

		if self.strict and not (self.scope:IsGlobalScope() or (self.include and self.scope:Depth() == 1)) then
			self:Warning("Functions should be in the top scope, nesting them does nothing", trace)
		end

		local fn_data, lookup_variadic, userfunction = self:GetFunction(name.value, param_types, meta_type)
		if fn_data then
			if not userfunction then
				if not lookup_variadic or variadic_ind == 1 then -- Allow overrides like print(nnn) and print(n..r) to override print(...), but not print(...r)
					self:Error("Cannot overwrite existing function: " .. (meta_type and (meta_type .. ":") or "") .. name.value .. "(" .. table.concat(fn_data.args, ", ") .. ")", name.trace)
				end
			else
				if return_type then
					self:Assert(fn_data.ret == return_type, "Cannot override with differing return type", trace)
				else
					self:Assert(fn_data.ret == nil, "Cannot override function returning void with differing return type", trace)
				end

				if not self.strict then
					self:Warning("Do not override functions. This is a hard error with @strict.", trace)
				else
					self:Error("Cannot override existing function '" .. name.value .. "'", trace)
				end
			end
		end

		local fn = { args = param_types, ret = return_type, meta = meta_type, cost = variadic_ty and 10 or 5 + (self.strict and 0 or 3), attrs = {} }
		local sig = table.concat(param_types, "", 1, #param_types - 1) .. ((variadic_ty and ".." or "") .. (param_types[#param_types] or ""))

		if meta_type then
			self.user_methods[meta_type] = self.user_methods[meta_type] or {}

			self.user_methods[meta_type][name.value] = self.user_methods[meta_type][name.value] or {}

			if variadic_ty then
				local opposite = variadic_ty == "r" and "t" or "r"
				if self.user_methods[meta_type][name.value][sig:gsub(".." .. variadic_ty, ".." .. opposite)] then
					self:Error("Cannot override variadic " .. opposite .. " function with variadic " .. variadic_ty .. " function to avoid ambiguity.", trace)
				end
			end

			self.user_methods[meta_type][name.value][sig] = fn

			-- Insert "This" variable
			table.insert(param_names, 1, "This")
			table.insert(param_types, 1, meta_type)
		else
			self.user_functions[name.value] = self.user_functions[name.value] or {}
			if variadic_ty then
				local opposite = variadic_ty == "r" and "t" or "r"
				if self.user_functions[name.value][sig:gsub(".." .. variadic_ty, ".." .. opposite)] then
					self:Error("Cannot override variadic " .. opposite .. " function with variadic " .. variadic_ty .. " function to avoid ambiguity.", trace)
				end
			end
			self.user_functions[name.value][sig] = fn
		end


		local block
		if variadic_ty then
			local last, non_variadic = #param_types, #param_types - 1
			if variadic_ty == "r" then
				function fn.op(state, args) ---@param state RuntimeContext
					local s_scopes, s_scopeid, s_scope = state.Scopes, state.ScopeID, state.Scope

					local scope = { vclk = {} } -- Hack in the fact that functions don't have upvalues right now.
					state.Scopes = { [0] = state.GlobalScope, [1] = scope }
					state.Scope = scope
					state.ScopeID = 1

					for i = 1, non_variadic do
						scope[param_names[i]] = args[i]
					end

					local a, n = {}, 1
					for i = last, #args do
						a[n] = args[i]
						n = n + 1
					end

					scope[param_names[last]] = a
					block(state)

					state.Scopes, state.ScopeID, state.Scope = s_scopes, s_scopeid, s_scope

					state.__return__ = false
					return state.__returnval__
				end
			else -- table
				function fn.op(state, args, arg_types) ---@param state RuntimeContext
					local s_scopes, s_scopeid, s_scope = state.Scopes, state.ScopeID, state.Scope

					local scope = { vclk = {} } -- Hack in the fact that functions don't have upvalues right now.
					state.Scopes = { [0] = state.GlobalScope, [1] = scope }
					state.Scope = scope
					state.ScopeID = 1

					for i = 1, non_variadic do
						scope[param_names[i]] = args[i]
					end

					local n, ntypes = {}, {}
					for i = last, #args do
						n[i - last + 1], ntypes[i - last + 1] = args[i], arg_types[i - (meta_type and 1 or 0)]
					end

					scope[param_names[last]] = { s = {}, stypes = {}, n = n, ntypes = ntypes, size = last }

					block(state)

					state.Scopes, state.ScopeID, state.Scope = s_scopes, s_scopeid, s_scope

					state.__return__ = false
					return state.__returnval__
				end
			end
		else -- Todo: Make this output a different function when it doesn't early return, and/or has no parameters as an optimization.
			local nargs = #param_types
			function fn.op(state, args) ---@param state RuntimeContext
				local s_scopes, s_scopeid, s_scope = state.Scopes, state.ScopeID, state.Scope

				local scope = { vclk = {} } -- Hack in the fact that functions don't have upvalues right now.
				state.Scopes = { [0] = state.GlobalScope, [1] = scope }
				state.Scope = scope
				state.ScopeID = 1

				for i = 1, nargs do
					scope[param_names[i]] = args[i]
				end

				block(state)

				state.Scopes, state.ScopeID, state.Scope = s_scopes, s_scopeid, s_scope

				state.__return__ = false
				return state.__returnval__
			end
		end

		self:IsolatedScope(function (scope)
			for i, type in ipairs(param_types) do
				scope:DeclVar(param_names[i], { type = type, trace_if_unused = data[4][i] and data[4][i].name.trace or trace, initialized = true })
			end

			scope.data["function"] = { name.value, fn }

			block = self:CompileStmt(data[5])

			if return_type then -- Ensure function either returns or errors
				self:Assert(scope.data.dead, "This function marked to return '" .. data[1].value .. "' must return a value", data[1].trace)
			end
		end)

		if return_type then
			self:Assert(fn.ret == return_type, "Function " .. name.value .. " expects to return type (" .. return_type .. ") but got type (" .. (fn.ret or "void") .. ")", trace)
		else
			return_type = fn.ret
		end

		local sig = name.value .. "(" .. (meta_type and (meta_type .. ":") or "") .. sig .. ")"
		local fn = fn.op

		if not self.strict then
			return function(state) ---@param state RuntimeContext
				state.funcs[sig] = fn
				state.funcs_ret[sig] = return_type
			end
		end
	end,

	---@param data string
	[NodeVariant.Include] = function (self, trace, data)
		local include = self.includes[data]
		self:Assert(include and include[1], "Problem including file '" .. data .. "'", trace)

		if not include[2] then
			include[2] = true -- Prevent self-compiling infinite loop

			for var in pairs(include[3]) do -- add dvars from include
				self.delta_vars[var] = true
			end

			local last_file = self.include
			self.include = data
			self.warnings[data] = self.warnings[data] or {}

			local status, script = self:IsolatedScope(function(_)
				return pcall(self.CompileStmt, self, include[1])
			end)

			if not status then ---@cast script Error
				local reason = script.message
				if reason:find("C stack overflow") then reason = "Include depth too deep" end

				if not self.IncludeError then
					-- Otherwise Errors messages will be wrapped inside other error messages!
					self.IncludeError = true
					self:Error("include '" .. data .. "' -> " .. reason, trace)
				else
					error(script, 0) -- re-throw
				end
			else
				self.include = last_file

				local nwarnings = #self.warnings[data]
				if nwarnings ~= 0 then
					self:Warning("include '" .. data .. "' has " .. nwarnings .. " warning(s).", trace)
				end
			end

			include[2] = script
		end

		return function(state) ---@param state RuntimeContext
			local s_scopes, s_scopeid, s_scope = state.Scopes, state.ScopeID, state.Scope

			local scope = { vclk = {} } -- Isolated scope, except global variables are shared.
			state.Scope = scope
			state.ScopeID = 1
			state.Scopes = { [0] = state.GlobalScope, [1] = scope }

			include[2](state)

			state.Scopes, state.ScopeID, state.Scope = s_scopes, s_scopeid, s_scope
		end
	end,

	---@param data {}
	[NodeVariant.Continue] = function(self, trace, data)
		self.scope.data.dead = true
		return function(state) ---@param state RuntimeContext
			state.__continue__ = true
		end
	end,

	---@param data {}
	[NodeVariant.Break] = function(self, trace, data)
		self.scope.data.dead = true
		return function(state) ---@param state RuntimeContext
			state.__break__ = true
		end
	end,

	---@param data Node?
	[NodeVariant.Return] = function (self, trace, data)
		local fn = self.scope:ResolveData("function")
		self:Assert(fn, "Cannot use `return` outside of a function", trace)

		self.scope.data.dead = "ret"

		local retval, ret_ty
		if data then
			retval, ret_ty = self:CompileExpr(data)
		end

		local name, fn = fn[1], fn[2]

		if fn.ret then
			self:Assert(fn.ret == ret_ty, "Function " .. name .. " expects return type (" .. (fn.ret or "void") .. ") but was given (" .. (ret_ty or "void") .. ")", trace)
		else
			fn.ret = ret_ty
		end

		if ret_ty then
			return function(state) ---@param state RuntimeContext
				state.__returnval__, state.__return__ = retval(state), true
			end
		else -- return void (or just return)
			return function(state) ---@param state RuntimeContext
				state.__returnval__, state.__return__ = nil, true
			end
		end
	end,

	---@param data { [1]: boolean, [2]: { [1]: Token<string>, [2]: { [1]: Node, [2]: Token<string>?, [3]: Trace }[] }[], [3]: Node } is_local, vars, value
	[NodeVariant.Assignment] = function (self, trace, data)
		local value, value_ty = self:CompileExpr(data[3])

		if data[1] then
			-- Local declaration. Fastest case.
			local var_name = data[2][1][1].value
			self:AssertW(not self.scope.vars[var_name], "Do not redeclare existing variable " .. var_name, trace)
			self:Assert(not self.scope.vars[var_name] or not self.scope.vars[var_name].const, "Cannot redeclare constant variable", trace)

			self.scope:DeclVar(var_name, { initialized = true, trace_if_unused = data[2][1][1].trace, type = value_ty })
			return function(state) ---@param state RuntimeContext
				state.Scope[var_name] = value(state)
			end
		end

		local stmts = {}
		for i, v in ipairs(data[2]) do
			local var, indices, trace = v[1].value, v[2], v[3]

			local existing = self.scope:LookupVar(var)
			if existing then
				local expr_ty = existing.type

				-- It can have indices, it already exists
				if #indices > 0 then
					existing.trace_if_unused = nil

					local setter, id = table.remove(indices), existing.depth
					stmts[i] = function(state)
						return state.Scopes[id][var]
					end

					for _, index in ipairs(indices) do
						local key, key_ty = self:CompileExpr(index[1])

						local op
						if index[2] then -- <EXPR>[<EXPR>, <type>]
							local ty = self:CheckType(index[2])
							op, expr_ty = self:GetOperator("indexget", { expr_ty, key_ty, ty }, index[3])
						else -- <EXPR>[<EXPR>]
							op, expr_ty = self:GetOperator("indexget", { expr_ty, key_ty }, index[3])
						end

						local handle = stmts[i] -- need this, or stack overflow...
						stmts[i] = function(state)
							return op(state, handle(state), key(state))
						end
					end

					local key, key_ty = self:CompileExpr(setter[1])

					local op
					if setter[2] then -- <EXPR>[<EXPR>, <type>]
						local ty = self:CheckType(setter[2])
						self:Assert(ty == value_ty, "Cannot assign type " .. value_ty .. " to object expecting " .. ty, trace)
						op, expr_ty = self:GetOperator("indexset", { expr_ty, key_ty, ty }, setter[3])
					else -- <EXPR>[<EXPR>]
						op, expr_ty = self:GetOperator("indexset", { expr_ty, key_ty, value_ty }, setter[3])
					end

					local handle = stmts[i] -- need this, or stack overflow...
					stmts[i] = function(state, val) ---@param state RuntimeContext
						op(state, handle(state), key(state), val)
					end
				else
					self:Assert(existing.type == value_ty, "Cannot assign type (" .. value_ty .. ") to variable of type (" .. existing.type .. ")", trace)
					self:Assert(not existing.const, "Cannot assign to constant variable " .. var, trace)
					existing.initialized = true

					local id = existing.depth
					if id == 0 then
						if self.delta_vars[var] then
							if E2Lib.IOTableTypes[value_ty] then
								stmts[i] = function(state, val) ---@param state RuntimeContext
									state.GlobalScope["$" .. var] = state.GlobalScope[var]
									state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true

									if state.GlobalScope.lookup[val] then
										state.GlobalScope.lookup[val][var] = true
									else
										state.GlobalScope.lookup[val] = { [var] = true }
									end
								end
							else
								stmts[i] = function(state, val) ---@param state RuntimeContext
									state.GlobalScope["$" .. var] = state.GlobalScope[var]
									state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true
								end
							end
						elseif E2Lib.IOTableTypes[value_ty] then
							stmts[i] = function(state, val) ---@param state RuntimeContext
								state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true

								if state.GlobalScope.lookup[val] then
									state.GlobalScope.lookup[val][var] = true
								else
									state.GlobalScope.lookup[val] = { [var] = true }
								end
							end
						else
							stmts[i] = function(state, val) ---@param state RuntimeContext
								state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true
							end
						end
					else
						stmts[i] = function(state, val) ---@param state RuntimeContext
							state.Scopes[id][var] = val
						end
					end
				end
			else
				-- Cannot have indices.
				self:Assert(#indices == 0, "Variable (" .. var .. ") does not exist", trace)
				self.global_scope:DeclVar(var, { type = value_ty, initialized = true, trace_if_unused = trace })

				if self.delta_vars[var] then
					if E2Lib.IOTableTypes[value_ty] then
						stmts[i] = function(state, val) ---@param state RuntimeContext
							state.GlobalScope["$" .. var] = state.GlobalScope[var] -- Set $Var to old value to be used in $ operator.
							state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true

							if state.GlobalScope.lookup[val] then
								state.GlobalScope.lookup[val][var] = true
							else
								state.GlobalScope.lookup[val] = { [var] = true }
							end
						end
					else
						stmts[i] = function(state, val) ---@param state RuntimeContext
							state.GlobalScope["$" .. var] = state.GlobalScope[var] -- Set $Var to old value to be used in $ operator.
							state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true
						end
					end
				elseif E2Lib.IOTableTypes[value_ty] then
					stmts[i] = function(state, val) ---@param state RuntimeContext
						state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true

						if state.GlobalScope.lookup[val] then
							state.GlobalScope.lookup[val][var] = true
						else
							state.GlobalScope.lookup[val] = { [var] = true }
						end
					end
				else
					stmts[i] = function(state, val) ---@param state RuntimeContext
						state.GlobalScope[var], state.GlobalScope.vclk[var] = val, true
					end
				end
			end
		end

		return function(state) ---@param state RuntimeContext
			local val = value(state)
			for _, stmt in ipairs(stmts) do
				stmt(state, val)
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Node }
	[NodeVariant.Const] = function (self, trace, data)
		local name, expr, expr_ty = data[1].value, self:CompileExpr(data[2])
		self:Assert(not self.scope.vars[name], "Cannot redeclare existing variable " .. name, trace)
		self.scope:DeclVar(name, { type = expr_ty, initialized = true, const = true, trace_if_unused = data[1].trace })

		return function(state)
			state.Scope[name] = expr(state)
		end
	end,

	---@param data Token<string>
	[NodeVariant.Increment] = function (self, trace, data)
		-- Transform V-- to V = V + 1
		local one = Node.new(NodeVariant.ExprLiteral, { "n", 1 }, trace)
		local var = Node.new(NodeVariant.ExprIdent, data, data.trace)

		local result = Node.new(
			NodeVariant.ExprArithmetic,
			{ var, Operator.Add, one },
			trace
		)

		return self:CompileStmt(Node.new(
			NodeVariant.Assignment,
			{ false, { { data, {}, trace } }, result },
			trace
		))
	end,

	---@param data Token<string>
	[NodeVariant.Decrement] = function (self, trace, data)
		-- Transform V-- to V = V - 1
		local one = Node.new(NodeVariant.ExprLiteral, { "n", 1 }, trace)
		local var = Node.new(NodeVariant.ExprIdent, data, data.trace)

		local result = Node.new(
			NodeVariant.ExprArithmetic,
			{ var, Operator.Sub, one },
			trace
		)

		return self:CompileStmt(Node.new(
			NodeVariant.Assignment,
			{ false, { { data, {}, trace } }, result },
			trace
		))
	end,

	---@param data { [1]: Token<string>, [2]: Operator, [3]: Node }
	[NodeVariant.CompoundArithmetic] = function(self, trace, data)
		-- Transform V <op>= E -> V = V <op> E
		local result = Node.new(
			NodeVariant.ExprArithmetic,
			{ Node.new(NodeVariant.ExprIdent, data[1], data[1].trace), data[2], data[3] },
			trace
		)

		return self:CompileStmt(Node.new(
			NodeVariant.Assignment,
			{ false, { { data[1], {}, trace } }, result },
			trace
		))
	end,

	---@param data { [1]: Node, [2]: Node }
	[NodeVariant.ExprDefault] = function(self, trace, data)
		local cond, cond_ty = self:CompileExpr(data[1])
		local expr, expr_ty = self:CompileExpr(data[2])

		self:Assert(cond_ty == expr_ty, "Cannot use default (?:) operator with differing types", trace)

		local op = self:GetOperator("is", { cond_ty }, trace)
		return function(state) ---@param state RuntimeContext
			local iff = cond(state)
			return op(state, iff) ~= 0 and iff or expr(state)
		end, cond_ty
	end,

	---@param data { [1]: Node, [2]: Node }
	[NodeVariant.ExprTernary] = function(self, trace, data)
		local cond, cond_ty = self:CompileExpr(data[1])
		local iff, iff_ty = self:CompileExpr(data[2])
		local els, els_ty = self:CompileExpr(data[3])

		self:Assert(iff_ty == els_ty, "Cannot use ternary (A ? B : C) operator with differing types", trace)

		local op = self:GetOperator("is", { cond_ty }, trace)
		return function(state) ---@param state RuntimeContext
			return op(state, cond(state)) ~= 0 and iff(state) or els(state)
		end, iff_ty
	end,

	---@param data { [1]: string, [2]: string|number|table }
	[NodeVariant.ExprLiteral] = function (self, trace, data)
		local val = data[2]
		self.scope.data.ops = self.scope.data.ops + 0.125
		return function()
			return val
		end, data[1]
	end,

	---@param data Token<string>
	[NodeVariant.ExprIdent] = function (self, trace, data)
		local var, name = self:Assert(self.scope:LookupVar(data.value), "Undefined variable (" .. data.value .. ")", trace), data.value
		var.trace_if_unused = nil

		self:AssertW(var.initialized, "Use of variable [" .. name .. "] before initialization", trace)
		self.scope.data.ops = self.scope.data.ops + 0.25

		local id = var.depth
		return function(state) ---@param state RuntimeContext
			return state.Scopes[id][name]
		end, var.type
	end,

	---@param data Token<string>
	[NodeVariant.ExprConstant] = function (self, trace, data, used_as_stmt)
		local value = self:Assert( wire_expression2_constants[data.value], "Invalid constant: " .. data.value, trace ).value

		local ty = type(value)
		if ty == "number" then
			return self:CompileExpr( Node.new(NodeVariant.ExprLiteral, { "n", value }, trace) )
		elseif ty == "string" then
			return self:CompileExpr( Node.new(NodeVariant.ExprLiteral, { "s", value }, trace) )
		elseif ty == "Vector" and wire_expression2_funcs["vec(nnn)"] then
			return self:CompileExpr(Node.new(NodeVariant.ExprCall, {
				Token.new(TokenVariant.String, "vec"),
				{
					Node.new(NodeVariant.ExprLiteral, { "n", value[1] }, trace),
					Node.new(NodeVariant.ExprLiteral, { "n", value[2] }, trace),
					Node.new(NodeVariant.ExprLiteral, { "n", value[3] }, trace)
				}
			}, trace))
		elseif ty == "Angle" and wire_expression2_funcs["ang(nnn)"] then
			return self:CompileExpr(Node.new(NodeVariant.ExprCall, {
				Token.new(TokenVariant.String, "ang"),
				{
					Node.new(NodeVariant.ExprLiteral, { "n", value[1] }, trace),
					Node.new(NodeVariant.ExprLiteral, { "n", value[2] }, trace),
					Node.new(NodeVariant.ExprLiteral, { "n", value[3] }, trace)
				}
			}, trace))
		elseif ty == "table" then -- Know it's an array already from registerConstant
			local out = {}
			for i, val in ipairs(value) do
				local ty = type(val)
				if ty == "number" then
					out[i] = Node.new(NodeVariant.ExprLiteral, { "n", val }, trace)
				elseif ty == "string" then
					out[i] = Node.new(NodeVariant.ExprLiteral, { "s", val }, trace)
				elseif ty == "Vector" then
					out[i] = Node.new(NodeVariant.ExprCall, {
						Token.new(TokenVariant.String, "vec"),
						{
							Node.new(NodeVariant.ExprLiteral, { "n", val[1] }, trace),
							Node.new(NodeVariant.ExprLiteral, { "n", val[2] }, trace),
							Node.new(NodeVariant.ExprLiteral, { "n", val[3] }, trace)
						}
					}, trace)
				elseif ty == "Angle" then
					out[i] = Node.new(NodeVariant.ExprCall, {
						Token.new(TokenVariant.String, "ang"),
						{
							Node.new(NodeVariant.ExprLiteral, { "n", val[1] }, trace),
							Node.new(NodeVariant.ExprLiteral, { "n", val[2] }, trace),
							Node.new(NodeVariant.ExprLiteral, { "n", val[3] }, trace)
						}
					}, trace)
				else
					self:Error("Constant " .. data.value .. " has invalid data type", trace)
				end
			end

			return self:CompileExpr( Node.new(NodeVariant.ExprArray, out, trace) )
		else
			self:Error("Constant " .. data.value .. " has invalid data type", trace)
		end
	end,

	---@param data Node[]|{ [1]: Node, [2]:Node }[]
	[NodeVariant.ExprArray] = function (self, trace, data)
		if #data == 0 then
			return function()
				return {}
			end, "r"
		elseif data[1][2] then -- key value array
			---@cast data { [1]: Node, [2]: Node }[] # Key value pair arguments

			local numbers = {}
			for _, kvpair in ipairs(data) do
				local key, key_ty = self:CompileExpr(kvpair[1])

				if key_ty == "n" then
					local value, ty = self:CompileExpr(kvpair[2])
					self:Assert(not BLOCKED_ARRAY_TYPES[ty], "Cannot use type " .. ty .. " as array value", kvpair[2].trace)
					numbers[key] = value
				else
					self:Error("Cannot use type " .. key_ty .. " as array key", kvpair[1].trace)
				end
			end

			return function(state) ---@param state RuntimeContext
				local array = {}

				for key, value in pairs(numbers) do
					array[key(state)] = value(state)
				end

				return array
			end, "r"
		else
			local args = {}
			for k, arg in ipairs(data) do
				local value, ty = self:CompileExpr(arg)
				self:Assert(not BLOCKED_ARRAY_TYPES[ty], "Cannot use type " .. ty .. " as array value", trace)
				args[k] = value
			end

			return function(state) ---@param state RuntimeContext
				local array = {}
				for i, val in ipairs(args) do
					array[i] = val(state)
				end
				return array
			end, "r"
		end
	end,

	[NodeVariant.ExprTable] = function (self, trace, data)
		if #data == 0 then
			return function()
				return { n = {}, ntypes = {}, s = {}, stypes = {}, size = 0 }
			end, "t"
		elseif data[1][2] then
			---@cast data { [1]: Node, [2]: Node }[] # Key value pair arguments

			local strings, numbers, nstrings, nnumbers, size = {}, {}, 0, 0, #data
			for _, kvpair in ipairs(data) do
				local key, key_ty = self:CompileExpr(kvpair[1])
				local value, value_ty = self:CompileExpr(kvpair[2])

				if key_ty == "s" then
					nstrings = nstrings + 1
					strings[nstrings] = { key, value, value_ty }
				elseif key_ty == "n" then
					nnumbers = nnumbers + 1
					numbers[nnumbers] = { key, value, value_ty }
				else
					self:Error("Cannot use type " .. key_ty .. " as table key", kvpair[1].trace)
				end
			end

			return function(state) ---@param state RuntimeContext
				local s, stypes, n, ntypes = {}, {}, {}, {}

				for i = 1, nstrings do
					local data = strings[i]
					local key, value, valuetype = data[1](state), data[2], data[3]
					s[key], stypes[key] = value(state), valuetype
				end

				for i = 1, nnumbers do
					local data = numbers[i]
					local key, value, valuetype = data[1](state), data[2], data[3]
					n[key], ntypes[key] = value(state), valuetype
				end

				return { s = s, stypes = stypes, n = n, ntypes = ntypes, size = size }
			end, "t"
		else
			---@cast data Node[]
			local args, argtypes, len = {}, {}, #data
			for k, arg in ipairs(data) do
				args[k], argtypes[k] = self:CompileExpr(arg)
			end

			return function(state) ---@param state RuntimeContext
				local array = {}
				for i = 1, len do
					array[i] = args[i](state)
				end
				return { n = array, ntypes = argtypes, s = {}, stypes = {}, size = len }
			end, "t"
		end
	end,

	---@param data { [1]: Parameter[], [2]: Node }
	[NodeVariant.ExprFunction] = function(self, trace, data)
		---@type EnvFunction
		local fn, param_names, param_types, nargs = { attrs = {} }, {}, {}, #data[1]

		local block = self:Scope(function(scope)
			scope.data["function"] = { "<anonymous>", fn }

			for i, param in ipairs(data[1]) do
				self:Assert(param.type, "Cannot omit parameter type for lambda, annotate with :<type>", param.name.trace)
				param_names[i], param_types[i] = param.name.value, self:Assert(self:CheckType(param.type), "Cannot use void as parameter", param.name.trace)
				self:Assert(not param.variadic, "Variadic lambdas are not supported, use an array instead", param.name.trace)
				scope:DeclVar(param.name.value, { type = param_types[i], initialized = true, trace_if_unused = param.name.trace })
			end

			local block = self:CompileStmt(data[2])

			if fn.ret then -- Ensure function either returns or errors
				self:Assert(scope.data.dead, "Not all codepaths return a value of type '" .. fn.ret .. "'", trace)
			end

			return block
		end)

		local ret = fn.ret
		local expected_sig = table.concat(param_types)

		self.scope.data.ops = self.scope.data.ops + 25

		return function(state)
			local inherited_scopes, after = {}, state.ScopeID + 1
			for i = 0, state.ScopeID do
				inherited_scopes[i] = state.Scopes[i]
			end

			return E2Lib.Lambda.new(
				expected_sig,
				ret,
				function(args)
					local s_scopes, s_scope, s_scopeid = state.Scopes, state.Scope, state.ScopeID

					state.prf = state.prf + 10

					local scope = { vclk = {} }
					state.Scopes = inherited_scopes
					state.ScopeID = after
					state.Scopes[after] = scope
					state.Scope = scope

					for i = 1, nargs do
						scope[param_names[i]] = args[i]
					end

					block(state)

					state.ScopeID, state.Scope, state.Scopes = s_scopeid, s_scope, s_scopes

					state.__return__ = false
					return state.__returnval__
				end
			)
		end, "f"
	end,

	[NodeVariant.ExprArithmetic] = handleInfixOperation,

	---@param data { [1]: Node, [2]: Operator, [3]: self }
	[NodeVariant.ExprLogicalOp] = function(self, trace, data)
		local lhs, lhs_ty = self:CompileExpr(data[1])
		local rhs, rhs_ty = self:CompileExpr(data[3])

		-- self:Assert(lhs_ty == rhs_ty, "Cannot perform logical operation on differing types", trace)

		local op_lhs, op_lhs_ret = self:GetOperator("is", { lhs_ty }, trace)
		local op_rhs, op_rhs_ret = self:GetOperator("is", { rhs_ty }, trace)

		self:Assert(op_lhs_ret == "n", "Cannot perform logical operation on type " .. op_lhs_ret, trace)
		self:Assert(op_rhs_ret == "n", "Cannot perform logical operation on type " .. op_rhs_ret, trace)

		if data[2] == Operator.Or then
			return function(state)
				return ((op_lhs(state, lhs(state)) ~= 0) or (op_rhs(state, rhs(state)) ~= 0)) and 1 or 0
			end, "n"
		else -- Operator.And
			return function(state)
				return (op_lhs(state, lhs(state)) ~= 0 and op_rhs(state, rhs(state)) ~= 0) and 1 or 0
			end, "n"
		end
	end,

	[NodeVariant.ExprBinaryOp] = handleInfixOperation,
	[NodeVariant.ExprComparison] = handleInfixOperation,

	[NodeVariant.ExprEquals] = function(self, trace, data)
		local lhs, lhs_ty = self:CompileExpr(data[1])
		local rhs, rhs_ty = self:CompileExpr(data[3])

		self:Assert(lhs_ty == rhs_ty, "Cannot perform equality operation on differing types", trace)

		local op, op_ret, legacy = self:GetOperator("eq", { lhs_ty, rhs_ty }, trace)
		self:Assert(op_ret == "n", "Cannot use perform equality operation on type " .. lhs_ty, trace)

		if data[2] == Operator.Eq then
			if legacy then
				local largs = { [1] = {}, [2] = { lhs }, [3] = { rhs }, [4] = { lhs_ty, rhs_ty } }
				return function(state)
					return op(state, largs)
				end, "n"
			else
				return function(state)
					return op(state, lhs(state), rhs(state))
				end, "n"
			end
		elseif data[2] == Operator.Neq then
			if legacy then
				local largs = { [1] = {}, [2] = { lhs }, [3] = { rhs }, [4] = { lhs_ty, rhs_ty } }
				return function(state)
					return op(state, largs) == 0 and 1 or 0
				end, "n"
			else
				return function(state)
					return op(state, lhs(state), rhs(state)) == 0 and 1 or 0
				end, "n"
			end
		end
	end,

	[NodeVariant.ExprBitShift] = handleInfixOperation,

	---@param data { [1]: Operator, [2]: Node, [3]: self }
	[NodeVariant.ExprUnaryOp] = function(self, trace, data)
		local exp, ty = self:CompileExpr(data[2])

		if data[1] == Operator.Not then -- Return opposite of operator_is result
			local op = self:GetOperator("is", { ty }, trace)
			return function(state)
				return op(state, exp(state)) == 0 and 1 or 0
			end, "n"
		elseif data[1] == Operator.Sub then -- Negate
			local op, op_ret, legacy = self:GetOperator("neg", { ty }, trace)
			if legacy then
				local largs = { [1] = {}, [2] = { exp }, [3] = { ty } }
				return function(state)
					return op(state, largs)
				end, op_ret
			else
				return function(state)
					return op(state, exp(state))
				end, op_ret
			end
		end
	end,

	---@param data { [1]: Operator, [2]: Token<string> }
	[NodeVariant.ExprUnaryWire] = function(self, trace, data)
		local var_name = data[2].value
		local var = self:Assert(self.scope:LookupVar(var_name), "Undefined variable (" .. var_name .. ")", trace)
		var.trace_if_unused = nil
		self:AssertW(var.initialized, "Use of variable [" .. var_name .. "] before initialization", trace)

		if data[1] == Operator.Dlt then -- $
			self:Warning("Delta operator ($) is deprecated. Recommended to handle variable differences yourself.", trace)
			self:Assert(var.depth == 0, "Delta operator ($) can not be used on temporary variables", trace)

			local sub_op, sub_ty = self:GetOperator("sub", { var.type, var.type }, trace)
			return function(state) ---@param state RuntimeContext
				return sub_op(state, state.GlobalScope[var_name], state.GlobalScope["$" .. var_name])
			end, sub_ty
		elseif data[1] == Operator.Trg then -- ~
			return function(state) ---@param state RuntimeContext
				return state.triggerinput == var_name and 1 or 0
			end, "n"
		elseif data[1] == Operator.Imp then -- ->
			if self.inputs[3][var_name] then
				return function(state) ---@param state RuntimeContext
					return IsValid(state.entity.Inputs[var_name].Src) and 1 or 0
				end, "n"
			elseif self.outputs[3][var_name] then
				return function(state) ---@param state RuntimeContext
					local tbl = state.entity.Outputs[var_name].Connected
					local ret = #tbl
					for i = 1, ret do
						if not IsValid(tbl[i].Entity)then
							ret = ret - 1
						end
					end
					return ret
				end, "n"
			else
				self:Error("Can only use connected (->) operator on inputs or outputs", trace)
			end
		end
	end,

	---@param data { [1]: Node, [2]: Index[] }
	[NodeVariant.ExprIndex] = function (self, trace, data)
		local expr, expr_ty = self:CompileExpr(data[1])
		for i, index in ipairs(data[2]) do
			local key, key_ty = self:CompileExpr(index[1])

			local op
			if index[2] then -- <EXPR>[<EXPR>, <type>]
				local ty = self:CheckType(index[2])
				op, expr_ty = self:GetOperator("indexget", { expr_ty, key_ty, ty }, index[3])
			else -- <EXPR>[<EXPR>]
				op, expr_ty = self:GetOperator("indexget", { expr_ty, key_ty }, index[3])
			end

			local handle = expr -- need this, or stack overflow...
			expr = function(state)
				return op(state, handle(state), key(state))
			end
		end

		return expr, expr_ty
	end,

	---@param data { [1]: Token<string>, [2]: Node[] }
	[NodeVariant.ExprCall] = function (self, trace, data, used_as_stmt)
		local name, args, types = data[1], {}, {}

		if name.value == "changed" and data[2][1].variant == NodeVariant.ExprIdent and self.inputs[3][data[2][1].data.value] then
			self:Warning("Use ~ instead of changed() for inputs", trace, { { replace = "~" .. data[2][1].data.value, at = trace } })
		end

		for k, arg in ipairs(data[2]) do
			args[k], types[k] = self:CompileExpr(arg)
		end

		local arg_sig = table.concat(types)
		local fn_data = self:Assert(self:GetFunction(data[1].value, types), "No such function: " .. name.value .. "(" .. table.concat(types, ", ") .. ")", name.trace)
		self.scope.data.ops = self.scope.data.ops + fn_data.cost

		self:AssertW(not (used_as_stmt and fn_data.attrs.nodiscard), "The return value of this function cannot be discarded", trace)

		if fn_data.attrs["deprecated"] then
			local value = fn_data.attrs["deprecated"]
			self:Warning("Use of deprecated function (" .. name.value .. ") " .. (type(value) == "string" and value or ""), trace)
		end

		if fn_data.attrs["noreturn"] then
			self.scope.data.dead = true
		end

		local nargs = #args
		local user_function = self.user_functions[name.value] and self.user_functions[name.value][arg_sig]
		if user_function then
			if self.strict then -- If @strict, functions are compile time constructs (like events).
				local fn = user_function.op
				return function(state)
					local rargs = {}
					for k = 1, nargs do
						rargs[k] = args[k](state)
					end
					return fn(state, rargs, types)
				end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
			else
				local full_sig = name.value .. "(" .. arg_sig .. ")"
				return function(state) ---@param state RuntimeContext
					local rargs = {}
					for k = 1, nargs do
						rargs[k] = args[k](state)
					end

					local fn = state.funcs[full_sig]
					if fn then
						return state.funcs[full_sig](state, rargs, types)
					else
						state:forceThrow("No such function defined at runtime: " .. full_sig)
					end
				end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
			end
		elseif fn_data.attrs["legacy"] then -- Not a user function. Can get function to call at compile time.
			local fn, largs = fn_data.op, { [1] = {}, [nargs + 2] = types }
			for i = 1, nargs do
				largs[i + 1] = { [1] = args[i] }
			end
			return function(state) ---@param state RuntimeContext
				return fn(state, largs)
			end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
		else
			local fn = fn_data.op
			return function(state) ---@param state RuntimeContext
				local rargs = {}
				for k = 1, nargs do
					rargs[k] = args[k](state)
				end

				return fn(state, rargs, types)
			end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
		end
	end,

	---@param data { [1]: Node, [2]: Token<string>, [3]: Node[] }
	[NodeVariant.ExprMethodCall] = function (self, trace, data, used_as_stmt)
		local name, args, types = data[2], {}, {}
		for k, arg in ipairs(data[3]) do
			args[k], types[k] = self:CompileExpr(arg)
		end

		local arg_sig = table.concat(types)
		local meta, meta_type = self:CompileExpr(data[1])

		local fn_data = self:Assert(self:GetFunction(name.value, types, meta_type), "No such method: " .. (meta_type or "void") .. ":" .. name.value .. "(" .. table.concat(types, ", ") .. ")", name.trace)
		self.scope.data.ops = self.scope.data.ops + fn_data.cost

		self:AssertW(not (used_as_stmt and fn_data.attrs.nodiscard), "The return value of this function cannot be discarded", trace)

		if fn_data.attrs["deprecated"] then
			local value = fn_data.attrs["deprecated"]
			self:Warning("Use of deprecated function (" .. name.value .. ") " .. (type(value) == "string" and value or ""), trace)
		end

		local nargs = #args
		local user_method = self.user_methods[meta_type] and self.user_methods[meta_type][name.value] and self.user_methods[meta_type][name.value][arg_sig]
		if user_method then
			if self.strict then -- If @strict, functions are compile time constructs (like events).
				local fn = user_method.op
				return function(state)
					local rargs = { meta(state) }
					for k = 1, nargs do
						rargs[k + 1] = args[k](state)
					end
					return fn(state, rargs, types)
				end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
			else
				local full_sig = name.value .. "(" .. meta_type .. ":" .. arg_sig .. ")"
				return function(state) ---@param state RuntimeContext
					local rargs = { meta(state) }
					for k = 1, nargs do
						rargs[k + 1] = args[k](state)
					end

					local fn = state.funcs[full_sig]
					if fn then
						return state.funcs[full_sig](state, rargs, types)
					else
						state:forceThrow("No such method defined at runtime: " .. full_sig)
					end
				end, fn_data.ret and (fn_data.ret ~= "" and fn_data.ret or nil)
			end
		elseif fn_data.attrs["legacy"] then
			local fn, largs = fn_data.op, { [nargs + 3] = types, [2] = { [1] = meta } }
			for k = 1, nargs do
				largs[k + 2] = { [1] = args[k] }
			end

			return function(state) ---@param state RuntimeContext
				return fn(state, largs)
			end, fn_data.ret
		else
			local fn = fn_data.op
			return function(state) ---@param state RuntimeContext
				local rargs = { meta(state) }
				for k = 1, nargs do
					rargs[k + 1] = args[k](state)
				end

				return fn(state, rargs, types)
			end, fn_data.ret
		end
	end,

	---@param data { [1]: Node, [2]: Node[], [3]: Token<string>? }
	[NodeVariant.ExprDynCall] = function (self, trace, data)
		local expr, expr_ty = self:CompileExpr(data[1])

		local args, arg_types = {}, {}
		for i, arg in ipairs(data[2]) do
			args[i], arg_types[i] = self:CompileExpr(arg)
		end

		local ret_type = data[3] and self:CheckType(data[3])

		if expr_ty == "s" then
			self:Warning("String calls are deprecated. Use lambdas instead. This will be an error on @strict in the future.", trace)
			self.scope.data.ops = self.scope.data.ops + 25

			local type_sig = table.concat(arg_types)
			local arg_sig = "(" .. type_sig .. ")"
			local meta_arg_sig = #arg_types >= 1 and ("(" .. arg_types[1] .. ":" .. table.concat(arg_types, "", 2) .. ")") or "()"

			local nargs = #args
			return function(state) ---@param state RuntimeContext
				local rargs = {}
				for k = 1, nargs do
					rargs[k] = args[k](state)
				end

				local fn_name = expr(state)
				local sig, meta_sig = fn_name .. arg_sig, fn_name .. meta_arg_sig

				local fn = state.funcs[sig] or state.funcs[meta_sig]
				if fn then -- first check if user defined any functions that match signature
					local r = state.funcs_ret[sig] or state.funcs_ret[meta_sig]
					if r ~= ret_type then
						state:forceThrow( "Mismatching return types. Got " .. (r or "void") .. ", expected " .. (ret_type or "void"))
					end

					return fn(state, rargs, arg_types)
				else -- no user defined functions, check builtins
					fn = wire_expression2_funcs[sig] or wire_expression2_funcs[meta_sig]
					if fn then
						local r = fn[2]
						if r ~= ret_type and not (ret_type == nil and r == "") then
							state:forceThrow( "Mismatching return types. Got " .. (r or "void") .. ", expected " .. (ret_type or "void"))
						end

						if fn.attributes.legacy then
							local largs = { [1] = {}, [nargs + 2] = arg_types }
							for i = 1, nargs do
								largs[i + 1] = { [1] = function() return rargs[i] end }
							end
							return fn[3](state, largs, arg_types)
						else
							return fn[3](state, rargs, arg_types)
						end
					else -- none found, check variadic builtins
						for i = nargs, 0, -1 do
							local varsig = fn_name .. "(" .. type_sig:sub(1, i) .. "...)"
							local fn = wire_expression2_funcs[varsig]
							if fn then
								local r = fn[2]
								if r ~= ret_type and not (ret_type == nil and r == "") then
									state:forceThrow("Mismatching return types. Got " .. (r or "void") .. ", expected " .. (ret_type or "void"))
								end

								if fn.attributes.legacy then
									local largs = { [1] = {}, [nargs + 2] = arg_types }
									for i = 1, nargs do
										largs[i + 1] = { [1] = function() return rargs[i] end }
									end
									return fn[3](state, largs, arg_types)
								elseif varsig == "array(...)" then -- Need this since can't enforce compile time argument type restrictions on string calls. Woop. Array creation should not be a function..
									local i = 1
									while i <= #arg_types do
										local ty = arg_types[i]
										if BLOCKED_ARRAY_TYPES[ty] then
											table.remove(rargs, i)
											table.remove(arg_types, i)
											state:forceThrow("Cannot use type " .. ty .. " for argument #" .. i .. " in stringcall array creation")
										else
											i = i + 1
										end
									end
								end

								return fn[3](state, rargs, arg_types)
							else
								local varsig = fn_name .. "(" .. type_sig:sub(1, i) .. "..r)"
								local fn = state.funcs[varsig]

								if fn then
									for _, ty in ipairs(arg_types) do -- Just block them entirely. Current method of finding variadics wouldn't allow a proper solution that works with x<yz> types. Would need to rewrite all of this which I don't think is worth it when already nobody is going to use this functionality.
										if BLOCKED_ARRAY_TYPES[ty] then
											state:forceThrow("Cannot pass array into variadic array function")
										end
									end

									return fn(state, rargs, arg_types)
								else
									local varsig = fn_name .. "(" .. type_sig:sub(1, i) .. "..t)"
									local fn = state.funcs[varsig]
									if fn then
										return fn(state, rargs, arg_types)
									end
								end
							end
						end

						state:forceThrow("No such function: " .. fn_name .. arg_sig)
					end
				end
			end, ret_type
		elseif expr_ty == "f" then
			local nargs = #args
			local sig = table.concat(arg_types)

			return function(state)
				---@type E2Lambda
				local f = expr(state)

				if f.arg_sig ~= sig then
					state:forceThrow("Incorrect arguments passed to lambda, expected (" .. f.arg_sig .. ") got (" .. sig .. ")")
				elseif f.ret ~= ret_type then
					state:forceThrow("Expected type " .. (ret_type or "void") .. " from lambda, got " .. (f.ret or "void"))
				else
					local rargs = {}
					for k = 1, nargs do
						rargs[k] = args[k](state)
					end
					return f.fn(rargs)
				end
			end, ret_type
		else
			self:Error("Cannot call type of " .. expr_ty, trace)
		end
	end,

	---@param data { [1]: Token<string>, [2]: Parameter[], [3]: Node }
	[NodeVariant.Event] = function (self, trace, data)
		self:AssertW(self.scope:IsGlobalScope() or (self.include and self.scope:Depth() == 1), "Events cannot be nested inside of statements, they are compile time constructs. This will become a hard error in the future!", trace)

		---@type string, { [1]: string, [2]: string }[]
		local name, params = data[1].value, {}
		for i, param in ipairs(data[2]) do
			local type = param.type and self:CheckType(param.type)
			if not type then
				self:Warning("Use of implicit parameter type is deprecated", param.name.trace, { { replace = param.name.value .. ":number", at = param.name.trace } })
				type = "n"
			end
			params[i] = { param.name.value, type }
		end

		local event = self:Assert(E2Lib.Env.Events[name], "No such event exists: '" .. name .. "'", trace)
		if #params > #event.args then
			local extra_arg_types = {}
			for i = #event.args + 1, #params do
				-- name, type, variadic
				extra_arg_types[#extra_arg_types + 1] = params[i][2]
			end

			self:Error("Event '" .. name .. "' does not take arguments (" .. table.concat(extra_arg_types, ", ") .. ")", trace)
		end

		for k, arg in ipairs(event.args) do
			if not params[k] then
				-- TODO: Maybe this should be a warning so that events can have extra params added without breaking old code?
				self:Error("Event '" .. name .. "' missing argument #" .. k .. " of type " .. tostring(arg), trace)
			end

			if arg.type ~= params[k][2] then
				self:Error("Mismatched event argument: " .. arg.type .. " vs " .. tostring(params[k][2]), trace)
			end
		end

		if (self.registered_events[name] and self.registered_events[name][self.include or "__main__"]) then
			self:Error("You can only register one event callback per file", trace)
		end

		self.registered_events[name] = self.registered_events[name] or {}

		local block = self:IsolatedScope(function(scope)
			for k, arg in ipairs(event.args) do
				scope:DeclVar(params[k][1], { type = arg.type, initialized = true, trace_if_unused = params[k][3] })
			end

			return self:CompileStmt(data[3])
		end)

		self.registered_events[name][self.include or "__main__"] = function(state, args) ---@param state RuntimeContext
			local s_scopes, s_scopeid, s_scope = state.Scopes, state.ScopeID, state.Scope

			local scope = { vclk = {} } -- Hack in the fact that functions don't have upvalues right now.
			state.Scopes = { [0] = state.GlobalScope, [1] = scope }
			state.Scope = scope
			state.ScopeID = 1

			for i, param in ipairs(params) do
				scope[param[1]] = args[i]
			end

			block(state)

			state.Scopes, state.ScopeID, state.Scope = s_scopes, s_scopeid, s_scope
		end

		return nil
	end
}

---@alias TypeSignature string

local function DEFAULT_EQUALS(self, lhs, rhs)
	return lhs == rhs and 1 or 0
end

---@param variant string
---@param types TypeSignature[]
---@param trace Trace
---@return RuntimeOperator fn
---@return TypeSignature signature
---@return boolean legacy
---@return boolean default
function Compiler:GetOperator(variant, types, trace)
	local fn = wire_expression2_funcs["op:" .. variant .. "(" .. table.concat(types) .. ")"]
	if fn then
		self.scope.data.ops = self.scope.data.ops + (fn[4] or 2) + (fn.attributes.legacy and 1 or 0)
		return fn[3], fn[2], fn.attributes.legacy, false
	elseif variant == "eq" and #types == 2 and types[1] == types[2] then
		-- If no equals operator present, default to just basic lua equals.
		self.scope.data.ops = self.scope.data.ops + 1
		return DEFAULT_EQUALS, "n", false, true
	end

	self:Error("No such operator: " .. variant .. " (" .. table.concat(types, ", ") .. ")", trace)
end

---@param name string
---@param types TypeSignature[]
---@param method? string
---@return EnvFunction? function
---@return boolean? variadic
function Compiler:GetUserFunction(name, types, method)
	---@type EnvFunction
	local overloads
	if method then
		overloads = self.user_methods[method]
		if not overloads then return end
		overloads = overloads[name]
	else
		overloads = self.user_functions[name]
	end
	if not overloads then return end

	local param_sig = table.concat(types)
	if overloads[param_sig] then return overloads[param_sig], false end

	for i = #types, 0, -1 do
		local sig = table.concat(types, "", 1, i)

		local fn = overloads[sig .. "..r"]
		if fn then
			for j = i, #types do
				if BLOCKED_ARRAY_TYPES[types[j]] then
					self:Error("Cannot call variadic array function (" .. name .. ") with a " .. tostring(types[j]) .. " value.", trace)
				end
			end
			return fn, true
		end

		fn = overloads[sig .. "..t"]
		if fn then return fn, true end
	end
end

---@param name string
---@param types TypeSignature[]
---@param method? string
---@return EnvFunction?
---@return boolean? variadic
---@return boolean? userfunction
function Compiler:GetFunction(name, types, method)
	local sig, method_prefix = table.concat(types), method and (method .. ":") or ""

	local fn = wire_expression2_funcs[name .. "(" .. method_prefix .. sig .. ")"]
	if fn then return { op = fn[3], ret = fn[2], args = types, cost = fn[4], attrs = fn.attributes }, false, false end

	local fn, variadic = self:GetUserFunction(name, types, method)
	if fn then return fn, variadic, true end

	for i = #sig, 0, -1 do
		fn = wire_expression2_funcs[name .. "(" .. method_prefix .. sig:sub(1, i) .. "...)"]
		if fn then return { op = fn[3], ret = fn[2], args = types, cost = fn[4], attrs = fn.attributes }, true, false end
	end
end

function Compiler:CompileExpr(node --[[@param node Node]]) ---@return RuntimeOperator, string
	local op, ty = CompileVisitors[node.variant](self, node.trace, node.data, false) ---@cast op -nil # Expressions should never return nil function

	if ty == nil then
		if node.variant == NodeVariant.ExprDynCall then
			self:Error("Cannot use void in expression position ( Did you mean Call()[type] ? )", node.trace)
		else
			self:Error("Cannot use void in expression position", node.trace)
		end
	end ---@cast ty -nil # LuaLS can't figure this out yet.

	return op, ty
end

function Compiler:CompileStmt(node --[[@param node Node]])
	return CompileVisitors[node.variant](self, node.trace, node.data, true)
end

---@param ast Node
---@return RuntimeOperator
function Compiler:Process(ast)
	for var, type in pairs(self.persist[3]) do
		self.global_scope:DeclVar(var, { initialized = false, trace_if_unused = self.persist[5][var], type = type })
	end

	for var, type in pairs(self.inputs[3]) do
		self.global_scope:DeclVar(var, { initialized = true, trace_if_unused = self.inputs[5][var], type = type })
	end

	for var, type in pairs(self.outputs[3]) do
		self.global_scope:DeclVar(var, { initialized = false, type = type })
	end

	return self:CompileStmt(ast)
end