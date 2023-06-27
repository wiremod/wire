-- Before linting E2 Files, need to preprocess that e2function syntax away.
-- Hackily polyfill gmod-globals and run the preprocesor outside of gmod in the linter workflow.

local filesToProcess = {}
for _, v in ipairs(arg) do
	if string.find(v, "lua/entities/gmod_wire_expression2/core", 1, true) then
		filesToProcess[#filesToProcess+1] = v
	end
end
if #filesToProcess==0 then
	return
end

-- Polyfills
AddCSLuaFile = function() end
_G.E2Lib = {}
_G.wire_expression_types = {
	VECTOR = {"v"}, VECTOR2 = {"xv2"},
	VECTOR4 = {"xv4"}, STRING = {"s"},
	NORMAL = {"n"}, ANGLE = {"a"},
	ARRAY = {"r"}, TABLE = {"t"},
	ENTITY = {"e"}, WIRELINK = {"xwl"},
	BONE = {"b"}, QUATERNION = {"q"},
	COMPLEX = {"c"}, GTABLE = {"xgt"},
	MATRIX = {"m"}, MATRIX2 = {"xm2"},
	MATRIX4 = {"xm4"}, RANGER = {"xrd"},
	EFFECT = {"xef"}
}

if not unpack then unpack = table.unpack end
function istable(t) return type(t) == "table" end

function string.Trim(s)
	return string.match( s, "^%s*(.-)%s*$" ) or s
end

function string.Split(str, separator)
	local ret, current_pos = {}, 1
	for i = 1, #str do
		local start_pos, end_pos = string.find(str, separator, current_pos)
		if not start_pos then break end
		ret[ i ] = string.sub( str, current_pos, start_pos - 1 )
		current_pos = end_pos + 1
	end

	ret[ #ret + 1 ] = string.sub( str, current_pos )
	return ret
end
-- Polyfills

require("lua.entities.gmod_wire_expression2.core.extpp")

E2Lib.ExtPP.Init()

---@param path string
local function process(path)
	local handle = io.open(path, "rb")
	local content = handle:read("*a")
	handle:close()

	E2Lib.ExtPP.Pass1(content)
	local preprocessed = E2Lib.ExtPP.Pass2(content)
	if preprocessed then
		local handle = io.open(path, "wb")
		handle:write(preprocessed)
		handle:close()
	end
end

for _, v in ipairs(filesToProcess) do
	process(v)
end
