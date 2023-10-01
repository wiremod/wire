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
		* skips past errors
]]

AddCSLuaFile()

local Trace, Warning, Error = E2Lib.Debug.Trace, E2Lib.Debug.Warning, E2Lib.Debug.Error

---@class Tokenizer
---@field pos integer
---@field col integer
---@field line integer
---@field code string?
---@field warnings Warning[]
local Tokenizer = {}
Tokenizer.__index = Tokenizer

function Tokenizer.new()
	return setmetatable({}, Tokenizer)
end

E2Lib.Tokenizer = Tokenizer

---@enum TokenVariant
local TokenVariant = {
	Whitespace = 1, -- Used internally, won't be given to the parser.

	Hexadecimal = 2,
	Binary = 3,
	Decimal = 4,
	Quat = 5, -- quat number (4j, 4k)
	Complex = 6, -- complex number literal (4i)

	String = 7, -- "foo"

	Boolean = 8, -- true, false

	Grammar = 9, -- [] () {} ,
	Operator = 10, -- += + / *

	Keyword = 11,
	LowerIdent = 12, -- function_name

	Ident = 13, -- VariableName
	Discard = 14, -- _

	Constant = 15, -- _CONST
}

Tokenizer.Variant = TokenVariant

local VariantLookup = {}

for k, v in pairs(TokenVariant) do
	VariantLookup[v] = k
end

Tokenizer.VariantLookup = VariantLookup

---@class Token<T>: { value: T, variant: TokenVariant, whitespaced: boolean, trace: Trace }
---@field variant TokenVariant
---@field whitespaced boolean
---@field trace Trace
---@field value any
local Token = {}
Token.__index = Token

Tokenizer.Token = Token

--- Creates a new (partially filled) token
--- Line, column and whitespaced need to be added manually.
---@generic T
---@param variant TokenVariant
---@param value T
---@return Token<T>
function Token.new(variant, value)
	return setmetatable({ variant = variant, value = value }, Token)
end

--- Returns a debug representation of a token
---@return string
function Token:debug()
	if self.variant == TokenVariant.Operator then
		return string.format("Token { variant = %s, value = %s, trace = %s }", VariantLookup[self.variant], E2Lib.OperatorNames[self.value], self.trace)
	elseif self.variant == TokenVariant.Keyword then
		return string.format("Token { variant = %s, value = %s, trace = %s }", VariantLookup[self.variant], E2Lib.KeywordNames[self.value], self.trace)
	elseif self.variant == TokenVariant.Grammar then
		return string.format("Token { variant = %s, value = %s, trace = %s }", VariantLookup[self.variant], E2Lib.GrammarNames[self.value], self.trace)
	else
		return string.format("Token { variant = %s, value = %s, trace = %s }", VariantLookup[self.variant], self.value, self.trace)
	end
end
Token.__tostring = Token.debug

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
---@return Token[]|Error[] tokens_or_errors
---@return Tokenizer self
function Tokenizer.Execute(code)
	local instance = Tokenizer.new()
	local tokens = instance:Process(code)

	local ok = #instance.errors == 0
	return ok, ok and tokens or instance.errors, instance
end

---@param message string
---@param trace Trace?
---@return boolean false
function Tokenizer:Error(message, trace)
	self.errors[#self.errors + 1] = Error.new( message, trace or self:GetTrace() )
	return false
end

---@param message string
---@param trace Trace?
function Tokenizer:Warning(message, trace)
	self.warnings[#self.warnings + 1] = Warning.new( message, trace or self:GetTrace() )
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

---@return Token|nil|boolean # Either a token, `nil` for unexpected character, or `false` for error.
function Tokenizer:Next()
	local match = self:ConsumePattern("^%s+", true)
	if match then
		return Token.new(TokenVariant.Whitespace, match)
	end

	match = self:ConsumePattern("^0x")
	if match then
		local nums = self:ConsumePattern("^%x+")
		if nums then
			local val = tonumber(nums, 16)
			if val then
				return Token.new(TokenVariant.Hexadecimal, val)
			end
		end

		return self:Error("Malformed hexadecimal number")
	end

	match = self:ConsumePattern("^0b")
	if match then
		local nums = self:ConsumePattern("^[0-1]+")
		if nums then
			return Token.new(TokenVariant.Binary, tonumber(nums, 2))
		elseif self:ConsumePattern("^%w+") then
			return self:Error("Malformed binary number")
		else
			return self:Error("No valid digits found for number")
		end
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*[eE][+-]?[0-9]+")
	if match then
		-- Decimal number with exponent part
		local val = tonumber(match)
		if val then
			return Token.new(TokenVariant.Decimal, val)
		end

		return self:Error("Malformed decimal number")
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*[jk]")
	if match then
		-- Quaternion number
		if self:ConsumePattern("^[a-zA-Z_]") then
			self:Error("Malformed quaternion literal")
		end

		return Token.new(TokenVariant.Quat, match)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*i")
	if match then
		-- Complex number
		if self:ConsumePattern("^[a-zA-Z_]") then
			self:Error("Malformed complex number literal")
		end
		return Token.new(TokenVariant.Complex, match)
	end

	match = self:ConsumePattern("^[0-9]+%.?[0-9]*")
	if match then
		-- Decimal number
		local val = tonumber(match)
		if val then
			return Token.new(TokenVariant.Decimal, val)
		end

		self:Error("Malformed decimal number")
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
		elseif match:sub(1, 1) ~= "#" then
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

		if type(value) == "number" then
			return Token.new(TokenVariant.Decimal, value)
		elseif type(value) == "string" then
			return Token.new(TokenVariant.String, value)
		else
			return self:Error("Constant (" .. match .. ") has invalid data type (" .. type(value) .. ")")
		end
	end

	if self:ConsumePattern("^_") then
		-- A discard is used to signal intent that something is intentionally not used.
		-- This is mainly to avoid warnings for unused variables from events or functions.
		-- You are not allowed to actually use the discard anywhere but in a signature, since you can have multiple in the signature.
		return Token.new(TokenVariant.Ident, "_")
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
				self:ConsumePattern("^.*", true)
				return self:Error("Missing \" to end string")
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
function Tokenizer:Prev()
	return self.code:sub(self.pos - 1, self.pos - 1)
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
	self.pos, self.col, self.line, self.code, self.warnings, self.errors = 1, 1, 1, code, {}, {}

	local length = #code
	local tokens, ntok, error, nerror = {}, 0, {}, 0

	local line, col, whitespaced = 1, 1, false

	function self:GetTrace()
		return Trace.new(line, col, self.line, self.col)
	end

	while self.pos <= length do
		local tok = self:Next()

		if tok == nil then
			nerror = nerror + 1
			error[nerror] = self:Prev()
		elseif tok ~= false then
			if nerror ~= 0 then
				self:Error("Unexpected symbol '" .. table.concat(error, '', 1, nerror) .. "'", Trace.new(line, col, line, col + nerror))
				nerror = 0
			end

			if tok.variant == TokenVariant.Whitespace then
				line, col, whitespaced = self.line, self.col, true
			else
				tok.trace = Trace.new(line, col, self.line, self.col)
				tok.whitespaced = whitespaced

				line, col = self.line, self.col

				ntok = ntok + 1
				tokens[ntok] = tok

				whitespaced = false
			end
		end
	end

	if nerror ~= 0 then
		self:Error("Unexpected symbol '" .. table.concat(error, '', 1, nerror) .. "'", Trace.new(line, col, line, col + nerror))
	end

	return tokens
end