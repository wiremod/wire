AddCSLuaFile("init.lua")

/******************************************************************************\
  Expression 2 for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

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

-- TODO: combine with makecheck
local function namefunc(func, name)
	name = "e2_"..name:gsub("[^A-Za-z_0-9]","_")

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
	return ret
end

-- Installs a typecheck in a function identified by the given signature.
local function makecheck(signature)
	local name = signature:match("^([^(]*)")
	local entry = wire_expression2_funcs[signature]
	local oldfunc,signature, rets, func,cost = entry.oldfunc,unpack(entry)

	if oldfunc then return end
	oldfunc = namefunc(func, name)

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
			[5] = function(retval) if retval ~= nil then error("Return value of void function is not nil.",0) end end
		}
	}
	wire_expression2_funcs = {}
	wire_expression2_funclist = {}
	if CLIENT then wire_expression2_funclist_lowercase = {} end
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
		ok, ret = pcall(callback, ...)
		if not ok then
			if ret == "cancelhook" then break end
			table.insert(errors, "\n"..ret)
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

	wire_expression2_constants[name] = value
end

/******************************************************************************/

if SERVER then
	if VERSION >= 150 then
		util.AddNetworkString("e2st")
		util.AddNetworkString("e2se")
	end

	local clientside_files = {}

	function AddCSE2File(filename)
		AddCSLuaFile(filename)
		clientside_files[filename] = true
	end
	include("extloader.lua")

	-- -- Transfer E2 function info to the client for validation and syntax highlighting purposes -- --

	function _R.CRecipientFilter.IsValid() return true end -- workaround for this bug: http://www.facepunch.com/showpost.php?p=15117600 - thanks Lexi

	do
		if (!glon) then require("glon") end -- Doubt this will be necessary, but still

		local functiondata,functiondata2
		local functiondata_buffer, functiondata2_buffer, clientside_files_buffer = {}, {}, {}

		-- prepares a table with information (no, a glon string! - edit by Divran) about E2 types and functions
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

			local maxPacketSize =  VERSION < 150 and 245 or 63999

			-- Add functiondata to buffer
			local temp = glon.encode( functiondata )
			functiondata_buffer = {}
			for i=1,#temp,maxPacketSize do
				functiondata_buffer[#functiondata_buffer+1] = temp:sub(i,i+maxPacketSize-1)
			end

			-- Add functiondata2 to buffer
			local temp = glon.encode( functiondata2 )
			functiondata2_buffer = {}
			for i=1,#temp,maxPacketSize do
				functiondata2_buffer[#functiondata2_buffer+1] = temp:sub(i,i+maxPacketSize-1)
			end

			-- Clientside file buffer (for initial spawn only)
			local temp = {}
			for k,v in pairs( clientside_files ) do temp[#temp+1] = k end
			temp = glon.encode( temp )
			clientside_files_buffer = {}
			for i=1,#temp,maxPacketSize do
				clientside_files_buffer[#clientside_files_buffer+1] = temp:sub(i,i+maxPacketSize-1)
			end
		end

		wire_expression2_prepare_functiondata()

		local sendClientsideFilesList

		-- Send everything
		local targets = {}
		local function sendData( target )
			if (type(target) == "table") then
				for k,v in pairs( target ) do
					if (type(v) == "Player") then
						sendData( v )
					end
				end
				return
			end
			if (target and type(target) == "Player" and target:IsValid() and targets[target] == nil) then
				targets[target] = { 1, 0 }
				if VERSION >= 150 then
					net.Start("e2st")
						net.WriteUInt( #functiondata_buffer + #functiondata2_buffer, 64 )
					net.Send(target)
				else
					umsg.Start("e2st",target) umsg.Short( #functiondata_buffer + #functiondata2_buffer ) umsg.End()
					timer.Remove( "wire_expression2_clientside_files_list_send_" .. target:UniqueID() )
				end
			end
		end

		if VERSION < 150 then
			-- Send only CL file list
			function sendClientsideFilesList( target )
				if type(target) == "table" then
					for k,v in pairs( target ) do
						if type(v) == "Player" then
							sendCLientsideFilesList( v )
						end
					end
					return
				elseif target and type(target) == "Player" and target:IsValid() and not timer.Exists( "wire_expression2_clientside_files_list_send_" .. target:UniqueID() ) then
					local uid = target:UniqueID()
					local i = 0
					umsg.Start("e2fs",target) umsg.Short( #clientside_files_buffer ) umsg.End()
					timer.Create( "wire_expression2_clientside_files_list_send_" .. uid, 0, 0,function()
						if not target or not target:IsValid() then
							timer.Remove( "wire_expression2_clientside_files_list_send_" .. uid )
							return
						end

						i = i + 1
						umsg.Start( "e2fd", target )
							umsg.String( clientside_files_buffer[i] )
						umsg.End()
						if i == #clientside_files_buffer then
							umsg.Start( "e2fe", target ) umsg.End()
							timer.Remove( "wire_expression2_clientside_files_list_send_" .. uid )
						end
					end)
				end
			end
		end

		hook.Remove("Think","wire_expression2_sendfunctions_think") -- Remove the old hook
		hook.Add("Think","wire_expression2_sendfunctions_think",function()
			for k,v in pairs( targets ) do
				if (!k:IsValid() or !k:IsPlayer() or v[1] == 3) then
					targets[k] = nil
				elseif (v[1] == 1) then -- functiondata
					v[2] = v[2] + 1
					if VERSION >= 150 then
						net.Start("e2se")
							net.WriteString( functiondata_buffer[v[2]] )
							if (v[2] == #functiondata_buffer) then
								net.WriteInt(1,8) -- Done with functiondata nr 1
								v[1] = 2
								v[2] = 0
							else
								net.WriteInt(0,8) -- We're not done yet
							end
						net.Send(k)
					else
						umsg.Start("e2sd",k) umsg.String( functiondata_buffer[v[2]] ) umsg.End()
						if (v[2] == #functiondata_buffer) then
							umsg.Start("e2se",k) umsg.Bool(false) umsg.End()
							v[1] = 2
							v[2] = 0
						end
					end
				elseif (v[1] == 2) then -- functiondata2
					v[2] = v[2] + 1
					if VERSION >= 150 then
						net.Start("e2se")
							net.WriteString( functiondata2_buffer[v[2]] )

							if (v[2] == #functiondata2_buffer) then

								net.WriteInt(2,8) -- Done with functiondata nr 2

								v[1] = 3
								v[2] = 0
							else
								net.WriteInt(0,8) -- We're not done yet
							end

						net.Send(k)
					else
						umsg.Start("e2sd",k) umsg.String( functiondata2_buffer[v[2]] ) umsg.End()
						if (v[2] == #functiondata2_buffer) then
							umsg.Start("e2se",k) umsg.Bool(true) umsg.End()
							v[1] = 3
							v[2] = 0
						end
					end
				end
			end
		end)

		local antispam = {}
		function wire_expression2_sendfunctions(ply,isconcmd)
			if (isconcmd) then
				if (!antispam[ply]) then antispam[ply] = 0 end
				if (antispam[ply] > CurTime()) then
					ply:PrintMessage(HUD_PRINTCONSOLE,"This command has a 60 second anti spam protection. Try again in " .. math.Round(antispam[ply] - CurTime()) .. " seconds.")
					return
				end
				antispam[ply] = CurTime() + 60
				sendData( ply )
			elseif (SinglePlayer()) then
				sendData( ply )
			end
		end

		-- add a console command the user can use to re-request the function info, in case of errors or updates
		concommand.Add("wire_expression2_sendfunctions", wire_expression2_sendfunctions)

		hook.Add( "PlayerInitialSpawn", "wire_expression2_sendfunctions", function( ply )
			-- If single player, send everything
			if game.SinglePlayer() then
				sendData( ply )
			else -- else send only files list
				if VERSION < 150 then
					sendClientsideFilesList( ply )
				end
			end
		end)

		-- send function info once the player first spawns (NOTE: Only in single player)
		--if game.SinglePlayer() then hook.Add("PlayerInitialSpawn", "wire_expression2_sendfunctions", wire_expression2_sendfunctions) end
	end

elseif CLIENT then

	e2_function_data_received = nil
	-- -- Receive E2 function info from the server for validation and syntax highlighting purposes -- --

	wire_expression2_reset_extensions()

	local function insertData( functiondata )
		wire_expression2_reset_extensions()

		-- types
		for typename,typeid in pairs(functiondata[1]) do
			wire_expression_types[typename] = { typeid }
			wire_expression_types2[typeid] = { typename }
		end

		-- functions
		for signature,ret in pairs(functiondata[2]) do
			local fname = signature:match("^([^(:]+)%(")
			if fname then
				wire_expression2_funclist[fname] = true
				wire_expression2_funclist_lowercase[fname:lower()] = fname
			end
			wire_expression2_funcs[signature] = { signature, ret, false }
		end

		-- includes
		for filename,_ in pairs(functiondata[3]) do
			include("entities/gmod_wire_expression2/core/"..filename)
		end

		-- constants
		wire_expression2_constants = functiondata[4]
	end
	local function insertData2( functiondata2 )
		for signature,v in pairs(functiondata2) do
			local entry = wire_expression2_funcs[signature]
			if entry then
				entry[4] = v[1] -- cost
				entry.argnames = v[2] -- argnames
			end
		end

		e2_function_data_received = true

		if wire_expression2_editor then
			wire_expression2_editor:Validate(false)

			-- Update highlighting on all tabs
			for i=1,wire_expression2_editor:GetNumTabs() do
				wire_expression2_editor:GetEditor( i ).PaintRows = {}
			end
		end
	end

	local function status( count, total_count )
		local editor = wire_expression2_editor
		if (editor and editor:IsValid() and editor:IsVisible()) then
			local percent = count/total_count
			editor:SetValidatorStatus( "Receiving extension data. Please wait... " .. math.floor(percent*100) .. "% (" .. count .. "/" .. total_count .. ")", 128-128*percent, 128*percent, 0 )
		end
	end

	local buffer = ""
	local buffer_total_count = 0
	local buffer_current_count = 0
	if VERSION >= 150 then

		net.Receive("e2st",function(len)
			buffer_total_count = net.ReadUInt(64)
			draw_progress_bar = true
			buffer_current_count = 0
			status( 0, buffer_total_count )
			buffer = ""
		end)

		net.Receive("e2se",function( len )
			local data = net.ReadString()
			buffer = buffer .. data
			buffer_current_count = buffer_current_count + 1
			status( buffer_current_count,buffer_total_count )

			local bit = net.ReadInt(8)

			if bit == 1 or bit == 2 then
				local OK, data = pcall( glon.decode, buffer )
				if (!OK) then
					ErrorNoHalt( "[E2] Failed to receive extension data. Error message was:\n" .. data )
					if wire_expression2_editor and wire_expression2_editor:IsValid() then
						wire_expression2_editor:SetValidatorStatus( "Failed to receive extension data. Error message was: " .. data )
					end
				else
					if bit == 1 then
						insertData( data )
					else
						insertData2( data )
					end
				end
			end
		end)

	else
		usermessage.Hook("e2st",function( um )
			buffer_total_count = um:ReadShort()
			draw_progress_bar = true
			buffer_current_count = 0
			status( 0, buffer_total_count )
		end)
		usermessage.Hook("e2sd",function( um )
			local str = um:ReadString()
			buffer = buffer .. str
			buffer_current_count = buffer_current_count + 1
			status( buffer_current_count, buffer_total_count )
		end)
		usermessage.Hook("e2se",function( um )
			local OK, data = pcall( glon.decode, buffer )
			if (!OK) then
				ErrorNoHalt( "[E2] Failed to receive extension data. Error message was:\n" .. data )
				if wire_expression2_editor and wire_expression2_editor:IsValid() then
					wire_expression2_editor:SetValidatorStatus( "Failed to receive extension data. Error message was: " .. data )
				end
			else
				local what = um:ReadBool()
				if (!what) then
					insertData( data )
				else
					insertData2( data )
				end
			end
			buffer = ""
		end)
	end

	if VERSION < 150 then
		-- Initial spawn file includes
		local buffer2 = ""
		usermessage.Hook( "e2fs", function( um )
			buffer2 = ""
		end)

		usermessage.Hook( "e2fd", function( um )
			local str = um:ReadString()
			buffer2 = buffer2 .. str
		end)

		usermessage.Hook( "e2fe", function( um )
			local OK, data = pcall( glon.decode, buffer2 )
			if (!OK) then
				ErrorNoHalt( "[E2] Failed to receive client side file list. Error message was:\n" .. data )
				if wire_expression2_editor and wire_expression2_editor:IsValid() then
					wire_expression2_editor:SetValidatorStatus( "Failed to receive client side file list. Error message was: " .. data )
				end
			else
				for _,filename in pairs( data ) do
					include("entities/gmod_wire_expression2/core/"..filename)
				end
			end
			buffer2 = ""
		end)
	end
end

include("e2doc.lua")
