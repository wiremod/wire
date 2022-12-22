--[[
	Expression 2 Parser for Garry's Mod

	Rewritten by Vurv
	Notable changes:
		* Now uses Nodes and NodeVariant rather than strings (Much faster and better for intellisense)
		* Removed excessive use of functions / recursion as an optimization
		* This no longer does any analysis based on the environment like whether a type is valid or not since a Parser shouldn't be doing that.
		* Removed PEG-style grammar.
		* Condensed from 1.7k LOC -> 1k LOC
]]

AddCSLuaFile()

local Trace, Warning, Error = E2Lib.Debug.Trace, E2Lib.Debug.Warning, E2Lib.Debug.Error
local Tokenizer = E2Lib.Tokenizer
local Token, TokenVariant = Tokenizer.Token, Tokenizer.Variant
local Keyword, Grammar, Operator = E2Lib.Keyword, E2Lib.Grammar, E2Lib.Operator

---@class Parser
---@field tokens Token[]
---@field ntokens integer
---@field index integer
---@field warnings Warning[]
---@field traces Trace[] # Stack of traces to push and pop
---@field delta_vars table<string, boolean>
---@field include_files string[]
local Parser = {}
Parser.__index = Parser

---@param tokens table?
function Parser.new(tokens)
	return setmetatable({ tokens = tokens or {}, ntokens = tokens and #tokens or 0, index = 1, warnings = {}, traces = {} }, Parser)
end

E2Lib.Parser = Parser

---@class Node<T>: { data: T, variant: NodeVariant, trace: Trace }
---@field variant NodeVariant
---@field trace Trace
---@field data any
local Node = {}
Node.__index = Node

Parser.Node = Node

---@param variant NodeVariant
---@param data any
---@param trace Trace?
---@return Node
function Node.new(variant, data, trace)
	return setmetatable({ variant = variant, trace = trace, data = data }, Node)
end

---@enum NodeVariant
local NodeVariant = {
	Block = 1,

	--- Statements
	If = 2, -- `if (1) {} elseif (1) {} else {}`
	While = 3, -- `while (1) {}`, `do {} while(1)`
	For = 4, -- `for (I = 1, 2, 3) {}`
	Foreach = 5, -- `foreach(K, V = T) {}`

	Break = 6, -- break
	Continue = 7, -- `continue`
	Return = 8, -- `return`

	Increment = 9, -- `++`
	Decrement = 10, -- `--`
	CompoundArithmetic = 11, -- `+=`, `-=`, `*=`, `/=`
	DefineLocal = 12, -- `local X = 5`
	Assignment = 13, -- `X = Y[2, number] = Z[2] = 5`

	Switch = 14, -- `switch (<EXPR>) { case <EXPR>, <STMT>* default, <STMT*> }
	Function = 15,
	Include = 16, -- #include "file"
	Try = 17, -- try {} catch (Err) {}

	--- Compile time constructs
	Event = 18, -- event tick() {}

	--- Expressions
	ExprTernary = 19, -- `X ? Y : Z`
	ExprDefault = 20, -- `X ?: Y`
	ExprLogicalOp = 21, -- `|` `&` (Yes they are flipped.)
	ExprBinaryOp = 22, -- `||` `&&` `^^`
	ExprComparison = 23, -- `>` `<` `>=` `<=`
	ExprEquals = 24, -- `==` `!=`
	ExprBitShift = 25, -- `>>` `<<`
	ExprArithmetic = 26, -- `+` `-` `*` `/` `^` `%`
	ExprUnaryOp = 27, -- `-` `+` `!`
	ExprMethodCall = 28, -- `<EXPR>:call()`
	ExprIndex = 29,	-- `<EXPR>[<EXPR>, <type>?]`
	ExprGrouped = 30, -- (<EXPR>)
	ExprCall = 31, -- `call()`
	ExprStringCall = 32, -- `""()` (Temporary until lambdas are made)
	ExprUnaryWire = 33, -- `~Var` `$Var` `->Var`
	ExprArray = 34, -- `array(1, 2, 3)` or `array(1 = 2, 2 = 3)`
	ExprTable = 35, -- `table(1, 2, 3)` or `table(1 = 2, "test" = 3)`
	ExprLiteral = 36, -- `"test"` `5e2` `4.023` `4j`
	ExprIdent = 37 -- `Variable`
}

Parser.Variant = NodeVariant

local NodeVariantLookup = {}
for var, i in pairs(NodeVariant) do
	NodeVariantLookup[i] = var
end

function Node:debug()
	return string.format("Node { variant = %s, data = %s, trace = %s }", NodeVariantLookup[self.variant], self.data, self.trace)
end

---@return string
function Node:instr()
	return NodeVariantLookup[self.variant]
end

Node.__tostring = Node.debug

---@return boolean ok, Node|Error ast, table<string, boolean> dvars, string[] include_files, Parser self
function Parser.Execute(tokens)
	local instance = Parser.new(tokens)
	local ok, ast, dvars, include_files = xpcall(Parser.Process, E2Lib.errorHandler, instance, tokens)
	return ok, ast, dvars, include_files, instance
end

function Parser:Eof() return self.index > self.ntokens end
function Parser:Peek() return self.tokens[self.index + 1] end
function Parser:At() return self.tokens[self.index] end
function Parser:Prev() return self.tokens[self.index - 1] end

---@param variant TokenVariant
---@param value? number|string|boolean
---@return Token?
function Parser:Consume(variant, value)
	local token = self:At()
	if not token or token.variant ~= variant then return end
	if value ~= nil and token.value ~= value then return end

	self.index = self.index + 1
	return token
end

---@return Trace
function Parser:GetTrace()
	return assert(self.traces[#self.traces], "GetTrace() without any current trace in stack."):stitch(assert(self:At() or self:Prev(), "No active token").trace)
end

function Parser:PushTrace()
	self.traces[#self.traces + 1] = assert(self:Peek() or self:At(), "PushTrace without a proceeding token").trace
end

---@return Trace
function Parser:PopTrace()
	return assert(table.remove(self.traces), "PopTrace without trace on top of stack"):stitch(assert(self:At() or self:Prev(), "No active token").trace)
end

---@param message string
---@param trace Trace?
function Parser:Error(message, trace)
	error( Error.new( message, trace or self:GetTrace() ), 2 )
end

---@param message string
---@param trace Trace?
function Parser:Warning(message, trace)
	self.warnings[#self.warnings + 1] = Warning.new( message, trace or self:GetTrace() )
end

---@generic T
---@param v? T
---@param message string
---@return T
function Parser:Assert(v, message)
	if not v then error( Error.new( message, self:GetTrace() ):display(), 2 ) end
	return v
end

---@return Node ast, table<string, boolean> dvars, string[] include_files
function Parser:Process(tokens)
	self.index, self.tokens, self.ntokens, self.warnings, self.delta_vars, self.include_files = 1, tokens, #tokens, {}, {}, {}

	local stmts = {}
	if self:Eof() then return Node.new(NodeVariant.Block, stmts, Trace.new(0, 0, 0, 0)), self.delta_vars, self.include_files end

	self:PushTrace()
	while true do
		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			self:Error("Statement separator (,) must not appear multiple times")
		end

		self:PushTrace()
			local stmt = self:Stmt() or self:Expr()
			stmt.trace = self:PopTrace()
		stmts[#stmts + 1] = stmt

		if self:Eof() then break end

		if not self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			if not self:At().whitespaced then
				self:Error("Statements must be separated by comma (,) or whitespace", stmt.trace)
			end
		end
	end

	return Node.new(NodeVariant.Block, stmts, self:PopTrace()), self.delta_vars, self.include_files
end

---@param variant TokenVariant
---@param value? number|string|boolean
function Parser:ConsumeTailing(variant, value)
	local token = self:At()
	if not token or token.whitespaced then return end

	return self:Consume(variant, value)
end

---@param variant TokenVariant
---@param value? number|string|boolean
function Parser:ConsumeLeading(variant, value)
	local token = self:Peek()
	if not token or token.whitespaced then return end

	return self:Consume(variant, value)
end

---@return Node
function Parser:Condition()
	self:Assert( self:Consume(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() expected before condition")
	self:PushTrace()
		local expr = self:Expr()
	self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) missing, to close condition")
	return expr
end

---@return Node?
function Parser:Stmt()
	if self:Consume(TokenVariant.Keyword, Keyword.If) then
		local cond, block = self:Condition(), self:Assert( self:Block(), "Expected block after if condition")

		---@type { [1]: Node?, [2]: Node }[]
		local chain = { {cond, block} }
		while self:Consume(TokenVariant.Keyword, Keyword.Elseif) do
			local cond, block = self:Condition(), self:Assert( self:Block(), "Expected block after elseif condition")
			chain[#chain + 1] = { cond, block }
		end

		if self:Consume(TokenVariant.Keyword, Keyword.Else) then
			chain[#chain + 1] = { nil, self:Assert( self:Block(), "Expected block after else keyword") }
		end

		return Node.new(NodeVariant.If, chain)
	end

	if self:Consume(TokenVariant.Keyword, Keyword.While) then
		return Node.new(NodeVariant.While, { self:Condition(), self:Block(), false })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.For) then
		if not self:Consume(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left Parenthesis (() must appear before condition")
		end

		local var = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected for numeric index" )
		self:Assert( self:Consume(TokenVariant.Operator, Operator.Ass), "Assignment operator (=) expected to preceed variable" )

		local start = self:Expr()
		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after start value" )

		local stop = self:Expr()

		local step
		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			step = self:Expr()
		end

		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) missing, to close for statement" )

		return Node.new(NodeVariant.For, { var, start, stop, step, self:Block() })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Foreach) then
		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() missing after foreach statement" )

		local key = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected to hold the key" )

		local key_type
		if self:Consume(TokenVariant.Operator, Operator.Col) then
			key_type = self:Assert(self:Type(), "Type expected after colon")
		end

		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after key variable" )

		local value = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected to hold the value" )
		self:Assert( self:Consume(TokenVariant.Operator, Operator.Col), "Colon (:) expected to separate type from variable" )

		local value_type = self:Assert(self:Type(), "Type expected after colon")
		self:Assert( self:Consume(TokenVariant.Operator, Operator.Ass), "Equals sign (=) expected after value type to specify table" )

		local table = self:Expr()

		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RParen), "Missing right parenthesis after foreach statement" )

		return Node.new(NodeVariant.Foreach, { key, key_type, value, value_type, table, self:Block() })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Break) then
		return Node.new(NodeVariant.Break)
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Continue) then
		return Node.new(NodeVariant.Continue)
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Return) then
		if self:Consume(TokenVariant.LowerIdent, "void") then
			return Node.new(NodeVariant.Return)
		elseif self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
			self.index = self.index - 1
			return Node.new(NodeVariant.Return)
		end
		return Node.new(NodeVariant.Return, self:Expr())
	end

	local var = self:Consume(TokenVariant.Ident)
	if var then
		--- Increment / Decrement
		if self:ConsumeTailing(TokenVariant.Operator, Operator.Inc) then
			return Node.new(NodeVariant.Increment, var)
		elseif self:Consume(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:ConsumeTailing(TokenVariant.Operator, Operator.Dec) then
			return Node.new(NodeVariant.Decrement, var)
		elseif self:Consume(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		--- Compound Assignment
		if self:Consume(TokenVariant.Operator, Operator.Aadd) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Aadd, self:Expr() })
		elseif self:Consume(TokenVariant.Operator, Operator.Asub) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Asub, self:Expr() })
		elseif self:Consume(TokenVariant.Operator, Operator.Amul) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Amul, self:Expr() })
		elseif self:Consume(TokenVariant.Operator, Operator.Adiv) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Adiv, self:Expr() })
		end

		-- Didn't match anything. Might be something else.
		self.index = self.index - 1
	end

	local is_local, var = self:Consume(TokenVariant.Keyword, Keyword.Local) ~= nil, self:Consume(TokenVariant.Ident)
	if not var then
		self:Assert(not is_local, "Invalid operator (local) must be used for variable declaration.")
	else
		local exprs = { { var, is_local and {} or self:Indices(), self:GetTrace() } }
		while self:Consume(TokenVariant.Operator, Operator.Ass) do
			local id = self:Consume(TokenVariant.Ident)
			if id then
				self:PushTrace()
				-- Var = Var = ...
				exprs[#exprs + 1] = { id, self:Indices(), self:PopTrace() }
			else
				return Node.new(NodeVariant.Assignment, { is_local, exprs, self:Expr() })
			end
		end

		-- Edge case where last assignment is an indexing operation.
		-- X = Y = T[5]
		local last = table.remove(exprs)
		last = Node.new(NodeVariant.ExprIndex, { Node.new(NodeVariant.ExprIdent, last[1]), last[2] })

		return Node.new(NodeVariant.Assignment, { is_local, exprs, last })
	end

	-- Switch Case
	if self:Consume(TokenVariant.Keyword, Keyword.Switch) then
		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() expected before switch condition" )
			local expr = self:Expr()
		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) expected before switch condition" )

		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.LCurly), "Left curly bracket ({) expected after switch condition" )

		local cases, default = {}, nil
		if not self:Eof() and not self:Consume(TokenVariant.Grammar, Grammar.RParen) then
			self:Assert( self:Consume(TokenVariant.Keyword, Keyword.Case) or self:Consume(TokenVariant.Keyword, Keyword.Default), "Expected case or default in switch block" )
			self.index = self.index - 1

			while true do
				local case, expr = self:Consume(TokenVariant.Keyword, Keyword.Case)
				if case then
					expr = self:Expr()
					self:Assert( self:Consume(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after case condition" )
				end

				local default_ = self:Consume(TokenVariant.Keyword, Keyword.Default)
				if default_ then
					self:Assert(not default, "Only one default case (default:) may exist.")
					self:Assert( self:Consume(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after default case" )
				elseif not case then
					break
				end

				if self:Eof() then
					self:Error("Case block is missing after case declaration.")
				end

				local block = {}
				while true do
					self:PushTrace()
					if self:Consume(TokenVariant.Keyword, Keyword.Case) or self:Consume(TokenVariant.Keyword, Keyword.Default) or self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
						self.index = self.index - 1
						break
					elseif self:Consume(TokenVariant.Grammar, Grammar.Comma) then
						self:Error("Statement separator (,) must not appear multiple times")
					elseif self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
						self:Error("Statement separator (,) must be suceeded by statement")
					end

					self:PushTrace()
						local stmt = self:Stmt() or self:Expr()
						stmt.trace = self:PopTrace()
					block[#block + 1] = stmt

					if not self:Consume(TokenVariant.Grammar, Grammar.Comma) then
						if self:Eof() then break end

						if not self:At().whitespaced then
							self:Error("Statements must be separated by comma (,) or whitespace")
						end
					end
				end

				if default_ then
					default = Node.new(NodeVariant.Block, block, self:PopTrace())
				else
					cases[#cases + 1] = { expr, Node.new(NodeVariant.Block, block, self:PopTrace()) }
				end
			end
		end

		self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RCurly), "Right curly bracket (}) missing, to close switch block")

		return Node.new(NodeVariant.Switch, { expr, cases, default })
	end

	-- Function definition
	if self:Consume(TokenVariant.Keyword, Keyword.Function) then
		local type_or_name = self:Assert( self:Consume(TokenVariant.LowerIdent), "Expected function return type or name after function keyword")

		if self:Consume(TokenVariant.Operator, Operator.Col) then
			-- function entity:xyz()
			return Node.new(NodeVariant.Function, { nil, type_or_name, self:Assert(self:Consume(TokenVariant.LowerIdent), "Expected function name after colon (:)"), self:Parameters(), self:Block() })
		end

		local meta_or_name = self:Consume(TokenVariant.LowerIdent)
		if meta_or_name then
			if self:Consume(TokenVariant.Operator, Operator.Col) then
				-- function void entity:xyz()
				return Node.new(NodeVariant.Function, { type_or_name, meta_or_name, self:Assert(self:Consume(TokenVariant.LowerIdent), "Expected function name after colon (:)"), self:Parameters(), self:Block() })
			else
				-- function void test()
				return Node.new(NodeVariant.Function, { type_or_name, nil, meta_or_name, self:Parameters(), self:Block() })
			end
		else
			-- function test()
			return Node.new(NodeVariant.Function, { nil, nil, type_or_name, self:Parameters(), self:Block() })
		end
	end

	-- #include
	if self:Consume(TokenVariant.Keyword, Keyword["#Include"]) then
		local path = self:Assert( self:Consume(TokenVariant.String), "include path (string) expected after #include")

		self.include_files[#self.include_files + 1] = path.value
		return Node.new(NodeVariant.Include, path.value)
	end

	-- Try catch
	if self:Consume(TokenVariant.Keyword, Keyword.Try) then
		local stmt = self:Block()

		if self:Consume(TokenVariant.Keyword, Keyword.Catch) then
			if not self:Consume(TokenVariant.Grammar, Grammar.LParen) then
				self:Error("Left parenthesis (() expected after catch keyword")
			end

			local err_ident = self:Consume(TokenVariant.Ident)
			if not err_ident then
				self:Error("Variable expected after left parenthesis (() in catch statement")
			end

			if not self:Consume(TokenVariant.Grammar, Grammar.RParen) then
				self:Error("Right parenthesis ()) missing, to close catch statement")
			end

			return Node.new(NodeVariant.Try, {stmt, err_ident, self:Block()})
		else
			self:Error("Try block must be followed by catch statement")
		end
	end

	-- Do while
	if self:Consume(TokenVariant.Keyword, Keyword.Do) then
		local block = self:Block()
		self:Assert( self:Consume(TokenVariant.Keyword, Keyword.While), "while expected after do and code block (do {...} )")
		return Node.new(NodeVariant.While, { self:Condition(), block })
	end

	-- Event
	if self:Consume(TokenVariant.Keyword, Keyword.Event) then
		local name = self:Assert( self:Consume(TokenVariant.LowerIdent), "Expected event name after 'event' keyword")
		return Node.new(NodeVariant.Event, { name, self:Parameters(), self:Block() })
	end
end

function Parser:Type()
	local type = self:Consume(TokenVariant.LowerIdent)
	if type and type.value == "normal" then
		type.value = "number"
	end
	return type
end

---@alias Index { [1]: Node, [2]: Token<string>?, [3]: Trace }
---@return Index[]
function Parser:Indices()
	local indices = {}
	while self:ConsumeTailing(TokenVariant.Grammar, Grammar.LSquare) do
		self:PushTrace()
		local exp = self:Expr()

		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			local type = self:Assert(self:Type(), "Indexing operator ([]) requires a valid type [X, t]")
			self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RSquare), "Right square bracket (]) missing, to close indexing operator [X,t]" )

			indices[#indices + 1] = { exp, type, self:PopTrace() }
		elseif self:ConsumeTailing(TokenVariant.Grammar, Grammar.RSquare) then
			indices[#indices + 1] = { exp, nil, self:PopTrace() }
		else
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		end
	end

	return indices
end

function Parser:Block()
	if not self:Consume(TokenVariant.Grammar, Grammar.LCurly) then
		self:Error("Left curly bracket ({) expected for block")
	end

	self:PushTrace()
	local stmts = {}
	if self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
		return Node.new(NodeVariant.Block, stmts, self:PopTrace())
	end

	if not self:Eof() then
		while true do
			if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
				self:Error("Statement separator (,) must not appear multiple times")
			elseif self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
				self:Error("Statement separator (,) must be suceeded by statement")
			end

			self:PushTrace()
				local stmt = self:Stmt() or self:Expr()
				stmt.trace = self:PopTrace()
			stmts[#stmts + 1] = stmt

			if self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
				return Node.new(NodeVariant.Block, stmts, self:PopTrace())
			end

			if not self:Consume(TokenVariant.Grammar, Grammar.Comma) then
				if self:Eof() then break end

				if not self:At().whitespaced then
					self:Error("Statements must be separated by comma (,) or whitespace")
				end
			end
		end
	end

	self:Error("Right curly bracket (}) missing, to close block")
end

--- `type` is nil in case of the default param type. (number)
---@alias Parameter { name: Token<string>, type: Token<string>? }

---@return Parameter[]?
function Parser:Parameters()
	self:Assert( self:Consume(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() must appear for function parameters name")

	local params = {}
	if self:Consume(TokenVariant.Grammar, Grammar.RParen) then
		return params
	end

	while true do
		local variadic
		if self:Consume(TokenVariant.Grammar, Grammar.LSquare) then
			local temp = {}
			repeat
				temp[#temp + 1] = self:Assert(self:Consume(TokenVariant.Ident), "Expected parameter name")
			until self:Consume(TokenVariant.Grammar, Grammar.RSquare)

			local typ, len = nil, #params
			if self:Consume(TokenVariant.Operator, Operator.Col) then
				typ = self:Assert( self:Type(), "Expected type after colon (:)" )
			else
				self:Warning("You should explicitly mark the type of these parameters")
			end

			for k, name in ipairs(temp) do
				params[len + k] = { name = name, type = typ }
			end
		else
			variadic = self:Consume(TokenVariant.Operator, Operator.Spread)

			local name, type = self:Assert(self:Consume(TokenVariant.Ident), "Expected parameter name")
			if self:Consume(TokenVariant.Operator, Operator.Col) then
				type = self:Assert(self:Type(), "Expected valid parameter type")
			end

			params[#params + 1] = { name = name, type = type }
		end

		if variadic then
			self:Assert( self:Consume(TokenVariant.Grammar, Grammar.RParen), "Variadic parameter must be final in list" )
			break
		elseif self:Consume(TokenVariant.Grammar, Grammar.Comma) then
		elseif self:Consume(TokenVariant.Grammar, Grammar.RParen) then
			return params
		else
			self:Error("Expected comma (,) to separate parameters")
		end
	end
end

function Parser:Expr()
	-- Error for compound operators in expression
	if self:Consume(TokenVariant.Ident) then
		if self:Consume(TokenVariant.Operator, Operator.Ass) then
			self:Error("Assignment operator (=) must not be part of equation")
		end

		if self:Consume(TokenVariant.Operator, Operator.Aadd) then
			self:Error("Additive assignment operator (+=) must not be part of equation")
		elseif self:Consume(TokenVariant.Operator, Operator.Asub) then
			self:Error("Subtractive assignment operator (-=) must not be part of equation")
		elseif self:Consume(TokenVariant.Operator, Operator.Amul) then
			self:Error("Multiplicative assignment operator (*=) must not be part of equation")
		elseif self:Consume(TokenVariant.Operator, Operator.Adiv) then
			self:Error("Divisive assignment operator (/=) must not be part of equation")
		end

		self.index = self.index - 1
	end

	-- Ternary or Default
	self:PushTrace()
	local cond = self:Expr2()
	if self:Consume(TokenVariant.Operator, Operator.Qsm) then
		local if_true = self:Expr()

		if not self:Consume(TokenVariant.Operator, Operator.Col) then -- perhaps we want to make sure there is space around this (method bug)
			self:Error("Conditional operator (:) must appear after expression to complete conditional")
		end

		return Node.new(NodeVariant.ExprTernary, { cond, if_true, self:Expr() }, self:PopTrace())
	end

	if self:Consume(TokenVariant.Operator, Operator.Def) then
		return Node.new(NodeVariant.ExprDefault, { cond, self:Expr() }, self:PopTrace())
	end

	cond.trace = self:PopTrace()
	return cond
end

---@param func fun(self: Parser): Node
---@param variant NodeVariant
---@param tbl Operator[]
---@return Node
function Parser:RecurseLeft(func, variant, tbl)
	local lhs, hit = func(self), true
	while hit do
		hit = false
		for _, op in ipairs(tbl) do
			if self:Consume(TokenVariant.Operator, op) then
				local rhs = func(self)
				hit, lhs = true, Node.new(variant, { lhs, op, rhs }, self:GetTrace())
				break
			end
		end
	end

	return lhs
end

function Parser:Expr2()
	return self:RecurseLeft(self.Expr3, NodeVariant.ExprLogicalOp, { Operator.Or, Operator.And })
end

function Parser:Expr3()
	return self:RecurseLeft(self.Expr4, NodeVariant.ExprBinaryOp, { Operator.Band, Operator.Bor, Operator.Bxor })
end

function Parser:Expr4()
	return self:RecurseLeft(self.Expr5, NodeVariant.ExprEquals, { Operator.Eq, Operator.Neq })
end

function Parser:Expr5()
	return self:RecurseLeft(self.Expr6, NodeVariant.ExprComparison, { Operator.Gth, Operator.Lth, Operator.Geq, Operator.Leq })
end

function Parser:Expr6()
	return self:RecurseLeft(self.Expr7, NodeVariant.ExprBitShift, { Operator.Bshr, Operator.Bshl })
end

function Parser:Expr7()
	return self:RecurseLeft(self.Expr8, NodeVariant.ExprArithmetic, { Operator.Add, Operator.Sub })
end

function Parser:Expr8()
	return self:RecurseLeft(self.Expr9, NodeVariant.ExprArithmetic, { Operator.Mul, Operator.Div, Operator.Mod })
end

function Parser:Expr9()
	return self:RecurseLeft(self.Expr10, NodeVariant.ExprArithmetic, { Operator.Exp })
end

---@return Node
function Parser:Expr10()
	if self:ConsumeLeading(TokenVariant.Operator, Operator.Add) then
		return self:Expr11()
	elseif self:Consume(TokenVariant.Operator, Operator.Add) then
		self:Error("Identity operator (+) must not be succeeded by whitespace")
	end

	if self:ConsumeLeading(TokenVariant.Operator, Operator.Sub) then
		return Node.new(NodeVariant.ExprUnaryOp, { Operator.Sub, self:Expr11() })
	elseif self:Consume(TokenVariant.Operator, Operator.Sub) then
		self:Error("Negation operator (-) must not be succeeded by whitespace")
	end

	if self:ConsumeLeading(TokenVariant.Operator, Operator.Not) then
		return Node.new(NodeVariant.ExprUnaryOp, { Operator.Not, self:Expr10() })
	elseif self:Consume(TokenVariant.Operator, Operator.Not) then
		self:Error("Logical not operator (!) must not be succeeded by whitespace")
	end

	return self:Expr11()
end

---@return Node[]
function Parser:Arguments()
	if not self:ConsumeTailing(TokenVariant.Grammar, Grammar.LParen) then
		if self:Consume(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left parenthesis (() must not be preceded by whitespace")
		else
			self:Error("Left parenthesis (() must appear to start argument list")
		end
	end

	local arguments = {}
	if self:Consume(TokenVariant.Grammar, Grammar.RParen) then
		return arguments
	end

	while true do
		arguments[#arguments + 1] = self:Expr()

		if self:Consume(TokenVariant.Grammar, Grammar.RParen) then
			return arguments
		elseif not self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			self:Error("Right parenthesis ()) missing, to close argument list")
		end
	end
end

---@param start_bracket Grammar
---@param end_bracket Grammar
---@return { [1]: Node, [2]: Node }[]?
function Parser:ArgumentsKV(start_bracket, end_bracket)
	local before = self.index
	if not self:ConsumeTailing(TokenVariant.Grammar, start_bracket) then
		if self:Consume(TokenVariant.Grammar, start_bracket) then
			self:Error("Bracket must not be preceded by whitespace")
		else
			self.index = before
			return
		end
	end

	if self:Consume(TokenVariant.Grammar, end_bracket) then
		return {}
	end

	local first = self:Expr()

	if not self:Consume(TokenVariant.Operator, Operator.Ass) then
		self.index = before
		return
	else
		local arguments = { { first, self:Expr() } }

		if self:Consume(TokenVariant.Grammar, end_bracket) then
			return arguments
		end

		while true do
			self:Assert( self:Consume(TokenVariant.Grammar, Grammar.Comma), "Expected comma (,) in between key value arguments" )

			local key = self:Expr()
			self:Assert( self:Consume(TokenVariant.Operator, Operator.Ass), "Assignment operator (=) missing, to complete expression" )
			arguments[#arguments + 1] = {key, self:Expr()}

			if self:Consume(TokenVariant.Grammar, end_bracket) then
				return arguments
			end
		end
	end
end

---@return Node
function Parser:Expr11()
	local expr = self:Expr12()

	while true do
		if self:ConsumeTailing(TokenVariant.Operator, Operator.Col) then
			local fn = self:ConsumeTailing(TokenVariant.LowerIdent)
			if not fn then
				if self:Consume(TokenVariant.LowerIdent) then
					self:Error("Method operator (:) must not be preceded by whitespace")
				else
					self:Error("Method operator (:) must be followed by method name")
				end
			end

			return Node.new(NodeVariant.ExprMethodCall, { expr, fn, self:Arguments() }, self:GetTrace())
		else
			local indices = self:Indices()
			if #indices > 0 then
				return Node.new(NodeVariant.ExprIndex, { expr, indices })
			elseif self:Consume(TokenVariant.Grammar, Grammar.LSquare) then
				self:Error("Indexing operator ([]) must not be preceded by whitespace")
			end

			if self:ConsumeTailing(TokenVariant.Grammar, Grammar.LParen) then
				self.index = self.index - 1

				local args, typ = self:Arguments()

				if self:Consume(TokenVariant.Grammar, Grammar.LSquare) then
					typ = self:Consume(TokenVariant.LowerIdent)
					if not typ then
						self:Error("Return type operator ([]) requires a lower case type [type]")
					end

					if not self:Consume(TokenVariant.Grammar, Grammar.RSquare) then
						self:Error("Right square bracket (]) missing, to close return type operator [type]")
					end
				end

				return Node.new(NodeVariant.ExprStringCall, { expr, args, typ })
			else
				break
			end
		end
	end

	return expr
end

---@return Node
function Parser:Expr12()
	if self:Consume(TokenVariant.Grammar, Grammar.LParen) then
		local expr = self:Expr()

		if not self:Consume(TokenVariant.Grammar, Grammar.RParen) then
			self:Error("Right parenthesis ()) missing, to close grouped equation")
		end

		return expr
	end

	local fn = self:Consume(TokenVariant.LowerIdent)
	if fn then
		-- Transform key value
		if fn.value == "array" then
			return Node.new(NodeVariant.ExprArray, self:ArgumentsKV(Grammar.LParen, Grammar.RParen) or self:Arguments(), self:GetTrace())
		elseif fn.value == "table" then
			return Node.new(NodeVariant.ExprTable, self:ArgumentsKV(Grammar.LParen, Grammar.RParen) or self:Arguments(), self:GetTrace())
		end
		return Node.new(NodeVariant.ExprCall, { fn.value, self:Arguments() }, self:GetTrace())
	end

	-- Decimal / Hexadecimal / Binary numbers
	local num = self:Consume(TokenVariant.Decimal) or self:Consume(TokenVariant.Hexadecimal) or self:Consume(TokenVariant.Binary)
	if num then
		return Node.new(NodeVariant.ExprLiteral, { "n", num.value }, num.trace)
	end

	-- Complex / Quaternion numbers
	local adv_num = self:Consume(TokenVariant.Complex) or self:Consume(TokenVariant.Quat)
	if adv_num then
		local num, suffix = adv_num.value:match("^([-+e0-9.]*)(.*)$")
		num = self:Assert(tonumber(num), "Malformed numeric literal")
		local value, type
		if suffix == "" then
			value, type = num, "n"
		elseif suffix == "i" then
			value, type = {0, num}, "c"
		elseif suffix == "j" then
			value, type = {0, 0, num, 0}, "q"
		elseif suffix == "k" then
			value, type = {0, 0, 0, num}, "q"
		else
			self:Error("unrecognized numeric suffix " .. suffix)
		end

		return Node.new(NodeVariant.ExprLiteral, { type, value }, adv_num.trace)
	end

	-- String
	local str = self:Consume(TokenVariant.String)
	if str then
		return Node.new(NodeVariant.ExprLiteral, { "s", str.value }, str.trace)
	end

	-- Unary Wiremod Operators
	for _, v in ipairs { { "~", Operator.Trg }, { "$", Operator.Dlt }, { "->", Operator.Imp } } do
		if self:Consume(TokenVariant.Operator, v[2]) then
			local ident = self:ConsumeTailing(TokenVariant.Ident)
			if not ident then
				if self:Consume(TokenVariant.Ident) then
					self:Error("Operator (" .. v[1] .. ") must not be succeeded by whitespace")
				else
					self:Error("Operator (" .. v[1] .. ") must be followed by variable")
				end
			end

			return Node.new(NodeVariant.ExprUnaryWire, { v[2], ident })
		end
	end

	-- Increment/Decrement
	if self:Consume(TokenVariant.Ident) then
		if self:ConsumeTailing(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be part of equation")
		elseif self:Consume(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:ConsumeTailing(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be part of equation")
		elseif self:Consume(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		self.index = self.index - 1
	end

	-- Variables
	local ident =  self:Consume(TokenVariant.Ident)
	if ident then
		return Node.new(NodeVariant.ExprIdent, ident, ident.trace)
	end

	-- Error Messages
	if self:Eof() then
		self:Error("Further input required at end of code, incomplete expression")
	end

	if self:Consume(TokenVariant.Operator, Operator.Add) then
		self:Error("Addition operator (+) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Sub) then -- can't occur (unary minus)
		self:Error("Subtraction operator (-) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Mul) then
		self:Error("Multiplication operator (*) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Div) then
		self:Error("Division operator (/) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Mod) then
		self:Error("Modulo operator (%) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Exp) then
		self:Error("Exponentiation operator (^) must be preceded by equation or value")

	elseif self:Consume(TokenVariant.Operator, Operator.Ass) then
		self:Error("Assignment operator (=) must be preceded by variable")
	elseif self:Consume(TokenVariant.Operator, Operator.Aadd) then
		self:Error("Additive assignment operator (+=) must be preceded by variable")
	elseif self:Consume(TokenVariant.Operator, Operator.Asub) then
		self:Error("Subtractive assignment operator (-=) must be preceded by variable")
	elseif self:Consume(TokenVariant.Operator, Operator.Amul) then
		self:Error("Multiplicative assignment operator (*=) must be preceded by variable")
	elseif self:Consume(TokenVariant.Operator, Operator.Adiv) then
		self:Error("Divisive assignment operator (/=) must be preceded by variable")

	elseif self:Consume(TokenVariant.Operator, Operator.And) then
		self:Error("Logical and operator (&) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Or) then
		self:Error("Logical or operator (|) must be preceded by equation or value")

	elseif self:Consume(TokenVariant.Operator, Operator.Eq) then
		self:Error("Equality operator (==) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Neq) then
		self:Error("Inequality operator (!=) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Gth) then
		self:Error("Greater than or equal to operator (>=) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Lth) then
		self:Error("Less than or equal to operator (<=) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Geq) then
		self:Error("Greater than operator (>) must be preceded by equation or value")
	elseif self:Consume(TokenVariant.Operator, Operator.Leq) then
		self:Error("Less than operator (<) must be preceded by equation or value")

	elseif self:Consume(TokenVariant.Operator, Operator.Inc) then
		self:Error("Increment operator (++) must be preceded by variable")
	elseif self:Consume(TokenVariant.Operator, Operator.Dec) then
		self:Error("Decrement operator (--) must be preceded by variable")

	elseif self:Consume(TokenVariant.Grammar, Grammar.RParen) then
		self:Error("Right parenthesis ()) without matching left parenthesis")
	elseif self:Consume(TokenVariant.Grammar, Grammar.LCurly) then
		self:Error("Left curly bracket ({) must be part of an if/while/for-statement block")
	elseif self:Consume(TokenVariant.Grammar, Grammar.RCurly) then
		self:Error("Right curly bracket (}) without matching left curly bracket")
	elseif self:Consume(TokenVariant.Grammar, Grammar.LSquare) then
		self:Error("Left square bracket ([) must be preceded by variable")
	elseif self:Consume(TokenVariant.Grammar, Grammar.RSquare) then
		self:Error("Right square bracket (]) without matching left square bracket")

	elseif self:Consume(TokenVariant.Grammar, Grammar.Comma) then
		self:Error("Comma (,) not expected here, missing an argument?")
	elseif self:Consume(TokenVariant.Operator, Operator.Col) then
		self:Error("Method operator (:) must not be preceded by whitespace")
	elseif self:Consume(TokenVariant.Operator, Operator.Spread) then
		self:Error("Spread operator (...) must only be used as a function parameter")

	elseif self:Consume(TokenVariant.Keyword, Keyword.If) then
		self:Error("If keyword (if) must not appear inside an equation")
	elseif self:Consume(TokenVariant.Keyword, Keyword.Elseif) then
		self:Error("Else-if keyword (elseif) must be part of an if-statement")
	elseif self:Consume(TokenVariant.Keyword, Keyword.Else) then
		self:Error("Else keyword (else) must be part of an if-statement")
	else
		self:Error("Unexpected token found (" .. self:At():display() .. ")")
	end

	error("unreachable")
end