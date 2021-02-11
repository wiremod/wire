CPUGateActions("Arithmetic")

CPUGateActions["arithmetic-half-adder"] = {
  name = "Half Adder",
  inputs = {"A", "B"},
  outputs = {"Sum", "Carry"},
	output = function(gate, A, B)
    if A ~= 0 and B ~= 0 then
      return 0, 1
    elseif A ~= 0 or B ~= 0 then
      return 1, 0
    else
      return 0, 0
    end
	end
}

CPUGateActions["arithmetic-full-adder"] = {
  name = "Full Adder",
  inputs = {"A", "B", "Carry"},
  outputs = {"Sum", "Carry"},
  output = function(gate, A, B, C)
    local v = (A ~= 0 and 1 or 0) + (B ~= 0 and 1 or 0) + (C ~= 0 and 1 or 0)
    if v == 0 then return 0, 0
    elseif v == 1 then return 1, 0
    elseif v == 2 then return 0, 1
    else return 1, 1
    end
	end
}

CPUGateActions["arithmetic-half-subtractor"] = {
  name = "Half Subtractor",
  inputs = {"A", "B"},
  outputs = {"Difference", "Borrow"},
	output = function(gate, A, B)
    if A == 0 and B ~= 0 then
      return 1, 1
    elseif A ~= 0 and B == 0 then
      return 1, 0
    else
      return 0, 0
    end
	end
}

CPUGateActions["arithmetic-full-subtractor"] = {
  name = "Full Subtractor",
  inputs = {"A", "B", "Borrow"},
  outputs = {"Difference", "Borrow"},
  output = function(gate, A, B, C)
    local a, b, c = A ~= 0, B ~= 0, C ~= 0
    if not a and not b and c then
      return 1, 1
    elseif not a and b and not c then
      return 1, 1
    elseif not a and b and c then 
      return 0, 1
    elseif a and not b and not c then
      return 1, 0
    elseif a and b and c then
      return 1, 1
    else
      return 0, 0
    end
	end
}