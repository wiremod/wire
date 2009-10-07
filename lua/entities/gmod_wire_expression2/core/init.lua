AddCSLuaFile("init.lua")

/******************************************************************************\
  Expression 2 for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

// ADD FUNCTIONS FOR COLOR CONVERSION!
// ADD CONSOLE SUPPORT

/*
n = numeric
v = vector
s = string
t = table
e = entity
x = non-basic extensions prefix
*/

wire_expression2_delta = 0.0000001000000
delta = wire_expression2_delta

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/

/******************************************************************************/
-- functions to type-check function return values.

local wire_expression2_debug = CreateConVar("wire_expression2_debug", 0, 0)

cvars.AddChangeCallback("wire_expression2_debug", function(CVar, PreviousValue, NewValue)
	if (PreviousValue) == NewValue then return end
	wire_expression2_reload()
end)

-- Removes a typecheck from a function identified by the given signature.
local function removecheck(signature)
	local entry = wire_expression2_funcs[signature]
	local oldfunc,signature, rets, func,cost = entry.oldfunc,unpack(entry)

	if not oldfunc then return end
	func = oldfunc
	oldfunc = nil

	entry[3] = func
	entry.oldfunc = oldfunc
end

-- Installs a typecheck in a function identified by the given signature.
local function makecheck(signature)
	local entry = wire_expression2_funcs[signature]
	local oldfunc,signature, rets, func,cost = entry.oldfunc,unpack(entry)

	if oldfunc then return end
	oldfunc = func

	function func(...)
		local retval = oldfunc(...)

		local checker = wire_expression_types2[rets][5]
		if not checker then return retval end

		local ok, msg = pcall(checker, retval)
		if ok then return retval end
		debug.Trace()
		local full_signature = E2Lib.generate_signature(signature, rets)
		error(string.format("Type check for function %q failed: %s\n", full_signature, msg),0)

		return retval
	end

	entry[3] = func
	entry.oldfunc = oldfunc
end

/******************************************************************************/

function wire_expression2_reset_extensions()
	wire_expression_callbacks = {
		construct = {},
		destruct = {},
		preexecute = {},
		postexecute = {},
	}

	wire_expression_types = {}
	wire_expression_types2 = {
		[""] = {
			[5] = function() if checker ~= nil then error("Return value of void function is not nil.",0) end end
		}
	}
	wire_expression2_funcs = {}
	wire_expression2_funclist = {}
	wire_expression2_constants = {}
end

-- additional args: <input serializer>, <output serializer>, <type checker>
function registerType(name, id, def, ...)
	wire_expression_types[string.upper(name)] = {id, def, ...}
	wire_expression_types2[id] = {string.upper(name), def, ...}
	if not WireLib.DT[string.upper(name)] then
		WireLib.DT[string.upper(name)] = { Zero = def }
	end
end

function wire_expression2_CallHook(hookname, ...)
	if not wire_expression_callbacks[hookname] then return end
	local ret_array = {}
	local errors = {}
	local ok, ret
	for i,callback in ipairs(wire_expression_callbacks[hookname]) do
		e2_install_hook_fix()
		ok, ret = pcall(callback, ...)
		e2_remove_hook_fix()
		if not ok then
			table.insert(errors, "\n"..e2_processerror(ret))
			ret_array = nil
		else
			if ret_array then table.insert(ret_array, ret or false) end
		end
	end
	if not ret_array then error("Error(s) occured while executing '"..hookname.."' hook:"..table.concat(errors),0) end
	return ret_array
end

function registerCallback(event, callback)
	if not wire_expression_callbacks[event] then wire_expression_callbacks[event] = {} end
	table.insert(wire_expression_callbacks[event], callback)
end

local tempcost

function __e2setcost(cost)
	tempcost = cost
end
function __e2getcost()
	return tempcost
end

function registerOperator(name, pars, rets, func, cost, argnames)
	local signature = "op:" .. name .. "(" .. pars .. ")"

	wire_expression2_funcs[signature] = { signature, rets, func, cost or tempcost, argnames=argnames }
	if wire_expression2_debug:GetBool() then makecheck(signature) end
end

function registerFunction(name, pars, rets, func, cost, argnames)
	local signature = name .. "(" .. pars .. ")"

	wire_expression2_funcs[signature] = { signature, rets, func, cost or tempcost, argnames=argnames }
	wire_expression2_funclist[name] = true
	if wire_expression2_debug:GetBool() then makecheck(signature) end
end

function E2Lib.registerConstant(name, value, literal)
	if name:sub(1,1) ~= "_" then name = "_"..name end
	if not value and not literal then value = _G[name] end

	if literal or type(value) == "number" then
		wire_expression2_constants[name] = tostring(value)
	else
		wire_expression2_constants[name] = string.format("%q", value)
	end
end

/******************************************************************************/

if not datastream then require( "datastream" ) end

if SERVER then

	e2_processerror = nil
	local clientside_files = {}

	function AddCSE2File(filename)
		AddCSLuaFile(filename)
		clientside_files[filename] = true
	end
	include("extloader.lua")

	-- -- Transfer E2 function info to the client for validation and syntax highlighting purposes -- --

	function _R.CRecipientFilter.IsValid() return true end -- workaround for this bug: http://www.facepunch.com/showpost.php?p=15117600 - thanks Lexi

	do
		local functiondata,functiondata2

		-- prepares a table with information about E2 types and functions
		function wire_expression2_prepare_functiondata()
			functiondata = { {}, {}, clientside_files, wire_expression2_constants }
			functiondata2 = {}
			for typename,v in pairs(wire_expression_types) do
				functiondata[1][typename] = v[1] -- typeid
			end

			for signature,v in pairs(wire_expression2_funcs) do
				functiondata[2][signature] = v[2] -- ret
				functiondata2[signature] = { v[4], v.argnames } -- cost, argnames
			end
		end

		wire_expression2_prepare_functiondata()


		function wire_expression2_sendfunctions(ply)
			-- send the prepared function data to the client
			datastream.StreamToClients( ply, "wire_expression2_sendfunctions_hook", functiondata )
			datastream.StreamToClients( ply, "wire_expression2_sendfunctions_hook2", functiondata2 )
		end

		-- add a console command the user can use to re-request the function info, in case of errors or updates
		concommand.Add("wire_expression2_sendfunctions", wire_expression2_sendfunctions)

		-- send function info once the player first spawns (TODO: find an even earlier hook)
		hook.Add("PlayerInitialSpawn", "wire_expression2_sendfunctions", wire_expression2_sendfunctions)
	end

elseif CLIENT then

	e2_function_data_received = nil
	-- -- Receive E2 function info from the server for validation and syntax highlighting purposes -- --

	wire_expression2_reset_extensions()

	datastream.Hook( "wire_expression2_sendfunctions_hook", function( ply, handle, id, functiondata )
		wire_expression2_reset_extensions()

		-- types
		for typename,typeid in pairs(functiondata[1]) do
			wire_expression_types[typename] = { typeid }
			wire_expression_types2[typeid] = { typename }
		end

		-- functions
		for signature,ret in pairs(functiondata[2]) do
			local fname = signature:match("^([^(:]+)%(")
			if fname then wire_expression2_funclist[fname] = true end
			wire_expression2_funcs[signature] = { signature, ret, false }
		end

		-- includes
		for filename,_ in pairs(functiondata[3]) do
			include("entities/gmod_wire_expression2/core/"..filename)
		end

		-- constants
		wire_expression2_constants = functiondata[4]

		e2_function_data_received = true

		if wire_expression2_editor then wire_expression2_editor:Validate(false) end
	end)
	datastream.Hook( "wire_expression2_sendfunctions_hook2", function( ply, handle, id, functiondata2 )
		for signature,v in pairs(functiondata2) do
			local entry = wire_expression2_funcs[signature]
			if entry then
				entry[4] = v[1] -- cost
				entry.argnames = v[2] -- argnames
			end
		end
	end)

	if CanRunConsoleCommand() then
		RunConsoleCommand("wire_expression2_sendfunctions")
	end

end

include("e2doc.lua")
