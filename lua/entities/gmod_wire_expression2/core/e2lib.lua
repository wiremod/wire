AddCSLuaFile()

E2Lib = {
	Env = {
		---@type { name: string, args: { [1]: string, [2]: string }[], constructor: fun(t: table)?, destructor: fun(t: table)?, listening: table<userdata, boolean> }
		Events = {}
	}
}

local type = type
local function checkargtype(argn, value, argtype)
	if type(value) ~= argtype then error(string.format("bad argument #%d to 'E2Lib.%s' (%s expected, got %s)", argn, debug.getinfo(2, "n").name, argtype, type(value)), 2) end
end

-- -------------------------- Helper functions -----------------------------
local unpack = unpack
local IsValid = IsValid

-- This functions should not be used in functions that tend to be used very often, as it is slower than getting the arguments manually.
function E2Lib.getArguments(self, args)
	local ret = {}
	for i = 2, #args[7] + 1 do
		ret[i - 1] = args[i][1](self, args[i])
	end
	return unpack(ret)
end

-- Backwards compatibility
E2Lib.isnan = WireLib.isnan
E2Lib.clampPos = WireLib.clampPos
E2Lib.setPos = WireLib.setPos
E2Lib.setAng = WireLib.setAng

function E2Lib.setMaterial(ent, material)
	material = WireLib.IsValidMaterial(material)
	ent:SetMaterial(material)
	duplicator.StoreEntityModifier(ent, "material", { MaterialOverride = material })
end

function E2Lib.setSubMaterial(ent, index, material)
	index = math.Clamp(index, 0, 255)
	material = WireLib.IsValidMaterial(material)
	ent:SetSubMaterial(index, material)
	duplicator.StoreEntityModifier(ent, "submaterial", { ["SubMaterialOverride_"..index] = material })
end

-- Returns a default e2 table.
function E2Lib.newE2Table()
	return {n={},ntypes={},s={},stypes={},size=0}
end

-- Returns a cloned table of the variable given if it is a table.
-- TODO: Ditch this system for instead having users provide a function that returns the default value.
-- Would be much more efficient and avoid type checks.
local istable = istable
local table_Copy = table.Copy
function E2Lib.fixDefault(var)
	local t = type(var)
	return t == "table" and table_Copy(var)
		or t == "Vector" and Vector(var)
		or t == "Angle" and Angle(var)
		or var
end

-- getHash
-- Returns a hash for the given string

-- local str_byte = string.byte
-- local str_sub = string.sub
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

-- -------------------------- signature generation -----------------------------

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
			local slice = args:sub(i)
			if slice ~= "..." and slice ~= "..r" and slice ~= "..t" then error("Misplaced '.' in args", 2) end
			table.insert(ret, slice)
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

-- ------------------------ various entity checkers ----------------------------

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

-- This function gets wrapped when CPPI is detected, see very end of this file
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

-- This function gets replaced when CPPI is detected, see very end of this file
function E2Lib.isFriend(owner, player)
	return owner == player
end

function E2Lib.isOwner(self, entity)
	if game.SinglePlayer() then return true end
	local owner = E2Lib.getOwner(self, entity)
	if not IsValid(owner) then return false end

	return E2Lib.isFriend(owner, self.player)
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

-- ------------------------ type guessing ------------------------------------------

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
	local vtype = type(value)
	if type_lookup[vtype] then return type_lookup[vtype] end
	if IsValid(value) then return "e" end
	if value.EntIndex then return "e" end
	if vtype == "table" then
		if table_length_lookup[#value] then return table_length_lookup[#value] end
		if value.HitPos then return "xrd" end
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

-- ------------------------ list filtering -------------------------------------------------

function E2Lib.filterList(list, criterion)
	local index = 1
	-- print("-- filterList: "..#list.." entries --")

	while index <= #list do
		if not criterion(list[index]) then
			-- MsgC(Color(128,128,128), "-    "..tostring(list[index]).."\n")
			list[index] = list[#list]
			table.remove(list)
		else
			-- print(string.format("+%3d %s", index, tostring(list[index])))
			index = index + 1
		end
	end

	-- print("--------")
	return list
end

-- ----------------------------- compiler stuf ---------------------------------

-- A function suitable for use as xpcall's error handler. If the error is
-- generated by Compiler:Error, Parser:Error, etc., then the string will be a
-- usable error message. If not, then it's an error not caused by an error in
-- user code, and so we dump a stack trace to the console to help debug it.
function E2Lib.errorHandler(message)
	if string.match(message, " at line ") then return message end

	print("Internal error - please report to https://github.com/wiremod/wire/issues")
	print(message)
	debug.Trace()
	return "Internal error, see console for more details"
end

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
	dlt = "$",
	trg = "~",
	imp = "->",
	spread = "..."
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
	local op_order = { ["+"] = 1, ["-"] = 2, ["*"] = 3, ["/"] = 4, ["%"] = 5, ["^"] = 6, ["="] = 7, ["!"] = 8, [">"] = 9, ["<"] = 10, ["&"] = 11, ["|"] = 12, ["?"] = 13, [":"] = 14, ["$"] = 15, ["~"] = 16 }
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

---@enum Keyword
local Keyword = {
	-- ``if``
	If = 1,
	-- ``elseif``
	Elseif = 2,
	-- ``else``
	Else = 3,
	-- ``local``
	Local = 4,
	-- ``while``
	While = 5,
	-- ``for``
	For = 6,
	-- ``break``
	Break = 7,
	-- ``continue``
	Continue = 8,
	-- ``switch``
	Switch = 9,
	-- ``case``
	Case = 10,
	-- ``default``
	Default = 11,
	-- ``foreach``
	Foreach = 12,
	-- ``function``
	Function = 13,
	-- ``return``
	Return = 14,
	-- ``#include``
	["#Include"] = 15,
	-- ``try``
	Try = 16,
	-- ``catch``
	Catch = 17,
	-- ``do``
	Do = 18,
	-- ``event``
	Event = 19
}

E2Lib.Keyword = Keyword

---@type table<string, Keyword>
E2Lib.KeywordLookup = {}

for kw, v in pairs(Keyword) do
	E2Lib.KeywordLookup[kw:lower()] = v
end

local KeywordNames = {}
for name, val in pairs(Keyword) do
	KeywordNames[val] = name
end
E2Lib.KeywordNames = KeywordNames

---@enum Grammar
local Grammar = {
	-- {
	LCurly = 1,
	-- }
	RCurly = 2,
	-- (
	LParen = 3,
	-- )
	RParen = 4,
	-- [
	LSquare = 5,
	-- ]
	RSquare = 6,
	-- ,
	Comma = 7
}

E2Lib.Grammar = Grammar
E2Lib.GrammarLookup = {
	['{'] = Grammar.LCurly,
	['}'] = Grammar.RCurly,
	['('] = Grammar.LParen,
	[')'] = Grammar.RParen,
	['['] = Grammar.LSquare,
	[']'] = Grammar.RSquare,
	[','] = Grammar.Comma
}

local GrammarNames = {}
for name, val in pairs(Grammar) do
	GrammarNames[val] = name
end
E2Lib.GrammarNames = GrammarNames

---@enum Operator
local Operator = {
	-- `+`
	Add = 1,
	-- `-`
	Sub = 2,
	-- `*`
	Mul = 3,
	-- `/`
	Div = 4,
	-- `%`
	Mod = 5,
	-- `^`
	Exp = 6,
	-- `=`
	Ass = 7,
	-- +=
	Aadd = 8,
	-- -=
	Asub = 9,
	-- `*=`
	Amul = 10,
	-- `/=`
	Adiv = 11,
	-- `++`
	Inc = 12,
	-- `--`
	Dec = 13,
	-- `==`
	Eq = 14,
	-- `!=`
	Neq = 15,
	-- `<`
	Lth = 16,
	-- `>=`
	Geq = 17,
	-- `<=`
	Leq = 18,
	-- `>`
	Gth = 19,
	-- `&&`
	Band = 20,
	-- `||`
	Bor = 21,
	-- `^^`
	Bxor = 22,
	-- `>>`
	Bshr = 23,
	-- `<<`
	Bshl = 24,
	-- `!`
	Not = 25,
	-- `&`
	And = 26,
	-- `|`
	Or = 27,
	-- `?`
	Qsm = 28,
	-- `:`
	Col = 29,
	-- `?:`
	Def = 30,
	-- `$`
	Dlt = 31,
	-- `~`
	Trg = 32,
	-- `->`
	Imp = 33,
	-- `...`
	Spread = 34
}

E2Lib.Operator = Operator

local OperatorNames = {}
for name, val in pairs(Operator) do
	OperatorNames[val] = name
end
E2Lib.OperatorNames = OperatorNames

local OperatorLookup = {
	["+"] = Operator.Add, ["-"] = Operator.Sub, ["*"] = Operator.Mul, ["/"] = Operator.Div,
	["%"] = Operator.Mod, ["^"] = Operator.Exp, ["="] = Operator.Ass, ["+="] = Operator.Aadd,
	["-="] = Operator.Asub, ["*="] = Operator.Amul, ["/="] = Operator.Adiv, ["++"] = Operator.Inc,
	["--"] = Operator.Dec, ["=="] = Operator.Eq, ["!="] = Operator.Neq, ["<"] = Operator.Lth,
	[">="] = Operator.Geq, ["<="] = Operator.Leq, [">"] = Operator.Gth, ["&&"] = Operator.Band,
	["||"] = Operator.Bor, ["^^"] = Operator.Bxor, [">>"] = Operator.Bshr, ["<<"] = Operator.Bshl,
	["!"] = Operator.Not, ["&"] = Operator.And, ["|"] = Operator.Or, ["?"] = Operator.Qsm,
	[":"] = Operator.Col, ["?:"] = Operator.Def, ["$"] = Operator.Dlt, ["~"] = Operator.Trg,
	["->"] = Operator.Imp, ["..."] = Operator.Spread
}

E2Lib.OperatorLookup = OperatorLookup

local OperatorChars = {}
for op in pairs(OperatorLookup) do
	for i = 1, #op do
		local c = op:sub(i, i)
		OperatorChars[c] = true
	end
end

E2Lib.OperatorChars = OperatorChars

E2Lib.blocked_array_types = {
	["t"] = true,
	["r"] = true,
	["xgt"] = true
}

-- ------------------------------ string stuff ---------------------------------

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

-- ------------------------------- extensions ----------------------------------

do
	-- Shared stuff, defined later.

	local extensions, printExtensions, conCommandSetExtensionStatus

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
			E2Lib.currentextension = name

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

-- ------------------------ clientside reload command --------------------------

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

-- ------------------------------ compatibility --------------------------------

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
				if not owner:IsPlayer() then
					return player:GetOwner() == owner
				end

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
				if not IsValid(entity) then return end
				if entity == self.entity or entity == self.player then return self.player end

				local owner = entity:CPPIGetOwner()
				if IsValid(owner) then return owner end

				return _getOwner(self, entity)
			end)
		end
	end
end)

--- Valid file extensions kept to avoid trying to make files with extensions gmod doesn't allow.
-- https://wiki.facepunch.com/gmod/file.Write
local file_extensions = {
	["txt"] = true,
	["dat"] = true,
	["json"] = true,
	["xml"] = true,
	["csv"] = true,
	["jpg"] = true,
	["jpeg"] = true,
	["png"] = true,
	["vtf"] = true,
	["vmt"] = true,
	["mp3"] = true,
	["wav"] = true,
	["ogg"] = true
}

-- Returns whether the file has an extension garrysmod can write to, to avoid useless net messages, etc
function E2Lib.isValidFileWritePath(path)
	local ext = string.GetExtensionFromFilename(path)
	if ext then return file_extensions[string.lower(ext)] end
end

-- Different from Context:throw, which does not error the chip if
-- @strict is not enabled and instead returns a default value.
-- This is what Context:throw calls internally if @strict
-- By default E2 can catch these errors.
function E2Lib.raiseException(msg, level, trace, can_catch)
	error({
		catchable = (can_catch == nil) and true or can_catch,
		msg = msg,
		trace = trace
	}, level)
end

--- Unpacks either an exception object as seen above or an error string.
---@return boolean catchable
---@return string msg
---@return TokenTrace? trace
function E2Lib.unpackException(struct)
	if isstring(struct) then
		return false, struct, nil
	end
	return struct.catchable, struct.msg, struct.trace
end


--- Mimics an E2 Context as if it were really on an entity.
--- This code can probably be deduplicated but that'd needlessly complicate things, and I've made this compact enough.
---@param owner GEntity? # Owner, or assumes world
---@return ScopeManager? # Context or nil if failed
local function makeContext(owner)
	local ctx = setmetatable({
		data = {}, vclk = {}, funcs = {}, funcs_ret = {},
		entity = owner, player = owner, uid = IsValid(owner) and owner:UniqueID() or "World",
		prf = 0, prfcount = 0, prfbench = 0,
		time = 0, timebench = 0, includes = {}
	}, E2Lib.ScopeManager)

	ctx:InitScope()

	-- Construct the context to run code.
	-- If not done, 
	local ok, why = pcall(wire_expression2_CallHook, "construct", ctx)
	if not ok then
		pcall(wire_expression2_CallHook, "destruct", ctx)
	end

	return ctx
end

--- Compiles an E2 script without an entity owning it.
--- This doesn't have 1:1 behavior with an actual E2 chip existing, but is useful for testing.
---@param code string E2 Code to compile.
---@param owner GEntity? 'Owner' entity, default world.
---@return boolean success If ran successfully
---@return string|function compiled Compiled function, or error message if not success
function E2Lib.compileScript(code, owner, run)
	local status, directives, code = E2Lib.PreProcessor.Execute(code)
	if not status then return false, directives end -- Preprocessor failed.

	local status, tokens = E2Lib.Tokenizer.Execute(code)
	if not status then return false, tokens end

	local status, tree, dvars = E2Lib.Parser.Execute(tokens)
	if not status then return false, tree end

	status,tree = E2Lib.Optimizer.Execute(tree)
	if not status then return false, tree end

	local status, script, inst = E2Lib.Compiler.Execute(tree, directives.inputs, directives.outputs, directives.persist, dvars, {})
	if not status then return false, script end

	local ctx = makeContext(owner or game.GetWorld())
	if directives.strict then
		local err = E2Lib.raiseException
		function ctx:throw(msg)
			err(msg, 2, self.trace)
		end
	else
		function ctx:throw(_msg, variable)
			return variable
		end
	end

	return true, function(ctx2)
		ctx = ctx2 or ctx

		do
			-- This was originally in makeContext, but I put it here in order to ensure the owner entity
			-- Isn't polluted by these fields, so they reset each time the compiled script is used.

			ctx.entity.context = ctx
			ctx.entity.outports, ctx.entity.inports = { {}, {}, {} }, { {}, {}, {} }
			ctx.entity.GlobalScope, ctx.entity._vars = ctx.GlobalScope, ctx.GlobalScope
		end

		ctx:PushScope()
			local success, why = pcall( script[1], ctx, script )
		ctx:PopScope()

		-- Cleanup so hooks like runOnTick won't run after this call
		pcall(wire_expression2_CallHook, "destruct", ctx)

		do
			-- Cleanup
			ctx.entity.context = nil
			ctx.entity.outports, ctx.entity.inports = nil, nil
			ctx.entity.GlobalScope, ctx.entity._vars = nil, nil
		end

		if success then
			return true
		else
			local _, why, trace = E2Lib.unpackException(why)

			if trace then
				return false, "Runtime error: '" .. why .. "' at line " .. trace[1] .. ", col " .. trace[2]
			else
				return false, why
			end
		end
	end
end