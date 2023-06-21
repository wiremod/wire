-- Before linting E2 Files, need to preprocess that e2function syntax away.
-- Hackily polyfill gmod-globals and run the preprocesor outside of gmod in the linter workflow.

-- Polyfills
AddCSLuaFile = function() end
_G.E2Lib = {}
_G.wire_expression_types = {
	["VECTOR"] = { "v" },
	["VECTOR2"] = { "xv2" },
	["VECTOR4"] = { "xv4" },
	["STRING"] = { "s" },
	["NORMAL"] = { "n" },
	["ANGLE"] = { "a" },
	["ARRAY"] = { "r" },
	["TABLE"] = { "t" },
	["ENTITY"] = { "e" },
	["WIRELINK"] = { "xwl" },
	["BONE"] = { "b" }, -- Rest of the types seem to properly be picked up by Pass1.
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

local path_sep = package.config:sub(1, 1)
local traverse_cmd = path_sep == "\\" and "dir /b " or "ls "

---@param path string
---@param callback fun(filename: string, path: string)
local function iterFiles(path, callback)
	path = string.gsub(path, "/", path_sep)

	local dir = io.popen(traverse_cmd .. path)
	for file in dir:lines() do
		callback(file, path .. "/" .. file)
	end
	dir:close()
end

---@param filename string
---@param path string
local function handle(filename, path)
	if filename:sub(1, 3) ~= "cl_" and filename:sub(-4) == ".lua" then
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
end

iterFiles("lua/entities/gmod_wire_expression2/core", handle)
iterFiles("lua/entities/gmod_wire_expression2/core/custom", handle)