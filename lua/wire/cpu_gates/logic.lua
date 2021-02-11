CPUGateActions("Logic")
local i = 1

CPUGateActions["logic-buffer"] = {
  order = i,
  name = "Buffer",
  inputs = {"A"},
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
	output = function(gate, A, B)
		if (A ~= 0 and B == 0) or (A == 0 and B ~= 0) then 
      return 0
    else
      return 1
    end
	end
}