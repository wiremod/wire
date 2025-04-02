E2Lib.RegisterExtension("serialization", true, "Adds functions to serialize data structures into a string and back again.")

-- vON / JSON (De)Serialization
local newE2Table = E2Lib.newE2Table

local antispam_lookup = {}
local function antispam( self )
	if antispam_lookup[self.uid] and antispam_lookup[self.uid] > CurTime() then
		return false
	end

	antispam_lookup[self.uid] = CurTime() + 0.5
	return true
end

-- this conversions table is used by luaTypeToWireTypeid
local conversions = {
	-- convert boolean to number
	boolean = function( v ) return "normal", v and 1 or 0 end,

	-- these probably won't happen, but just in case
	Player = function( v ) return "Entity" end,
	NPC = function( v ) return "Entity" end,
}

-- converts a lua variable's type to a wire typeid
-- also returns v. v may have been modified in the process (converting boolean to number, for example)
local function luaTypeToWireTypeid( v )
	local typename = type( v )

	if conversions[typename] then
		local new_val
		typename, new_val = conversions[typename]( v )
		if new_val ~= nil then
			v = new_val
		end
	end

	-- special check for number
	if typename == "number" then typename = "normal" end

	-- convert full type name to typeid
	return wire_expression_types[ string.upper( typename ) ][1], v
end

local forbiddenTypes = {
	["xgt"] = true,
	["xwl"] = true
}

local sanitizeOutput

local typeSanitizers = {

	-- Two sanitizers to help out with making older serialized data from before #2399 usable
	["v"] = function ( self, glonOutputObject, safeGlonObjectMap )
		if type(glonOutputObject) ~= "Vector" then
			return Vector( glonOutputObject[1], glonOutputObject[2], glonOutputObject[3] )
		end
		return glonOutputObject
	end,
	["a"] = function ( self, glonOutputObject, safeGlonObjectMap )
		if type(glonOutputObject) ~= "Angle" then
			return Angle( glonOutputObject[1], glonOutputObject[2], glonOutputObject[3] )
		end
		return glonOutputObject
	end,

	["r"] = function ( self, glonOutputObject, safeGlonObjectMap )
				if safeGlonObjectMap["r"][glonOutputObject] then
					return safeGlonObjectMap["r"][glonOutputObject]
				end

				local safeArray = {}
				if not glonOutputObject then return safeArray end
				safeGlonObjectMap["r"][glonOutputObject] = safeArray

				if !istable(glonOutputObject) then return safeArray end

				for k, v in pairs(glonOutputObject) do
					if type (k) == "number" then
						safeArray[k] = v
					end
				end

				return safeArray
			end,
	["t"] = function ( self, glonOutputObject, safeGlonObjectMap )
				if safeGlonObjectMap["t"][glonOutputObject] then
					return safeGlonObjectMap["t"][glonOutputObject]
				end

				local safeTable = newE2Table()
				if not glonOutputObject then return safeTable end
				safeGlonObjectMap["t"][glonOutputObject] = safeTable

				if !istable(glonOutputObject) then return safeTable end

				if istable(glonOutputObject.s) and istable(glonOutputObject.stypes) then
					for k, v in pairs(glonOutputObject.s) do
						local objectType = glonOutputObject.stypes[k]
						local safeObject = sanitizeOutput( self, v, objectType, safeGlonObjectMap )
						if safeObject then
							safeTable.s[tostring(k)] = safeObject
							safeTable.stypes[tostring(k)] = objectType
							safeTable.size = safeTable.size + 1
						end
					end
				end

				if istable(glonOutputObject.n) and istable(glonOutputObject.ntypes) then
					for k, v in pairs(glonOutputObject.n) do
						if isnumber(k) then
							local objectType = glonOutputObject.ntypes[k]
							local safeObject = sanitizeOutput( self, v, objectType, safeGlonObjectMap )
							if safeObject then
								safeTable.n[k] = safeObject
								safeTable.ntypes[k] = objectType
								safeTable.size = safeTable.size + 1
							end
						end
					end
				end

				return safeTable
			end,
	["external_t"] = function ( self, glonOutputObject, safeGlonObjectMap )
				if safeGlonObjectMap["t"][glonOutputObject] then
					return safeGlonObjectMap["t"][glonOutputObject]
				end

				local safeTable = {}
				if not glonOutputObject then return safeTable end
				safeGlonObjectMap["t"][glonOutputObject] = safeTable

				if !istable(glonOutputObject) then return safeTable end

				for k, v in pairs(glonOutputObject) do
					local objectType, v = luaTypeToWireTypeid( v )
					if objectType == "t" then objectType = "external_t" end

					local safeObject = sanitizeOutput( self, v, objectType, safeGlonObjectMap )
					if safeObject then
						safeTable[k] = safeObject
					end
				end

				return safeTable
			end,
}

function sanitizeOutput ( self, glonOutputObject, objectType, safeGlonObjectMap )
	self.prf = self.prf + 1

	if not objectType then return end
	if forbiddenTypes[objectType] then return end
	if not wire_expression_types2[objectType] and not objectType == "external_t" then return end

	safeGlonObjectMap = safeGlonObjectMap or {
		r = {},
		t = {}
	}

	if not typeSanitizers[objectType] then
		if wire_expression_types2[objectType][6](glonOutputObject) then return nil end -- failed type validity check
		return glonOutputObject
	end

	return typeSanitizers[objectType] ( self, glonOutputObject, safeGlonObjectMap )
end


-- Default sanitizer for types that are arrays of numbers
local numericArrayDataTypes =
{
	["c"]	= 2,
	["m"]	= 9,
	["q"]	= 4,
	["xm2"]	= 4,
	["xm4"]	= 16,
	["xv2"]	= 2,
	["xv4"]	= 4
}

for objectType, arrayLength in pairs(numericArrayDataTypes) do
	typeSanitizers[objectType] = function ( self, glonOutputObject, sanitizedGlonObjectMap )
		if !istable(glonOutputObject) then return table.Copy(wire_expression_types2[objectType][2]) end

		local safeValue = {}
		for i = 1, arrayLength do
			safeValue[i] = tonumber(glonOutputObject[i]) or wire_expression_types2[objectType][2][i]
		end

		return safeValue
	end
end

---------------------------------------------------------------------------
-- von
---------------------------------------------------------------------------
local last_von_error

__e2setcost(10)

--- Encodes <data> into a string, using [[von]].
e2function string vonEncode(array data)
	local ok, ret = pcall(WireLib.von.serialize, data)
	if not ok then
		last_von_error = ret
		if not antispam(self) then return "" end
		WireLib.ClientError("von.encode error: "..ret, self.player)
		return ""
	end

	if ret then
		self.prf = self.prf + #ret / 2
	end

	return ret or ""
end

--- Decodes <data> into an array, using [[von]].
e2function array vonDecode(string data)
	if not data or data == "" then return {} end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(WireLib.von.deserialize, data)

	if not ok then
		last_von_error = ret
		if not antispam(self) then return {} end
		WireLib.ClientError("von.decode error: "..ret, self.player)
		return {}
	end

	return sanitizeOutput( self, ret, "r" ) or {}
end

__e2setcost(1)
e2function string vonError()
	return last_von_error or ""
end

__e2setcost(15)

--- Encodes <data> into a string, using [[von]].
e2function string vonEncode(table data) = e2function string vonEncode(array data)

__e2setcost(25)

-- decodes a glon string and returns an table
e2function table vonDecodeTable(string data)
	if not data or data == "" then return newE2Table() end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(WireLib.von.deserialize, data)
	if not ok then
		last_von_error = ret
		if not antispam(self) then return newE2Table() end
		WireLib.ClientError("von.decode error: "..ret, self.player)
		return newE2Table()
	end

	return sanitizeOutput( self, ret, "t" ) or newE2Table()
end

---------------------------------------------------------------------------
-- json
---------------------------------------------------------------------------

local function CheckCyclic(tbl, parents) -- https://github.com/Facepunch/garrysmod-issues/issues/6259
    parents[tbl] = true
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            if parents[v] then error("Cannot encode a table with cyclic references") end
            CheckCyclic(v, parents)
        end
    end
    parents[tbl] = nil
end

local last_json_error

-- this encodes the table into json
local function jsonEncode( self, data, prettyprint )
	local ok, ret = pcall(CheckCyclic, data, {})
	if not ok then
		last_json_error = ret
		if not antispam(self) then return "" end
		WireLib.ClientError("jsonEncode error: "..ret, self.player)
		return ""
	end

	local ok, ret = pcall(util.TableToJSON, data, prettyprint ~= 0)
	if not ok then
		last_json_error = ret
		if not antispam(self) then return "" end
		WireLib.ClientError("jsonEncode error: "..ret, self.player)
		return ""
	end

	if ret then
		self.prf = self.prf + #ret / 2
	end

	return ret or ""
end

-- this decodes the json string into a table
local function jsonDecode( self, data, tp )
	if not data or data == "" then return {} end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(util.JSONToTable, data)

	if not ok then
		last_json_error = ret
		if not antispam(self) then return {} end
		WireLib.ClientError("jsonDecode error: "..ret, self.player)
		return {}
	end

	return sanitizeOutput( self, ret, tp ) or {}
end

__e2setcost(1)
e2function string jsonError()
	return last_json_error or ""
end

__e2setcost(50)

-- arrays don't store their values' types, so there are many ambiguous types.
-- This function removes all values that are ambiguous
-- (basically only keeps numbers and strings)
local function jsonEncode_arrays( array )
	local luatable = {}

	for k,v in pairs( array ) do
		local tp = type(v)

		if tp == "number" then
			luatable[k] = v
		elseif tp == "string" then
			luatable[k] = v
		end
	end

	return luatable
end

-- this function converts an E2 table into a Lua table (drops arrays)
local function jsonEncode_recurse( self, data, tp, copied_tables )
	local luatable = {}
	copied_tables[data] = luatable

	local e2types = wire_expression_types2

	for k,v in pairs( data.n ) do
		self.prf = self.prf + 0.3

		if data.ntypes[k] == "r" then
			v = jsonEncode_arrays( v )
		elseif data.ntypes[k] == "t" then
			if copied_tables[v] then
				v = copied_tables[v]
			else
				v = jsonEncode_recurse( self, v, data.ntypes[k], copied_tables )
			end

		-- convert from E2 type to Lua type
		elseif e2types[data.ntypes[k]] and e2types[data.ntypes[k]][4] then
			v = e2types[data.ntypes[k]][4]( self, v )
		end

		luatable[k] = v
	end

	for k,v in pairs( data.s ) do
		self.prf = self.prf + 0.3

		if data.stypes[k] == "r" then
			v = jsonEncode_arrays( v )
		elseif data.stypes[k] == "t" then
			if copied_tables[v] then
				v = copied_tables[v]
			else
				v = jsonEncode_recurse( self, v, data.stypes[k], copied_tables )
			end

		-- convert from E2 type to Lua type
		elseif e2types[data.stypes[k]] and e2types[data.stypes[k]][4] then
			v = e2types[data.stypes[k]][4]( self, v )
		end

		luatable[k] = v
	end

	return luatable
end

local function jsonEncode_start( self, data, prettyprint )
	local copied_tables = {}
	local luatable = jsonEncode_recurse( self, data, "external_t", copied_tables )
	return jsonEncode( self, luatable, prettyprint )
end

-- Used to encode an E2 table to a Lua table, so that it can be used by external resources properly.
e2function string jsonEncode( table data ) return jsonEncode_start( self, data, 0 ) end
e2function string jsonEncode( table data, prettyprint ) return jsonEncode_start( self, data, prettyprint ) end

-- this function converts a lua table into an E2 table
local function jsonDecode_recurse( self, luatable, copied_tables )
	local e2table = newE2Table()

	local wire_expression_types = wire_expression_types

	for k,v in pairs( luatable ) do
		local typeid, v = luaTypeToWireTypeid( v )

		-- if it's a table, recurse through it and convert all the tables it contains
		if typeid == "t" then
			local val = v
			v = newE2Table()

			if copied_tables[val] then
				v = copied_tables[val]
			else
				v = jsonDecode_recurse( self, val, copied_tables )
			end
		end

		if type(k) == "number" then
			e2table.ntypes[k] = typeid
			e2table.n[k] = v
			e2table.size = e2table.size + 1
		elseif type(k) == "string" then
			e2table.stypes[k] = typeid
			e2table.s[k] = v
			e2table.size = e2table.size + 1
		end
	end

	self.prf = self.prf + 0.3 * e2table.size

	return e2table
end

e2function table jsonDecode( string data )
	local luatable = jsonDecode( self, data, "external_t" )
	local copied_tables = {}
	return jsonDecode_recurse( self, luatable, copied_tables )
end
