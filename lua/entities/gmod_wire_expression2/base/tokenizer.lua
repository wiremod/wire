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
local ReservedWord = E2Lib.ReservedWord

local tonumber = tonumber
local string_find, string_gsub, string_sub = string.find, string.gsub, string.sub

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
---@param quick_fix { replace: string, at: Trace }[]?
function Tokenizer:Error(message, trace, quick_fix)
	self.errors[#self.errors + 1] = Error.new( message, trace or self:GetTrace(), nil, quick_fix )
	return false
end

---@param message string
---@param trace Trace?
---@param quick_fix { replace: string, at: Trace }[]?
function Tokenizer:Warning(message, trace, quick_fix)
	self.warnings[#self.warnings + 1] = Warning.new( message, trace or self:GetTrace(), quick_fix )
end

local escapes = {
	["\\"] = "\\",
	["\""] = "\"",
	["a"] = "\a",
	["b"] = "\b",
	["f"] = "\f",
	["n"] = "\n",
	["r"] = "\r",
	["t"] = "\t",
	["v"] = "\v",
	["0"] = "\0"
}

local bit_band = bit.band
local bit_bor = bit.bor
local bit_rshift = bit.rshift
local string_char = string.char
local function toUnicodeChar(v)
	if v < 0x80 then -- Single-byte sequence
		return string_char(v)
	elseif v < 0x800 then -- Two-byte sequence
		return string_char(
			bit_bor(0xC0, bit_band(bit_rshift(v, 6), 0x3F)),
			bit_bor(0x80, bit_band(v, 0x3F))
		 )
	elseif v < 0x10000 then -- Three-byte sequence
		 return string_char(
			bit_bor(0xE0, bit_band(bit_rshift(v, 12), 0x3F)),
			bit_bor(0x80, bit_band(bit_rshift(v, 6), 0x3F)),
			bit_bor(0x80, bit_band(v, 0x3F))
		 )
	else -- Four-byte sequence
		return string_char(
			bit_bor(0xF0, bit_band(bit_rshift(v, 18), 0x07)),
			bit_bor(0x80, bit_band(bit_rshift(v, 12), 0x3F)),
			bit_bor(0x80, bit_band(bit_rshift(v, 6), 0x3F)),
			bit_bor(0x80, bit_band(v, 0x3F))
		 )
	end
end

---@return Token|nil|boolean # Either a token, `nil` for unexpected character, or `false` for error.
function Tokenizer:Next()
	local match = self:ConsumePatternMulti("^%s+")
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
		elseif string_sub(match, 1, 1) ~= "#" then
			if ReservedWord[match] then self:Warning("'".. match .. "' is a reserved identifier and may break your code in the future") end
			return Token.new(TokenVariant.LowerIdent, match)
		end
	end

	match = self:ConsumePattern("^[A-Z][a-zA-Z0-9_]*")
	if match then
		return Token.new(TokenVariant.Ident, match)
	end

	match = self:ConsumePattern("^_[A-Z0-9_]+")
	if match then
		return Token.new(TokenVariant.Constant, match)
	end

	if self:At() == "_" then
		-- A discard is used to signal intent that something is intentionally not used.
		-- This is mainly to avoid warnings for unused variables from events or functions.
		-- You are not allowed to actually use the discard anywhere but in a signature, since you can have multiple in the signature.
		self:SkipChar()
		return Token.new(TokenVariant.Ident, "_")
	end

	if self:At() == "\"" then
		self:SkipChar()
		local buffer, nbuffer = {}, 0
		while true do
			local m = self:ConsumePatternMulti("^[^\"\\]*[\"\\]")
			local line, col = self.line, self.col

			if m then
				nbuffer = nbuffer + 1
				buffer[nbuffer] = string_sub(m, 1, -2)

				-- See if the last char in the match was a quote or an escape char
				if string_sub(m, -1, -1) == "\"" then
					break
				else -- Escape
					local char = self:At()
					local esc, err = ""

					-- Using %g here just to be a bit more informative on warnings
					if escapes[char] then
						self:SkipChar() -- its crucial that this is only done without supporting newlines as long as `escapes` doesn't support doing \<newline>
						esc = escapes[char]
					elseif char == "u" then
						self:SkipChar()
						if self:At() ~= "{" then err = "Unicode escape must begin with {" goto _err end

						esc = self:ConsumePatternMulti("^%b{}")

						if not esc then err = "Unicode escape must end with }"
						elseif #esc == 2 then err = "Unicode escape cannot be empty"
						elseif #esc > 8 then err = "Unicode escape can only contain up to 6 characters"
						else
							esc = string_sub(esc, 2, -2)
							local illegal = string_find(esc, "%X") -- Scan for bad characters
							if illegal then
								err = "Unicode escape must contain hexadecimal digits"
								col = col + illegal + 1
								goto _err
							end
							local num = tonumber(esc, 16)
							if not num then
								err = "Unicode escape is invalid"
							elseif num < 0 then
								err = "Unicode escape cannot be negative"
							elseif num >= 0x10ffff then
								err = "Unicode escape cannot be greater than 10ffff"
							else
								esc = toUnicodeChar(num)
							end
						end
					elseif char == "x" then
						self:SkipChar()
						esc = self:ConsumePattern("^%x%x")
						if not esc then
							err = "Hexadecimal escape expects 2 hex digits"
						else
							esc = string_char(tonumber(esc, 16) or 0)
						end
					else
						esc = "\\"
						self:Warning("Invalid escape " .. "\\" .. string_gsub(char, "%G", " "), Trace.new(line, col, self.line, self.col), { { at = Trace.new(self.line, self.col - 1, self.line, self.col), replace = "" } })
					end

					::_err::
					if err then
						local tr = Trace.new(line, col, self.line, self.col)
						self:ConsumePatternMulti("^.*")
						return self:Error(err, tr)
					end
					nbuffer = nbuffer + 1
					buffer[nbuffer] = esc
				end
			else
				self:ConsumePatternMulti("^.*")
				return self:Error("Missing \" to end string")
			end
		end

		return Token.new(TokenVariant.String, table.concat(buffer, "", 1, nbuffer))
	end

	if E2Lib.GrammarLookup[self:At()] then
		local c = self:At()
		self:SkipChar()
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

	self:SkipChar()

	if op then
		return Token.new(TokenVariant.Operator, E2Lib.OperatorLookup[E2Lib.optable_inv[op[1]]])
	end
end

---@return string?
function Tokenizer:At()
	return string_sub(self.code, self.pos, self.pos)
end

---@return string?
function Tokenizer:Prev()
	return string_sub(self.code, self.pos - 1, self.pos - 1)
end

---@return string?
function Tokenizer:PeekChar()
	return string_sub(self.code, self.pos + 1, self.pos + 1)
end

--- Doesn't take into account newlines.
function Tokenizer:SkipChar()
	self.pos = self.pos + 1
	self.col = self.col + 1
end

--- Doesn't take into account newlines.
function Tokenizer:NextChar()
	self.pos = self.pos + 1
	self.col = self.col + 1

	return string_sub(self.code, self.pos, self.pos)
end

function Tokenizer:ConsumePatternMulti(pattern --[[@param pattern string]])
	local start, ed = string_find(self.code, pattern, self.pos)
	if not start then return end

	local match = string_sub(self.code, start, ed)
	local _, newlines = string_gsub(match, "\n", "")

	if newlines ~= 0 then
		local final_nl, final_char = string_find(match, "\n[^\n]*$")

		self.pos = ed + 1
		self.col = final_char - final_nl + 1

		self.line = self.line + newlines

		return match
	end

	-- Assume no newlines were matched past here.

	self.pos = ed + 1
	self.col = self.col + (ed - start + 1)

	return match
end

function Tokenizer:ConsumePattern(pattern --[[@param pattern string]])
	local start, ed = string_find(self.code, pattern, self.pos)
	if not start then return end

	self.pos = ed + 1
	self.col = self.col + (ed - start + 1)

	return string_sub(self.code, start, ed)
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