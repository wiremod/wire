--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Optimizer
--------------------------------------------------------------------------------




local OptimizationPattern = {
--------------------------------------------------------------------------------
  {{{"sstack","A","B"},
    {"rstack","C","A"},
   },
   {{"sstack","A","B"},
    {"mov",   "C","B"},
   },
  },
--------------------------------------------------------------------------------
  {{{"?1"    ,"A","B"},
    {"sstack","C","D"},
    {"?2"    ,"E","F"},
    {"sstack","C","D"},
   },
   {{"?1"    ,"A","B"},
    {"?2"    ,"E","F"},
    {"sstack","C","D"},
   },
  },
--------------------------------------------------------------------------------
  {{{"mov","A","A"},
   },
   {
   },
  }
}




--------------------------------------------------------------------------------
-- Compare if two operands match
local function CompareOperands(op1,op2)
  return op1 and op2 and
         (op1.Constant      == op2.Constant) and
         (op1.Register      == op2.Register) and
         (op1.Segment       == op2.Segment) and
         (op1.Memory        == op2.Memory) and
         (op1.MemoryPointer == op2.MemoryPointer)
end




--------------------------------------------------------------------------------
-- Optimizes the generated code. Returns true if something was optimized
function HCOMP:OptimizeCode()
  -- For all opcodes
  for index,opcode in ipairs(self.GeneratedCode) do
    -- Check all optimization patterns
    for _,pattern in pairs(OptimizationPattern) do
      -- Check that pattern is long enough
      if self.GeneratedCode[index+#pattern[1]-1] then
        -- Check if pattern matches
        local patternMatches = true
        local temporaryOperands = {}
        local temporaryOpcodes = {}

        -- Check all opcodes in pattern, continously
        for i,matchPattern in ipairs(pattern[1]) do
          local matchOpcode = matchPattern[1]
          if not self.OpcodeNumber[matchPattern[1]] then
            if not temporaryOpcodes[matchPattern[1]] then
              temporaryOpcodes[matchPattern[1]] = self.GeneratedCode[index+i-1].Opcode
            end
            matchOpcode = temporaryOpcodes[matchPattern[1]]
          end

          if (matchOpcode) and (self.GeneratedCode[index+i-1].Opcode == matchOpcode) then
            local operand1 = self.GeneratedCode[index+i-1].Operands[1]
            local operand2 = self.GeneratedCode[index+i-1].Operands[2]

            if matchPattern[2] and (not temporaryOperands[matchPattern[2]]) then
              temporaryOperands[matchPattern[2]] = operand1
            end
            if matchPattern[3] and (not temporaryOperands[matchPattern[3]]) then
              temporaryOperands[matchPattern[3]] = operand2
            end

            -- Compare so operand "A" equals operand "A", etc
            if matchPattern[2] and (not CompareOperands(operand1,temporaryOperands[matchPattern[2]])) then
              patternMatches = false
            end
            if matchPattern[3] and (not CompareOperands(operand2,temporaryOperands[matchPattern[3]])) then
              patternMatches = false
            end
          else
            patternMatches = false
          end
        end

        if patternMatches then
          -- If match found, delete all old entries
          for i=1,#pattern[1] do
            table.remove(self.GeneratedCode,index)
          end

          -- Re-add the new ones
          for i=1,#pattern[2] do
            local tempOperands = {}
            -- This will properly match letters with operands parsed when matching
            if pattern[2][i][2] then tempOperands[1] = temporaryOperands[pattern[2][i][2]] end
            if pattern[2][i][3] then tempOperands[2] = temporaryOperands[pattern[2][i][3]] end

            if self.OpcodeNumber[pattern[2][i][1]] then
              table.insert(self.GeneratedCode,index+i-1,
                {
                  Opcode = pattern[2][i][1],
                  Operands = tempOperands,
                })
            else
              table.insert(self.GeneratedCode,index+i-1,
                {
                  Opcode = temporaryOpcodes[pattern[2][i][1]],
                  Operands = tempOperands,
                })
            end
          end
          return true
        end
      end
    end
  end

  return false
end
