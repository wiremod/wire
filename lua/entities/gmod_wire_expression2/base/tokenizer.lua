--[[
	Expression 2 Tokenizer for Garry's Mod

	Rewritten by Vurv
	Notable changes:
		* void is no longer a keyword, it is treated like any other type as a lowercase identifier.
		* tokens are proper instances of a class to allow for methods and simpler usage.
		* should be much faster to parse, and simpler to read
		* boolean literals are reserved for later use.
		* internal representations are stored as enums for faster computation (operators, keywords, grammar)
		* emmylua annotations
]]

AddCSLuaFile()

---@class Tokenizer
---@field pos integer
---@field col integer
---@field line integer
---@field code string?
---@field warnings Warning[]
local Tokenizer = {}
Tokenizer.__index = Tokenizer

E2Lib.Tokenizer = Tokenizer

---@enum TokenVariant
local TokenVariant = {
	Hexadecimal = 1,
	Binary = 2,
	Decimal = 3,
	Quat = 4, -- quat number (4j, 4k)
	Complex = 5, -- complex number literal (4i)

	String = 6, -- "foo"

	Boolean = 7, -- true, false

	Grammar = 8, -- [] () {} ,
	Operator = 9, -- += + / *

	Keyword = 10,
	LowerIdent = 11, -- function_name

	Ident = 12, -- VariableName
	Discard = 13, -- _

	Constant = 14, -- _CONST
}

Tokenizer.Variant = TokenVariant

local VariantLookup = {}

for k, v in pairs(TokenVariant) do
	VariantLookup[v] = k
end

Tokenizer.VariantLookup = VariantLookup

---@class Token
---@field variant TokenVariant
---@field value number|string|boolean
---@field whitespaced boolean
---@field start_line integer
---@field end_line integer
---@field start_col integer
---@field end_col integer
local Token = {}
Token.__index = Token

Tokenizer.Token = Token

--- Creates a new (partially filled) token
--- Line, column and whitespaced need to be added manually.
---@param variant TokenVariant
---@param value number|string|boolean
---@return Token
function Token.new(variant, value)
	return setmetatable({ variant = variant, value = value }, Token)
end

--- Returns a debug representation of a token
---@return string
function Token:debug()
	if self.variant == TokenVariant.Operator then
		return "Token { variant = " .. (VariantLookup[self.variant] or "nil") .. ", value = " .. (E2Lib.OperatorNames[self.value] or "nil") .. "}"
	elseif self.variant == TokenVariant.Keyword then
		return "Token { variant = " .. (VariantLookup[self.variant] or "nil") .. ", value = " .. (E2Lib.KeywordNames[self.value] or "nil") .. "}"
	elseif self.variant == TokenVariant.Grammar then
		return "Token { variant = " .. (VariantLookup[self.variant] or "nil") .. ", value = " .. (E2Lib.GrammarNames[self.value] or "nil") .. "}"
	else
		return "Token { variant = " .. (VariantLookup[self.variant] or "nil") .. ", value = " .. (self.value or "nil") .. "}"
	end
end

--- Returns the 'name' of a token for passing to a user.
---@return string
function Token:display()
	if self.variant == TokenVariant.Operator then
		return E2Lib.OperatorNames[self.value] or "unknown?!"
	elseif self.variant == TokenVariant.Keyword then
		return E2Lib.KeywordNames[self.value] or "unknown?!"
	elseif self.variant == TokenVariant.Grammar then
		return E2Lib.GrammarNames[self.value] or "unknown?!"
	else
		return VariantLookup[self.variant]
	end
end

---@return boolean ok
---@return Token[]
---@return Tokenizer self
function Tokenizer.Execute(code)
	-- instantiate Tokenizer
	local instance = setmetatable({}, Tokenizer)

	-- and pcall the new instance's Process method.
	local ok, tokens = xpcall(Tokenizer.Process, E2Lib.errorHandler, instance, code)
	return ok, tokens, instance
end

function Tokenizer:Reset()
	self.pos = 1
	self.col = 1
	self.line = 1
	self.code = nil
	self.warnings = {}
end

---@param message string
---@param offset integer?
function Tokenizer:Error(message, offset)
	error(message .. " at line " .. self.line .. ", char " .. (self.col + (offset or 0)), 0)
end

---@param message string
---@param offset integer?
function Tokenizer:Warning(message, offset)
	self.warnings[#self.warnings + 1] = { message = message, line = self.line, char = (self.col + (offset or 0)) }
end

local Escapes = {
	['\\'] = '\\',
	['"'] = '"',
	['a'] = '\a',
	['b'] = '\b',
	['f'] = '\f',
	['n'] = '\n',
	['r'] = '\r',
	['t'] = '\t',
	['v'] = '\v'
}

---@return Token?
function Tokenizer:Next()
	local match = self:ConsumePattern("^0x[0-9A-F]+")

	if match then
		local val = tonumber(match) or self:Error("Invalid number format (" .. E2Lib.limitString(match, 10) .. ")")
		return Token.new(TokenVariant.Hexadecimal, val)
	end

	match = self:ConsumePattern("^0b[0-1]+")
	if match then
		local val = tonumber( match:sub(3), 2 ) or self:Error("Invalid number format (" .. E2Lib.limitString(match, 10) .. ")")
		return Token.new(TokenVariant.Binary, val)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*[eE][+-]?[0-9]+")
	if match then
		-- Decimal number with exponent part
		local val = tonumber(match) or self:Error("Invalid number format (" .. E2Lib.limitString(match, 10) .. ")")
		return Token.new(TokenVariant.Decimal, val)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*[jk]")
	if match then
		-- Quaternion number
		local badmatch = self:ConsumePattern("^[a-zA-Z_]")
		if badmatch then
			self:Error("Invalid number format (" .. E2Lib.limitString(match .. badmatch, 10) .. ")")
		end
		return Token.new(TokenVariant.Quat, match)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*i")
	if match then
		-- Complex number
		local badmatch = self:ConsumePattern("^[a-zA-Z_]")
		if badmatch then
			self:Error("Invalid number format (" .. E2Lib.limitString(match .. badmatch, 10) .. ")")
		end
		return Token.new(TokenVariant.Complex, match)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*")
	if match then
		-- Decimal number
		local val = tonumber(match) or self:Error("Invalid number format (" .. E2Lib.limitString(match, 10) .. ")")
		return Token.new(TokenVariant.Decimal, val)
	end

	match = self:ConsumePattern("^[a-z#][a-zA-Z0-9_]*")
	if match then
		-- Keyword/Function
		if E2Lib.KeywordLookup[match] then
			return Token.new(TokenVariant.Keyword, E2Lib.KeywordLookup[match])
		elseif match == "true" then
			return Token.new(TokenVariant.Boolean, true)
		elseif match == "false" then
			return Token.new(TokenVariant.Boolean, false)
		elseif match == "k" or match == "j" then
			self:Warning("Avoid using quaternion literal '" .. match .. "' on its own. (Use 1" .. match .. " instead)")
			return Token.new(TokenVariant.Quat, "1" .. match)
		elseif match == "i" then
			-- self:Warning("Avoid using complex literal 'i' on its own. (Use 1i instead)")
			return Token.new(TokenVariant.Complex, "1i")
		else
			return Token.new(TokenVariant.LowerIdent, match)
		end
	end

	match = self:ConsumePattern("^[A-Z][a-zA-Z0-9_]*")
	if match then
		return Token.new(TokenVariant.Ident, match)
	end

	match = self:ConsumePattern("^_[A-Z0-9_]+")
	if match then
		-- Constant value
		local value = wire_expression2_constants[match]

		if isnumber(value) then
			return Token.new(TokenVariant.Decimal, value)
		elseif isstring(value) then
			return Token.new(TokenVariant.String, value)
		else
			self:Error("Constant (" .. match .. ") has invalid data type (" .. type(value) .. ")")
		end
	end

	if self:ConsumePattern("^_") then
		-- A discard is used to signal intent that something is intentionally not used.
		-- This is mainly to avoid warnings for unused variables from events or functions.
		-- You are not allowed to actually use the discard anywhere but in a signature, since you can have multiple in the signature.
		return Token.new(TokenVariant.Discard, "_")
	end

	if self:At() == "\"" then
		self:NextChar()
		local buffer, nbuffer = {}, 0
		while true do
			local m = self:ConsumePattern("^[^\"\\]*[\"\\]", true)

			if m then
				nbuffer = nbuffer + 1
				buffer[nbuffer] = m:sub(1, -2)

				-- See if the last char in the match was a quote or an escape char
				if m:sub( -1, -1) == "\"" then
					break
				else -- Escape
					local c = self:At()

					if not Escapes[c] then
						self:Warning("Invalid escape \\" .. c)
						c = '\\' .. c
					else
						c = Escapes[c]
					end

					self:NextChar(true)

					nbuffer = nbuffer + 1
					buffer[nbuffer] = c
				end
			else
				self:Error("Missing \" to end string")
			end
		end

		return Token.new(TokenVariant.String, table.concat(buffer, '', 1, nbuffer))
	end

	if E2Lib.GrammarLookup[self:At()] then
		local c = self:At()
		self:NextChar()
		return Token.new(TokenVariant.Grammar, E2Lib.GrammarLookup[c])
	end

	---@type string|Operator|nil
	local op = E2Lib.optable[self:At()]

	while op do
		if op[2] and op[2][self:PeekChar()] then
			op = op[2][self:NextChar()]
		else
			break
		end
	end

	self:NextChar()

	if op then
		return Token.new(TokenVariant.Operator, E2Lib.OperatorLookup[E2Lib.optable_inv[op[1]]])
	end
end

---@return string?
function Tokenizer:At()
	return self.code:sub(self.pos, self.pos)
end

---@return string?
function Tokenizer:PeekChar()
	return self.code:sub(self.pos + 1, self.pos + 1)
end

--- Doesn't take into account newlines.
---@param ws boolean?
---@return string?
function Tokenizer:NextChar(ws)
	self.pos = self.pos + 1
	local c = self.code:sub(self.pos, self.pos)

	if ws and c == '\n' then
		self.line = self.line + 1
		self.col = 1
	else
		self.col = self.col + 1
	end

	return c
end

---@param pattern string
---@param ws boolean? Whether the pattern may contain newlines. Default false
---@return string?
function Tokenizer:ConsumePattern(pattern, ws)
	local start, ed = self.code:find(pattern, self.pos)
	if not start then return end

	local match = self.code:sub(start, ed)

	if ws then
		-- Newlines could possibly be matched.
		local _, newlines = match:gsub("\n", "")

		if newlines ~= 0 then
			local final_nl, final_char = match:find("\n[^\n]*$")

			self.pos = ed + 1
			self.col = final_char - final_nl + 1

			self.line = self.line + newlines

			return match
		end
	end

	-- Assume no newlines were matched past here.

	self.pos = ed + 1
	self.col = self.col + (ed - start + 1)

	return match
end

---@return Token[]
function Tokenizer:Process(code)
	self:Reset()

	local length = #code
	local tokens, ntok = {}, 0
	self.code = code

	local line, col
	while self.pos <= length do
		local whitespaced = self:ConsumePattern("^%s+", true) ~= nil
		line, col = self.line, self.col

		if self.pos > length then
			break
		end

		local tok = self:Next()
		if not tok then
			self:Error("Failed to parse token")
		end

		tok.start_line, tok.start_col = line, col
		tok.end_line, tok.end_col = self.line, self.col
		tok.whitespaced = whitespaced

		line, col = self.line, self.col

		ntok = ntok + 1
		tokens[ntok] = tok
	end

	return tokens
end