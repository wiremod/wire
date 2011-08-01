/******************************************************************************\
  Loading extensions
\******************************************************************************/

-- deal with lua_openscript entities/gmod_wire_expression2/core/extloader.lua
local is_reload = e2_processerror ~= nil

-- Save E2's metatable for wire_expression2_reload
if ENT then
	local wire_expression2_ENT = ENT
	function wire_expression2_reload(ply, cmd, args)
		if validEntity(ply) and ply:IsPlayer() and not ply:IsSuperAdmin() and not SinglePlayer() then return end

		Msg("Calling destructors for all Expression2 chips.\n")
		local chips = ents.FindByClass("gmod_wire_expression2")
		for _,chip in ipairs(chips) do
			if not chip.error then
				chip:PCallHook('destruct')
			end
			chip.script = nil
		end
		Msg("Reloading Expression2 extensions.\n")

		ENT = wire_expression2_ENT
		wire_expression2_is_reload = true
		include("entities/gmod_wire_expression2/core/extloader.lua")
		wire_expression2_is_reload = nil
		ENT = nil

		Msg("Calling constructors for all Expression2 chips.\n")
		wire_expression2_prepare_functiondata()
		if not args or args[1] ~= "nosend" then
			wire_expression2_sendfunctions(player.GetAll())
		end
		for _,chip in ipairs(chips) do
			pcall(chip.OnRestore, chip)
		end
		Msg("Done reloading Expression2 extensions.\n")
	end
	concommand.Add("wire_expression2_reload", wire_expression2_reload)
end

wire_expression2_reset_extensions()


include("extpp.lua")

-- begin preprocessor stuff --
-- mostly a huge workaround for the lack of a chunkname parameter in RunString (thanks, garry)

-- make some wrappers for some commonly used functions that use callbacks.
-- this way we can wrap the callback functions that are passed to them and process their error messages.
local timer_Create = timer.Create
local timer_Adjust = timer.Adjust
local timer_Simple = timer.Simple
local hook_Add     = hook.Add

local function wrap_function(func)
	return function(...)
		e2_install_hook_fix()
		local ok, ret = pcall(func, ...)
		e2_remove_hook_fix()
		if not ok then error(e2_processerror(ret),0) end
		return ret
	end
end

local hook_fix_state = 0

function e2_install_hook_fix()
	hook_fix_state = hook_fix_state + 1
	function timer.Create(uniqueID, delay, reps, func, ...)
		return timer_Create(uniqueID, delay, reps, wrap_function(func), ...)
	end

	function timer.Adjust(uniqueID, delay, reps, func, ...)
		return timer_Adjust(uniqueID, delay, reps, wrap_function(func), ...)
	end

	function timer.Simple(delay, func, ...)
		return timer_Simple(delay, wrap_function(func), ...)
	end

	function hook.Add(hook, unique_name, hook_func)
		return hook_Add(hook, unique_name, wrap_function(hook_func))
	end
end

function e2_remove_hook_fix()
	hook_fix_state = hook_fix_state - 1
	if hook_fix_state == 0 then
		timer.Create = timer_Create
		timer.Adjust = timer_Adjust
		timer.Simple = timer_Simple
		hook.Add     = hook_Add
	end
end

-- end of wrap stuff

local function countlines(s)
	local _,number_of_newlines = string.gsub(s, "\n", "")
	return number_of_newlines+1
end

local function luaExists(luaname)
	return #file.FindInLua(luaname) ~= 0
end

local e2_chunks = { { 1, "unknown chunk" } }
local e2_lastline = 10

function e2_processerror(e)
	--if e:sub(1,1) ~= ":" then return e end
	local line, err = string.match(e,"^%[@?RunString:([1-9][0-9]*)%]%w*(.*)$")
	if not line then return e end
	line = tonumber(line)
	local found_chunk = e2_chunks[#e2_chunks]
	for i,chunk in ipairs(e2_chunks) do
		if chunk[1] > line then
			found_chunk = e2_chunks[i-1]
			break
		end
	end
	return string.format("%s:%d:%s", found_chunk[2], line - found_chunk[1], err)
end

local included_files = {}

-- parses typename/typeid associations from a file and stores info about the file for later use by e2_include_finalize/e2_include_pass2
local function e2_include(name)
	local path,filename = string.match(name, "^(.-/?)([^/]*)$")

	local cl_name = path.."cl_"..filename
	if luaExists("entities/gmod_wire_expression2/core/"..cl_name) then
		-- If a file of the same name prefixed with cl_ exists, send it to the client and load it there.
		AddCSE2File(cl_name)
	end

	local luaname = "entities/gmod_wire_expression2/core/"..name
	local contents = file.Read("../lua/"..luaname) or ""
	e2_extpp_pass1(contents)
	table.insert(included_files, {name, luaname, contents})
end

-- parses and executes an extension
local function e2_include_pass2(name, luaname, contents)
	local ok,ret= pcall(e2_extpp_pass2, contents)
	if not ok then
		ErrorNoHalt(luaname..ret.."\n")
		return
	end

	if not ret then
		-- e2_extpp_pass2 returned false => file doesn't need preprocessing => use the regular means of inclusion
		return include(name)
	end
	-- file needs preprocessing

	-- This variable receives a table with the results from pcalling the code
	e2_includeerror = nil
	-- run code with some padding so the error can be matched up with a file name by e2_processerror.
	RunString("e2_includeerror = { pcall(function() "..string.rep("\n",e2_lastline)..ret.." end) }")

	-- store info for e2_processerror
	table.insert(e2_chunks, { e2_lastline, luaname })
	e2_lastline = e2_lastline + countlines(ret)

	-- evaluate errors
	if e2_includeerror then
		-- no syntax errors, maybe a runtime error?
		ok,ret = unpack(e2_includeerror)
		if not ok then
			-- runtime error => show and bail out
			ErrorNoHalt(e2_processerror(ret).."\n")
			return
		end
	else
		-- no error table present -> there must have been a syntax error. Display context information
		ErrorNoHalt("...while parsing E2 extension. Precise error:\n"..luaname)
		-- evaluate again, displaying the same syntax error, but this time with the proper line number
		RunString(ret)
		-- This results in something like this:
		--[[
		:1234: You forgot a closing ')', noob!
		...while parsing E2 extension. Precise error:
		entities/gmod_wire_expression2/core/foo.lua:3: You forgot a closing ')', noob!
		]]
		-- Sorry, it's not possible to improve this.
	end
end

local function e2_include_finalize()
	e2_install_hook_fix()
	for _,info in ipairs(included_files) do
		e2_include_pass2(unpack(info))
	end
	e2_remove_hook_fix()
	included_files = nil
	e2_include = nil
end

-- end preprocessor stuff

e2_include("core.lua")
e2_include("array.lua")
e2_include("number.lua")
e2_include("vector.lua")
e2_include("string.lua")
e2_include("angle.lua")
e2_include("entity.lua")
e2_include("player.lua")
e2_include("timer.lua")
e2_include("selfaware.lua")
e2_include("unitconv.lua")
e2_include("wirelink.lua")
e2_include("console.lua")
e2_include("find.lua")
e2_include("files.lua")
e2_include("cl_files.lua")
e2_include("globalvars.lua")
e2_include("ranger.lua")
e2_include("sound.lua")
e2_include("color.lua")
e2_include("serverinfo.lua")
e2_include("chat.lua")
e2_include("constraint.lua")
e2_include("weapon.lua")
e2_include("gametick.lua")
e2_include("npc.lua")
e2_include("matrix.lua")
e2_include("vector2.lua")
e2_include("signal.lua")
e2_include("bone.lua")
e2_include("table.lua")
e2_include("glon.lua")
e2_include("hologram.lua")
e2_include("complex.lua")
e2_include("bitwise.lua")
e2_include("quaternion.lua")
e2_include("debug.lua")
e2_include("http.lua")
e2_include("compat.lua")
e2_include("custom.lua")
e2_include("datasignal.lua")
e2_include("egpfunctions.lua")
e2_include("functions.lua")

do
	local list = file.FindInLua("entities/gmod_wire_expression2/core/custom/*.lua")
	for _,filename in pairs(list) do
		if filename:sub(1,3) == "cl_" then
			-- If the is prefixed with "cl_", send it to the client and load it there.
			AddCSE2File("custom/" .. filename)
		else
			e2_include("custom/" .. filename)
		end
	end
end

e2_include_finalize()

wire_expression2_CallHook("postinit")
