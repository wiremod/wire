--[[******************************************************************************]]--
--  String support
--[[******************************************************************************]]--

local string_sub, string_byte, string_char = string.sub, string.byte, string.char
local string_gsub, string_find, string_match = string.gsub, string.find, string.match
local string_gmatch, string_format = string.gmatch, string.format

local string_Replace, string_Explode = string.Replace, string.Explode

--[[******************************************************************************]]--

registerType("string", "s", "",
	nil,
	nil,
	nil,
	function(v)
		return not isstring(v)
	end
)

--[[******************************************************************************]]--

__e2setcost(3) -- temporary


local string_sub, string_byte = string.sub, string.byte

local function iterc(str, i)
	i = i + 1
	if i <= #str then
		return i, string_sub(str, i, i)
	end
end

local function iterb(str, i)
	i = i + 1
	if i <= #str then
		return i, string_byte(str, i, i)
	end
end

registerOperator("iter", "ns=s", "", function(state, str)
	state.prf = state.prf + #str
	return function()
		return iterc, str, 0
	end
end)

registerOperator("iter", "nn=s", "", function(state, str)
	state.prf = state.prf + #str
	return function()
		return iterb, str, 0
	end
end)

--[[******************************************************************************]]--

e2function number operator_is(string this)
	return this ~= "" and 1 or 0
end

e2function number operator>=(string lhs, string rhs)
	self.prf = self.prf + math.min(#lhs, #rhs) / 10
	return lhs >= rhs and 1 or 0
end

e2function number operator<=(string lhs, string rhs)
	self.prf = self.prf + math.min(#lhs, #rhs) / 10
	return lhs <= rhs and 1 or 0
end

e2function number operator>(string lhs, string rhs)
	self.prf = self.prf + math.min(#lhs, #rhs) / 10
	return lhs > rhs and 1 or 0
end

e2function number operator<(string lhs, string rhs)
	self.prf = self.prf + math.min(#lhs, #rhs) / 10
	return lhs < rhs and 1 or 0
end

--[[******************************************************************************]]--

__e2setcost(1) -- temporary

e2function string operator+(string lhs, string rhs)
	self.prf = self.prf + #lhs * 0.01 + #rhs * 0.01
	return lhs .. rhs
end

--[[******************************************************************************]]--

e2function string operator+(string lhs, number rhs)
	self.prf = self.prf + #lhs * 0.01
	return lhs .. rhs --[[ concatenating a number to a string is valid without tostring. ]]
end

e2function string operator+(number lhs, string rhs)
	self.prf = self.prf + #rhs * 0.01
	return lhs .. rhs --[[ concatenating a strings to a number is valid without tostring. ]]
end

--[[******************************************************************************]]--

__e2setcost(2)

e2function number string:toNumber()
	return tonumber(this) or 0
end

e2function number string:toNumber(number base)
	if base < 2 or base > 36 then return self:throw("Base out of range", 0) end
	return tonumber(this, base) or 0
end

local utf8_char = utf8.char
local utf8_byte = utf8.codepoint

__e2setcost(1)

e2function string toChar(number n)
	if n < 0 or n > 255 then return self:throw("Invalid argument (" .. n .. ") (must be between 0 and 255)", "") end
	return string_char(n)
end

e2function number toByte(string c)
	return string_byte(c) or -1
end

e2function number toByte(string str, number idx)
	return string_byte(str, idx) or -1
end

__e2setcost(5)

local math_floor = math.floor

e2function string toUnicodeChar(number byte)
	-- upper limit used to be 2097152, new limit acquired using pcall and a for loop
	-- above this limit, the function causes a lua error
	if byte < 1 or byte > 1114112 then return self:throw("Invalid argument (" .. byte .. ") (must be between 1 and 1,114,112)", "") end
	return utf8_char(byte)
end

e2function number toUnicodeByte(string c)
	-- upper limit used to be 2097152, new limit acquired using pcall and a for loop
	-- above this limit, the function causes a lua error
	if c == "" then return -1 end
	return utf8_byte(c)
end

--[[******************************************************************************]]--

__e2setcost(1)

[deprecated = "Use the indexing operator instead"]
e2function string string:index(number idx)
	return string_sub(this, idx, idx)
end

e2function string string:left(number idx)
	return string_sub(this, 1, idx)
end

e2function string string:right(number idx)
	return string_sub(this, -idx)
end

e2function string string:sub(number start, number finish)
	return string_sub(this, start, finish)
end

e2function string string:sub(start)
	return string_sub(this, start)
end

registerOperator("indexget", "sn", "s", function(state, this, index)
	return string_sub(this, index, index)
end)

e2function string string:upper()
	return this:upper()
end

e2function string string:lower()
	return this:lower()
end

e2function number string:length()
	return #this
end

__e2setcost(10)

e2function number string:unicodeLength()
	-- the string.gsub method is inconsistent with how writeUnicodeString and toUnicodeByte handles badly-formed sequences.
	-- local _, length = string.gsub (rv1, "[^\128-\191]", "")
	local length = 0
	local i = 1
	while i <= #this do
		local byte = string_byte (this, i)
		if byte >= 240 then
			i = i + 4
		elseif byte >= 224 then
			i = i + 3
		elseif byte >= 192 then
			i = i + 2
		else
			i = i + 1
		end
		length = length + 1
	end
	self.prf = self.prf + length * 0.1
	return length
end

--[[******************************************************************************]]--

__e2setcost(3)

e2function string string:repeat(number times)
	local len = #this * times
	if len <= 0 or len ~= len then return "" end

	self.prf = self.prf + len * 0.01
	if self.prf > e2_tickquota then error("perf", 0) end

	return this:rep(times)
end

__e2setcost(2)

e2function string string:trim()
	return this:Trim()
end

e2function string string:trimLeft()
	return this:TrimLeft()
end

e2function string string:trimRight()
	return this:TrimRight()
end

--[[******************************************************************************]]--

__e2setcost(10)

--- Returns the 1st occurrence of the string <pattern>, returns 0 if not found. Prints malformed string errors to the chat area.
e2function number string:findRE(string pattern)
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return string_find(this, pattern) end)
	if not ok then
		return self:throw(ret, 0)
	else
		return ret or 0
	end
end

---  Returns the 1st occurrence of the string <pattern> starting at <start> and going to the end of the string, returns 0 if not found. Prints malformed string errors to the chat area.
e2function number string:findRE(string pattern, start)
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return string_find(this, pattern, start) end)
	if not ok then
		return self:throw(ret, 0)
	else
		return ret or 0
	end
end

__e2setcost(6)

--- Returns the 1st occurrence of the string <needle>, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle)
	return string_find(this, needle, 1, true) or 0
end

---  Returns the 1st occurrence of the string <needle> starting at <start> and going to the end of the string, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle, start)
	return string_find(this, needle, start, true) or 0
end

__e2setcost(8)

--- Finds and replaces every occurrence of <needle> with <new> without regular expressions
e2function string string:replace(string needle, string new)
	if needle == "" then return this end
	self.prf = self.prf + #this * 0.1 + #new * 0.1
	if self.prf > e2_tickquota then error("perf", 0) end
	return string_Replace(this, needle, new)
end

__e2setcost(12)

---  Finds and replaces every occurrence of <pattern> with <new> using regular expressions. Prints malformed string errors to the chat area.
e2function string string:replaceRE(string pattern, string new)
	self.prf = self.prf + #this * 0.1 + #new * 0.1
	if self.prf > e2_tickquota then error("perf", 0) end
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return string_gsub(this, pattern, new) end)
	if not ok then
		return self:throw(ret, "")
	else
		return ret or ""
	end
end

__e2setcost(2)

--- Splits the string into an array, along the boundaries formed by the string <pattern>. See also [[string.Explode]]
e2function array string:explode(string delim)
	local ret = string_Explode( delim, this )
	self.prf = self.prf + #ret * 0.3 + #this * 0.1
	return ret
end

__e2setcost(5)

e2function array string:explodeRE( string delim )
	self.prf = self.prf + #this * 0.1
	local ok, ret = pcall(function() WireLib.CheckRegex(this, delim) return string_Explode( delim, this, true ) end)
	if not ok then
		return self:throw(ret, {})
	end

	self.prf = self.prf + #ret * 0.3
	return ret
end

__e2setcost(6)

--- Returns a reversed version of <this>
e2function string string:reverse()
	return this:reverse()
end

--[[******************************************************************************]]--
__e2setcost(3)

--- Formats a values exactly like Lua's [http://www.lua.org/manual/5.1/manual.html#pdf-string.format string.format]. Any number and type of parameter can be passed through the "...". Prints errors to the chat area.
e2function string format(string fmt, ...args)
	self.prf = self.prf + #args * 2

	-- TODO: call toString for table-based types
	local ok, ret = pcall(string_format, fmt, unpack(args))
	if not ok then
		return self:throw(ret, "")
	end
	return ret
end

--[[******************************************************************************]]--
-- string.match wrappers by Jeremydeath, 2009-08-30
local table_remove = table.remove

__e2setcost(10)

--- runs [[string.match]](<this>, <pattern>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern)
	local args = {pcall(function() WireLib.CheckRegex(this, pattern) return string_match(this, pattern) end)}
	if not args[1] then
		return self:throw(args[2], {})
	else
		table_remove( args, 1) -- Remove "OK" boolean
		return args or {}
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern, position)
	local args = {pcall(function() WireLib.CheckRegex(this, pattern) return string_match(this, pattern, position) end)}
	if not args[1] then
		return self:throw(args[2], {})
	else
		table_remove( args, 1 ) -- Remove "OK" boolean
		return args or {}
	end
end

-- Helper function for gmatch (below)
-- (By Divran)
local newE2Table = E2Lib.newE2Table

local function gmatch( self, this, pattern )
	local ret = newE2Table()
	local num = 0
	local iter = string_gmatch( this, pattern )
	local v
	while true do
		v = {iter()}
		if not v or #v == 0 then break end
		num = num + 1
		ret.n[num] = v
		ret.ntypes[num] = "r"
	end
	self.prf = self.prf + num
	ret.size = num
	return ret
end

__e2setcost(12)

--- runs [[string.gmatch]](<this>, <pattern>) and returns the captures in an array in a table. Prints malformed pattern errors to the chat area.
-- (By Divran)
e2function table string:gmatch(string pattern)
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return gmatch(self, this, pattern) end)
	if not ok then
		return self:throw(ret, newE2Table())
	else
		return ret
	end
end

--- runs [[string.gmatch]](<this>, <pattern>, <position>) and returns the captures in an array in a table. Prints malformed pattern errors to the chat area.
-- (By Divran)
e2function table string:gmatch(string pattern, position)
	this = this:Right( -position-1 )
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return gmatch(self, this, pattern) end)
	if not ok then
		return self:throw(ret, newE2Table())
	else
		return ret
	end
end

__e2setcost(10)

--- runs [[string.match]](<this>, <pattern>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern)
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return string_match(this, pattern) end)
	if not ok then
		return self:throw(ret, "")
	else
		return ret or ""
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern, position)
	local ok, ret = pcall(function() WireLib.CheckRegex(this, pattern) return string_match(this, pattern, position) end)
	if not ok then
		return self:throw(ret, "")
	else
		return ret or ""
	end
end

--[[******************************************************************************]]--
local unpack = unpack
local isnumber = isnumber
local utf8_len = utf8.len

local function ToUnicodeChar(self, args)
	local count = #args
	if count == 0 then return "" end
	self.prf = self.prf + count * 4

	local codepoints = {}
	for i = 1, count do
		local value = args[i]
		if isnumber(value) then
			value = math_floor(value)
			if 0 <= value and value <= 0x10FFFF then
				codepoints[#codepoints + 1] = value
			end
		end
	end

	return utf8_char(unpack(codepoints))
end

__e2setcost(3)

--- Returns the UTF-8 string from the given Unicode code-points.
e2function string toUnicodeChar(...args)
	return ToUnicodeChar(self, args)
end

--- Returns the UTF-8 string from the given Unicode code-points.
e2function string toUnicodeChar(array args)
	return ToUnicodeChar(self, args)
end

--- Returns the Unicode code-points from the given UTF-8 string.
e2function array string:toUnicodeByte(number startPos, number endPos)
	if #this == 0 then return {} end
	local codepoints = { pcall(utf8_byte, this, startPos, endPos) }
	local ok = table.remove(codepoints, 1)
	if not ok then return {} end
	self.prf = self.prf + #codepoints * 3
	return codepoints
end

--- Returns the length of the given UTF-8 string.
e2function number string:unicodeLength(number startPos, number endPos)
	if #this == 0 then return 0 end
	self.prf = self.prf + #this

	local ok, length = pcall(utf8_len, this, startPos, endPos)
	if ok and isnumber(length) then
		return length
	end
	return -1
end

--[[******************************************************************************]]--
__e2setcost(10)

local compress = util.Compress
local decompress = util.Decompress

e2function string compress(string plaintext)
	local len = #plaintext
	if len > 32768 then return self:throw("Input string is too long!", "") end
	self.prf = self.prf + len * 0.1
	return compress(plaintext)
end

e2function string decompress(string compressed)
	local len = #compressed
	if len > 32768 then return self:throw("Input string is too long!", "") end
	self.prf = self.prf + len * 0.5
	return decompress(compressed) or self:throw("Invalid input for decompression!", "")
end

--[[******************************************************************************]]--
-- Hash functions

local function hash_generic(self, text, func)
	local len = #text
	if len > 131072 then self:forceThrow("Input string is too long!") end
	self.prf = self.prf + len * 0.01
	return func(text)
end

__e2setcost(5)

[nodiscard]
e2function string hashCRC(string text)
	return hash_generic(self, text, util.CRC)
end

[nodiscard]
e2function string hashMD5(string text)
	return hash_generic(self, text, util.MD5)
end

[nodiscard]
e2function string hashSHA1(string text)
	return hash_generic(self, text, util.SHA1)
end

[nodiscard]
e2function string hashSHA256(string text)
	return hash_generic(self, text, util.SHA256)
end