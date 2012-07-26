/******************************************************************************\
  Expression 2 Tokenizer for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

AddCSLuaFile("tokenizer.lua")

Tokenizer = {}
Tokenizer.__index = Tokenizer

function Tokenizer.Execute(...)
	-- instantiate Tokenizer
	local instance = setmetatable({}, Tokenizer)

	-- and pcall the new instance's Process method.
	return pcall(Tokenizer.Process, instance, ...)
end

function Tokenizer:Error(message, offset)
	error(message .. " at line " .. self.filename .. ":" .. self.tokenline .. ", char " .. (self.tokenchar+(offset or 0)), 0)
end

function Tokenizer:Process(buffer, includes)
	self.buffer = buffer
	self.includes = includes
	self.stack = {}

	self.filename = "generic"
	self.length = buffer:len()
	self.position = 0

	self:SkipCharacter()

	local tokens = {}
	local tokenname, tokendata, tokenspace, includespace
	self.tokendata = ""

	while true do
		while self.character do
			-- Localize stuff because it will be changed after
			local prevline = self.readline
			local includes = self.includes

			-- Skip spaces and take into account space in token after inclusion
			tokenspace = self:NextPattern("%s+") and true or false or includespace
			includespace = false

			-- Process includes
			for line=self.readline, prevline, -1 do
				-- This line contains include
				if includes[line] then
					self:PushFile(unpack(includes[line]))
					includespace = true
				end
			end

			-- There were no includes in previous lines, so continue working on this
			if includes == self.includes then
				if !self.character then break end
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

				tokens[#tokens + 1] = { tokenname, tokendata, tokenspace, self.filename, self.tokenline, self.tokenchar }
			end
		end

		-- Pop file
		if #self.stack > 0 then 
			self:PopFile()
			includespace = true

			self.includes[self.readline] = nil -- To prevent infinite loop in case "#include" is not everything this line has
		else break end
	end

	return tokens
end

function Tokenizer:PushFile(filename, buffer, includes)
	-- Put in stack
	self.stack[#self.stack+1] = {
		self.filename, self.buffer, self.length, 
		self.readline, self.readchar, self.position, self.character,
		self.includes
	}

	-- Set current
	self.filename, self.buffer, self.length, self.position, self.includes = filename, buffer, buffer:len(), 0, includes

	self:SkipCharacter()
end

function Tokenizer:PopFile()
	-- Set current
	self.filename, self.buffer, self.length, self.readline, self.readchar, self.position, self.character, self.includes = unpack(self.stack[#self.stack])
	
	-- Remove the latest
	self.stack[#self.stack] = nil
end

/******************************************************************************/

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
		self.character = self.buffer:sub(self.position, self.position)
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
	local startpos,endpos,text = self.buffer:find(pattern, self.position)

	if startpos ~= self.position then return false end
	local buf = self.buffer:sub(startpos, endpos)
	if not text then text = buf end

	self.tokendata = self.tokendata .. text


	self.position = endpos + 1
	if self.position <= self.length then
		self.character = self.buffer:sub(self.position, self.position)
	else
		self.character = nil
	end

	buf = string.Explode("\n", buf)
	if #buf > 1 then
		self.readline = self.readline+#buf-1
		self.readchar = #buf[#buf]+1
	else
		self.readchar = self.readchar + #buf[#buf]
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
			errorpos = errorpos or self.tokendata:len()
		end

		if errorpos then
			self:Error("Invalid number format (" .. E2Lib.limitString(self.tokendata, 10) .. ")", errorpos-1)
		end

		tokenname = "num"

	elseif self:NextPattern("^[a-z][a-zA-Z0-9_]*") then
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
		elseif self.tokendata:match("^[ijk]$") and self.character ~= "(" then
			tokenname, self.tokendata = "num", "1"..self.tokendata
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
		local tp = type(value)

		if tp == "number" then
			tokenname = "num"
			self.tokendata = value
		elseif tp == "string" then
			tokenname = "str"
			self.tokendata = value
		elseif tp == "nil" then
			self:Error("Unknown constant found ("..self.tokendata..")")
		else
			self:Error("Constant ("..self.tokendata..") has invalid data type ("..tp..")")
		end

	elseif self.character == "\"" then
		-- strings

		-- skip opening quotation mark
		self:SkipCharacter()

		-- loop until the closing quotation mark
		while self.character != "\"" do
			-- check for line/file endings
			if !self.character then
				self:Error("Unterminated string (\"" .. E2Lib.limitString(self.tokendata, 10):gsub( "\n", "" ) .. ")")
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
