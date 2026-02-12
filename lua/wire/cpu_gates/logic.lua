CPUGateActions("Logic")
local i = 1

CPUGateActions["logic-buffer"] = {
  order = i,
  name = "Buffer",
  inputs = {"A"},
  outputs = {"A"},
	output = function(gate, A)
    if A == 0 then
      return 0
    else
      return 1
    end
	end
}

i = i + 1
CPUGateActions["logic-not"] = {
  order = i,
  name = "NOT",
  inputs = {"A"},
  outputs = {"~A"},
	output = function(gate, A)
    if A == 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-and"] = {
  order = i,
  name = "AND",
  inputs = {"A", "B"},
  outputs = {"A&B"},
  output = function(gate, A, B)
    if A ~= 0 and B ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-or"] = {
  order = i,
  name = "OR",
  inputs = {"A", "B"},
  outputs = {"A|B"},
	output = function(gate, A, B)
		if A ~= 0 or B ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-nand"] = {
  order = i,
  name = "NAND",
  inputs = {"A", "B"},
  outputs = {"~(A|B)"},
	output = function(gate, A, B)
		if A ~= 0 and B ~= 0 then
      return 0
    else
      return 1
    end
	end
}

i = i + 1
CPUGateActions["logic-nor"] = {
  order = i,
  name = "NOR",
  inputs = {"A", "B"},
  outputs = {"~(A|B)"},
	output = function(gate, A, B)
		if A ~= 0 or B ~= 0 then
      return 0
    else
      return 1
    end
	end
}

i = i + 1
CPUGateActions["logic-xor"] = {
  order = i,
  name = "XOR",
  inputs = {"A", "B"},
  outputs = {"A^B"},
	output = function(gate, A, B)
		if (A ~= 0 and B == 0) or (A == 0 and B ~= 0) then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-xnor"] = {
  order = i,
  name = "XNOR",
  inputs = {"A", "B"},
  outputs = {"~(A^B)"},
	output = function(gate, A, B)
		if (A ~= 0 and B == 0) or (A == 0 and B ~= 0) then
      return 0
    else
      return 1
    end
	end
}

i = i + 1
CPUGateActions["logic-not-4"] = {
  order = i,
  name = "4-bit NOT",
  inputs = {"A", "B", "C", "D"},
  outputs = {"~A", "~B", "~C", "~D"},
  output = function(gate, A, B, C, D)
    return A == 0, B == 0, C == 0, D == 0
	end
}

i = i + 1
CPUGateActions["logic-not-8"] = {
  order = i,
  name = "8-bit NOT",
  inputs = {"A", "B", "C", "D", "E", "F", "G", "H"},
  outputs = {"~A", "~B", "~C", "~D", "~E", "~F", "~G", "~H"},
  output = function(gate, A, B, C, D, E, F, G, H)
    return A == 0, B == 0, C == 0, D == 0, E == 0, F == 0, G == 0, H == 0
	end
}

i = i + 1
CPUGateActions["logic-not-16"] = {
  order = i,
  name = "16-bit NOT",
  inputs = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P"},
  outputs = {"~A", "~B", "~C", "~D", "~E", "~F", "~G", "~H", "~I", "~J", "~K", "~L", "~M", "~N", "~O", "~P"},
  output = function(gate, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P)
    return A == 0, B == 0, C == 0, D == 0, E == 0, F == 0, G == 0, H == 0, I == 0, J == 0, K == 0, L == 0, M == 0, N == 0, O == 0, P == 0
	end
}

i = i + 1
CPUGateActions["logic-and-3"] = {
  order = i,
  name = "3-way AND",
  inputs = {"A", "B", "C"},
  outputs = {"A&B&C"},
  output = function(gate, A, B, C)
    if A ~= 0 and B ~= 0 and C ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-and-4"] = {
  order = i,
  name = "4-way AND",
  inputs = {"A", "B", "C", "D"},
  outputs = {"A&B&C&D"},
  output = function(gate, A, B, C, D)
    if A ~= 0 and B ~= 0 and C ~= 0 and D ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-and-8"] = {
  order = i,
  name = "8-way AND",
  inputs = {"A", "B", "C", "D", "E", "F", "G", "H"},
  outputs = {"A&B&C&D&E&F&G&H"},
  output = function(gate, A, B, C, D, E, F, G, H)
    if A ~= 0 and B ~= 0 and C ~= 0 and D ~= 0 and E ~= 0 and F ~= 0 and G ~= 0 and H ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-or-3"] = {
  order = i,
  name = "3-way OR",
  inputs = {"A", "B", "C"},
  outputs = {"A|B|C"},
  output = function(gate, A, B, C)
    if A ~= 0 or B ~= 0 or C ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-or-4"] = {
  order = i,
  name = "4-way OR",
  inputs = {"A", "B", "C", "D"},
  outputs = {"A|B|C|D"},
  output = function(gate, A, B, C, D)
    if A ~= 0 or B ~= 0 or C ~= 0 or D ~= 0 then
      return 1
    else
      return 0
    end
	end
}

i = i + 1
CPUGateActions["logic-or-8"] = {
  order = i,
  name = "8-way OR",
  inputs = {"A", "B", "C", "D", "E", "F", "G", "H"},
  outputs = {"A|B|C|D|E|F|G|H"},
  output = function(gate, A, B, C, D, E, F, G, H)
    if A ~= 0 or B ~= 0 or C ~= 0 or D ~= 0 or E ~= 0 or F ~= 0 or G ~= 0 or H ~= 0 then
      return 1
    else
      return 0
    end
	end
}