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

	local ok, err_or_func = E2Lib.compileScript(source, nil, true)

	local should, step = source:match("^## SHOULD_(%w+):(%w+)")
	local function assertmsg(v, step, err)
		if not v then
			local msg = "FAILED " .. step .. " (" .. name .. "): " .. err .. "\n"
			Msg(msg)
			return false, msg
		end
		return true
	end

	if step == "COMPILE" then
		if should == "FAIL" then
			return assertmsg(not ok, "COMPILING", "Should have failed to compile")			
		else
			return assertmsg(ok, "COMPILING", err_or_func)
		end
	elseif step == "EXECUTE" then
		assertmsg(ok, "COMPILING", err_or_func)

		local ok, err = err_or_func()
		if not ok and err == "exit" then
			return true
		elseif should == "FAIL" then			
			return assertmsg(not ok, "EXECUTION", err_or_func)			
		else
			return assertmsg(ok, "EXECUTION", err_or_func)			
		end
	else
		error("Unhandled unit test combination (" .. name .. "): " .. (should or "nil") .. " + " .. (step or "nil"))
	end
end

---@param path string
---@return string[] failures
---@return string[] passes
local function runE2Tests(path, failures, passes)
	local files, folders = file.Find(AddonRoot .. '/' .. path .. "/*", "GAME")
	failures, passes = failures or {}, passes or {}

	for _, name in ipairs(files) do
		if string.match(name, "%.txt$") then
			local ok, err = runE2Test(AddonRoot .. '/' .. path .. '/' .. name, name)
			if ok then
				passes[#passes + 1] = name
			else
				failures[#failures + 1] = name
			end
		end
	end

	-- Recurse folders
	for _, folder in ipairs(folders) do
		runE2Tests(path .. '/' .. folder, failures, passes)
	end

	return failures, passes
end

concommand.Add("e2test", function()
	local failed, passed = runE2Tests("data/expression2/tests")

	print(#passed .. "/" .. (#passed + #failed) .. " tests passed")
end)