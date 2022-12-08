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

--- Stitches the trace to end at the ending of the other trace (Assumes other trace is ahead)
---@param other Trace
function Trace:stitch(other)
	self.end_col = other.end_col
	self.end_line = other.end_line
end

---@class Warning
---@field message string
---@field trace Trace
local Warning = {}
Warning.__index = Warning

---@param message string
---@param trace Trace
---@return Warning
function Warning.new(message, trace)
	return setmetatable({ message = message, trace = trace }, Warning)
end

function Warning:debug()
	return string.format("Warning { message = %q, trace = %s }", self.message, self.trace)
end
Warning.__tostring = Warning.debug

---@class Error
---@field message string
---@field trace Trace
local Error = {}
Error.__index = Error

---@param message string
---@param trace Trace
---@return Error
function Error.new(message, trace)
	return setmetatable({ message = message, trace = trace }, Error)
end

function Error:debug()
	return string.format("Error { message = %q, trace = %s }", self.message, self.trace)
end
Error.__tostring = Error.debug


E2Lib.Debug = {
	Warning = Warning,
	Error = Error,
	Trace = Trace
}