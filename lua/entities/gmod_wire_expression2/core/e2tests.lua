if CLIENT then return end -- Somehow ran on client

-- First find where wiremod is stored.
local AddonRoot = ""
local _, addons = file.Find("addons/*", "GAME")

for _, addon in pairs(addons) do
	local head = "addons/" .. addon

	if file.Exists(head .. "/lua/autorun/wire_load.lua", "GAME") then
		AddonRoot = head
		break
	end
end


---@param path string
---@param name string
---@return boolean ok
---@return string? message # Error message if not ok
local function runE2Test(path, name)
	local source = file.Read(path, "GAME")

	local ok, err = E2Lib.runScript(source, nil, true)
	if not ok and err ~= "exit" then
		local _, msg = E2Lib.unpackException(err)
		Msg("FAILED (" .. name .. "): " .. msg .. "\n")
	else
		Msg("OK (" .. name ..")\n")
	end
end

---@param path string
local function runE2Tests(path)
	local files, folders = file.Find(AddonRoot .. '/' .. path .. "/*", "GAME")

	for _, name in ipairs(files) do
		if string.match(name, "%.txt$") then
			runE2Test(AddonRoot .. '/' .. path .. '/' .. name, name)
		end
	end

	-- Recurse folders
	for _, folder in ipairs(folders) do
		runE2Tests(path .. '/' .. folder, recursive)
	end
end

concommand.Add("e2test", function()
	print("=== Running E2 Unit Tests ===")
	runE2Tests("data/expression2/tests")

	print("=== Running E2 Unit Tests ===")
end)