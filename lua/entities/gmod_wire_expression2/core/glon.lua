if not glon then require("glon") end

local last_glon_error = ""

__e2setcost(10)

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(array data)
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

--- Decodes <data> into an array, using [[GLON]].
e2function array glonDecode(string data)
	self.prf = self.prf + string.len(data) / 2

	local ok, ret = pcall(glon.decode, data)

	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.decode error: "..ret)
		return {}
	end

	if (type(ret) != "table") then -- Exploit detected
		--MsgN( "[E2] WARNING! " .. self.player:Nick() .. " (" .. self.player:SteamID() .. ") tried to read a non-table type as a table. This is a known and serious exploit that has been prevented." )
		--error( "Tried to read a non-table type as a table." )
		return {}
	end

	return ret or {}
end

e2function string glonError()
	return last_glon_error
end

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

---------------------------------------------------------------------------
-- table glon
---------------------------------------------------------------------------

__e2setcost(15)

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(table data) = e2function string glonEncode(array data)

__e2setcost(25)

local function ExploitFix( self, tbl, checked )
	if (!self or !tbl) then return true end

	if (!tbl.istable) then return false end

	local ret = true

	for k,v in pairs( tbl.n ) do
		self.prf = self.prf + 1
		if (!checked[v]) then
			checked[v] = true
			if (exploitables[type(v)] and tbl.ntypes[k] != "e") then
				ret = false
			elseif (tbl.ntypes[k] == "t") then
				local temp = ExploitFix( self, v, checked )
				if (temp == false) then ret = false end
			end
		end
	end
	for k,v in pairs( tbl.s ) do
		self.prf = self.prf + 1
		if (!checked[v]) then
			checked[v] = true
			if (exploitables[type(v)] and tbl.stypes[k] != "e") then
				ret = false
			elseif (tbl.stypes[k] == "t") then
				local temp = ExploitFix( self, v, checked )
				if (temp == false) then ret = false end
			end
		end
	end
	return ret
end

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,istable=true,depth=0}

-- decodes a glon string and returns an table
e2function table glonDecodeTable(string data)
	if (!data or data == "") then return table.Copy(DEFAULT) end

	self.prf = self.prf + string.len(data) / 2

	data = string.Replace(data, "\7xwl", "\7xxx")

	local ok, ret = pcall(glon.decode, data)
	if not ok then
		last_glon_error = ret
		ErrorNoHalt("glon.decode error: "..ret)
		return table.Copy(DEFAULT)
	end

	if (!ret or !ret.istable) then return table.Copy(DEFAULT) end

	if (type(ret) != "table" or ExploitFix( self, ret, { [ret] = true } ) == false) then -- Exploit check
		--MsgN( "[E2] WARNING! " .. self.player:Nick() .. " (" .. self.player:SteamID() .. ") tried to read a non-table type as a table. This is a known and serious exploit that has been prevented." )
		--error( "Tried to read a non-table type as a table." )
		return table.Copy(DEFAULT)
	end

	return ret or table.Copy(DEFAULT)
end

__e2setcost(nil)
