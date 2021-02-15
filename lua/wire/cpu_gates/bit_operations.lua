CPUGateActions("Bitwise Operations")
local i = 1

CPUGateActions["bit-not"] = {
  order = i,
  name = "Not",
  inputs = {"A"},
  outputs = {"~A"},
	output = function(gate, A)
    return bit.bnot(A)
	end
}

i = i + 1
CPUGateActions["bit-or"] = {
  order = i,
  name = "Or",
  inputs = {"A", "B"},
  outputs = {"A|B"},
	output = function(gate, A, B)
    return bit.bor(A, B)
	end
}

i = i + 1
CPUGateActions["bit-and"] = {
  order = i,
  name = "And",
  inputs = {"A", "B"},
  outputs = {"A&B"},
	output = function(gate, A, B)
    return bit.band(A, B)
	end
}

i = i + 1
CPUGateActions["bit-xor"] = {
  order = i,
  name = "Xor",
  inputs = {"A", "B"},
  outputs = {"A^B"},
	output = function(gate, A, B)
    return bit.bor(A, B)
	end
}

-- i = i + 1
-- CPUGateActions["bit-reduce-4"] = {
--   order = i,
--   name = "A",
--   inputs = {"A", "B"},
-- 	output = function(gate, A, B)
--     return bit.bor(A, B)
-- 	end
-- }