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
local function runE2Test(path, name)
	local source = file.Read(path, "GAME")

	local ok, err_or_func = E2Lib.compileScript(source)
	local should, step = source:match("^## SHOULD_(%w+):(%w+)")

	local function msgf(...)
		Msg( string.format(...) )
	end

	if step == "COMPILE" then
		if should == "FAIL" and ok then
			msgf("FAILED COMPILING (%s): %s\n", name, "Should have failed to compile")
			return false
		elseif should == "PASS" and not ok then
			msgf("FAILED COMPILING (%s): %s\n", name, err_or_func)
			return false
		else
			return true
		end
	elseif step == "EXECUTE" then
		if not ok then
			msgf("FAILED COMPILING (%s): %s\n", name, err_or_func)
			return false
		end

		local ok, err = err_or_func()
		if not ok and err == "exit" and should == "PASS" then
			-- Exception for exit(). That should count as a pass
			return true
		elseif should == "FAIL" and ok then
			msgf("FAILED EXECUTION (%s): %s\n", name, "Should have failed to execute")
			return false
		elseif should == "PASS" and not ok then
			msgf("FAILED EXECUTION (%s): %s\n", name, err)
			return false
		else
			return true
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
		local ext = string.match(name, "%.([^.]+)$")
		local full_path = AddonRoot .. '/' .. path .. '/' .. name

		if ext == "txt" then
			local ok = runE2Test(full_path, name)
			if ok then
				passes[#passes + 1] = name
			else
				failures[#failures + 1] = name
			end
		elseif ext == "lua" then
			local fn = CompileString(file.Read(full_path, "GAME"))

			local ok, msg = pcall(fn)
			if ok then
				passes[#passes + 1] = name
			else
				Msg("FAILED LUA TEST (" .. name .. "): " .. msg .. "\n")
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

concommand.Add("e2test", function(ply)
	if IsValid( ply ) and not ply:IsSuperAdmin() and not game.SinglePlayer() then
		ply:PrintMessage( 2, "Sorry " .. ply:Name() .. ", you don't have access to this command." )
		return
	end

	local failed, passed = runE2Tests("data/expression2/tests")

	local msg = #passed .. "/" .. (#passed + #failed) .. " tests passed"
	if IsValid(ply) then
		ply:PrintMessage(2, msg)
	else
		print(msg)
	end
end)