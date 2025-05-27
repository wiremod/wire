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

local blocked_types = E2Lib.blocked_array_types

-- Fix return values
local fixDefault = E2Lib.fixDefault

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
	nil,
	function(v)
		return not istable(v)
	end
)

--------------------------------------------------------------------------------
-- Array(...)
-- Constructs and returns an array with the given values as elements. If you specify values that are not supported by the array data type, they are skipped
--------------------------------------------------------------------------------
__e2setcost(1)
e2function array array(...args)
	-- Assume the arguments passed to the array do not contain illegal array types,
	-- from the compile time checks.
	self.prf = self.prf + #args * (1 / 4)

	return args
end

--------------------------------------------------------------------------------
-- IS operator
--------------------------------------------------------------------------------

e2function number operator_is(array this)
	return istable(this) and 1 or 0
end

--------------------------------------------------------------------------------
-- Looped functions and operators
--------------------------------------------------------------------------------
registerCallback( "postinit", function()
	local NO_LEGACY = { legacy = false }
	for k,v in pairs( wire_expression_types ) do
		local name = k:lower()
		if name == "normal" then name = "number" end
		local nameupperfirst = upperfirst( name )
		local id = v[1]
		local default = v[2]
		local typecheck = v[6]

		if not blocked_types[id] then -- blocked check start

			--------------------------------------------------------------------------------
			-- Get functions
			-- value = R[N,type], and value = R:<type>(N)
			--------------------------------------------------------------------------------
			__e2setcost(1)

			local function getter( self, array, index, doremove )
				if not array or not index then return fixDefault( default ) end -- Make sure array and index are value
				local ret
				if (doremove) then
					ret = table_remove( array, index )
					self.GlobalScope.vclk[array] = true
				else
					ret = array[floor(index)]
				end
				if (typecheck and typecheck( ret )) then return fixDefault( default ) end -- If typecheck returns true, the type is wrong.
				return ret
			end

			if typecheck then
				registerOperator("indexget", "rn" .. id, id, function(self, array, index)
					local ret = array[floor(index)]
					if typecheck(ret) then
						return fixDefault(default)
					end

					return ret
				end)
			else
				registerOperator("indexget", "rn" .. id, id, function(self, array, index)
					return array[floor(index)]
				end)
			end

			__e2setcost(5)

			registerFunction( name, "r:n", id, function(self, args)
				local array, index = args[1], args[2]
				return getter( self, array, index )
			end, nil, nil, { legacy = false, deprecated = true })

			--------------------------------------------------------------------------------
			-- Set functions
			-- R[N,type] = value, and R:set<type>(N,value)
			--------------------------------------------------------------------------------

			local function setter( self, array, index, value, doinsert )
				if not array or not index then return fixDefault( default ) end -- Make sure array and index are valid
				if (typecheck and typecheck( value )) then return fixDefault( default ) end -- If typecheck returns true, the type is wrong.
				if (doinsert) then
					if index > 2^31 or index < 0 then return fixDefault( default ) end -- too large, possibility of crashing gmod
					table_insert( array, index, value )
				else
					array[floor(index)] = value
				end
				self.GlobalScope.vclk[array] = true
				return value
			end

			if typecheck then
				registerOperator("indexset", "rn" .. id, id, function(self, array, index, value)
					if typecheck(value) then
						return fixDefault(default)
					end

					array[floor(index)] = value
					self.GlobalScope.vclk[array] = true
				end, 2)
			else
				registerOperator("indexset", "rn" .. id, id, function(self, array, index, value)
					array[floor(index)] = value
					self.GlobalScope.vclk[array] = true
				end, 1)
			end

			registerFunction("set" .. nameupperfirst, "r:n"..id, id, function(self,args)
				local array, index, value = args[1], args[2], args[3]
				return setter( self, array, index, value )
			end, nil, nil, { legacy = false, deprecated = true })


			--------------------------------------------------------------------------------
			-- Push functions
			-- Inserts the value at the end of the array
			--------------------------------------------------------------------------------
			__e2setcost(7)

			registerFunction( "push" .. nameupperfirst, "r:" .. id, id, function(self,args)
				local array, value = args[1], args[2]
				return setter( self, array, #array + 1, value )
			end, nil, nil, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Insert functions
			-- Inserts the value at the specified index. Subsequent values are moved up to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "insert" .. nameupperfirst, "r:n" .. id, id, function( self, args )
				local array, index, value = args[1], args[2], args[3]
				return setter( self, array, index, value, true )
			end, nil, nil, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Pop functions
			-- Removes and returns the last value in the array.
			--------------------------------------------------------------------------------
			registerFunction( "pop" .. nameupperfirst, "r:", id, function(self,args)
				local array = args[1]
				if not array then return fixDefault(default) end
				return getter( self, array, #array, true )
			end, nil, nil, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Unshift functions
			-- Inserts the value at the beginning of the array. Subsequent values are moved up to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "unshift" .. nameupperfirst, "r:" .. id, id, function(self,args)
				local array, value = args[1], args[2]
				return setter( self, array, 1, value, true )
			end, nil, nil, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Shift functions
			-- Removes and returns the first value of the array. Subsequent values are moved down to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "shift" .. nameupperfirst, "r:", id, function(self,args)
				local array = args[1]
				if not array then return fixDefault(default) end
				return getter( self, array, 1, true )
			end, nil, nil, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Remove functions
			-- Removes and returns the specified value of the array. Subsequent values are moved down to compensate.
			--------------------------------------------------------------------------------
			registerFunction( "remove" .. nameupperfirst, "r:n", id, function(self,args)
				local array, index = args[1], args[2]
				if not array or not index then return fixDefault(default) end
				return getter( self, array, index, true )
			end, nil, nil, NO_LEGACY)

			-- indexOf

			registerFunction("indexOf", "r:" .. id, "n", function(self, args)
				local arr, val = args[1], args[2]
				local l = #arr
				for i = 1, l do
					if arr[i] == val then
						self.prf = self.prf + i
						return i
					end
				end
				self.prf = self.prf + l
				return 0
			end, nil, { "value" }, NO_LEGACY)

			--------------------------------------------------------------------------------
			-- Foreach operators
			--------------------------------------------------------------------------------
			__e2setcost(0)

			local function iter(tbl, i)
				local v = tbl[i + 1]
				if not typecheck(v) then
					return i + 1, v
				end
			end

			registerOperator("iter", "n" .. id .. "=r", "", function(state, array)
				return function()
					return iter, array, 0
				end
			end)

		end -- blocked check end
	end
end)

--------------------------------------------------------------------------------
-- Pop
-- Removes the last entry in the array and returns 1 if removed
--------------------------------------------------------------------------------
__e2setcost(2)
e2function number array:pop()
	local result = table_remove( this ) and 1 or 0
	self.GlobalScope.vclk[this] = true
	return result
end

--------------------------------------------------------------------------------
-- Shift
-- Removes the first element of the array; all other entries will move down one address and returns 1 if removed
--------------------------------------------------------------------------------
__e2setcost(3)
e2function number array:shift()
	local result = table_remove( this, 1 ) and 1 or 0
	self.GlobalScope.vclk[this] = true
	return result
end

--------------------------------------------------------------------------------
-- Remove
-- Removes the specified entry, moving subsequent entries down to compensate and returns 1 if removed
--------------------------------------------------------------------------------
__e2setcost(2)
e2function number array:remove( index )
	local result = table_remove( this, index ) and 1 or 0
	self.GlobalScope.vclk[this] = true
	return result
end

--------------------------------------------------------------------------------
-- Force remove
-- Force removes the specified entry, without moving subsequent entries down and returns 1 if removed
-- Does not shift larger indexes down to fill the hole
--------------------------------------------------------------------------------
e2function number array:unset( index )
	if this[index] == nil then return 0 end
	this[index] = nil
	self.GlobalScope.vclk[this] = true
	return 1
end

--------------------------------------------------------------------------------
-- Exists
-- Returns 1 if any value exists at the specified index, 0 if not
--------------------------------------------------------------------------------
__e2setcost(1)
e2function number array:exists( index )
	return this[index] ~= nil and 1 or 0
end

--------------------------------------------------------------------------------
-- Count
-- Returns the number of entries in the array
--------------------------------------------------------------------------------
__e2setcost(3)
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
	if not next(this) and not next(other) then return {} end -- Both of them are empty
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
	if not next(this) and not next(other) then return {} end -- Both of them are empty
	local ret = {}
	for i=1,math.max(#this,#other) do
		ret[i] = other[i] or this[i]
	end
	self.prf = self.prf + #ret / 3
	return ret
end

__e2setcost(2)
e2function string toString(array array)
	local buf, len = {}, #array

	self.prf = self.prf + len
	if self.prf > e2_tickquota then error("perf", 0) end

	for i = 1, len do
		local val = array[i]
		local ty = type(val)

		if ty == "Vector" then
			buf[i] = ("vec(%g,%g,%g)"):format(val[1], val[2], val[3])
		elseif ty == "Angle" then
			buf[i] = ("ang(%g,%g,%g)"):format(val[1], val[2], val[3])
		elseif ty == "string" then
			buf[i] = ("%q"):format(val)
		else
			buf[i] = tostring(val)
		end
	end

	return "array(" .. table.concat(buf, ", ") .. ")"
end

e2function string array:toString() = e2function string toString(array array)