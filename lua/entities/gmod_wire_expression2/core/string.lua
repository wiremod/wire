/******************************************************************************\
  String support
\******************************************************************************/

// TODO: is string.left() faster than s:left()?
// TODO: is string.sub faster than both left and right?
// TODO: these return bad results when used with negative numbers!
// TODO: benchmarks!

local string = string -- optimization

/******************************************************************************/

registerType("string", "s", "",
	nil,
	nil,
	function(retval)
		if !isstring(retval) then error("Return value is not a string, but a "..type(retval).."!",0) end
	end,
	function(v)
		return !isstring(v)
	end
)

/******************************************************************************/

__e2setcost(3) -- temporary

registerOperator("ass", "s", "s", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)

	return rv1 ~= "" and 1 or 0
end)

registerOperator("eq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	return rv1 == rv2 and 1 or 0
end)

registerOperator("neq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	return rv1 ~= rv2 and 1 or 0
end)

registerOperator("geq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + math.min(#rv1, #rv2) / 10

	return rv1 >= rv2 and 1 or 0
end)

registerOperator("leq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + math.min(#rv1, #rv2) / 10

	return rv1 <= rv2 and 1 or 0
end)

registerOperator("gth", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + math.min(#rv1, #rv2) / 10

	return rv1 > rv2 and 1 or 0
end)

registerOperator("lth", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + math.min(#rv1, #rv2) / 10

	return rv1 < rv2 and 1 or 0
end)

/******************************************************************************/

__e2setcost(10) -- temporary

registerOperator("add", "ss", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv1*0.01 + #rv2*0.01

	return rv1 .. rv2
end)

/******************************************************************************/

registerOperator("add", "sn", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv1*0.01

	return rv1 .. tostring(rv2)
end)

registerOperator("add", "ns", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv2*0.01

	return tostring(rv1) .. rv2
end)

/******************************************************************************/

registerOperator("add", "sv", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv1*0.01

	return ("%s[%s,%s,%s]"):format( rv1, rv2[1], rv2[2], rv2[3] )
end)

registerOperator("add", "vs", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv2*0.01

	return ("[%s,%s,%s]%s"):format( rv1[1],rv1[2],rv1[3],rv2)
end)

/******************************************************************************/

registerOperator("add", "sa", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv1*0.01

	return ("%s[%s,%s,%s]"):format( rv1,rv2[1],rv2[2],rv2[3] )
end)

registerOperator("add", "as", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)

	self.prf = self.prf + #rv2*0.01

	return ("[%s,%s,%s]%s"):format( rv1[1],rv1[2],rv1[3],rv2)
end)

/******************************************************************************/

__e2setcost(20) -- temporary

e2function number string:toNumber()
	local ret = tonumber(this)
	if ret == nil then return 0 end
	return ret
end

e2function number string:toNumber(number base)
	local ret = tonumber(this, base)
	if ret == nil then return 0 end
	return ret
end

local string_char = string.char
local string_byte = string.byte
local string_len = string.len
local utf8_char = utf8.char
local utf8_byte = utf8.codepoint

registerFunction("toChar", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 < 0 then return "" end
	if rv1 > 255 then return "" end
	return string_char(rv1)
end)

registerFunction("toByte", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == "" then return -1 end
	return string_byte(rv1)
end)

registerFunction("toByte", "sn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2 < 1 || rv2 > string_len(rv1) then return -1 end
	return string_byte(rv1, rv2)
end)

local math_floor = math.floor

registerFunction("toUnicodeChar", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)

	-- upper limit used to be 2097152, new limit acquired using pcall and a for loop
	-- above this limit, the function causes a lua error
	if rv1 < 1 or rv1 > 1114112 then return "" end

	return utf8_char(rv1)
end)

registerFunction("toUnicodeByte", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == "" then return -1 end

	return utf8_byte(rv1)
end)

/******************************************************************************/

registerFunction("index", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:sub(rv2, rv2)
end)

registerFunction("left", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:Left(rv2)
end)

registerFunction("right", "s:n", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return rv1:Right(rv2)
end)

registerFunction("sub", "s:nn", "s", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	return rv1:sub(rv2, rv3)
end)

e2function string string:sub(start)
	return this:sub(start)
end

e2function string string:operator[](index)
	return this:sub(index,index)
end

registerFunction("upper", "s:", "s", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:upper()
end)

registerFunction("lower", "s:", "s", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:lower()
end)

registerFunction("length", "s:", "n", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return rv1:len()
end)

registerFunction("unicodeLength", "s:", "n", function(self, args)
	local op1 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	-- the string.gsub method is inconsistent with how writeUnicodeString and toUnicodeByte handles badly-formed sequences.
	-- local _, length = string.gsub (rv1, "[^\128-\191]", "")
	local length = 0
	local i = 1
	while i <= #rv1 do
		local byte = string_byte (rv1, i)
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
end)

/******************************************************************************/

registerFunction("repeat", "s:n", "s", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), math.abs(op2[1](self, op2))
	self.prf = self.prf + #rv1 * rv2 * 0.01
	if self.prf > e2_tickquota then error("perf", 0) end
	return rv1:rep(rv2)
end)

registerFunction("trim", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.Trim(rv1)
end)

registerFunction("trimLeft", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1:match( "^ *(.-)$")
end)

registerFunction("trimRight", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return rv1:TrimRight()
end)

/******************************************************************************/


local sub = string.sub
local gsub = string.gsub
local find = string.find

--- Returns the 1st occurrence of the string <pattern>, returns 0 if not found. Prints malformed string errors to the chat area.
e2function number string:findRE(string pattern)
	local OK, Ret = pcall(string.find, this, pattern)
	if not OK then
		self.player:ChatPrint(Ret)
		return 0
	else
		return Ret or 0
	end
end

---  Returns the 1st occurrence of the string <pattern> starting at <start> and going to the end of the string, returns 0 if not found. Prints malformed string errors to the chat area.
e2function number string:findRE(string pattern, start)
	local OK, Ret = pcall(find, this, pattern, start)
	if not OK then
		self.player:ChatPrint(Ret)
		return 0
	else
		return Ret or 0
	end
end

--- Returns the 1st occurrence of the string <needle>, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle)
	return this:find( needle, 1, true) or 0
end

---  Returns the 1st occurrence of the string <needle> starting at <start> and going to the end of the string, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle, start)
	return this:find( needle, start, true) or 0
end

--- Finds and replaces every occurrence of <needle> with <new> without regular expressions
e2function string string:replace(string needle, string new)
	if needle == "" then return this end
	return this:Replace( needle, new)
end

---  Finds and replaces every occurrence of <pattern> with <new> using regular expressions. Prints malformed string errors to the chat area.
e2function string string:replaceRE(string pattern, string new)
	local OK, NewStr = pcall(gsub, this, pattern, new)
	if not OK then
		self.player:ChatPrint(NewStr)
		return ""
	else
		return NewStr or ""
	end
end

__e2setcost(5)

--- Splits the string into an array, along the boundaries formed by the string <pattern>. See also [[string.Explode]]
local string_Explode = string.Explode
e2function array string:explode(string delim)
	local ret = string_Explode( delim, this )
	self.prf = self.prf + #ret * 0.3 + #this * 0.1
	return ret
end

e2function array string:explodeRE( string delim )
	local ret = string_Explode( delim, this, true )
	self.prf = self.prf + #ret * 0.3 + #this * 0.1
	return ret
end

__e2setcost(10)

--- Returns a reversed version of <this>
e2function string string:reverse()
	return this:reverse()
end

/******************************************************************************/
local string_format = string.format
local gmatch = string.gmatch
local Right = string.Right

--- Formats a values exactly like Lua's [http://www.lua.org/manual/5.1/manual.html#pdf-string.format string.format]. Any number and type of parameter can be passed through the "...". Prints errors to the chat area.
e2function string format(string fmt, ...)
	-- TODO: call toString for table-based types
	local ok, ret = pcall(string_format, fmt, ...)
	if not ok then
		self.player:ChatPrint(ret)
		return ""
	end
	return ret
end

/******************************************************************************/
-- string.match wrappers by Jeremydeath, 2009-08-30
local string_match = string.match
local table_remove = table.remove

--- runs [[string.match]](<this>, <pattern>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern)
	local args = {pcall(string_match, this, pattern)}
	if not args[1] then
		self.player:ChatPrint(args[2] or "Unknown error in str:match")
		return {}
	else
		table_remove( args, 1 ) -- Remove "OK" boolean
		return args or {}
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern, position)
	local args = {pcall(string_match, this, pattern, position)}
	if not args[1] then
		self.player:ChatPrint(args[2] or "Unknown error in str:match")
		return {}
	else
		table_remove( args, 1 ) -- Remove "OK" boolean
		return args or {}
	end
end

local table_Copy = table.Copy

-- Helper function for gmatch (below)
-- (By Divran)
local newE2Table = E2Lib.newE2Table

local function gmatch( self, this, pattern )
	local ret = newE2Table()
	local num = 0
	local iter = this:gmatch( pattern )
	local v
	while true do
		v = {iter()}
		if (!v or #v==0) then break end
		num = num + 1
		ret.n[num] = v
		ret.ntypes[num] = "r"
	end
	self.prf = self.prf + num
	ret.size = num
	return ret
end

--- runs [[string.gmatch]](<this>, <pattern>) and returns the captures in an array in a table. Prints malformed pattern errors to the chat area.
-- (By Divran)
e2function table string:gmatch(string pattern)
	local OK, ret = pcall( gmatch, self, this, pattern )
	if (!OK) then
		self.player:ChatPrint( ret or "Unknown error in str:gmatch" )
		return newE2Table()
	else
		return ret
	end
end

--- runs [[string.gmatch]](<this>, <pattern>, <position>) and returns the captures in an array in a table. Prints malformed pattern errors to the chat area.
-- (By Divran)
e2function table string:gmatch(string pattern, position)
	this = this:Right( -position-1 )
	local OK, ret = pcall( gmatch, self, this, pattern )
	if (!OK) then
		self.player:ChatPrint( ret or "Unknown error in str:gmatch" )
		return newE2Table()
	else
		return ret
	end
end

--- runs [[string.match]](<this>, <pattern>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern)
	local OK, Ret = pcall(string_match, this, pattern)
	if not OK then
		self.player:ChatPrint(Ret)
		return ""
	else
		return Ret or ""
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern, position)
	local OK, Ret = pcall(string_match, this, pattern, position)
	if not OK then
		self.player:ChatPrint(Ret)
		return ""
	else
		return Ret or ""
	end
end

/******************************************************************************/
local unpack = unpack
local isnumber = isnumber
local utf8_len = utf8.len

local function ToUnicodeChar(self, args)
	local count = #args
	if count == 0 then return "" end
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
	self.prf = self.prf + count * 0.001
	return utf8_char(unpack(codepoints))
end

__e2setcost(1)

--- Returns the UTF-8 string from the given Unicode code-points.
e2function string toUnicodeChar(...)
	return ToUnicodeChar(self, { ... })
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
	self.prf = self.prf + #codepoints * 0.001
	return codepoints
end

--- Returns the length of the given UTF-8 string.
e2function number string:unicodeLength(number startPos, number endPos)
	if #this == 0 then return 0 end
	local ok, length = pcall(utf8_len, this, startPos, endPos)
	if ok and isnumber(length) then
		self.prf = self.prf + length * 0.001
		return length
	end
	self.prf = self.prf + #this * 0.001
	return -1
end
