--[[
  Loading extensions
]]

wire_expression2_PreLoadExtensions()

-- Save E2's metatable for wire_expression2_reload
if ENT then

	local wire_expression2_ENT = ENT

	function wire_expression2_reload(ply, cmd, args)
		if IsValid( ply ) and not ply:IsSuperAdmin() and not game.SinglePlayer() then
			ply:PrintMessage( 2, "Sorry " .. ply:Name() .. ", you don't have access to this command." )
			return
		end

		local function _Msg( str )
			if IsValid( ply ) then ply:PrintMessage( 2, str ) end
			if not game.SinglePlayer() then MsgN( str ) end
		end

		timer.Remove( "E2_AutoReloadTimer" )

		_Msg( "Calling destructors for all Expression 2 chips." )
		local chips = ents.FindByClass( "gmod_wire_expression2" )
		for _, chip in ipairs( chips ) do
			if not chip.error then
				chip:Destruct()
			end
			chip.script = nil
		end


		_Msg("Reloading Expression 2 internals.")
		include("entities/gmod_wire_expression2/core/e2lib.lua")
		include("entities/gmod_wire_expression2/base/debug.lua")
		include("entities/gmod_wire_expression2/base/preprocessor.lua")
		include("entities/gmod_wire_expression2/base/tokenizer.lua")
		include("entities/gmod_wire_expression2/base/parser.lua")
		include("entities/gmod_wire_expression2/base/compiler.lua")

		_Msg( "Reloading Expression 2 extensions." )
		include("entities/gmod_wire_expression2/core/init.lua")

		ENT = wire_expression2_ENT
		wire_expression2_is_reload = true
		include( "entities/gmod_wire_expression2/core/extloader.lua" )
		wire_expression2_is_reload = nil
		ENT = nil

		_Msg( "Calling constructors for all Expression 2 chips." )
		wire_expression2_prepare_functiondata()
		if not args or args[1] ~= "nosend" then
			for _, p in ipairs( player.GetAll() ) do
				if IsValid( p ) then wire_expression2_sendfunctions( p ) end
			end
		end
		for _, chip in ipairs( chips ) do
			pcall( chip.OnRestore, chip )
		end

		_Msg( "Done reloading Expression 2 extensions." )

		hook.Run("Expression2Reloaded")
	end

	concommand.Add( "wire_expression2_reload", wire_expression2_reload )

end

wire_expression2_reset_extensions()

include("extpp.lua")

local included_files

local function e2_include_init()
	E2Lib.ExtPP.Init()
	included_files = {}
end

-- parses typename/typeid associations from a file and stores info about the file for later use by e2_include_finalize/e2_include_pass2
local function e2_include(name)
	local luaname = "entities/gmod_wire_expression2/core/" .. name
	local contents = file.Read(luaname, "LUA") or ""
	E2Lib.ExtPP.Pass1(contents)
	table.insert(included_files, { name, luaname, contents })
end

-- parses and executes an extension
local function e2_include_pass2(name, luaname, contents)
	local preprocessedSource = E2Lib.ExtPP.Pass2(contents, luaname)
	E2Lib.currentextension = string.StripExtension( string.GetFileFromFilename(name) )
	if not preprocessedSource then return include(name) end

	local func = CompileString(preprocessedSource, luaname)

	local ok, err = pcall(func)
	if not ok then -- an error occured while executing
		if not err:find( "EXTENSION_DISABLED" ) then
			error(err, 0)
		end
		return
	end

	__e2setcost(nil) -- Reset ops cost at the end of each file
end

local function e2_include_finalize()
	for _, info in ipairs(included_files) do
		local ok, message = pcall(e2_include_pass2, unpack(info))
		if not ok then
			WireLib.ErrorNoHalt(string.format("There was an error loading " ..
			"the %s extension. Please report this to its developer.\n%s\n",
			info[1], message))
		end
	end
	included_files = nil
	e2_include = nil
end

-- end preprocessor stuff

e2_include_init()

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
e2_include("serialization.lua")
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
e2_include("steamidconv.lua")
e2_include("easings.lua")
e2_include("damage.lua")
e2_include("remote.lua")
e2_include("egpobjects.lua")

-- Load serverside files here, they need additional parsing
do
	local list = file.Find("entities/gmod_wire_expression2/core/custom/*.lua", "LUA")
	for _, filename in pairs(list) do
		if filename:sub(1, 3) ~= "cl_" then
			e2_include("custom/" .. filename)
		end
	end
end

e2_include_finalize()
wire_expression2_CallHook("postinit")
wire_expression2_PostLoadExtensions()
