--[[
	Expression 2 Compiler for Garry's Mod
		by Vurv

	todo:
		- [] reimplement prf counter
		- [] reimplement all verification
		- [] optimizing step
		- [] make break and continue work
		- [] make return work
		- [] reimplement all warnings
]]

AddCSLuaFile()

local Trace, Warning, Error = E2Lib.Debug.Trace, E2Lib.Debug.Warning, E2Lib.Debug.Error
local Token, TokenVariant = E2Lib.Tokenizer.Token, E2Lib.Tokenizer.Variant
local Node, NodeVariant = E2Lib.Parser.Node, E2Lib.Parser.Variant
local Keyword, Grammar, Operator = E2Lib.Keyword, E2Lib.Grammar, E2Lib.Operator

local TickQuota = GetConVar("wire_expression2_quotatick"):GetInt()

cvars.RemoveChangeCallback("wire_expression2_quotatick", "compiler_quota_check")
cvars.AddChangeCallback("wire_expression2_quotatick", function(_, old, new)
	TickQuota = tonumber(new)
end, "compiler_quota_check")

---@class ScopeData
---@field dead boolean?
---@field loop boolean?
---@field switch_case boolean?
---@field function { [1]: string, [2]: EnvFunction}?
---@field ops integer

---@alias VarData { type: string, trace_if_unused: Trace?, initialized: boolean, scope: Scope }

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

---@param name string
---@param data VarData
function Scope:DeclVar(name, data)
	data.scope = self
	self.vars[name] = data
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
---@field delta_vars table<string, true> # Variable: True
---@field persist table<string, string> # Variable: Type
---@field inputs table<string, string> # Variable: Type
---@field outputs table<string, string> # Variable: Type
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
function Compiler.from(directives)
	local global_scope = Scope.new()
	return setmetatable({
		persist = directives.persist[3], inputs = directives.inputs[3], outputs = directives.outputs[3],
		global_scope = global_scope, scope = global_scope, warnings = {}, registered_events = {}, user_functions = {}, user_methods = {},
		delta_vars = {}
	}, Compiler)
end

local BLOCKED_ARRAY_TYPES = E2Lib.blocked_array_types

---@param ast Node
---@param directives PPDirectives
---@param dvars table<string, boolean>
---@param includes string[]
---@return boolean ok, function|Error script, Compiler self
function Compiler.Execute(ast, directives, dvars, includes)
	local instance = Compiler.from(directives, dvars, includes)
	local ok, script = xpcall(Compiler.Process, E2Lib.errorHandler, instance, ast)
	return ok, script, instance
end

---@param message string
---@param trace Trace
function Compiler:Error(message, trace)
	error( Error.new(message, trace), 0)
end

---@generic T
---@param v? T
---@param message string
---@param trace Trace
---@return T
function Compiler:Assert(v, message, trace)
	if not v then error( Error.new(message, trace), 0) end
	return v
end

---@param message string
---@param trace Trace
function Compiler:Warning(message, trace)
	if self.include then
		local tbl = self.warnings[self.include]
		tbl[#tbl + 1] = Warning.new(message, trace)
	else
		self.warnings[#self.warnings + 1] = Warning.new(message, trace)
	end
end

---@param fn fun(scope: Scope)
function Compiler:Scope(fn)
	self.scope = Scope.new(self.scope)
	fn(self.scope)
	self.scope = self.scope.parent
end

--- Ensure that a token of variant LowerIdent is a valid type
---@param ty Token<string>
---@return string type_id
function Compiler:CheckType(ty)
	-- if not E2Lib.Env.Types[ty.value] then self:Error("Invalid type (" .. ty.value .. ")", ty.trace) end
	if ty.value == "number" then return "n" end
	return self:Assert(wire_expression_types[ty.value:upper()], "Invalid type (" .. ty.value .. ")", ty.trace)[1]
end

---@alias RuntimeScope table
---@alias RuntimeOperator fun(self: RuntimeScope, ...): any

---@type fun(self: Compiler, trace: Trace, data: { [1]: Node, [2]: Operator, [3]: self }): RuntimeOperator, string?
local function handleInfixOperation(self, trace, data)
	local lhs, lhs_ty = self:CompileNode(data[1])
	local rhs, rhs_ty = self:CompileNode(data[3])

	local op, op_ret, ops = self:GetOperator(E2Lib.OperatorNames[data[2]]:lower(), { lhs_ty, rhs_ty }, trace)

	if true then
		-- legacy
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

---@type fun(self: Compiler, trace: Trace, data: { [1]: Operator, [2]: Node, [3]: self }): RuntimeOperator, string?
local function handleUnaryOperation(self, trace, data)
	local exp, ty = self:CompileNode(data[2])
	local op, op_ret = self:GetOperator(data[1] == Operator.Sub and "neg" or E2Lib.OperatorNames[data[1]]:lower(), { ty }, trace)

	if true then
		local largs = { [1] = {}, [2] = { exp }, [4] = { ty } }

		return function(state)
			return op(state, largs)
		end, op_ret
	else
		return function(state)
			return op(state, exp(state))
		end, op_ret
	end
end

---@type table<NodeVariant, fun(self: Compiler, trace: Trace, data: table): RuntimeOperator|nil, string?>
local CompileVisitors = {
	---@param data Node[]
	[NodeVariant.Block] = function(self, trace, data)
		local stmts = {}
		for i, stmt in ipairs(data) do
			if not self.scope.data.dead then
				stmts[i] = self:CompileNode(stmt)
			end
		end

		local cost = self.scope.data.ops
		self.scope.data.ops = 0

		if self.scope:ResolveData("loop") then -- Inside loop, check if continued or broken
			return function(state)
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for _, stmt in ipairs(stmts) do
					if state.__break__ or state.__return__ then break end
					if not state.__continue__ then
						stmt(state)
					end
				end
			end
		elseif self.scope:ResolveData("function") then -- If inside a function, check if returned.
			return function(state)
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for _, stmt in ipairs(stmts) do
					if state.__return__ then break end
					stmt(state)
				end
			end
		else -- Most optimized case, not inside a function or loop.
			return function(state)
				state.prf = state.prf + cost
				if state.prf > TickQuota then error("perf", 0) end

				for _, stmt in ipairs(stmts) do
					stmt(state)
				end
			end
		end
	end,

	---@param data { [1]: Node?, [2]: Node }[]
	[NodeVariant.If] = function (self, trace, data)
		local chain = {}
		for i, ifeif in ipairs(data) do
			self:Scope(function()
				chain[i] = {ifeif[1] and self:CompileNode(ifeif[1]), self:CompileNode(ifeif[2])}
			end)
		end
		return function(state)
			for _, data in ipairs(chain) do
				local cond, block = data[1], data[2]
				if cond then
					if cond(state) ~= 0 then
						block(state)
						break
					end
				else
					-- Else block
					block(state)
					break
				end
			end
		end
	end,

	---@param data { [1]: Node, [2]: Node, [3]: boolean }
	[NodeVariant.While] = function(self, trace, data)
		local expr, block, cost = nil, nil, 3
		self:Scope(function(scope)
			expr = self:CompileNode(data[1])
			scope.data.loop = true
			block = self:CompileNode(data[2])
			cost = cost + scope.data.ops
		end)

		if data[3] then
			-- do while
			return function(state)
				repeat
					state.prf = state.prf + cost
					if state.__continue__ then
						if state.prf > TickQuota then error("perf", 0) end
						state.__continue__ = false
					else
						block(state)
						if state.__break__ or state.__return__ then break end
					end
				until expr(state) == 0
			end
		else
			return function(state)
				while expr(state) ~= 0 do
					state.prf = state.prf + cost
					if state.__continue__ then
						if state.prf > TickQuota then error("perf", 0) end
						state.__continue__ = false
					else
						block(state)
						if state.__break__ or state.__return__ then break end
					end
				end
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Node, [3]: Node, [4]: Node?, [5]: Node } var start stop step block
	[NodeVariant.For] = function (self, trace, data)
		local var, start, stop, step = data[1], self:CompileNode(data[2]), self:CompileNode(data[3]), data[4] and self:CompileNode(data[4]) or data[4]

		local block, cost = nil, 3
		self:Scope(function(scope)
			scope.data.loop = true
			scope:DeclVar(var.value, { initialized = true, type = "n", trace_if_unused = var.trace })

			block = self:CompileNode(data[5])
			cost = cost + scope.data.ops
		end)

		local var = var.value
		return function(state)
			local step = step and step(state) or 1
			for i = start(state), stop(state), step do
				state.prf = state.prf + cost
				state[var] = i

				if state.__continue__ then
					if state.prf > TickQuota then error("perf", 0) end
					state.__continue__ = false
				else
					block(state)
					if state.__break__ or state.__return__ then break end
				end
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Token<string>?, [3]: Token<string>, [4]: Token<string>, [5]: Node, [6]: Node } key key_type value value_type iterator block
	[NodeVariant.Foreach] = function (self, trace, data)
		local key, key_type, value, value_type = data[1], data[2] and self:CheckType(data[2]) or "n", data[3], self:CheckType(data[4])

		local iterator, iterator_ty = self:CompileNode(data[5])
		self:Scope(function(scope)
			scope.data.loop = true

			scope:DeclVar(key.value, { initialized = true, trace_if_unused = key.trace, type = key_type })
			scope:DeclVar(value.value, { initialized = true, trace_if_unused = value.trace, type = value_type })

			block = self:CompileNode(data[6])
		end)

		local foreach, _, ops = self:GetOperator("fea", { key_type, value_type, iterator_ty }, trace)
		return function(state)
			local iterator, block = iterator(state), block(state)
			return foreach(state, iterator, block)
		end
	end,

	---@param data { [1]: Node, [2]: {[1]: Node, [2]: Node}[], [3]: Node? }
	[NodeVariant.Switch] = function (self, trace, data)
		local expr, expr_ty = self:CompileNode(data[1])

		local cases = {}
		for i, case in ipairs(data[2]) do
			local cond, cond_ty = self:CompileNode(case[1])
			local block
			self:Scope(function(scope)
				scope.data.switch_case = true
				block = self:CompileNode(case[2])
			end)

			local eq =  self:GetOperator("eq", { expr_ty, cond_ty }, case[1].trace)
			cases[i] = { eq, block }
		end

		local default
		if data[3] then
			self:Scope(function(_scope)
				default = self:CompileNode(data[3])
			end)
		end

		return function(state)
			for i, case in ipairs(cases) do
				if case[1](state) then
					case[2](state)
				end
			end
		end
	end,

	---@param data { [1]: Node, [2]: Token<string>, [3]: Node }
	[NodeVariant.Try] = function (self, trace, data)
		local try_block, catch_block, err_var = nil, nil, data[2]
		self:Scope(function(scope)
			try_block = self:CompileNode(data[1])
		end)

		self:Scope(function (scope)
			scope:DeclVar(err_var.value, { initialized = true, trace_if_unused = err_var.trace, type = "s" })
			catch_block = self:CompileNode(data[3])
		end)

		return function(state)
			local ok, err = pcall(try_block, state)
			if not ok then
				local catchable, msg, trace = E2Lib.unpackException(err)
				if catchable then
					state[err_var.value] = isstring(msg) and msg or ""
					catch_block(state)
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
			meta_type = self:CheckType(data[2])
		end

		local param_types, param_names, variadic, variadic_ty = {}, {}, nil, nil
		if data[4] then
			for i, param in ipairs(data[4]) do
				if param.type then
					local t = self:CheckType(param.type)
					if param.variadic then
						self:Assert(t == "r" or t == "t", "Variadic parameter must be of type array or table", param.type.trace)
						param_types[i] = ".." .. t
						variadic, variadic_ty = param.name, t
					else
						param_types[i] = t
					end
				elseif param.variadic then
					self:Error("Variadic parameter requires explicit type", param.name.trace)
				else
					param_types[i] = "n"
					self:Warning("Use of implicit parameter type is deprecated (add :number)", name.trace)
				end
				param_names[i] = param.name.value
			end
		end


		--[[
		local fn_data, variadic = self:GetFunction(name.value, param_types, meta_type)
		if fn_data and not variadic then
			self:Error("Cannot overwrite existing function: " .. name.value .. "(" .. table.concat(param_types, ", ") .. ")", name.trace)
		end
		]]

		local block, op
		if return_type then
			function op(state, args)
				for i, arg in ipairs(args) do
					state[param_names[i]] = arg
				end

				block(state)
				if state.__return__ then
					state.__return__ = false
					return state.func_rv
				else
					state:throw("Expected function return at runtime of type (" .. return_type .. ")")
				end
			end
		elseif variadic then
			local last, non_variadic = #param_types, #param_types - 1
			if variadic_ty == "r" then
				function op(state, args)
					for i = 1, non_variadic do
						state[param_names[i]] = args[i]
					end

					local a, n = {}, 1
					for i = last, #args do
						a[n] = args[i]
						n = n + 1
					end
					state[param_names[last]] = a

					block(state)
				end
			else -- table
				function op(state, args, arg_types)
					for i = 1, non_variadic do
						state[param_names[i]] = args[i]
					end

					local t = { s = {}, stypes = {}, n = {}, ntypes = {}, size = last }
					for i = last, #args do
						t.n[i], t.ntypes[i] = args[i], arg_types[i]
					end
					state[param_names[last]] = t

					block(state)
				end
			end
		else
			function op(state, args)
				for i in ipairs(args) do
					state[param_names[i]] = arg
				end

				block(state)
			end
		end

		local fn = { args = param_types, returns = nil, meta = meta_type, op = op, cost = 20, attrs = {} }
		local sig = table.concat(param_types)
		if meta_type then
			self.user_methods[meta_type] = self.user_methods[meta_type] or {}

			self.user_methods[meta_type][name.value] = self.user_methods[meta_type][name.value] or {}
			self.user_methods[meta_type][name.value][sig] = fn
		else
			self.user_functions[name.value] = self.user_functions[name.value] or {}
			print(name.value, sig, "= fn")
			self.user_functions[name.value][sig] = fn
		end

		self:Scope(function (scope)
			for i, type in ipairs(param_types) do
				-- I know this is horrible
				scope:DeclVar(data[4][i].name.value, { type = type, initialized = true, trace_if_unused = data[4][i].name.trace })
			end

			scope.data["function"] = { name.value, fn }
			block = self:CompileNode(data[5])
		end)

		-- No `return` statement found. Returns void
		if not fn.returns then
			fn.returns = {}
		end

		self:Assert(fn.returns[1] == return_type, "Function " .. name.value .. " expects to return type (" .. (return_type or "void") .. ") but got type (" .. (fn.returns[1] or "void") .. ")", trace)

		local sig = name.value .. "(" .. sig .. ")"
		return function(state)
			state.funcs[sig] = op
		end
	end,

	---@param data {}
	[NodeVariant.Continue] = function(self, trace, data)
		self.scope.data.dead = true
		return function(state)
			state.__continue__ = true
		end
	end,

	---@param data {}
	[NodeVariant.Break] = function(self, trace, data)
		self.scope.data.dead = true
		return function(state)
			state.__break__ = true
		end
	end,

	---@param data Node?
	[NodeVariant.Return] = function (self, trace, data)
		local fn = self.scope:ResolveData("function")
		self:Assert(fn, "Cannot use `return` outside of a function", trace)

		local retval, ret_ty
		if data then
			retval, ret_ty = self:CompileNode(data)

			local name, fn = fn[1], fn[2]

			if fn.returns then
				self:Assert(fn.returns[1] == ret_ty, "Function " .. name .. " expects return type (" .. fn.returns[1] .. ") but was given (" .. ret_ty .. ")", trace)
			end

			fn.returns = { ret_ty }
		end

		return function(state)
			state.func_rv = retval(state)
			state.__return__ = true
		end
	end,

	---@param data { [1]: boolean, [2]: { [1]: Token<string>, [2]: { [1]: Node, [2]: Token<string>?, [3]: Trace }[] }[], [3]: Node } is_local, vars, value
	[NodeVariant.Assignment] = function (self, trace, data)
		local value, value_ty = self:CompileNode(data[3])
		assert(value_ty, "Assigning to expression without return type ? " .. tostring(data[3]))

		local exprs = {}
		for i, v in ipairs(data[2]) do
			local var, indices, trace = v[1], v[2], v[3]

			local indices2, existing = {}, self.scope:LookupVar(var.value)
			if existing then
				-- It can have indices, it already exists.
				self:Assert(existing.type == value_ty, "Cannot assign type (" .. value_ty .. ") to variable of type (" .. existing.type .. ")", trace)
				for j, index in ipairs(indices) do
					indices2[j] = {self:CompileNode(index[1]), index[2]}
				end
			else
				-- Cannot have indices.
				self:Assert(#indices == 0, "Variable (" .. var.value .. ") does not exist", trace)
				self.scope:DeclVar(var.value, { type = value_ty, initialized = true, trace_if_unused = trace })
			end

			exprs[i] = { var.value, indices2 }
		end

		return function(state)
			local val = value(state)
			for i, v in ipairs(exprs) do
				local var, indexes = v[1], v[2]
				state[var] = val
			end
		end
	end,

	---@param data Token<string>
	[NodeVariant.Increment] = function (self, trace, data)
		local var = data.value
		self:Assert(self.scope:LookupVar(var), "Unknown variable to increment: " .. var, trace)

		-- todo: operator support
		return function(state)
			state[var] = state[var] + 1
		end
	end,

	---@param data Token<string>
	[NodeVariant.Decrement] = function (self, trace, data)
		local var = data.value
		self:Assert(self.scope:LookupVar(var), "Unknown variable to decrement: " .. var, trace)

		-- todo: operator support
		return function(state)
			state[var] = state[var] - 1
		end
	end,

	---@param data { [1]: Token<string>, [2]: Operator, [3]: Node }
	[NodeVariant.CompoundArithmetic] = function(self, trace, data)
		local var = self:Assert(self.scope:LookupVar(data[1].value), "Variable " .. data[1].value .. " does not exist.", trace)
		local expr, expr_ty = self:CompileNode(data[3])

		local op, op_ty = self:GetOperator(E2Lib.OperatorNames[data[2]]:lower():sub(2), { var.type, expr_ty }, trace)
		self:Assert(op_ty == var.type, "Cannot use compound arithmetic on differing types", trace)

		return function(state)
			op(state)
		end
	end,

	---@param data { [1]: Node, [2]: Node }
	[NodeVariant.ExprDefault] = function(self, trace, data)
		local cond, cond_ty = self:CompileNode(data[1])
		local expr, expr_ty = self:CompileNode(data[2])

		self:Assert(cond_ty == expr_ty, "Cannot use default (?:) operator with differing types", trace)

		local op = self:GetOperator("is", { cond_ty }, trace)

		return function(state)
			local iff = cond(state)
			return op(state, iff) ~= 0 and iff or expr(state)
		end, cond_ty
	end,

	---@param data { [1]: Node, [2]: Node }
	[NodeVariant.ExprTernary] = function(self, trace, data)
		local cond, cond_ty = self:CompileNode(data[1])
		local iff, iff_ty = self:CompileNode(data[2])
		local els, els_ty = self:CompileNode(data[2])

		self:Assert(iff_ty == els_ty, "Cannot use ternary (A ? B : C) operator with differing types", trace)

		local op = self:GetOperator("is", { cond_ty }, trace)

		return function(state)
			return op(state, cond(state)) ~= 0 and iff(state) or els(state)
		end, iff_ty
	end,

	---@param data { [1]: string, [2]: string|number|table }
	[NodeVariant.ExprLiteral] = function (self, trace, data)
		local val = data[2]

		self.scope.data.ops = self.scope.data.ops + 0.5
		return function()
			return val
		end, data[1]
	end,

	---@param data Token<string>
	[NodeVariant.ExprIdent] = function (self, trace, data)
		local var, name = self:Assert(self.scope:LookupVar(data.value), "Undefined variable: " .. data.value, trace), data.value

		self.scope.data.ops = self.scope.data.ops + 1

		return function(state)
			return state[name]
		end, var.type
	end,

	---@alias ArgumentsKV { [1]: Node, [2]: Node }
	---@alias Arguments Node[]

	---@param data ArgumentsKV|Arguments
	[NodeVariant.ExprArray] = function (self, trace, data)
		if #data == 0 then
			return function(state)
				return {}
			end, "r"
		elseif data[1][2] then
			-- key value
			local args = {}
			return function(state)
				error("Unimplemented: kv array")
			end
		else
			local args = {}
			for k, arg in ipairs(data) do
				args[k] = self:CompileNode(arg)
			end

			return function(state)
				local array = {}
				for i, val in ipairs(args) do
					array[i] = val(state)
				end
				return array
			end, "r"
		end
	end,

	---@param data ArgumentsKV|Arguments
	[NodeVariant.ExprTable] = function (self, trace, data)
		if #data == 0 then
			return function(state)
				return {}
			end, "t"
		elseif data[1][2] then
			-- key value
			local args = {}
			return function(state)
				error("Unimplemented: kvtable")
			end, "t"
		else
			local args = {}
			for k, arg in ipairs(data) do
				args[k] = self:CompileNode(arg)
			end

			return function(state)
				local array = {}
				for i, val in ipairs(args) do
					array[i] = val(state)
				end
				return array
			end, "t"
		end
	end,

	[NodeVariant.ExprArithmetic] = handleInfixOperation,
	[NodeVariant.ExprLogicalOp] = handleInfixOperation,
	[NodeVariant.ExprBinaryOp] = handleInfixOperation,
	[NodeVariant.ExprComparison] = handleInfixOperation,
	[NodeVariant.ExprEquals] = handleInfixOperation,
	[NodeVariant.ExprBitShift] = handleInfixOperation,
	[NodeVariant.ExprUnaryOp] = handleUnaryOperation,

	---@param data { [1]: Operator, [2]: Token<string> }
	[NodeVariant.ExprUnaryWire] = function(self, trace, data)
		local var_name = data[2].value
		local var = self:Assert(self.scope:LookupVar(var_name), "Undefined variable (" .. var_name .. ")", trace)

		if data[1] == Operator.Dlt then -- $
			self:Assert(var.scope:IsGlobalScope(), "Delta operator ($) can not be used on temporary variables", trace)
			self.delta_vars[var_name] = true

			local sub_op, sub_ty = self:GetOperator("sub", { var.type, var.type }, trace)
			local var = Node.new(NodeVariant.ExprIdent, data[2])

			local tok = Token.new(TokenVariant.Ident, "$" .. data[2].value)
			tok.trace = data[2].trace
			local var_dlt = Node.new(NodeVariant.ExprIdent, tok)

			return function(state)
				sub_op(state, var, var_dlt)
			end, sub_ty
		elseif data[1] == Operator.Trg then -- ~
			local op, op_ret = self:GetOperator("trg", {}, trace)
			return function(state)
				return op(state, var_name)
			end, op_ret
		elseif data[1] == Operator.Imp then -- ->
			if self.inputs[var_name] then
				local op, op_ret = self:GetOperator("iwc", {}, trace)
				return function(state)
					return op(state, var_name)
				end, op_ret
			elseif self.outputs[var_name] then
				local op, op_ret = self:GetOperator("owc", {}, trace)
				return function(state)
					return op(state, var_name)
				end, op_ret
			else
				self:Error("Can only use connected (->) operator on inputs or outputs", trace)
			end
		end
	end,

	---@param data { [1]: Node, [2]: Index[] }
	[NodeVariant.ExprIndex] = function (self, trace, data)
		local expr, expr_ty = self:CompileNode(data[1])
		for i, index in ipairs(data[2]) do
			local key, key_ty = self:CompileNode(index[1])
			local op, op_ty
			if index[2] then -- <EXPR>[<EXPR>, <type>]
				local ty = self:CheckType(index[2])
				op, expr_ty = self:GetOperator("idx", { ty, "=", expr_ty, key_ty }, index[3]) -- hack for backwards compat..
			else -- <EXPR>[<EXPR>]
				op, expr_ty = self:GetOperator("idx", { expr_ty, key_ty }, index[3])
			end

			expr = function(state)
				op(state, expr, key)
			end
		end

		return function(state)
			return expr(state)
		end, expr_ty
	end,

	---@param data { [1]: string, [2]: Node[] }
	[NodeVariant.ExprCall] = function (self, trace, data)
		local args, types = {}, {}
		for k, arg in ipairs(data[2]) do
			args[k], types[k] = self:CompileNode(arg)
		end

		local fn_data = self:Assert(self:GetFunction(data[1], types), "No such function: " .. data[1] .. "(" .. table.concat(types, ", ") .. ")", trace)
		local fn = fn_data.op

		self.scope.data.ops = self.scope.data.ops + ((fn_data.cost or 20) + (fn_data.attrs["legacy"] and 10 or 0))

		if fn_data.attrs["legacy"] then
			local largs = { [1] = {}, [#args + 2] = types }
			for i, arg in ipairs(args) do
				largs[i + 1] = { [1] = arg }
			end

			return function(state)
				return fn(state, largs)
			end, fn_data.returns[1]
		else
			return function(state)
				local rargs = {}
				for k, arg in ipairs(args) do
					rargs[k] = arg(state)
				end

				return fn(state, rargs, types)
			end, fn_data.returns[1]
		end
	end,

	---@param data { [1]: Node, [2]: Token<string>, [3]: Node[] }
	[NodeVariant.ExprMethodCall] = function (self, trace, data)
		local name, args, types = data[2], {}, {}
		for k, arg in ipairs(data[2]) do
			args[k], types[k] = self:CompileNode(arg)
		end

		local meta, meta_type = self:CompileNode(data[1])

		local fn_data = self:Assert(self:GetFunction(name.value, types, meta_type), "No such method: " .. meta_type .. ":" .. name.value .. "(" .. table.concat(types, ", ") .. ")", name.trace)
		local fn = fn_data.op

		if fn_data.attrs["legacy"] then
			local largs = { [#args + 3] = types, [2] = { [1] = meta } }
			for i, arg in ipairs(args) do
				largs[i + 2] = { [1] = arg }
			end

			return function(state)
				return fn(state, largs)
			end, fn_data.returns[1]
		else
			return function(state)
				local rargs = { meta }
				for k, arg in ipairs(args) do
					rargs[k + 1] = arg(state)
				end

				return fn(state, rargs)
			end, fn_data.returns[1]
		end
	end,

	---@param data { [1]: Node, [2]: Node[], [3]: Token<string>? }
	[NodeVariant.ExprStringCall] = function (self, trace, data)
		local expr = self:CompileNode(data[1])

		local args, arg_types = {}, {}
		for i, arg in ipairs(data[2]) do
			args[i], arg_types[i] = self:CompileNode(arg)
		end

		local arg_sig = table.concat(arg_types)
		return function(state)
			local rargs = {}
			for k, arg in ipairs(args) do
				rargs[k] = arg(state)
			end

			local fn = expr(state)
			if state.funcs[fn] then
				return state.funcs[fn](rargs)
			else
				state:throw("No such function: " .. fn .. "(" .. arg_sig .. ")")
			end
		end, data[3] and self:CheckType(data[3])
	end,

	---@param data { [1]: Token<string>, [2]: Parameter[], [3]: Node }
	[NodeVariant.Event] = function (self, trace, data)
		if self.scope.parent then
			self:Error("Events cannot be nested inside of statements, they are compile time constructs", trace)
		end

		local name = data[1]
		local params = {}
		for i, param in ipairs(data[2]) do
			params[i] = { param.name.value, param.type and self:CheckType(param.type) or "n" }
		end

		return nil
	end
}

---@alias TypeSignature string

---@param variant string
---@param types TypeSignature[]
---@param trace Trace
---@return RuntimeOperator fn
---@return TypeSignature signature
function Compiler:GetOperator(variant, types, trace)
	local fn = wire_expression2_funcs["op:" .. variant .. "(" .. table.concat(types) .. ")"]
	if fn then
		self.scope.data.ops = self.scope.data.ops + (fn[4] or 3)
		return fn[3], fn[2]
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

	for i = #param_sig, 0, -1 do
		local sig = param_sig:sub(1, i)

		local fn = overloads[sig .. "..r"]
		if fn then return fn, true end

		fn = overloads[sig .. "..t"]
		if fn then return fn, true end
	end
end

---@param name string
---@param types TypeSignature[]
---@param method? string
---@return EnvFunction?
---@return boolean? variadic
function Compiler:GetFunction(name, types, method)
	local sig, method_prefix = table.concat(types), method and (method .. ":") or ""

	local fn = wire_expression2_funcs[name .. "(" .. method_prefix .. sig .. ")"]
	if fn then return { op = fn[3], returns = { fn[2] }, args = types, cost = fn[4], attrs = fn.attributes }, false end

	local fn, variadic = self:GetUserFunction(name, types, method)
	if fn then return fn, variadic end

	for i = #sig, 0, -1 do
		fn = wire_expression2_funcs[name .. "(" .. method_prefix .. sig:sub(1, i) .. "...)"]
		if fn then return { op = fn[3], returns = { fn[2] }, args = types, cost = fn[4], attrs = fn.attributes }, true end
	end
end

---@param node Node
---@return RuntimeOperator
---@return string? expr_type
function Compiler:CompileNode(node)
	assert(node.trace, "Incomplete node: " .. tostring(node))
	return assert(CompileVisitors[node.variant], "Unimplemented Compile Step: " .. node:instr())(self, node.trace, node.data)
end

---@param ast Node
---@return RuntimeOperator
function Compiler:Process(ast)
	-- Todo: Add trace_if_unused
	for var, type in pairs(self.persist) do
		self.scope:DeclVar(var, { initialized = false, type = type })
	end

	for var, type in pairs(self.inputs) do
		self.scope:DeclVar(var, { initialized = true, type = type })
	end

	for var, type in pairs(self.outputs) do
		self.scope:DeclVar(var, { initialized = false, type = type })
	end

	return self:CompileNode(ast)
end