----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Formerly known as "mtable", this extension has now (15-11-2010) replaced the old table extension.
-- Made by Divran
----------------------------------------------------------------------------------------------------------------------------------------------------------------
local IsEmpty = table.IsEmpty
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
	xgt = true
}

--------------------------------------------------------------------------------

local function checkOwner(self)
	return IsValid(self.player)
end


--------------------------------------------------------------------------------
-- Type defining
--------------------------------------------------------------------------------

local newE2Table = E2Lib.newE2Table

registerType("table", "t", newE2Table(),
	function(self, input)
		if input.size == 0 then
			return newE2Table()
		end
		return input
	end,
	nil,
	nil,
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
			ret = ret .. formatPort[longtype](v, orientvertical)
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
	return "{" .. ret:sub(1, orientvertical and -2 or -3) .. "}"
end)

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Fix default values
local fixDefault = E2Lib.fixDefault

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
	f =		tostring
}

local function checkAbort( ret, cost, abortafter )
	if abortafter and cost > abortafter then
		if ret[#ret] ~= "\n- Aborted to prevent lag -" then
			ret[#ret+1] = "\n- Aborted to prevent lag -"
		end
		return true
	end

	return false
end

local function normal_table_tostring( tbl, indenting, abortafter, cost )
	local ret = {}
	local cost = cost or 0
	for k,v in pairs( tbl ) do
		if tostrings[type(v)] then
			ret[#ret+1] = rep("\t",indenting) .. k .. "\t=\t" .. tostrings[type(v)]( v ) .. "\n"
			cost = cost + 1
		else
			ret[#ret+1] = rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
			cost = cost + 1
		end

		if checkAbort( ret, cost, abortafter ) then return table.concat(ret), cost end
	end
	return table.concat(ret), cost
end

local table_tostring

local function var_tostring( k, v, typeid, indenting, printed, abortafter, cost )
	local ret = ""
	local cost = (cost or 0) + 1
	if (typeid == "t" and not printed[v]) then -- If it's a table
		printed[v] = true
		ret = rep("\t",indenting) .. k .. ":\n"
		local ret2, cost2 = table_tostring( v, indenting + 2, printed, abortafter, cost )
		ret = ret .. ret2
		cost = cost + cost2
	elseif typeid == "r" and not printed[v] then -- if it's an array
		printed[v] = true
		ret = rep("\t",indenting) .. k .. ":\n"
		local ret2, cost2 = normal_table_tostring( v, indenting + 2, abortafter, cost )
		ret = ret .. ret2
		cost = cost2
	elseif tostring_typeid[typeid] then -- if it's a type defined in this table
		ret = rep("\t",indenting) .. k .. "\t=\t" .. tostring_typeid[typeid]( v ) .. "\n"
	else -- if it's anything else
		ret = rep("\t",indenting) .. k .. "\t=\t" .. tostring(v) .. "\n"
	end
	return ret, cost + #ret * 0.05
end

table_tostring = function( tbl, indenting, printed, abortafter, cost )
	local ret = {}
	local cost = cost or 0
	for k,v in pairs( tbl.n ) do
		if checkAbort( ret, cost, abortafter ) then return table.concat(ret), cost end
		local ret2, cost2 = var_tostring( k, v, tbl.ntypes[k], indenting, printed, abortafter, cost )
		ret[#ret+1] = ret2
		cost = cost2
	end
	for k,v in pairs( tbl.s ) do
		if checkAbort( ret, cost, abortafter ) then return table.concat(ret), cost end
		local ret2, cost2 = var_tostring( k, v, tbl.stypes[k], indenting, printed, abortafter, cost )
		ret[#ret+1] = ret2
		cost = cost2
	end
	return table.concat(ret), cost
end

local TABLE_INIT_COST = opcost * 3
--- Creates a deep copy of an E2Table. This only deep copies tables and shallow copies arrays. Any other types are ignored.
--- @param self RuntimeContext
--- @param tbl E2Table
--- @return E2Table
local function deepCopy(self, tbl, lookup)
	local size = tbl.size
	local prf = self.prf + size * opcost

	local before
	if not lookup then
		lookup = {}
		before = collectgarbage("count") -- Init this only on the first run
	else -- Use the fact that lookup is only empty on first run to embed this extra cost
		prf = prf + TABLE_INIT_COST
	end

	if prf > e2_tickquota then
		self:forceThrow("perf")
	end

	self.prf = prf

	-- Now the table copying starts
	local ret = newE2Table()
	ret.size = size

	lookup[tbl] = ret

	local n = true

	local t_x, t_xtypes, r_x, r_xtypes = tbl.n, tbl.ntypes, ret.n, ret.ntypes
	::loop:: -- Don't be scared. This deduplicates code while being extremely lightweight for a single repetition
	for k, v in pairs(t_xtypes) do
		r_xtypes[k] = v
		if v == "t" then
			local tbl2 = t_x[k]
			local looked_up = lookup[tbl2]
			if looked_up then
				r_x[k] = looked_up
			else
				r_x[k] = deepCopy(self, tbl2, lookup)
			end
		elseif v == "r" then
			local arr2 = t_x[k]
			local arr = {}
			r_x[k] = arr

			local len = #arr2

			self.prf = self.prf + TABLE_INIT_COST + opcost * len -- Can't use prf here because self.prf can be modified by tables and arrays :(

			if prf > e2_tickquota then -- Have to do this awkwardly here
				self:forceThrow("perf")
			end

			for i = v[0] ~= nil and 0 or 1, len do -- Just copy array elements by reference since we cannot typecheck
				arr[i] = arr2[i]
			end
		else
			r_x[k] = t_x[k]
		end
	end

	if n then
		t_x, t_xtypes, r_x, r_xtypes = tbl.s, tbl.stypes, ret.s, ret.stypes
		n = false
		goto loop -- Blazingly fast pseudo-optimization
	end

	if before then -- `before` is only init on first run
		local mem = (collectgarbage("count") - before)
		if mem > 0 then
			self.prf = self.prf + mem * 20
		end
	end

	return ret
end

--- Increases and checks the perf of the chip based on the given size. Throws perf exception to `self` is this operation would hit the tick quota. Auxiliary of table_perf_check.
--- @param self RuntimeContext
--- @param size integer The number of elements to check
--- @return number perf # The adjusted op count after increasing
local function num_perf_check(self, size)
	local prf = self.prf + size * opcost

	if prf > e2_tickquota then
		self:forceThrow("perf")
	end
	self.prf = prf

	return prf
end

--- Increases and checks the perf of the chip. Throws perf exception to `self` if this operation would hit the tick quota.
--- @param self RuntimeContext
--- @param tbl E2Table
--- @return number size # The size of the table
--- @return number perf # The adjusted op count after increasing
local function table_perf_check(self, tbl)
	local size = tbl.size
	return size, num_perf_check(self, size)
end

--- Creates a shallow copy of an E2Table.
--- @param self RuntimeContext
--- @param tbl E2Table
--- @return E2Table
local function shallowCopy(self, tbl)
	local size = table_perf_check(self, tbl)

	local ret = newE2Table()
	ret.size = size

	local n = true

	local t_x, t_xtypes, r_x, r_xtypes = tbl.n, tbl.ntypes, ret.n, ret.ntypes
	::loop::
	for k, v in pairs(t_xtypes) do
		r_xtypes[k] = v
		r_x[k] = t_x[k]
	end

	if n then
		t_x, t_xtypes, r_x, r_xtypes = tbl.s, tbl.stypes, ret.s, ret.stypes
		n = false
		goto loop
	end

	return ret
end

--------------------------------------------------------------------------------
-- Operators
--------------------------------------------------------------------------------

__e2setcost(1)

e2function number operator_is(table this)
	return (this.size > 0) and 1 or 0
end

--------------------------------------------------------------------------------
-- Common functions
--------------------------------------------------------------------------------

__e2setcost(1)

-- Creates a table
e2function table table(...tbl)
	table_check_perf(self, tbl)

	local ret = newE2Table()
	if #tbl == 0 then return ret end -- Don't construct table

	local size = 0

	for k, v in ipairs(tbl) do
		local tid = typeids[k]
		if blocked_types[tid] then
			self:throw("Type '" .. wire_expression_types2[tid][1] .. "' is not allowed inside of a table")
		else
			size = size + 1
			ret.n[k] = v
			ret.ntypes[k] = tid
		end
	end

	ret.size = size
	return ret
end

__e2setcost(3)

-- Erases everything in the table
e2function void table:clear()
	this.n = {}
	this.ntypes = {}
	this.s = {}
	this.stypes = {}
	this.size = 0
	return this
end

__e2setcost(1)

-- Returns the number of elements in the table
e2function number table:count()
	return this.size
end

__e2setcost(3)
-- Returns the number of elements in the array-part of the table
e2function number table:ncount()
	return #this.n
end

__e2setcost(1)
-- Returns 1 if any value exists at the specified index, else 0
e2function number table:exists( index )
	return this.n[index] ~= nil and 1 or 0
end
e2function number table:exists( string index )
	return this.s[index] ~= nil and 1 or 0
end

__e2setcost(5)

e2function void printTable( table tbl )
	if not checkOwner(self) then return end
	if tbl.size > 200 then
		self.player:ChatPrint("Table has more than 200 ("..tbl.size..") elements. PrintTable cancelled to prevent lag")
		return
	end
	local printed = { [tbl] = true }
	local ret, cost = table_tostring( tbl, 0, printed, 200 )
	self.prf = self.prf + cost
	for str in string.gmatch( ret, "[^\n]+" ) do
		if #str > 250 then
			self.prf = self.prf + 100
			self.player:ChatPrint("PrintTable attempted to print too much. PrintTable was cancelled to prevent lag")
			return
		end
		self.player:ChatPrint( str )
	end
end

__e2setcost(5)

-- Flip the numbers and strings of the table
e2function table table:flip()
	local ret = newE2Table()
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
	local size = table_perf_check(self, this)

	local n = true

	local ret = newE2Table()
	ret.size = size

	local to, from, types = ret.n, this.ntypes, ret.ntypes

	::loop::
	for k, v in pairs(from) do
		to[k] = v
		types[k] = "s"
	end

	if n then
		to, from, types = ret.s, this.stypes, ret.stypes
		n = false
		goto loop
	end

	return ret
end

-- Removes the specified entry from the array-part and returns 1 if removed
e2function number table:remove( number index )
	if (#this.n == 0) then return 0 end
	if (not this.n[index]) then return 0 end
	if index < 1 then -- table.remove doesn't work if the index is below 1
		this.n[index] = nil
		this.ntypes[index] = nil
	else
		table.remove( this.n, index )
		table.remove( this.ntypes, index )
	end
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
	return 1
end

-- Force removes the specified entry from the table-part, without moving subsequent entries down and returns 1 if removed
e2function number table:remove( string index )
	if (IsEmpty(this.s)) then return 0 end
	if (not this.s[index]) then return 0 end
	this.s[index] = nil
	this.stypes[index] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
	return 1
end

--------------------------------------------------------------------------------
-- Force remove
-- Force removes the specified entry from the array-part, without moving subsequent entries down and returns 1 if removed
-- Does not shift larger indexes down to fill the hole
--------------------------------------------------------------------------------
e2function number table:unset( index )
	if this.n[index] == nil then return 0 end
	this.n[index] = nil
	this.ntypes[index] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
	return 1
end

-- Force remove for strings is an alias to table:remove(string)
e2function number table:unset( string index ) = e2function number table:remove( string index )

-- Removes all variables not of the type
e2function table table:clipToTypeid( string typeid )
	table_perf_check(self, this)

	local ret, ret_size = newE2Table(), 0

	local this_ntypes, this_stypes = this.ntypes, this.stypes
	local ret_ntypes, ret_stypes = ret.ntypes, ret.stypes
	local ret_n, ret_s = ret.n, ret.s

	for k, v in pairs( this.n ) do
		if this_ntypes[k] == typeid then
			local n = ret_size + 1
			ret_n[n] = v
			ret_ntypes[n] = this_ntypes[k]
			ret_size = ret_size + 1
		end
	end

	for k, v in pairs( this.s ) do
		if this_stypes[k] == typeid then
			ret_s[k] = v
			ret_stypes[k] = this_stypes[k]
			ret_size = ret_size + 1
		end
	end

	ret.size = ret_size
	return ret
end

-- Removes all variables of the type
e2function table table:clipFromTypeid( string typeid )
	table_perf_check(self, this)

	local ret = newE2Table()

	for k,v in pairs( this.n ) do
		if (this.ntypes[k] ~= typeid) then
			if istable(v) then
				ret.n[k] = prf_clone(self, v)
			else
				ret.n[k] = v
			end
			ret.ntypes[k] = this.ntypes[k]
			ret.size = ret.size + 1
		end
	end

	for k, v in pairs( this.s ) do
		if (this.stypes[k] ~= typeid) then
			if istable(v) then
				ret.s[k] = prf_clone(self, v)
			else
				ret.s[k] = v
			end
			ret.stypes[k] = this.stypes[k]
			ret.size = ret.size + 1
		end
	end

	return ret
end

__e2setcost(10)

e2function table table:clone()
	return deepCopy(self, this)
end

e2function table table:copy()
	return shallowCopy(self, this)
end

__e2setcost(1)

e2function string table:id()
	return tostring(this)
end

__e2setcost(5)

-- Formats the table as a human readable string
e2function string table:toString()
	local printed = { [this] = true }
	local ret, cost = table_tostring( this, 0, printed, 4000 )
	self.prf = self.prf + cost * opcost
	if self.prf > e2_tickquota then self:forceThrow("perf") end
	return ret
end

-- Adds rv2 to the end of 'this' (adds numerical indexes to the end of the array-part, and only inserts string indexes that don't exist on rv1)
e2function table table:add( table rv2 )
	table_perf_check(self, rv2)
	local ret = shallowCopy(self, this)

	local size = ret.size

	local ret_n, ret_ntypes = ret.n, ret.ntypes
	local ret_s, ret_stypes = ret.s, ret.stypes

	local rv2_n, rv2_ntypes = rv2.n, rv2.ntypes
	local rv2_s, rv2_stypes = rv2.s, rv2.stypes

	local count = #ret.n
	for k, v in pairs( rv2_n ) do
		local id = rv2_ntypes[k]
		if not blocked_types[id] then
			count = count + 1
			size = size + 1

			ret_n[count] = v
			ret_ntypes[count] = id
		end
	end

	for k, v in pairs( rv2_s ) do
		if not ret_s[k] then
			local id = rv2_stypes[k]
			if not blocked_types[id] then
				size = size + 1

				ret_s[k] = v
				ret_stypes[k] = id
			end
		end
	end

	ret.size = size
	return ret
end

-- Merges rv2 with 'this' (both numerical and string indexes are overwritten)
e2function table table:merge( table rv2 )
	table_perf_check(self, rv2)
	local ret = shallowCopy(self, this)

	local size = ret.size

	for k,v in pairs( rv2.n ) do
		local id = rv2.ntypes[k]
		if not blocked_types[id] then
			if not ret.n[k] then size = size + 1 end
			ret.n[k] = v
			ret.ntypes[k] = id
		end
	end

	for k,v in pairs( rv2.s ) do
		local id = rv2.stypes[k]
		if not blocked_types[id] then
			if not ret.s[k] then size = size + 1 end
			ret.s[k] = v
			ret.stypes[k] = id
		end
	end

	ret.size = size
	return ret
end

-- Removes all variables from 'this' which have keys which exist in rv2
e2function table table:difference( table rv2 )
	table_perf_check(self, this)
	local ret = newE2Table()
	local size = 0

	for k,v in pairs( this.n ) do
		if not rv2.n[k] then
			size = size + 1
			ret.n[size] = v
			ret.ntypes[size] = this.ntypes[k]
		end
	end

	for k,v in pairs( this.s ) do
		if not rv2.s[k] then
			size = size + 1
			ret.s[k] = v
			ret.stypes[k] = this.stypes[k]
		end
	end

	ret.size = size
	return ret
end

-- Removes all variables from 'this' which don't have keys which exist in rv2
e2function table table:intersect( table rv2 )
	table_perf_check(self, this)
	local ret = newE2Table()
	local cost = 0
	local size = 0

	for k,v in pairs( this.n ) do
		cost = cost + 1
		if rv2.n[k] then
			size = size + 1
			ret.n[size] = v
			ret.ntypes[size] = this.ntypes[k]
		end
	end

	for k,v in pairs( this.s ) do
		cost = cost + 1
		if rv2.s[k] then
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

-- Removes the last entry in the array-part and returns 1 if removed
e2function number table:pop()
	local n = #this.n
	if (n == 0) then return 0 end
	this.n[n] = nil
	this.ntypes[n] = nil
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
	return 1
end

-- Deletes the first element of the table; all other entries will move down one address and returns 1 if removed
e2function number table:shift()
	local result = table.remove( this.n, 1 ) and 1 or 0
	table.remove( this.ntypes, 1 )
	this.size = this.size - 1
	self.GlobalScope.vclk[this] = true
	return result
end

__e2setcost(5)

-- Returns the smallest number in the array-part
e2function number table:min()
	if (IsEmpty(this.n)) then return 0 end
	table_perf_check(self, this)
	local smallest = nil
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] == "n") then
			if (smallest == nil or v < smallest) then
				smallest = v
			end
		end
	end
	return smallest or 0
end

-- Returns the largest number in the array-part
e2function number table:max()
	if (IsEmpty(this.n)) then return 0 end
	table_perf_check(self, this)
	local largest = nil
	for k,v in pairs( this.n ) do
		if (this.ntypes[k] == "n") then
			if (largest == nil or v > largest) then
				largest = v
			end
		end
	end
	return largest or 0
end

-- Returns the index of the largest number in the array-part
e2function number table:maxIndex()
	if (IsEmpty(this.n)) then return 0 end
	table_perf_check(self, this)
	local largest = nil
	local index = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (largest == nil or v > largest) then
				largest = v
				index = k
			end
		end
	end
	return index
end

-- Returns the index of the smallest number in the array-part
e2function number table:minIndex()
	if (IsEmpty(this.n)) then return 0 end
	table_perf_check(self, this)
	local smallest = nil
	local index = 0
	for k,v in pairs( this.n ) do
		cost = cost + 1
		if (this.ntypes[k] == "n") then
			if (smallest == nil or v < smallest) then
				smallest = v
				index = k
			end
		end
	end
	return index
end

-- Returns the types of the variables in the array-part
e2function array table:typeidsArray()
	if IsEmpty(this.n) then return {} end

	table_perf_check(self, this)

	local ret = {}

	for i, v in ipairs(this.ntypes) do
		ret[i] = v
	end

	return ret
end

-- Converts the table into an array
e2function array table:toArray()
	if IsEmpty(this.n) then return {} end
	table_perf_check(self, this)
	local ret = {}
	for k,v in pairs( this.n ) do
		local id = this.ntypes[k]
		if (tbls[id] ~= true) then
			ret[k] = v
		end
	end
	return ret
end

__e2setcost(20)

-- Returns the find in the array part of an table
e2function table findToTable()
	local ret = newE2Table()
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
local function concat(self, tab, delimeter, startindex, endindex)
	local len = #tab

	startindex = startindex or 1
	if startindex > len then return "" end

	endindex = clamp(endindex or len, startindex, len)

	num_perf_check(self, endindex - startindex)

	local ret = {}

	for i=startindex, endindex do
		ret[#ret+1] = tostring(tab[i])
	end
	return luaconcat( ret, delimeter )
end

e2function string table:concat()
	return concat(self, this.n)
end

e2function string table:concat(string delimiter)
	return concat(self, this.n,delimiter)
end

e2function string table:concat(string delimiter, startindex)
	return concat(self, this.n,delimiter,startindex)
end

e2function string table:concat(string delimiter, startindex, endindex)
	return concat(self, this.n,delimiter,startindex,endindex)
end

e2function string table:concat(startindex)
	return concat(self, this.n,"",startindex)
end

e2function string table:concat(startindex,endindex)
	return concat(self, this.n,"",startindex,endindex)
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
	num_perf_check(self, #arr)

	local ret = newE2Table()
	local size = 0
	for i,v in ipairs(arr) do
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
	return ret
end

--- Returns a lookup table for <tbl>. Usage: Key = T:string(toString(Value)).
--- Don't overuse this function, as it can become expensive for tables with > 10 entries!
e2function table invert(table tbl)
	table_perf_check(self, tbl)
	local ret = newE2Table()
	local size = 0
	for i,v in pairs(tbl.n) do
		local typeid = tbl.ntypes[i]
		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[tostring_this(v)] = "n"
			size = size + 1
		elseif checkOwner(self) then
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	for i,v in pairs(tbl.s) do
		local typeid = tbl.stypes[i]
		local tostring_this = tostring_typeid[typeid]
		if tostring_this then
			ret.s[tostring_this(v)] = i
			ret.stypes[tostring_this(v)] = "s"
			size = size + 1
		elseif checkOwner(self) then
			self.player:ChatPrint("E2: invert(T): Invalid type ("..typeid..") in table. Ignored.")
		end
	end
	ret.size = size
	return ret
end

e2function array table:keys()
	table_perf_check(self, this)
	local ret = {}
	for index in pairs(this.n) do
		ret[#ret+1] = index
	end
	for index in pairs(this.s) do
		ret[#ret+1] = index
	end
	return ret
end

e2function array table:values()
	table_perf_check(self, this)
	local ret = {}
	for index,value in pairs(this.n) do
		if (not tbls[this.ntypes[index]]) then
			ret[#ret+1] = value
		end
	end
	for index,value in pairs(this.s) do
		if (not tbls[this.stypes[index]]) then
			ret[#ret+1] = value
		end
	end
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
		local default = v[2]
		local typecheck = v[6]

		if (not blocked_types[id]) then -- blocked check start

		--------------------------------------------------------------------------------
		-- Set/Get functions, t[index,type] syntax
		--------------------------------------------------------------------------------

		__e2setcost(3)

		-- Getters
		if typecheck then -- If there's a type check
			registerOperator("indexget", "ts" .. id, id, function(self, tbl, key)
				if not tbl.s[key] or tbl.stypes[key] ~= id then
					return fixDefault(default)
				end

				if typecheck(tbl.s[key]) then
					return fixDefault(default)
				end

				return tbl.s[key]
			end)

			registerOperator("indexget", "tn" .. id, id, function(self, tbl, key)
				if not tbl.n[key] or tbl.ntypes[key] ~= id then
					return fixDefault(default)
				end

				if typecheck(tbl.n[key]) then
					return fixDefault(default)
				end

				return tbl.n[key]
			end, 2)
		else
			registerOperator("indexget", "ts" .. id, id, function(self, tbl, key)
				if not tbl.s[key] or tbl.stypes[key] ~= id then
					return fixDefault(default)
				end

				return tbl.s[key]
			end, 1)

			registerOperator("indexget", "tn" .. id, id, function(self, tbl, key)
				if not tbl.n[key] or tbl.ntypes[key] ~= id then
					return fixDefault(default)
				end

				return tbl.n[key]
			end, 1)
		end

		-- Setters
		registerOperator("indexset", "ts" .. id , "", function(self, tbl, key, value)
			if tbl.s[key] == nil and value ~= nil then
				tbl.size = tbl.size + 1
			elseif tbl.s[key] ~= nil and value == nil then
				tbl.size = tbl.size - 1
			end

			tbl.s[key], tbl.stypes[key] = value, id
			self.GlobalScope.vclk[tbl] = true
		end)

		registerOperator("indexset", "tn" .. id, "", function(self, tbl, key, value)
			if tbl.n[key] == nil and value ~= nil then
				tbl.size = tbl.size + 1
			elseif tbl.n[key] ~= nil and value == nil then
				tbl.size = tbl.size - 1
			end

			tbl.n[key], tbl.ntypes[key] = value, id
			self.GlobalScope.vclk[tbl] = true
		end)


		--------------------------------------------------------------------------------
		-- Remove functions
		--------------------------------------------------------------------------------

		__e2setcost(8)

		local function removefunc( self, rv1, rv2, numidx )
			if (not rv1 or not rv2) then return fixDefault(v[2]) end
			if (numidx) then
				if (not rv1.n[rv2] or rv1.ntypes[rv2] ~= id) then return fixDefault(v[2]) end
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
				if (not rv1.s[rv2] or rv1.stypes[rv2] ~= id) then return fixDefault(v[2]) end
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
			if rv2 < 0 then return self:throw("Insert key cannot be negative!") end
			if rv2 > 2^31 then return self:throw("Insert key too large!") end -- too large, possibility of crashing gmod
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

		--------------------------------------------------------------------------------
		-- Foreach operators
		--------------------------------------------------------------------------------
		__e2setcost(0)

		local next = next
		local function itern(tbl, i)
			local value
			repeat
				i, value = next(tbl.n, i)
			until tbl.ntypes[i] == id or value == nil
			return i, value
		end

		local function iters(tbl, i)
			local value
			repeat
				i, value = next(tbl.s, i)
			until tbl.stypes[i] == id or value == nil
			return i, value
		end

		registerOperator("iter", "s" .. id .. "=t", "", function(state, table)
			return function()
				return iters, table
			end
		end)

		registerOperator("iter", "n" .. id .. "=t", "", function(state, table)
			return function()
				return itern, table
			end
		end)

		end -- blocked check end

	end
end)

--------------------------------------------------------------------------------
-- "lookup" stuff copied from the old table.lua file
--------------------------------------------------------------------------------

-- these postexecute and construct hooks handle changes to both tables and arrays.
registerCallback("postexecute", function(self) --- @param self RuntimeContext
	local Scope = self.GlobalScope
	local vclk, lookup = Scope.vclk, Scope.lookup

	-- Go through all registered values of the types table and array.
	for value,varnames in pairs(lookup) do
		local clk = vclk[value]

		local still_assigned = false
		-- For each value, go through the variables they're assigned to and trigger them.
		for varname,_ in pairs(varnames) do
			if rawequal(value,Scope[varname]) then
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

registerCallback("construct", function(self)
	local Scope = self.GlobalScope
	Scope.lookup = {}

	for k,v in pairs( Scope ) do
		if k ~= "lookup" then
			local datatype = self.entity.outports[3][k]
			if (E2Lib.IOTableTypes[datatype]) then
				if (not Scope.lookup[v]) then Scope.lookup[v] = {} end
				Scope.lookup[v][k] = true
			end
		end
	end
end)
