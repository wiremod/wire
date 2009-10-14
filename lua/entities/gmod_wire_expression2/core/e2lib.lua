AddCSLuaFile("e2lib.lua")

E2Lib = {}

local type = type
local function checkargtype(argn, value, argtype)
	if type(value) ~= argtype then error(string.format("bad argument #%d to 'E2Lib.%s' (%s expected, got %s)", argn, debug.getinfo(2,"n").name, argtype, type(text)),2) end
end

--[[************************* signature generation ***************************]]

local function maketype(typeid)
	if typeid == "" then return "void" end
	if typeid == "n" then return "number" end

	local tp = wire_expression_types2[typeid]
	if not tp then error("Type ID '"..typeid.."' not found",2) end

	local typename = tp[1]:lower()
	return typename or "unknown"
end

local function splitargs(args)
	local ret = {}
	local thistype = nil
	local i = 1
	while i <= #args do
		letter = args:sub(i,i)
		if letter == ":" then
			if #ret ~= 1 then error("Misplaced ':' in args",2) end
			thistype = ret[1]
			ret = {}
		elseif letter == "." then
			if args:sub(i) ~= "..." then error("Misplaced '.' in args",2) end
			table.insert(ret, "...")
			i=i+2
		else
			local typeid = letter
			if letter == "x" then
				typeid = args:sub(i,i+2)
				i = i+2
			end
			table.insert(ret, maketype(typeid))
		end
		i = i + 1
	end
	return thistype,ret
end

-- given a function signature like "setNumber(xwl:sn)" and an optional return typeid, generates a nice, readable signature
function E2Lib.generate_signature(signature, rets, argnames)
	local funcname, args = string.match(signature, "([^(]+)%(([^)]*)%)")
	if not funcname then error("malformed signature") end

	local thistype, args = splitargs(args)

	if argnames then
		for i = 1,#args do
			if argnames[i] then args[i] = args[i].." "..argnames[i] end
		end
	end
	local new_signature = string.format("%s(%s)", funcname, table.concat(args,","))
	if thistype then new_signature = thistype..":"..new_signature end

	return (not rets or rets == "") and (new_signature) or (maketype(rets).."="..new_signature)
end

--[[*********************** various entity checkers **************************]]

-- replaces an E2Lib function (ex.: isOwner) and notifies plugins
function E2Lib.replace_function(funcname, func)
	checkargtype(1,funcname,"string")
	checkargtype(2,func,"function")

	local oldfunc = E2Lib[funcname]
	if type(oldfunc) ~= "function" then error("No E2Lib function by the name "..funcname.." found.",2) end
	E2Lib[funcname] = func
	wire_expression2_CallHook("e2lib_replace_function", funcname, func, oldfunc)
end

E2Lib.validEntity = _R.Entity.IsValid -- this covers all cases the old validEntity covered, and more (strings, PhysObjs, etc.). it's also significantly faster.
local validEntity = E2Lib.validEntity

function E2Lib.validPhysics(entity)
	if validEntity(entity) then
		if entity:IsWorld() then return false end
		if entity:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
		return entity:GetPhysicsObject():IsValid()
	end
	return false
end

function E2Lib.getOwner(self, entity)
	if(entity == self.entity or entity == self.player) then return self.player end
	if entity.GetPlayer then
		local ply = entity:GetPlayer()
		if validEntity(ply) then return ply end
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
		if validEntity(ply) then return ply end
	end

	return nil
end

local wire_expression2_restricted = CreateConVar('wire_expression2_restricted', 1)
function E2Lib.isOwner(self, entity)
	if wire_expression2_restricted:GetBool() then
		return getOwner(self, entity) == self.player
	end
	return true
end
local isOwner = E2Lib.isOwner

-- This function is only here for compatibility. Use validEntity() in new code.
function E2Lib.checkEntity(entity)
	if validEntity(entity) then return entity end
	return nil
end

-- Checks whether the player is the chip's owner or in a pod owned by the chip's owner. Assumes that ply is really a player.
function E2Lib.canModifyPlayer(self, ply)
	if ply == self.player then return true end

	if not validEntity(ply) then return false end
	if not ply:IsPlayer() then return false end

	local vehicle = ply:GetVehicle()
	if not validEntity(vehicle) then return false end
	return isOwner(self, vehicle)
end

--[[**************************** type guessing *******************************]]

local type_lookup = {
	number = "n",
	string = "s",
	Vector = "v",
	PhysObj = "b",
}
local table_length_lookup = {
	[ 2] = "xv2",
	[ 3] = "v",
	[ 4] = "xv4",
	[ 9] = "m",
	[16] = "xm4",
}

function E2Lib.guess_type(value)
	if validEntity(value) then return "e" end
	if value.EntIndex then return "e" end
	local vtype = type(v)
	if type_lookup[vtype] then return type_lookup[vtype] end
	if vtype == "table" then
		if table_length_lookup[#v] then return table_length_lookup[#v] end
		if v.HitPos then return "xrd" end
	end

	for typeid,v in pairs(wire_expression_types2) do
		if v[5] then
			local ok = pcall(v[5],value)
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

--[[**************************** list filtering ******************************]]

local Debug = false
local cPrint
if Debug then
	if not console then require("console") end -- only needed if you want fancy-colored output.
	function cPrint(color, text) Msg(text) end
	if console and console.Print then cPrint = console.Print end
end

function E2Lib.filterList(list, criterion)
	local index = 1
	--if Debug then print("-- filterList: "..#list.." entries --") end

	while index <= #list do
		if not criterion(list[index]) then
			--if Debug then cPrint(Color(128,128,128), "-    "..tostring(list[index]).."\n") end
			list[index] = list[#list]
			table.remove(list)
		else
			--if Debug then print(string.format("+%3d %s", index, tostring(list[index]))) end
			index = index + 1
		end
	end

	--if Debug then print("--------") end
	return list
end

--[[**************************** compiler stuff ******************************]]

-- TODO: rewrite this!
E2Lib.optable = {
	["+"] = {"add", {["="] = {"aadd"}, ["+"] = {"inc"}}},
	["-"] = {"sub", {["="] = {"asub"}, ["-"] = {"dec"}}},
	["*"] = {"mul", {["="] = {"amul"}}},
	["/"] = {"div", {["="] = {"adiv"}}},
	["%"] = {"mod"},
	["^"] = {"exp"},

	["="] = {"ass", {["="] = {"eq"}}},
	["!"] = {"not", {["="] = {"neq"}}},
	[">"] = {"gth", {["="] = {"geq"}}},
	["<"] = {"lth", {["="] = {"leq"}}},

	["&"] = {"and"},
	["|"] = {"or"},

	["?"] = {"qsm"},
	[":"] = {"col"},
	[","] = {"com"},

	["("] = {"lpa"},
	[")"] = {"rpa"},
	["{"] = {"lcb"},
	["}"] = {"rcb"},
	["["] = {"lsb"},
	["]"] = {"rsb"},

	["$"] = {"dlt"},
	["~"] = {"trg"},
}

E2Lib.optable_inv = {}

do
	-- TODO: Reverse this and build optable from optable_inv.
	local function build_op_index(optable,prefix)
		for k,v in pairs(optable) do
			if v[1] then E2Lib.optable_inv[v[1]] = prefix..k end
			if v[2] then build_op_index(v[2],prefix..k) end
		end
	end
	build_op_index(E2Lib.optable, "")
end

function E2Lib.printops()
	local op_order = {["+"]=1,["-"]=2,["*"]=3,["/"]=4,["%"]=5,["^"]=6,["="]=7,["!"]=8,[">"]=9,["<"]=10,["&"]=11,["|"]=12,["?"]=13,[":"]=14,[","]=15,["("]=16,[")"]=17,["{"]=18,["}"]=19,["["]=20,["]"]=21,["$"]=22,["~"]=23}
	print("E2Lib.optable = {")
	for k,v in pairs_sortkeys(E2Lib.optable,function(a,b) return (op_order[a] or math.huge)<(op_order[b] or math.huge) end) do
		tblstring = table.ToString(v)
		tblstring = tblstring:gsub(",}","}")
		tblstring = tblstring:gsub("{(.)="," {[\"%1\"] = ")
		tblstring = tblstring:gsub(",(.)=",", [\"%1\"] = ")
		print(string.format("\t[%q] = %s,",k,tblstring))
	end
	print("}")
end

--[[***************************** string stuff *******************************]]

-- limits the given string to the given length and adds "..." to the end if too long.
function E2Lib.limitString(text, length)
	checkargtype(1,text,"string")
	checkargtype(2,length,"number")

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
		local valid_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 +-*/#^!?~=@&|.,:(){}[]<>" -- list of "normal" chars that can be transferred without problems
		local hex = { '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F' }


		for byte = 1,255 do
			dectbl[hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1]] = string.char(byte)
			enctbl[string.char(byte)] = "%" .. hex[(byte - byte % 16) / 16 + 1] .. hex[byte % 16 + 1]
		end

		for i = 1,valid_chars:len() do
			local char = valid_chars:sub(i, i)
			enctbl[char] = char
		end
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

--[[************************* disabling extensions ***************************]]

do
	local extensions = {}

	if not sql.TableExists("wire_expression2_extensions") then
		sql.Query("CREATE TABLE wire_expression2_extensions (name varchar(255), enabled tinyint)")
		sql.Query("CREATE UNIQUE INDEX name ON wire_expression2_extensions(name)")
	end

	function extensions.GetStatus(name, default)
		local value = sql.QueryValue(string.format("SELECT enabled FROM wire_expression2_extensions WHERE (name = %s)", sql.SQLStr(name)))
		return value and value ~= "0" or default
	end

	function extensions.SetStatus(name, status)
		sql.Query(string.format("REPLACE INTO wire_expression2_extensions (name, enabled) VALUES (%s, %d)", sql.SQLStr(name), status and 1 or 0))
	end

	function E2Lib.RegisterExtension(name, default)
		local status = extensions.GetStatus(name, default)
		if not status then error("Skipping E2 extension '"..name.."'.", 0) end
	end

	concommand.Add("wire_expression2_extension_enable", function(ply, cmd, args)
		if ValidEntity(ply) and not ply:IsSuperAdmin() then return end

		extensions.SetStatus(args[1], true)
	end)

	concommand.Add("wire_expression2_extension_disable", function(ply, cmd, args)
		if ValidEntity(ply) and not ply:IsSuperAdmin() then return end

		extensions.SetStatus(args[1], false)
	end)
end

--[[***************************** compatibility ******************************]]

-- Some functions need to be global for backwards-compatibility.
local makeglobal = {
	["validEntity"] = true,
	["validPhysics"] = true,
	["getOwner"] = true,
	["isOwner"] = true,
	["checkEntity"] = true,
}

-- Put all these functions into the global scope.
for funcname,_ in pairs(makeglobal) do
	_G[funcname] = E2Lib[funcname]
end

hook.Add("InitPostEntity", "e2lib", function()
	-- If changed, put them into the global scope again.
	registerCallback("e2lib_replace_function", function(funcname, func, oldfunc)
		if makeglobal[funcname] then
			_G[funcname] = func
		end
		if funcname == "validEntity" then validEntity = func
		elseif funcname == "isOwner" then isOwner = func
		end
	end)

	-- check for a CPPI compliant plugin
	if SERVER and CPPI and _R.Player.CPPIGetFriends then
		E2Lib.replace_function("isOwner", function(self, entity)
			local ply = self.player
			local owner = getOwner(self, entity)
			if not validEntity(owner) then return false end
			if ply == owner then return true end

			local friends = owner:CPPIGetFriends()
			for _,friend in pairs(friends) do
				if ply == friend then return true end
			end
			return false
		end)
	end
end)
