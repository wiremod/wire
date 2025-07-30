if CLIENT then return end -- Somehow ran on client

---@param path string
---@param name string
---@return boolean ok
local function runE2Test(path, name)
	local source = file.Read(path, "DATA")
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
	local files, folders = file.Find(path .. "/*", "DATA")
	failures, passes = failures or {}, passes or {}

	for _, name in ipairs(files) do
		local ext = string.match(name, "%.(.+)$")
		local filepath = path .. '/' .. name

		if ext == "txt" then
			local ok = runE2Test(filepath, name)
			if ok then
				passes[#passes + 1] = name
			else
				failures[#failures + 1] = name
			end
		elseif ext == "lua.txt" then
			local fn = CompileString(file.Read(filepath, "DATA"))

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

	-- Let's make sure we have the latest versions of tests.
	WireLib.GenerateDefaultData()

	local failed, passed = runE2Tests("expression2/tests")
	local msg = #passed .. "/" .. (#passed + #failed) .. " tests passed"

	if IsValid(ply) then
		ply:PrintMessage(2, msg)
	else
		print(msg)
	end
end)