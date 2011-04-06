--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Opcode definition file
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Initialize opcode count lookup table
HCOMP.OperandCount = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  HCOMP.OperandCount[instruction.Opcode] = instruction.OperandCount
end

-- Initialize table of single-operand instructions which write 1st operand
HCOMP.OpcodeWritesOperand = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  if instruction.WritesFirstOperand and (instruction.Mnemonic ~= "RESERVED") then
    HCOMP.OpcodeWritesOperand[string.lower(instruction.Mnemonic)] = true
  end
end

-- Initialize opcode number lookup table
HCOMP.OpcodeNumber = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  if instruction.Mnemonic ~= "RESERVED" then
    HCOMP.OpcodeNumber[string.lower(instruction.Mnemonic)] = instruction.Opcode
  end
end

-- Initialize list of obsolete/old opcodes
HCOMP.OpcodeObsolete = {}
HCOMP.OpcodeOld = {}
for _,instruction in pairs(CPULib.InstructionTable) do
  if instruction.Obsolete and (instruction.Mnemonic ~= "RESERVED") then
    HCOMP.OpcodeObsolete[string.lower(instruction.Mnemonic)] = true
  end
  if instruction.Old and (instruction.Mnemonic ~= "RESERVED") then
    HCOMP.OpcodeOld[string.lower(instruction.Mnemonic)] = string.lower(instruction.Reference)
  end
end
