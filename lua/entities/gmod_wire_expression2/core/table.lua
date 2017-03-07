----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Formerly known as "mtable", this extension has now (15-11-2010) replaced the old table extension.
-- Made by Divran
----------------------------------------------------------------------------------------------------------------------------------------------------------------
local function IsEmpty( t ) return !next(t) end
local rep = string.rep
local tostring = tostring
local table = table
local type = type

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

--------------------------------------------------------------------------------

local function checkOwner(self)
	return IsValid(self.player);
end


--------------------------------------------------------------------------------
-- Type defining
--------------------------------------------------------------------------------

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

registerType("table", "t", table.Copy(DEFAULT),
	function(self, input)
		if IsEmpty(input) then
			return table.Copy(DEFAULT)
		end
		return input
	end,
	nil,
	function(retval)
		if not istable(retval) then error("Return value is not a table, but a "..type(retval).."!", 0) end
	end,
	function(v)
		return not istable(v)
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
	if not value.n or not value.s then return "{}" end
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
	return istable(def) and table.Copy(def) or def
end

-- Uppercases the first letter
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

----------------------------------
-- tostrings
----------------------------------

-- for invert(R) and printTable and T:toString()
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

function tostrings.Vector2(v)
	return ("[%s,%s]"):format(v[1],v[2])
end

function tostrings.Vector(v)
	return ("[%s,%s,%s]"):format(v[1],v[2],v[3])
end

function tostrings.Vector4(v)
	return ("[%s,%s,%s,%s]"):format(v[1],v[2],v[3],v[4])
end

-- for invert(T)
local tostring_typeid = {
	c =		formatPort.COMPLEX,
	b =		tostring,
	e =		tostring,
	xwl =	tostring,
	xrd =	tostring,
	n =		tostring,
	q =		formatPort.QUATERNION,
	s =		function(s) return s end,
	r =		tostring,
	xm4 =	tostrings.table,
	t =		tostring,
	v =		tostrings.Vector,
	m =		tostrings.table,
	xv2 = 	tostrings.Vector2,
	xm2 = 	tostrings.table,
	a = 	tostrings.Vector,
	xv4 = 	tostrings.Vector4,
}

local function normal_table_tostring( tbl, indenting, abortafter )
	local ret = ""
	local cost = 0
	for k,v in pairs( tbl ) do
		if tostrings[type(v)] then
			ret = ret .. rep("\t",indenting) .. k .. "\t=\t" .. tostrings[type(v)]( v ) .. "\n"
			cost = cost + 1
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

local table_tostring

local function var_tostring( k, v, typeid, indenting, printed, abortafter )
	local ret = ""
	local cost = 0
	if (typeid == "t" and not printed[v]) then -- If it's a table
		printed[v] = true
		ret = rep("\t",indenting) .. k .. ":\n"
		local ret2, cost2 = table_tostring( v, indenting + 2, printed, abortafter )
		ret = ret .. ret2
		cost = cost2 + 1
	elseif typeid == "r" and not printed[v] then -- if it's an array
		printed[v] = true
		ret = rep("\t",indenting) .. k .. ":\n"
		local ret2, cost2 = normal_table_tostring( v, indenting + 2, abortafter )
		ret = ret .. ret2
		cost = cost2 + 1
	elseif tostring_typeid[typeid] then -- if it's a type defined in this table
		ret = rep("\t",indenting) .. k .. "\t=\t" .. tostring_typeid[typeid]( v ) .. "\n"
		cost = 1
	else -- if it's anything else
		ret = rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
		cost = 1
	end
	return ret, cost
end

table_tostring = function( tbl, indenting, printed, abortafter )
	local ret = ""
	local cost = 0
	for k,v in pairs( tbl.n ) do
		local ret2, cost2 = var_tostring( k, v, tbl.ntypes[k], indenting, printed, abortafter )
		ret = ret .. ret2
		cost = cost + cost2
		if abortafter and cost > abortafter then
			ret = ret .. "\n- Aborted to prevent lag -"
			return ret, cost
		end
	end
	for k,v in pairs( tbl.s ) do
		local ret2, cost2 = var_tostring( k, v, tbl.stypes[k], indenting, printed, abortafter )
		ret = ret .. ret2
		cost = cost + cost2
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

__e2setcost(5)

registerOperator("ass", "t", "t", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)

	local Scope = self.Scopes[scope]
	if !Scope.lookup then Scope.lookup = {} end

	local lookup = Scope.lookup
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end
	if (!lookup[rhs]) then lookup[rhs] = {} end
	lookup[rhs][lhs] = true

	Scope[lhs] = rhs
	Scope.vclk[lhs] = true
	return rhs
end)

__e2setcost(1)

e2function number operator_is( table tbl )
	return (tbl.size > 0) and 1 or 0
end

e2function number operator==( table rv1, table rv2 )
	return (rv1 == rv2) and 1 or 0
end

e2function number operator!=( table rv1, table rv2 )
	return (rv1 ~= rv2) and 1 or 0
end

__e2setcost(nil)

registerOperator("fea","t","",function(self,args)
	local keyname,valname,valtypeid = args[2],args[3],args[4]
	local tbl = args[5]
	tbl = tbl[1](self,tbl)
	local statement = args[6]

	local keys = {}
	local count = 0
	for key,_ in pairs(tbl.s) do
		if (tbl.stypes[key] == valtypeid) then
			count = count + 1
			keys[count] = key
		end
	end

	for i=1, count do
		self:PushScope()
		local key = keys[i]
		if tbl.s[key] ~= nil then
			self.prf = self.prf + 3

			self.Scope.vclk[keyname] = true
			self.Scope.vclk[valname] = true

			self.Scope[keyname] = key
			self.Scope[valname] = tbl.s[key]

			local ok, msg = pcall(statement[1], self, statement)
			if not ok then
				if msg == "break" then self:PopScope() break
				elseif msg ~= "continue" then self:PopScope() error(msg, 0) end
			end
		end
		self:PopScope()
	end
end)

registerOperator( "kvtable", "", "t", function( self, args )
	local ret = table.Copy( DEFAULT )


	local types = args[3]

	local s, stypes, n, ntypes = {}, {}, {}, {}

	local size = 0
	for k,v in pairs( args[2] ) do
		if not blocked_types[types[k]] then
			local key = k[1]( self, k )

			if isstring(key) then
				s[key] = v[1]( self, v )
				stypes[key] = types[k]
			elseif isnumber(key) then
				n[key] = v[1]( self, v )
				ntypes[key] = types[k]
			end
			size = size + 1
		end
	end

	self.prf = self.prf + size * opcost
	ret.size = size
	ret.s = s
	ret.stypes = stypes
	ret.n = n
	ret.ntypes = ntypes
	return ret
end)

--------------------------------------------------------------------------------
-- Common functions
--------------------------------------------------------------------------------

__e2setcost(1)

-- Creates a table
e2function table table(...)
	local tbl = {...}
	if (#tbl == 0) then return table.Copy(DEFAULT) end
	local ret = table.Copy(DEFAULT)
	local size = 0
	for k,v in ipairs( tbl ) do
		if (!blocked_types[typeids[k]]) then
			size = size + 1
			ret.n[k] = v
			ret.ntypes[k] = typeids[k]
		end
	end
	ret.size = size
	self.prf = self.prf + size * opcost
	return ret
end

__e2setcost(1)

-- Erases everything in the table
e2function void table:clear()
	self.prf = self.prf + this.size * opcost
	table.Empty( this.n )
	this.ntypes = {}
	table.Empty( this.s )
	this.stypes = {}
	this.size = 0
	return this
end

__e2setcost(1)

-- Returns the number of elements in the table
e2function number table:count()
	return this.size
end

-- Returns the number of elements in the array-part of the table
e2function number table:ncount()
	return #this.n
end

__e2setcost(3)

__e2setcost(1)
-- Returns 1 if any value exists at the specified index, else 0
e2function number table:exists( index )
	return this.n[index] != nil and 1 or 0
end
e2function number table:exists( string index )
	return this.s[index] != nil and 1 or 0
end

__e2setcost(5)

e2function void printTable( table tbl )
	if (not checkOwner(self)) then return; end
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

__e2setcost(5)

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

-- Remove a variable at a number index
e2function void table:remove( number index )
	if (#this.n == 0) then return end
	if (!this.n[index]) then return end
	if index < 1 then -- table.remove doesn't work if the index is below 1
		this.n[index] = nil
		this.ntypes[index] = nil
	else
		table.remove( this.n, index )
		table.remove( this.ntypes, index )
	end
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
end

-- Remove a variable at a string index
e2function void table:remove( string index )
	if (IsEmpty(this.s)) then return end
	if (!this.s[index]) then return end
	this.s[index] = nil
	this.stypes[index] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
end

--------------------------------------------------------------------------------
-- Force remove
-- Forcibly removes the value from the array by setting it to nil
-- Does not shift larger indexes down to fill the hole
--------------------------------------------------------------------------------
e2function void table:unset( index )
	if this.n[index] == nil then return end
	this.n[index] = nil
	this.ntypes[index] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
end

-- Force remove for strings is an alias to table:remove(string)
e2function void table:unset( string index ) = e2function void table:remove( string index )

-- Removes all variables not of the type
e2function table table:clipToTypeid( string typeid )
	local ret = table.Copy(DEFAULT)
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] == typeid) then
			local n = #ret.n+1
			if istable(v) then
				ret.n[n] = table.Copy(v)
			else
				ret.n[n] = v
			end
			ret.ntypes[n] = this.ntypes[k]
			ret.size = ret.size + 1
		end
	end
	for k,v in pairs( this.s ) do
		if (this.stypes[k] == typeid) then
			if istable(v) then
				ret.s[k] = table.Copy(v)
			else
				ret.s[k] = v
			end
			ret.stypes[k] = this.stypes[k]
			ret.size = ret.size + 1
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
			if istable(v) then
				ret.n[k] = table.Copy(v)
			else
				ret.n[k] = v
			end
			ret.ntypes[k] = this.ntypes[k]
			ret.size = ret.size + 1
		end
	end
	for k,v in pairs( this.s ) do
		if (this.stypes[k] != typeid) then
			if istable(v) then
				ret.s[k] = table.Copy(v)
			else
				ret.s[k] = v
			end
			ret.stypes[k] = this.stypes[k]
			ret.size = ret.size + 1
		end
	end
	self.prf = self.prf + this.size * opcost
	return ret
end

__e2setcost(10)

e2function table table:clone()
	self.prf = self.prf + this.size * opcost
	return table.Copy(this)
end

__e2setcost(1)

e2function string table:id()
	return tostring(this)
end

__e2setcost(5)

-- Formats the table as a human readable string
e2function string table:toString()
	local printed = { [this] = true }
	local ret, cost = table_tostring( this, 0, printed )
	self.prf = self.prf + cost * opcost
	return ret
end

-- Adds rv2 to the end of 'this' (adds numerical indexes to the end of the array-part, and only inserts string indexes that don't exist on rv1)
e2function table table:add( table rv2 )
	local ret = table.Copy(this)
	local cost = this.size
	local size = this.size

	local count = #ret.n
	for k,v in pairs( rv2.n ) do
		cost = cost + 1
		local id = rv2.ntypes[k]
		if (!blocked_types[id]) then
			count = count + 1
			size = size + 1
			ret.n[count] = v
			ret.ntypes[count] = id
		end
	end

	for k,v in pairs( rv2.s ) do
		cost = cost + 1
		if (!ret.s[k]) then
			local id = rv2.stypes[k]
			if (!blocked_types[id]) then
				size = size + 1
				ret.s[k] = v
				ret.stypes[k] = id
			end
		end
	end

	self.prf = self.prf + cost * opcost
	ret.size = size
	return ret
end

-- Merges rv2 with 'this' (both numerical and string indexes are overwritten)
e2function table table:merge( table rv2 )
	local ret = table.Copy(this)
	local cost = this.size
	local size = this.size

	for k,v in pairs( rv2.n ) do
		cost = cost + 1
		local id = rv2.ntypes[k]
		if (!blocked_types[id]) then
			if (!ret.n[k]) then size = size + 1 end
			ret.n[k] = v
			ret.ntypes[k] = id
		end
	end

	for k,v in pairs( rv2.s ) do
		cost = cost + 1
		local id = rv2.stypes[k]
		if (!blocked_types[id]) then
			if (!ret.s[k]) then size = size + 1 end
			ret.s[k] = v
			ret.stypes[k] = id
		end
	end

	self.prf = self.prf + cost * opcost
	ret.size = size
	return ret
end

-- Removes all variables from 'this' which have keys which exist in rv2
e2function table table:difference( table rv2 )
	local ret = table.Copy(DEFAULT)
	local cost = 0
	local size = 0

	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (!rv2.n[k]) then
			size = size + 1
			ret.n[size] = v
			ret.ntypes[size] = this.ntypes[k]
		end
	end

	for k,v in pairs( this.s ) do
		cost = cost + 1
		if (!rv2.s[k]) then
			size = size + 1
			ret.s[k] = v
			ret.stypes[k] = this.stypes[k]
		end
	end
	self.prf = self.prf + cost * opcost
	ret.size = size

	return ret
end

-- Removes all variables from 'this' which don't have keys which exist in rv2
e2function table table:intersect( table rv2 )
	local ret = table.Copy(DEFAULT)
	local cost = 0
	local size = 0

	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (rv2.n[k]) then
			size = size + 1
			ret.n[size] = v
			ret.ntypes[size] = this.ntypes[k]
		end
	end

	for k,v in pairs( this.s ) do
		cost = cost + 1
		if (rv2.s[k]) then
			size = size + 1
			ret.s[k] = v
			ret.stypes[k] = this.stypes[k]
		end
	end
	self.prf = self.prf + cost * opcost
	ret.size = size

	return ret
end

--------------------------------------------------------------------------------
-- Array-part-only functions
--------------------------------------------------------------------------------

__e2setcost(3)

-- Removes the last element in the array part
e2function void table:pop()
	local n = #this.n
	if (n == 0) then return end
	this.n[n] = nil
	this.ntypes[n] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
end

-- Removes the first emelemt in the array part
e2function void table:shift()
	table.remove( this.n, 1 )
	table.remove( this.ntypes, 1 )
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
end

__e2setcost(5)

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

-- Returns the types of the variables in the array-part
e2function array table:typeidsArray()
	if (IsEmpty(this.n)) then return {} end
	self.prf = self.prf + table.Count(this.ntypes) * opcost
	return table.Copy(this.ntypes)
end

-- Converts the table into an array
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

__e2setcost(1)
local luaconcat = table.concat
local clamp = math.Clamp
local function concat( tab, delimeter, startindex, endindex )
	local ret = {}
	local len = #tab
	
	startindex = startindex or 1
	if startindex > len then return "" end
	
	endindex = clamp(endindex or len, startindex, len)
	
	for i=startindex, endindex do
		ret[#ret+1] = tostring(tab[i])
	end
	return luaconcat( ret, delimeter )
end

e2function string table:concat()
	self.prf = self.prf + #this * opcost
	return concat(this.n)
end
e2function string table:concat(string delimiter)
	self.prf = self.prf + #this * opcost
	return concat(this.n,delimiter)
end
e2function string table:concat(string delimiter, startindex)
	self.prf = self.prf + #this * opcost
	return concat(this.n,delimiter,startindex)
end
e2function string table:concat(string delimiter, startindex, endindex)
	self.prf = self.prf + #this * opcost
	return concat(this.n,delimiter,startindex,endindex)
end
e2function string table:concat(startindex)
	self.prf = self.prf + #this * opcost
	return concat(this.n,"",startindex,endindex)
end
e2function string table:concat(startindex,endindex)
	self.prf = self.prf + #this * opcost
	return concat(this.n,"",startindex,endindex)
end

--------------------------------------------------------------------------------
-- Table-part-only functions
--------------------------------------------------------------------------------

__e2setcost(5)

--------------------------------------------------------------------------------
-- Backwards compatibility functions (invert & co.)
--------------------------------------------------------------------------------

--- Returns a lookup table for <arr>. Usage: Index = T:number(toString(Value)).
--- Don't overuse this function, as it can become expensive for arrays with > 10 entries!
e2function table invert(array arr)
	local ret = table.Copy(DEFAULT)
	local c = 0
	local size = 0
	for i,v in ipairs(arr) do
		c = c + 1
		local tostring_this = tostrings[type(v)]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[tostring_this(v)] = "n"
			size = size + 1
		elseif (checkOwner(self)) then
			self.player:ChatPrint("E2: invert(R): Invalid type ("..type(v)..") in array. Ignored.")
		end
	end
	ret.size = size
	self.prf = self.prf + c * opcost
	return ret
end

--- Returns a lookup table for <tbl>. Usage: Key = T:string(toString(Value)).
--- Don't overuse this function, as it can become expensive for tables with > 10 entries!
e2function table invert(table tbl)
	local ret = table.Copy(DEFAULT)
	local c = 0
	local size = 0
	for i,v in pairs(tbl.n) do
		c = c + 1
		local typeid = tbl.ntypes[i]
		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[tostring_this(v)] = "n"
			size = size + 1
		elseif (checkOwner(self)) then
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	for i,v in pairs(tbl.s) do
		c = c + 1
		local typeid = tbl.stypes[i]
		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[tostring_this(v)] = "s"
			size = size + 1
		elseif (checkOwner(self)) then
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	self.prf = self.prf + c * opcost
	ret.size = size
	return ret
end

e2function array table:keys()
	local ret = {}
	local c = 0
	for index,value in pairs(this.n) do
		c = c + 1
		ret[#ret+1] = index
	end
	for index,value in pairs(this.s) do
		c = c + 1
		ret[#ret+1] = index
	end
	self.prf = self.prf + c * opcost
	return ret
end

e2function array table:values()
	local ret = {}
	local c = 0
	for index,value in pairs(this.n) do
		c = c + 1
		if (!tbls[this.ntypes[index]]) then
			ret[#ret+1] = value
		end
	end
	for index,value in pairs(this.s) do
		c = c + 1
		if (!tbls[this.stypes[index]]) then
			ret[#ret+1] = value
		end
	end
	self.prf = self.prf + c * opcost
	return ret
end

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

		__e2setcost(5)

		-- Getters
		registerOperator("idx",	id.."=ts"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1.s[rv2] or rv1.stypes[rv2] != id) then return fixdef(v[2]) end
			if (v[6] and v[6](rv1.s[rv2])) then return fixdef(v[2]) end -- Type check
			return rv1.s[rv2]
		end)

		registerOperator("idx",	id.."=tn"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1.n[rv2] or rv1.ntypes[rv2] != id) then return fixdef(v[2]) end
			if (v[6] and v[6](rv1.n[rv2])) then return fixdef(v[2]) end -- Type check
			return rv1.n[rv2]
		end)

		-- Setters
		registerOperator("idx", id.."=ts"..id , id, function( self, args )
			local op1, op2, op3, scope = args[2], args[3], args[4], args[5]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (rv1.s[rv2] == nil and rv3 ~= nil) then rv1.size = rv1.size + 1
			elseif (rv1.n[rv2] ~= nil and rv3 == nil) then rv1.size = rv1.size - 1 end
			rv1.s[rv2] = rv3
			rv1.stypes[rv2] = id
			self.GlobalScope.vclk[rv1] = true
			return rv3
		end)

		registerOperator("idx", id.."=tn"..id, id, function(self,args)
			local op1, op2, op3, scope = args[2], args[3], args[4], args[5]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (rv1.n[rv2] == nil and rv3 ~= nil) then rv1.size = rv1.size + 1
			elseif (rv1.n[rv2] ~= nil and rv3 == nil) then rv1.size = rv1.size - 1 end
			rv1.n[rv2] = rv3
			rv1.ntypes[rv2] = id
			self.GlobalScope.vclk[rv1] = true
			return rv3
		end)


		--------------------------------------------------------------------------------
		-- Remove functions
		--------------------------------------------------------------------------------

		__e2setcost(8)

		local function removefunc( self, rv1, rv2, numidx )
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (numidx) then
				if (!rv1.n[rv2] or rv1.ntypes[rv2] != id) then return fixdef(v[2]) end
				local ret = rv1.n[rv2]
				if rv2 < 1 then -- table.remove doesn't work if the index is below 1
					rv1.n[rv2] = nil
					rv1.ntypes[rv2] = nil
				else
					table.remove( rv1.n, rv2 )
					table.remove( rv1.ntypes, rv2 )
				end
				rv1.size = rv1.size - 1
				self.GlobalScope.vclk[rv1] = true
				return ret
			else
				if (!rv1.s[rv2] or rv1.stypes[rv2] != id) then return fixdef(v[2]) end
				local ret = rv1.s[rv2]
				rv1.s[rv2] = nil
				rv1.stypes[rv2] = nil
				self.GlobalScope.vclk[rv1] = true
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
		__e2setcost(10)

		-- Push a variable into the table (into the array part)
		registerFunction( "push"..name,"t:"..id,"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if rv2 == nil then return end
			local n = #rv1.n+1
			rv1.size = rv1.size + 1
			rv1.n[n] = rv2
			rv1.ntypes[n] = id
			self.GlobalScope.vclk[rv1] = true
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
			if rv3 == nil then return end
			if rv2 < 0 then return end
			if rv2 > 2^31 then return end -- too large, possibility of crashing gmod
			rv1.size = rv1.size + 1
			table.insert( rv1.n, rv2, rv3 )
			table.insert( rv1.ntypes, rv2, id )
			self.GlobalScope.vclk[rv1] = true
			return rv3
		end)

		registerFunction( "unshift"..name,"t:"..id,"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if rv2 == nil then return end
			rv1.size = rv1.size + 1
			table.insert( rv1.n, 1, rv2 )
			table.insert( rv1.ntypes, 1, id )
			self.GlobalScope.vclk[rv1] = true
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
	local Scope = self.GlobalScope
	local vclk, lookup = Scope.vclk, Scope.lookup

	-- Go through all registered values of the types table and array.
	for value,varnames in pairs(lookup) do
		local clk = vclk[value]

		local still_assigned = false
		-- For each value, go through the variables they're assigned to and trigger them.
		for varname,_ in pairs(varnames) do
			if value == Scope[varname] then
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
	local Scope = self.GlobalScope
	Scope.lookup = {}

	for k,v in pairs( Scope ) do
		if k != "lookup" then
			local datatype = self.entity.outports[3][k]
			if (tbls[datatype]) then
				if (!Scope.lookup[v]) then Scope.lookup[v] = {} end
				Scope.lookup[v][k] = true
			end
		end
	end
end)
