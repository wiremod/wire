// Written by Syranide, me@syranide.com

AddCSLuaFile("parser.lua")

WireGateExpressionParser = {}

WireGateExpressionParser.toktable = {
	["add"] = "+",
	["sub"] = "-",
	["mul"] = "*",
	["div"] = "/",
	["mod"] = "%",
	["exp"] = "^",

	["aadd"] = "+=",
	["asub"] = "-=",
	["amul"] = "*=",
	["adiv"] = "/=",
	["amod"] = "%=",
	["aexp"] = "^=",

	["imp"] = "->",

	["ass"] = "=",
	["not"] = "!",
	["gth"] = ">",
	["lth"] = "<",
	["eq"] = "==",
	["neq"] = "!=",
	["geq"] = ">=",
	["leq"] = "<=",

	["and"] = "&",
	["or"] = "|",

	["qst"] = "?",
	["col"] = ":",
	["sem"] = ";",
	["com"] = ",",

	["lpa"] = "(",
	["rpa"] = ")",

	["trg"] = "~",
	["dlt"] = "$",
}

WireGateExpressionParser.optable = {
	["+"] = {"add", {["="] = {"aadd"}}},
	["-"] = {"sub", {["="] = {"asub"}, [">"] = {"imp"}}},
	["*"] = {"mul", {["="] = {"amul"}}},
	["/"] = {"div", {["="] = {"adiv"}}},
	["%"] = {"mod", {["="] = {"amod"}}},
	["^"] = {"exp", {["="] = {"aexp"}}},

	["="] = {"ass", {["="] = {"eq"}}},
	["!"] = {"not", {["="] = {"neq"}}},
	[">"] = {"gth", {["="] = {"geq"}}},
	["<"] = {"lth", {["="] = {"leq"}}},

	["&"] = {"and"},
	["|"] = {"or"},

	["?"] = {"qst"},
	[":"] = {"col"},
	[";"] = {"sem"},
	[","] = {"com"},

	["("] = {"lpa"},
	[")"] = {"rpa"},

	["~"] = {"trg"},
	["$"] = {"dlt"},
}

function WireGateExpressionParser:New(code, inputs, outputs)
	local object = {
		symtok = nil,
		symarg = nil,
		locals = {},
		symbols = {},
		symbindex = 1,
		line = 1,
	}

	self.__index = self
	self = setmetatable(object, self)

	self:ParseSymbols(code)

	self:NextSymbol()
	self.instructions = self:expr1()

	self.inputs = self:ParsePorts(inputs)
	self.outputs = self:ParsePorts(outputs)

	if #self.outputs == 0 then
		self.outputs = self.inputs
	end

	if #self.outputs == 0 then
		self:Error('No outputs defined')
	end

	local inputkeys = self.GetIndexTable(self.inputs)
	local outputkeys = self.GetIndexTable(self.outputs)

	local _locals = self.locals self.locals = {}
	for key,_ in pairs(_locals) do
		if not inputkeys[key] and not outputkeys[key] then
			table.insert(self.locals, key)
		end
	end

	return self
end

function WireGateExpressionParser:GetError()
	return self.error
end

function WireGateExpressionParser:GetInstructions()
	if self.error then return nil end
	return self.instructions
end

function WireGateExpressionParser:GetLocals()
	if self.error then return nil end
	return self.locals
end

function WireGateExpressionParser:GetInputs()
	if self.error then return nil end
	return self.inputs
end

function WireGateExpressionParser:GetOutputs()
	if self.error then return nil end
	return self.outputs
end


function WireGateExpressionParser.GetIndexTable(tbl)
	local keys = {}
	for _,key in ipairs(tbl) do keys[key] = true end
	return keys
end

function WireGateExpressionParser:Error(str)
	if not self.error then self.error = str end
end

function WireGateExpressionParser:NextCharacter()
	if self.position <= self.length then
		self.character = string.sub(self.expression, self.position, self.position)
		self.charvalue = string.byte(self.character)
		self.position  = self.position + 1
	else
		self.character = nil
		self.charvalue = nil
	end
end

function WireGateExpressionParser:ReadCharacter()
	self.buffer = self.buffer .. self.character
	self:NextCharacter()
end

function WireGateExpressionParser:ParseSymbols(str)
	--[[
	97 = a, 122 = z
	65 = A, 90 = Z
	--]]

	if str == "" then str = "0" end

	self.expression = str
	self.position = 1
	self.length = string.len(str)
	self.buffer = ""

	self:NextCharacter()

	while true do
		if self.character then
			while self.character == " " or self.character == "\t" or self.character == "\n" or self.character == "\r" do
				if self.character == "\n" then self.line = self.line + 1 end
				self:NextCharacter()
			end

			if not self.character then break end

			self.symarg = ""
			self.buffer = ""

			if self.character >= "0" and self.character <= "9" then
				while self.character and self.character >= "0" and self.character <= "9" do self:ReadCharacter() end
				if self.character and self.character == "." then
					self:ReadCharacter()
					-- error otherwise self:Error("Improper number layout")
					while self.character and self.character >= "0" and self.character <= "9" do self:ReadCharacter() end
				end
				self.symtok = "num";
			elseif self.charvalue >= 97 and self.charvalue <= 122 then
				while self.character and (self.charvalue >= 97 and self.charvalue <= 122 or self.charvalue >= 65 and self.charvalue <= 90 or self.character >= "0" and self.character <= "9" or self.character == "_") do self:ReadCharacter() end
				self.symtok = "fun"
			elseif self.charvalue >= 65 and self.charvalue <= 90 or self.character == "_" then
				while self.character and (self.charvalue >= 65 and self.charvalue <= 90 or self.charvalue >= 97 and self.charvalue <= 122 or self.character >= "0" and self.character <= "9" or self.character == "_") do self:ReadCharacter() end
				self.symtok = "var"
			elseif self.character == "'" then
				self:NextCharacter()
				while self.character and self.character ~= "'" do self:ReadCharacter() end
				self:NextCharacter()
				self.symtok = "str"
			elseif self.character == "" then
				break
			else
				if !self:ParseOperator() then
					self:Error("Unexpected character (" .. self.character .. ") at line " .. self.line)
					self:NextCharacter()
				end
			end

			self.symarg = self.buffer
		else
			break
		end

		table.insert(self.symbols, { self.symtok, self.symarg, self.line })
	end
end

function WireGateExpressionParser:ParseOperator()
	-- should be extended to automatically backtrack if failed (and is at nil, but passed a token that wasn't nil)
	-- this is not entirely correct either
	local op = self.optable

	if op[self.character] then
		while true do
			op = op[self.character]
			self:ReadCharacter()

			if self.character then
				if op[2] then

					if op[2][self.character] then
						op = op[2]
					else
						self.symtok = op[1]
						self.symarg = self.buffer
						return true
					end
				else
					self.symtok = op[1]
					self.symarg = self.buffer
					return true
				end
			else
				if op[1] then
					self.symtok = op[1]
					self.symarg = self.buffer
				else
					return false
				end
			end
		end
	else
		return false
	end
end

function WireGateExpressionParser:ParsePorts(ports)
	local vals = {}
	local keys = {}
	ports = string.Explode(" ", string.Trim(ports))

	for _,key in ipairs(ports) do
		key = string.Trim(key)
		if key ~= "" then
			character = string.sub(key, 1, 1)
			charvalue = string.byte(character)
			if charvalue >= 65 and charvalue <= 90 or character == "_" then
				for i=2,string.len(key) do
					character = string.sub(key, i, i)
					charvalue = string.byte(character)
					if character and charvalue >= 65 and charvalue <= 90 or charvalue >= 97 and charvalue <= 122 or character >= "0" and character <= "9" or character == "_" then
					else
						self:Error("Invalid port name: " .. key)
					end
				end
			else
				self:Error("Invalid port name: " .. key)
			end

			if keys[key] then
				self:Error("Duplicate port: " .. key)
			else
				keys[key] = true
				table.insert(vals, key)
			end
		end
	end

	return vals
end



function WireGateExpressionParser:Accept(token)
	if self.symtok == token then
		self:NextSymbol()
		return true;
	else
		return false;
	end
end

function WireGateExpressionParser:Expect(token) -- outputs bad errors (lpa) etc
	if self:Accept(token) then
		return true;
	else
		if self.symtok then
			if self.symtok == "fun" then
				self:Error("Expected symbol (" .. self.toktable[token] .. ") near function (" .. self.symarg .. ") at line " .. self.line);
			elseif self.symtok == "var" then
				self:Error("Expected symbol (" .. self.toktable[token] .. ") near variable (" .. self.symarg .. ") at line " .. self.line);
			elseif self.symtok == "num" then
				self:Error("Expected symbol (" .. self.toktable[token] .. ") near number (" .. self.symarg .. ") at line " .. self.line);
			elseif self.symtok == "str" then
				self:Error("Expected symbol (" .. self.toktable[token] .. ") near string (" .. self.symarg .. ") at line " .. self.line);
			else
				self:Error("Expected symbol (" .. self.toktable[token] .. ") near (" .. self.toktable[self.symtok] .. ") at line " .. self.line);
			end
		else
			self:Error("Expected symbol (" .. self.toktable[token] .. ") at line " .. self.line);
		end
		return false;
	end
end

function WireGateExpressionParser:NextSymbol()
	if self.symbindex <= #self.symbols then
		self.symtok = self.symbols[self.symbindex][1]
		self.symarg = self.symbols[self.symbindex][2]
		self.line =   self.symbols[self.symbindex][3]
		self.symbindex = self.symbindex + 1
	else
		self.symtok = nil
		self.symarg = nil
	end
end

function WireGateExpressionParser:RecurseLeft(expr, tbl)
	local expression = expr(self)
	local ins = false
	while true do
		for key,value in pairs(tbl) do
			if self:Accept(key) then
				ins = true
				expression = {value, expression, expr(self)}
				break
			end
		end
		if !ins then break end
		ins = false
	end
	return expression
end

function WireGateExpressionParser:RecurseRight(expr, tbl)
	local expression = expr(self)
	for key,value in pairs(tbl) do
		if self:Accept(key) then
			return {value, expression, self:RecurseRight(expr, tbl)}
		end
	end
	return expression
end

--[[ 1 : exp2 , exp2 exp1 ]]
function WireGateExpressionParser:expr1()
	local expression = self:expr2()

	if self:Accept("com") or self.symtok then
		return {"seq", expression, self:expr1()}
	else
		return expression
	end
end

--[[ 2 : exp4 , exp4->exp3; ]]
function WireGateExpressionParser:expr2()
	if self.symtok and self.symtok == "fun" and (self.symarg == "concommand" or self.symarg == "concmd") then
		self:NextSymbol()
		self:Expect("lpa")
		local arg = self.symarg
		self:Expect("str")
		self:Expect("rpa")
		return {"con", arg}
	end

	local expression = self:expr4()

	if self:Accept("imp") then
		local expression = {"imp", expression, self:expr3()}
		self:Expect("sem")
		return expression
	else
		return expression
	end
end

--[[ 3 : exp2 , exp2 exp3 ]]
function WireGateExpressionParser:expr3()
	if self.symtok and self.symtok == "fun" and self.symarg == "end" then
		self:NextSymbol()
		return {"end"}
	end

	local expression = self:expr2()
	if self:Accept("com") or self.symtok and self.symtok != "sem" then
		return {"seq", expression, self:expr3()}
	else
		return expression
	end
end

--[[ 4 : exp5 , var=exp4 , var+=exp4 ]] -- force for first level!
function WireGateExpressionParser:expr4()
	local expression = self:expr5()
	if expression and expression[1] == "var" then
		local arg = expression
		if self:Accept("ass") then
			return {"ass", arg, self:expr4()}
		elseif self:Accept("aadd") then
			return {"aadd", arg, self:expr4()}
		elseif self:Accept("asub") then
			return {"asub", arg, self:expr4()}
		elseif self:Accept("amul") then
			return {"amul", arg, self:expr4()}
		elseif self:Accept("adiv") then
			return {"adiv", arg, self:expr4()}
		elseif self:Accept("amod") then
			return {"amod", arg, self:expr4()}
		elseif self:Accept("aexp") then
			return {"aexp", arg, self:expr4()}
		end
	end
	return expression
end

--[[ 5 : exp6 , exp6?exp4:exp4 ]]
function WireGateExpressionParser:expr5()
	local expression = self:expr6()
	if self:Accept("qst") then
		local exprtrue = self:expr4()
		self:Expect("col")
		return {"cnd", expression, exprtrue, self:expr4()}
	else
		return expression
	end
end

--[[ 6 : exp7 , exp7|exp6 ]]
function WireGateExpressionParser:expr6()
	return self:RecurseLeft(self.expr7, {["or"] = "or"})
end

--[[ 7 : exp8 , exp7&exp8 ]]
function WireGateExpressionParser:expr7()
	return self:RecurseLeft(self.expr8, {["and"] = "and"})
end

--[[ 8 : exp9 , exp8==exp9 , exp8!=exp9 ]]
function WireGateExpressionParser:expr8()
	return self:RecurseLeft(self.expr9, {["eq"] = "eq", ["neq"] = "neq"})
end

--[[ 9 : exp10, exp9>=exp10 , exp9<=exp10 , exp9>exp10 , exp9<exp10 ]]
function WireGateExpressionParser:expr9()
	return self:RecurseLeft(self.expr10, {["geq"] = "geq", ["leq"] = "leq", ["gth"] = "gth", ["lth"] = "lth"})
end

--[[ 10: exp11, exp10+exp11 , exp10-exp11 ]]
function WireGateExpressionParser:expr10()
	return self:RecurseLeft(self.expr11, {["add"] = "add", ["sub"] = "sub"})
end

--[[ 11: exp12, exp11*exp12 , exp11/exp12 , exp11%exp12 ]]
function WireGateExpressionParser:expr11()
	return self:RecurseLeft(self.expr12, {["mul"] = "mul", ["div"] = "div", ["mod"] = "mod"})
end

--[[ 12: exp13, exp13^exp12 ]] -- left or right? (right is lua, left is normal calcs)
function WireGateExpressionParser:expr12()
	return self:RecurseRight(self.expr13, {["exp"] = "exp"})
end

--[[ 13: exp14, -exp14, !exp14 ]]
function WireGateExpressionParser:expr13()
	if self:Accept("sub") then
		return {"neg", self:expr14()}
	elseif self:Accept("not") then
		return {"not", self:expr14()}
	else
		return self:expr14()
	end
end

--[[ 14: exp15, (exp4), function(exp16) ]]
function WireGateExpressionParser:expr14()
	local arg = self.symarg
	if self:Accept("lpa") then
		local expression = self:expr4()
		self:Expect("rpa")
		return expression
	elseif self:Accept("fun") then
		self:Expect("lpa")
		if self:Accept("rpa") then
			return {"fun", arg, {"nil"}}
		else
			local expression = self:expr16()
			self:Expect("rpa")
			return {"fun", arg, expression}
		end
	else
		return self:expr15()
	end
end

--[[ 15: number, variable ]]
function WireGateExpressionParser:expr15()
	local arg = self.symarg
	if self:Accept("num") then
		return {"num", tonumber(arg)}
	elseif self:Accept("var") then
		self.locals[arg] = true
		return {"var", arg}
	elseif self:Accept("trg") then
		arg = self.symarg
		if self:Accept("var") then
			return {"trg", arg}
		else
			self:Error("Expected variable near trigger (~) at line " .. self.line)
		end
	elseif self:Accept("dlt") then
		arg = self.symarg
		if self:Accept("var") then
			return {"dlt", arg}
		else
			self:Error("Expected variable near delta ($) at line " .. self.line)
		end
	else
		if self.symtok then
			self:Error("Unexpected symbol (" .. self.symarg .. ") at line " .. self.line)

			self.symbindex = -1 -- make sure there are no more
			self.symtok    = nil
			self.symarg    = nil
		else
			self:Error("Expected further input at line " .. self.line)
		end
	end
end

--[[ 16 : nil , exp4,exp16 ]]
function WireGateExpressionParser:expr16()
	local parameters = {"prm", {"nil"}, self:expr4()}

	while self:Accept("com") do
		parameters = {"prm", parameters, self:expr4()}
	end

	return parameters
end
