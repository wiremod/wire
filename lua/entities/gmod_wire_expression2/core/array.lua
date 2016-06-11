--------------------------------------------------------------------------------
-- Array Support
-- Original author: Unknown (But the Wiki mentions Erkle)
-- Rewritten by Divran at 2010-12-21
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Helper functions and constants
--------------------------------------------------------------------------------

local table_insert = table.insert
local table_remove = table.remove
local floor = math.floor

local blocked_types = {
	["t"] = true,
	["r"] = true,
	["xgt"] = true
}

-- Fix return values
local function fixdef( val )
	return istable(val) and table.Copy(val) or val
end

-- Uppercases the first letter
local function upperfirst( word )
	return word:Left(1):upper() .. word:Right(-2):lower()
end

--------------------------------------------------------------------------------
-- Type
--------------------------------------------------------------------------------

registerType("array", "r", {},
	function(self, input)
		local ret = {}
		self.prf = self.prf + #input / 3
		for k,v in pairs(input) do ret[k] = v end
		return ret
	end,
	nil,
	function(retval)
		if !istable(retval) then error("Return value is not a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return !istable(v)
	end
)

--------------------------------------------------------------------------------
-- Array(...)
-- Constructs and returns an array with the given values as elements. If you specify values that are not supported by the array data type, they are skipped
--------------------------------------------------------------------------------
__e2setcost(1)
e2function array array(...)
	local ret = {...}
	if (#ret == 0) then return {} end -- This is in place of the old "array()" function (now deleted because array(...) overwrote it)
	for k,v in pairs( ret ) do
		self.prf = self.prf + 1/3
		if (blocked_types[typeids[k]]) then ret[k] = nil end
	end
	return ret
end

registerOperator( "kvarray", "", "r", function( self, args )
	local ret = {}

	local values = args[2]
	local types = args[3]

	for k,v in pairs( values ) do
		if not blocked_types[types[k]] then
			local key = k[1]( self, k )
			local value = v[1]( self, v )

			ret[key] = value

			self.prf = self.prf + 1/3
		end
	end

	return ret
end)

--------------------------------------------------------------------------------
-- = operator
--------------------------------------------------------------------------------
registerOperator("ass", "r", "r", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)

	local Scope = self.Scopes[scope]
	if !Scope.lookup then Scope.lookup = {} end
	local lookup = Scope.lookup

	--remove old lookup entry
	if (lookup[rhs]) then lookup[rhs][lhs] = nil end

	--add new
	if (!lookup[rhs]) then
		lookup[rhs] = {}
	end
	lookup[rhs][lhs] = true

	Scope[lhs] = rhs
	Scope.vclk[lhs] = true
	return rhs
end)



--------------------------------------------------------------------------------
-- IS operator
--------------------------------------------------------------------------------
e2function number operator_is(array arr)
	return istable(arr) and 1 or 0
end

--------------------------------------------------------------------------------
-- Looped functions and operators
--------------------------------------------------------------------------------
registerCallback( "postinit", function()
	local getf, setf
	for k,v in pairs( wire_expression_types ) do
		local name = k:lower()
		if (name == "normal") then name = "number" end
		local nameupperfirst = upperfirst( name )
		local id = v[1]
		local default = v[2]
		local typecheck = v[6]

		if (!blocked_types[id]) then -- blocked check start

			--------------------------------------------------------------------------------
			-- Get functions
			-- value = R[N,type], and value = R:<type>(N)
			--------------------------------------------------------------------------------
			__e2setcost(10)

			local function getter( self, array, index, doremove )
				if (!array or !index) then return fixdef( default ) end -- Make sure array and index are value
				local ret
				if (doremove) then
					ret = table_remove( array, index )
					self.GlobalScope.vclk[array] = true
				else
					ret = array[floor(index)]
				end
				if (typecheck and typecheck( ret )) then return fixdef( default ) end -- If typecheck returns true, the type is wrong.
				return ret
			end

			registerOperator("idx", id.."=rn", id, function(self,args)
				local op1, op2 = args[2], args[3]
				local array, index = op1[1](self,op1), op2[1](self,op2)
				return getter( self, array, index )
			end)

			registerFunction( name, "r:n", id, function(self,args)
				local op1, op2 = args[2], args[3]
				local array, index = op1[1](self,op1), op2[1](self,op2)
				return getter( self, array, index )
			end)

			--------------------------------------------------------------------------------
			-- Set functions
			-- R[N,type] = value, and R:set<type>(N,value)
			--------------------------------------------------------------------------------

			local function setter( self, array, index, value, doinsert )
				if (!array or !index) then return fixdef( default ) end -- Make sure array and index are valid
				if (typecheck and typecheck( value )) then return fixdef( default ) end -- If typecheck returns true, the type is wrong.
				if (doinsert) then
					if index > 2^31 or index < 0 then return fixdef( default ) end -- too large, possibility of crashing gmod
					table_insert( array, index, value )
				else
					array[floor(index)] = value
				end
				self.GlobalScope.vclk[array] = true
				return value
			end

			registerOperator("idx", id.."=rn"..id, id, function(self,args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local array, index, value = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
				return setter( self, array, index, value )
			end)

			registerFunction("set" .. nameupperfirst, "r:n"..id, id, function(self,args)
				local op1, op2, op3 = args[2], args[3], args[4]
				local array, index, value = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
				return setter( self, array, index, value )
			end)


			--------------------------------------------------------------------------------
			-- Push functions
			-- Inserts the value at the end of the array
			--------------------------------------------------------------------------------
			__e2setcost(15)

			registerFunction( "push" .. nameupperfirst, "r:" .. id, id, function(self,args)
				local op1, op2 = args[2], args[3]
				local array, value = op1[1](self,op1), op2[1](self,op2)
				return setter( self, array, #array + 1, value )
			end)

			--------------------------------------------------------------------------------
			-- Insert functions
			-- Inserts the value at the specified index. Subsequent values are moved up to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "insert" .. nameupperfirst, "r:n" .. id, id, function( self, args )
				local op1, op2, op3 = args[2], args[3], args[4]
				local array, index, value = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
				return setter( self, array, index, value, true )
			end)

			--------------------------------------------------------------------------------
			-- Pop functions
			-- Removes and returns the last value in the array.
			--------------------------------------------------------------------------------
			registerFunction( "pop" .. nameupperfirst, "r:", id, function(self,args)
				local op1 = args[2]
				local array = op1[1](self,op1)
				if (!array) then return fixdef( default ) end
				return getter( self, array, #array, true )
			end)

			--------------------------------------------------------------------------------
			-- Unshift functions
			-- Inserts the value at the beginning of the array. Subsequent values are moved up to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "unshift" .. nameupperfirst, "r:" .. id, id, function(self,args)
				local op1, op2 = args[2], args[3]
				local array, value = op1[1](self,op1), op2[1](self,op2)
				return setter( self, array, 1, value, true )
			end)

			--------------------------------------------------------------------------------
			-- Shift functions
			-- Removes and returns the first value of the array. Subsequent values are moved down to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "shift" .. nameupperfirst, "r:", id, function(self,args)
				local op1 = args[2]
				local array = op1[1](self,op1)
				if (!array) then return fixdef( default ) end
				return getter( self, array, 1, true )
			end)

			--------------------------------------------------------------------------------
			-- Remove functions
			-- Removes and returns the specified value of the array. Subsequent values are moved down to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "remove" .. nameupperfirst, "r:n", id, function(self,args)
				local op1, op2 = args[2], args[3]
				local array, index = op1[1](self,op1), op2[1](self,op2)
				if (!array or !index) then return fixdef( default ) end
				return getter( self, array, index, true )
			end)


		end -- blocked check end
	end
end)

--------------------------------------------------------------------------------
-- Pop
-- Removes the last entry in the array
--------------------------------------------------------------------------------
__e2setcost(15)
e2function void array:pop()
	table_remove( this )
	self.GlobalScope.vclk[this] = true
end

--------------------------------------------------------------------------------
-- Remove
-- Removes the specified entry in the array
--------------------------------------------------------------------------------
__e2setcost(15)
e2function void array:remove( index )
	table_remove( this, index )
	self.GlobalScope.vclk[this] = true
end

--------------------------------------------------------------------------------
-- Force remove
-- Forcibly removes the value from the array by setting it to nil
-- Does not shift larger indexes down to fill the hole
--------------------------------------------------------------------------------
e2function void array:unset( index )
	if this[index] == nil then return end
	this[index] = nil
	self.GlobalScope.vclk[this] = true
end

--------------------------------------------------------------------------------
-- Shift
-- Removes the first entry in the array
--------------------------------------------------------------------------------
__e2setcost(15)
e2function void array:shift()
	table_remove( this, 1 )
	self.GlobalScope.vclk[this] = true
end

--------------------------------------------------------------------------------
-- Exists
-- Returns 1 if any value exists at the specified index, 0 if not
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:exists( index )
	return this[index] != nil and 1 or 0
end

--------------------------------------------------------------------------------
-- Count
-- Returns the number of entries in the array
--------------------------------------------------------------------------------
__e2setcost(5)
e2function number array:count()
	return #this
end

--------------------------------------------------------------------------------
-- Clear
-- Empties the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function void array:clear()
	self.prf = self.prf + #this / 3
	table.Empty(this)
end

--------------------------------------------------------------------------------
-- Clone
-- Returns a copy of the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function array array:clone()
	local ret = {}
	self.prf = self.prf + #this / 3
	for k,v in pairs(this) do
		ret[k] = v
	end
	return ret
end

--------------------------------------------------------------------------------
-- Sum
-- Returns the sum of all numerical values in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:sum()
	local ret = 0
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		ret = ret + (tonumber(v) or 0)
	end
	self.prf = self.prf + indexes / 2
	return ret
end

--------------------------------------------------------------------------------
-- Average
-- Returns the average of all numerical values in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:average()
	local ret = 0
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		ret = ret + (tonumber(v) or 0)
	end
	self.prf = self.prf + indexes / 2
	return ret / indexes
end

--------------------------------------------------------------------------------
-- Min
-- Returns the smallest value in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:min()
	local num
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		local val = tonumber(v) or 0
		if (num == nil or val < num) then
			num = val
		end
	end
	self.prf = self.prf + indexes / 2
	return num or 0
end

--------------------------------------------------------------------------------
-- MinIndex
-- Returns the index of the smallest value in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:minIndex()
	local num = nil
	local index = nil
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		local val = tonumber(v) or 0
		if (num == nil or val < num) then
			num = val
			index = k
		end
	end
	self.prf = self.prf + indexes / 2
	return index or 0
end

--------------------------------------------------------------------------------
-- Max
-- Returns the largest value in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:max()
	local num
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		local val = tonumber(v) or 0
		if (num == nil or val > num) then
			num = val
		end
	end
	self.prf = self.prf + indexes / 2
	return num or 0
end

--------------------------------------------------------------------------------
-- MaxIndex
-- Returns the index of the largest value in the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:maxIndex()
	local num = nil
	local index = nil
	local indexes = 0
	for k,v in pairs( this ) do
		indexes = indexes + 1
		local val = tonumber(v) or 0
		if (num == nil or val > num) then
			num = val
			index = k
		end
	end
	self.prf = self.prf + indexes / 2
	return index or 0
end

--------------------------------------------------------------------------------
-- Concat
-- Concatenates the values of the array
--------------------------------------------------------------------------------
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

e2function string array:concat()
	self.prf = self.prf + #this/3
	return concat(this)
end
e2function string array:concat(string delimiter)
	self.prf = self.prf + #this/3
	return concat(this,delimiter)
end
e2function string array:concat(string delimiter, startindex)
	self.prf = self.prf + #this/3
	return concat(this,delimiter,startindex)
end
e2function string array:concat(string delimiter, startindex, endindex)
	self.prf = self.prf + #this/3
	return concat(this,delimiter,startindex,endindex)
end
e2function string array:concat(startindex)
	self.prf = self.prf + #this/3
	return concat(this,"",startindex,endindex)
end
e2function string array:concat(startindex,endindex)
	self.prf = self.prf + #this/3
	return concat(this,"",startindex,endindex)
end

--------------------------------------------------------------------------------
-- Id
-- Returns a string identifier representing the array
--------------------------------------------------------------------------------
__e2setcost(1)
e2function string array:id()
	return tostring(this)
end

--------------------------------------------------------------------------------
-- Add
-- Add the contents of the specified array to the end of 'this'
--------------------------------------------------------------------------------
__e2setcost(1)
e2function array array:add( array other )
	if (!next(this) and !next(other)) then return {} end -- Both of them are empty
	local ret = {}
	for i=1,#this do
		ret[i] = this[i]
	end
	for i=1,#other do
		ret[#ret+1] = other[i]
	end
	self.prf = self.prf + #ret / 3
	return ret
end

--------------------------------------------------------------------------------
-- Merge
-- Merges the two tables. Identical indexes will be overwritten by 'other'
--------------------------------------------------------------------------------
__e2setcost(1)
e2function array array:merge( array other )
	if (!next(this) and !next(other)) then return {} end -- Both of them are empty
	local ret = {}
	for i=1,math.max(#this,#other) do
		ret[i] = other[i] or this[i]
	end
	self.prf = self.prf + #ret / 3
	return ret
end
