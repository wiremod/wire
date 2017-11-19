--[[
  Expression 2 Tokenizer for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

AddCSLuaFile()

local utf8_charpattern = utf8.charpattern
local utf8_offset = utf8.offset
local string_match = string.match
local math_Clamp = math.Clamp
local string_sub = string.sub
local string_len = utf8.len

E2Lib.Tokenizer = {}
local Tokenizer = E2Lib.Tokenizer
Tokenizer.__index = Tokenizer

function Tokenizer.Execute(...)
	-- instantiate Tokenizer
	local instance = setmetatable({}, Tokenizer)

	-- and pcall the new instance's Process method.
	return xpcall(Tokenizer.Process, E2Lib.errorHandler, instance, ...)
end

function Tokenizer:Error(message, offset)
	error(message .. " at line " .. self.tokenline .. ", char " .. (self.tokenchar + (offset or 0)), 0)
end

function Tokenizer:Process(buffer, params)
	self.buffer = buffer
	self.length = string_len(buffer)
	self.position = 0

	self:SkipCharacter()

	local tokens = {}
	local tokenname, tokendata, tokenspace
	self.tokendata = ""

	while self.character do
		tokenspace = self:NextPattern("%s+") and true or false

		if not self.character then break end

		self.tokenline = self.readline
		self.tokenchar = self.readchar
		self.tokendata = ""

		tokenname, tokendata = self:NextSymbol()

		if tokenname == nil then
			tokenname, tokendata = self:NextOperator()

			if tokenname == nil then
				self:Error("Unknown character found (" .. self.character .. ")")
			end
		end

		tokens[#tokens + 1] = { tokenname, tokendata, tokenspace, self.tokenline, self.tokenchar }
	end

	return tokens
end

-- ---------------------------------------------------------------------------------------

function Tokenizer:GetLine(line_nr, start, stop)
	local line
	if type(line_nr) == "number" then -- if it's a number, get the line
		line = self.Rows[line_nr]
	else -- assume it's a string
		line = line_nr
	end

	local len = string_len(line)
	if #line == 0 or start > len or (stop and stop <= 0) then return "" end

	-- utf8.offset starts at 0, so subtract one
	if start then
		start = utf8_offset(line,math_Clamp(start,1,len)-1)
		start = string.match(line,"()"..utf8_charpattern,start)
	end
	if stop then
		stop = utf8_offset(line,math_Clamp(stop,1,len)-1)
		stop = string.match(line,utf8_charpattern.."()",stop)-1
	end

	if not start and stop then
		return string_sub(line,1,stop)
	elseif not stop and start then
		return string_sub(line,start)
	elseif start and stop then
		return string_sub(line,start,stop)
	end
end

function Tokenizer:SkipCharacter()
	if self.position < self.length then
		if self.position > 0 then
			if self.character == "\n" then
				self.readline = self.readline + 1
				self.readchar = 1
			else
				self.readchar = self.readchar + 1
			end
		else
			self.readline = 1
			self.readchar = 1
		end

		self.position = self.position + 1
		self.character = self:GetLine(self.buffer,self.position,self.position)
	else
		self.character = nil
	end
end

function Tokenizer:NextCharacter()
	self.tokendata = self.tokendata .. self.character
	self:SkipCharacter()
end

-- Returns true on success, nothing if it fails.
function Tokenizer:NextPattern(pattern)
	if not self.character then return false end
	local startpos, endpos, text = self.buffer:find(pattern, utf8_offset(self.buffer,self.position-1))

	if startpos ~= self.position then return false end
	local buf = self:GetLine(self.buffer,startpos,endpos)
	if not text then text = buf end

	self.tokendata = self.tokendata .. text

	self.position = self.position + string_len(buf) --endpos + 1
	if self.position <= self.length then
		self.character = self:GetLine(self.buffer,self.position,self.position)
	else
		self.character = nil
	end

	buf = string.Explode("\n", buf)
	if #buf > 1 then
		self.readline = self.readline + #buf - 1
		self.readchar = string_len(buf[#buf]) + 1
	else
		self.readchar = self.readchar + string_len(buf[#buf])
	end
	return true
end

function Tokenizer:NextSymbol()
	local tokenname

	if self:NextPattern("^0x[0-9A-F]+") then
		-- Hexadecimal number literal
		tokenname = "num"
		self.tokendata = tonumber(self.tokendata) or self:Error("Invalid number format (" .. E2Lib.limitString(self.tokendata, 10) .. ")")
	elseif self:NextPattern("^0b[0-1]+") then
		-- Binary number literal
		tokenname = "num"
		self.tokendata = tonumber(self.tokendata:sub(3), 2) or self:Error("Invalid number format (" .. E2Lib.limitString(self.tokendata, 10) .. ")")
	elseif self:NextPattern("^[0-9]+%.?[0-9]*") then
		-- real/imaginary/quaternion number literals
		local errorpos = self.tokendata:match("^0()[0-9]") or self.tokendata:find("%.$")
		if self:NextPattern("^[eE][+-]?[0-9][0-9]*") then
			errorpos = errorpos or self.tokendata:match("[eE][+-]?()0[0-9]")
		end

		self:NextPattern("^[ijk]")
		if self:NextPattern("^[a-zA-Z_]") then
			errorpos = errorpos or string_len(self.tokendata)
		end

		if errorpos then
			self:Error("Invalid number format (" .. E2Lib.limitString(self.tokendata, 10) .. ")", errorpos - 1)
		end

		tokenname = "num"

	elseif self:NextPattern("^[a-z#][a-zA-Z0-9_]*") then
		-- keywords/functions
		if self.tokendata == "if" then
			tokenname = "if"
		elseif self.tokendata == "elseif" then
			tokenname = "eif"
		elseif self.tokendata == "else" then
			tokenname = "els"
		elseif self.tokendata == "local" then
			tokenname = "loc"
		elseif self.tokendata == "while" then
			tokenname = "whl"
		elseif self.tokendata == "for" then
			tokenname = "for"
		elseif self.tokendata == "break" then
			tokenname = "brk"
		elseif self.tokendata == "continue" then
			tokenname = "cnt"
		elseif self.tokendata == "switch" then
			tokenname = "swh"
		elseif self.tokendata == "case" then
			tokenname = "case"
		elseif self.tokendata == "default" then
			tokenname = "default"
		elseif self.tokendata == "foreach" then
			tokenname = "fea"
		elseif self.tokendata == "function" then
			tokenname = "func"
		elseif self.tokendata == "return" then
			tokenname = "ret"
		elseif self.tokendata == "void" then
			tokenname = "void"
		elseif self.tokendata == "#include" then
			tokenname = "inclu"
		elseif self.tokendata:match("^[ijk]$") and self.character ~= "(" then
			tokenname, self.tokendata = "num", "1" .. self.tokendata
		else
			tokenname = "fun"
		end

	elseif self:NextPattern("^[A-Z][a-zA-Z0-9_]*") then
		-- variables
		tokenname = "var"

	elseif self.character == "_" then
		-- constants
		self:NextCharacter()
		self:NextPattern("^[A-Z0-9_]*")

		local value = wire_expression2_constants[self.tokendata]

		if isnumber(value) then
			tokenname = "num"
			self.tokendata = value
		elseif isstring(value) then
			tokenname = "str"
			self.tokendata = value
		else
			self:Error("Constant (" .. self.tokendata .. ") has invalid data type (" .. type(value) .. ")")
		end

	elseif self.character == "\"" then
		-- strings

		-- skip opening quotation mark
		self:SkipCharacter()

		-- loop until the closing quotation mark
		while self.character ~= "\"" do
			-- check for line/file endings
			if not self.character then
				self:Error("Unterminated string (\"" .. E2Lib.limitString(self.tokendata, 10):gsub("\n", "") .. ")")
			end

			if self.character == "\\" then
				self:SkipCharacter()
				if self.character == "n" then
					self.tokendata = self.tokendata .. "\n"
					self:SkipCharacter()
				elseif self.character == "t" then
					self.tokendata = self.tokendata .. "\t"
					self:SkipCharacter()
				else
					self:NextCharacter()
				end
			else
				self:NextCharacter()
			end
		end
		-- skip closing quotation mark
		self:SkipCharacter()

		tokenname = "str"

	else
		-- nothing
		return
	end

	return tokenname, self.tokendata
end

function Tokenizer:NextOperator()
	local op = E2Lib.optable[self.character]

	if not op then return end

	while true do
		self:NextCharacter()

		-- Check for the end of the string.
		if not self.character then return op[1] end

		-- Check whether we are at a leaf and can't descend any further.
		if not op[2] then return op[1] end

		-- Check whether we are at a node with no matching branches.
		if not op[2][self.character] then return op[1] end

		-- branch
		op = op[2][self.character]
	end
end
