--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Opcode definition file
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Initialize opcode count lookup table
HCOMP.OperandCount = {}

local function buildMainLookup(instructions)
  for _,instruction in pairs(instructions) do
    HCOMP.OperandCount[instruction.Opcode] = instruction.OperandCount
  end
end

-- Initialize table of single-operand instructions which write 1st operand
HCOMP.OpcodeWritesOperand = {}

local function buildWritesFirstLookup(instructions)
for _,instruction in pairs(instructions) do
    if instruction.WritesFirstOperand and (instruction.Mnemonic ~= "RESERVED") then
      HCOMP.OpcodeWritesOperand[string.lower(instruction.Mnemonic)] = true
    end
  end
end

-- Initialize opcode number lookup table
HCOMP.OpcodeNumber = {}

local function buildOpLookupTable(instructions)
  for _,instruction in pairs(instructions) do
    if instruction.Mnemonic ~= "RESERVED" then
      HCOMP.OpcodeNumber[string.lower(instruction.Mnemonic)] = instruction.Opcode
    end
  end
end

-- Initialize list of obsolete/old opcodes
HCOMP.OpcodeObsolete = {}
HCOMP.OpcodeOld = {}

local function buildDeprecatedLookupTable(instructions)
  for _,instruction in pairs(instructions) do
    if instruction.Obsolete and (instruction.Mnemonic ~= "RESERVED") then
      HCOMP.OpcodeObsolete[string.lower(instruction.Mnemonic)] = true
    end
    if instruction.Old and (instruction.Mnemonic ~= "RESERVED") then
      HCOMP.OpcodeOld[string.lower(instruction.Mnemonic)] = string.lower(instruction.Reference)
    end
  end
end

buildMainLookup(CPULib.InstructionTable)
buildWritesFirstLookup(CPULib.InstructionTable)
buildOpLookupTable(CPULib.InstructionTable)
buildDeprecatedLookupTable(CPULib.InstructionTable)

local function RemoveInstructions(indexes)
  for _, inst in ipairs(indexes) do
    local instName = string.lower(CPULib.InstructionTable[inst].Mnemonic)
    HCOMP.OperandCount[CPULib.InstructionTable[inst].Opcode] = nil
    HCOMP.OpcodeWritesOperand[instName] = nil
    HCOMP.OpcodeNumber[instName] = nil
    HCOMP.OpcodeOld[instName] = nil
    HCOMP.OpcodeObsolete[instName] = nil
  end
  HCOMP:RemoveTokenizerOpcodes(indexes)
end

local function CreateInstructions(indexes)
  -- build a small table mirroring instructiontable to reuse the above functions
  local newInstructions = {}
  for _,inst in ipairs(indexes) do
    table.insert(newInstructions,CPULib.InstructionTable[inst])
  end
  buildMainLookup(newInstructions)
  buildWritesFirstLookup(newInstructions)
  buildOpLookupTable(newInstructions)
  buildDeprecatedLookupTable(newInstructions)
  HCOMP:RegenerateTokenizerOpcodes()
end

table.insert(CPULib.RemoveInstructionHooks,RemoveInstructions)
table.insert(CPULib.CreateInstructionHooks,CreateInstructions)
