-- GMA packer by Vurv
assert(arg[1], "Missing argument #1 (output file)")

---@generic T, V
---@param t T[]
---@param f fun(v: T, k: integer): V
---@return V[]
local function map(t, f)
	local out = {}
	for k, v in ipairs(t) do out[k] = f(v, k) end
	return out
end

---@param name string
---@param desc string
---@param author string
---@param files { path: string, content: string }[] # List of 'files'
---@param steamid integer? # SteamID64 of person who packed the addon. Defaults 0
---@param timestamp integer? # Timestamp of when addon was packed. Defaults to os.time()
---@return string gma # Packed gma file contents
local function pack(name, desc, author, files, steamid, timestamp)
	return "GMAD"
		.. ("< I1 I8 I8 x z z z I4"):pack(3 --[[version]], steamid or 0, timestamp or os.time(), name, desc, author, 1)
		.. table.concat(map(files, function(v, k)
			return ("< I4 z I8 I4"):pack(k, v.path, #v.content, 0 --[[crc]])
		end))
		.. "\0\0\0\0"
		.. table.concat(map(files, function(v)
			return v.content
		end))
		.. "\0\0\0\0"
end

local path_sep = package.config:sub(1, 1)
local traverse_cmd = path_sep == "\\" and "dir /b " or "ls "

local ignore = { -- Don't need the full ignore list since we're only packing the source folders (lua, materials, models, resource, sound)
	".*%.txt$",
	".*%.md$",
	".*%.xcf$",
	".*%.psd$"
}

---@generic T
---@param val T?
---@return T
local function assert(val, msg)
	if not val then error(msg) end
	return val
end

---@param path string
---@param callback fun(filename: string, path: string)
local function iterFiles(path, callback)
	path = string.gsub(path, "/", path_sep)

	local dir = assert(io.popen(traverse_cmd .. '"' .. path .. '"'))
	for file in dir:lines() do
		local full = path .. path_sep .. file
		for _, pattern in ipairs(ignore) do
			if full:match(pattern) then
				goto skip
			end
		end

		local ext = file:match("%.(%w+)$")
		if ext then
			callback(file, full)
		else
			iterFiles(full, callback)
		end

		::skip::
	end
	dir:close()
end

---@type { path: string, content: string }[]
local files = {}

---@param name string
---@param path string
local function handle(name, path)
	local handle = assert(io.open(path, "rb"))
	files[#files + 1] = { path = path, content = handle:read("*a") }
	handle:close()
end

iterFiles("lua", handle)
iterFiles("materials", handle)
iterFiles("models", handle)
iterFiles("resource", handle)
iterFiles("sound", handle)

local gma = pack(
	"Wiremod",
	"A collection of entities connectable by data wires utilizing logical concepts, which allows for the creation of advanced contraptions.",
	"Wireteam",
	files
)

local handle = assert(io.open(arg[1], "wb"), "Failed to create/overwrite output file")
handle:write(gma)
handle:close()