CPUGateActions("Arithmetic")
local i = 1

CPUGateActions["arithmetic-half-adder"] = {
  order = i,
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

i = i + 1
CPUGateActions["arithmetic-full-adder"] = {
  order = i,
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

i = i + 1
CPUGateActions["arithmetic-half-subtractor"] = {
  order = i,
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

i = i + 1
CPUGateActions["arithmetic-full-subtractor"] = {
  order = i,
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

i = i + 1
CPUGateActions["arithmetic-4-bit-adder"] = {
  order = i,
  name = "4-bit Adder",
  inputs = {"[4-bit] A", "[4-bit] B", "Carry"},
  outputs = {"Sum [4-bit]", "Carry"},
  output = function(gate, A, B, C)
    local v = bit.band(A, 15) + bit.band(B, 15) + (C ~= 0 and 1 or 0)

    return bit.band(v, 15), v > 15 and 1 or 0
	end
}


i = i + 1
CPUGateActions["arithmetic-8-bit-adder"] = {
  order = i,
  name = "8-bit Adder",
  inputs = {"[8-bit] A", "[8-bit] B", "Carry"},
  outputs = {"Sum [8-bit]", "Carry"},
  output = function(gate, A, B, C)
    local v = bit.band(A, 255) + bit.band(B, 255) + (C ~= 0 and 1 or 0)

    return bit.band(v, 255), v > 255 and 1 or 0
	end
}

i = i + 1
CPUGateActions["arithmetic-16-bit-adder"] = {
  order = i,
  name = "16-bit Adder",
  inputs = {"[16-bit] A", "[16-bit] B", "Carry"},
  outputs = {"Sum [16-bit]", "Carry"},
  output = function(gate, A, B, C)
    local v = bit.band(A, 65535) + bit.band(B, 65535) + (C ~= 0 and 1 or 0)

    return bit.band(v, 65535), v > 65535 and 1 or 0
	end
}