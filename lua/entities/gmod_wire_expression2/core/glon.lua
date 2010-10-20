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

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(table data) = e2function string glonEncode(array data)


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

--- Decodes <data> into a table, using [[GLON]].
e2function table glonDecodeTable(string data)
	self.prf = self.prf + string.len(data) / 2

	data = string.Replace(data, "\7xwl", "\7xxx")

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

__e2setcost(nil)
