----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Multitable or "Super" table - aka mtable
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
	xmt = true,
}

-- Types not allowed in mtables
local blocked_types = {
	xgt = true,
}

local _maxdepth = CreateConVar("wire_expression2_mtable_maxdepth",6,{FCVAR_ARCHIVE,FCVAR_NOTIFY})
local function maxdepth()
	return _maxdepth:GetInt()
end
local maxsize = 1024*1024


--------------------------------------------------------------------------------
-- Type defining
--------------------------------------------------------------------------------

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,ismtable=true,depth=0}

registerType("mtable", "xmt", table.Copy(DEFAULT),
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
			else
				if (id == "xmt") then
					ret = ret .. "MTable with " .. v.size .. " elements"
				else
					ret = ret .. "Table with " .. table.Count(v) .. " elements"
				end
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
WireLib.registerDebuggerFormat( "mtable", function( value, orientvertical )
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

-- Sets the depth of all mtables in the mtable, and returns the deepest depth
local function checkdepth( tbl, depth, setdepth )
	local deepest = depth or 0
	for k,v in pairs( tbl.n ) do
		if (tbl.ntypes[k] == "xmt") then
			if (depth + 1 > maxdepth()) then return depth + 1 end
			if (setdepth != false) then v.depth = depth + 1 end
			local temp = checkdepth( v, depth + 1, setdepth )
			if (temp > deepest) then
				deepest = temp
			end
		end
	end
	for k,v in pairs( tbl.s ) do
		if (tbl.stypes[k] == "xmt") then
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

local function mtable_tostring( tbl, indenting, printed, abortafter )
	local ret = ""
	local cost = 0
	for k,v in pairs( tbl.n ) do
		if (tbl.ntypes[k] == "xmt" and !printed[v]) then -- If it's an mtable
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = mtable_tostring( v, indenting + 2, printed, abortafter )
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
		if (tbl.stypes[k] == "xmt" and !printed[v]) then -- If it's an mtable
			printed[v] = true
			ret = ret .. rep("\t",indenting) .. k .. ":\n"
			local ret2, cost2 = mtable_tostring( v, indenting + 2, printed, abortafter )
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

e2function mtable operator=(mtable lhs, mtable rhs)
	if (checkdepth( rhs, 0, false ) > maxdepth()) then
		self.prf = self.prf + 500
		return table.Copy(DEFAULT)
	end
	if (rhs.size > maxsize) then
		self.prf = self.prf + 500
		return table.Copy(DEFAULT)
	end
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

__e2setcost(1)

e2function number operator_is( mtable tbl )
	return (tbl.size > 0) and 1 or 0
end

e2function number operator==( mtable rv1, mtable rv2 )
	return (rv1 == rv2) and 1 or 0
end

__e2setcost(40)

e2function mtable operator+( mtable rv1, mtable rv2 )
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

registerOperator("fea","xmt","s",function(self,args)
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

-- Creates an mtable
e2function mtable mtable(...)
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
			if (typeids[k] == "xmt") then
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

-- Converts a table into an mtable
e2function mtable table:toMTable()
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
		if (!blocked_types[id]) then
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

__e2setcost(5)

-- Erases everything in the table
e2function void mtable:clear()
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
e2function number mtable:count()
	return this.size
end

-- Returns the depth of the table
e2function number mtable:depth()
	return this.depth
end

__e2setcost(10)

-- Returns the parent of the mtable
e2function mtable mtable:parent()
	return this.parent or table.Copy(DEFAULT)
end

__e2setcost(15)

e2function void printTable( mtable tbl )
	if (tbl.size > 200) then
		self.player:ChatPrint("Table has more than 200 ("..tbl.size..") elements. PrintTable cancelled to prevent lag")
		return
	end
	local printed = { [tbl] = true }
	local ret, cost = mtable_tostring( tbl, 0, printed, 200 )
	self.prf = self.prf + cost
	for str in string.gmatch( ret, "[^\n]+" ) do
		self.player:ChatPrint( str )
	end
end

__e2setcost(20)

-- Flip the numbers and strings of the mtable
e2function mtable mtable:flip()
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

-- Returns an mtable with the typesids of both the array- and table-parts
e2function mtable mtable:typeids()
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
e2function void mtable:remove( number index )
	if (#this.n == 0) then return end
	if (!this.n[index]) then return end
	this.size = this.size - 1
	this.n[index] = nil
	this.size = this.size - 1
	self.vclk[this] = true
end

-- Remove a variable at a string index
e2function void mtable:remove( string index )
	if (IsEmpty(this.s)) then return end
	if (!this.s[index]) then return end
	this.s[index] = nil
	this.size = this.size - 1
	self.vclk[this] = true
end

if (!glon) then require("glon") end

__e2setcost(25)

-- encodes an mtable
e2function string glonEncode(mtable data)
	local ok, ret = pcall(glon.encode, data)
	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.encode error: "..ret)
		return ""
	end

	if ret then
		self.prf = self.prf + string.len(ret) / 2
	end

	return ret or ""
end

-- decodes a glon string and returns an mtable
e2function mtable glonDecodeMTable(string data)
	self.prf = self.prf + string.len(data) / 2

	data = string.Replace(data, "\7xwl", "\7xxx")

	local ok, ret = pcall(glon.decode, data)
	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.decode error: "..ret)
		return table.Copy(DEFAULT)
	end

	if (!ret.ismtable) then return table.Copy(DEFAULT) end

	return ret or table.Copy(DEFAULT)
end

__e2setcost(20)

-- Removes all variables not of the type
e2function mtable mtable:clipToTypeid( string typeid )
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
e2function mtable mtable:clipFromTypeid( string typeid )
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

e2function mtable mtable:clone()
	self.prf = self.prf + this.size * opcost
	return table.Copy(this)
end

__e2setcost(5)

e2function string mtable:id()
	return tostring(this)
end

__e2setcost(20)

-- Formats the table as a human readable string
e2function string mtable:toString()
	local printed = { [this] = true }
	local ret, cost = mtable_tostring( this, 0, printed )
	self.prf = self.prf + cost * opcost
	return ret
end

--------------------------------------------------------------------------------
-- Array-part-only functions
--------------------------------------------------------------------------------

__e2setcost(10)

-- Removes the last element in the array part
e2function void mtable:pop()
	local n = #this.n
	if (n == 0) then return end
	this.n[n] = nil
	this.size = this.size - 1
	self.vclk[this] = true
end

__e2setcost(10)

-- Returns the smallest number in the array-part
e2function number mtable:min()
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
e2function number mtable:max()
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
e2function number mtable:maxIndex()
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
e2function number mtable:minIndex()
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
e2function array mtable:typeidsArray()
	self.prf = self.prf + table.Count(this.ntypes) * opcost
	return table.Copy(this.ntypes)
end

-- Converts an mtable into an array
e2function array mtable:toArray()
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

-- Returns the find in the array part of an mtable
e2function mtable findToMTable()
	local ret = table.Copy(DEFAULT)
	for k,v in ipairs( self.data.findlist ) do
		ret.n[k] = v
		ret.ntypes[k] = "e"
		ret.size = k
	end
	return ret
end

__e2setcost(15)

e2function string mtable:concat()
	self.prf = self.prf + #this.n * opcost
	local ret = ""
	for k,v in ipairs( this.n ) do
		ret = ret .. tostring(v)
	end
	return ret
end

e2function string mtable:concat( string delimiter )
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

-- Converts an mtable into a table
e2function table mtable:toTable()
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

-- Returns a table with the types of the variables in the table-part
e2function table mtable:typeidsTable()
	local ret = {}
	local cost = 0
	for k,v in pairs( this.stypes ) do
		cost = cost + 1
		ret["s"..k] = v
	end
	self.prf = self.prf + cost * opcost
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
		-- Set/Get functions, xmt[index,type] syntax
		--------------------------------------------------------------------------------

		__e2setcost(10)

		-- Getters
		registerOperator("idx",	id.."=xmts"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (!rv1.s[rv2] or rv1.stypes[rv2] != id) then return fixdef(v[2]) end
			return rv1.s[rv2]
		end)

		registerOperator("idx",	id.."=xmtn"		, id, function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			if (!rv1 or !rv2) then return fixdef(v[2]) end
			if (!rv1.n[rv2] or rv1.ntypes[rv2] != id) then return fixdef(v[2]) end
			return rv1.n[rv2]
		end)

		-- Setters
		registerOperator("idx", id.."=xmts"..id , id, function( self, args )
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (!rv1 or !rv2 or !rv3) then return fixdef(v[2]) end
			if (id == "xmt") then
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

		registerOperator("idx", id.."=xmtn"..id, id, function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (!rv1 or !rv2 or !rv3) then return fixdef(v[2]) end
			if (id == "xmt") then
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
		registerFunction("remove"..name,"xmt:s",id,function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			return removefunc( self, rv1, rv2)
		end)
		registerFunction("remove"..name,"xmt:n",id,function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			return removefunc(self, rv1, rv2, true)
		end)


		--------------------------------------------------------------------------------
		-- Array functions
		--------------------------------------------------------------------------------

		-- Push a variable into the mtable (into the array part)
		registerFunction( "push"..name,"xmt:"..id,"",function(self,args)
			local op1, op2 = args[2], args[3]
			local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
			local n = #rv1.n+1
			if (id == "xmt") then
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

		registerFunction( "pop"..name,"xmt:",id,function(self,args)
			local op1 = args[2]
			local rv1 = op1[1](self, op1)
			return removefunc(self, rv1, #rv1.n, true)
		end)

		registerFunction( "insert"..name,"xmt:n"..id,"",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self,op3)
			if (!rv1 or !rv2 or !rv3 or rv2 < 0) then return end
			if (id == "xmt") then
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

		registerFunction( "unshift"..name,"xmt:"..id,"",function(self,args)
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self,op3)
			if (!rv1 or !rv2) then return end
			if (id == "xmt") then
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
