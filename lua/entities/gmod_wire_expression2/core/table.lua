----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Formerly known as "mtable", this extension has now (15-11-2010) replaced the old table extension.
-- Made by Divran
----------------------------------------------------------------------------------------------------------------------------------------------------------------
local function IsEmpty( t ) return !next(t) end
local rep = string.rep
local tostring = tostring

local opcost = 1/3 -- cost of looping through table multiplier

-- All different table types in E2
local tbls = {
	r = true,
	t = true,
	xgt = true,
}

-- Types not allowed in tables
local blocked_types = {
	xgt = true,
}

local _maxdepth = CreateConVar("wire_expression2_table_maxdepth",6,{FCVAR_ARCHIVE,FCVAR_NOTIFY})
local function maxdepth()
	return _maxdepth:GetInt()
end
local maxsize = 1024*1024

--------------------------------------------------------------------------------
-- Type defining
--------------------------------------------------------------------------------

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,istable=true,depth=0}

registerType("table", "t", table.Copy(DEFAULT),
	function(self, input)
		return input
	end,
	nil,
	function(retval)
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "table"
	end
)

local formatPort = WireLib.Debugger.formatPort
local function temp( ret, tbl, k, v, orientvertical, isnum )
	local id
	if (isnum) then
		id = tbl.ntypes[k]
	else
		id = tbl.stypes[k]
	end

	if (isnum) then
		ret = ret .. k .. "="
	else
		ret = ret .. '"' .. k .. '"' .. "="
	end

	local longtype = wire_expression_types2[id][1]

	if (tbls[id] == true) then
		if (id == "xgt") then
			ret = ret .. "wtf how did this get here"
		else
			if (id == "r") then
				ret = ret .. "Array with " .. #v .. " elements"
			elseif (id == "t") then
				ret = ret .. "Table with " .. v.size .. " elements"
			else
				ret = ret .. "Error! Should never get down here!"
			end
		end
	else
		ret = ret .. formatPort[longtype]( v, orientvertical )
	end

	if (orientvertical) then
		ret = ret .. "\n"
	else
		ret = ret .. ", "
	end

	return ret
end
WireLib.registerDebuggerFormat( "table", function( value, orientvertical )
	local ret = ""
	local n = 0
	for k2,v2 in pairs( value.n ) do
		n = n + 1
		if (n > 7) then break end
		ret = temp( ret, value, k2, v2, orientvertical, true )
	end
	for k3, v3 in pairs( value.s ) do
		n = n + 1
		if (n > 7) then break end
		ret = temp( ret, value, k3, v3, orientvertical, false )
	end
	ret = ret:Left(-3)
	return "{" .. ret .. "}"
end)

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Fix default values
local function fixdef( def )
	if (type(def) == "table") then return table.Copy(def) else return def end
end

-- Uppercases the first letter
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

-- Sets the depth of all tables in the table, and returns the deepest depth
local function checkdepth( tbl, depth, setdepth )
	local deepest = depth or 0
	for k,v in pairs( tbl.n ) do
		if (tbl.ntypes[k] == "t") then
			if (depth + 1 > maxdepth()) then return depth + 1 end
			if (setdepth != false) then v.depth = depth + 1 end
			local temp = checkdepth( v, depth + 1, setdepth )
			if (temp > deepest) then
				deepest = temp
			end
		end
	end
	for k,v in pairs( tbl.s ) do
		if (tbl.stypes[k] == "t") then
			if (depth + 1 > maxdepth()) then return depth + 1 end
			if (setdepth != false) then v.depth = depth + 1 end
			local temp = checkdepth( v, depth + 1, setdepth )
			if (temp > deepest) then
				deepest = temp
			end
		end
	end
	return deepest
end

local function normal_table_tostring( tbl, indenting, printed, abortafter )
	ret = ""
	cost = 0
	for k,v in pairs( tbl ) do
		if (type(v) == "table" and !printed[v]) then
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = normal_table_tostring( tbl, indenting + 2, printed, abortafter )
			cost = cost + cost2 + 2
		else
			ret = ret .. rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
			cost = cost + 1
		end
		if (abortafter and cost > abortafter) then
			ret = ret .. "\n- Aborted to prevent lag -"
			return ret, cost
		end
	end
	return ret, cost
end

local function table_tostring( tbl, indenting, printed, abortafter )
	local ret = ""
	local cost = 0
	for k,v in pairs( tbl.n ) do
		if (tbl.ntypes[k] == "t" and !printed[v]) then -- If it's an table
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = table_tostring( v, indenting + 2, printed, abortafter )
			ret = ret .. ret2
			cost = cost + cost2 + 2
		elseif (type(v) == "table" and !printed[v]) then -- If it's another kind of table
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = normal_table_tostring( v, indenting + 2, printed, abortafter )
			ret = ret .. ret2
		else -- If it's anything else (or a table which has already been printed)
			ret = ret .. rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
		end
		if (abortafter and cost > abortafter) then
			ret = ret .. "\n- Aborted to prevent lag -"
			return ret, cost
		end
	end
	for k,v in pairs( tbl.s ) do
		if (tbl.stypes[k] == "t" and !printed[v]) then -- If it's an table
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = table_tostring( v, indenting + 2, printed, abortafter )
			ret = ret .. ret2
			cost = cost + cost2 + 2
		elseif (type(v) == "table" and !printed[v]) then -- If it's another kind of table
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = normal_table_tostring( v, indenting + 2, printed, abortafter )
			ret = ret .. ret2
		else -- If it's anything else (or a table which has already been printed)
			ret = ret .. rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
		end
		if (abortafter and cost > abortafter) then
			ret = ret .. "\n- Aborted to prevent lag -"
			return ret, cost
		end
	end
	return ret, cost
end

--------------------------------------------------------------------------------
-- Operators
--------------------------------------------------------------------------------

__e2setcost(5) -- temporary

e2function table operator=(table lhs, table rhs)
	if (checkdepth( rhs, 0, false ) > maxdepth()) then
		self.prf = self.prf + 500
		return table.Copy(DEFAULT)
	end
	if (rhs.size > maxsize) then
		self.prf = self.prf + 500
		return table.Copy(DEFAULT)
	end

	local lookup = self.data.lookup

	-- remove old lookup entry
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end

	-- add new
	if (!lookup[rhs]) then
		lookup[rhs] = {}
	end
	lookup[rhs][lhs] = true

	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

__e2setcost(1)

e2function number operator_is( table tbl )
	return (tbl.size > 0) and 1 or 0
end

e2function number operator==( table rv1, table rv2 )
	return (rv1 == rv2) and 1 or 0
end

__e2setcost(40)

e2function table operator+( table rv1, table rv2 )
	local ret = table.Copy(rv1)
	local size = ret.size
	local cost = 0
	for k,v in ipairs( rv2.n ) do
		cost = cost + 1
		if (!blocked_types[rv2.ntypes[k]]) then
			if (!ret.n[k]) then size = size + 1 end
			ret.n[k] = v
			ret.ntypes[k] = rv2.ntypes[k]
		end
	end
	for k,v in pairs( rv2.s ) do
		cost = cost + 1
		if (!blocked_types[rv2.stypes[k]]) then
			if (!ret.s[k]) then size = size + 1 end
			ret.s[k] = v
			ret.stypes[k] = rv2.stypes[k]
		end
	end
	ret.size = size
	self.prf = self.prf + cost * opcost
	if (checkdepth( ret, 0, false ) > maxdepth()) then
		self.prf = self.prf + 500 -- Punishment
		return table.Copy(DEFAULT)
	end
	return ret
end

__e2setcost(nil)

registerOperator("fea","t","s",function(self,args)
	local keyname,valname,valtypeid = args[2],args[3],args[4]
	local tbl = args[5]
	tbl = tbl[1](self,tbl)
	local statement = args[6]

	self.vclk[keyname] = true
	self.vclk[valname] = true

	local len = valtypeid:len()

	local keys = {}
	for key,_ in pairs(tbl.s) do
		if (tbl.stypes[key] == valtypeid) then
			keys[#keys+1] = key
		end
	end

	for _,key in ipairs(keys) do
		if tbl.s[key] ~= nil then
			self.prf = self.prf + 3

			self.vars[keyname] = key
			self.vars[valname] = tbl.s[key]

			local ok, msg = pcall(statement[1], self, statement)
			if not ok then
				if msg == "break" then break
				elseif msg ~= "continue" then error(msg, 0) end
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- Common functions
--------------------------------------------------------------------------------

__e2setcost(20)

-- Creates an table
e2function table table(...)
	local tbl = {...}
	if (#tbl == 0) then return table.Copy(DEFAULT) end
	local ret = table.Copy(DEFAULT)
	local size = 0
	for k,v in ipairs( tbl ) do
		if (!blocked_types[typeids[k]]) then
			size = size + 1
			if (size > maxsize) then -- Max size check
				self.prf = self.prf + size * opcost + 500
				return table.Copy(DEFAULT)
			end
			if (typeids[k] == "t") then
				if (checkdepth( v, 1 )>maxdepth()) then -- Max depth check
					self.prf = self.prf + size * opcost + 500
					return table.Copy(DEFAULT)
				end
				v.depth = 1
				v.parent = ret
			end
			ret.n[k] = v
			ret.ntypes[k] = typeids[k]
		end
	end
	ret.size = size
	self.prf = self.prf + size * opcost
	return ret
end

__e2setcost(20)

local exploitables = { Entity = true, NPC = true, Vehicle = true }

--[[ This function is no longer necessary. Will likely be removed soon - leaving it here just in case
-- Converts a table into an table
e2 function table table:toTable()
	if (IsEmpty( this )) then return table.Copy(DEFAULT) end
	local ret = table.Copy(DEFAULT)
	local size = 0
	local cost = 0
	for k,v in pairs( this ) do
		cost = cost + 1
		local id = k:Left(1)
		local index
		if (id == "x") then
			id = k:Left(3)
			index = k:Right(-4)
		else
			index = k:Right(-2)
		end
		if (!blocked_types[id]) then -- Check for blocked types.. there's also no way there could be a table inside a table.

			if ((exploitables[type(v)] and id != "e") or id != "t" or id != "t" or id != "r") then -- Exploit check
				--MsgN( "[E2] WARNING! " .. self.player:Nick() .. " (" .. self.player:SteamID() .. ") tried to read a non-table type as a table. This is a known and serious exploit that has been prevented." )
				--error( "Tried to read a non-table type as a table." )
				return table.Copy(DEFAULT)
			end


			size = size + 1
			if (size > maxsize) then
				self.prf = self.prf + size * opcost + 500
				return table.Copy(DEFUALT)
			end
			ret.s[index] = v
			ret.stypes[index] = id
		end
	end
	ret.size = size
	self.prf = self.prf + cost * opcost
	return ret
end
]]

__e2setcost(5)

-- Erases everything in the table
e2function void table:clear()
	self.prf = self.prf + this.size * opcost
	table.Empty( this.n )
	this.ntypes = {}
	table.Empty( this.s )
	this.stypes = {}
	this.parent = nil
	this.size = 0
	return this
end

__e2setcost(2)

-- Returns the number of elements in the table
e2function number table:count()
	return this.size
end

-- Returns the depth of the table
e2function number table:depth()
	return this.depth
end

__e2setcost(10)

-- Returns the parent of the table
e2function table table:parent()
	return this.parent or table.Copy(DEFAULT)
end

__e2setcost(15)

e2function void printTable( table tbl )
	if (tbl.size > 200) then
		self.player:ChatPrint("Table has more than 200 ("..tbl.size..") elements. PrintTable cancelled to prevent lag")
		return
	end
	local printed = { [tbl] = true }
	local ret, cost = table_tostring( tbl, 0, printed, 200 )
	self.prf = self.prf + cost
	for str in string.gmatch( ret, "[^\n]+" ) do
		self.player:ChatPrint( str )
	end
end

__e2setcost(20)

-- Flip the numbers and strings of the table
e2function table table:flip()
	local ret = table.Copy(DEFAULT)
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] == "s") then
			ret.s[v] = k
			ret.stypes[v] = "n"
		end
	end
	for k,v in pairs( this.s ) do
		if (this.stypes[k] == "n") then
			ret.n[v] = k
			ret.ntypes[v] = "s"
		end
	end
	self.prf = self.prf + this.size * opcost
	return ret
end

__e2setcost(20)

-- Returns an table with the typesids of both the array- and table-parts
e2function table table:typeids()
	local ret = table.Copy(DEFAULT)
	ret.n = table.Copy(this.ntypes)
	for k,v in pairs( ret.n ) do
		ret.ntypes[k] = "s"
	end
	ret.s = table.Copy( this.stypes )
	for k,v in pairs( ret.s ) do
		ret.stypes[k] = "s"
	end
	ret.size = this.size
	self.prf = self.prf + this.size * opcost
	return ret
end

__e2setcost(15)

-- Remove a variable at a number index
e2function void table:remove( number index )
	if (#this.n == 0) then return end
	if (!this.n[index]) then return end
	table.remove( this.n, index )
	table.remove( this.ntypes, index )
	this.size = this.size - 1
	self.vclk[this] = true
end

-- Remove a variable at a string index
e2function void table:remove( string index )
	if (IsEmpty(this.s)) then return end
	if (!this.s[index]) then return end
	this.s[index] = nil
	this.stypes[index] = nil
	this.size = this.size - 1
	self.vclk[this] = true
end

__e2setcost(20)

-- Removes all variables not of the type
e2function table table:clipToTypeid( string typeid )
	local ret = table.Copy(DEFAULT)
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] == typeid) then
			local n = #ret.n+1
			if (type(v) == "table") then
				ret.n[n] = table.Copy(v)
			else
				ret.n[n] = v
			end
			ret.ntypes[n] = this.ntypes[k]
		end
	end
	for k,v in pairs( this.s ) do
		if (this.stypes[k] == typeid) then
			if (type(v) == "table") then
				ret.s[k] = table.Copy(v)
			else
				ret.s[k] = v
			end
			ret.stypes[k] = this.stypes[k]
		end
	end
	self.prf = self.prf + this.size * opcost
	return ret
end

-- Removes all variables of the type
e2function table table:clipFromTypeid( string typeid )
	local ret = table.Copy(DEFAULT)
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] != typeid) then
			if (type(v) == "table") then
				ret.n[k] = table.Copy(v)
			else
				ret.n[k] = v
			end
			ret.ntypes[k] = this.ntypes[k]
		end
	end
	for k,v in pairs( this.s ) do
		if (this.stypes[k] != typeid) then
			if (type(v) == "table") then
				ret.s[k] = table.Copy(v)
			else
				ret.s[k] = v
			end
			ret.stypes[k] = this.stypes[k]
		end
	end
	self.prf = self.prf + this.size * opcost
	return ret
end

__e2setcost(50)

e2function table table:clone()
	self.prf = self.prf + this.size * opcost
	return table.Copy(this)
end

__e2setcost(5)

e2function string table:id()
	return tostring(this)
end

__e2setcost(20)

-- Formats the table as a human readable string
e2function string table:toString()
	local printed = { [this] = true }
	local ret, cost = table_tostring( this, 0, printed )
	self.prf = self.prf + cost * opcost
	return ret
end

--------------------------------------------------------------------------------
-- Array-part-only functions
--------------------------------------------------------------------------------

__e2setcost(10)

-- Removes the last element in the array part
e2function void table:pop()
	local n = #this.n
	if (n == 0) then return end
	this.n[n] = nil
	this.size = this.size - 1
	self.vclk[this] = true
end

__e2setcost(10)

-- Returns the smallest number in the array-part
e2function number table:min()
	if (IsEmpty(this.n)) then return 0 end
	local smallest = nil
	local cost = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (smallest == nil or v < smallest) then
				smallest = v
			end
		end
	end
	self.prf = self.prf + cost * opcost
	return smallest or 0
end

-- Returns the largest number in the array-part
e2function number table:max()
	if (IsEmpty(this.n)) then return 0 end
	local largest = nil
	local cost = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (largest == nil or v > largest) then
				largest = v
			end
		end
	end
	self.prf = self.prf + cost * opcost
	return largest or 0
end

-- Returns the index of the largest number in the array-part
e2function number table:maxIndex()
	if (IsEmpty(this.n)) then return 0 end
	local largest = nil
	local index = 0
	local cost = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (largest == nil or v > largest) then
				largest = v
				index = k
			end
		end
	end
	self.prf = self.prf + cost * opcost
	return index
end

-- Returns the index of the smallest number in the array-part
e2function number table:minIndex()
	if (IsEmpty(this.n)) then return 0 end
	local smallest = nil
	local index = 0
	local cost = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (smallest == nil or v < smallest) then
				smallest = v
				index = k
			end
		end
	end
	self.prf = self.prf + cost * opcost
	return index
end

__e2setcost(20)

-- Returns the types of the variables in the array-part
e2function array table:typeidsArray()
	self.prf = self.prf + table.Count(this.ntypes) * opcost
	return table.Copy(this.ntypes)
end

-- Converts an table into an array
e2function array table:toArray()
	if (IsEmpty(this.n)) then return {} end
	local ret = {}
	local cost = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		local id = this.ntypes[k]
		if (tbls[id] != true) then
			ret[k] = v
		end
	end
	self.prf = self.prf + cost * opcost
	return ret
end

__e2setcost(20)

-- Returns the find in the array part of an table
e2function table findToTable()
	local ret = table.Copy(DEFAULT)
	for k,v in ipairs( self.data.findlist ) do
		ret.n[k] = v
		ret.ntypes[k] = "e"
		ret.size = k
	end
	return ret
end

__e2setcost(15)

e2function string table:concat()
	self.prf = self.prf + #this.n * opcost
	local ret = ""
	for k,v in ipairs( this.n ) do
		ret = ret .. tostring(v)
	end
	return ret
end

e2function string table:concat( string delimiter )
	self.prf = self.prf + #this.n * opcost
	local ret = ""
	for k,v in ipairs( this.n ) do
		ret = ret .. tostring(v) .. delimiter
	end
	return ret:Left(-#delimiter-1)
end

--------------------------------------------------------------------------------
-- Table-part-only functions
--------------------------------------------------------------------------------

__e2setcost(20)

-- Converts an table into a table
e2function table table:toTable()
	if (IsEmpty( this.s )) then return {} end
	local cost = 0
	local ret = {}
	for k,v in pairs( this.s ) do
		cost = cost + 1
		local id = this.stypes[k]
		if (tbls[id] != true) then
			ret[id..k] = v
		end
	end
	self.prf = self.prf + cost * opcost
	return ret
end

---[[
--------------------------------------------------------------------------------
-- Backwards compatibility functions (invert)
--------------------------------------------------------------------------------
-- for invert(R)
local tostrings = {
	number=tostring,
	string=tostring,
	Entity=tostring,
	Weapon=tostring,
	Player=tostring,
	Vehicle=tostring,
	NPC=tostring,
	PhysObj=e2_tostring_bone,
	["nil"] = function() return "(null)" end
}

function tostrings.table(t)
	return "["..table.concat(t, ",").."]"
end

function tostrings.Vector(v)
	return "[" .. tostring(v[1]) .. "," .. tostring(v[2]) .. "," .. tostring(v[3]) .. "]"
end

-- for invert(T)
local tostring_typeid = {
	n=tostring,
	s=tostring,
	e=tostring,
	xv2=tostrings.table,
	v=tostrings.Vector,
	xv4=tostrings.table,
	a=tostrings.table,
	b=e2_tostring_bone,
}

--- Returns a lookup table for <arr>. Usage: Index = T:number(toString(Value)).
--- Don't overuse this function, as it can become expensive for arrays with > 10 entries!
e2function table invert(array arr)
	local ret = table.Copy(DEFAULT)
	local c = 0
	for i,v in ipairs(arr) do
		c = c + 1
		local tostring_this = tostrings[type(v)]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[i] = "n"
		else
			self.player:ChatPrint("E2: invert(R): Invalid type ("..type(v)..") in array. Ignored.")
		end
	end
	self.prf = self.prf + c * opcost
	return ret
end

--- Returns a lookup table for <tbl>. Usage: Key = T:string(toString(Value)).
--- Don't overuse this function, as it can become expensive for tables with > 10 entries!
e2function table invert(table tbl)
	local ret = table.Copy(DEFAULT)
	local c = 0
	for i,v in pairs(tbl.s) do
		c = c + 1
		local typeid = tbl.stypes[i]
		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[i] = "s"
		else
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	self.prf = self.prf + c * opcost
	return ret
end

e2function array table:keys()
	local ret = {}
	local c = 0
	for index,value in pairs(this.stypes) do
		c = c + 1
		ret[#ret+1] = value
	end
	self.prf = self.prf + c * opcost
	return ret
end

e2function array table:values()
	local ret = {}
	local c = 0
	for index,value in pairs(this.s) do
		c = c + 1
		ret[#ret+1] = value
	end
	self.prf = self.prf + c * opcost
	return ret
end
--]]

--------------------------------------------------------------------------------
-- Looped functions
--------------------------------------------------------------------------------

registerCallback( "postinit", function()
	local getf, setf
	for k,v in pairs( wire_expression_types ) do
		local name = k
		local id = v[1]

		if (!blocked_types[id]) then -- blocked check start

		--------------------------------------------------------------------------------
		-- Set/Get functions, t[index,type] syntax
		--------------------------------------------------------------------------------

		__e2setcost(10)

		-- Getters
		registerOperator("idx",	id.."=ts"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (!rv1.s[rv2] or rv1.stypes[rv2] != id) then return fixdef(v[2]) end
			if (v[6] and v[6](rv1.s[rv2])) then return fixdef(v[2]) end -- Type check
			return rv1.s[rv2]
		end)

		registerOperator("idx",	id.."=tn"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (!rv1.n[rv2] or rv1.ntypes[rv2] != id) then return fixdef(v[2]) end
			if (v[6] and v[6](rv1.n[rv2])) then return fixdef(v[2]) end -- Type check
			return rv1.n[rv2]
		end)

		-- Setters
		registerOperator("idx", id.."=ts"..id , id, function( self, args )
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (!rv1 or !rv2 or !rv3) then return fixdef(v[2]) end
			if (id == "t") then
				rv3.depth = rv1.depth + 1
				if (checkdepth( rv3, rv3.depth, true ) > maxdepth()) then -- max depth check
					self.prf = self.prf + 500
					return fixdef(v[2])
				end
				rv3.parent = rv1
			end
			if (!rv1.s[rv2]) then rv1.size = rv1.size + 1 end
			if (rv1.size > maxsize) then
				self.prf = self.prf + 500
				return fixdef(v[2])
			end
			rv1.s[rv2] = rv3
			rv1.stypes[rv2] = id
			self.vclk[rv1] = true
			return rv3
		end)

		registerOperator("idx", id.."=tn"..id, id, function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (!rv1 or !rv2 or !rv3) then return fixdef(v[2]) end
			if (id == "t") then
				rv3.depth = rv1.depth + 1
				if (checkdepth( rv3, rv3.depth, true ) > maxdepth()) then -- max depth check
					self.prf = self.prf + 500
					return fixdef(v[2])
				end
				rv3.parent = rv1
			end
			if (!rv1.n[rv2]) then rv1.size = rv1.size + 1 end
			if (rv1.size > maxsize) then return fixdef(v[2]) end
			rv1.n[rv2] = rv3
			rv1.ntypes[rv2] = id
			self.vclk[rv1] = true
			return rv3
		end)


		--------------------------------------------------------------------------------
		-- Remove functions
		--------------------------------------------------------------------------------

		__e2setcost(15)

		local function removefunc( self, rv1, rv2, numidx )
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (numidx) then
				if (!rv1.n[rv2] or rv1.ntypes[rv2] != id) then return fixdef(v[2]) end
				local ret = rv1.n[rv2]
				table.remove( rv1.n, rv2 )
				table.remove( rv1.ntypes, rv2 )
				rv1.size = rv1.size - 1
				self.vclk[rv1] = true
				return ret
			else
				if (!rv1.s[rv2] or rv1.stypes[rv2] != id) then return fixdef(v[2]) end
				local ret = rv1.s[rv2]
				rv1.s[rv2] = nil
				rv1.stypes[rv2] = nil
				self.vclk[rv1] = true
				rv1.size = rv1.size - 1
				return ret
			end
		end

		name = upperfirst( name )
		if (name == "Normal") then name = "Number" end
		registerFunction("remove"..name,"t:s",id,function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			return removefunc( self, rv1, rv2)
		end)
		registerFunction("remove"..name,"t:n",id,function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			return removefunc(self, rv1, rv2, true)
		end)


		--------------------------------------------------------------------------------
		-- Array functions
		--------------------------------------------------------------------------------

		-- Push a variable into the table (into the array part)
		registerFunction( "push"..name,"t:"..id,"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			local n = #rv1.n+1
			if (id == "t") then
				rv2.depth = rv1.depth + 1
				if (checkdepth( rv2, rv2.depth, true ) > maxdepth()) then
					self.prf = self.prf + 500
					return fixdef(v[2])
				end
				rv2.parent = rv1
			end
			rv1.size = rv1.size + 1
			if (rv1.size > maxsize) then
				self.prf = self.prf + 500
				return fixdef(v[2])
			end
			rv1.n[n] = rv2
			rv1.ntypes[n] = id
			self.vclk[rv1] = true
			return rv2
		end)

		registerFunction( "pop"..name,"t:",id,function(self,args)
			local op1 = args[2]
			local rv1 = op1[1](self, op1)
			return removefunc(self, rv1, #rv1.n, true)
		end)

		registerFunction( "insert"..name,"t:n"..id,"",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self,op3)
			if (!rv1 or !rv2 or !rv3 or rv2 < 0) then return end
			if (id == "t") then
				rv3.depth = rv1.depth + 1
				if (checkdepth( rv3, rv3.depth, true ) > maxdepth()) then
					self.prf = self.prf + 500
					return fixdef(v[2])
				end
				rv3.parent = rv1
			end
			rv1.size = rv1.size + 1
			if (rv1.size > maxsize) then
				self.prf = self.prf + 500
				return fixdef(v[2])
			end
			table.insert( rv1.n, rv2, rv3 )
			table.insert( rv1.ntypes, rv2, id )
			self.vclk[rv1] = true
			return rv3
		end)

		registerFunction( "unshift"..name,"t:"..id,"",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self,op3)
			if (!rv1 or !rv2) then return end
			if (id == "t") then
				rv2.depth = rv1.depth + 1
				if (checkdepth( rv2, rv2.depth, true ) > maxdepth()) then
					self.prf = self.prf + 500
					return fixdef(v[2])
				end
				rv2.parent = rv1
			end
			rv1.size = rv1.size + 1
			if (rv1.size > maxsize) then
				self.prf = self.prf + 500
				return fixdef(v[2])
			end
			table.insert( rv1.n, 1, rv2 )
			table.insert( rv1.ntypes, 1, id )
			self.vclk[rv1] = true
			return rv2
		end)


		end -- blocked check end

	end
end)

--------------------------------------------------------------------------------
-- "lookup" stuff copied from the old table.lua file
--------------------------------------------------------------------------------

-- these postexecute and construct hooks handle changes to both tables and arrays.
registerCallback("postexecute", function(self)
	local vars, vclk, lookup = self.vars, self.vclk, self.data.lookup

	-- Go through all registered values of the types table and array.
	for value,varnames in pairs(lookup) do
		local clk = vclk[value]

		local still_assigned = false
		-- For each value, go through the variables they're assigned to and trigger them.
		for varname,_ in pairs(varnames) do
			if value == vars[varname] then
				-- The value is still assigned to the variable? => trigger it.
				if clk then vclk[varname] = true end
				still_assigned = true
			else
				-- The value is no longer assigned to the variable? => remove the lookup table entry.
				varnames[varname] = nil
			end
		end

		-- if the value is no longer assigned to anything, remove all references to it.
		if not still_assigned then
			lookup[value] = nil
		end
		-- If the value has no more variable names associated, remove the value's place in the lookup table.
		if IsEmpty(varnames) then lookup[value] = nil end
	end
end)

local tbls = {
	ARRAY = true,
	TABLE = true,
}

registerCallback("construct", function(self)
	self.data.lookup = {}

	for k,v in pairs( self.vars ) do
		local datatype = self.entity.outports[3][k]
		if (tbls[datatype]) then
			if (!self.data.lookup[v]) then self.data.lookup[v] = {} end
			self.data.lookup[v][k] = true
		end
	end
end)
