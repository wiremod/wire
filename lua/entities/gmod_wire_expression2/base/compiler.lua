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
local Node, NodeVariant = E2Lib.Parser.Node, E2Lib.Parser.Variant
local Keyword, Grammar, Operator = E2Lib.Keyword, E2Lib.Grammar, E2Lib.Operator

---@alias ScopeData { dead: boolean?, loop: boolean? }
---@alias VarData { type: string, trace_if_unused: Trace?, initialized: boolean }

---@class Scope
---@field parent Scope?
---@field data ScopeData
---@field vars table<string, VarData>
local Scope = {}
Scope.__index = Scope

---@param parent Scope?
function Scope.new(parent)
	return setmetatable({ data = {}, vars = {}, parent = parent }, Scope)
end

---@param name string
---@param data VarData
function Scope:DeclVar(name, data)
	self.vars[name] = data
end

---@param name string
---@return VarData?
function Scope:LookupVar(name)
	return self.vars[name] or (self.parent and self.parent:LookupVar(name))
end

---@param field string
---@return ScopeData?
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
--- Directives
---@field persist table<string, string> # Variable: Type
---@field inputs table<string, string> # Variable: Type
---@field outputs table<string, string> # Variable: Type
local Compiler = {}
Compiler.__index = Compiler

E2Lib.Compiler = Compiler

function Compiler.new()
	return setmetatable({}, Compiler)
end

local BLOCKED_ARRAY_TYPES = E2Lib.blocked_array_types

---@param ast Node
---@return boolean ok
---@return function|Error script
---@return Compiler self
function Compiler.Execute(ast)
	local instance = Compiler.new()
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
---@return string
function Compiler:CheckType(ty)
	if not E2Lib.Env.Types[ty.value] then self:Error("Invalid type (" .. ty.value .. ")", ty.trace) end
	return ty.value
end

---@alias RuntimeScope table
---@alias RuntimeOperator fun(self: RuntimeScope, ...): any

---@type fun(self: Compiler, trace: Trace, data: { [1]: Node, [2]: Operator, [3]: self }): RuntimeOperator, string?
local function handleInfixOperation(self, trace, data)
	local lhs, lhs_ty = self:CompileNode(data[1])
	local rhs, rhs_ty = self:CompileNode(data[3])

	local op, op_ret = self:GetOperator(E2Lib.OperatorNames[data[2]]:lower(), { lhs_ty, rhs_ty }, trace)

	return function(state)
		return op(state, lhs, rhs)
	end, op_ret
end

---@type fun(self: Compiler, trace: Trace, data: { [1]: Node, [2]: Operator, [3]: self }): RuntimeOperator, string?
local function handleUnaryOperation(self, trace, data)
	local exp, ty = self:CompileNode(data[1])
	local op, op_ret = self:GetOperator(E2Lib.OperatorNames[data[2]], { ty }, trace)

	return function(state)
		return op(state, exp)
	end, op_ret
end

local function legacyEval(state, args)

end

---@type table<NodeVariant, fun(self: Compiler, trace: Trace, data: table): RuntimeOperator, string?>
local CompileVisitors = {
	---@param data Node[]
	[NodeVariant.Block] = function(self, trace, data)
		local stmts = {}
		for i, stmt in ipairs(data) do
			if not self.scope.data.dead then
				stmts[i] = self:CompileNode(stmt)
			end
		end

		if self.scope:ResolveData("loop") then
			return function(state)
				for _, stmt in ipairs(stmts) do
					if state.__break__ then break end
					if not state.__continue__ then
						stmt(state)
					end
				end
			end
		else
			return function(state)
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

	---@param data { [1]: Token<string>, [2]: Node, [3]: Node, [4]: Node?, [5]: Node } var start stop step block
	[NodeVariant.For] = function (self, trace, data)
		local var, start, stop, step = data[1], self:CompileNode(data[2]), self:CompileNode(data[3]), data[4] and self:CompileNode(data[4]) or data[4]
		local stmts
		self:Scope(function(scope)
			scope.data.loop = true

			if scope:LookupVar(var.value) then
				self:Error("Cannot overwrite existing variable (" .. var.value .. ") with for loop variable", var.trace)
			else
				scope:DeclVar(data[1].value, { initialized = true, type = "number", trace_if_unused = data[1].trace })
			end

			stmts = {}
			for i, stmt in ipairs(data[5].data) do
				stmts[i] = self:CompileNode(stmt)
			end
		end)

		return function(state)
			local step = step and step(state) or 1
			for i = start(state), stop(state), step do
				for _, stmt in ipairs(stmts) do
					if state.__continue__ then
						state.__continue__ = false
					else
						stmt(state)
					end

					if state.__break__ then break end
				end
			end
		end
	end,

	---@param data { [1]: Token<string>, [2]: Token<string>?, [3]: Token<string>, [4]: Token<string>, [5]: Node, [6]: Node } key key_type value value_type iterator block
	[NodeVariant.Foreach] = function (self, trace, data)
		local key, key_type, value, value_type = data[1], data[2] and self:CheckType(data[2]) or "number", data[3], self:CheckType(data[4])

		local iterator, block = self:CompileNode(data[5]), nil
		self:Scope(function(scope)
			scope.data.loop = true

			if scope:LookupVar(key.value) then
				self:Error("Cannot overwrite existing variable (" .. key.value .. ") with foreach key variable", key.trace)
			else
				scope:DeclVar(key.value, { initialized = true, trace_if_unused = key.trace, type = key_type })
			end

			if scope:LookupVar(value.value) then
				self:Error("Cannot overwrite existing variable (" .. value.value .. ") with foreach value variable", value.trace)
			else
				scope:DeclVar(value.value, { initialized = true, trace_if_unused = value.trace, type = value_type })
			end

			block = self:CompileNode(data[6])
		end)

		local foreach = self:GetOperator("Foreach", { key_type, value_type }, trace)
		return function(state)
			local iterator, block = iterator(state), block(state)
			return foreach(state, iterator, block)
		end
	end,

	---@param data { [1]: Node, [2]: Token<string>, [3]: Node }
	[NodeVariant.Try] = function (self, trace, data)
		local try_block, catch_block, err_var = nil, nil, data[2]
		self:Scope(function(scope)
			try_block = self:CompileNode(data[1])
		end)

		self:Scope(function (scope)
			if scope:LookupVar(err_var.value) then
				self:Error("Cannot overwrite existing variable (" .. err_var.value .. ") with catch error", err_var.trace)
			else
				scope:DeclVar(err_var.value, { initialized = true, trace_if_unused = err_var.trace, type = "s" })
			end
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
		local return_type
		if data[1] then
			return_type = self:CheckType(data[1])
		end

		local meta_type
		if data[2] then
			meta_type = self:CheckType(data[2])
		end

		local params, param_types, block = {}, {}, nil
		self:Scope(function (scope)
			for i, param in ipairs(data[4]) do
				scope:DeclVar(param.name.value, { type = self:CheckType(param.type), initialized = true, trace_if_unused = param.type.trace })

				params[i] = param.name.value
				param_types[i] = param.type.value
			end

			block = self:CompileNode(data[5])
		end)

		local fn_data, _, variadic = self:GetCoreFunction(data[3].value, param_types, trace)
		if fn and not variadic then
			self:Error("Cannot overwrite existing function: " .. data[3].value .. "(" .. table.concat(param_types, ", ") .. ")", trace)
		end

		local sig = data[3].value .. "(" .. table.concat(param_types, ", ") .. ")"
		return function(state)
			state.functions[sig] = function(state, ...)
				-- todo: set vars at runtime
				block(state)
			end
		end
	end,

	---@param data {}
	[NodeVariant.Continue] = function(self, trace, data)
		self:Assert( self.scope:ResolveData("loop"), "Cannot use break outside of a loop", trace )

		self.scope.data.dead = true
		return function(state)
			state.__continue__ = true
		end
	end,

	---@param data {}
	[NodeVariant.Break] = function(self, trace, data)
		self:Assert( self.scope:ResolveData("loop"), "Cannot use break outside of a loop", trace )

		self.scope.data.dead = true
		return function(state)
			state.__break__ = true
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

	---@param data { [1]: string, [2]: string|number|table }
	[NodeVariant.ExprLiteral] = function (self, trace, data)
		local val = data[2]
		return function()
			return val
		end, data[1]
	end,

	---@param data Token<string>
	[NodeVariant.ExprIdent] = function (self, trace, data)
		local var = self:Assert(self.scope:LookupVar(data.value), "Undefined variable: " .. data.value, trace)

		local name = data.value
		return function(state)
			return state[name]
		end, var.type
	end,

	[NodeVariant.ExprArithmetic] = handleInfixOperation,
	[NodeVariant.ExprLogicalOp] = handleInfixOperation,
	[NodeVariant.ExprBinaryOp] = handleInfixOperation,
	[NodeVariant.ExprComparison] = handleInfixOperation,
	[NodeVariant.ExprBitShift] = handleInfixOperation,
	[NodeVariant.ExprUnaryOp] = handleUnaryOperation,
	[NodeVariant.ExprUnaryOp] = handleUnaryOperation,

	---@param data { [1]: string, [2]: Node[] }
	[NodeVariant.ExprCall] = function (self, trace, data)
		local args, types = {}, {}
		for k, arg in ipairs(data[2]) do
			args[k], types[k] = self:CompileNode(arg)
		end

		local fn_data = self:Assert(self:GetCoreFunction(data[1], types, trace), "No such function: " .. data[1] .. "(" .. table.concat(types, ", ") .. ")", trace)
		local fn = fn_data.op

		print(data[1], fn_data.attrs.legacy, table.concat(fn_data.args, ", "), fn_data)
		if fn_data.attrs["legacy"] then
			-- legacy
			local largs = {}
			for i, arg in ipairs(args) do
				largs[i + 1] = { [1] = arg, [2] = function() return "test" end }
			end

			return function(state)
				return fn(state, largs)
			end
		else
			return function(state)
				local rargs = {}
				for k, arg in ipairs(args) do
					rargs[k] = arg(state)
				end

				return fn(state, rargs)
			end
		end
	end
}

---@alias TypeSignature string

---@param variant string
---@param types TypeSignature[]
---@param trace Trace
---@return RuntimeOperator
---@return TypeSignature
function Compiler:GetOperator(variant, types, trace)
	local operators = self:Assert(E2Lib.Env.Operators[variant], "No such operator: " .. variant .. " (" .. table.concat(types, ", ") .. ")", trace)

	local arg_sig = table.concat(types, "")
	for _, data in ipairs(operators) do
		local sig = table.concat(data.args, "")

		if sig == arg_sig then
			return data.op, data.returns[1]
		end
	end

	self:Error("No such operator: " .. variant .. " (" .. table.concat(types, ", ") .. ")", trace)
end

function Compiler:GetUserFunction(name, types, trace)

end

---@param name string
---@param types TypeSignature[]
---@param trace Trace
---@return EnvFunction?
---@return boolean? variadic
function Compiler:GetCoreFunction(name, types, trace)
	local functions = E2Lib.Env.Libraries.Builtins.Functions[name]
	if not functions then return end

	local arg_sig, variadic, variadic_ret = table.concat(types, ""), nil, nil
	for _, data in ipairs(functions) do
		local sig = table.concat(data.args, "")

		if sig == arg_sig then
			return data, false
		else
			local first_bit = sig:match("([^.]*)%.%.%.")
			if arg_sig:sub(1, first_bit and #first_bit or 0) == first_bit then
				variadic = data
			end
		end
	end

	if variadic then return variadic, true end
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
	local global_scope = Scope.new()

	self.global_scope = global_scope
	self.scope = global_scope
	self.warnings = {}

	return self:CompileNode(ast)
end