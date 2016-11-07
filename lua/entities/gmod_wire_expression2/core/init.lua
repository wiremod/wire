AddCSLuaFile()

--[[
  Expression 2 for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

wire_expression2_delta = 0.0000001000000
delta = wire_expression2_delta

-- functions to type-check function return values.

local wire_expression2_debug = CreateConVar("wire_expression2_debug", 0, 0)

if SERVER then
	cvars.AddChangeCallback("wire_expression2_debug", function(CVar, PreviousValue, NewValue)
		if (PreviousValue) == NewValue then return end
		wire_expression2_reload()
	end)
end

-- Removes a typecheck from a function identified by the given signature.
local function removecheck(signature)
	local entry = wire_expression2_funcs[signature]
	local oldfunc, signature, rets, func, cost = entry.oldfunc, unpack(entry)

	if not oldfunc then return end
	func = oldfunc
	oldfunc = nil

	entry[3] = func
	entry.oldfunc = oldfunc
end

--- This function ensures that the given function shows up by the given name in stack traces.
--- It does so by eval'ing a generated block of code which invokes the actual function.
--- Tail recursion optimization is specifically avoided by introducing a local variable in the generated code block.
local function namefunc(func, name)
	-- Filter the name
	name = name:gsub("[^A-Za-z_0-9]", "_")

	-- RunString doesn't have a return value, so we need to go via a global variable
	wire_expression2_namefunc = func
	RunString(([[
		local %s = wire_expression2_namefunc
		function wire_expression2_namefunc(...)
			local ret = %s(...)
			return ret
		end
	]]):format(name, name))
	local ret = wire_expression2_namefunc
	wire_expression2_namefunc = nil

	-- Now ret contains the wrapped function and we can just return it.
	return ret
end

-- Installs a typecheck in a function identified by the given signature.
local function makecheck(signature)
	if signature == "op:seq()" then return end
	local name = signature:match("^([^(]*)")
	local entry = wire_expression2_funcs[signature]
	local oldfunc, signature, rets, func, cost = entry.oldfunc, unpack(entry)

	if oldfunc then return end
	oldfunc = namefunc(func, "e2_" .. name)

	function func(...)
		local retval = oldfunc(...)

		local checker = wire_expression_types2[rets][5]
		if not checker then return retval end

		local ok, msg = pcall(checker, retval)
		if ok then return retval end
		debug.Trace()
		local full_signature = E2Lib.generate_signature(signature, rets)
		error(string.format("Type check for function %q failed: %s\n", full_signature, msg), 0)

		return retval
	end

	entry[3] = func
	entry.oldfunc = oldfunc
end

------------------------------------------------------------------------

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
			[5] = function(retval) if retval ~= nil then error("Return value of void function is not nil.", 0) end end
		}
	}
	wire_expression2_funcs = {}
	wire_expression2_funclist = {}
	if CLIENT then wire_expression2_funclist_lowercase = {} end
	wire_expression2_constants = {}
end

-- additional args: <input serializer>, <output serializer>, <type checker>
function registerType(name, id, def, ...)
	wire_expression_types[string.upper(name)] = { id, def, ... }
	wire_expression_types2[id] = { string.upper(name), def, ... }
	if not WireLib.DT[string.upper(name)] then
		WireLib.DT[string.upper(name)] = { Zero = def }
	end
end

function wire_expression2_CallHook(hookname, ...)
	if not wire_expression_callbacks[hookname] then return end
	local ret_array = {}
	local errors = {}
	local ok, ret
	for i, callback in ipairs(wire_expression_callbacks[hookname]) do
		ok, ret = pcall(callback, ...)
		if not ok then
			if ret == "cancelhook" then break end
			table.insert(errors, "\n" .. ret)
			ret_array = nil
		else
			if ret_array then table.insert(ret_array, ret or false) end
		end
	end
	if not ret_array then error("Error(s) occured while executing '" .. hookname .. "' hook:" .. table.concat(errors), 0) end
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

	wire_expression2_funcs[signature] = { signature, rets, func, cost or tempcost, argnames = argnames }
	if wire_expression2_debug:GetBool() then makecheck(signature) end
end

function registerFunction(name, pars, rets, func, cost, argnames)
	local signature = name .. "(" .. pars .. ")"

	wire_expression2_funcs[signature] = { signature, rets, func, cost or tempcost, argnames = argnames }
	wire_expression2_funclist[name] = true
	if wire_expression2_debug:GetBool() then makecheck(signature) end
end

function E2Lib.registerConstant(name, value, literal)
	if name:sub(1, 1) ~= "_" then name = "_" .. name end
	if not value and not literal then value = _G[name] end

	wire_expression2_constants[name] = value
end

-----------------------------------------------------------------

if SERVER then
	util.AddNetworkString("e2_functiondata_start")
	util.AddNetworkString("e2_functiondata_chunk")

	local clientside_files = {}

	function AddCSE2File(filename)
		AddCSLuaFile(filename)
		clientside_files[filename] = true
	end

	include("extloader.lua")

	-- -- Transfer E2 function info to the client for validation and syntax highlighting purposes -- --

	do
		local miscdata = {} -- Will contain {E2 types info, includes, constants}, this whole table is under 1kb
		local functiondata = {} -- Will contain {functionname = {returntype, cost, argnames}, this will be between 50-100kb

		-- Fills out the above two tables
		function wire_expression2_prepare_functiondata()
			miscdata = { {}, clientside_files, wire_expression2_constants }
			functiondata = {}
			for typename, v in pairs(wire_expression_types) do
				miscdata[1][typename] = v[1] -- typeid (s)
			end

			for signature, v in pairs(wire_expression2_funcs) do
				functiondata[signature] = { v[2], v[4], v.argnames } -- ret (s), cost (n), argnames (t)
			end
		end

		wire_expression2_prepare_functiondata()

		-- Send everything
		local targets = {}
		local function sendData(target)
			if IsValid(target) and target:IsPlayer() and targets[target] == nil then
				targets[target] = "start"
				net.Start("e2_functiondata_start")
				net.WriteTable(miscdata[1])
				net.WriteTable(miscdata[2])
				net.WriteTable(miscdata[3])
				net.Send(target)
			end
		end

		hook.Add("Think", "wire_expression2_sendfunctions_think", function()
			for k, signature in pairs(targets) do
				if not k:IsValid() or not k:IsPlayer() then
					targets[k] = nil
				else
					net.Start("e2_functiondata_chunk")
					if signature == "start" then signature = nil end -- We want to start with next(functiondata, nil) but can't store nil in a table
					local tab
					while net.BytesWritten() < 64000 do
						signature, tab = next(functiondata, signature)
						if not signature then break end
						net.WriteString(signature) -- The function signature ["holoAlpha(nn)"]
						net.WriteString(tab[1]) -- The function's return type ["s"]
						net.WriteUInt(tab[2] or 0, 16) -- The function's cost [5]
						net.WriteTable(tab[3] or {}) -- The function's argnames table (if a table isn't set, it'll just send a 1 byte blank table)
					end
					net.WriteString("") -- Needed to break out of the receiving for loop without affecting the final completion bit boolean
					net.WriteBit(signature == nil) -- If we're at the end of the table, next will return nil, thus sending a true here
					targets[k] = signature -- If nil, this'll remove the entry. Otherwise, this'll set a new next(t,k) starting point
					net.Send(k)
				end
			end
		end)

		local antispam = {}
		function wire_expression2_sendfunctions(ply, isconcmd)
			if isconcmd and not game.SinglePlayer() then
				if not antispam[ply] then antispam[ply] = 0 end
				if antispam[ply] > CurTime() then
					ply:PrintMessage(HUD_PRINTCONSOLE, "This command has a 60 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime()) .. " seconds.")
					return
				end
				antispam[ply] = CurTime() + 60
			end
			sendData(ply)
		end

		-- add a console command the user can use to re-request the function info, in case of errors or updates
		concommand.Add("wire_expression2_sendfunctions", wire_expression2_sendfunctions)

		if game.SinglePlayer() then
			-- If single player, send everything immediately
			hook.Add("PlayerInitialSpawn", "wire_expression2_sendfunctions", sendData)
		end
	end

elseif CLIENT then

	e2_function_data_received = nil
	-- -- Receive E2 function info from the server for validation and syntax highlighting purposes -- --

	wire_expression2_reset_extensions()

	local function insertData(functiondata)
		-- functions
		for signature, tab in pairs(functiondata) do
			local fname = signature:match("^([^(:]+)%(")
			if fname then
				wire_expression2_funclist[fname] = true
				wire_expression2_funclist_lowercase[fname:lower()] = fname
			end
			if not next(tab[3]) then tab[3] = nil end -- If the function has no argnames table, the server will just send a blank table
			wire_expression2_funcs[signature] = { signature, tab[1], false, tab[2], argnames = tab[3] }
		end

		e2_function_data_received = true

		if wire_expression2_editor then
			wire_expression2_editor:Validate(false)

			-- Update highlighting on all tabs
			for i = 1, wire_expression2_editor:GetNumTabs() do
				wire_expression2_editor:GetEditor(i).PaintRows = {}
			end
		end
	end

	local function insertMiscData(types, includes, constants)
		wire_expression2_reset_extensions()

		-- types
		for typename, typeid in pairs(types) do
			wire_expression_types[typename] = { typeid }
			wire_expression_types2[typeid] = { typename }
		end

		-- includes
		for filename, _ in pairs(includes) do
			include("entities/gmod_wire_expression2/core/" .. filename)
		end

		-- constants
		wire_expression2_constants = constants
	end

	local buffer = {}
	net.Receive("e2_functiondata_start", function(len)
		buffer = {}
		insertMiscData(net.ReadTable(), net.ReadTable(), net.ReadTable())
	end)

	net.Receive("e2_functiondata_chunk", function(len)
		while true do
			local signature = net.ReadString()
			if signature == "" then break end -- We've reached the end of the packet
			buffer[signature] = { net.ReadString(), net.ReadUInt(16), net.ReadTable() } -- ret, cost, argnames
		end

		if net.ReadBit() == 1 then
			insertData(buffer) -- We've received the last packet!
		end
	end)
end

include("e2doc.lua")
