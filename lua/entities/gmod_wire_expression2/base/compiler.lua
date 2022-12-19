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

---@alias ScopeData { dead: boolean? }
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
	local global_scope = Scope.new()
	return setmetatable({ global_scope = global_scope, scope = global_scope }, Compiler)
end

local BLOCKED_ARRAY_TYPES = E2Lib.blocked_array_types

---@param ast Node
---@return boolean ok
---@return function script
---@return Compiler self
function Compiler.Execute(ast)
	local instance = Compiler.new()
	local ok, script = xpcall(Compiler.Process, E2Lib.errorHandler, instance, ast)
	return ok, script, instance
end

---@param message string
---@param trace Trace
function Compiler:Error(message, trace)
	error( Error.new(message, trace):display(), 0)
end

---@generic T
---@param v? T
---@param message string
---@param trace Trace
---@return T
function Compiler:Assert(v, message, trace)
	if not v then error( Error.new(message, trace):display(), 0) end
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

---@param fn fun(s: Scope)
function Compiler:Scope(fn)
	self.scope = Scope.new(self.scope)
	fn(self.scope)
	self.scope = self.scope.parent
end

--- Ensure that a token of variant LowerIdent is a valid type
---@param ty Token<string>
---@return string
function Compiler:CheckType(ty)
	if not wire_expression_types[ty.value] then self:Error("Invalid type", ty.trace) end
	return ty.value
end

---@alias RuntimeScope table
---@alias RuntimeOperator fun(self: RuntimeScope): any

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

		return function(state)
			for _, stmt in ipairs(stmts) do
				stmt(state)
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
		local start, stop, step, stmts
		self:Scope(function(scope)
			start, stop, step = self:CompileNode(data[2]), self:CompileNode(data[3]), data[4] and self:CompileNode(data[4]) or data[4]
			scope:DeclVar(data[1].value, { initialized = true, type = "number", trace_if_unused = data[1].trace })

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
		local key, key_type, value, value_type = data[1].value, data[2] and self:CheckType(data[2]) or "number", data[3].value, self:CheckType(data[4])

		local iterator, block
		self:Scope(function(scope)
			scope:DeclVar(data[1].value, { initialized = true, trace_if_unused = data[1].trace, type = key_type })
			scope:DeclVar(data[3].value, { initialized = true, trace_if_unused = data[3].trace, type = value_type })

			iterator = self:CompileNode(data[5])
			block = self:CompileNode(data[6])
		end)

		return self:GetOperator("Foreach", { key_type, value_type }, trace)
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

	---@param data { [1]: string, [2]: string|number|table }
	[NodeVariant.ExprLiteral] = function (self, trace, data)
		local val = data[2]
		return function()
			return val
		end, data[1]
	end,

	---@param data { [1]: string, [2]: Node[] }
	[NodeVariant.ExprCall] = function (self, trace, data)
		local args, types = {}, {}
		for k, arg in ipairs(data[2]) do
			args[k], types[k] = self:CompileNode(arg)
		end

		local fn = self:GetBuiltinFunction(data[1], types, trace)

		return function(state)
			local rargs = {}
			for k, arg in ipairs(args) do
				rargs[k] = arg(state)
			end

			return fn(rargs)
		end
	end
}

---@alias TypeSignature string

---@param variant string
---@param types TypeSignature[]
---@param trace Trace
---@return RuntimeOperator
function Compiler:GetOperator(variant, types, trace)
	local operators = self:Assert(E2Lib.Env.Operators[variant], "No such operator: " .. variant .. " (" .. table.concat(types, ", ") .. ")", trace)

	for _, data in ipairs(operators) do
		local types, eq = data.types, false
		for i, desired in ipairs(types) do
			if types[i] ~= desired then eq = false break end
			eq = true
		end
		if eq then return data.op end
	end

	self:Error("No such operator: " .. variant .. " (" .. table.concat(types, ", ") .. ")", trace)
end

---@param name string
---@param types TypeSignature[]
---@param trace Trace
---@return RuntimeOperator
function Compiler:GetBuiltinFunction(name, types, trace)
	local functions = self:Assert(E2Lib.Env.Functions[name], "No such function: " .. name .. "(" .. table.concat(types, ", ") .. ")", trace)

	local arg_sig, variadic = table.concat(types, ""), nil
	for _, data in ipairs(functions) do
		local sig = table.concat(data.types, "")

		if sig == arg_sig then
			return data.op
		else
			local first_bit = sig:match("([^.]+)%.%.%.")
			if first_bit and arg_sig:sub(1, #first_bit) == first_bit then
				variadic = data.op
			end
		end
	end

	if variadic then return variadic end
	self:Error("No such function: " .. name .. "(" .. table.concat(types, ", ") .. ")", trace)
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
	local compiled = self:CompileNode(ast)
	if compiled then
		return function()
			compiled({})
		end
	end
end