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
		return string.format("Clock:%s Memory:%s Address:%s Data:%s = %s", Clk, Memory, Address, Data, Out)
	end
}

GateActions["highspeed_read"] = {
	name = "Highspeed Read",
	inputs = { "Clk", "Memory", "Address" },
	inputtypes = { "NORMAL", "WIRELINK", "NORMAL" },
	output = function(gate, Clk, Memory, Address)
		if Clk <= 0 then return gate.Memory or 0 end

		Address = math.floor(Address or -1)
		if not Memory or not Memory.ReadCell or Address < 0 then
			gate.Memory = 0
			return 0
		end

		gate.Memory = Memory:ReadCell(Address)
		return gate.Memory or 0
	end,
	label = function(Out, Clk, Memory, Address)
		return string.format("Clock:%s Memory:%s Address:%s = %s", Clk, Memory, Address, Out)
	end
}


GateActions()
