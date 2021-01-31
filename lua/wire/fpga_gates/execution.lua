FPGAGateActions("Execution")

-- FPGAGateActions["execution-last-wild"] = {
-- 	name = "Last",
--   inputs = {"A"},
--   inputtypes = {"WILD"},
--   outputs = {"Out"},
--   outputtypes = {"LINKED"},
--   neverActive = true,
--   output = function(gate)
--     return gate.value
--   end,
--   postCycle = function(gate, value)
--     gate.value = value
-- 	end,
-- }

FPGAGateActions["execution-last-normal"] = {
  	name = "Last Normal",
    inputs = {"A"},
    inputtypes = {"NORMAL"},
    outputs = {"Out"},
    outputtypes = {"NORMAL"},
    neverActive = true,
    output = function(gate, value)
      gate.memory = value
      return gate.value
    end,
    reset = function(gate)
      gate.value = 0
      gate.memory = 0
    end,
    postCycle = function(gate)
      gate.value = gate.memory
  	end,
  }