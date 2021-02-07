CPUGateActions("Conversion")

CPUGateActions["normal-to-4bit"] = {
	name = "To 4-bit",
  inputs = {"A"},
  outputs = {"Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, value)
    local bits = {}
    local check = 8
    for i = 1, 4 do
      if bit.band(value, check) > 0 then
        bits[i] = 1
      else
        bits[i] = 0
      end
      check = check / 2
    end

		return unpack(bits)
	end
}

CPUGateActions["normal-to-8bit"] = {
	name = "To 8-bit",
  inputs = {"A"},
  outputs = {"Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, value)
		local bits = {}
    local check = 128
    for i = 1, 8 do
      if bit.band(value, check) > 0 then
        bits[i] = 1
      else
        bits[i] = 0
      end
      check = check / 2
    end

		return unpack(bits)
	end
}

CPUGateActions["normal-to-16bit"] = {
	name = "To 16-bit",
  inputs = {"A"},
  outputs = {"Bit 16", "Bit 15", "Bit 14", "Bit 13", "Bit 12", "Bit 11", "Bit 10", "Bit 9", "Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
  output = function(gate, value)
    local bits = {}
    local check = 32768
    for i = 1, 16 do
      if bit.band(value, check) > 0 then
        bits[i] = 1
      else
        bits[i] = 0
      end
      check = check / 2
    end

		return unpack(bits)
	end
}

CPUGateActions["4bit-to-normal"] = {
	name = "From 4-bit",
  inputs = {"Bit 4", "Bit 3", "Bit 2", "Bit 1"},
  output = function(gate, B4, B3, B2, B1)
    local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc + 8 end

		return acc
	end
}

CPUGateActions["8bit-to-normal"] = {
	name = "From 8-bit",
  inputs = {"Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, B8, B7, B6, B5, B4, B3, B2, B1)
		local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc + 8 end
    if B5 >= 1 then acc = acc + 16 end
    if B6 >= 1 then acc = acc + 32 end
    if B7 >= 1 then acc = acc + 64 end
    if B8 >= 1 then acc = acc + 128 end

		return acc
	end
}

CPUGateActions["16bit-to-normal"] = {
	name = "From 16-bit",
  inputs = {"Bit 16", "Bit 15", "Bit 14", "Bit 13", "Bit 12", "Bit 11", "Bit 10", "Bit 9", "Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, B16, B15, B14, B13, B12, B11, B10, B9, B8, B7, B6, B5, B4, B3, B2, B1)
		local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc + 8 end
    if B5 >= 1 then acc = acc + 16 end
    if B6 >= 1 then acc = acc + 32 end
    if B7 >= 1 then acc = acc + 64 end
    if B8 >= 1 then acc = acc + 128 end
    if B9 >= 1 then acc = acc + 256 end
    if B10 >= 1 then acc = acc + 512 end
    if B11 >= 1 then acc = acc + 1024 end
    if B12 >= 1 then acc = acc + 2048 end
    if B13 >= 1 then acc = acc + 4096 end
    if B14 >= 1 then acc = acc + 8192 end
    if B15 >= 1 then acc = acc + 16384 end
    if B16 >= 1 then acc = acc + 32768 end

		return acc
	end
}

CPUGateActions["signed-4bit-to-normal"] = {
	name = "From signed 4-bit",
  inputs = {"Bit 4", "Bit 3", "Bit 2", "Bit 1"},
  output = function(gate, B4, B3, B2, B1)
    local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc - 8 end

		return acc
	end
}

CPUGateActions["signed-8bit-to-normal"] = {
	name = "From signed 8-bit",
  inputs = {"Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, B8, B7, B6, B5, B4, B3, B2, B1)
		local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc + 8 end
    if B5 >= 1 then acc = acc + 16 end
    if B6 >= 1 then acc = acc + 32 end
    if B7 >= 1 then acc = acc + 64 end
    if B8 >= 1 then acc = acc - 128 end

		return acc
	end
}

CPUGateActions["signed-16bit-to-normal"] = {
	name = "From signed 16-bit",
  inputs = {"Bit 16", "Bit 15", "Bit 14", "Bit 13", "Bit 12", "Bit 11", "Bit 10", "Bit 9", "Bit 8", "Bit 7", "Bit 6", "Bit 5", "Bit 4", "Bit 3", "Bit 2", "Bit 1"},
	output = function(gate, B16, B15, B14, B13, B12, B11, B10, B9, B8, B7, B6, B5, B4, B3, B2, B1)
		local acc = 0
    if B1 >= 1 then acc = acc + 1 end
    if B2 >= 1 then acc = acc + 2 end
    if B3 >= 1 then acc = acc + 4 end
    if B4 >= 1 then acc = acc + 8 end
    if B5 >= 1 then acc = acc + 16 end
    if B6 >= 1 then acc = acc + 32 end
    if B7 >= 1 then acc = acc + 64 end
    if B8 >= 1 then acc = acc + 128 end
    if B9 >= 1 then acc = acc + 256 end
    if B10 >= 1 then acc = acc + 512 end
    if B11 >= 1 then acc = acc + 1024 end
    if B12 >= 1 then acc = acc + 2048 end
    if B13 >= 1 then acc = acc + 4096 end
    if B14 >= 1 then acc = acc + 8192 end
    if B15 >= 1 then acc = acc + 16384 end
    if B16 >= 1 then acc = acc - 32768 end

		return acc
	end
}