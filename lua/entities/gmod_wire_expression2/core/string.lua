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
		if type(retval) ~= "string" then error("Return value is not a string, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "string"
	end
)

/******************************************************************************/

__e2setcost(3) -- temporary

registerOperator("ass", "s", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local      rv2 = op2[1](self, op2)
	self.vars[op1] = rv2
	self.vclk[op1] = true
	return rv2
end)

/******************************************************************************/

registerOperator("is", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 ~= "" then return 1 else return 0 end
end)

registerOperator("eq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 == rv2 then return 1 else return 0 end
end)

registerOperator("neq", "ss", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv1 != rv2 then return 1 else return 0 end
end)

/******************************************************************************/

__e2setcost(10) -- temporary

registerOperator("add", "ss", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) .. op2[1](self, op2)
end)

/******************************************************************************/

registerOperator("add", "sn", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return op1[1](self, op1) .. tostring(op2[1](self, op2))
end)

registerOperator("add", "ns", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	return tostring(op1[1](self, op1)) .. op2[1](self, op2)
end)

/******************************************************************************/

registerOperator("add", "sv", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv2 = op2[1](self, op2)
	return op1[1](self, op1) .. "[" .. tostring(rv2[1]) .. "," .. tostring(rv2[2]) .. "," .. tostring(rv2[3]) .. "]"
end)

registerOperator("add", "vs", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "," .. tostring(rv1[3]) .. "]" .. op2[1](self, op2)
end)

/******************************************************************************/

registerOperator("add", "sa", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv2 = op2[1](self, op2)
	return op1[1](self, op1) .. "[" .. tostring(rv2[1]) .. "," .. tostring(rv2[2]) .. "," .. tostring(rv2[3]) .. "]"
end)

registerOperator("add", "as", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1 = op1[1](self, op1)
	return "[" .. tostring(rv1[1]) .. "," .. tostring(rv1[2]) .. "," .. tostring(rv1[3]) .. "]" .. op2[1](self, op2)
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


registerFunction("toChar", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 < 32 then return "" end
	if rv1 > 255 then return "" end
	return string.char(rv1)
end)

registerFunction("toByte", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == "" then return -1 end
	return string.byte(rv1)
end)

registerFunction("toByte", "sn", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if rv2 < 1 || rv2 > string.len(rv1) then return -1 end
	return string.byte(rv1, rv2)
end)

registerFunction("toUnicodeChar", "n", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	local utf8 = ""
	if rv1 < 1 then
		return ""
	elseif rv1 <= 127 then
		utf8 = string.char (rv1)
	elseif rv1 < 2048 then
		utf8 = string.format ("%c%c", 192 + math.floor (rv1 / 64), 128 + (rv1 & 63))
	elseif rv1 < 65536 then
		utf8 = string.format ("%c%c%c", 224 + math.floor (rv1 / 4096), 128 + (math.floor (rv1 / 64) & 63), 128 + (rv1 & 63))
	elseif rv1 < 2097152 then
		utf8 = string.format ("%c%c%c%c", 240 + math.floor (rv1 / 262144), 128 + (math.floor (rv1 / 4096) & 63), 128 + (math.floor (rv1 / 64) & 63), 128 + (rv1 & 63))
	end
	return utf8
end)

registerFunction("toUnicodeByte", "s", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if rv1 == "" then return -1 end
	local byte = string.byte(rv1)
	if byte >= 128 then
		if byte >= 240 then
			-- 4 byte sequence
			if string.len (rv1) < 4 then
				return -1
			end
			byte = (byte & 7) * 262144
			byte = byte + (string.byte (rv1, 2) & 63) * 4096
			byte = byte + (string.byte (rv1, 3) & 63) * 64
			byte = byte + (string.byte (rv1, 4) & 63)
		elseif byte >= 224 then
			-- 3 byte sequence
			if string.len (rv1) < 3 then
				return -1
			end
			byte = (byte & 15) * 4096
			byte = byte + (string.byte (rv1, 2) & 63) * 64
			byte = byte + (string.byte (rv1, 3) & 63)
		elseif byte >= 192 then
			-- 2 byte sequence
			if string.len (rv1) < 2 then
				return -1
			end
			byte = (byte & 31) * 64
			byte = byte + (string.byte (rv1, 2) & 63)
		else
			-- invalid sequence
			byte = -1
		end
	end
	return byte
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
	return string.sub(this,start)
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
		local byte = string.byte (rv1, i)
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
	local rv1, rv2 = op1[1](self, op1),op2[1](self, op2)
	return string.rep(rv1,rv2)
end)

registerFunction("trim", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.Trim(rv1)
end)

registerFunction("trimLeft", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.match(rv1, "^ *(.-)$")
end)

registerFunction("trimRight", "s:", "s", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	return string.TrimRight(rv1)
end)

/******************************************************************************/
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
	local OK, Ret = pcall(string.find, this, pattern, start)
	if not OK then
		self.player:ChatPrint(Ret)
		return 0
	else
		return Ret or 0
	end
end

--- Returns the 1st occurrence of the string <needle>, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle)
	return string.find(this, needle, 1, true) or 0
end

---  Returns the 1st occurrence of the string <needle> starting at <start> and going to the end of the string, returns 0 if not found. Does not use LUA patterns.
e2function number string:find(string needle, start)
	return string.find(this, needle, start, true) or 0
end

--- Finds and replaces every occurrence of <needle> with <new> without regular expressions
e2function string string:replace(string needle, string new)
	if needle == "" then return "" end -- prevent crashes. stupid garry...
	return string.Replace(this, needle, new)
end

---  Finds and replaces every occurrence of <pattern> with <new> using regular expressions. Prints malformed string errors to the chat area.
e2function string string:replaceRE(string pattern, string new)
	local OK, NewStr = pcall(string.gsub, this, pattern, new)
	if not OK then
		self.player:ChatPrint(NewStr)
		return ""
	else
		return NewStr or ""
	end
end

local specialchars = {
	["%"] = true,
	["^"] = true,
	["$"] = true,
	["("] = true,
	[")"] = true,
	["."] = true,
	["["] = true,
	["]"] = true,
	["*"] = true,
	["+"] = true,
	["-"] = true,
	["?"] = true
}

__e2setcost(5)

local gmatch = string.gmatch
local sub = string.sub
local Right = string.Right
local find = string.find

--- Splits the string into an array, along the boundaries formed by the string <pattern>. See also [[string.Explode]]
e2function array string:explode(string delim)
	if (this == "") then return {} end
    if (delim == "") then -- Quicker loop for when the delim is empty
        local ret = {}
        for i=1,#this do
            ret[i] = this:sub(i,i)
        end
		self.prf = self.prf + #this / 2
        return ret
    elseif (#delim == 1) then -- Quicker loop when delim is 1 char
        local ret = {}
        local _delim, count = delim, 0
        if (specialchars[delim]) then delim = "%" .. delim end
        for word in this:gmatch( "[^" .. delim .. "]+" ) do
			self.prf = self.prf + 0.5
            count = count + 1
            ret[count] = word
        end
        return ret
    else -- Thanks to Deco Da Man for making this part
        local res = {}
        local count, newpos, pos, start = 1, 0
        repeat
            pos = newpos+1
            start, newpos = this:find( delim, pos, true )
            res[count] = this:sub( pos, (start or 0)-1)
            count = count + 1
			self.prf = self.prf + 0.5
        until not start
        return res
    end
end

__e2setcost(10)

--- Returns a reversed version of <this>
e2function string string:reverse()
	return string.reverse(this)
end

/******************************************************************************/

--- Formats a values exactly like Lua's [http://www.lua.org/manual/5.1/manual.html#pdf-string.format string.format]. Any number and type of parameter can be passed through the "...". Prints errors to the chat area.
e2function string format(string fmt, ...)
	-- TODO: call toString for table-based types
	local ok, ret = pcall(string.format, fmt, ...)
	if not ok then
		self.player:ChatPrint(ret)
		return ""
	end
	return ret
end

/******************************************************************************/
-- string.match wrappers by Jeremydeath, 2009-08-30

--- runs [[string.match]](<this>, <pattern>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern)
	local OK, Ret = pcall(string.match, this, pattern)
	if not OK then
		self.player:ChatPrint(Ret)
		return {}
	else
		return { string.match(this, pattern) }
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the sub-captures as an array. Prints malformed pattern errors to the chat area.
e2function array string:match(string pattern, position)
	local OK, Ret = pcall(string.match, this, pattern, position)
	if not OK then
		self.player:ChatPrint(Ret)
		return {}
	else
		return { string.match(this, pattern) }
	end
end

--- runs [[string.match]](<this>, <pattern>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern)
	local OK, Ret = pcall(string.match, this, pattern)
	if not OK then
		self.player:ChatPrint(Ret)
		return ""
	else
		return Ret or ""
	end
end

--- runs [[string.match]](<this>, <pattern>, <position>) and returns the first match or an empty string if the match failed. Prints malformed pattern errors to the chat area.
e2function string string:matchFirst(string pattern, position)
	local OK, Ret = pcall(string.match, this, pattern, position)
	if not OK then
		self.player:ChatPrint(Ret)
		return ""
	else
		return Ret or ""
	end
end

__e2setcost(nil)
