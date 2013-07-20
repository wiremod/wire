E2Lib.RegisterExtension("glon", true)

if not glon then pcall(require,"glon") end

local last_glon_error = ""

-- GLON output validation
local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,depth=0}

--[[
wire_expression2_glon = {}
wire_expression2_glon.history = {}
wire_expression2_glon.players = {}

local function logGlonCall( self, glonString, ret, safeGlonObject )
	local logEntry =
		{
			Expression2 =
				{
					Name = self.entity.name,
					Owner = self.entity.player,
					OwnerID = self.entity.player:IsValid() and self.entity.player:SteamID() or "[Unknown]",
					OwnerName = self.entity.player:IsValid() and self.entity.player:Name() or "[Unknown]",
				},
			GLON = glonString,
			GLONOutput = ret,
			SafeOutput = safeGlonObject,
			Timestamp = os.date("%c")
		}

	wire_expression2_glon.history[#wire_expression2_glon.history + 1] = logEntry

	if self.entity.player:IsValid() then
		wire_expression2_glon.players[self.entity.player] = wire_expression2_glon.players[self.entity.player] or {}
		wire_expression2_glon.players[self.entity.player][#wire_expression2_glon.players[self.entity.player] + 1] = logEntry
	end
end
]]

local forbiddenTypes = {
	["xgt"] = true,
	["xwl"] = true
}

local typeSanitizers

local function sanitizeGlonOutput ( self, glonOutputObject, objectType, safeGlonObjectMap )
	self.prf = self.prf + 1

	if not objectType then return nil end
	if forbiddenTypes[objectType] then return nil end
	if not wire_expression_types2[objectType] then return nil end

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

typeSanitizers = {
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

				local safeTable = table.Copy(DEFAULT)
				if not glonOutputObject then return safeTable end
				safeGlonObjectMap["t"][glonOutputObject] = safeTable

				if !istable(glonOutputObject) then return safeTable end

				if istable(glonOutputObject.s) and istable(glonOutputObject.stypes) then
					for k, v in pairs(glonOutputObject.s) do
						local objectType = glonOutputObject.stypes[k]
						local safeObject = sanitizeGlonOutput( self, v, objectType, safeGlonObjectMap )
						if safeObject then
							safeTable.s[tostring(k)] = safeObject
							safeTable.stypes[tostring(k)] = objectType
						end
					end
				end

				if istable(glonOutputObject.n) and istable(glonOutputObject.ntypes) then
					for k, v in pairs(glonOutputObject.n) do
						if isnumber(k) then
							local objectType = glonOutputObject.ntypes[k]
							local safeObject = sanitizeGlonOutput( self, v, objectType, safeGlonObjectMap )
							if safeObject then
								safeTable.n[k] = safeObject
								safeTable.ntypes[k] = objectType
							end
						end
					end
				end

				safeTable.size = table.Count(safeTable.s) + #safeTable.n

				return safeTable
			end,
	["v"] = function ( self, glonOutputObject, safeGlonObjectMap )
				if not glonOutputObject then return table.Copy(wire_expression_types2["v"][2]) end
				if isvector(glonOutputObject) then return { glonOutputObject.x, glonOutputObject.y, glonOutputObject.z } end
				if !istable(glonOutputObject) then return table.Copy(wire_expression_types2["v"][2]) end

				local safeValue = {}
				for i = 1, 3 do
					safeValue[i] = tonumber(glonOutputObject[i]) or wire_expression_types2["v"][2][i]
				end

				return safeValue
			end
}

-- Default sanitizer for types that are arrays of numbers
local numericArrayDataTypes =
{
	["a"]	= 3,
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

__e2setcost(10)

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(array data)
	if not glon then
		error( "Glon is not installed on this server. Please use von instead.", 0 )
	end

	local ok, ret = pcall(glon.encode, data)
	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.encode error: "..ret)
		return ""
	end

	if ret then
		self.prf = self.prf + #ret / 2
	end

	return ret or ""
end

--- Decodes <data> into an array, using [[GLON]].
e2function array glonDecode(string data)
	if not glon then
		error( "Glon is not installed on this server. Please use von instead.", 0 )
	end

	if not data then return {} end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(glon.decode, data)

	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.decode error: "..ret)
		return {}
	end

	local safeArray = sanitizeGlonOutput( self, ret, "r" )
	-- logGlonCall( self, data, ret, safeArray )
	return safeArray or {}
end

e2function string glonError()
	if not glon then
		error( "Glon is not installed on this server. Please use von instead.", 0 )
	end

	return last_glon_error
end

if glon then
	hook.Add("InitPostEntity", "wire_expression2_glonfix", function()
		-- Fixing other people's bugs...
		for i = 1,20 do
			local name, encode_types = debug.getupvalue(glon.Write, i)
			if name == "encode_types" then
				for _,tp in ipairs({"NPC","Vehicle","Weapon"}) do
					if not encode_types[tp] then encode_types[tp] = encode_types.Entity end
				end
				break
			end
		end
	end)
end

---------------------------------------------------------------------------
-- table glon
---------------------------------------------------------------------------

__e2setcost(15)

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(table data) = e2function string glonEncode(array data)

__e2setcost(25)

-- decodes a glon string and returns an table
e2function table glonDecodeTable(string data)
	if not glon then
		error( "Glon is not installed on this server. Please use von instead.", 0 )
	end

	if not data then return table.Copy(DEFAULT) end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(glon.decode, data)
	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.decode error: "..ret)
		return table.Copy(DEFAULT)
	end

	local safeTable = sanitizeGlonOutput( self, ret, "t" )
	return safeTable or table.Copy(DEFAULT)
end

---------------------------------------------------------------------------
-- von
---------------------------------------------------------------------------
local last_von_error

__e2setcost(10)

--- Encodes <data> into a string, using [[von]].
e2function string vonEncode(array data)
	local ok, ret = pcall(von.serialize, data)
	if not ok then
		last_von_error = ret
		ErrorNoHalt("von.encode error: "..ret)
		return ""
	end

	if ret then
		self.prf = self.prf + #ret / 2
	end

	return ret or ""
end

--- Decodes <data> into an array, using [[von]].
e2function array vonDecode(string data)
	if not data then return {} end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(von.deserialize, data)

	if not ok then
		last_von_error = ret
		ErrorNoHalt("von.decode error: "..ret)
		return {}
	end

	local safeArray = sanitizeGlonOutput( self, ret, "r" )
	return safeArray or {}
end

e2function string vonError()
	return last_von_error
end

__e2setcost(15)

--- Encodes <data> into a string, using [[von]].
e2function string vonEncode(table data) = e2function string vonEncode(array data)

__e2setcost(25)

-- decodes a glon string and returns an table
e2function table vonDecodeTable(string data)
	if not data then return table.Copy(DEFAULT) end

	self.prf = self.prf + #data / 2

	local ok, ret = pcall(von.deserialize, data)
	if not ok then
		last_von_error = ret
		ErrorNoHalt("von.decode error: "..ret)
		return table.Copy(DEFAULT)
	end

	local safeTable = sanitizeGlonOutput( self, ret, "t" )
	return safeTable or table.Copy(DEFAULT)
end
