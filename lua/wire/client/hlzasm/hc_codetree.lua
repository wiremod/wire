--------------------------------------------------------------------------------
-- Creates new code tree leaf
function HCOMP:NewLeaf(parentLeaf)
  local leaf = {
    Opcode = "INVALID",      -- Opcode number in this leaf
    Operands = {},
    ParentLabel = self.CurrentParentLabel,
  }

  if parentLeaf then
    leaf.CurrentPosition = parentLeaf.CurrentPosition
  else
    leaf.CurrentPosition = self:CurrentSourcePosition()
  end
  return leaf
end

function HCOMP:NewOpcode(opcode,op1,op2)
  local leaf = self:NewLeaf()
  leaf.Opcode = opcode
  leaf.Operands[1] = op1
  leaf.Operands[2] = op2
  return leaf
end

-- Each operand can contain the following entries:
--   Register - number of register to use (if it's an "eax" or "es:eax" operand)
--   Constant - constant value to use (if it's an "123" or "es:123" or "123:es" operand)
--   Memory - leaf of memory block to use (if it's an "ptr" or "es:ptr" or "ptr:es" operand)
--   MemoryPointer - explict pointer to memory (can be constant or a leaf)
--   Segment - number of segment register to use
--   MemoryRegister - memory by register (if it's an "#eax" or es:#eax
--   UnknownOperationByLabel - operation type will be determined by label
--   PointerToLabel - operation to retrieve pointer by label
--   Stack - stack operation (can be constant offset or a leaf)
--   TrigonometryHack - operand copied from the first one
--   PreviousLeaf - leaf that must be generated prior to calculating operand
--   ForceTemporary - forces this register to be marked busy & temporary

-- Each leaf contains the following REQUIRED items:
--   Opcode (required)
--   Operands (required if opcode is asm one)
--   CurrentPosition (position in the sourcecode leaf corresponds to)

-- Each leaf can contain the following OPTIONAL markers:
--   ForceType - force type of the operation (int, vector, matrix)
--   ExplictAssign (true/nil, the opcode MUST be performed. Result returned BEFORE the operation finished)
--   ReturnAfterAssign (true/nil, if this and ExplictAssign are set, result is returned AFTER the operation finished)
--   ZeroPadding (amount of zero bytes that must be padded after the leaf)
--   PreviousLeaf (leaf that must be generated prior to generating this one)
--   Comment (extra commentary inserted before leaf in assembly listing)
--   Label (label this leaf corresponds to)
--   Data (extra data to be written after the leaf)
--   SetWritePointer (command for leaf to change write pointer in the output stream)
--   SetPointerOffset (command for leaf to change offset in label pointers in output stream)
--   BusyRegisters (array of busy registers for this leaf)
--   ParentLabel (which label this leaf is assigned to, if label was not referenced, this code is not generated)

-- Special opcodes:
--   LABEL - label leaf (has no size)
--   DATA - data leaf (allocated data)
--   MARKER - marker which tells how to resync write pointer

-- Types of labels
--   Unknown (undefined)
--   Pointer
--   Variable
--   Stack
--   Register

-- Label can have extra marker:
--   Array (is this variable an array?)

--------------------------------------------------------------------------------
-- Adds leaf to the tail
function HCOMP:AddLeafToTail(leaf)
  if self.BusyRegisters then
    leaf.BusyRegisters = self.BusyRegisters
  end

  if self.GenerateInlineFunction then
    table.insert(self.InlineFunctionCode,leaf)
  else
    table.insert(self.CodeTree,leaf)
  end
end


--------------------------------------------------------------------------------
-- Returns free (non-busy) register. Does not check EBP and ESP
function HCOMP:FreeRegister()
  -- Try to find a free register
  for i=1,6 do
    if not self.RegisterBusy[i] then return i end
  end

  -- Try to find a register that wasnt pushed to stack yet
--  for i=1,6 do
--    if not self.RegisterStackOffset[i] then
--      local pushLeaf = self:NewLeaf()
--      pushLeaf.Opcode = "push"
--      pushLeaf.Operands[1] = { Register = i }
--      self.RegisterStackOffset[i] = 0
--    end
--  end
  -- FIXME: non-busy register must always exist?

  self:Error("Out of free registers",self.ErrorReportLeaf)
  return 1
end

-- Gets current list of registers used by users. This can be either the global
-- list, or list inside current code block
function HCOMP:GetUserRegisters()
  return self.UserRegisters
end



--------------------------------------------------------------------------------
-- Makes first operand temporary
-- Returns the register number used, changes the first operand to a temp register
function HCOMP:MakeFirstOperandTemporary(operands)
  local freeReg = self:FreeRegister()

  -- Generate MOV
  local movLeaf = self:NewLeaf(self.ErrorReportLeaf)
  movLeaf.Opcode = "mov"
  movLeaf.Operands[1] = {
    Register = freeReg
  }
  movLeaf.Operands[2] = operands[1]
  self:GenerateLeaf(movLeaf)

  -- Sets operand to be free register, and marks it as temporary and busy
  operands[1] = movLeaf.Operands[1]
  operands[1].Temporary = true
  self.RegisterBusy[freeReg] = true

  return freeReg
end

-- Reads operand from stack into a temp register (index: which operand is the stack index)
function HCOMP:ReadOperandFromStack(operands,index,forceRead)
  local stackOffset = operands[index].Stack
  local freeReg = self:FreeRegister()

  -- Generate RSTACK opcode to read value from stack
  local rstackLeaf = self:NewLeaf(self.ErrorReportLeaf)
  rstackLeaf.Opcode = "rstack"
  rstackLeaf.Operands[1] = {
    Register = freeReg,
  }
  if tonumber(stackOffset) then -- Stack offset is a constant value
    rstackLeaf.Operands[2] = {
      Constant = stackOffset,
      Segment = 16
    }
  else -- Stack offset is a leaf that returns a constant value
    -- Register must be marked used up so its not used in next gen step
    self.RegisterBusy[freeReg] = true

    -- Request result of this leaf into a register
    local offsetReg,isTemp = self:GenerateLeaf(operands[index].Stack,true)
    rstackLeaf.Operands[2] = {
      Register = offsetReg,
      Segment = 16,
      Temporary = isTemp
    }
    self.RegisterBusy[offsetReg] = isTemp

    self.RegisterBusy[freeReg] = false
  end

  -- Generate "RSTACK" leaf
  self:GenerateLeaf(rstackLeaf)

  -- Mark register as used (couldn't do before or else code generator would
  -- mess up the RSTACK instruction)
  self.RegisterBusy[freeReg] = true

  -- Change the operand (and make sure it retains stack offset)
  operands[index] = rstackLeaf.Operands[1]
  operands[index].Temporary = true
  operands[index].Stack = stackOffset
end

-- Reads operand from memory (index: which operand is the memory pointer)
-- Replaces operand with a temporary register
function HCOMP:ReadOperandFromMemory(operands,index)
  if operands[index].MemoryPointer.Opcode then -- Parse complex expression
    local addrReg,isTemp = self:GenerateLeaf(operands[index].MemoryPointer,true)
    operands[index] = { MemoryRegister = addrReg, Temporary = isTemp }
    self.RegisterBusy[addrReg] = isTemp
    return addrReg
  else -- Parse an operand
    local freeReg = self:FreeRegister()
    if operands[index].MemoryPointer.Stack then -- Generate stack read
      if not tonumber(operands[index].MemoryPointer.Stack) then self:Error("Internal error 186") end
      local rstackLeaf = self:NewLeaf(self.ErrorReportLeaf)
      rstackLeaf.Opcode = "rstack"
      rstackLeaf.Operands[1] = { Register = freeReg }
      rstackLeaf.Operands[2] = { Constant = operands[index].MemoryPointer.Stack, Segment = 16 }
      self:GenerateLeaf(rstackLeaf)

      operands[index] = { MemoryRegister = freeReg, Temporary = true }
      self.RegisterBusy[freeReg] = true
      return addrReg
    else -- Generate more than just a stack read
      if operands[index].MemoryPointer.Register then
        operands[index] = { MemoryRegister = operands[index].MemoryPointer.Register, Temporary = operands[index].MemoryPointer.Temporary }
        return operands[index].Register
      elseif operands[index].MemoryPointer.Constant then
        operands[index] = { Memory = operands[index].MemoryPointer.Constant }
        return nil
      else
        local movLeaf = self:NewLeaf(self.ErrorReportLeaf)
        movLeaf.Opcode = "mov"
        movLeaf.Operands[1] = { Register = freeReg, Temporary = true }
        movLeaf.Operands[2] = operands[index].MemoryPointer
        self.RegisterBusy[freeReg] = true

        local addrReg,isTemp = self:GenerateLeaf(movLeaf,true)
        operands[index] = { MemoryRegister = addrReg, Temporary = isTemp }
        self.RegisterBusy[addrReg] = isTemp
        return addrReg
      end
    end
  end
end

-- Turns known label operation into a know one
function HCOMP:TurnUnknownLabelIntoKnown(operand)
  local label = operand.UnknownOperationByLabel
  operand.UnknownOperationByLabel = nil
  --print("UNKLABEL",label.Name,label.Type)
  if label.Type == "Variable" then
    operand.Memory = label
  elseif label.Type == "Pointer" then
    operand.Constant = label.Expression or {{ Type = self.TOKEN.IDENT, Data = label.Name, Position = self.ErrorReportLeaf.CurrentPosition }}
  else
    if not label.Name then self:Error("Internal error 033") end
    self:Error("Undefined label: "..label.Name,self.ErrorReportLeaf)
  end
end









--------------------------------------------------------------------------------
-- This is THE BEST function. Its the one which turns code tree into generated
-- code.
--
-- Generates code for the leaf. Returns register which stores result, if required
--
-- MASSIVE NOTE: it returns WHETHER THE REGISTER >>>MUST<<< BE MADE TEMPORARY,
--               not that it's actually temporary!
--
function HCOMP:GenerateLeaf(leaf,needResult)
  -- Set this leaf for error reporting (small hack)
  self.ErrorReportLeaf = leaf

--  local initTempRegisters = {}
--  for k,v in pairs(self.RegisterBusy) do
--    initTempRegisters[k] = v
--  end

  -- If we have previous leaf, generate it
  if leaf.PreviousLeaf then
    self:GenerateLeaf(leaf.PreviousLeaf,false)
    leaf.PreviousLeaf = nil
  end

  -- Do not generate invalid tree leaves
  if not leaf.Opcode then
    if not leaf.PreviousLeaf then --not leaf.Register then
      if type(leaf.Constant) == "table" then
        self:Warning("Trying to generate invalid code ("..self:PrintTokens(leaf.Constant)..")",leaf)
      elseif not leaf.ForceTemporary then
        self:Warning("Trying to generate invalid code",leaf)
      end
    end
    return
  end

  -- If operand has a previous leaf assigned, generate it
--  for i=1,#leaf.Operands do
--    if leaf.Operands[i].PreviousLeaf then
--      self:GenerateLeaf(leaf.Operands[i].PreviousLeaf,false)
--      leaf.Operands[i].PreviousLeaf = nil
--    end
--  end

  -- Check if this opcode writes to its first argument
  local opcodeWritesFirstOperand = (#leaf.Operands == 2) or
                                  ((#leaf.Operands == 1) and (self.OpcodeWritesOperand[leaf.Opcode]))

  -- Generate explict operands for this leaf
  local genOperands = {}
  local i = #leaf.Operands
  while i >= 1 do
    if leaf.Operands[i].PreviousLeaf then
      self:GenerateLeaf(leaf.Operands[i].PreviousLeaf,false)
      leaf.Operands[i].PreviousLeaf = nil
    end

    -- Turn unknown label into known one
    if leaf.Operands[i].UnknownOperationByLabel then
      --self:TurnUnknownLabelIntoKnown(leaf.Operands[i])
      local label = leaf.Operands[i].UnknownOperationByLabel
      leaf.Operands[i].UnknownOperationByLabel = nil
      if label.Type == "Variable" then
        leaf.Operands[i].Memory = label
      elseif label.Type == "Pointer" then
        leaf.Operands[i].Constant = label.Expression or {{ Type = self.TOKEN.IDENT, Data = label.Name, Position = self.ErrorReportLeaf.CurrentPosition }}
      else
        if not label.Name then self:Error("Internal error 033") end
        self:Error("Undefined label: "..label.Name,self.ErrorReportLeaf)
      end
    end
    if leaf.Operands[i].MemoryPointer and
       (type(leaf.Operands[i].MemoryPointer) == "table") and
       leaf.Operands[i].MemoryPointer.UnknownOperationByLabel then
--      self:TurnUnknownLabelIntoKnown(leaf.Operands[i].MemoryPointer)
      local label = leaf.Operands[i].MemoryPointer.UnknownOperationByLabel
      leaf.Operands[i].MemoryPointer.UnknownOperationByLabel = nil
      if label.Type == "Variable" then
        leaf.Operands[i].MemoryPointer = { Memory = label }
      elseif label.Type == "Pointer" then
        leaf.Operands[i].MemoryPointer = label.Expression or {{ Type = self.TOKEN.IDENT, Data = label.Name, Position = self.ErrorReportLeaf.CurrentPosition }, TokenList = true }
      elseif label.Type == "Register" then
        leaf.Operands[i].MemoryPointer = { MemoryRegister = label.Value }
      else
        if not label.Name then self:Error("Internal error 033") end
        self:Error("Undefined label: "..label.Name,self.ErrorReportLeaf)
      end
    end

    if leaf.Operands[i].Opcode then -- It's an opcode, not an operand we can write
      -- Try to calculate the leaf into some temporary register
      local resultReg,isTemp = self:GenerateLeaf(leaf.Operands[i],true)
      if resultReg then
        self.RegisterBusy[resultReg] = isTemp
        genOperands[i] = {
          Register = resultReg,
          Temporary = isTemp,
        }
      else
        -- Generate invalid constant value
        genOperands[i] = {
          Constant = self.Settings.MagicValue,
        }
        self:Error("Expression messed up",leaf)
      end
    else
      genOperands[i] = {}
      for k,v in pairs(leaf.Operands[i]) do genOperands[i][k] = v end

      -- Need a real explict value if its laying on stack, and we want to write into it
      -- Do not gen explict value if our opcode is MOV though (we can turn it into sstack later)
      -- Also do not generate explict value if its an explict assign
      if genOperands[i].Stack then
        if ((i == 1) and (leaf.Opcode ~= "mov")) or -- Force value out of stack if we are about to perform an instruction on it
            (i == 2) then                           -- Or if we are about to read from it
          self:ReadOperandFromStack(genOperands,i)
        end
      end

      -- Need a real explict value if its a non-constant address to memory
      if       genOperands[i].MemoryPointer and
         (type(genOperands[i].MemoryPointer) == "table") and
         (not genOperands[i].MemoryPointer.TokenList) then

        self:ReadOperandFromMemory(genOperands,i)
      end

      -- Calculate pointer to the label if required
      -- was "(i > 1) and genOperands[i].PointerToLabel"
      if genOperands[i].PointerToLabel then
        local label = genOperands[i].PointerToLabel
        if (label.Type == "Variable") or (label.Type == "Unknown") then -- Read from a variable

          genOperands[i] =
            { Constant =
              { { Type = self.TOKEN.AND, Position = leaf.CurrentPosition },
                { Type = self.TOKEN.IDENT, Data = genOperands[i].PointerToLabel.Name, Position = leaf.CurrentPosition },
              }
            }
        elseif label.Type == "Stack" then -- Read from stack
          genOperands[i] = { Constant = genOperands[i].PointerToLabel.StackOffset }
        elseif label.Type == "Pointer" then -- Pointer value
          genOperands[i] = { Constant = {{ Type = self.TOKEN.IDENT, Data = genOperands[i].PointerToLabel.Name, Position = leaf.CurrentPosition }} }
        end
      end

      -- Make register operand temporary if requested
      if genOperands[i].ForceTemporary then
        local initReg = genOperands[i].Register
        genOperands[i].ForceTemporary = false

        if self.RegisterBusy[initReg] then
          local freeReg = self:FreeRegister()
          self.RegisterBusy[initReg] = false

          local pushLeaf = self:NewLeaf(leaf)
          pushLeaf.Opcode = "push"
          pushLeaf.Operands[1] = { Register = initReg }
          self:GenerateLeaf(pushLeaf)

          local movLeaf = self:NewLeaf(leaf)
          movLeaf.Opcode = "mov"
          movLeaf.Operands[1] = { Register = freeReg, Temporary = true }
          movLeaf.Operands[2] = { Register = initReg }
          self.RegisterBusy[freeReg] = true

          local addrReg,isTemp = self:GenerateLeaf(movLeaf,true)
          genOperands[i] = { Register = addrReg, Temporary = isTemp }
          self.RegisterBusy[addrReg] = isTemp

          local popLeaf = self:NewLeaf(leaf)
          popLeaf.Opcode = "pop"
          popLeaf.Operands[1] = { Register = initReg }
          self:GenerateLeaf(popLeaf)

          self.RegisterBusy[initReg] = true
        else
          genOperands[i].Temporary = true
          self.RegisterBusy[initReg] = true
        end
      end
    end

    i = i - 1
  end

  -- Result to return (if needResult is true)
  local destRegister,isDestTemp

  if opcodeWritesFirstOperand then
    -- Apply hack for trigonometric operations which look like "FSIN EAX,EAX" instead of "FSIN EAX"
    if (#leaf.Operands > 1) and (genOperands[2].TrigonometryHack) then
      genOperands[2] = genOperands[1]
    end

    -- Are we trying to operate on a value which is busy or must not be changed? (MOV busyReg,<...>)
    -- But if register is temporary, lets just re-assign it
    if (not leaf.ExplictAssign) and
       (genOperands[1].Register) and (not genOperands[1].Temporary) and
       ((self.RegisterBusy[genOperands[1].Register] == true) or
        (self.RegisterBusy[genOperands[1].Register] == nil)) then
      self:MakeFirstOperandTemporary(genOperands)
    end

    -- Check if we are trying to do "MOV VAR,<...>" when VAR is a stack one (change to SSTACK instead)
    if (genOperands[1].Stack) and (leaf.Opcode == "mov") then
      -- MOV STK(10),123 -> SSTACK EBP:10,123
      leaf.Opcode = "sstack"
      if tonumber(genOperands[1].Stack) then
        genOperands[1].Constant = genOperands[1].Stack
        genOperands[1].Register = nil
      else
        local offsetReg,isTemp = self:GenerateLeaf(genOperands[1].Stack,true)
        genOperands[1] = { Register = offsetReg, Temporary = isTemp }
        self.RegisterBusy[offsetReg] = isTemp
      end
      genOperands[1].Segment = 16
      genOperands[1].Stack = nil
    end

    -- Check if we are trying to do "INC VAR" when VAR is a stack, explict one
    if leaf.ExplictAssign and (genOperands[1].Stack) then
      -- INC STK(10) -> INC STK(10); SSTACK EBP:10,VAR
      local sstackLeaf = self:NewLeaf(leaf)
      sstackLeaf.Opcode = "sstack"
      if tonumber(genOperands[1].Stack) then
        sstackLeaf.Operands[1] = { Constant = genOperands[1].Stack }
      else
        local offsetReg,isTemp = self:GenerateLeaf(genOperands[1].Stack,true)
        sstackLeaf.Operands[1] = { Register = offsetReg, Temporary = isTemp }
        self.RegisterBusy[offsetReg] = isTemp
      end

      genOperands[1].Stack = nil
      sstackLeaf.Operands[1].Segment = 16
      sstackLeaf.Operands[2] = genOperands[1]
      leaf.NextLeaf = sstackLeaf
    end

    -- Are we trying to do "ADD VAR,<...>" when VAR is a stack one?
    -- At this point "VAR" is already read into a register, so generate this leaf, and then
    -- change it to sstack
    if (genOperands[1].Stack) and (genOperands[1].Register) then
      local tempReg = genOperands[1].Register
      local stackOffset = genOperands[1].Stack

      -- Generate proper opcode for the opepration
      local operationLeaf = self:NewLeaf(leaf)
      operationLeaf.Opcode = leaf.Opcode
      operationLeaf.Operands[1] = {
        Register = tempReg,
        Temporary = true
      }
      self.RegisterBusy[tempReg] = true
      if #leaf.Operands > 1 then
        -- Generate second operand. It's already read from stack into a temp register,
        -- so remove the "stack" marker
        operationLeaf.Operands[2] = genOperands[2]
        operationLeaf.Operands[2].Stack = nil
      end
      self:GenerateLeaf(operationLeaf)

      -- Turn this operation into SSTACK
      leaf.Opcode = "sstack"
      genOperands[2] = {
        Register = tempReg,
        Temporary = true
      }
      genOperands[1] = {
        Constant = stackOffset,
        Segment = 16
      }
      self.RegisterBusy[tempReg] = true
    end

    -- If we really need result, then make sure it lies in some register
    if needResult then
      if genOperands[1].Register and (not leaf.ExplictAssign) then
        -- If operand is already a register, just return it
        -- (that is, unless we want an explict assign operation on it)
        destRegister = genOperands[1].Register
        isDestTemp = genOperands[1].Temporary
      else
        -- Otherwise we will need to copy this result into a register
        if leaf.Opcode == "sstack" then
          -- turn SSTACK into MOV
          destRegister = self:FreeRegister()
          leaf.Opcode = "mov"
          genOperands[1] = { Register = destRegister, Temporary = true } --FIXME
          isDestTemp = true

          -- This happens when there is a code tree like this:
          -- cmp
          --   0
          --   add
          --     stack 0
          --     stack 1
        else
          if leaf.ExplictAssign then -- Perform explict assign and copy to temp register anyway
            if leaf.ReturnAfterAssign then
              -- HACK: generate opcode before the MOV
              self:GenerateOpcode(leaf,genOperands)
              leaf.Opcode = nil

              local movLeaf = self:NewLeaf(leaf)
              destRegister = self:FreeRegister()
              movLeaf.Opcode = "mov"
              movLeaf.Operands[1] = {
                Register = destRegister
              }
              movLeaf.Operands[2] = genOperands[1]
              self:GenerateLeaf(movLeaf)
              self.RegisterBusy[destRegister] = true
              isDestTemp = true
            else
              local movLeaf = self:NewLeaf(leaf)
              destRegister = self:FreeRegister()
              movLeaf.Opcode = "mov"
              movLeaf.Operands[1] = {
                Register = destRegister
              }
              movLeaf.Operands[2] = genOperands[1]
              self:GenerateLeaf(movLeaf)
              self.RegisterBusy[destRegister] = true
              isDestTemp = true
            end
          else -- Just make it temporary
            destRegister = self:MakeFirstOperandTemporary(genOperands)
            isDestTemp = true
          end
        end
      end
    end
  end

  -- Generate the opcode, unless it's a "MOV REG,REG" (happens with RETURN token)
  if (not ((leaf.Opcode == "mov") and genOperands[1].Register and (genOperands[1].Register == genOperands[2].Register))) and
     (leaf.Opcode) then
    self:GenerateOpcode(leaf,genOperands)
  end

  -- Generate next leaf too, if required
  if leaf.NextLeaf then
    self:GenerateLeaf(leaf.NextLeaf,false)
  end

  -- Reset all temporary registers used in the expression
  for i=1,#genOperands do
    if genOperands[i].Temporary then
      if genOperands[i].Register then
        self.RegisterBusy[genOperands[i].Register] = false
      elseif genOperands[i].MemoryRegister then
        self.RegisterBusy[genOperands[i].MemoryRegister] = false
      else
        self:Error("Internal error 379",leaf)
      end
    end
  end

--  for k,v in pairs(initTempRegisters) do
--    self.RegisterBusy[k] = v
--    if not (isDestTemp and (destRegister == k)) then
--    if self.RegisterBusy[k] ~= v then
--      print("Internal error 564: register mismatch "..k.." ~= "..tostring(v).." @ "..leaf.Opcode,leaf)
--    end
--    end
--  end

  return destRegister,isDestTemp
end


--------------------------------------------------------------------------------
-- Generate opcode (writes it to the generated code list)
function HCOMP:GenerateOpcode(leaf,operands)
--  local registerBusyHint = {}
--  for k,v in pairs(self.RegisterBusy) do registerBusyHint[k] = v end
--      RegisterBusyHint = registerBusyHint, -- Hint on temporary registers for the optimizer

--  local rstr = ""
--  for i=1,8 do if self.RegisterBusy[i] then rstr = rstr.."1" else rstr = rstr.."0" end end
--  print(leaf.Opcode,rstr,leaf.CurrentPosition.Line)

  table.insert(self.GeneratedCode,{
      Opcode = leaf.Opcode,
      Operands = operands,
      Comment = leaf.Comment,
      CurrentPosition = leaf.CurrentPosition,
    })
end

-- Generate other marker
function HCOMP:GenerateMarker(leaf)
  table.insert(self.GeneratedCode,{
    ZeroPadding = leaf.ZeroPadding,
    Data = leaf.Data,
    Label = leaf.Label,
    Comment = leaf.Comment,

    SetWritePointer = leaf.SetWritePointer,
    CurrentPosition = leaf.CurrentPosition,
  })
end


--------------------------------------------------------------------------------
-- Generate leaf (called by the stage, it generates special leaves too)
function HCOMP:StageGenerateLeaf(leaf)
  if self.Settings.OutputCodeTree then self:PrintLeaf(leaf) end

  if self.Settings.NoUnreferencedLeaves == true then
    if leaf.ParentLabel and (leaf.ParentLabel.Referenced == false) then
      -- Do not generate leafs that are parented to unreferenced labels
      return false
    end
  end

  if (leaf.Opcode == "DATA") or
     (leaf.Opcode == "LABEL") or
     (leaf.Opcode == "MARKER") then
    self:GenerateMarker(leaf)
    return false
  else
    -- Make sure it never attempts to use ESP/EBP, mark them always busy
    self.RegisterBusy = { false,false,false,false,false,false,true,true }
    self.RegisterStackOffset = {}

    if leaf.BusyRegisters then
      for k,v in pairs(leaf.BusyRegisters) do
        self.RegisterBusy[k] = v
      end
    end

    self:GenerateLeaf(leaf)

    return false
  end
end
