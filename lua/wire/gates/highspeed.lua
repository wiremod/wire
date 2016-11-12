GateActions("Highspeed")

GateActions["highspeed_write"] = {
	name = "Highspeed Write",
	inputs = { "Clk", "Memory", "Address", "Data" },
	inputtypes = { "NORMAL", "WIRELINK", "NORMAL", "NORMAL" },
	output = function(gate, Clk, Memory, Address, Data)
		if not Memory then return 0 end
		if not Memory.WriteCell then return 0 end
		if Clk <= 0 then return 0 end

		Address = math.floor(Address)
		if Address < 0 then return 0 end

		return Memory:WriteCell(Address, Data) and 1 or 0
	end,
	label = function(Out, Clk, Memory, Address, Data)
		return "Clock:"..Clk.." Memory:"..Memory.." Address:"..Address.." Data:"..Data.." = "..Out
	end
}

GateActions["highspeed_read"] = {
	name = "Highspeed Read",
	inputs = { "Clk", "Memory", "Address" },
	inputtypes = { "NORMAL", "WIRELINK", "NORMAL" },
	output = function(gate, Clk, Memory, Address)
		if not Memory then  return 0 end
		if not Memory.ReadCell then return 0 end
		if Clk <= 0 then return 0 end

		Address = math.floor(Address)
		if Address < 0 then return 0 end

		return Memory:ReadCell(Address) or 0
	end,
	label = function(Out, Clk, Memory, Address)
		return "Clock:"..Clk.." Memory:"..Memory.." Address:"..Address.." = "..Out
	end
}


GateActions()
