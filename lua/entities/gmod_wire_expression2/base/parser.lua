/******************************************************************************\
  Expression 2 Parser for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

AddCSLuaFile("parser.lua")

/*

Root
 1 : q1

seQuencing
 1 : ""
 2 : "s1 q1", "s1, q2"

Statement
 1 : if (e1) { q1 } i1
 2 : while (e1) { q1 }
 3 : for (var = e1, e1[, e1]) { q1 }
 4 : foreach(var, var:type = e1) { q1}
 5 : break, continue
 6 : var++, var--
 7 : var += e1, var -= e1, var *= e1, var /= e1
 8 : var = s8, var[e1,type] = s8
 9 : e1

If
 1 : elseif (e1) { q1 } i1
 2 : else { q1 }

Expression
 1 : var = e1, var += e1, var -= e1, var *= e1, var /= e1 [ERROR]
 2 : e3 ? e1 : e1, e3 ?: e1
 3 : e1 | e2			-- (or)
 4 : e1 & e2			-- (and)
 5 : e1 || e2 			-- (bit or)
 6 : e1 && e1			-- (bit and)
 7 : e1 ^^ e2			-- (bit xor)
 6 : e5 == e6, e5 != e6
 7 : e6 < e7, e6 > e7, e6 <= e7, e6 >= e7
 8 : e1 << e2, e1 >> e2 -- (bit shift)
 9 : e7 + e8, e7 - e8
10 : e8 * e9, e8 / e9, e8 % e9
11 : e9 ^ e10
12 : +e11, -e11, !e10
13 : e11:fun([e1, ...]), e11[var,type]
14 : (e1), fun([e1, ...])
15 : string, num, ~var, $var, ->var
16 : var++, var-- [ERROR]
17 : var

*/
/******************************************************************************/

Parser = {}
Parser.__index = Parser

function Parser.Execute(...)
	-- instantiate Parser
	local instance = setmetatable({}, Parser)

	-- and pcall the new instance's Process method.
	return pcall(Parser.Process, instance, ...)
end

function Parser:Error(message, token)
	if token then
		error(message .. " at line " .. token[4] .. ", char " .. token[5], 0)
	else
		error(message .. " at line " .. self.token[4] .. ", char " .. self.token[5], 0)
	end
end

function Parser:Process(tokens, params)
	self.tokens = tokens

	self.index = 0
	self.count = #tokens
	self.delta = {}

	self:NextToken()
	local tree = self:Root()

	return tree, self.delta
end

/******************************************************************************/

function Parser:GetToken()
	return self.token
end

function Parser:GetTokenData()
	return self.token[2]
end

function Parser:GetTokenTrace()
	return {self.token[4], self.token[5]}
end


function Parser:Instruction(trace, name, ...)
	return {name, trace, ...} //
end


function Parser:HasTokens()
	return self.readtoken != nil
end

function Parser:NextToken()
	if self.index <= self.count then
		if self.index > 0 then
			self.token = self.readtoken
		else
			self.token = {"", "", false, 1, 1}
		end

		self.index = self.index + 1
		self.readtoken = self.tokens[self.index]
	else
		self.readtoken = nil
	end
end

function Parser:TrackBack()
	self.index = self.index - 2
	self:NextToken()
end


function Parser:AcceptRoamingToken(name)
	local token = self.readtoken
	if !token or token[1] != name then return false end

	self:NextToken()
	return true
end

function Parser:AcceptTailingToken(name)
	local token = self.readtoken
	if !token or token[3] then return false end

	return self:AcceptRoamingToken(name)
end

function Parser:AcceptLeadingToken(name)
	local token = self.tokens[self.index + 1]
	if !token or token[3] then return false end

	return self:AcceptRoamingToken(name)
end


function Parser:RecurseLeft(func, tbl)
	local expr = func(self)
	local hit = true

	while hit do
		hit = false
		for i=1,#tbl do
			if self:AcceptRoamingToken(tbl[i]) then
				local trace = self:GetTokenTrace()

				hit = true
				expr = self:Instruction(trace, tbl[i], expr, func(self))
				break
			end
		end
	end

	return expr
end

/******************************************************************************/

local loopdepth

function Parser:Root()
	loopdepth = 0
	return self:Stmts()
end


function Parser:Stmts()
	local trace = self:GetTokenTrace()
	local stmts = self:Instruction(trace, "seq")

	if !self:HasTokens() then return stmts end

	while true do
		if self:AcceptRoamingToken("com") then
			self:Error("Statement separator (,) must not appear multiple times")
		end

		stmts[#stmts + 1] = self:Stmt1()

		if !self:HasTokens() then break end

		if !self:AcceptRoamingToken("com") then
			if self.readtoken[3] == false then
				self:Error("Statements must be separated by comma (,) or whitespace")
			end
		end
	end

	return stmts
end


function Parser:Stmt1()
	if self:AcceptRoamingToken("if") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "if", self:Cond(), self:Block("if condition"), self:IfElseIf())
	end

	return self:Stmt2()
end

function Parser:Stmt2()
	if self:AcceptRoamingToken("whl") then
		local trace = self:GetTokenTrace()
		loopdepth = loopdepth + 1
		local whl = self:Instruction(trace, "whl", self:Cond(), self:Block("while condition"))
		loopdepth = loopdepth - 1
		return whl
	end

	return self:Stmt3()
end

function Parser:Stmt3()
	if self:AcceptRoamingToken("for") then
		local trace = self:GetTokenTrace()
		loopdepth = loopdepth + 1

		if !self:AcceptRoamingToken("lpa") then
			self:Error("Left parenthesis (() must appear before condition")
		end

		if !self:AcceptRoamingToken("var") then
			self:Error("Variable expected for the numeric index")
		end

		local var = self:GetTokenData()

		if !self:AcceptRoamingToken("ass") then
			self:Error("Assignment operator (=) expected to preceed variable")
		end

		local estart = self:Expr1()

		if !self:AcceptRoamingToken("com") then
			self:Error("Comma (,) expected after start value")
		end

		local estop = self:Expr1()

		local estep
		if self:AcceptRoamingToken("com") then
			estep = self:Expr1()
		end

		if !self:AcceptRoamingToken("rpa") then
			self:Error("Right parenthesis ()) missing, to close condition")
		end

		local sfor = self:Instruction(trace, "for", var, estart, estop, estep, self:Block("for statement"))

		loopdepth = loopdepth - 1
		return sfor
	end

	return self:Stmt4()
end

function Parser:Stmt4()
	if self:AcceptRoamingToken("fea") then
		local trace = self:GetTokenTrace()
		loopdepth = loopdepth + 1

		if not self:AcceptRoamingToken("lpa") then
			self:Error("Left parenthesis missing (() after foreach statement")
		end

		if not self:AcceptRoamingToken("var") then
			self:Error("Variable expected to hold the key")
		end
		local keyvar = self:GetTokenData()

		if not self:AcceptRoamingToken("com") then
			self:Error("Comma (,) expected after key variable")
		end

		if not self:AcceptRoamingToken("var") then
			self:Error("Variable expected to hold the value")
		end
		local valvar = self:GetTokenData()

		if not self:AcceptRoamingToken("col") then
			self:Error("Colon (:) expected to separate type from variable")
		end

		if not self:AcceptRoamingToken("fun") and not self:AcceptRoamingToken("udf") then
			self:Error("Type expected after colon")
		end
		local valtype = self:GetTokenData()
		if valtype == "number" then valtype = "normal" end
		if wire_expression_types[string.upper(valtype)] == nil then
			self:Error("Unknown type: "..valtype)
		end
		valtype = wire_expression_types[string.upper(valtype)][1]

		if not self:AcceptRoamingToken("ass") then
			self:Error("Equals sign (=) expected after value type to specify table")
		end

		local tableexpr = self:Expr1()

		if not self:AcceptRoamingToken("rpa") then
			self:Error("Missing right parenthesis after foreach statement")
		end

		local sfea = self:Instruction(trace, "fea", keyvar, valvar, valtype, tableexpr, self:Block("foreach statement"))
		loopdepth = loopdepth -1
		return sfea
	end

	return self:Stmt5()
end

function Parser:Stmt5()
	if self:AcceptRoamingToken("brk") then
		if loopdepth > 0 then
			local trace = self:GetTokenTrace()
			return self:Instruction(trace, "brk")
		else
			self:Error("Break may not exist outside of a loop")
		end
	elseif self:AcceptRoamingToken("cnt") then
		if loopdepth > 0 then
			local trace = self:GetTokenTrace()
			return self:Instruction(trace, "cnt")
		else
			self:Error("Continue may not exist outside of a loop")
		end
	end

	return self:Stmt6()
end

function Parser:Stmt6()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()

		if self:AcceptTailingToken("inc") then
			return self:Instruction(trace, "inc", var)
		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:AcceptTailingToken("dec") then
			return self:Instruction(trace, "dec", var)
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		self:TrackBack()
	end

	return self:Stmt7()
end

function Parser:Stmt7()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()

		if self:AcceptRoamingToken("aadd") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "add", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("asub") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "sub", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("amul") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "mul", self:Instruction(trace, "var", var), self:Expr1()))
		elseif self:AcceptRoamingToken("adiv") then
			return self:Instruction(trace, "ass", var, self:Instruction(trace, "div", self:Instruction(trace, "var", var), self:Expr1()))
		end

		self:TrackBack()
	end

	return self:Stmt8()
end

function Parser:Stmt8()
	if self:AcceptRoamingToken("var") then
		local tbpos = self.index
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()

		if self:AcceptTailingToken("lsb") then
			if self:AcceptRoamingToken("rsb") then
				self:Error("Indexing operator ([]) requires an index [X]")
			end

			local expr = self:Expr1()
			if self:AcceptRoamingToken("com") then
				if !self:AcceptRoamingToken("fun") then
					self:Error("Indexing operator ([]) requires a lower case type [X,t]")
				end

				local longtp = self:GetTokenData()

				if !self:AcceptRoamingToken("rsb") then
					self:Error("Right square bracket (]) missing, to close indexing operator [X,t]")
				end

				if self:AcceptRoamingToken("ass") then
					if longtp == "number" then longtp = "normal" end
					if wire_expression_types[string.upper(longtp)] == nil then
						self:Error("Indexing operator ([]) does not support the type [" .. longtp .. "]")
					end

					local tp = wire_expression_types[string.upper(longtp)][1]
					return self:Instruction(trace, "set", var, expr, self:Stmt8(), tp)
				end
			elseif self:AcceptRoamingToken("rsb") then
				if self:AcceptRoamingToken("ass") then
					return self:Instruction(trace, "set", var, expr, self:Stmt8())
				end
			else
				self:Error("Indexing operator ([]) needs to be closed with comma (,) or right square bracket (])")
			end
		elseif self:AcceptRoamingToken("lsb") then
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		elseif self:AcceptRoamingToken("ass") then
			return self:Instruction(trace, "ass", var, self:Stmt8())
		end

		self.index = tbpos - 2
		self:NextToken()
	end

	return self:Stmt9()
end

function Parser:Stmt9()

	//--Function Statment
	if ( self:AcceptRoamingToken("func") ) then

		local Trace = self:GetTokenTrace()


		if self.in_func then self:Error("Functions can not be created from inside other functions") end


		local Name,Return,Type
		local NameToken,ReturnToken,TypeToken
		local Args,Temp,Arg = {},{},1


		-- Errors are handeled after line 49, both 'fun' and 'var' tokens are used for accurate error reports.
		if self:AcceptRoamingToken("fun") or self:AcceptRoamingToken("var") or self:AcceptRoamingToken("void") then --get the name
			Name = self:GetTokenData()
			NameToken = self.token -- Copy the current token for error reporting

			-- We check if the previous token was actualy the return not the name
			if self:AcceptRoamingToken("fun") or self:AcceptRoamingToken("var") or self:AcceptRoamingToken("void") then
				Return = Name
				ReturnToken = NameToken

				Name = self:GetTokenData()
				NameToken = self.token
			end

			-- We check if the name token is actualy the type
			if self:AcceptRoamingToken("col") then
				if self:AcceptRoamingToken("fun") or self:AcceptRoamingToken("var") then
					Type = Name
					TypeToken = NameToken

					Name = self:GetTokenData()
					NameToken = self.token
				else
					self:Error("Function name must appear after colon (:)")
				end
			end
		end


		if Return and Return != "void" then -- Check the retun value

			if Return != Return:lower() then
				self:Error("Function return type must be lowercased",ReturnToken)
			end

			if Return == "number" then Return = "normal" end

			Return = Return:upper()

			if !wire_expression_types[Return] then
				self:Error("Invalid return argument '" .. E2Lib.limitString(Return:lower(), 10) .. "'",ReturnToken)
			end

			Return = wire_expression_types[Return][1]

		else
			Return = ""
		end


		local Sig = (Name or "") .. "("


		if Type then -- check the Type

			if Type != Type:lower() then self:Error("Function object type must be full lowercase",TypeToken) end

			if Type == "number" then Type = "normal" end

			if Type == "normal" then self:Error("Number can not be used as function object type",TypeToken) end

			if Type == "void" then self:Error("Void can not be used as function object type",TypeToken) end

			Type = Type:upper()

			if !wire_expression_types[Type] then
				self:Error("Invalid data type '" .. E2Lib.limitString(Type:lower(), 10) .. "'",TypeToken)
			end

			Temp["This"] = true

			Args[1] = {"This",Type}

			Arg = 2

			Type = wire_expression_types[Type][1]

			Sig = Sig .. Type .. ":"
		else
			Type = ""
		end


		if !Name then self:Error("Function name must follow function declaration") end

		if Name[1] != Name[1]:lower() then self:Error("Function name must start with a lower case letter",NameToken) end


		if !self:AcceptRoamingToken("lpa") then
			self:Error("Left parenthesis (() must appear affter function name")
		end

		if self:HasTokens() and !self:AcceptRoamingToken("rpa") then
			while true do

				if self:AcceptRoamingToken("com") then self:Error("Argument separator (,) must not appear multiple times") end

				local Type,Name = "normal"

				if self:AcceptRoamingToken("var") or self:AcceptRoamingToken("fun") then
					Name = self:GetTokenData()
				end

				if !Name then self:Error("Function argument #" .. Arg .. " varible required") end

				if Name[1] != Name[1]:upper() then self:Error("Function argument #" .. Arg .. " varible must start with uppercased letter") end

				if self:AcceptRoamingToken("col") then
					if self:AcceptRoamingToken("fun") or self:AcceptRoamingToken("var") then
						Type = self:GetTokenData()
					else
						self:Error("Function argument #" .. Arg .. " type must appear after (:)")
					end
				end

				if Type != Type:lower() then self:Error("Function argument #" .. Arg .. " type must be lowercased") end

				if Type == "number" then Type = "normal" end

				Type = Type:upper()

				if !wire_expression_types[Type] then
					self:Error("Function argument #" .. Arg .. " type is invalid")
				end


				Temp[Name] = true
				Args[Arg] = {Name,Type}
				Arg = Arg + 1

				Sig = Sig .. wire_expression_types[Type][1]

				if !self:HasTokens() then self:Error("Right parenthesis ()) must appear after function arguments")

				elseif self:AcceptRoamingToken("rpa") then break

				elseif !self:AcceptRoamingToken("com") then self:Error("Function arguments must be separated by comma (,)") end

			end
		end


		Sig = Sig .. ")"

		if wire_expression2_funcs[Sig] then self:Error("Function '" .. Sig .. "' already exists") end

		self.in_func = true

		local Inst = self:Instruction(Trace, "function", Sig, Return, Type, Args, self:Block("function decleration"))

		self.in_func = false

		return Inst


	//--GetFunction Statment
	elseif self:AcceptRoamingToken("getfunc") then

		local Trace = self:GetTokenTrace()

		if !self:AcceptRoamingToken("rpa") then
			self:Error("Left parenthesis (() must appear affter function")
		end

		local Name = self:Expr1()

		if !Name then
			self:Error("Argument 1 of getFunction must be a function name as string")
		end

		local Arg,Perams = 1,""

		if self:HasTokens() and !self:AcceptRoamingToken("rpa") then
			while true do

				if self:AcceptRoamingToken("com") then self:Error("Argument separator (,) must not appear multiple times") end

				local Type = "normal"

				if self:AcceptRoamingToken("fun") or self:AcceptRoamingToken("var") then
					Type = self:GetTokenData()
				else
					self:Error("getFunction argument #" .. (Arg + 1) .. " type exspected")
				end

				if Type != Type:lower() then self:Error("getFunction argument #" .. (Arg + 1) .. " type must be lowercased") end

				if Type == "number" then Type = "normal" end


				Type = Type:upper()

				if !wire_expression_types[Type] and Type != "VOID" then
					self:Error("Function argument #" .. (Arg + 1) .. " type is invalid")
				end


				if self:AcceptRoamingToken("col") and Arg == 1 then
					if  Type != "VOID" then
						Perams = Perams .. wire_expression_types[Type][1] .. ":"
					else
						Perams = Perams .. wire_expression_types[Type][1]
					end

				elseif Type == "VOID" then
					self:Error("Function argument #" .. (Arg + 1) .. " type is invalid")
				else
					Perams = Perams .. wire_expression_types[Type][1]
				end

				Arg = Arg + 1

				if !self:HasTokens() then self:Error("Right parenthesis ()) must appear after function arguments")

				elseif self:AcceptRoamingToken("rpa") then break

				elseif !self:AcceptRoamingToken("com") then self:Error("getFunction arguments must be separated by comma (,)") end

			end
		end

		return self:Instruction(Trace, "getfunction", Name,Perams)


	//--Return Statment
	elseif self:AcceptRoamingToken("ret") then

		local Trace = self:GetTokenTrace()

		if self.in_func then

			local Ret

			if !self:AcceptRoamingToken("void")then
				Ret = self:Expr1()
			end

			return self:Instruction(Trace, "return", Ret)

		else
			self:Error("Return may not exist outside of a function")
		end


	//--Void Missplacement
	elseif self:AcceptRoamingToken("void") then

		self:Error("Void may only exist after return")

	end

	return self:Expr1()
end


function Parser:IfElseIf()
	if self:AcceptRoamingToken("eif") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "if", self:Cond(), self:Block("elseif condition"), self:IfElseIf())
	end

	return self:IfElse()
end

function Parser:IfElse()
	if self:AcceptRoamingToken("els") then
		return self:Block("else")
	end

	local trace = self:GetTokenTrace()
	return self:Instruction(trace, "seq")
end

function Parser:Cond()
	if !self:AcceptRoamingToken("lpa") then
		self:Error("Left parenthesis (() must appear before condition")
	end

	local expr = self:Expr1()

	if !self:AcceptRoamingToken("rpa") then
		self:Error("Right parenthesis ()) missing, to close condition")
	end

	return expr
end


function Parser:Block(block_type)
	local trace = self:GetTokenTrace()
	local stmts = self:Instruction(trace, "seq")

	if !self:AcceptRoamingToken("lcb") then
		self:Error("Left curly bracket ({) must appear after "..(block_type or "condition"))
	end

	local token = self:GetToken()

	if self:AcceptRoamingToken("rcb") then
		return stmts
	end

	if self:HasTokens() then
		while true do
			if self:AcceptRoamingToken("com") then
				self:Error("Statement separator (,) must not appear multiple times")
			elseif self:AcceptRoamingToken("rcb") then
				self:Error("Statement separator (,) must be suceeded by statement")
			end

			stmts[#stmts + 1] = self:Stmt1()

			if self:AcceptRoamingToken("rcb") then
				return stmts
			end

			if !self:AcceptRoamingToken("com") then
				if !self:HasTokens() then break end

				if self.readtoken[3] == false then
					self:Error("Statements must be separated by comma (,) or whitespace")
				end
			end
		end
	end

	self:Error("Right curly bracket (}) missing, to close statement block", token)
end


function Parser:Expr1()
	self.exprtoken = self:GetToken()

	if self:AcceptRoamingToken("var") then
		if self:AcceptRoamingToken("ass") then
			self:Error("Assignment operator (=) must not be part of equation")
		end

		if self:AcceptRoamingToken("aadd") then
			self:Error("Additive assignment operator (+=) must not be part of equation")
		elseif self:AcceptRoamingToken("asub") then
			self:Error("Subtractive assignment operator (-=) must not be part of equation")
		elseif self:AcceptRoamingToken("amul") then
			self:Error("Multiplicative assignment operator (*=) must not be part of equation")
		elseif self:AcceptRoamingToken("adiv") then
			self:Error("Divisive assignment operator (/=) must not be part of equation")
		end

		self:TrackBack()
	end

	return self:Expr2()
end

function Parser:Expr2()
	local expr = self:Expr3()

	if self:AcceptRoamingToken("qsm") then
		local trace = self:GetTokenTrace()
		local exprtrue = self:Expr1()

		if !self:AcceptRoamingToken("col") then -- perhaps we want to make sure there is space around this (method bug)
			self:Error("Conditional operator (:) must appear after expression to complete conditional", token)
		end

		return self:Instruction(trace, "cnd", expr, exprtrue, self:Expr1())
	end

	if self:AcceptRoamingToken("def") then
		local trace = self:GetTokenTrace()

		return self:Instruction(trace, "def", expr, self:Expr1())
	end

	return expr
end

function Parser:Expr3()
	return self:RecurseLeft(self.Expr4, {"or"})
end

function Parser:Expr4()
	return self:RecurseLeft(self.Expr5, {"and"})
end

function Parser:Expr5()
	return self:RecurseLeft(self.Expr6, {"bor"})
end

function Parser:Expr6()
	return self:RecurseLeft(self.Expr7, {"band"})
end

function Parser:Expr7()
	return self:RecurseLeft(self.Expr8, {"bxor"})
end

function Parser:Expr8()
	return self:RecurseLeft(self.Expr9, {"eq", "neq"})
end

function Parser:Expr9()
	return self:RecurseLeft(self.Expr10, {"gth", "lth", "geq", "leq"})
end

function Parser:Expr10()
	return self:RecurseLeft(self.Expr11, {"bshr", "bshl"})
end

function Parser:Expr11()
	return self:RecurseLeft(self.Expr12, {"add", "sub"})
end

function Parser:Expr12()
	return self:RecurseLeft(self.Expr13, {"mul", "div", "mod"})
end

function Parser:Expr13()
	return self:RecurseLeft(self.Expr14, {"exp"})
end

function Parser:Expr14()
	if self:AcceptLeadingToken("add") then
		return self:Expr15()
	elseif self:AcceptRoamingToken("add") then
		self:Error("Identity operator (+) must not be succeeded by whitespace")
	end

	if self:AcceptLeadingToken("sub") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "neg", self:Expr15())
	elseif self:AcceptRoamingToken("sub") then
		self:Error("Negation operator (-) must not be succeeded by whitespace")
	end

	if self:AcceptLeadingToken("not") then
		local trace = self:GetTokenTrace()
		return self:Instruction(trace, "not", self:Expr14())
	elseif self:AcceptRoamingToken("not") then
		self:Error("Logical not operator (!) must not be succeeded by whitespace")
	end

	return self:Expr15()
end

function Parser:Expr15()
	local expr = self:Expr16()

	while true do
		if self:AcceptTailingToken("col") then
			if !self:AcceptTailingToken("fun") then
				if self:AcceptRoamingToken("fun") then
					self:Error("Method operator (:) must not be preceded by whitespace")
				else
					self:Error("Method operator (:) must be followed by method name")
				end
			end

			local trace = self:GetTokenTrace()
			local fun = self:GetTokenData()

			if !self:AcceptTailingToken("lpa") then
				if self:AcceptRoamingToken("lpa") then
					self:Error("Left parenthesis (() must not be preceded by whitespace")
				else
					self:Error("Left parenthesis (() must appear after method name")
				end
			end

			local token = self:GetToken()

			if self:AcceptRoamingToken("rpa") then
				expr = self:Instruction(trace, "mto", fun, expr, {})
			else
				local exprs = {self:Expr1()}

				while self:AcceptRoamingToken("com") do
					exprs[#exprs + 1] = self:Expr1()
				end

				if !self:AcceptRoamingToken("rpa") then
					self:Error("Right parenthesis ()) missing, to close method argument list", token)
				end

				expr = self:Instruction(trace, "mto", fun, expr, exprs)
			end
		--elseif self:AcceptRoamingToken("col") then
		--	self:Error("Method operator (:) must not be preceded by whitespace")
		elseif self:AcceptTailingToken("lsb") then
			local trace = self:GetTokenTrace()

			if self:AcceptRoamingToken("rsb") then
				self:Error("Indexing operator ([]) requires an index [X]")
			end

			local aexpr = self:Expr1()
			if self:AcceptRoamingToken("com") then
				if !self:AcceptRoamingToken("fun") then
					self:Error("Indexing operator ([]) requires a lower case type [X,t]")
				end

				local longtp = self:GetTokenData()

				if !self:AcceptRoamingToken("rsb") then
					self:Error("Right square bracket (]) missing, to close indexing operator [X,t]")
				end

				if longtp == "number" then longtp = "normal" end
				if wire_expression_types[string.upper(longtp)] == nil then
					self:Error("Indexing operator ([]) does not support the type [" .. longtp .. "]")
				end

				local tp = wire_expression_types[string.upper(longtp)][1]
				expr = self:Instruction(trace, "get", expr, aexpr, tp)
			elseif self:AcceptRoamingToken("rsb") then
				expr = self:Instruction(trace, "get", expr, aexpr)
			else
				self:Error("Indexing operator ([]) needs to be closed with comma (,) or right square bracket (])")
			end
		elseif self:AcceptRoamingToken("lsb") then
			self:Error("Indexing operator ([]) must not be preceded by whitespace")
		else
			break
		end
	end

	return expr
end

function Parser:Expr16()
	if self:AcceptRoamingToken("lpa") then
		local token = self:GetToken()

		local expr = self:Expr1()

		if !self:AcceptRoamingToken("rpa") then
			self:Error("Right parenthesis ()) missing, to close grouped equation", token)
		end

		return expr
	end

	if self:AcceptRoamingToken("fun") then
		local trace = self:GetTokenTrace()
		local fun = self:GetTokenData()

		if !self:AcceptTailingToken("lpa") then
			if self:AcceptRoamingToken("lpa") then
				self:Error("Left parenthesis (() must not be preceded by whitespace")
			else
				self:Error("Left parenthesis (() must appear after function name, variables must start with uppercase letter,")
			end
		end

		local token = self:GetToken()

		if self:AcceptRoamingToken("rpa") then
			return self:Instruction(trace, "fun", fun, {})
		else
			local exprs = {self:Expr1()}
			while self:AcceptRoamingToken("com") do
				exprs[#exprs + 1] = self:Expr1()
			end

			if !self:AcceptRoamingToken("rpa") then
				self:Error("Right parenthesis ()) missing, to close function argument list", token)
			end

			return self:Instruction(trace, "fun", fun, exprs)
		end
	end

	return self:Expr17()
end

function Parser:Expr17()
	if self:AcceptRoamingToken("num") then
		local trace = self:GetTokenTrace()
		local tokendata = self:GetTokenData()
		if type(tokendata) == "number" then
			return self:Instruction(trace, "num", tokendata)
		end
		local num,tp = tokendata:match("^([-+e0-9.]*)(.*)$")
		return self:Instruction(trace, "num"..tp, num)
	end

	if self:AcceptRoamingToken("str") then
		local trace = self:GetTokenTrace()
		local str = self:GetTokenData()
		return self:Instruction(trace, "str", str)
	end

	if self:AcceptRoamingToken("trg") then
		local trace = self:GetTokenTrace()

		if !self:AcceptTailingToken("var") then
			if self:AcceptRoamingToken("var") then
				self:Error("Triggered operator (~) must not be succeeded by whitespace")
			else
				self:Error("Triggered operator (~) must be preceded by variable")
			end
		end

		local var = self:GetTokenData()
		return self:Instruction(trace, "trg", var)
	end

	if self:AcceptRoamingToken("dlt") then
		local trace = self:GetTokenTrace()

		if !self:AcceptTailingToken("var") then
			if self:AcceptRoamingToken("var") then
				self:Error("Delta operator ($) must not be succeeded by whitespace")
			else
				self:Error("Delta operator ($) must be preceded by variable")
			end
		end

		local var = self:GetTokenData()
		self.delta[var] = true

		return self:Instruction(trace, "dlt", var)
	end

	if self:AcceptRoamingToken("imp") then
		local trace = self:GetTokenTrace()

		if !self:AcceptTailingToken("var") then
			if self:AcceptRoamingToken("var") then
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
	if self:AcceptRoamingToken("var") then
		if self:AcceptTailingToken("inc") then
			self:Error("Increment operator (++) must not be part of equation")
		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must not be preceded by whitespace")
		end

		if self:AcceptTailingToken("dec") then
			self:Error("Decrement operator (--) must not be part of equation")
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must not be preceded by whitespace")
		end

		self:TrackBack()
	end

	return self:Expr19()
end

function Parser:Expr19()
	if self:AcceptRoamingToken("var") then
		local trace = self:GetTokenTrace()
		local var = self:GetTokenData()
		return self:Instruction(trace, "var", var)
	end

	return self:ExprError()
end

function Parser:ExprError()
	if self:HasTokens() then
		if self:AcceptRoamingToken("add") then
			self:Error("Addition operator (+) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("sub") then -- can't occur (unary minus)
			self:Error("Subtraction operator (-) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("mul") then
			self:Error("Multiplication operator (*) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("div") then
			self:Error("Division operator (/) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("mod") then
			self:Error("Modulo operator (%) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("exp") then
			self:Error("Exponentiation operator (^) must be preceded by equation or value")

		elseif self:AcceptRoamingToken("ass") then
			self:Error("Assignment operator (=) must be preceded by variable")
		elseif self:AcceptRoamingToken("aadd") then
			self:Error("Additive assignment operator (+=) must be preceded by variable")
		elseif self:AcceptRoamingToken("asub") then
			self:Error("Subtractive assignment operator (-=) must be preceded by variable")
		elseif self:AcceptRoamingToken("amul") then
			self:Error("Multiplicative assignment operator (*=) must be preceded by variable")
		elseif self:AcceptRoamingToken("adiv") then
			self:Error("Divisive assignment operator (/=) must be preceded by variable")

		elseif self:AcceptRoamingToken("and") then
			self:Error("Logical and operator (&) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("or") then
			self:Error("Logical or operator (|) must be preceded by equation or value")

		elseif self:AcceptRoamingToken("eq") then
			self:Error("Equality operator (==) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("neq") then
			self:Error("Inequality operator (!=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("gth") then
			self:Error("Greater than or equal to operator (>=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("lth") then
			self:Error("Less than or equal to operator (<=) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("geq") then
			self:Error("Greater than operator (>) must be preceded by equation or value")
		elseif self:AcceptRoamingToken("leq") then
			self:Error("Less than operator (<) must be preceded by equation or value")

		elseif self:AcceptRoamingToken("inc") then
			self:Error("Increment operator (++) must be preceded by variable")
		elseif self:AcceptRoamingToken("dec") then
			self:Error("Decrement operator (--) must be preceded by variable")

		elseif self:AcceptRoamingToken("rpa") then
			self:Error("Right parenthesis ()) without matching left parenthesis")
		elseif self:AcceptRoamingToken("lcb") then
			self:Error("Left curly bracket ({) must be part of an if/while/for-statement block")
		elseif self:AcceptRoamingToken("rcb") then
			self:Error("Right curly bracket (}) without matching left curly bracket")
		elseif self:AcceptRoamingToken("lsb") then
			self:Error("Left square bracket ([) must be preceded by variable")
		elseif self:AcceptRoamingToken("rsb") then
			self:Error("Right square bracket (]) without matching left square bracket")

		elseif self:AcceptRoamingToken("com") then
			self:Error("Comma (,) not expected here, missing an argument?")
		elseif self:AcceptRoamingToken("col") then
			self:Error("Method operator (:) must not be preceded by whitespace")

		elseif self:AcceptRoamingToken("if") then
			self:Error("If keyword (if) must not appear inside an equation")
		elseif self:AcceptRoamingToken("eif") then
			self:Error("Else-if keyword (elseif) must be part of an if-statement")
		elseif self:AcceptRoamingToken("els") then
			self:Error("Else keyword (else) must be part of an if-statement")

		else
			self:Error("Unexpected token found (" .. self.readtoken[1] .. ")")
		end
	else
		self:Error("Further input required at end of code, incomplete expression", self.exprtoken)
	end
end
