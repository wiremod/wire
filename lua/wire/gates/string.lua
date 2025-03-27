--[[
	String gates  !  :P
]]

local MAX_LEN = 64*1024 -- max string length of 64k

GateActions("String")

GateActions["string_ceq"] = {
	name = "Equal",
	inputs = { "A" , "B" },
	inputtypes = { "STRING" , "STRING" },
	output = function(gate, A, B)
		if A == B then return 1 else return 0 end
	end,
	label = function(Out, A, B)
		return string.format ("(%s == %s) = %d", A, B, Out)
	end
}

GateActions["string_cineq"] = {
	name = "Inequal",
	inputs = { "A" , "B" },
	inputtypes = { "STRING" , "STRING" },
	output = function(gate, A, B)
		if A ~= B then return 1 else return 0 end
	end,
	label = function(Out, A, B)
		return string.format ("(%s != %s) = %d", A, B, Out)
	end
}

GateActions["string_index"] = {
	name = "Index",
	description = "Gets the character at the index.",
	inputs = { "A" , "Index" },
	inputtypes = { "STRING" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B)
		if not A then A = "" end
		if not B then B = 0 end
		return string.sub(A,B,B)
	end,
	label = function(Out, A, B)
		return string.format ("index(%s , %s) = %q", A, B, Out)
	end
}

GateActions["string_length"] = {
	name = "Length",
	inputs = { "A" },
	inputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = "" end
		return #A
	end,
	label = function(Out, A)
		return string.format ("length(%s) = %d", A, Out)
	end
}

GateActions["string_upper"] = {
	name = "Uppercase",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = "" end
		return string.upper(A)
	end,
	label = function(Out, A)
		return string.format ("upper(%s) = %q", A, Out)
	end
}

GateActions["string_lower"] = {
	name = "Lowercase",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = "" end
		return string.lower(A)
	end,
	label = function(Out, A)
		return string.format ("lower(%s) = %q", A, Out)
	end
}

GateActions["string_sub"] = {
	name = "Substring",
	description = "Gets a part of the string between the start and end indices (inclusive).",
	inputs = { "A" , "Start" , "End" },
	inputtypes = { "STRING" , "NORMAL" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C)
		if not A then A = "" end
		if not B then B = 1 end  -- defaults to start of string
		if not C then C = -1 end -- defaults to end of string
		return string.sub(A,B,C)
	end,
	label = function(Out, A, B, C)
		return string.format ("%s:sub(%s , %s) = %q", A, B, C, Out)
	end
}

GateActions["string_explode"] = {
	name = "Explode",
	description = "Splits a string into an array by the separator pattern.",
	inputs = { "A" , "Separator" },
	inputtypes = { "STRING" , "STRING" },
	outputtypes = { "ARRAY" },
	output = function(gate, A, B)
		if not A then A = "" end
		if not B then B = "" end
		if  (A and #A or 0)
		  + (B and #B or 0)  > MAX_LEN
		then
			return false
		end
		return string.Explode(B,A)
	end,
	label = function(Out, A, B)
		return string.format ("explode(%s , %s)", A, B)
	end
}

GateActions["string_find"] = {
	name = "Find",
	description = "Finds a substring within the string and outputs the position it begins.",
	inputs = { "A", "B", "StartIndex" },
	inputtypes = { "STRING", "STRING" },
	outputtypes = { "NORMAL" },
	outputs = { "Out" },
	output = function(gate, A, B, StartIndex)
		local r,_ = string.find(A,B,StartIndex,true)
		return r or 0
	end,
	label = function(Out, A, B)
		if istable(Out) then Out = Out.Out end
	    return string.format ("find(%s , %s) = %d", A, B, Out)
	end
}

GateActions["string_concat"] = {
	name = "Concatenate",
	description = "Combines multiple strings together into one string.",
	inputs = { "A" , "B" , "C" , "D" , "E" , "F" , "G" , "H" },
	inputtypes = { "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" , "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C, D, E, F, G, H)
		if  (A and #A or 0)
		  + (B and #B or 0)
		  + (C and #C or 0)
		  + (D and #D or 0)
		  + (E and #E or 0)
		  + (F and #F or 0)
		  + (G and #G or 0)
		  + (H and #H or 0)  > MAX_LEN
		then
			return false
		end
		local T = {A,B,C,D,E,F,G,H}
		return table.concat(T)
	end,
	label = function(Out)
		return string.format ("concat = %q", Out)
	end
}

GateActions["string_trim"] = {
	name = "Trim",
	description = "Removes trailing and leading whitespace from the string.",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = "" end
		return string.Trim(A)
	end,
	label = function(Out, A)
		return string.format ("trim(%s) = %q", A, Out)
	end
}

GateActions["string_replace"] = {
	name = "Replace",
	description = "Replaces each occurance of the ToBeReplaced pattern with the Replacer pattern.",
	inputs = { "String" , "ToBeReplaced" , "Replacer" },
	inputtypes = { "STRING" , "STRING" , "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A, B, C)
		if not A then A = "" end
		if not B then B = "" end
		if not C then C = "" end
		if #A + #B + #C > MAX_LEN then return false end
		if not pcall(WireLib.CheckRegex, A, B) then return false end
		return string.gsub(A,B,C)
	end,
	label = function(Out, A, B, C)
		return string.format ("%s:replace(%s , %s) = %q", A, B, C, Out)
	end
}

GateActions["string_reverse"] = {
	name = "Reverse",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = "" end
		return string.reverse(A)
	end,
	label = function(Out, A)
		return string.format ("reverse(%s) = %q", A, Out)
	end
}

GateActions["string_tonum"] = {
	name = "To Number",
	description = "Tries to convert the string to a number.",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if not A then A = "" end
		return tonumber(A)
	end,
	label = function(Out, A)
		return string.format ("tonumber(%s) = %d", A, Out)
	end
}

GateActions["string_tostr"] = {
	name = "Number to String",
	description = "Converts the number to a string.",
	inputs = { "A" },
	inputtypes = { "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A then A = 0 end
		return tostring(A)
	end,
	label = function(Out, A)
		return string.format ("tostring(%s) = %q", A, Out)
	end
}

GateActions["string_tobyte"] = {
	name = "To Byte",
	description = "Converts a character to a number representation.",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "NORMAL" },
	output = function(gate, A)
		if not A then A = "" end
		return string.byte(A)
	end,
	label = function(Out, A)
		return string.format ("tobyte(%s) = %d", A, Out)
	end
}

GateActions["string_tochar"] = {
	name = "To Character",
	description = "Tries to convert a number to a character.",
	inputs = { "A" },
	inputtypes = { "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A)
		if not A or A < 0 or A > 255 then A = 0 end
		return string.char(A)
	end,
	label = function(Out, A)
		return string.format ("tochar(%s) = %q", A, Out)
	end
}

GateActions["string_repeat"] = {
	name = "Repeat",
	description = "Repeats a string by Num times.",
	inputs = { "A" , "Num"},
	inputtypes = { "STRING" , "NORMAL" },
	outputtypes = { "STRING" },
	output = function(gate, A, B)
		if not A then A = "" end
		if not B or B<0 then B = 0 end

		if B * #A > MAX_LEN then return false end

		return string.rep(A,B)
	end,
	label = function(Out, A)
		return string.format ("repeat(%s) = %q", A, Out)
	end
}

GateActions["string_ident"] = {
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, A )
		return A
	end,
	label = function(Out, A)
	    return string.format ("%s = %s", A, Out)
	end
}

GateActions["string_select"] = {
	name = "Select",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "NORMAL", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING", "STRING" },
	outputtypes = { "STRING" },
	output = function(gate, Choice, ...)
		return ({...})[math.Clamp(Choice,1,8)]
	end,
	label = function(Out, Choice)
	    return string.format ("select(%s) = %s", Choice, Out)
	end
}

GateActions["string_to_memory"] = {
  name = "String => Memory",
  inputs = { "A" },
  inputtypes = { "STRING" },
  outputs = { "Memory" },
  reset = function(gate)
    gate.stringQueued = false
    gate.stringChanged = false
    gate.currentString = ""
  end,

  output = function(gate, A)
    if (A ~= gate.currentString) then
      if (not gate.stringChanged) then
        gate.stringChanged = true
        gate.currentString = A
        gate.stringQueued = false
      else
        gate.stringQueued = true
      end
    end
    return gate.Outputs["Memory"].Value --This will prevent Wire_TriggerOutput from changing anything
  end,

  ReadCell = function(self, gate, Address)
    if (Address == 0) then 	   --Clk
      if (gate.stringChanged) then return 1 else return 0 end
    elseif (Address == 1) then --String length
      return #(gate.currentString)
    else --Return string bytes
      local index = Address - 1
      if (index > #(gate.currentString)) then -- Check whether requested address is outside the string
        return 0
      else
        return string.byte(gate.currentString, index)
      end
    end
  end,

  WriteCell = function(self, gate, Address, value)
    if (Address == 0) and (value == 0) then --String got accepted
      gate.stringChanged = false
	  	if gate.stringQueued then --Get queued string
			gate.stringQueued = false
			gate.currentString = gate.Inputs["A"].Value
			gate.stringChanged = true
	  	end
	  	return true
    else
      return false
    end
  end
}


GateActions["string_from_memory"] = {
  name = "Memory => String",
  inputs = {},
  outputs = { "Out", "Memory" },
  outputtypes = { "STRING", "NORMAL" },
  reset = function(gate) --initialize the gate
    gate.memory = {}
    gate.stringLength = 0
    gate.currentString = ""
    gate.ready = true
  end,

  output = function(gate)
    return gate.currentString, gate.Outputs["Memory"].Value
  end,

  ReadCell = function(self, gate, address)
    if (address == 0) then
      return 0
    elseif (address == 1) then
      return gate.stringLength
    else
      return gate.memory[address-1] or 0 -- "or 0" to prevent it from returning nil if index is outside the array
    end
  end,

  WriteCell = function(self, gate, address, value)
    if (value >= 0) then
		if (address == 0) and (value == 1) then -- Clk has been set
			local maxIndex = gate.stringLength
			for i=1,gate.stringLength,1 do
				if not gate.memory[i] then
					maxIndex = i-1
					break
				end
			end
			gate.currentString = string.char(unpack(gate.memory, 1, maxIndex))
			gate:CalcOutput()
			return true
		elseif (address == 1) then -- Set string length
			gate.stringLength = math.floor(value)
			return true
		elseif (address > 1) then  -- Set memory cell
			gate.memory[address-1] = math.floor(value)
			return true
		end
	end
	return false; -- if (value < 0) or ((address == 0) and (value != 1))
  end
}

GateActions()
