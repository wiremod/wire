--[[
	Expression 2 Debugging
		by Vurv
]]

AddCSLuaFile()

---@class Trace
---@field start_col integer
---@field end_col integer
---@field start_line integer
---@field end_line integer
local Trace = {}
Trace.__index = Trace

---@param start_col integer
---@param start_line integer
---@param end_col integer
---@param end_line integer
---@return Trace
function Trace.new(start_line, start_col, end_line, end_col)
	-- These traces define column as exclusive to the characters. So a start_col of 1, end_col of 2 would be a single character.
	return setmetatable({ start_col = start_col, end_col = end_col, start_line = start_line, end_line = end_line }, Trace)
end

function Trace:debug()
	return string.format("Trace { start_col: %u, end_col: %u, start_line: %u, end_line: %u }", self.start_col, self.end_col, self.start_line, self.end_line)
end
Trace.__tostring = Trace.debug

--- Returns the a new trace that spans both traces.
---@param other Trace
---@return Trace
function Trace:stitch(other)
	return setmetatable({ start_col = self.start_col, end_col = other.end_col, start_line = self.start_line, end_line = other.end_line }, Trace)
end

---@class Warning
---@field message string
---@field trace Trace
---@field quick_fix { replace: string, at: Trace }[]? # Replacements to be made for quick fix
local Warning = {}
Warning.__index = Warning

---@param message string
---@param trace Trace
---@param quick_fix { replace: string, at: Trace }[]? # Replacements for quick fix
function Warning.new(message, trace, quick_fix)
	return setmetatable({ message = message, trace = trace, quick_fix = quick_fix }, Warning)
end

function Warning:debug()
	return string.format("Warning { message = %q, trace = %s }", self.message, self.trace)
end

function Warning:display()
	return string.format("Warning at line %u, char %u: %q", self.trace.start_line, self.trace.start_col, self.message)
end

Warning.__tostring = Warning.debug

---@alias ErrorUserdata { catchable: boolean? }

---@class Error
---@field message string
---@field trace Trace
---@field userdata ErrorUserdata
---@field quick_fix { replace: string, at: Trace }[]? # Replacements to be made for quick fix
local Error = {}
Error.__index = Error

---@param message string
---@param trace Trace?
---@param userdata ErrorUserdata?
---@param quick_fix { replace: string, at: Trace }[]? # Replacements to be made for quick fix
function Error.new(message, trace, userdata, quick_fix)
	return setmetatable({ message = message, trace = trace, userdata = userdata, quick_fix = quick_fix }, Error)
end

function Error:debug()
	return string.format("Error { message = %q, trace = %s }", self.message, self.trace)
end

function Error:display()
	if self.trace then
		local first
		if self.trace.start_line ~= self.trace.end_line then
			first = "Error from lines " .. self.trace.start_line .. " to " .. self.trace.end_line
		else
			first = "Error at line " .. self.trace.start_line
		end

		return string.format("%s, chars %u to %u: %q", first, self.trace.start_col, self.trace.end_col, self.message)
	else
		return self.message
	end
end

Error.__tostring = Error.debug


E2Lib.Debug = {
	Warning = Warning,
	Error = Error,
	Trace = Trace
}