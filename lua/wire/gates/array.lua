--[[
		Array Gates
]]

GateActions("Array")

GateActions["table_8merge"] = {
	name = "8x merger",
	timed = true,
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputs = { "Tbl" },
	outputtypes = { "ARRAY" },
	output = function(gate, A, B, C, D, E, F, G, H)
		if A then return { A, B, C, D, E, F, G, H }
		else return {}
		end
	end,
}

GateActions["table_8split"] = {
	name = "8x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "ARRAY" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0,0,0,0,0
		end
	end,
}

GateActions["table_8duplexer"] = {
	name = "8x duplexer",
	timed = true,
	inputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "BIDIRARRAY" },
	outputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "BIDIRARRAY" },
	output = function(gate, Tbl, A, B, C, D, E, F, G, H)
		local t,v = {0,0,0,0,0,0,0,0}, {}
		if Tbl then t = Tbl end
		if A then v = { A, B, C, D, E, F, G, H } end
		return v, unpack( t )
	end,
}

GateActions["table_valuebyidx"] = {
	name = "Value retriever",
	timed = true,
	inputs = { "Tbl", "Index" },
	inputtypes = { "ARRAY" },
	outputs = { "Data" },
	output = function(gate, Tbl, idx)
		if Tbl && idx && Tbl[idx] then return Tbl[idx]
		else return 0
		end
	end,
}

GateActions()
