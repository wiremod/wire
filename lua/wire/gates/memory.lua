--[[
		Memory Gates
]]

GateActions("Memory")

GateActions["latch"] = {
	name = "Latch (Edge triggered)",
	description = "Updates its value to Data when Clk changes and is greater than 0.",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = Data
			end
		end
		return gate.LatchStore or 0
	end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Data, Clk)
		return "Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["dlatch"] = {
	name = "D-Latch",
	description = "Updates its value to Data when Clk is greater than 0.",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		if (Clk > 0) then
			gate.LatchStore = Data
		end
		return gate.LatchStore or 0
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, Data, Clk)
		return "D-Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["srlatch"] = {
	name = "SR-Latch",
	description = "Outputs 1 when set (S) until it gets reset (R).",
	inputs = { "S", "R" },
	output = function(gate, S, R)
		if (S > 0) and (R <= 0) then
			gate.LatchStore = 1
		elseif (S <= 0) and (R > 0) then
			gate.LatchStore = 0
		end
		return gate.LatchStore
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, S, R)
		return "S:"..S.." R:"..R.." == "..Out
	end
}

GateActions["rslatch"] = {
	name = "RS-Latch",
	description = "Outputs 1 when set (S) and not reset (R).",
	inputs = { "S", "R" },
	output = function(gate, S, R)
		if (S > 0) and (R < 1) then
			gate.LatchStore = 1
		elseif (R > 0) then
			gate.LatchStore = 0
		end
		return gate.LatchStore
	end,
	reset = function(gate)
		gate.LatchStore = 0
	end,
	label = function(Out, S, R)
		return "S:"..S.." R:"..R.." == "..Out
	end
}

GateActions["toggle"] = {
	name = "Toggle (Edge triggered)",
	description = "Toggles its output between two values when Clk changes.",
	inputs = { "Clk", "OnValue", "OffValue" },
	output = function(gate, Clk, OnValue, OffValue)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = (not gate.LatchStore)
			end
		end

		if (gate.LatchStore) then return OnValue end
		return OffValue
	end,
	reset = function(gate)
		gate.LatchStore = false
		gate.PrevValue = nil
	end,
	label = function(Out, Clk, OnValue, OffValue)
		return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["wom4"] = {
	name = "Write Only Memory(4 store)",
	inputs = { "Clk", "AddrWrite", "Data" },
	output = function( gate, Clk, AddrWrite, Data )
		AddrWrite = math.floor(tonumber(AddrWrite))
		if ( Clk > 0 ) then
			if ( AddrWrite >= 0 ) and ( AddrWrite < 4 ) then
				gate.LatchStore[AddrWrite] = Data
			end
		end
		return 0
	end,
	reset = function( gate )
		gate.LatchStore = {}
		for i = 0, 3 do
			gate.LatchStore[i] = 0
		end
	end,
	label = function()
		return "Write Only Memory - 4 store"
	end
}

GateActions["ram8"] = {
	name = "RAM(8 store)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
			gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))

		if (Clk > 0) then
			if (AddrWrite >= 0) and (AddrWrite < 8) then
				gate.LatchStore[AddrWrite] = Data
			end
		end

		if (AddrRead < 0) or (AddrRead >= 8) then return 0 end

		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
		"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 8) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 8) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram64"] = {
	name = "RAM(64 store)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 64) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 64) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 64) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram1k"] = {
	name = "RAM(1kb)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 1024) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset )
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 1024) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 1024) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram32k"] = {
	name = "RAM(32kb)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 32768) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data, Reset )
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 32768) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 32768) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram128k"] = {
	name = "RAM(128kb)",
	inputs = { "Clk", "AddrRead", "AddrWrite", "Data", "Reset" },
	output = function(gate, Clk, AddrRead, AddrWrite, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrRead = math.floor(tonumber(AddrRead))
		AddrWrite = math.floor(tonumber(AddrWrite))
		if (Clk > 0) then
			if (AddrWrite < 131072) then
					gate.LatchStore[AddrWrite] = Data
			end
		end
		return gate.LatchStore[AddrRead] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrRead, AddrWrite, Data)
		return "WriteAddr:"..AddrWrite.."  Data:"..Data.."  Clock:"..Clk..
			"\nReadAddr:"..AddrRead.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 131072) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 131072) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["ram64x64"] = {
	name = "RAM(64x64 store)",
	inputs = { "Clk", "AddrReadX", "AddrReadY", "AddrWriteX", "AddrWriteY", "Data", "Reset" },
	output = function(gate, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data, Reset )
		if (Reset > 0) then
				gate.LatchStore = {}
		end

		AddrReadX = math.floor(tonumber(AddrReadX))
		AddrReadY = math.floor(tonumber(AddrReadY))
		AddrWriteX = math.floor(tonumber(AddrWriteX))
		AddrWriteY = math.floor(tonumber(AddrWriteY))
		if (Clk > 0) then
			if (AddrWriteX >= 0) and (AddrWriteX < 64) or (AddrWriteY >= 0) and (AddrWriteY < 64) then
				gate.LatchStore[AddrWriteX + AddrWriteY*64] = Data
			end
		end

		if (AddrReadX < 0) or (AddrReadX >= 64) or (AddrReadY < 0) or (AddrReadY >= 64) then
			return 0
		end

		return gate.LatchStore[AddrReadX + AddrReadY*64] or 0
	end,
	reset = function(gate)
		gate.LatchStore = {}
	end,
	label = function(Out, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data, Reset)
		return "WriteAddr:"..AddrWriteX..", "..AddrWriteY.."  Data:"..Data.."  Clock:"..Clk.."  Reset:"..Reset..
		"\nReadAddr:"..AddrReadX..", "..AddrReadY.." = "..Out
	end,
	ReadCell = function(dummy,gate,Address)
		if (Address < 0) or (Address >= 4096) then
			return 0
		else
			return gate.LatchStore[Address] or 0
		end
	end,
	WriteCell = function(dummy,gate,Address,value)
		if (Address < 0) or (Address >= 4096) then
			return false
		else
			gate.LatchStore[Address] = value
			return true
		end
	end
}

GateActions["udcounter"] = {
	name = "Up/Down Counter",
	description = "Increases or decreases on Clk.",
	inputs = { "Increment", "Decrement", "Clk", "Reset"},
	output = function(gate, Inc, Dec, Clk, Reset)
		local lInc = (Inc > 0)
		local lDec = (Dec > 0)
		local lClk = (Clk > 0)
		local lReset = (Reset > 0)
		if ((gate.PrevInc ~= lInc or gate.PrevDec ~= lDec or gate.PrevClk ~= lClk) and lClk) then
			if (lInc) and (not lDec) and (not lReset) then
				gate.countStore = (gate.countStore or 0) + 1
			elseif (not lInc) and (lDec) and (not lReset) then
				gate.countStore = (gate.countStore or 0) - 1
			end
			gate.PrevInc = lInc
			gate.PrevDec = lDec
			gate.PrevClk = lClk
		end
		if (lReset) then
			gate.countStore = 0
		end
		return gate.countStore
	end,
	label = function(Out, Inc, Dec, Clk, Reset)
		return "Increment:"..Inc.." Decrement:"..Dec.." Clk:"..Clk.." Reset:"..Reset.." = "..Out
	end
}

GateActions["togglewhile"] = {
	name = "Toggle While(Edge triggered)",
	description = "Toggles its output between two values when Clk changes and While is nonzero.",
	inputs = { "Clk", "OnValue", "OffValue", "While" },
	output = function(gate, Clk, OnValue, OffValue, While)
		local clk = (Clk > 0)

		if (While <= 0) then
			clk = false
			gate.LatchStore = false
		end

		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
			if (clk) then
				gate.LatchStore = (not gate.LatchStore)
			end
		end

		if (gate.LatchStore) then return OnValue end
		return OffValue
	end,
	reset = function(gate)
		gate.LatchStore = 0
		gate.PrevValue = nil
	end,
	label = function(Out, Clk, OnValue, OffValue, While)
		return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.."  While:"..While.." = "..Out
	end
}

GateActions()
