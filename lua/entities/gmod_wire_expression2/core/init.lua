AddCSLuaFile()

--[[
  Expression 2 for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
]]

function wire_expression2_reset_extensions()
	wire_expression_callbacks = {
		construct = {},
		destruct = {},
		preexecute = {},
		postexecute = {},
	}

	wire_expression_types = {}
	wire_expression_types2 = { [""] = {} } -- TODO: do we really need ""? :\
	wire_expression2_funcs = {}
	wire_expression2_funclist = {}

	if CLIENT then wire_expression2_funclist_lowercase = {} end
	wire_expression2_constants = {}
end

local function isValidTypeId(id)
	return #id == (string.sub(id, 1, 1) == "x" and 3 or 1)
end

---@generic T
---@param name string
---@param id string
---@param def T | nil
---@param input_serialize (fun(self, input: any): T)?
---@param output_serialize (fun(self, output: any): T)?
---@param type_check (fun(v: any))? # DEPRECATED, NO LONGER USED. Can pass nil here safely.
---@param is_invalid (fun(v: any): boolean)?
function registerType(name, id, def, input_serialize, output_serialize, type_check, is_invalid, ...)
	if not isValidTypeId(id) then
		-- this type ID format is relied on in various places including
		-- E2Lib.splitType, and malformed type IDs cause confusing and subtle
		-- errors. Catch this early and blame the caller.
		error(string.format("malformed type ID '%s' - type IDs must be one " ..
		"character long, or three characters long starting with an x", id), 2)
	end

	wire_expression_types[string.upper(name)] = { id, def, input_serialize, output_serialize, type_check, is_invalid, ... }
	wire_expression_types2[id] = { string.upper(name), def, input_serialize, output_serialize, type_check, is_invalid, ... }

	if not WireLib.DT[string.upper(name)] then
		WireLib.DT[string.upper(name)] = {
			Zero = istable(def) and function()
				-- Don't need to handle Vector or Angle case since WireLib.DT already defines them.
				return table.Copy(def)
			end or function()
				-- If not a table, don't need to run table.Copy.
				return def
			end,

			Validator = is_invalid and function(v)
				return not is_invalid(v)
			end or function()
				return true
			end
		}
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

function E2Lib.registerCallback(event, callback)
	assert(isfunction(callback), "registerCallback must be given a proper callback function!")

	if not wire_expression_callbacks[event] then wire_expression_callbacks[event] = {} end
	local currExt = E2Lib.currentextension
	table.insert(wire_expression_callbacks[event], function(a, b, c, d, e, f) E2Lib.currentextension = currExt return callback(a, b, c, d, e, f) end)
end

registerCallback = E2Lib.registerCallback

local tempcost

function __e2setcost(cost)
	tempcost = cost
end

function __e2getcost()
	return tempcost
end

---@param args string
---@return string?, table
local function getArgumentTypeIds(args)
	local thistype, nargs = args:match("^([^:]+):(.*)$")
	if nargs then args = nargs end

	local out, ptr = {}, 1
	while ptr <= #args do
		local c = args:sub(ptr, ptr)
		if c == "x" then
			out[#out + 1] = args:sub(ptr, ptr + 2)
			ptr = ptr + 3
		elseif args:sub(ptr) == "..." then
			out[#out + 1] = "..."
			ptr = ptr + 3
		elseif c:match("^%w") then
			out[#out + 1] = c
			ptr = ptr + 1
		else
			error("Invalid signature: " .. args)
		end
	end

	return thistype, out
end

local EnforcedTypings = {
	["is"] = "n"
}

---@param name string
---@param pars string
---@param rets string
---@param func fun(state: RuntimeContext, ...): any
---@param cost integer?
---@param argnames string[]?
---@param attributes table<string, string|boolean>?
function registerOperator(name, pars, rets, func, cost, argnames, attributes)
	if attributes and attributes.legacy == nil then
		-- can explicitly mark "false" (used by extpp)
		attributes.legacy = true
	elseif not attributes then
		attributes = { legacy = true }
	end

	local enforced = EnforcedTypings[name]
	if enforced and rets ~= enforced then
		error("Registering invalid operator '" .. name .. "' (must return type " .. enforced .. ")")
	end

	local signature = "op:" .. name .. "(" .. pars .. ")"

	wire_expression2_funcs[signature] = { signature, rets, func, cost or tempcost, argnames = argnames, attributes = attributes }
end

function registerFunction(name, pars, rets, func, cost, argnames, attributes)
	if attributes and attributes.legacy == nil then
		-- can explicitly mark "false" (used by extpp)
		attributes.legacy = true
	elseif not attributes then
		attributes = { legacy = true }
	end

	local signature = name .. "(" .. pars .. ")"

	wire_expression2_funcs[signature] = { signature, rets, func, (cost or tempcost or 15) + (attributes.legacy and 10 or 0), argnames = argnames, extension = E2Lib.currentextension, attributes = attributes }

	wire_expression2_funclist[name] = true
end

---@alias E2Constant string | number | E2Constant[]

local TypeMap = {
	["number"] = "n", ["string"] = "s",
	["Vector"] = "v", ["Angle"] = "a",
	["table"] = "r"
}

local ValidArrayTypes = {
	["number"] = true, ["string"] = true,
	["Vector"] = true, ["Angle"] = true
}

---@param value E2Constant
---@param description string?
function E2Lib.registerConstant(name, value, description)
	if name:sub(1, 1) ~= "_" then name = "_" .. name end

	local ty = type(value)
	local e2ty = TypeMap[ty]

	if e2ty then
		if ty == "table" then -- ensure it's actually an array (sequential and valid types)
			local i = 1
			for _, val in pairs(value) do
				assert(value[i] ~= nil, "Invalid array passed to registerConstant (must be sequential)")
				assert(ValidArrayTypes[type(val)], "Invalid array passed to registerConstant (must only contain numbers, strings, vector or angles)")
				i = i + 1
			end
		end

		wire_expression2_constants[name] = {
			value = value,
			type = e2ty,
			description = description,
			extension = E2Lib.currentextension
		}
	else
		local db = debug.getinfo(2, "l")
		WireLib.Notify(nil,
			string.format("[%s]:%d: Invalid value passed to registerConstant for \"%s\". Only numbers, strings, vectors, angles and arrays can be constant values.\n", E2Lib.currentextension, db.currentline, name),
		3)
	end
end

--- Example:
--- E2Lib.registerEvent("propSpawned", { {"TheProp", "e"} })
---@param name string
---@param args { [1]: string, [2]: string }[]?
---@param constructor fun(self: table)? # Constructor to run when E2 initially starts listening to this event. Passes E2 context
---@param destructor fun(self: table)? # Destructor to run when E2 stops listening to this event. Passes E2 context
function E2Lib.registerEvent(name, args, constructor, destructor)
	-- Ensure event starts with lowercase letter
	-- assert(not E2Lib.Env.Events[name], "Possible addon conflict: Trying to override existing E2 event '" .. name .. "'")

	---@cast args { [1]: string, [2]: string }[]

	local printed = false

	if args then
		for k, v in ipairs(args) do
			if type(v) == "string" then -- backwards compatibility for old method without name
				if not printed then
					ErrorNoHaltWithStack("Using E2Lib.registerEvent with string arguments is deprecated (event: " .. name .. ").")
					printed = true
				end

				args[k] = {
					placeholder = v:upper() .. k,
					type = v
				}
			else
				args[k] = {
					placeholder = assert(v[1], "Expected name for event argument #" .. k),
					type = assert(v[2], "Expected type for event argument #" .. k)
				}
			end
		end
	end

	E2Lib.Env.Events[name] = {
		name = name,
		args = args or {},

		constructor = constructor,
		destructor = destructor,

		listening = {}
	}
end

---@param name string
---@param args table?
function E2Lib.triggerEvent(name, args)
	assert(E2Lib.Env.Events[name], "E2Lib.triggerEvent on nonexisting event: '" .. name .. "'")

	for ent in pairs(E2Lib.Env.Events[name].listening) do
		if ent.ExecuteEvent then
			ent:ExecuteEvent(name, args)
		else -- Destructor somehow wasn't run?
			E2Lib.Env.Events[name].listening[ent] = nil
		end
	end
end

---@param name string
---@param args table
---@param ignore table<Entity, true>
function E2Lib.triggerEventOmit(name, args, ignore)
	assert(E2Lib.Env.Events[name], "E2Lib.triggerEventOmit on nonexisting event: '" .. name .. "'")

	for ent in pairs(E2Lib.Env.Events[name].listening) do
		if not ignore[ent] then -- Don't trigger ignored chips
			if ent.ExecuteEvent then
				ent:ExecuteEvent(name, args)
			else -- Destructor somehow wasn't run?
				E2Lib.Env.Events[name].listening[ent] = nil
			end
		end
	end
end

-- ---------------------------------------------------------------

-- Load clientside files here
-- Serverside files are instead loaded in extloader.lua, because they need additional parsing
do
	local function loadFiles( extra, list )
		for _, filename in pairs(list) do
			if SERVER then AddCSLuaFile("entities/gmod_wire_expression2/core/" .. extra .. filename)
			else include("entities/gmod_wire_expression2/core/" .. extra .. filename) end
		end
	end

	loadFiles("custom/",file.Find("entities/gmod_wire_expression2/core/custom/cl_*.lua", "LUA"))
	loadFiles("",file.Find("entities/gmod_wire_expression2/core/cl_*.lua", "LUA"))
end

local E2FunctionQueue = WireLib.NetQueue("e2_functiondata")
local E2FUNC_SENDMISC, E2FUNC_SENDFUNC, E2FUNC_DONE = 0, 1, 2
if SERVER then
	-- Serverside files are loaded in extloader
	include("extloader.lua")

	-- -- Transfer E2 function info to the client for validation and syntax highlighting purposes -- --

	local miscdata = {} -- Will contain {E2 types info, constants}, this whole table is under 1kb
	local functiondata = {} -- Will contain {functionname = {returntype, cost, argnames, extension}, this will be between 50-100kb

	-- Fills out the above two tables
	function wire_expression2_prepare_functiondata()
		-- Sanitize events so 'listening' e2's aren't networked
		local events_sanitized = {}
		for evt, data in pairs(E2Lib.Env.Events) do
			events_sanitized[evt] = {
				name = data.name,
				args = data.args
			}
		end

		local types = {}
		for typename, v in pairs(wire_expression_types) do
			types[typename] = v[1] -- typeid (s)
		end

		miscdata = { types, wire_expression2_constants, events_sanitized }
		functiondata = {}

		for signature, v in pairs(wire_expression2_funcs) do
			functiondata[signature] = { v[2], v[4], v.argnames, v.extension, v.attributes } -- ret (s), cost (n), argnames (t), extension (s), attributes (t)
		end
	end

	wire_expression2_prepare_functiondata()

	-- Send everything
	local function sendData(ply)
		if not (IsValid(ply) and ply:IsPlayer()) then return end

		local queue = E2FunctionQueue.plyqueues[ply]
		queue:add(function()
			net.WriteUInt(E2FUNC_SENDMISC, 8)
			net.WriteTable(miscdata[1])
			net.WriteTable(miscdata[2])
			net.WriteTable(miscdata[3])
		end)
		for signature, tab in pairs(functiondata) do
			queue:add(function()
				net.WriteUInt(E2FUNC_SENDFUNC, 8)
				net.WriteString(signature) -- The function signature ["holoAlpha(nn)"]
				net.WriteString(tab[1]) -- The function's return type ["s"]
				net.WriteUInt(tab[2] or 0, 16) -- The function's cost [5]
				net.WriteTable(tab[3] or {}) -- The function's argnames table (if a table isn't set, it'll just send a 1 byte blank table)
				net.WriteString(tab[4] or "unknown")
				net.WriteTable(tab[5] or {}) -- Attributes
			end)
		end
		queue:add(function()
			net.WriteUInt(E2FUNC_DONE, 8)
		end)
		E2FunctionQueue:flushQueue(ply, queue)
	end

	local antispam = WireLib.RegisterPlayerTable()
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

elseif CLIENT then

	e2_function_data_received = nil
	-- -- Receive E2 function info from the server for validation and syntax highlighting purposes -- --

	wire_expression2_reset_extensions()

	local function insertData(signature, ret, cost, argnames, extension, attributes)
		local fname = signature:match("^([^(:]+)%(")
		if fname then
			wire_expression2_funclist[fname] = true
			wire_expression2_funclist_lowercase[fname:lower()] = fname
		end
		if table.IsEmpty(argnames) then argnames = nil end -- If the function has no argnames table, the server will just send a blank table
		wire_expression2_funcs[signature] = { signature, ret, false, cost, argnames = argnames, extension = extension, attributes = attributes }
	end

	local function doneInsertingData()
		e2_function_data_received = true

		if wire_expression2_editor then
			wire_expression2_editor:Validate(false)

			-- Update highlighting on all tabs
			for i = 1, wire_expression2_editor:GetNumTabs() do
				wire_expression2_editor:GetEditor(i).PaintRows = {}
			end
		end
	end

	---@param events table<string, {name: string, args: { placeholder: string, type: string }[]}>
	local function insertMiscData(types, constants, events)
		wire_expression2_reset_extensions()

		-- types
		for typename, typeid in pairs(types) do
			wire_expression_types[typename] = { typeid }
			wire_expression_types2[typeid] = { typename }
		end

		-- constants
		wire_expression2_constants = constants
		E2Lib.Env.Events = events
	end

	function E2FunctionQueue.receivecb()
		local state = net.ReadUInt(8)
		if state==E2FUNC_SENDFUNC then
			insertData(net.ReadString(), net.ReadString(), net.ReadUInt(16), net.ReadTable(), net.ReadString(), net.ReadTable())
		elseif state==E2FUNC_SENDMISC then
			insertMiscData(net.ReadTable(), net.ReadTable(), net.ReadTable())
		elseif state==E2FUNC_DONE then
			doneInsertingData()
		end
	end
end

-- this file just generates the docs so it doesn't need to run every time.
-- uncomment this line or use an openscript concmd if you want to generate docs
-- include("e2doc.lua")

if SERVER then
	include("e2tests.lua")
end
