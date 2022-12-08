--[[
	Expression 2 Parser for Garry's Mod

	Rewritten by Vurv
	Notable changes:
		* Now uses Nodes and NodeVariant rather than strings (Much faster and better for intellisense)
]]

AddCSLuaFile()

---@class Parser
---@field tokens Token[]
---@field ntokens integer
---@field index integer
---@field warnings Warning[]
---@field traces NodeTrace[] # Stack of Traces to push and pop.
---@field delta_vars table<string, boolean>
---@field include_files string[]
local Parser = {}
Parser.__index = Parser

---@param tokens table?
function Parser.new(tokens)
	return setmetatable({ tokens = tokens or {}, ntokens = tokens and #tokens or 0, index = 1, warnings = {} }, Parser)
end

E2Lib.Parser = Parser

---@class Node
---@field variant NodeVariant
---@field data any
---@field start_col integer
---@field start_line integer
---@field end_col integer
---@field end_line integer
local Node = {}
Node.__index = Node

---@param variant NodeVariant
---@param data any
---@return Node
function Node.new(variant, data)
	return setmetatable({ variant = variant, data = data }, Node)
end

---@enum NodeVariant
local NodeVariant = {
	--- Statements
	Sequence = 1,

	-- `if (1) {} elseif (1) {} else {}`
	If = 2,
	-- `while (1) {}`, `do {} while(1)`
	While = 3,
	-- `for (I = 1, 2, 3) {}`
	For = 4,
	-- `foreach(K, V = T) {}`
	Foreach = 5,

	Break = 6,
	Continue = 7,
	Return = 8,

	-- `++`
	Increment = 9,
	-- `--`
	Decrement = 10,

	-- `+=`, `-=`, `*=`, `/=`
	CompoundArithmetic = 11,

	-- `local X = 5`
	DefineLocal = 12,

	-- `X=Y=Z=5`
	Assignment = 13,

	-- `X[Y] = 5`
	IndexSet = 14,
	-- `X[Y, type][2]`
	IndexGet = 15,

	Switch = 16,
	Function = 17,

	Include = 18,
	Try = 19,

	--- Compile time constructs
	Event = 20,

	--- Expressions

	-- `X ? Y : Z`
	ExprTernary = 21,

	-- `X ?: Y`
	ExprDefault = 22,

	-- `|` `&` (Yes they are flipped.)
	ExprLogicalOp = 23,

	-- `||` `&&` `^^`
	ExprBinaryOp = 24,


	-- `>` `<` `>=` `<=`
	ExprComparison = 25,

	-- `==`
	ExprEquals = 26,

	-- `>>` `<<`
	ExprBitShift = 27,

	-- `+` `-` `*` `/` `^` `%`
	ExprArithmetic = 28,

	-- `-` `+` `!`
	ExprUnaryOp = 29,

	-- `<EXPR>:call()`
	ExprMethodCall = 30,

	-- `<EXPR>[<EXPR>, <type>?]`
	ExprIndex = 31,

	-- (<EXPR>)
	ExprGrouped = 32,

	-- `call()`
	ExprCall = 33,

	-- `~Var` `$Var` `->Var`
	ExprUnaryWire = 34,

	-- `23` `"str"`
	ExprLiteral = 35,

	-- `Variable`
	ExprVar = 36
}

local NodeVariantLookup = {}
for var, i in pairs(NodeVariant) do
	NodeVariantLookup[i] = var
end

function Node:debug()
	return string.format("Node { variant = %s, data = %s }", NodeVariantLookup[self.variant], self.data)
end
Node.__tostring = Node.debug

--[[

The following is a description of the E2 language as a parsing
expression grammar. Note that the parser does all its semantic analysis
while parsing, forbidding certain things which this grammar allows.

* ε is the end-of-file
* E? matches zero or one occurrences of T (and will always match one if possible)
* E* matches zero or more occurrences of T (and will always match as many as possible)
* E F matches E (and then whitespace) and then F
* E / F tries matching E, if it fails it matches F (from the start location)
* &E matches E, but does not consume any input.
* !E matches everything except E, and does not consume any input.

Root ← Stmts

Stmts ← Stmt1 (("," / " ") Stmt1)* ε

Stmt1 ← ("if" Cond Block IfElseIf)? Stmt2
Stmt2 ← ("while" Cond Block)? Stmt3
Stmt3 ← ("for" "(" Var "=" Expr1 "," Expr1 ("," Expr1)? ")" Block)? Stmt4
Stmt4 ← ("foreach" "(" Var "," Var ":" Fun "=" Expr1 ")" Block)? Stmt5
Stmt5 ← ("break" / "continue")? Stmt6
Stmt6 ← (Var ("++" / "--"))? Stmt7
Stmt7 ← (Var ("+=" / "-=" / "*=" / "/="))? Stmt8
Stmt8 ← "local"? (Var (&"[" Index ("=" Stmt8)? / "=" Stmt8))? Stmt9
Stmt9 ← ("switch" "(" Expr1 ")" "{" SwitchBlock)? Stmt10
Stmt10 ← (FunctionStmt / ReturnStmt)? Stmt11
Stmt11 ← ("#include" String)? Stmt12
Stmt12 ← ("try" Block "catch" "(" Var ")" Block)? Stmt13
Stmt13 ← ("do" Block "while" Cond)? Expr1
Stmt14 ← ("event" Fun "(" FunctionArgs Block)

FunctionStmt ← "function" FunctionHead "(" FunctionArgs Block
FunctionHead ← (Type Type ":" Fun / Type ":" Fun / Type Fun / Fun)
FunctionArgs ← (FunctionArg ("," FunctionArg)*)? ")"
FunctionArg ← Var (":" Type)?

ReturnStmt ← "return" ("void" / &"}" / Expr1)
IfElseIf ← "elseif" Cond Block IfElseIf / IfElse
IfElse ← "else" Block
Cond ← "(" Expr1 ")"
Block ← "{" (Stmt1 (("," / " ") Stmt1)*)? "}"
SwitchBlock ← (("case" Expr1 / "default") CaseBlock)* "}"
CaseBlock ← (Stmt1 (("," / " ") Stmt1)*)? &("case" / "default" / "}")

Expr1 ← !(Var "=") !(Var "+=") !(Var "-=") !(Var "*=") !(Var "/=") Expr2
Expr2 ← Expr3 (("?" Expr1 ":" Expr1) / ("?:" Expr1))?
Expr3 ← Expr4 ("|" Expr4)*
Expr4 ← Expr5 ("&" Expr5)*
Expr5 ← Expr6 ("||" Expr6)*
Expr6 ← Expr7 ("&&" Expr7)*
Expr7 ← Expr8 ("^^" Expr8)*
Expr8 ← Expr9 (("==" / "!=") Expr9)*
Expr9 ← Expr10 ((">" / "<" / ">=" / "<=") Expr10)*
Expr10 ← Expr11 (("<<" / ">>") Expr11)*
Expr11 ← Expr12 (("+" / "-") Expr12)*
Expr12 ← Expr13 (("*" / "/" / "%") Expr13)*
Expr13 ← Expr14 ("^" Expr14)*
Expr14 ← ("+" / "-" / "!") Expr15
Expr15 ← Expr16 (MethodCallExpr / TableIndexExpr)?
Expr16 ← "(" Expr1 ")" / FunctionCallExpr / Expr17
Expr17 ← Number / String / "~" Var / "$" Var / "->" Var / Expr18
Expr18 ← !(Var "++") !(Var "--") Expr19
Expr19 ← Var

MethodCallExpr ← ":" Fun "(" (Expr1 ("," Expr1)*)? ")"
TableIndexExpr ← "[" Expr1 ("," Type)? "]"

FunctionCallExpr ← Fun "(" KeyValueList? ")"
KeyValueList ← (KeyValue ("," KeyValue))*
KeyValue = Expr1 ("=" Expr1)?

]]

---@param tokens Token[]
---@return boolean ok
---@return table ast
function Parser.Execute(tokens)
	return xpcall(Parser.Process, E2Lib.errorHandler, Parser.new(tokens), tokens)
end

local Tokenizer = E2Lib.Tokenizer
local Token, TokenVariant = Tokenizer.Token, Tokenizer.Variant
local Keyword, Grammar, Operator = E2Lib.Keyword, E2Lib.Grammar, E2Lib.Operator

function Parser:Eof()
	return self.index > self.ntokens
end

function Parser:Peek()
	return self.tokens[self.index + 1]
end

---@param i integer?
function Parser:At(i)
	return self.tokens[i or self.index]
end

function Parser:Prev()
	return self.tokens[self.index - 1]
end

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

---@param variant TokenVariant
---@param value? number|string|boolean
---@param message string
---@return Token?
function Parser:MustConsume(variant, value, message)
	local token = self:At()
	if not token or token.variant ~= variant then self:Error(message) end
	if value ~= nil and token.value ~= value then self:Error(message) end

	self.index = self.index + 1
	return token
end

---@param message string
---@param token Token?
function Parser:Error(message, token)
	if token then
		error(message .. " at line " .. token.start_line .. ", char " .. token.start_col, 0)
	else
		error(message .. " at line " .. self:At().start_line .. ", char " .. self:At().start_col, 0)
	end
end

---@param message string
function Parser:Assert(v, message)
	if not v then self:Error(message) end
	return v
end


function Parser:Process(tokens)
	self.index, self.tokens, self.warnings, self.delta_vars, self.include_files = 1, tokens, {}, {}, {}

	local stmts = {}
	if self:Eof() then return stmts end

	while true do
		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			self:Error("Statement separator (,) must not appear multiple times")
		end

		local prior = self.index
		local stmt = self:Stmt()
		local start, ed = self:At(prior), self:At() or self:At(self.index - 1)

		stmt.start_col = start.start_col
		stmt.start_line = start.start_line
		stmt.end_col = ed.end_col
		stmt.end_line = ed.end_line

		stmts[#stmts + 1] = stmt

		if self:Eof() then break end

		if not self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			if not self:Peek().whitespaced then
				self:Error("Statements must be separated by comma (,) or whitespace")
			end
		end
	end

	return stmts, self.delta_vars, self.include_files
end

---@param variant TokenVariant
---@param value? number|string|boolean
function Parser:ConsumeTailing(variant, value)
	local token = self:At()
	if not token or token.whitespaced then return false end

	return self:Consume(variant, value)
end

---@param variant TokenVariant
---@param value? number|string|boolean
function Parser:ConsumeLeading(variant, value)
	local token = self:Peek()
	if not token or token.whitespaced then return false end

	return self:Consume(variant, value)
end

function Parser:Stmt()
	if self:Consume(TokenVariant.Keyword, Keyword.If) then
		return Node.new(NodeVariant.If, { self:Cond(), self:Block(), self:IfElseIf() })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.While) then
		return Node.new(NodeVariant.While, { self:Cond(), self:Block("while condition"), false })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.For) then
		if not self:Consume(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left Parenthesis (() must appear before condition")
		end

		local var = self:MustConsume(TokenVariant.Ident, nil, "Variable expected for numeric index")
		self:MustConsume(TokenVariant.Operator, Operator.Ass, "Assignment operator (=) expected to preceed variable")

		local start = self:Expr1()
		self:MustConsume(TokenVariant.Grammar, Grammar.Comma, "Comma (,) expected after start value")

		local stop = self:Expr1()

		local step
		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			step = self:Expr1()
		end

		self:MustConsume(TokenVariant.Grammar, Grammar.RParen, "Right parenthesis ()) missing, to close for statement")

		return Node.new(NodeVariant.For, { var, start, stop, step, self:Block("for statement") })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Foreach) then
		self:MustConsume(TokenVariant.Grammar, Grammar.LParen, "Left parenthesis (() missing after foreach statement")

		local key = self:MustConsume(TokenVariant.Ident, nil, "Variable expected to hold the key")

		local key_type
		if self:Consume(TokenVariant.Operator, Operator.Col) then
			key_type = self:Assert(self:Type(), "Type expected after colon")
		end

		self:MustConsume(TokenVariant.Grammar, Grammar.Comma, "Comma (,) expected after key variable")

		local value = self:MustConsume(TokenVariant.Ident, nil, "Variable expected to hold the value")
		self:MustConsume(TokenVariant.Operator, Operator.Col, "Colon (:) expected to separate type from variable")

		local value_type = self:Assert(self:Type(), "Type expected after colon")
		self:MustConsume(TokenVariant.Operator, Operator.Ass, "Equals sign (=) expected after value type to specify table")

		local table = self:Expr1()

		self:MustConsume(TokenVariant.Grammar, Grammar.RParen, "Missing right parenthesis after foreach statement")

		return Node.new(NodeVariant.Foreach, { key, key_type, value,  value_type, table, self:Block("foreach statement") })
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Break) then
		return Node.new(NodeVariant.Break)
	end

	if self:Consume(TokenVariant.Keyword, Keyword.Continue) then
		return Node.new(NodeVariant.Continue)
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
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Aadd, self:Expr1() })
		elseif self:Consume(TokenVariant.Operator, Operator.Asub) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Asub, self:Expr1() })
		elseif self:Consume(TokenVariant.Operator, Operator.Amul) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Amul, self:Expr1() })
		elseif self:Consume(TokenVariant.Operator, Operator.Adiv) then
			return Node.new(NodeVariant.CompoundArithmetic, { var, Operator.Adiv, self:Expr1() })
		end

		-- Didn't match anything. Might be something else.
		self.index = self.index - 1
	end

	self:Error("Didn't match any statement")
end

function Parser:Type()
	local type = self:Consume(TokenVariant.LowerIdent)
	return type and wire_expression_types[string.upper(type.value)]
end

function Parser:Index()
	local indices = {}
	self:PushTrace()
	while self:ConsumeTailing(TokenVariant.Grammar, Grammar.LSquare) do
		local exp = self:Expr1()

		if self:Consume(TokenVariant.Grammar, Grammar.Comma) then
			local type = self:Assert(self:Type(), "Indexing operator ([]) requires a valid type [X, t]")
			self:MustConsume(TokenVariant.Grammar, Grammar.RSquare, "Right square bracket (]) missing, to close indexing operator [X,t]")

			indices[#indices + 1] = { exp, type[1], self:PopTrace() }
		elseif self:ConsumeTailing(TokenVariant.Grammar, Grammar.RSquare) then
			indices[#indices + 1] = { exp, nil, self:PopTrace() }
			return indices
		else
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		end
	end
end

function Parser:Stmt8(parentLocalized)
	-- Example result: NodeVariant.AssignmentLocal { Var,  }
	local sets, localized = {}, false
	while true do
		if self:Consume(TokenVariant.Keyword, Keyword.Local) then
			-- Can't do local Var = local E = 5
			-- Can do local Var = E = 5
			localized = self:Assert(not localized, "Assignment can't contain roaming local operator")
		end

		local var = self:Consume(TokenVariant.Ident)
		if not var then
			self:Assert(not localized, "Invalid operator (local) must be used for variable declaration.")
			break
		end

		local tbpos = self.index

		if self:ConsumeTailing(TokenVariant.Grammar, Grammar.LSquare) then
			local indexes = self:Index()

			if self:Consume(TokenVariant.Operator, Operator.Ass) then
				self:Assert(not localized and not parentLocalized, "Invalid operator (local).")

				-- Example Result: NodeVariant.Assignment { ExprVar, { NodeVariant.IndexGet(1, table), NodeVariant.IndexGet(1, table), NodeVariant.IndexGet(2, nil) } }
				sets[#sets + 1] = Node.new(NodeVariant.Assignment, { Node.new(NodeVariant.ExprVar, var), indexes })
			end
		elseif self:Consume(TokenVariant.Operator, Operator.Ass) then
			if localized or parentLocalized then
				return Node.new(NodeVariant.DefineLocal, var, self:Stmt8(true))
			else
				return Node.new(NodeVariant.Assignment, var, self:Stmt8(false))
			end
		elseif localized then
			self:Error("Invalid operator (local) must be used for variable declaration.")
		end

		self.index = tbpos
	end
end

--[======[
function Parser:Stmt9()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Switch) then
		local trace = self:GetTokenTrace()

		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left parenthesis (() expected before switch condition")
		end

		local expr = self:Expr1()

		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
			self:Error("Right parenthesis ()) expected after switch condition")
		end

		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LCurly) then
			self:Error("Left curly bracket ({) expected after switch condition")
		end

		loopdepth = loopdepth + 1
		local cases, default = self:SwitchBlock()
		loopdepth = loopdepth - 1

		return self:Instruction(trace, "switch", expr, cases, default)
	end

	return self:Stmt10()
end

function Parser:Stmt10()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Function) then

		local Trace = self:GetTokenTrace()


		local Name, Return, Type
		local NameToken, ReturnToken, TypeToken
		local Args, Temp = {}, {}


		if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then --get the name
			Name = self:GetTokenData()
			NameToken = self.token -- Copy the current token for error reporting

			-- We check if the previous token was actualy the return not the name
			if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then
				Return = Name
				ReturnToken = NameToken

				Name = self:GetTokenData()
				NameToken = self.token
			end

			-- We check if the name token is actually the type
			if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
				if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then
					Type = Name
					TypeToken = NameToken

					Name = self:GetTokenData()
					NameToken = self.token
				else
					self:Error("Function name must appear after colon (:)")
				end
			end
		end


		if Return and Return ~= "void" then -- Check the retun value

			if Return ~= Return:lower() then
				self:Error("Function return type must be lowercased", ReturnToken)
			end

			if Return == "number" then Return = "normal" end

			Return = Return:upper()

			if not wire_expression_types[Return] then
				self:Error("Invalid return argument '" .. E2Lib.limitString(Return:lower(), 10) .. "'", ReturnToken)
			end

			Return = wire_expression_types[Return][1]

		else
			Return = ""
		end

		if Type then -- check the Type

			if Type ~= Type:lower() then self:Error("Function object type must be full lowercase", TypeToken) end

			if Type == "number" then Type = "normal" end

			if Type == "void" then self:Error("Void can not be used as function object type", TypeToken) end

			Type = Type:upper()

			if not wire_expression_types[Type] then
				self:Error("Invalid data type '" .. E2Lib.limitString(Type:lower(), 10) .. "'", TypeToken)
			end

			Temp["This"] = true

			Args[1] = { "This", Type }
		else
			Type = ""
		end

		if not Name then self:Error("Function name must follow function declaration") end

		if Name[1] ~= Name[1]:lower() then self:Error("Function name must start with a lower case letter", NameToken) end


		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left parenthesis (() must appear after function name")
		end

		self:FunctionArgs(Temp, Args)

		local Sig = Name .. "("
		for I = 1, #Args do
			local Arg = Args[I]
			Sig = Sig .. (Arg[3] and ".." or "") .. wire_expression_types[Arg[2]][1]
			if I == 1 and Arg[1] == "This" and Type ~= '' then
				Sig = Sig .. ":"
			end
		end
		Sig = Sig .. ")"

		if wire_expression2_funcs[Sig] then self:Error("Function '" .. Sig .. "' already exists") end

		-- Variadic signatures for lua created functions are ..., while user defined ones use ..<t>.
		-- Check if ... functions exist as to not essentially override them
		local lua_variadic_sig = string.gsub(Sig, "%.%.[rt]", "...")
		if wire_expression2_funcs[lua_variadic_sig] then self:Error("Can't override function " .. lua_variadic_sig .. " with user defined variadic function " .. Sig) end

		local Inst = self:Instruction(Trace, "function", Sig, Return, Type, Args, self:Block("function declaration"))

		return Inst

		-- Return Statment
	elseif self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Return) then

		local Trace = self:GetTokenTrace()

		if self:AcceptRoamingToken(TokenVariant.LowerIdent, "void") or (self.readtoken.variant == TokenVariant.Grammar and self.readtoken.value == Grammar.RCurly) then
			return self:Instruction(Trace, "return")
		end

		return self:Instruction(Trace, "return", self:Expr1())

		-- Void Missplacement
	elseif self:AcceptRoamingToken(TokenVariant.LowerIdent, "void") then
		self:Error("Void may only exist after return")
	end

	return self:Stmt11()
end

function Parser:Stmt11()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword["#Include"]) then

		local Trace = self:GetTokenTrace()

		-- if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
		-- self:Error("Left parenthesis (() must appear after include")
		-- end

		if not self:AcceptRoamingToken(TokenVariant.String) then
			self:Error("include path (string) expected after include")
		end

		local Path = self:GetTokenData()

		-- if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
		-- self:Error("Right parenthesis ()) must appear after include path")
		-- end

		self.includes[#self.includes + 1] = Path

		return self:Instruction(Trace, "inclu", Path)
	end

	return self:Stmt12()
end

function Parser:Stmt12()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Try) then
		local trace = self:GetTokenTrace()
		local stmt = self:Block("try block")
		if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Catch) then
			if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
				self:Error("Left parenthesis (() expected after catch keyword")
			end

			if not self:AcceptRoamingToken(TokenVariant.Ident) then
				self:Error("Variable expected after left parenthesis (() in catch statement")
			end
			local var_name = self:GetTokenData()

			if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
				self:Error("Right parenthesis ()) missing, to close catch statement")
			end

			return self:Instruction(trace, "try", stmt, var_name, self:Block("catch block") )
		else
			self:Error("Try block must be followed by catch statement")
		end
	end
	return self:Stmt13()
end

function Parser:Stmt13()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Do) then
		local trace = self:GetTokenTrace()

		loopdepth = loopdepth + 1
		local code = self:Block("do keyword")

		if not self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.While) then
			self:Error("while expected after do and code block (do {...} )")
		end

		local condition = self:Cond()


		local whl = self:Instruction(trace, "whl", condition, code,
			true) -- Skip condition check first time?
		loopdepth = loopdepth - 1

		return whl
	end

	return self:Stmt14()
end

function Parser:Stmt14()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Event) then
		local trace = self:GetTokenTrace()

		local name = self:AcceptRoamingToken(TokenVariant.LowerIdent)
		if not name then
			self:Error("Expected event name after 'event' keyword")
		end
		local name = self:GetTokenData()

		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
			self:Error("Left parenthesis (() must appear after event name")
		end

		local temp, args = {}, {}
		self:FunctionArgs(temp, args)

		return self:Instruction(trace, "event", name, args, self:Block("event block"))
	end

	return self:Expr1()
end

function Parser:FunctionArgs(Temp, Args)
	if self:HasTokens() and not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
		while true do

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then self:Error("Argument separator (,) must not appear multiple times") end

			-- ...Array:array
			if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Spread) then
				if not self:AcceptRoamingToken(TokenVariant.LowerIdent) and not self:AcceptRoamingToken(TokenVariant.Ident) then
					self:Error("Variable name expected after spread operator")
				end

				local name = self:GetTokenData()

				if not self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
					self:Error("Colon (:) expected after spread argument name")
				end

				if not self:AcceptRoamingToken(TokenVariant.LowerIdent) then
					self:Error("Variable type expected after colon (:)")
				end

				local type = self:GetTokenData()
				if type ~= type:lower() then
					self:Error("Variable type must be lowercased")
				end

				type = type:upper()

				if not wire_expression_types[type] then
					self:Error("Invalid type specified")
				end

				if type ~= "ARRAY" and type ~= "TABLE" then
					self:Error("Only array or table type is supported for spread arguments")
				end

				if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
					self:Error("Spread argument must be the last argument")
				end

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
					self:Error("Right parenthesis ()) expected after spread argument")
				end

				Temp[name] = true
				Args[#Args + 1] = { name, type, true }

				return
			end

			if self:AcceptRoamingToken(TokenVariant.Ident) or self:AcceptRoamingToken(TokenVariant.LowerIdent) then
				self:FunctionArg(Temp, Args)
			elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LSquare) then
				self:FunctionArgList(Temp, Args)
			end

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
				break

			elseif not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
				self:NextToken()
				self:Error("Right parenthesis ()) expected after function arguments")
			end
		end
	end
end

function Parser:FunctionArg(Temp, Args)
	local Type = "normal"

	local Name = self:GetTokenData()

	if not Name then self:Error("Variable required") end

	if Name[1] ~= Name[1]:upper() then self:Error("Variable must start with uppercased letter") end

	if Temp[Name] then self:Error("Variable '" .. Name .. "' is already used as an argument,") end

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
		if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then
			Type = self:GetTokenData()
		else
			self:Error("Type expected after colon (:)")
		end
	end

	if Type ~= Type:lower() then self:Error("Type must be lowercased") end

	if Type == "number" then Type = "normal" end

	Type = Type:upper()

	if not wire_expression_types[Type] then
		self:Error("Invalid type specified")
	end


	Temp[Name] = true
	Args[#Args + 1] = { Name, Type, false }
end

function Parser:FunctionArgList(Temp, Args)

	if self:HasTokens() then

		local Vars = {}
		while true do
			if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then
				local Name = self:GetTokenData()

				if not Name then self:Error("Variable required") end

				if Name[1] ~= Name[1]:upper() then self:Error("Variable must start with uppercased letter") end

				if Temp[Name] then self:Error("Variable '" .. Name .. "' is already used as an argument") end

				Temp[Name] = true
				Vars[#Vars + 1] = Name
			elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
				break

			else -- if !self:HasTokens() then
				self:NextToken()
				self:Error("Right square bracket (]) expected at end of argument list")
			end
		end

		if #Vars == 0 then
			self:TrackBack()
			self:TrackBack()
			self:Error("Variables expected in variable list")
		end

		local Type = "normal"

		if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
			if self:AcceptRoamingToken(TokenVariant.LowerIdent) or self:AcceptRoamingToken(TokenVariant.Ident) then
				Type = self:GetTokenData()
			else
				self:Error("Type expected after colon (:)")
			end
		end

		if Type ~= Type:lower() then self:Error("Type must be lowercased") end

		if Type == "number" then Type = "normal" end

		Type = Type:upper()

		if not wire_expression_types[Type] then
			self:Error("Invalid type specified")
		end

		for I = 1, #Vars do
			Args[#Args + 1] = { Vars[I], Type, false }
		end

	else
		self:Error("Variable expected after left square bracket ([) in argument list")
	end
end

function Parser:IfElseIf()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Elseif) then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "if", self:Cond(), self:Block("elseif condition"), self:IfElseIf())
	end

	return self:IfElse()
end

function Parser:IfElse()
	if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Else) then
		return self:Block("else")
	end

	local trace = self:GetTokenTrace()
	return self:Instruction(trace, "seq")
end

function Parser:Cond()
	if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
		self:Error("Left parenthesis (() expected before condition")
	end

	local expr = self:Expr1()

	if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
		self:Error("Right parenthesis ()) missing, to close condition")
	end

	return expr
end


function Parser:Block(block_type)
	local trace = self:GetTokenTrace()
	local stmts = self:Instruction(trace, "seq")

	if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LCurly) then
		self:Error("Left curly bracket ({) expected after " .. (block_type or "condition"))
	end

	local token = self:GetToken()

	if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
		return stmts
	end

	if self:HasTokens() then
		while true do
			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
				self:Error("Statement separator (,) must not appear multiple times")
			elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
				self:Error("Statement separator (,) must be suceeded by statement")
			end

			stmts[#stmts + 1] = self:Stmt1()

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
				return stmts
			end

			if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
				if not self:HasTokens() then break end

				if not self.readtoken.whitespaced then
					self:Error("Statements must be separated by comma (,) or whitespace")
				end
			end
		end
	end

	self:Error("Right curly bracket (}) missing, to close switch block", token)
end

function Parser:SwitchBlock() -- Shhh this is a secret. Do not tell anybody about this, Rusketh!
	local cases = {}
	local default

	if self:HasTokens() and not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then

		if not self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Case) and not self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Default) then
			self:Error("Case Operator (case) expected in case block.", self:GetToken())
		end

		self:TrackBack()

		while true do

			if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Case) then
				local expr = self:Expr1()

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
					self:Error("Comma (,) expected after case condition")
				end

				cases[#cases + 1] = { expr, self:CaseBlock() }

			elseif self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Default) then

				if default then
					self:Error("Only one default case (default:) may exist.")
				end

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
					self:Error("Comma (,) expected after default case")
				end

				default = true
				cases[#cases + 1] = { nil, self:CaseBlock() }

			else
				break
			end
		end
	end

	if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
		self:Error("Right curly bracket (}) missing, to close statement block", self:GetToken())
	end

	return cases
end

function Parser:CaseBlock() -- Shhh this is a secret. Do not tell anybody about this, Rusketh!
	if self:HasTokens() then
		local stmts = self:Instruction(self:GetTokenTrace(), "seq")

		if self:HasTokens() then
			while true do

				if self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Case) or self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Default) or self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
					self:TrackBack()
					return stmts
				elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
					self:Error("Statement separator (,) must not appear multiple times")
				elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
					self:Error("Statement separator (,) must be suceeded by statement")
				end

				stmts[#stmts + 1] = self:Stmt1()

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
					if not self:HasTokens() then break end

					if not self.readtoken.whitespaced then
						self:Error("Statements must be separated by comma (,) or whitespace")
					end
				end
			end
		end
	else
		self:Error("Case block is missing after case declaration.")
	end
end

function Parser:Expr1()
	self.exprtoken = self:GetToken()

	if self:AcceptRoamingToken(TokenVariant.Ident) then
		if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Ass) then
			self:Error("Assignment operator (=) must not be part of equation")
		end

		if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Aadd) then
			self:Error("Additive assignment operator (+=) must not be part of equation")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Asub) then
			self:Error("Subtractive assignment operator (-=) must not be part of equation")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Amul) then
			self:Error("Multiplicative assignment operator (*=) must not be part of equation")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Adiv) then
			self:Error("Divisive assignment operator (/=) must not be part of equation")
		end

		self:TrackBack()
	end

	return self:Expr2()
end

function Parser:Expr2()
	local expr = self:Expr3()

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Qsm) then
		local trace = self:GetTokenTrace()
		local exprtrue = self:Expr1()

		if not self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then -- perhaps we want to make sure there is space around this (method bug)
			self:Error("Conditional operator (:) must appear after expression to complete conditional", self:GetToken())
		end

		return self:Instruction(trace, "cnd", expr, exprtrue, self:Expr1())
	end

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Def) then
		local trace = self:GetTokenTrace()

		return self:Instruction(trace, "def", expr, self:Expr1())
	end

	return expr
end

function Parser:Expr3()
	return self:RecurseLeft(self.Expr4, { Operator.Or })
end

function Parser:Expr4()
	return self:RecurseLeft(self.Expr5, { Operator.And })
end

function Parser:Expr5()
	return self:RecurseLeft(self.Expr6, { Operator.Bor })
end

function Parser:Expr6()
	return self:RecurseLeft(self.Expr7, { Operator.Band })
end

function Parser:Expr7()
	return self:RecurseLeft(self.Expr8, { Operator.Bxor })
end

function Parser:Expr8()
	return self:RecurseLeft(self.Expr9, { Operator.Eq, Operator.Neq })
end

function Parser:Expr9()
	return self:RecurseLeft(self.Expr10, { Operator.Gth, Operator.Lth, Operator.Geq, Operator.Leq })
end

function Parser:Expr10()
	return self:RecurseLeft(self.Expr11, { Operator.Bshr, Operator.Bshl })
end

function Parser:Expr11()
	return self:RecurseLeft(self.Expr12, { Operator.Add, Operator.Sub })
end

function Parser:Expr12()
	return self:RecurseLeft(self.Expr13, { Operator.Mul, Operator.Div, Operator.Mod })
end

function Parser:Expr13()
	return self:RecurseLeft(self.Expr14, { Operator.Exp })
end

function Parser:Expr14()
	if self:AcceptLeadingToken(TokenVariant.Operator, Operator.Add) then
		return self:Expr15()
	elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Add) then
		self:Error("Identity operator (+) must not be succeeded by whitespace")
	end

	if self:AcceptLeadingToken(TokenVariant.Operator, Operator.Sub) then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "neg", self:Expr15())
	elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Sub) then
		self:Error("Negation operator (-) must not be succeeded by whitespace")
	end

	if self:AcceptLeadingToken(TokenVariant.Operator, Operator.Not) then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "not", self:Expr14())
	elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Not) then
		self:Error("Logical not operator (!) must not be succeeded by whitespace")
	end

	return self:Expr15()
end

function Parser:Expr15()
	local expr = self:Expr16()

	while true do
		if self:AcceptTailingToken(TokenVariant.Operator, Operator.Col) then
			if not self:AcceptTailingToken(TokenVariant.LowerIdent) then
				if self:AcceptRoamingToken(TokenVariant.LowerIdent) then
					self:Error("Method operator (:) must not be preceded by whitespace")
				else
					self:Error("Method operator (:) must be followed by method name")
				end
			end

			local trace = self:GetTokenTrace()
			local fun = self:GetTokenData()

			if not self:AcceptTailingToken(TokenVariant.Grammar, Grammar.LParen) then
				if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
					self:Error("Left parenthesis (() must not be preceded by whitespace")
				else
					self:Error("Left parenthesis (() must appear after method name")
				end
			end

			local token = self:GetToken()

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
				expr = self:Instruction(trace, "methodcall", fun, expr, {})
			else
				local exprs = { self:Expr1() }

				while self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) do
					exprs[#exprs + 1] = self:Expr1()
				end

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
					self:Error("Right parenthesis ()) missing, to close method argument list", token)
				end

				expr = self:Instruction(trace, "methodcall", fun, expr, exprs)
			end
			--elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
			--	self:Error("Method operator (:) must not be preceded by whitespace")
		elseif self:AcceptTailingToken(TokenVariant.Grammar, Grammar.LSquare) then
			local trace = self:GetTokenTrace()

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
				self:Error("Indexing operator ([]) requires an index [X]")
			end

			local aexpr = self:Expr1()
			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
				if not self:AcceptRoamingToken(TokenVariant.LowerIdent) then
					self:Error("Indexing operator ([]) requires a lower case type [X,t]")
				end

				local longtp = self:GetTokenData()

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
					self:Error("Right square bracket (]) missing, to close indexing operator [X,t]")
				end

				if longtp == "number" then longtp = "normal" end
				if wire_expression_types[string.upper(longtp)] == nil then
					self:Error("Indexing operator ([]) does not support the type [" .. longtp .. "]")
				end

				local tp = wire_expression_types[string.upper(longtp)][1]
				expr = self:Instruction(trace, "get", expr, aexpr, tp)
			elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
				expr = self:Instruction(trace, "get", expr, aexpr)
			else
				self:Error("Indexing operator ([]) needs to be closed with comma (,) or right square bracket (])")
			end
		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LSquare) then
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		elseif self:AcceptTailingToken(TokenVariant.Grammar, Grammar.LParen) then
			local trace = self:GetTokenTrace()

			local token = self:GetToken()
			local exprs

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
				exprs = {}
			else
				exprs = { self:Expr1() }

				while self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) do
					exprs[#exprs + 1] = self:Expr1()
				end

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
					self:Error("Right parenthesis ()) missing, to close function argument list", token)
				end
			end

			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LSquare) then
				if not self:AcceptRoamingToken(TokenVariant.LowerIdent) then
					self:Error("Return type operator ([]) requires a lower case type [type]")
				end

				local longtp = self:GetTokenData()

				if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
					self:Error("Right square bracket (]) missing, to close return type operator [type]")
				end

				if longtp == "number" then longtp = "normal" end
				if wire_expression_types[string.upper(longtp)] == nil then
					self:Error("Return type operator ([]) does not support the type [" .. longtp .. "]")
				end

				local stype = wire_expression_types[string.upper(longtp)][1]

				expr = self:Instruction(trace, "stringcall", expr, exprs, stype)
			else
				expr = self:Instruction(trace, "stringcall", expr, exprs, "")
			end
		else
			break
		end
	end

	return expr
end

function Parser:Expr16()
	if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
		local token = self:GetToken()

		local expr = self:Expr1()

		if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
			self:Error("Right parenthesis ()) missing, to close grouped equation", token)
		end

		return expr
	end

	if self:AcceptRoamingToken(TokenVariant.LowerIdent) then
		local trace = self:GetTokenTrace()
		local fun = self:GetTokenData()

		if not self:AcceptTailingToken(TokenVariant.Grammar, Grammar.LParen) then
			if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LParen) then
				self:Error("Left parenthesis (() must not be preceded by whitespace")
			else
				self:Error("Left parenthesis (() must appear after function name, variables must start with uppercase letter,")
			end
		end

		local token = self:GetToken()

		if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
			return self:Instruction(trace, "call", fun, {})
		else

			local exprs = {}

			-- Special case for "table( str=val, str=val, str=val, ... )" (or array)
			if fun == "table" or fun == "array" then
				local kvtable = false

				local key = self:Expr1()

				if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Ass) then
					if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
						self:Error("Expression expected, got right paranthesis ())", self:GetToken())
					end

					exprs[key] = self:Expr1()

					kvtable = true
				else -- If it isn't a "table( str=val, ...)", then it's a "table( val,val,val,... )"
					exprs = { key }
				end

				if kvtable then
					while self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) do
						local key = self:Expr1()
						local token = self:GetToken()

						if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Ass) then
							if self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
								self:Error("Expression expected, got right paranthesis ())", self:GetToken())
							end

							exprs[key] = self:Expr1()
						else
							self:Error("Assignment operator (=) missing, to complete expression", token)
						end
					end

					if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
						self:Error("Right parenthesis ()) missing, to close function argument list", self:GetToken())
					end

					return self:Instruction(trace, "kv" .. fun, exprs)
				end
			else
				exprs = { self:Expr1() }
			end

			while self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) do
				exprs[#exprs + 1] = self:Expr1()
			end

			if not self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
				self:Error("Right parenthesis ()) missing, to close function argument list", token)
			end

			return self:Instruction(trace, "call", fun, exprs)
		end
	end

	return self:Expr17()
end

function Parser:Expr17()
	-- Basic lua supported numeric literals (decimal, hex, binary)
	if self:AcceptRoamingToken(TokenVariant.Decimal) or self:AcceptRoamingToken(TokenVariant.Hexadecimal) or self:AcceptRoamingToken(TokenVariant.Binary) then
		return self:Instruction(self:GetTokenTrace(), "literal", self:GetTokenData(), "n")
	end

	if self:AcceptRoamingToken(TokenVariant.Complex) or self:AcceptRoamingToken(TokenVariant.Quat) then
		local trace = self:GetTokenTrace()
		local tokendata = self:GetTokenData()

		local num, suffix = tokendata:match("^([-+e0-9.]*)(.*)$")
		num = assert(tonumber(num), "unparseable numeric literal")
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
			error("unrecognized numeric suffix " .. suffix)
		end
		return self:Instruction(trace, "literal", value, type)
	end

	if self:AcceptRoamingToken(TokenVariant.String) then
		local trace = self:GetTokenTrace()
		local str = self:GetTokenData()

		return self:Instruction(trace, "literal", str, "s")
	end

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Trg) then
		local trace = self:GetTokenTrace()

		if not self:AcceptTailingToken(TokenVariant.Ident) then
			if self:AcceptRoamingToken(TokenVariant.Ident) then
				self:Error("Triggered operator (~) must not be succeeded by whitespace")
			else
				self:Error("Triggered operator (~) must be preceded by variable")
			end
		end

		local var = self:GetTokenData()
		return self:Instruction(trace, "trg", var)
	end

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Dlt) then
		local trace = self:GetTokenTrace()

		if not self:AcceptTailingToken(TokenVariant.Ident) then
			if self:AcceptRoamingToken(TokenVariant.Ident) then
				self:Error("Delta operator ($) must not be succeeded by whitespace")
			else
				self:Error("Delta operator ($) must be preceded by variable")
			end
		end

		local var = self:GetTokenData()
		self.delta[var] = true

		return self:Instruction(trace, "dlt", var)
	end

	if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Imp) then
		local trace = self:GetTokenTrace()

		if not self:AcceptTailingToken(TokenVariant.Ident) then
			if self:AcceptRoamingToken(TokenVariant.Ident) then
				self:Error("Connected operator (->) must not be succeeded by whitespace")
			else
				self:Error("Connected operator (->) must be preceded by variable")
			end
		end

		local var = self:GetTokenData()

		return self:Instruction(trace, "iwc", var)
	end

	return self:Expr18()
end

function Parser:Expr18()
	if self:AcceptRoamingToken(TokenVariant.Ident) then
		if self:AcceptTailingToken(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be part of equation")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:AcceptTailingToken(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be part of equation")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		self:TrackBack()
	end

	return self:Expr19()
end

function Parser:Expr19()
	if self:AcceptRoamingToken(TokenVariant.Ident) then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		return self:Instruction(trace, "var", var)
	end

	return self:ExprError()
end

function Parser:ExprError()
	if self:HasTokens() then
		if self:AcceptRoamingToken(TokenVariant.Operator, Operator.Add) then
			self:Error("Addition operator (+) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Sub) then -- can't occur (unary minus)
			self:Error("Subtraction operator (-) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Mul) then
			self:Error("Multiplication operator (*) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Div) then
			self:Error("Division operator (/) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Mod) then
			self:Error("Modulo operator (%) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Exp) then
			self:Error("Exponentiation operator (^) must be preceded by equation or value")

		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Ass) then
			self:Error("Assignment operator (=) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Aadd) then
			self:Error("Additive assignment operator (+=) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Asub) then
			self:Error("Subtractive assignment operator (-=) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Amul) then
			self:Error("Multiplicative assignment operator (*=) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Adiv) then
			self:Error("Divisive assignment operator (/=) must be preceded by variable")

		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.And) then
			self:Error("Logical and operator (&) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Or) then
			self:Error("Logical or operator (|) must be preceded by equation or value")

		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Eq) then
			self:Error("Equality operator (==) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Neq) then
			self:Error("Inequality operator (!=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Gth) then
			self:Error("Greater than or equal to operator (>=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Lth) then
			self:Error("Less than or equal to operator (<=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Geq) then
			self:Error("Greater than operator (>) must be preceded by equation or value")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Leq) then
			self:Error("Less than operator (<) must be preceded by equation or value")

		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Inc) then
			self:Error("Increment operator (++) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Dec) then
			self:Error("Decrement operator (--) must be preceded by variable")

		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RParen) then
			self:Error("Right parenthesis ()) without matching left parenthesis")
		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LCurly) then
			self:Error("Left curly bracket ({) must be part of an if/while/for-statement block")
		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RCurly) then
			self:Error("Right curly bracket (}) without matching left curly bracket")
		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.LSquare) then
			self:Error("Left square bracket ([) must be preceded by variable")
		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.RSquare) then
			self:Error("Right square bracket (]) without matching left square bracket")

		elseif self:AcceptRoamingToken(TokenVariant.Grammar, Grammar.Comma) then
			self:Error("Comma (,) not expected here, missing an argument?")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Col) then
			self:Error("Method operator (:) must not be preceded by whitespace")
		elseif self:AcceptRoamingToken(TokenVariant.Operator, Operator.Spread) then
			self:Error("Spread operator (...) must only be used as a function parameter")

		elseif self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.If) then
			self:Error("If keyword (if) must not appear inside an equation")
		elseif self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Elseif) then
			self:Error("Else-if keyword (elseif) must be part of an if-statement")
		elseif self:AcceptRoamingToken(TokenVariant.Keyword, Keyword.Else) then
			self:Error("Else keyword (else) must be part of an if-statement")

		else
			self:Error("Unexpected token found (" .. self.readtoken:display() .. ")")
		end
	else
		self:Error("Further input required at end of code, incomplete expression", self.exprtoken)
	end
end

]======]
