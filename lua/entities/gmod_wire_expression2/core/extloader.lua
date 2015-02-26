--[[
  Loading extensions
]]

-- Save E2's metatable for wire_expression2_reload
if ENT then
	local wire_expression2_ENT = ENT
	function wire_expression2_reload(ply, cmd, args)
		if IsValid(ply) and ply:IsPlayer() and not ply:IsSuperAdmin() and not game.SinglePlayer() then return end

		Msg("Calling destructors for all Expression2 chips.\n")
		local chips = ents.FindByClass("gmod_wire_expression2")
		for _, chip in ipairs(chips) do
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
			for _, p in pairs( player.GetAll() ) do
				if IsValid( p ) then wire_expression2_sendfunctions( p ) end
			end
		end
		for _, chip in ipairs(chips) do
			pcall(chip.OnRestore, chip)
		end
		Msg("Done reloading Expression2 extensions.\n")
	end

	concommand.Add("wire_expression2_reload", wire_expression2_reload)
end

wire_expression2_reset_extensions()

include("extpp.lua")

local function luaExists(luaname)
	return #file.Find(luaname, "LUA") ~= 0
end

local included_files = {}

-- parses typename/typeid associations from a file and stores info about the file for later use by e2_include_finalize/e2_include_pass2
local function e2_include(name)
	local path, filename = string.match(name, "^(.-/?)([^/]*)$")

	local cl_name = path .. "cl_" .. filename
	if luaExists("entities/gmod_wire_expression2/core/" .. cl_name) then
		-- If a file of the same name prefixed with cl_ exists, send it to the client and load it there.
		AddCSE2File(cl_name)
	end

	local luaname = "entities/gmod_wire_expression2/core/" .. name
	local contents = file.Read(luaname, "LUA") or ""
	e2_extpp_pass1(contents)
	table.insert(included_files, { name, luaname, contents })
end

-- parses and executes an extension
local function e2_include_pass2(name, luaname, contents)
	local ok, ret = pcall(e2_extpp_pass2, contents)
	if not ok then
		WireLib.ErrorNoHalt(luaname .. ret .. "\n")
		return
	end

	if not ret then
		-- e2_extpp_pass2 returned false => file didn't need preprocessing => use the regular means of inclusion
		return include(name)
	end
	
	-- file needed preprocessing => Run the processed file
	local ok, func = pcall(CompileString,ret,luaname)
	if not ok then -- an error occurred while compiling
		error(func)
		return
	end
	
	local ok, err = pcall(func)
	if not ok then -- an error occured while executing
		if string.find(err,"Skipping disabled E2 extension") ~= 0 then -- if it's just a disabled E2 extension...
			local err = string.match(err,"(Skipping disabled E2 extension.+).$") -- filter to the part we want
			print(err) -- print the error
		else
			error(err) -- otherwise, actually cause an error
		end
		return
	end
	
	__e2setcost(nil) -- Reset ops cost at the end of each file
end

local function e2_include_finalize()
	for _, info in ipairs(included_files) do
		e2_include_pass2(unpack(info))
	end
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
e2_include("strfunc.lua")

do
	local list = file.Find("entities/gmod_wire_expression2/core/custom/*.lua", "LUA")
	for _, filename in pairs(list) do
		if filename:sub(1, 3) == "cl_" then
			-- If the is prefixed with "cl_", send it to the client and load it there.
			AddCSE2File("custom/" .. filename)
		else
			e2_include("custom/" .. filename)
		end
	end
end

e2_include_finalize()

wire_expression2_CallHook("postinit")