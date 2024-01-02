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
---@param trace Trace
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
	Assignment = 12, -- `X = Y[2, number] = Z[2] = 5` or `local X = 5`
	Const = 13, -- const X = 5

	Switch = 14, -- `switch (<EXPR>) { case <EXPR>, <STMT>* default, <STMT*> }
	Function = 15, -- `function test() {}`
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
	ExprDynCall = 32, -- `Var()`
	ExprUnaryWire = 33, -- `~Var` `$Var` `->Var`
	ExprArray = 34, -- `array(1, 2, 3)` or `array(1 = 2, 2 = 3)`
	ExprTable = 35, -- `table(1, 2, 3)` or `table(1 = 2, "test" = 3)`
	ExprFunction = 36, -- `function() {}`
	ExprLiteral = 37, -- `"test"` `5e2` `4.023` `4j`
	ExprIdent = 38, -- `Variable`
	ExprConstant = 39, -- `_FOO`
}

Parser.Variant = NodeVariant

local NodeVariantLookup = {}
for var, i in pairs(NodeVariant) do
	NodeVariantLookup[i] = var
end

function Node:debug()
	return string.format("Node { variant = %s, data = %s, trace = %s }", NodeVariantLookup[self.variant], self.data, self.trace)
end

--- Returns whether the node is an expression variant.
function Node:isExpr()
	return self.variant >= NodeVariant.ExprTernary
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

function Parser:Consume(variant --[[@param variant TokenVariant]])
	local token = self.tokens[self.index] --[[self:At() inline]]
	if not token or token.variant ~= variant then return end

	self.index = self.index + 1
	return token
end

function Parser:ConsumeValue(variant --[[@param variant TokenVariant]], value --[[@param value any]])
	local token = self.tokens[self.index]
	if token == nil or token.variant ~= variant or token.value ~= value then return end

	self.index = self.index + 1
	return token
end

function Parser:ConsumeTailing(variant --[[@param variant TokenVariant]], value --[[@param value any]])
	local token = self.tokens[self.index]
	if token == nil or token.variant ~= variant or token.whitespaced then return end
	if value ~= nil and token.value ~= value then return end

	self.index = self.index + 1
	return token
end

--- SAFETY: This works fine only assuming ConsumeLeading *always* passes a value which is true atm.
function Parser:ConsumeLeading(variant --[[@param variant TokenVariant]], value --[[@param value any]])
	local token = self.tokens[self.index + 1] --[[self:Peek() inline]]
	if token == nil or token.whitespaced then return end

	local at = self.tokens[self.index]
	if at.variant ~= variant or at.value ~= value then return end
	self.index = self.index + 1

	return at
end

---@param message string
---@param trace Trace?
---@param quick_fix { replace: string, at: Trace }[]?
function Parser:Error(message, trace, quick_fix)
	error( Error.new( message, trace or self:Prev().trace, nil, quick_fix ), 2 )
end

---@param message string
---@param trace Trace?
---@param quick_fix { replace: string, at: Trace }[]?
function Parser:Warning(message, trace, quick_fix)
	self.warnings[#self.warnings + 1] = Warning.new( message, trace or self:Prev().trace, quick_fix )
end

---@generic T
---@param v? T
---@param message string
---@param trace Trace?
---@return T
function Parser:Assert(v, message, trace)
	if not v then error( Error.new( message, trace or self:Prev().trace ), 2 ) end
	return v
end

---@return Node ast, table<string, boolean> dvars, string[] include_files
function Parser:Process(tokens)
	self.index, self.tokens, self.ntokens, self.warnings, self.delta_vars, self.include_files = 1, tokens, #tokens, {}, {}, {}

	local stmts = {}
	if self:Eof() then return Node.new(NodeVariant.Block, stmts, Trace.new(0, 0, 0, 0)), self.delta_vars, self.include_files end

	while true do
		if self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
			self:Error("Statement separator (,) must not appear multiple times")
		end

		local stmt = self:Stmt() or self:Expr()
		stmts[#stmts + 1] = stmt

		if self:Eof() then break end

		if not self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
			self:Assert(self:At().whitespaced, "Statements must be separated by comma (,) or whitespace", stmt.trace)
		end
	end

	local trace = (#stmts ~= 0) and stmts[1].trace:stitch(stmts[#stmts].trace) or Trace.new(1, 1, 1, 1)
	return Node.new(NodeVariant.Block, stmts, trace), self.delta_vars, self.include_files
end

---@return Node
function Parser:Condition()
	self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() expected before condition")
		local expr = self:Expr()
	self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) missing, to close condition")
	return expr
end

---@return Node?
function Parser:Stmt()
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.If) then
		local cond, block = self:Condition(), self:Assert( self:Block(), "Expected block after if condition")

		---@type { [1]: Node?, [2]: Node }[]
		local chain = { {cond, block} }
		while self:ConsumeValue(TokenVariant.Keyword, Keyword.Elseif) do
			local cond, block = self:Condition(), self:Assert( self:Block(), "Expected block after elseif condition")
			chain[#chain + 1] = { cond, block }
		end

		if self:ConsumeValue(TokenVariant.Keyword, Keyword.Else) then
			chain[#chain + 1] = { nil, self:Assert( self:Block(), "Expected block after else keyword") }
		end

		return Node.new(NodeVariant.If, chain, cond.trace:stitch(self:Prev().trace))
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.While) then
		local trace = self:Prev().trace
		return Node.new(NodeVariant.While, { self:Condition(), self:Block(), false }, trace:stitch(self:Prev().trace))
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.For) then
		local trace = self:Prev().trace
		if not self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left Parenthesis (() must appear before condition")
		end

		local var = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected for numeric index" )
		self:Assert( self:ConsumeValue(TokenVariant.Operator, Operator.Ass), "Assignment operator (=) expected to preceed variable" )

		local start = self:Expr()
		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after start value" )

		local stop = self:Expr()

		local step
		if self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
			step = self:Expr()
		end

		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) missing, to close for statement" )

		return Node.new(NodeVariant.For, { var, start, stop, step, self:Block() }, trace:stitch(self:Prev().trace))
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Foreach) then
		local trace = self:Prev().trace
		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() missing after foreach statement" )

		local key = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected to hold the key" )

		local key_type
		if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
			key_type = self:Assert(self:Type(), "Type expected after colon")
		end

		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after key variable" )

		local value = self:Assert( self:Consume(TokenVariant.Ident), "Variable expected to hold the value" )
		self:Assert( self:ConsumeValue(TokenVariant.Operator, Operator.Col), "Colon (:) expected to separate type from variable" )

		local value_type = self:Assert(self:Type(), "Type expected after colon")
		self:Assert( self:ConsumeValue(TokenVariant.Operator, Operator.Ass), "Equals sign (=) expected after value type to specify table" )

		local table = self:Expr()

		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Missing right parenthesis after foreach statement" )

		return Node.new(NodeVariant.Foreach, { key, key_type, value, value_type, table, self:Block() }, trace:stitch(self:Prev().trace))
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Break) then
		return Node.new(NodeVariant.Break, nil, self:Prev().trace)
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Continue) then
		return Node.new(NodeVariant.Continue, nil, self:Prev().trace)
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Return) then
		local trace = self:Prev().trace
		if self:ConsumeValue(TokenVariant.LowerIdent, "void") then
			return Node.new(NodeVariant.Return, nil, trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
			self.index = self.index - 1
			return Node.new(NodeVariant.Return, nil, trace)
		else
			return Node.new(NodeVariant.Return, self:Expr(), trace:stitch(self:At().trace))
		end
	end

	local var = self:Consume(TokenVariant.Ident)
	if var then
		--- Increment / Decrement
		if self:ConsumeTailing(TokenVariant.Operator, Operator.Inc) then
			return Node.new(NodeVariant.Increment, var, var.trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:ConsumeTailing(TokenVariant.Operator, Operator.Dec) then
			return Node.new(NodeVariant.Decrement, var, var.trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		--- Compound Assignment
		if self:ConsumeValue(TokenVariant.Operator, Operator.Aadd) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Add, self:Expr() }, var.trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Asub) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Sub, self:Expr() }, var.trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Amul) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Mul, self:Expr() }, var.trace:stitch(self:Prev().trace))
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Adiv) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Div, self:Expr() }, var.trace:stitch(self:Prev().trace))
		end

		-- Didn't match anything. Might be something else.
		self.index = self.index - 1
	end

	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Const) then
		local trace = self:Prev().trace

		local name = self:Assert(self:Consume(TokenVariant.Ident), "Expected variable name after const")
		self:Assert( self:ConsumeValue(TokenVariant.Operator, Operator.Ass), "Expected = for constant declaration" )
		local value = self:Assert(self:Expr(), "Expected expression for constant declaration")

		return Node.new(NodeVariant.Const, { name, value }, trace:stitch(self:Prev().trace))
	end

	local is_local, var = self:ConsumeValue(TokenVariant.Keyword, Keyword.Local) or self:ConsumeValue(TokenVariant.Keyword, Keyword.Let), self:Consume(TokenVariant.Ident)
	if not var then
		self:Assert(not is_local, "Invalid operator (local) must be used for variable declaration.")
	else
		local revert, prev = self.index, self.index
		local assignments = { { var, is_local and {} or self:Indices(), (is_local or var).trace:stitch(self:Prev().trace) } }
		while self:ConsumeValue(TokenVariant.Operator, Operator.Ass) do
			local ident = self:Consume(TokenVariant.Ident)
			if ident then
				prev = self.index
				assignments[#assignments + 1] = { ident, self:Indices(), ident.trace:stitch(self:Prev().trace) }
			else
				return Node.new(NodeVariant.Assignment, { is_local, assignments, self:Expr() }, (is_local or var).trace:stitch(self:Prev().trace))
			end
		end

		if #assignments == 1 then -- No assignment
			self.index = revert - 1
		else -- Last 'assignment' is the expression.
			table.remove(assignments)
			self.index = prev - 1
			return Node.new(NodeVariant.Assignment, { is_local, assignments, self:Expr() }, (is_local or var).trace:stitch(self:Prev().trace))
		end
	end

	-- Switch Case
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Switch) then
		local trace = self:Prev().trace
		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() expected before switch condition" )
			local expr = self:Expr()
		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) expected before switch condition" )

		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LCurly), "Left curly bracket ({) expected after switch condition" )

		local cases, default = {}, nil
		if not self:Eof() and not self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
			self:Assert( self:ConsumeValue(TokenVariant.Keyword, Keyword.Case) or self:ConsumeValue(TokenVariant.Keyword, Keyword.Default), "Expected case or default in switch block" )
			self.index = self.index - 1

			while true do
				local case, expr = self:ConsumeValue(TokenVariant.Keyword, Keyword.Case)
				if case then
					expr = self:Expr()
					self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after case condition" )
				end

				local default_ = self:ConsumeValue(TokenVariant.Keyword, Keyword.Default)
				if default_ then
					self:Assert(not default, "Only one default case (default:) may exist.")
					self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma), "Comma (,) expected after default case" )
				elseif not case then
					break
				end

				if self:Eof() then
					self:Error("Case block is missing after case declaration.")
				end

				local block --[=[@type Node[]]=] = {}
				while true do
					if self:ConsumeValue(TokenVariant.Keyword, Keyword.Case) or self:ConsumeValue(TokenVariant.Keyword, Keyword.Default) or self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
						self.index = self.index - 1
						break
					elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
						self:Error("Statement separator (,) must not appear multiple times")
					elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
						self:Error("Statement separator (,) must be suceeded by statement")
					end

					local stmt = self:Stmt() or self:Expr()
					block[#block + 1] = stmt

					if not self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
						if self:Eof() then break end

						if not self:At().whitespaced then
							self:Error("Statements must be separated by comma (,) or whitespace", stmt.trace)
						end
					end
				end

				if default_ then
					local trace = (#block ~= 0) and default_.trace:stitch(block[1].trace):stitch(block[#block].trace) or default_.trace
					default = Node.new(NodeVariant.Block, block, trace)
				else ---@cast case Token # Know it isn't nil since (if not case then break end) above
					local trace = (#block ~= 0) and case.trace:stitch(block[1].trace):stitch(block[#block].trace) or case.trace
					cases[#cases + 1] = { expr, Node.new(NodeVariant.Block, block, trace) }
				end
			end
		end

		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly), "Right curly bracket (}) missing, to close switch block")

		return Node.new(NodeVariant.Switch, { expr, cases, default }, trace:stitch(self:Prev().trace))
	end

	-- Function definition
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Function) then
		local trace, type_or_name = self:Prev().trace, self:Assert( self:Type(), "Expected function return type or name after function keyword")

		if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
			-- function entity:xyz()
			return Node.new(NodeVariant.Function, { nil, type_or_name, self:Assert(self:Consume(TokenVariant.LowerIdent), "Expected function name after colon (:)"), self:Parameters(), self:Block() }, trace:stitch(self:Prev().trace))
		end

		local meta_or_name = self:Consume(TokenVariant.LowerIdent)
		if meta_or_name then
			if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
				-- function void entity:xyz()
				return Node.new(NodeVariant.Function, { type_or_name, meta_or_name, self:Assert(self:Consume(TokenVariant.LowerIdent), "Expected function name after colon (:)"), self:Parameters(), self:Block() }, trace:stitch(self:Prev().trace))
			else
				-- function void test()
				return Node.new(NodeVariant.Function, { type_or_name, nil, meta_or_name, self:Parameters(), self:Block() }, trace:stitch(self:Prev().trace))
			end
		else -- function test()
			self:Assert( type_or_name.value ~= "function", "Identifier expected. \"function\" is a reserved keyword that cannot be used here", trace )
			return Node.new(NodeVariant.Function, { nil, nil, type_or_name, self:Parameters(), self:Block() }, trace:stitch(self:Prev().trace))
		end
	end

	-- #include
	if self:ConsumeValue(TokenVariant.Keyword, Keyword["#Include"]) then
		local trace, path = self:Prev().trace, self:Assert( self:Consume(TokenVariant.String), "include path (string) expected after #include")

		self.include_files[#self.include_files + 1] = path.value
		return Node.new(NodeVariant.Include, path.value, trace:stitch(path.trace))
	end

	-- Try catch
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Try) then
		local trace, stmt = self:Prev().trace, self:Block()

		if self:ConsumeValue(TokenVariant.Keyword, Keyword.Catch) then
			if not self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen) then
				self:Error("Left parenthesis (() expected after catch keyword")
			end

			local err_ident = self:Consume(TokenVariant.Ident)
			if not err_ident then
				self:Error("Variable expected after left parenthesis (() in catch statement")
			end

			local ty
			if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
				ty = self:Assert(self:Type(), "Expected type name after : for error value", trace)
			end

			if not self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
				self:Error("Right parenthesis ()) missing, to close catch statement")
			end

			return Node.new(NodeVariant.Try, {stmt, err_ident, ty, self:Block()}, trace:stitch(self:Prev().trace))
		else
			self:Error("Try block must be followed by catch statement")
		end
	end

	-- Do while
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Do) then
		local trace, block = self:Prev().trace, self:Block()
		self:Assert( self:ConsumeValue(TokenVariant.Keyword, Keyword.While), "while expected after do and code block (do {...} )")
		return Node.new(NodeVariant.While, { self:Condition(), block, true }, trace:stitch(self:Prev().trace))
	end

	-- Event
	if self:ConsumeValue(TokenVariant.Keyword, Keyword.Event) then
		local trace, name = self:Prev().trace, self:Assert( self:Consume(TokenVariant.LowerIdent), "Expected event name after 'event' keyword")
		return Node.new(NodeVariant.Event, { name, self:Parameters(), self:Block() }, trace:stitch(self:Prev().trace))
	end
end

---@return Token<string>?
function Parser:Type()
	local type = self:Consume(TokenVariant.LowerIdent)
	if type then
		if type.value == "normal" then
			self:Warning("Use of deprecated type [normal]", type.trace, { { at = type.trace, replace = "number" } })
			type.value = "number"
		end
	else -- workaround to allow "function" as type while also being a keyword
		local fn = self:ConsumeValue(TokenVariant.Keyword, Keyword.Function)
		if fn then
			fn.value, fn.variant = "function", TokenVariant.LowerIdent
			return fn
		end
	end
	return type
end

---@alias Index { [1]: Node, [2]: Token<string>?, [3]: Trace }
---@return Index[]
function Parser:Indices()
	local indices = {}
	while true do
		local lsb = self:ConsumeTailing(TokenVariant.Grammar, Grammar.LSquare)
		if not lsb then break end

		local exp = self:Expr()

		if self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
			local type = self:Assert(self:Type(), "Indexing operator ([]) requires a valid type [X, t]")
			local rsb = self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RSquare), "Right square bracket (]) missing, to close indexing operator [X,t]" )

			indices[#indices + 1] = { exp, type, lsb.trace:stitch(rsb.trace) }
		elseif self:ConsumeTailing(TokenVariant.Grammar, Grammar.RSquare) then
			indices[#indices + 1] = { exp, nil, lsb.trace:stitch(self:Prev().trace) }
		else
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		end
	end

	return indices
end

function Parser:Block()
	local lcb = self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LCurly), "Left curly bracket ({) expected for block" )

	local stmts = {}
	if self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
		return Node.new(NodeVariant.Block, stmts, lcb.trace:stitch(self:Prev().trace))
	end

	if not self:Eof() then
		while true do
			if self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
				self:Error("Statement separator (,) must not appear multiple times")
			elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
				self:Error("Statement separator (,) must be suceeded by statement")
			end

			stmts[#stmts + 1] = self:Stmt() or self:Expr()

			if self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
				return Node.new(NodeVariant.Block, stmts, lcb.trace:stitch(self:Prev().trace))
			end

			if not self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
				if self:Eof() then break end
				self:Assert(self:At().whitespaced, "Statements must be separated by comma (,) or whitespace")
			end
		end
	end

	self:Error("Right curly bracket (}) missing, to close block")
end

--- `type` is nil in case of the default param type. (number)
---@alias Parameter { name: Token<string>, type: Token<string>?, variadic: boolean }

---@return Parameter[]?
function Parser:Parameters()
	self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen), "Left parenthesis (() must appear for function parameters name")

	local params = {}
	if self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
		return params
	end

	while true do
		local variadic
		if self:ConsumeValue(TokenVariant.Grammar, Grammar.LSquare) then
			local temp = {}
			repeat
				temp[#temp + 1] = self:Assert(self:Consume(TokenVariant.Ident), "Expected parameter name")
			until self:ConsumeValue(TokenVariant.Grammar, Grammar.RSquare)

			local typ, len = nil, #params
			if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
				typ = self:Assert( self:Type(), "Expected type after colon (:)" )
			else
				self:Warning("You should explicitly mark the type of these parameters")
			end

			for k, name in ipairs(temp) do
				params[len + k] = { name = name, type = typ, variadic = false }
			end
		else
			variadic = self:ConsumeValue(TokenVariant.Operator, Operator.Spread)

			local name, type = self:Assert(self:Consume(TokenVariant.Ident), "Expected parameter name")
			if self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
				type = self:Assert(self:Type(), "Expected valid parameter type")
			end

			params[#params + 1] = { name = name, type = type, variadic = variadic ~= nil }
		end

		if variadic then
			self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Variadic parameter must be final in list" )
			return params
		elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
		elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
			return params
		else
			self:Error("Expected comma (,) to separate parameters")
		end
	end
end

function Parser:Expr(ignore_assign)
	-- Error for compound operators in expression
	if self:Consume(TokenVariant.Ident) then
		if not ignore_assign and self:ConsumeValue(TokenVariant.Operator, Operator.Ass) then
			self:Error("Assignment operator (=) must not be part of equation ( Did you mean == ? )")
		end

		if self:ConsumeValue(TokenVariant.Operator, Operator.Aadd) then
			self:Error("Additive assignment operator (+=) must not be part of equation")
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Asub) then
			self:Error("Subtractive assignment operator (-=) must not be part of equation")
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Amul) then
			self:Error("Multiplicative assignment operator (*=) must not be part of equation")
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Adiv) then
			self:Error("Divisive assignment operator (/=) must not be part of equation")
		end

		self.index = self.index - 1
	end

	-- Ternary or Default
	local cond = self:Expr2()
	if self:ConsumeValue(TokenVariant.Operator, Operator.Qsm) then
		local if_true = self:Expr()

		if not self:ConsumeValue(TokenVariant.Operator, Operator.Col) then -- perhaps we want to make sure there is space around this (method bug)
			self:Error("Conditional operator (:) must appear after expression to complete conditional")
		end

		local if_false = self:Expr()

		return Node.new(NodeVariant.ExprTernary, { cond, if_true, if_false }, cond.trace:stitch(if_true.trace):stitch(if_false.trace))
	end

	if self:ConsumeValue(TokenVariant.Operator, Operator.Def) then
		local rhs = self:Expr()
		return Node.new(NodeVariant.ExprDefault, { cond, rhs }, cond.trace:stitch(rhs.trace))
	end

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
			if self:ConsumeValue(TokenVariant.Operator, op) then
				local rhs = func(self)
				hit, lhs = true, Node.new(variant, { lhs, op, rhs }, lhs.trace:stitch(rhs.trace))
				break
			end
		end
	end

	return lhs
end

function Parser:Expr2()
	return self:RecurseLeft(self.Expr3, NodeVariant.ExprLogicalOp, { Operator.Or })
end

function Parser:Expr3()
	return self:RecurseLeft(self.Expr4, NodeVariant.ExprLogicalOp, { Operator.And })
end

function Parser:Expr4()
	return self:RecurseLeft(self.Expr5, NodeVariant.ExprBinaryOp, { Operator.Bor })
end

function Parser:Expr5()
	return self:RecurseLeft(self.Expr6, NodeVariant.ExprBinaryOp, { Operator.Band })
end

function Parser:Expr6()
	return self:RecurseLeft(self.Expr7, NodeVariant.ExprBinaryOp, { Operator.Bxor })
end

function Parser:Expr7()
	return self:RecurseLeft(self.Expr8, NodeVariant.ExprEquals, { Operator.Eq, Operator.Neq })
end

function Parser:Expr8()
	return self:RecurseLeft(self.Expr9, NodeVariant.ExprComparison, { Operator.Gth, Operator.Lth, Operator.Geq, Operator.Leq })
end

function Parser:Expr9()
	return self:RecurseLeft(self.Expr10, NodeVariant.ExprBitShift, { Operator.Bshr, Operator.Bshl })
end

function Parser:Expr10()
	return self:RecurseLeft(self.Expr11, NodeVariant.ExprArithmetic, { Operator.Add, Operator.Sub })
end

function Parser:Expr11()
	return self:RecurseLeft(self.Expr12, NodeVariant.ExprArithmetic, { Operator.Mul, Operator.Div, Operator.Mod })
end

function Parser:Expr12()
	return self:RecurseLeft(self.Expr13, NodeVariant.ExprArithmetic, { Operator.Exp })
end

---@return Node
function Parser:Expr13()
	if self:ConsumeLeading(TokenVariant.Operator, Operator.Add) then
		return self:Expr14()
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Add) then
		self:Error("Identity operator (+) must not be succeeded by whitespace")
	end

	if self:ConsumeLeading(TokenVariant.Operator, Operator.Sub) then
		local trace, exp = self:Prev().trace, self:Expr14()
		return Node.new(NodeVariant.ExprUnaryOp, { Operator.Sub, exp }, trace:stitch(exp.trace))
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Sub) then
		self:Error("Negation operator (-) must not be succeeded by whitespace")
	end

	if self:ConsumeLeading(TokenVariant.Operator, Operator.Not) then
		local trace, exp = self:Prev().trace, self:Expr13()
		return Node.new(NodeVariant.ExprUnaryOp, { Operator.Not, exp }, trace:stitch(exp.trace))
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Not) then
		self:Error("Logical not operator (!) must not be succeeded by whitespace")
	end

	return self:Expr14()
end

---@return Node[]
function Parser:Arguments()
	if not self:ConsumeTailing(TokenVariant.Grammar, Grammar.LParen) then
		if self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left parenthesis (() must not be preceded by whitespace")
		else
			self:Error("Left parenthesis (() must appear to start argument list")
		end
	end

	local arguments = {}
	if self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
		return arguments
	end

	repeat
		arguments[#arguments + 1] = self:Expr()
	until not self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma)

	if not self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
		self:Error("Right parenthesis ()) missing, to close argument list")
	end

	return arguments
end

---@param start_bracket Grammar
---@param end_bracket Grammar
---@return { [1]: Node, [2]: Node }[]?
function Parser:ArgumentsKV(start_bracket, end_bracket)
	local before = self.index
	if not self:ConsumeTailing(TokenVariant.Grammar, start_bracket) then
		if self:ConsumeValue(TokenVariant.Grammar, start_bracket) then
			self:Error("Bracket must not be preceded by whitespace")
		else
			self.index = before
			return
		end
	end

	if self:ConsumeValue(TokenVariant.Grammar, end_bracket) then
		return {}
	end

	local first = self:Expr(true)

	if not self:ConsumeValue(TokenVariant.Operator, Operator.Ass) then
		self.index = before
		return
	else
		local arguments = { { first, self:Expr() } }

		if self:ConsumeValue(TokenVariant.Grammar, end_bracket) then
			return arguments
		end

		while true do
			self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma), "Expected comma (,) in between key value arguments" )

			local key = self:Expr()
			self:Assert( self:ConsumeValue(TokenVariant.Operator, Operator.Ass), "Assignment operator (=) missing, to complete expression" )
			arguments[#arguments + 1] = {key, self:Expr()}

			if self:ConsumeValue(TokenVariant.Grammar, end_bracket) then
				return arguments
			end
		end
	end
end

---@return Node
function Parser:Expr14()
	local expr = self:Expr15()

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

			expr = Node.new(NodeVariant.ExprMethodCall, { expr, fn, self:Arguments() }, expr.trace:stitch(self:Prev().trace))
		else
			local indices = self:Indices()
			if #indices > 0 then
				expr = Node.new(NodeVariant.ExprIndex, { expr, indices }, expr.trace:stitch(self:Prev().trace))
			elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.LSquare) then
				self:Error("Indexing operator ([]) must not be preceded by whitespace")
			elseif self:ConsumeTailing(TokenVariant.Grammar, Grammar.LParen) then
				self.index = self.index - 1

				local args, typ = self:Arguments()

				if self:ConsumeValue(TokenVariant.Grammar, Grammar.LSquare) then
					typ = self:Assert(self:Type(), "Return type operator ([]) requires a lower case type [type]")

					if not self:ConsumeValue(TokenVariant.Grammar, Grammar.RSquare) then
						self:Error("Right square bracket (]) missing, to close return type operator [type]")
					end
				end

				return Node.new(NodeVariant.ExprDynCall, { expr, args, typ }, expr.trace:stitch(self:Prev().trace))
			else
				break
			end
		end
	end

	return expr
end

---@return Node
function Parser:Expr15()
	if self:ConsumeValue(TokenVariant.Grammar, Grammar.LParen) then
		local expr = self:Expr()
		self:Assert( self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen), "Right parenthesis ()) missing, to close grouped equation" )
		return expr
	end

	local fn = self:Consume(TokenVariant.LowerIdent)
	if fn then
		-- Transform key value
		if fn.value == "array" then
			return Node.new(NodeVariant.ExprArray, self:ArgumentsKV(Grammar.LParen, Grammar.RParen) or self:Arguments(), fn.trace:stitch(self:Prev().trace))
		elseif fn.value == "table" then
			return Node.new(NodeVariant.ExprTable, self:ArgumentsKV(Grammar.LParen, Grammar.RParen) or self:Arguments(), fn.trace:stitch(self:Prev().trace))
		end

		return Node.new(NodeVariant.ExprCall, { fn, self:Arguments() }, fn.trace:stitch(self:Prev().trace))
	end

	local fn = self:ConsumeValue(TokenVariant.Keyword, Keyword.Function)
	if fn then
		return Node.new(NodeVariant.ExprFunction, { self:Parameters(), self:Assert(self:Block(), "Expected block to follow function") }, fn.trace:stitch(self:Prev().trace))
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
		local op = self:ConsumeValue(TokenVariant.Operator, v[2])
		if op then
			local ident = self:ConsumeTailing(TokenVariant.Ident)
			if not ident then
				if self:Consume(TokenVariant.Ident) then
					self:Error("Operator (" .. v[1] .. ") must not be succeeded by whitespace")
				else
					self:Error("Operator (" .. v[1] .. ") must be followed by variable")
				end
			end ---@cast ident Token

			if v[2] == Operator.Dlt then -- TODO: Delete this and move to analyzer step
				self.delta_vars[ident.value] = true
			end

			return Node.new(NodeVariant.ExprUnaryWire, { v[2], ident }, op.trace:stitch(ident.trace))
		end
	end

	-- Increment/Decrement
	if self:Consume(TokenVariant.Ident) then
		if self:ConsumeTailing(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be part of equation")
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:ConsumeTailing(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be part of equation")
		elseif self:ConsumeValue(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		self.index = self.index - 1
	end

	-- Variables
	local ident =  self:Consume(TokenVariant.Ident)
	if ident then
		return Node.new(NodeVariant.ExprIdent, ident, ident.trace)
	end

	local constant = self:Consume(TokenVariant.Constant)
	if constant then
		return Node.new(NodeVariant.ExprConstant, constant, constant.trace)
	end

	-- Error Messages
	if self:Eof() then
		self:Error("Further input required at end of code, incomplete expression")
	end

	if self:ConsumeValue(TokenVariant.Operator, Operator.Add) then
		self:Error("Addition operator (+) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Sub) then -- can't occur (unary minus)
		self:Error("Subtraction operator (-) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Mul) then
		self:Error("Multiplication operator (*) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Div) then
		self:Error("Division operator (/) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Mod) then
		self:Error("Modulo operator (%) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Exp) then
		self:Error("Exponentiation operator (^) must be preceded by equation or value")

	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Ass) then
		self:Error("Assignment operator (=) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Aadd) then
		self:Error("Additive assignment operator (+=) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Asub) then
		self:Error("Subtractive assignment operator (-=) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Amul) then
		self:Error("Multiplicative assignment operator (*=) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Adiv) then
		self:Error("Divisive assignment operator (/=) must be preceded by variable")

	elseif self:ConsumeValue(TokenVariant.Operator, Operator.And) then
		self:Error("Logical and operator (&) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Or) then
		self:Error("Logical or operator (|) must be preceded by equation or value")

	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Eq) then
		self:Error("Equality operator (==) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Neq) then
		self:Error("Inequality operator (!=) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Gth) then
		self:Error("Greater than or equal to operator (>=) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Lth) then
		self:Error("Less than or equal to operator (<=) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Geq) then
		self:Error("Greater than operator (>) must be preceded by equation or value")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Leq) then
		self:Error("Less than operator (<) must be preceded by equation or value")

	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Inc) then
		self:Error("Increment operator (++) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Dec) then
		self:Error("Decrement operator (--) must be preceded by variable")

	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RParen) then
		self:Error("Right parenthesis ()) without matching left parenthesis")
	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.LCurly) then
		self:Error("Left curly bracket ({) must be part of an if/while/for-statement block")
	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RCurly) then
		self:Error("Right curly bracket (}) without matching left curly bracket")
	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.LSquare) then
		self:Error("Left square bracket ([) must be preceded by variable")
	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.RSquare) then
		self:Error("Right square bracket (]) without matching left square bracket")

	elseif self:ConsumeValue(TokenVariant.Grammar, Grammar.Comma) then
		self:Error("Comma (,) not expected here, missing an argument?")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Col) then
		self:Error("Method operator (:) must not be preceded by whitespace")
	elseif self:ConsumeValue(TokenVariant.Operator, Operator.Spread) then
		self:Error("Spread operator (...) must only be used as a function parameter")

	elseif self:ConsumeValue(TokenVariant.Keyword, Keyword.If) then
		self:Error("If keyword (if) must not appear inside an equation")
	elseif self:ConsumeValue(TokenVariant.Keyword, Keyword.Elseif) then
		self:Error("Else-if keyword (elseif) must be part of an if-statement")
	elseif self:ConsumeValue(TokenVariant.Keyword, Keyword.Else) then
		self:Error("Else keyword (else) must be part of an if-statement")
	else
		self:Error("Unexpected token found (" .. self:At():display() .. ")", self:At().trace)
	end

	error("unreachable")
end