CPUGateActions("Logic")

CPUGateActions["logic-buffer"] = {
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

CPUGateActions["logic-not"] = {
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

CPUGateActions["logic-and"] = {
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

CPUGateActions["logic-or"] = {
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

CPUGateActions["logic-nand"] = {
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

CPUGateActions["logic-nor"] = {
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

CPUGateActions["logic-xor"] = {
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

CPUGateActions["logic-xnor"] = {
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