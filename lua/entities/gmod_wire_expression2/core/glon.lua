if not glon then require("glon") end

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(array data)
	local ok, ret = pcall(glon.encode, data)
	if not ok then
		ErrorNoHalt("glon.encode error: "..ret)
		return ""
	end
	return ret or ""
end

--- Encodes <data> into a string, using [[GLON]].
e2function string glonEncode(table data) = e2function string glonEncode(array data)


--- Decodes <data> into an array, using [[GLON]].
e2function array glonDecode(string data)
	local ok, ret = pcall(glon.decode, data)
	if not ok then
		ErrorNoHalt("glon.decode error: "..ret)
		return {}
	end

	return ret or {}
end

--- Decodes <data> into a table, using [[GLON]].
e2function table glonDecodeTable(string data)
	local ok, ret = pcall(glon.decode, data)
	if not ok then
		ErrorNoHalt("glon.decode error: "..ret)
		return {}
	end

	return ret or {}
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
