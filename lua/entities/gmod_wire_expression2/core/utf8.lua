local unpack = unpack
local isnumber = isnumber
local math_floor = math.floor
local utf8 = utf8
local utf8_char = utf8.char
local utf8_codepoint = utf8.codepoint
local utf8_len = utf8.len

__e2setcost(1)

--- Returns the UTF-8 string from the given Unicode code-points.
e2function string utf8char(...)
	local args = { ... }
	local count = #args
	if count == 0 then return "" end
	local codepoints = {}
	for i = 1, count do -- TODO: Limit the count to "max" amount. How about 512?
		local value = args[i]
		if typeids[i] == "n" and isnumber(value) then -- Accept a number only.
			value = math_floor(value)                 -- Convert into integer.
			if 0 <= value and value <= 0xFFFF then    -- Check for valid range.
				codepoints[#codepoints + 1] = value
			end
		end
	end
	self.prf = self.prf + #codepoints / 3
	return utf8_char(unpack(codepoints))
end

--- Returns the Unicode code-points from the given UTF-8 string.
e2function array utf8codepoint(string value, number startPos, number endPos)
	local codepoints = { utf8_codepoint(value, startPos, endPos) }
	self.prf = self.prf + #codepoints / 3
	return codepoints
end

--- Returns the length of the given UTF-8 string.
e2function number utf8length(string value, number startPos, number endPos)
	local length = utf8_len(value, startPos, endPos) -- Returns false if an invalid byte is found.
	if isnumber(length) then -- Success.
		self.prf = self.prf + length / 3
		return length
	end
	-- Failure.
	self.prf = self.prf + #value / 6
	return -1
end
