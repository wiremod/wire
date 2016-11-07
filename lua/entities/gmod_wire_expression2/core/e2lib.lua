AddCSLuaFile()

E2Lib = {}

local type = type
local function checkargtype(argn, value, argtype)
	if type(value) ~= argtype then error(string.format("bad argument #%d to 'E2Lib.%s' (%s expected, got %s)", argn, debug.getinfo(2, "n").name, argtype, type(text)), 2) end
end

---------------------------- Helper functions -----------------------------
local unpack = unpack

-- This functions should not be used in functions that tend to be used very often, as it is slower than getting the arguments manually.
function E2Lib.getArguments(self, args)
	local ret = {}
	for i = 2, #args[7] + 1 do
		ret[i - 1] = args[i][1](self, args[i])
	end
	return unpack(ret)
end

function E2Lib.isnan(n)
	return n ~= n
end
local isnan = E2Lib.isnan

-- This function clamps the position before moving the entity
local minx, miny, minz = -16384, -16384, -16384
local maxx, maxy, maxz = 16384, 16384, 16384
local clamp = math.Clamp
function E2Lib.clampPos(pos)
	pos.x = clamp(pos.x, minx, maxx)
	pos.y = clamp(pos.y, miny, maxy)
	pos.z = clamp(pos.z, minz, maxz)
	return pos
end

function E2Lib.setPos(ent, pos)
	if isnan(pos.x) or isnan(pos.y) or isnan(pos.z) then return end
	return ent:SetPos(E2Lib.clampPos(pos))
end

local huge, abs = math.huge, math.abs
function E2Lib.setAng(ent, ang)
	if isnan(ang.pitch) or isnan(ang.yaw) or isnan(ang.roll) then return end
	if abs(ang.pitch) == huge or abs(ang.yaw) == huge or abs(ang.roll) == huge then return false end -- SetAngles'ing inf crashes the server
	return ent:SetAngles(ang)
end

-- getHash
-- Returns a hash for the given string

--local str_byte = string.byte
--local str_sub = string.sub
local util_CRC = util.CRC
local tonumber = tonumber
function E2Lib.getHash(self, data)
	--[[
	-- Thanks to emspike for this code
	self.prf = self.prf + #data
	local a, b = 1, 0
	for i = 1, #data do
			a = (a + str_byte(str_sub(data,i,i))) % 65521
			b = (b + a) % 65521
	end
	return b << 16 | a
	-- but we're going to use Garry's function, since it's most likely done in C++, so it's probably faster.
	-- For some reason, Garry's util.CRC returns a string... but it's always a number, so tonumbering it should work.
	-- I'm making it default to -1 if it for some reason throws a letter in there, breaking tonumber.
	]] --

	if self then self.prf = self.prf + #data / 10 end
	return tonumber(util_CRC(data)) or -1
end

---------------------------- signature generation -----------------------------

function E2Lib.typeName(typeid)
	if typeid == "" then return "void" end
	if typeid == "n" then return "number" end

	local tp = wire_expression_types2[typeid]
	if not tp then error("Type ID '" .. typeid .. "' not found", 2) end

	local typename = tp[1]:lower()
	return typename or "unknown"
end

function E2Lib.splitType(args)
	local ret = {}
	local thistype
	local i = 1
	while i <= #args do
		local letter = args:sub(i, i)
		if letter == ":" then
			if #ret ~= 1 then error("Misplaced ':' in args", 2) end
			thistype = ret[1]
			ret = {}
		elseif letter == "." then
			if args:sub(i) ~= "..." then error("Misplaced '.' in args", 2) end
			table.insert(ret, "...")
			i = i + 2
		elseif letter == "=" then
			if #ret ~= 1 then error("Misplaced '=' in args", 2) end
			ret = {}
		else
			local typeid = letter
			if letter == "x" then
				typeid = args:sub(i, i + 2)
				i = i + 2
			end
			table.insert(ret, E2Lib.typeName(typeid))
		end
		i = i + 1
	end
	return thistype, ret
end

-- given a function signature like "setNumber(xwl:sn)" and an optional return typeid, generates a nice, readable signature
function E2Lib.generate_signature(signature, rets, argnames)
	local funcname, args = string.match(signature, "([^(]+)%(([^)]*)%)")
	if not funcname then error("malformed signature") end

	local thistype, args = E2Lib.splitType(args)

	if argnames then
		for i = 1, #args do
			if argnames[i] then args[i] = args[i] .. " " .. argnames[i] end
		end
	end
	local new_signature = string.format("%s(%s)", funcname, table.concat(args, ","))
	if thistype then new_signature = thistype .. ":" .. new_signature end

	return (not rets or rets == "") and (new_signature) or (E2Lib.typeName(rets) .. "=" .. new_signature)
end

-------------------------- various entity checkers ----------------------------

-- replaces an E2Lib function (ex.: isOwner) and notifies plugins
function E2Lib.replace_function(funcname, func)
	checkargtype(1, funcname, "string")
	checkargtype(2, func, "function")

	local oldfunc = E2Lib[funcname]
	if not isfunction(oldfunc) then error("No E2Lib function by the name " .. funcname .. " found.", 2) end
	E2Lib[funcname] = func
	wire_expression2_CallHook("e2lib_replace_function", funcname, func, oldfunc)
end

function E2Lib.validPhysics(entity)
	if IsValid(entity) then
		if entity:IsWorld() then return false end
		if entity:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
		return entity:GetPhysicsObject():IsValid()
	end
	return false
end

function E2Lib.getOwner(self, entity)
	if entity == nil then return end
	if entity == self.entity or entity == self.player then return self.player end
	if entity.GetPlayer then
		local ply = entity:GetPlayer()
		if IsValid(ply) then return ply end
	end

	local OnDieFunctions = entity.OnDieFunctions
	if OnDieFunctions then
		if OnDieFunctions.GetCountUpdate then
			if OnDieFunctions.GetCountUpdate.Args then
				if OnDieFunctions.GetCountUpdate.Args[1] then return OnDieFunctions.GetCountUpdate.Args[1] end
			end
		end
		if OnDieFunctions.undo1 then
			if OnDieFunctions.undo1.Args then
				if OnDieFunctions.undo1.Args[2] then return OnDieFunctions.undo1.Args[2] end
			end
		end
	end

	if entity.GetOwner then
		local ply = entity:GetOwner()
		if IsValid(ply) then return ply end
	end

	return nil
end

function E2Lib.abuse(ply)
	ply:Kick("Be good and don't abuse -- sincerely yours, the E2")
	error("abuse", 0)
end

function E2Lib.isFriend(owner, player)
	return owner == player
end

function E2Lib.isOwner(self, entity)
	if game.SinglePlayer() then return true end
	local player = self.player
	local owner = getOwner(self, entity)
	if not IsValid(owner) then return false end

	return E2Lib.isFriend(owner, player)
end

local isOwner = E2Lib.isOwner

-- Checks whether the player is the chip's owner or in a pod owned by the chip's owner. Assumes that ply is really a player.
function E2Lib.canModifyPlayer(self, ply)
	if ply == self.player then return true end

	if not IsValid(ply) then return false end
	if not ply:IsPlayer() then return false end

	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then return false end
	return isOwner(self, vehicle)
end

-------------------------- type guessing ------------------------------------------

local type_lookup = {
	number = "n",
	string = "s",
	Vector = "v",
	PhysObj = "b",
}
local table_length_lookup = {
	[2] = "xv2",
	[3] = "v",
	[4] = "xv4",
	[9] = "m",
	[16] = "xm4",
}

function E2Lib.guess_type(value)
	if IsValid(value) then return "e" end
	if value.EntIndex then return "e" end
	local vtype = type(v)
	if type_lookup[vtype] then return type_lookup[vtype] end
	if vtype == "table" then
		if table_length_lookup[#v] then return table_length_lookup[#v] end
		if v.HitPos then return "xrd" end
	end

	for typeid, v in pairs(wire_expression_types2) do
		if v[5] then
			local ok = pcall(v[5], value)
			if ok then return typeid end
		end
	end

	-- TODO: more type guessing here

	return "" -- empty string = unknown type, for now.
end

-- Types that cannot possibly be guessed correctly:
-- angle (will be reported as vector)
-- matrix2 (will be reported as vector4)
-- wirelink (will be reported as entity)
-- complex (will be reported as vector2)
-- quaternion (will be reported as vector4)
-- all kinds of nil stuff

-------------------------- list filtering -------------------------------------------------

local Debug = false
local cPrint
if Debug then
	if not console then require("console") end -- only needed if you want fancy-colored output.
	function cPrint(color, text) Msg(text) end

	if console and console.Print then cPrint = console.Print end
end

function E2Lib.filterList(list, criterion)
	local index = 1
	-- if Debug then print("-- filterList: "..#list.." entries --") end

	while index <= #list do
		if not criterion(list[index]) then
			-- if Debug then cPrint(Color(128,128,128), "-    "..tostring(list[index]).."\n") end
			list[index] = list[#list]
			table.remove(list)
		else
			-- if Debug then print(string.format("+%3d %s", index, tostring(list[index]))) end
			index = index + 1
		end
	end

	-- if Debug then print("--------") end
	return list
end

------------------------------- compiler stuf ---------------------------------

E2Lib.optable_inv = {
	add = "+",
	sub = "-",
	mul = "*",
	div = "/",
	mod = "%",
	exp = "^",
	ass = "=",
	aadd = "+=",
	asub = "-=",
	amul = "*=",
	adiv = "/=",
	inc = "++",
	dec = "--",
	eq = "==",
	neq = "!=",
	lth = "<",
	geq = ">=",
	leq = "<=",
	gth = ">",
	band = "&&",
	bor = "||",
	bxor = "^^",
	bshr = ">>",
	bshl = "<<",
	["not"] = "!",
	["and"] = "&",
	["or"] = "|",
	qsm = "?",
	col = ":",
	def = "?:",
	com = ",",
	lpa = "(",
	rpa = ")",
	lcb = "{",
	rcb = "}",
	lsb = "[",
	rsb = "]",
	dlt = "$",
	trg = "~",
	imp = "->",
	fea = "foreach",
}

E2Lib.optable = {}
for token, op in pairs(E2Lib.optable_inv) do
	local current = E2Lib.optable
	for i = 1, #op do
		local c = op:sub(i, i)
		local nxt = current[c]
		if not nxt then
			nxt = {}
			current[c] = nxt
		end

		if i == #op then
			nxt[1] = token
		else
			if not nxt[2] then
				nxt[2] = {}
			end

			current = nxt[2]
		end
	end
end

function E2Lib.printops()
	local op_order = { ["+"] = 1, ["-"] = 2, ["*"] = 3, ["/"] = 4, ["%"] = 5, ["^"] = 6, ["="] = 7, ["!"] = 8, [">"] = 9, ["<"] = 10, ["&"] = 11, ["|"] = 12, ["?"] = 13, [":"] = 14, [","] = 15, ["("] = 16, [")"] = 17, ["{"] = 18, ["}"] = 19, ["["] = 20, ["]"] = 21, ["$"] = 22, ["~"] = 23 }
	print("E2Lib.optable = {")
	for k, v in pairs_sortkeys(E2Lib.optable, function(a, b) return (op_order[a] or math.huge) < (op_order[b] or math.huge) end) do
		local tblstring = table.ToString(v)
		tblstring = tblstring:gsub(",}", "}")
		tblstring = tblstring:gsub("{(.)=", " {[\"%1\"] = ")
		tblstring = tblstring:gsub(",(.)=", ", [\"%1\"] = ")
		print(string.format("\t[%q] = %s,", k, tblstring))
	end
	print("}")
end

-------------------------------- string stuff ---------------------------------

-- limits the given string to the given length and adds "..." to the end if too long.
function E2Lib.limitString(text, length)
	checkargtype(1, text, "string")
	checkargtype(2, length, "number")

	if #text <= length then
		return text
	else
		return string.sub(text, 1, length) .. "..."
	end
end

do
	local enctbl = {}
	local dectbl = {}

	do
		-- generate encode/decode lookup tables
		-- local valid_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 +-*/#^!?~=@&|.,:(){}[]<>" -- list of "normal" chars that can be transferred without problems
		local invalid_chars = "'\"\n\\%"
		local hex = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' }


		for i = 1, #invalid_chars do
			local char = invalid_chars:sub(i, i)
			enctbl[char] = true
		end
		for byte = 1, 255 do
			dectbl[hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1]] = string.char(byte)
			if enctbl[string.char(byte)] then
				enctbl[string.char(byte)] = "%" .. hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1]
			else
				enctbl[string.char(byte)] = string.char(byte)
			end
		end

		--for i = 1, #valid_chars do
		--	local char = valid_chars:sub(i, i)
		--	enctbl[char] = char
		--end
	end

	-- escapes special characters
	function E2Lib.encode(str)
		return str:gsub(".", enctbl)
	end

	-- decodes escaped characters
	function E2Lib.decode(encoded)
		return encoded:gsub("%%(..)", dectbl)
	end
end

--------------------------------- extensions ----------------------------------

do
	-- Shared stuff, defined later.
	
	local extensions = nil
	local function printExtensions() end
	local function conCommandSetExtensionStatus() end

	function E2Lib.GetExtensions()
		return extensions.list
	end

	function E2Lib.GetExtensionStatus(name)
		name = name:Trim():lower()
		return extensions.status[name]
	end

	function E2Lib.GetExtensionDocumentation(name)
		return extensions.documentation[name] or {}
	end
	
	if SERVER then -- serverside stuff
		
		util.AddNetworkString( "wire_expression2_server_send_extensions_list" )
		util.AddNetworkString( "wire_expression2_client_request_print_extensions" )
		util.AddNetworkString( "wire_expression2_client_request_set_extension_status" )

		function wire_expression2_PreLoadExtensions()
			hook.Run( "Expression2_PreLoadExtensions" )
			extensions = { status = {}, list = {}, prettyList = {}, documentation = {} }
			local list = sql.Query( "SELECT * FROM wire_expression2_extensions" )
			if list then
				for i = 1, #list do
					local row = list[ i ]
					E2Lib.SetExtensionStatus( row.name, row.enabled )
				end
			else
				sql.Query( "CREATE TABLE wire_expression2_extensions ( name VARCHAR(32) PRIMARY KEY, enabled BOOLEAN )" )
			end
			extensions.save = true
		end

		function E2Lib.RegisterExtension(name, default, description, warning)
			name = name:Trim():lower()
			if extensions.status[ name ] == nil then
				E2Lib.SetExtensionStatus( name, default )
			end
			extensions.list[ #extensions.list + 1 ] = name

			if description or warning then
				extensions.documentation[name] = { Description = description, Warning = warning }
			end

			-- This line shouldn't be modified because it tells the parser that this extension is disabled,
			-- thus making its functions not available in the E2 Editor (see function e2_include_pass2 in extloader.lua).
			assert( extensions.status[ name ], "EXTENSION_DISABLED" )
		end
		
		function E2Lib.SetExtensionStatus( name, status )
			name = name:Trim():lower()
			status = tobool( status )
			extensions.status[ name ] = status
			if extensions.save then
				sql.Query( "REPLACE INTO wire_expression2_extensions ( name, enabled ) VALUES ( " .. sql.SQLStr( name ) .. ", " .. ( status and 1 or 0 ) .. " )" )
			end
		end
		
		-- After using E2Lib.SetExtensionStatus in an external script, this function should be called.
		-- Its purpose is to update the clientside autocomplete list for the concommands.
		function E2Lib.UpdateClientsideExtensionsList( ply )
			net.Start( "wire_expression2_server_send_extensions_list" )
			net.WriteTable(extensions)
			if IsValid( ply ) then
				net.Send( ply )
			else
				net.Broadcast()
			end
		end
		
		local function buildPrettyList()
			local function padLeft( str, len ) return (" "):rep( len - #str ) .. str end
			local function padRight( str, len ) return str .. (" "):rep( len - #str ) end
			local function padCenter( str, len ) return padRight( padLeft( str, math.floor( (len + #str) / 2 ) ), len ) end
			
			local list, column1, column2, columnsWidth = extensions.list, {}, {}, 0
			for i = 1, #list do
				local name = list[ i ]
				if #name > columnsWidth then columnsWidth = #name end
				if extensions.status[ name ] == true then column1[ #column1 + 1 ] = name else column2[ #column2 + 1 ] = name end
			end
			local mainTitle, column1Title, column2Title = "E2 EXTENSIONS", "ENABLED", "DISABLED"
			local maxWidth, maxRows = math.max( columnsWidth * 2, #column1Title + #column2Title, #mainTitle - 3 ), math.max( #column1, #column2 )
			if maxWidth % 2 ~= 0 then maxWidth = maxWidth + 1 end
			columnsWidth = maxWidth / 2
			maxWidth = maxWidth + 3
			local delimiter =  " +-" .. ("-"):rep( columnsWidth ) .. "-+-" .. ("-"):rep( columnsWidth ) .. "-+"
			
			list =
			{
				" +-" .. ("-"):rep( maxWidth ) .. "-+",
				" | " .. padCenter( mainTitle, maxWidth ) .. " |",
				delimiter,
				" | " .. padCenter( column1Title, columnsWidth ) .. " | " .. padCenter( column2Title, columnsWidth ) .. " |",
				delimiter,
			}
			for i = 1, maxRows do list[ #list + 1 ] = " | " .. padRight( column1[ i ] or "", columnsWidth ) .. " | " .. padRight( column2[ i ] or "", columnsWidth ) .. " |" end
			list[ #list + 1 ] = delimiter
			
			extensions.prettyList = list
		end
		
		function printExtensions( ply, str )
			if IsValid( ply ) then
				if str then ply:PrintMessage( 2, str ) end
				for i = 1, #extensions.prettyList do ply:PrintMessage( 2, extensions.prettyList[ i ] ) end
			else
				if str then print( str ) end
				for i = 1, #extensions.prettyList do print( extensions.prettyList[ i ] ) end
			end
		end
		
		function conCommandSetExtensionStatus( ply, cmd, args )
			if IsValid( ply ) and not ply:IsSuperAdmin() and not game.SinglePlayer() then
				ply:PrintMessage( 2, "Sorry " .. ply:Name() .. ", you don't have access to this command." )
				return
			end
			local name = args[ 1 ]
			if name then
				name = name:Trim():lower()
				if extensions.status[ name ] ~= nil then
					local status = tobool( cmd:find( "enable" ) )
					if extensions.status[ name ] == status then
						local str = "Extension '" .. name .. "' is already " .. ( status and "enabled" or "disabled" ) .. "."
						if IsValid( ply ) then ply:PrintMessage( 2, str ) else print( str ) end
					else
						E2Lib.SetExtensionStatus( name, status )
						E2Lib.UpdateClientsideExtensionsList()
						local str = "E2 Extension '" .. name .. "' has been " .. ( status and "enabled" or "disabled" )
						if not game.SinglePlayer() and IsValid( ply ) then MsgN( str .. " by " .. ply:Name() .. " (" .. ply:SteamID() .. ")." ) end
						local canReloadNow = #player.GetAll() == 0
						if canReloadNow then str = str .. ". Expression 2 will be reloaded now."  else str = str .. ". Expression 2 will be reloaded in 10 seconds." end
						if IsValid( ply ) then ply:PrintMessage( 2, str ) else print( str ) end
						if canReloadNow then wire_expression2_reload( ply ) else timer.Create( "E2_AutoReloadTimer", 10, 1, function() wire_expression2_reload( ply ) end ) end
					end
				else printExtensions( ply, "Unknown extension '" .. name .. "'. Here is a list of available extensions:" ) end
			else printExtensions( ply, "Usage: '" .. cmd .. " <name>'. Here is a list of available extensions:" ) end
		end
		
		net.Receive( "wire_expression2_client_request_print_extensions",
			function( _, ply )
				printExtensions( ply )
			end
		)
		
		net.Receive( "wire_expression2_client_request_set_extension_status",
			function( _, ply )
				conCommandSetExtensionStatus( ply, net.ReadString(), net.ReadTable() )
			end
		)
		
		hook.Add( "PlayerInitialSpawn", "wire_expression2_updateClientsideExtensions", E2Lib.UpdateClientsideExtensionsList )
		
		function wire_expression2_PostLoadExtensions()
			table.sort( extensions.list, function( a, b ) return a < b end )
			E2Lib.UpdateClientsideExtensionsList()
			buildPrettyList()
			if not wire_expression2_is_reload then -- only print once on startup, not on each reload.
				printExtensions()
			end
			hook.Run( "Expression2_PostLoadExtensions" )
		end
		
	else -- clientside stuff

		extensions = { status = {}, list = {} }
			
		function printExtensions()
			net.Start( "wire_expression2_client_request_print_extensions" )
			net.SendToServer()
		end
		
		function conCommandSetExtensionStatus( _, cmd, args )
			net.Start( "wire_expression2_client_request_set_extension_status" )
			net.WriteString( cmd )
			net.WriteTable( args )
			net.SendToServer()
		end

		net.Receive( "wire_expression2_server_send_extensions_list", function()
			extensions = net.ReadTable()
		end)
		
	end

	-- shared stuff
	
	local function makeAutoCompleteList( cmd, args )
		args = args:Trim():lower()
		local status, list, tbl, j = tobool( cmd:find( "enable" ) ), extensions.list, {}, 1
		for i = 1, #list do
			local name = list[ i ]
			if extensions.status[ name ] ~= status and name:find( args ) then
				tbl[ j ] = cmd .. " " .. name
				j = j + 1
			end
		end
		return tbl
	end

	concommand.Add( "wire_expression2_extension_enable", conCommandSetExtensionStatus, makeAutoCompleteList )
	concommand.Add( "wire_expression2_extension_disable", conCommandSetExtensionStatus, makeAutoCompleteList )
	concommand.Add( "wire_expression2_extensions", function( ply ) printExtensions( ply ) end )

end

-------------------------- clientside reload command --------------------------

do
	if SERVER then
	
		util.AddNetworkString( "wire_expression2_client_request_reload" )
		net.Receive( "wire_expression2_client_request_reload",
			function( n, ply )
				wire_expression2_reload( ply )
			end
		)
		
	else
	
		local function wire_expression2_reload()
			net.Start( "wire_expression2_client_request_reload" )
			net.SendToServer()
		end
		
		concommand.Add( "wire_expression2_reload", wire_expression2_reload )
		
	end
	
end

-------------------------------- compatibility --------------------------------

-- Some functions need to be global for backwards-compatibility.
local makeglobal = {
	["validPhysics"] = true,
	["getOwner"] = true,
	["isOwner"] = true,
}

-- Put all these functions into the global scope.
for funcname, _ in pairs(makeglobal) do
	_G[funcname] = E2Lib[funcname]
end

hook.Add("InitPostEntity", "e2lib", function()
-- If changed, put them into the global scope again.
	registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
		if makeglobal[funcname] then
			_G[funcname] = func
		end
		if funcname == "IsValid" then IsValid = func
		elseif funcname == "isOwner" then isOwner = func
		end
	end)

	-- check for a CPPI compliant plugin
	if SERVER and CPPI then
		if debug.getregistry().Player.CPPIGetFriends then
			E2Lib.replace_function("isFriend", function(owner, player)
				if owner == nil then return false end
				if owner == player then return true end

				local friends = owner:CPPIGetFriends()
				if not istable(friends) then return end

				for _, friend in pairs(friends) do
					if player == friend then return true end
				end

				return false
			end)
		end

		if debug.getregistry().Entity.CPPIGetOwner then
			local _getOwner = E2Lib.getOwner
			E2Lib.replace_function("getOwner", function(self, entity)
				if entity == self.entity or entity == self.player then return self.player end

				local owner = entity:CPPIGetOwner()
				if IsValid(owner) then return owner end

				return _getOwner(self, entity)
			end)
		end
	end
end)
