AddCSLuaFile()

---@class EnvEvent
---@field name string
---@field args { placeholder: string, type: TypeSignature }[]
---@field constructor fun(ctx: RuntimeContext)?
---@field destructor fun(ctx: RuntimeContext)?
---@field listening table<Entity, boolean>

---@class EnvType
---@field name string
---@field id string

---@class EnvConstant: { name: string, type: TypeSignature, value: any }

---@class EnvOperator
---@field args TypeSignature[]
---@field ret TypeSignature?
---@field op RuntimeOperator
---@field cost integer

---@class EnvFunction: EnvOperator
---@field attrs table<string, boolean|string>
---@field const boolean? # Whether the function can be overridden at runtime. Optimzation. Only present in user functions.

---@class EnvMethod: EnvFunction
---@field meta TypeSignature

---@class EnvLibrary
---@field Constants table<string, EnvConstant>
---@field Functions table<string, EnvFunction[]>
---@field Methods table<TypeSignature, table<string, EnvMethod[]>>

E2Lib = table.Merge(E2Lib or {}, {
	Env = {
		---@type EnvEvent[]
		Events = {}
	}
})

local type = type
local function checkargtype(argn, value, argtype)
	if type(value) ~= argtype then error(string.format("bad argument #%d to 'E2Lib.%s' (%s expected, got %s)", argn, debug.getinfo(2, "n").name, argtype, type(value)), 2) end
end

-- -------------------------- Helper functions -----------------------------

-- Only data types that can be directly casted, or already are in the same category. All other
-- E2 types are either need to be transformed, or can't be casted to anything except for table.
local e2TypeNameToLuaTypeIDTable = {
	["none"] = TYPE_NONE,
	["void"] = TYPE_NONE,
	[""] = TYPE_NONE,
	["number"] = TYPE_NUMBER,
	["n"] = TYPE_NUMBER,
	["string"] = TYPE_STRING,
	["s"] = TYPE_STRING,
	["entity"] = TYPE_ENTITY,
	["e"] = TYPE_ENTITY,
	["vector"] = TYPE_VECTOR,
	["v"] = TYPE_VECTOR,
	["angle"] = TYPE_ANGLE,
	["a"] = TYPE_ANGLE,
	["effect"] = TYPE_EFFECTDATA,
	["xef"] = TYPE_EFFECTDATA,
}

--- Helper function to get the Lua type ID from an E2 type name. (E2Lib.CastE2ValueToLuaValue is not limited to this!)
local function e2TypeNameToLuaTypeID(TypeName)
	return e2TypeNameToLuaTypeIDTable[string.lower(TypeName)] or TYPE_TABLE
end

-- Lua type -> E2 to lua casting function. No way to implement default behaviour, so use castE2ValueToLuaValue function instead of table.
-- (It's forward declaration(to make recursive table unpacking possible). Real table is beneath castE2ValueToLuaValue)
local castE2ValueToLuaValueTable = {}

function E2Lib.castE2ValueToLuaValue(targetTypeID, e2Value)
	if castE2ValueToLuaValueTable[targetTypeID] then
		return castE2ValueToLuaValueTable[targetTypeID](e2Value)
	end

	return nil
end

-- Well, most of it is a nobrainer, but still helpful when you're just iterating and casting everything.
castE2ValueToLuaValueTable = {
	[TYPE_BOOL] = function(e2Value) -- from 'number'
		if TypeID(e2Value)==TYPE_NUMBER then
			return e2Value > 0
		end

		return nil
	end,
	[TYPE_NUMBER] = function(e2Value) -- from 'number' or 'string'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_NUMBER then return e2Value end
		if e2TypeID == TYPE_STRING then return tonumber(e2Value) end

		return nil
	end,
	[TYPE_STRING] = function(e2Value) -- from 'string' or 'number'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_STRING then return e2Value end
		if e2TypeID == TYPE_NUMBER then return tostring(e2Value) end

		return nil
	end,
	[TYPE_TABLE] = function(e2Value) -- from 'table, array, ranger, quaternions, and a most other types that aren't present in other casts'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_TABLE then
			if e2Value.ntypes or e2Value.stypes then -- Is it an E2 table? Unpack it correctly then.
				local res = {}

				-- Handle 'n' field
				for i, value in pairs(e2Value["n"]) do
					res[i] = E2Lib.castE2ValueToLuaValue(e2TypeNameToLuaTypeID(e2Value["ntypes"][i]), value) -- recursively unpacks any tables, or just returns the value.
				end

				-- Handle 's' field
				for key, value in pairs(e2Value["s"]) do
					res[key] = E2Lib.castE2ValueToLuaValue(e2TypeNameToLuaTypeID(e2Value["stypes"][key]), value) -- recursively unpacks any tables, or just returns the value.
				end

				return res
			end

			return e2Value -- It's not? Just return it then.
		end

		if e2TypeID == TYPE_ANGLE or e2TypeID == TYPE_COLOR or e2TypeID == TYPE_VECTOR or e2TypeID == TYPE_MATRIX then return e2Value:ToTable() end

		return nil
	end,
	[TYPE_ENTITY] = function(e2Value) -- from 'entity'
		if TypeID(e2Value) == TYPE_ENTITY then return e2Value end

		return nil
	end,
	[TYPE_VECTOR] = function(e2Value) -- from 'vector' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_VECTOR then return e2Value end
		if e2TypeID == TYPE_TABLE and isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) then return Vector(e2Value[1], e2Value[2], e2Value[3]) end

		return nil
	end,
	[TYPE_ANGLE] = function(e2Value) -- from 'angle' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_ANGLE then return e2Value
		elseif e2TypeID == TYPE_TABLE and isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) then return Angle(e2Value[1], e2Value[2], e2Value[3]) end

		return nil
	end,
	[TYPE_DAMAGEINFO] = function(e2Value) -- from 'damageinfo'
		if TypeID(e2Value) == TYPE_DAMAGEINFO then return e2Value end
	end,
	[TYPE_EFFECTDATA] = function(e2Value) -- from 'effectdata'
		if TypeID(e2Value) == TYPE_EFFECTDATA then return e2Value end
	end,
	[TYPE_MATERIAL] = function(e2Value) -- from 'string' or 'itable'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_STRING then return Material(e2Value) end
		if e2TypeID == TYPE_TABLE then -- Png parameters support
			if #e2Value ~= 2 then return nil end

			if TypeID(e2Value[1]) ~= TYPE_STRING then return nil end
			if TypeID(e2Value[2]) ~= TYPE_STRING then return nil end

			return Material(e2Value[1], e2Value[2])
		end

		return nil
	end,
	[TYPE_MATRIX] = function(e2Value) -- from 'matrix4'
		if TypeID(e2Value) ~= TYPE_TABLE then return nil end

		if #e2Value == 16 then
			for i = 1, 16 do
				if not isnumber(e2Value[i]) then return nil end
			end

			return Matrix({e2Value[1], e2Value[2], e2Value[3], e2Value[4]}, {e2Value[5], e2Value[6], e2Value[7], e2Value[8]}, {e2Value[9], e2Value[10], e2Value[11], e2Value[12]}, {e2Value[13], e2Value[14], e2Value[15], e2Value[16]})
		end

		return nil
	end,
	[TYPE_COLOR] = function(e2Value) -- +from 'vector' or 'vector4' or 'itable' or 'table'
		local e2TypeID = TypeID(e2Value)
		if e2TypeID == TYPE_VECTOR then
			return Color(e2Value[1], e2Value[2], e2Value[3])
		elseif e2TypeID == TYPE_TABLE then -- vector4 support + direct table support
			if isnumber(e2Value[1]) and isnumber(e2Value[2]) and isnumber(e2Value[3]) and isnumber(e2Value[4]) then
				return Color(e2Value[1], e2Value[2], e2Value[3], e2Value[4])
			elseif e2Value.r and e2Value.g and e2Value.b then
				if e2Value.a then return Color(e2Value.r, e2Value.g, e2Value.b, e2Value.a) end
				return Color(e2Value.r, e2Value.g, e2Value.b)
			end
		end

		return nil
	end,
}

local IsValid = IsValid

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

-- Returns a default e2 table instance.
function E2Lib.newE2Table()
	return { n = {}, ntypes = {}, s = {}, stypes = {}, size = 0 }
end

---@class E2Lambda
---@field fn fun(args: any[]): any
---@field arg_sig string
---@field ret string
local Function = {}
Function.__index = Function

function Function:__tostring()
	return "function(" .. self.arg_sig .. ")" .. ((self.ret and (": " .. self.ret)) or "")
end

function Function.new(args, ret, fn)
	return setmetatable({ arg_sig = args, ret = ret, fn = fn }, Function)
end

E2Lib.Lambda = Function

--- Call the function without doing any type checking or pcall.
--- Only use this when you check self:Args() yourself to ensure you have the correct signature function.
function Function:UnsafeCall(args)
	return self.fn(args)
end

function Function:Call(args, types)
	if self.arg_sig == types then
		return self.fn(args)
	else
		error("Incorrect arguments passed to lambda")
	end
end

-- Use these if you're calling lambdas externally, the context(ctx) is used for passing errors to the chip.
function Function:UnsafeExtCall(args, ctx)
	local success,ret = pcall(self.fn,args)
	if success then
		return ret
	else
		local _,msg,trace = E2Lib.unpackException(ret)
		ctx.entity:Error("Expression 2 (" .. ctx.entity.name .. "): Runtime Lambda error '" .. msg .. "' at line " .. trace.start_line .. ", char " .. trace.start_col, "error in script")
	end
end

function Function:ExtCall(args, types, ctx)
	if self.arg_sig == types then
		local success,ret = pcall(self.fn,args)
		if success then
			return ret
		else
			local _,msg,trace = E2Lib.unpackException(ret)
			ctx.entity:Error("Expression 2 (" .. ctx.entity.name .. "): Runtime Lambda error '" .. msg .. "' at line " .. trace.start_line .. ", char " .. trace.start_col, "error in script")
		end
	else
		ctx.entity:Error("Expression 2 (" .. ctx.entity.name .. "): Internal Lambda error, incorrect arguments passed.")
	end
end


function Function:Args()
	return self.arg_sig
end

function Function:Ret()
	return self.ret
end

--- If given the correct arguments, returns the inner untyped function you can then call with ENT:Execute(f).
--- Otherwise, throws an error to the given E2 Context.
---@param arg_sig string
---@param ctx RuntimeContext
function Function:Unwrap(arg_sig, ctx)
	if self.arg_sig == arg_sig then
		return self.fn
	else
		ctx:forceThrow("Incorrect function signature passed, expected (" .. arg_sig .. ") got (" .. self.arg_sig .. ")")
	end
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

	return (not rets or rets == "") and new_signature or (E2Lib.typeName(rets) .. "=" .. new_signature)
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
local getOwnerEnabled = CreateConVar("wire_expression2_getowner", "1", FCVAR_ARCHIVE, "Whether or not to use :GetOwner() get the owner of an entity."):GetBool()
cvars.AddChangeCallback( "wire_expression2_getowner", function(_, _, new) getOwnerEnabled = tobool(new) end)

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

	if getOwnerEnabled and entity.GetOwner then
		local ply = entity:GetOwner()
		if IsValid(ply) then return ply end
	end

	return nil
end

-- This function gets replaced when CPPI is detected, see very end of this file
function E2Lib.isFriend(owner, player)
	return owner == player
end

if game.SinglePlayer() then
	function E2Lib.isOwner(self, entity)
		return true
	end
else
	function E2Lib.isOwner(self, entity)
		local owner = E2Lib.getOwner(self, entity)
		if not IsValid(owner) then return false end

		return E2Lib.isFriend(owner, self.player)
	end
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
	if getmetatable(message) == E2Lib.Debug.Error then
		return message
	end

	print("Internal error - please report to https://github.com/wiremod/wire/issues")
	print(message)
	debug.Trace()

	return E2Lib.Debug.Error.new("Internal error, see console for more details")
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
	-- ``let``
	Let = 5,
	-- ``const``
	Const = 6,
	-- ``while``
	While = 7,
	-- ``for``
	For = 8,
	-- ``break``
	Break = 9,
	-- ``continue``
	Continue = 10,
	-- ``switch``
	Switch = 11,
	-- ``case``
	Case = 12,
	-- ``default``
	Default = 13,
	-- ``foreach``
	Foreach = 14,
	-- ``function``
	Function = 15,
	-- ``return``
	Return = 16,
	-- ``#include``
	["#Include"] = 17,
	-- ``try``
	Try = 18,
	-- ``catch``
	Catch = 19,
	-- ``do``
	Do = 20,
	-- ``event``
	Event = 21
}

E2Lib.Keyword = Keyword

--- A list of every word that we might use in the future
E2Lib.ReservedWord = {
	abstract = true,
	as = true,
	await = true,
	async = true,
	class = true,
	constructor = true,
	debugger = true,
	declare = true,
	default = true,
	delete = true,
	enum = true,
	export = true,
	extends = true,
	["false"] = true,
	finally = true,
	from = true,
	implements = true,
	import = true,
	["in"] = true,
	instanceof = true,
	interface = true,
	macro = true,
	module = true,
	mut = true,
	namespace = true,
	new = true,
	null = true,
	of = true,
	package = true,
	private = true,
	protected =true,
	public = true,
	require = true,
	static = true,
	struct = true,
	super = true,
	this = true,
	throw = true,
	throws = true,
	["true"] = true,
	type = true,
	typeof = true,
	undefined = true,
	union = true,
	yield = true,
	var = true,
}

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

---@type table<Operator, string>
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

E2Lib.blocked_array_types = { -- todo: fix casing
	["t"] = true,
	["r"] = true,
	["xgt"] = true
}

--- Types that will trigger their I/O connections on assignment/index change.
E2Lib.IOTableTypes = {
	ARRAY = true, ["r"] = true,
	TABLE = true, ["t"] = true,
	VECTOR = true, ["v"] = true,
	VECTOR2 = true, ["xv2"] = true,
	VECTOR4 = true, ["xv4"] = true,
	ANGLE = true, ["a"] = true,
	QUATERNION = true, ["q"] = true
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

local function e2libDelayedSetup()
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
		if FindMetaTable("Player").CPPIGetFriends then
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

		if FindMetaTable("Entity").CPPIGetOwner then
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
end

hook.Add("Expression2Reloaded", "wire_expression2_e2lib", e2libDelayedSetup)
hook.Add("InitPostEntity", "wire_expression2_e2lib", e2libDelayedSetup)

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

--- Deprecated.
--- Superceded by RuntimeContext:forceThrow(msg) / RuntimeContext:throw(msg, default?)
---@deprecated
---@param message string
---@param level integer
---@param trace Trace
---@param can_catch boolean?
function E2Lib.raiseException(message, level, trace, can_catch)
	error(E2Lib.Debug.Error.new(
		message,
		trace,
		{ catchable = (can_catch == nil) and true or can_catch }
	), level)
end

--- Unpacks either an exception object as seen above or an error string.
---@param struct string|Error
---@return boolean catchable
---@return string message
---@return Trace? trace
function E2Lib.unpackException(struct)
	if type(struct) == "string" then
		return false, struct, nil
	end
	return struct.userdata and struct.userdata.catchable or false, struct.message, struct.trace
end

---@class RuntimeScope: table<string, any>
---@field vclk table<string, boolean>
---@field parent RuntimeScope?

--- Context of an Expression 2 at runtime.
---@class RuntimeContext
---
---@field Scope RuntimeScope
---@field Scopes RuntimeScope[]
---@field ScopeID integer
---@field GlobalScope RuntimeScope | { lookup: table }
---
---@field prf integer
---@field prfcount integer
---@field prfbench integer
---
---@field time integer
---@field timebench integer
---
---@field entity userdata
---@field player userdata
---@field uid integer
---
---@field trace Trace
---@field __break__ boolean
---@field __continue__ boolean
---@field __return__ boolean
---@field __returnval__ any
---
---@field funcs table<string, RuntimeOperator>
---@field funcs_ret table<string, string> # dumb stringcall thing delete soon please
---@field includes table
---
---@field data table # Userdata
---@field throw fun(self: RuntimeContext, msg: string, value: any?)
local RuntimeContext = {}
RuntimeContext.__index = RuntimeContext

function RuntimeContext:__tostring()
	return "RuntimeContext"
end

E2Lib.RuntimeContext = RuntimeContext

---@class RuntimeContextBuilder: RuntimeContext
local RuntimeContextBuilder = {}
RuntimeContextBuilder.__index = RuntimeContextBuilder

---@return RuntimeContextBuilder
function RuntimeContext.builder()
	local global = { vclk = {}, lookup = {}, parent = nil }
	return setmetatable({
		GlobalScope = global,
		Scopes = { [0] = global },
		ScopeID = 0,
		Scope = global,

		prf = 0, prfcount = 0, prfbench = 0,
		time = 0, timebench = 0, stackdepth = 0,

		entity = game.GetWorld(), player = game.GetWorld(), uid = "World",

		trace = nil, -- Should be set at runtime
		__break__ = false, __continue__ = false, __return__ = false,

		funcs = {}, funcs_ret = {}, includes = {}, data = {}
	}, RuntimeContextBuilder)
end

---@param ply userdata
function RuntimeContextBuilder:withOwner(ply)
	self.player = assert(ply)
	self.uid = (ply:IsValid() and ply.UniqueID and ply:UniqueID()) or "World"
	return self
end

---@param chip userdata
function RuntimeContextBuilder:withChip(chip)
	self.entity = assert(chip)
	return self
end

---@param prf integer
---@param prfcount integer
---@param prfbench integer
function RuntimeContextBuilder:withPrf(prf, prfcount, prfbench)
	self.prf, self.prfcount, self.prfbench = assert(prf), assert(prfcount), assert(prfbench)
	return self
end

---@param time integer
---@param timebench integer
function RuntimeContextBuilder:withTime(time, timebench)
	self.time, self.timebench = assert(time), assert(timebench)
	return self
end

---@param functions table<string, RuntimeOperator>
---@param rets table<string, string>
function RuntimeContextBuilder:withUserFunctions(functions, rets)
	self.funcs = assert(functions)
	self.funcs_ret = rets or self.funcs_ret
	return self
end

---@param includes table
function RuntimeContextBuilder:withIncludes(includes)
	self.includes = assert(includes)
	return self
end

---@param strict boolean?
function RuntimeContextBuilder:withStrict(strict)
	self.strict = strict == true
	return self
end

---@param inputs table<string, TypeSignature>
function RuntimeContextBuilder:withInputs(inputs)
	for k, v in pairs(inputs) do
		self.GlobalScope[k] = E2Lib.fixDefault(wire_expression_types2[v][2])
	end
	return self
end

---@param outputs table<string, TypeSignature>
function RuntimeContextBuilder:withOutputs(outputs)
	for k, v in pairs(outputs) do
		self.GlobalScope[k] = E2Lib.fixDefault(wire_expression_types2[v][2])
		self.GlobalScope.vclk[k] = true
	end
	return self
end

---@param persists table<string, TypeSignature>
function RuntimeContextBuilder:withPersists(persists)
	for k, v in pairs(persists) do
		self.GlobalScope[k] = E2Lib.fixDefault(wire_expression_types2[v][2])
	end
	return self
end

--- Registers delta variables in the context.
--- **MUST** register all persists/inputs/outputs BEFORE calling this.
---@param vars table<string, boolean>
function RuntimeContextBuilder:withDeltaVars(vars)
	for k, _ in pairs(vars) do
		self.GlobalScope["$" .. k] = self.GlobalScope[k]
	end
	return self
end

---@return RuntimeContext
function RuntimeContextBuilder:build()
	if not self.strict then
		function self:throw(_msg, variable)
			return variable
		end
	end

	return setmetatable(self, RuntimeContext)
end

local DEF_USERDATA = { catchable = true }

--- If @strict, raises an error with message.
--- Otherwise, returns given value.
---@generic T
---@param message string
---@param _default T?
---@return T?
function RuntimeContext:throw(message, _default)
	local err = E2Lib.Debug.Error.new(message, self.trace, DEF_USERDATA)
	error(err, 2)
end

--- Same as RuntimeContext:throw, except always throws the error regardless of @strict being disabled.
RuntimeContext.forceThrow = RuntimeContext.throw

function RuntimeContext:PushScope()
	local scope = { vclk = {} }
	self.Scope, self.ScopeID = scope, self.ScopeID + 1
	self.Scopes[self.ScopeID] = scope
end

function RuntimeContext:PopScope()
	self.Scopes[self.ScopeID] = nil
	self.ScopeID = self.ScopeID - 1
	self.Scope = self.Scopes[self.ScopeID]
end

--- Compiles an E2 script without an entity owning it.
--- This doesn't have 1:1 behavior with an actual E2 chip existing, but is useful for testing.
---@param code string E2 Code to compile.
---@param owner userdata? 'Owner' entity, default world.
---@return boolean success If ran successfully
---@return string|function compiled Compiled function, or error message if not success
function E2Lib.compileScript(code, owner)
	local status, directives, code = E2Lib.PreProcessor.Execute(code)
	if not status then return false, directives end

	local status, tokens = E2Lib.Tokenizer.Execute(code)
	if not status then return false, tokens end

	local status, tree, dvars = E2Lib.Parser.Execute(tokens)
	if not status then return false, tree end

	local status, script = E2Lib.Compiler.Execute(tree, directives, dvars, {})
	if not status then return false, script end

	local ctx = RuntimeContext.builder()
		:withOwner(owner or game.GetWorld())
		:withStrict(directives.strict)
		:withInputs(directives.inputs[3])
		:withOutputs(directives.outputs[3])
		:withPersists(directives.persist[3])
		:withDeltaVars(dvars)
		:build()

	return true, function(ctx2)
		ctx = ctx2 or ctx

		do
			-- This was originally in makeContext, but I put it here in order to ensure the owner entity
			-- Isn't polluted by these fields, so they reset each time the compiled script is used.

			ctx.entity.context = ctx
			ctx.entity.outports, ctx.entity.inports = { {}, {}, {} }, { {}, {}, {} }
			ctx.entity.GlobalScope, ctx.entity._vars = ctx.GlobalScope, ctx.GlobalScope
		end

		local success, why = pcall(wire_expression2_CallHook, "construct", ctx)
		if success then
			success, why = pcall( script, ctx )
		end

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
				return false, "Runtime error: '" .. why .. "' at line " .. trace.start_line .. ", col " .. trace.start_col
			else
				return false, why
			end
		end
	end
end
