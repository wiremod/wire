-- GMA packer by Vurv
assert(arg[1], "Missing argument #1 (output file)")

local function u8(n --[[@param n number]])
	return string.char(n)
end

local U8_MAX = 256
local U16_MAX = 65536
local U32_MAX = 4294967296

local function u16(n --[[@param n number]])
	return u8(n % U8_MAX) .. u8( math.floor(n / U8_MAX) )
end

local function u32(n --[[@param n number]])
	return u16(n % U16_MAX) .. u16( math.floor(n / U16_MAX) )
end

local function u64(n --[[@param n number]])
	return u32(n % U32_MAX) .. u32( math.floor(n / U32_MAX) )
end

local function cstr(s --[[@param s string]])
	return s .. "\0"
end

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
---@param description string
---@param author string
---@param files { path: string, content: string }[] # List of 'files'
---@return string gma # Packed gma file contents
local function pack(name, description, author, files)
	return table.concat {
		"GMAD", -- identifier
		u8(3), -- gma version
		u64(0), -- steamid
		u64( os.time() ), -- timestamp
		u8(0),
		cstr(name),
		cstr(description),
		cstr(author),
		u32(1),
		table.concat(map(files, function(v, k)
			return u32(k)
				.. cstr(v.path)
				.. u64(#v.content)
				.. u32(0)
		end)),
		u32(0),
		table.concat(map(files, function(v, k)
			return v.content
		end)),
		u32(0)
	}
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