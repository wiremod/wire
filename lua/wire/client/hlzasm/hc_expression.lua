--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Dynamic and constant expression generator
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Returns leaf for an expression on specific level
-- This will also test whether the expression is constant or not
function HCOMP:Expression_LevelLeaf(level)
  local levelLeaf
  local levelConst,levelValue,levelExpr = self:ConstantExpression(false,level)

  if levelConst then
    if levelExpr
    then levelLeaf = levelExpr  -- Expression that has to be recalculated later
    else levelLeaf = levelValue -- Numeric value
    end

    return { Constant = levelLeaf, CurrentPosition = self:CurrentSourcePosition() }
  else
    return self["Expression_Level"..level](self)
  end
end



-- generate explict increment/decrement opcode
function HCOMP:Expression_ExplictIncDec(opcode,label,returnAfter)
  local operationLeaf = self:NewLeaf()
  operationLeaf.Opcode = opcode

  if tonumber(label) then --returnBefore
    operationLeaf.Operands[1] = { Register = label }
  elseif not label.Type then
    operationLeaf.Operands[1] = label
  else
    if label.Type == "Variable" then
      operationLeaf.Operands[1] = { Memory = label }
    elseif label.Type == "Unknown" then
      operationLeaf.Operands[1] = { UnknownOperationByLabel = label }
    elseif label.Type == "Stack" then
      operationLeaf.Operands[1] = { Stack = label.StackOffset }
    elseif label.Type == "Register" then
      operationLeaf.Operands[1] = { Register = label.Value }
    end
  end

  -- Mark this leaf as an explict assign operation
  operationLeaf.ExplictAssign = true
  operationLeaf.ReturnAfterAssign = returnAfter

  return operationLeaf
end



-- level3: (<level0>) or <variable>
function HCOMP:Expression_Level3() local TOKEN = self.TOKEN
  local negateLeaf,operationLeaf


  -- Negate value if required
  if self:MatchToken(TOKEN.MINUS) then -- "-"
    negateLeaf = self:NewLeaf()
    negateLeaf.Opcode = "neg"
  end
  -- Logically negate value if required
  if self:MatchToken(TOKEN.NOT) then -- "!"
    negateLeaf = self:NewLeaf()
    negateLeaf.Opcode = "lneg"
  end


  if self:MatchToken(TOKEN.AND) then -- Parse retrieve pointer operation (&var)
    if self:MatchToken(TOKEN.IDENT) then
      local label = self:GetLabel(self.TokenData)
      if label.Type == "Stack" then
        if self:MatchToken(TOKEN.LSUBSCR) then -- Pointer to element of an array on stack
          local arrayOffsetLeaf = self:Expression()
          self:ExpectToken(TOKEN.RSUBSCR)

          -- Create leaf for calculating address
          local addressLeaf
          if arrayOffsetLeaf.Constant then
            addressLeaf = { Constant = label.StackOffset+arrayOffsetLeaf.Constant }
          else
            addressLeaf = self:NewLeaf()
            addressLeaf.Opcode = "add"
            addressLeaf.Operands[1] = { Constant = label.StackOffset }
            addressLeaf.Operands[2] = arrayOffsetLeaf
          end

          -- Create leaf that returns pointer to stack
          operationLeaf = self:NewLeaf()
          operationLeaf.Opcode = "add"
          operationLeaf.Operands[1] = { Register = 7, Segment = 2 } -- EBP:SS
          operationLeaf.Operands[2] = addressLeaf
        else -- Pointer to a stack variable
          -- FIXME: check if var is an array

          -- Create leaf that returns pointer to stack
          operationLeaf = self:NewLeaf()
          operationLeaf.Opcode = "add"
          operationLeaf.Operands[1] = { Register = 7, Segment = 2 } -- EBP:SS
          operationLeaf.Operands[2] = { Constant = label.StackOffset }
        end
      else
        -- All other pointers must be resolved by constant expression parser
        -- If they are not, it's a bug
        self:Error("Internal error 085")
      end
    else
      self:Error("Identifier expected")
      return
    end
  elseif self:MatchToken(TOKEN.TIMES) then -- Parse memory read operation
    local pointerLeaf = self:Expression_LevelLeaf(3)
    operationLeaf = { MemoryPointer = pointerLeaf }
  elseif self:MatchToken(TOKEN.INC) then -- Parse ++X
    local operandLeaf = self:Expression_LevelLeaf(3)
    operationLeaf = self:Expression_ExplictIncDec("inc",operandLeaf,true)
  elseif self:MatchToken(TOKEN.DEC) then -- Parse --X
    local operandLeaf = self:Expression_LevelLeaf(3)
    operationLeaf = self:Expression_ExplictIncDec("dec",operandLeaf,true)
  elseif self:MatchToken(TOKEN.REGISTER) or self:MatchToken(TOKEN.SEGMENT) then
    local register = self.TokenData
    if self.TokenType == TOKEN.SEGMENT then register = register + 15 end

    if self:MatchToken(TOKEN.INC) then -- reg++
      operationLeaf = self:Expression_ExplictIncDec("inc",register)
    elseif self:MatchToken(TOKEN.DEC) then -- reg--
      operationLeaf = self:Expression_ExplictIncDec("dec",register)
    else
      operationLeaf = { Register = register }
    end
  elseif self:MatchToken(TOKEN.IDENT) then
    local label = self:GetLabel(self.TokenData)
    local forceType = label.ForceType

    if self:MatchToken(TOKEN.INC) then -- Parse var++
      operationLeaf = self:Expression_ExplictIncDec("inc",label)
    elseif self:MatchToken(TOKEN.DEC) then -- Parse var--
      operationLeaf = self:Expression_ExplictIncDec("dec",label)
    elseif self:MatchToken(TOKEN.LPAREN) then -- Parse a function call
      -- Parse arguments and push them to stack
      local argumentCount = 0
      local argumentExpression = {}
      while not (self:PeekToken() == TOKEN.RPAREN) do
        -- Parse argument
        argumentExpression[#argumentExpression+1] = self:Expression()

        -- Go to next one
        argumentCount = argumentCount + 1
        self:MatchToken(TOKEN.COMMA)
      end
      self:ExpectToken(TOKEN.RPAREN)

      -- Find the function definition
      local functionEntry = self.Functions[label.Name]

      -- All leaves that must be generated previously to knowing correct result
      local genLeaves = {}

      -- Push arguments to stack in reverse order
      for argNo = #argumentExpression,1,-1 do
        local pushLeaf = self:NewLeaf()
        pushLeaf.Opcode = "push"
        pushLeaf.Operands[1] = argumentExpression[argNo]
        table.insert(genLeaves,pushLeaf)

        if functionEntry then
          if functionEntry.Parameters[argNo] then
            pushLeaf.Comment = label.Name.." arg #"..argNo.." ("..
              string.lower(self.TOKEN_TEXT["TYPE"][2][functionEntry.Parameters[argNo].Type])..
              string.rep("*",functionEntry.Parameters[argNo].PtrLevel)..
              " "..
              functionEntry.Parameters[argNo].Name..")"
          else
            pushLeaf.Comment = label.Name.." arg #"..argNo.." (unknown)"
          end
        end
      end

      -- Call function
      if functionEntry and functionEntry.InlineCode then
        for i=1,#functionEntry.InlineCode do
--          self:AddLeafToTail(functionEntry.InlineCode[i])
          if functionEntry.InlineCode[i].Opcode ~= "LABEL" then
            table.insert(genLeaves,functionEntry.InlineCode[i])
          end
        end
      else
        -- Push argument count to stack
        local argCountLeaf = self:NewLeaf()
        argCountLeaf.Opcode = "mov"
        argCountLeaf.ExplictAssign = true
        argCountLeaf.Operands[1] = { Register = 3 } -- ECX is the argument count register
        argCountLeaf.Operands[2] = { Constant = argumentCount }
        table.insert(genLeaves,argCountLeaf)

        local callLeaf = self:NewLeaf()
        callLeaf.Opcode = "call"
        callLeaf.Comment = label.Name.."(...)"
        if label.Type == "Stack" then
          callLeaf.Operands[1] = { Stack = label.StackOffset }
        else --{ PointerToLabel = label }
          callLeaf.Operands[1] = { UnknownOperationByLabel = label }
        end
        table.insert(genLeaves,callLeaf)
      end

      -- Stack cleanup
      if argumentCount > 0 then
        local stackCleanupLeaf = self:NewLeaf()
        stackCleanupLeaf.Opcode = "add"
        stackCleanupLeaf.ExplictAssign = true
        stackCleanupLeaf.Operands[1] = { Register = 7 }
        stackCleanupLeaf.Operands[2] = { Constant = argumentCount }
        table.insert(genLeaves,stackCleanupLeaf)
      end

      -- Create correct leaf tree
      for i=2,#genLeaves do
        genLeaves[i].PreviousLeaf = genLeaves[i-1]
      end

      -- Return EAX as the return value
      operationLeaf = { Register = 1, ForceTemporary = true, PreviousLeaf = genLeaves[#genLeaves] } -- EAX is the return value
    elseif self:MatchToken(TOKEN.LSUBSCR) then -- Parse array access
      local arrayOffsetLeaf = self:Expression()
      self:ExpectToken(TOKEN.RSUBSCR)

      -- Create leaf for calculating address
      local addressLeaf = self:NewLeaf()

      if label.Array then -- Parse array access treating label as pointer to array
        if label.Type == "Stack" then
          if arrayOffsetLeaf.Constant then
            operationLeaf = { Stack = label.StackOffset+arrayOffsetLeaf.Constant }
          else
            addressLeaf.Opcode = "add"
            addressLeaf.Operands[1] = { Constant = label.StackOffset }
            addressLeaf.Operands[2] = arrayOffsetLeaf
            operationLeaf = { Stack = addressLeaf }
          end
        else
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = arrayOffsetLeaf
          addressLeaf.Operands[2] = { PointerToLabel = label }
          operationLeaf = { MemoryPointer = addressLeaf }
        end
      else -- Parse array access treating variable as pointer
        if label.Type == "Stack" then
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = { Stack = label.StackOffset }
          addressLeaf.Operands[2] = arrayOffsetLeaf
          operationLeaf = { MemoryPointer = addressLeaf }
        elseif label.Type == "Variable" then
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = arrayOffsetLeaf
          addressLeaf.Operands[2] = { Memory = label }
          operationLeaf = { MemoryPointer = addressLeaf }
        elseif label.Type == "Pointer" then
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = arrayOffsetLeaf
          addressLeaf.Operands[2] = { Constant = {{ Type = TOKEN.IDENT, Data = label.Name, Position = self:CurrentSourcePosition() }} }
          operationLeaf = { MemoryPointer = addressLeaf }
        elseif label.Type == "Register" then
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = arrayOffsetLeaf
          addressLeaf.Operands[2] = { Register = label.Value }
          operationLeaf = { MemoryPointer = addressLeaf }
        else
          addressLeaf.Opcode = "add"
          addressLeaf.Operands[1] = arrayOffsetLeaf
          addressLeaf.Operands[2] = { UnknownOperationByLabel = label }
          operationLeaf = { MemoryPointer = addressLeaf }
        end
      end

      if self:MatchToken(TOKEN.INC) then -- reg++
        operationLeaf = self:Expression_ExplictIncDec("inc",operationLeaf)
      elseif self:MatchToken(TOKEN.DEC) then -- reg--
        operationLeaf = self:Expression_ExplictIncDec("dec",operationLeaf)
      end
    else -- Parse variable access
      if label.Type == "Variable" then -- Read from a variable
        -- Array variables are resolved as pointers at constant expression stage
        operationLeaf = { Memory = label, ForceType = forceType }
      elseif label.Type == "Unknown" then -- Read from an unknown variable
        operationLeaf = { UnknownOperationByLabel = label, ForceType = forceType }
      elseif label.Type == "Stack" then -- Read from stack
        if label.Array then
          -- Array on stack - return pointer
          operationLeaf = self:NewLeaf()
          operationLeaf.Opcode = "add"
          operationLeaf.Operands[1] = { Register = 7, Segment = 2 } -- EBP:SS
          operationLeaf.Operands[2] = { Constant = label.StackOffset }
        else
          -- Stack variable
          operationLeaf = { Stack = label.StackOffset, ForceType = forceType }
        end
      elseif label.Type == "Register" then
        -- Register variable
        operationLeaf = { Register = label.Value }
      end
    end
  elseif self:MatchToken(TOKEN.LPAREN) then -- (...)
    if self:MatchToken(TOKEN.TYPE) then
      local forceType = self.TokenData
      operationLeaf = self:Expression_LevelLeaf(3)
      operationLeaf.ForceType = forceType
    else
      operationLeaf = self:Expression_LevelLeaf(0)
    end
    self:ExpectToken(TOKEN.RPAREN)
  end

  if not operationLeaf then
    self:Error("Expression expected, got \""..self:PrintTokens(self:GetSavedTokens()).."\"")
    return
  else
    -- Assign sourcecode position to leaf
    if not operationLeaf.CurrentPosition then
      operationLeaf.CurrentPosition = self:CurrentSourcePosition()
    end

    -- Negate the result if required
    if negateLeaf then
      negateLeaf.Operands[1] = operationLeaf
      return negateLeaf
    else
      return operationLeaf
    end
  end
end


-- level2: <level3> * <level2>
function HCOMP:Expression_Level2()
  local leftLeaf = self:Expression_LevelLeaf(3)

  local token = self:PeekToken()
  if (token == self.TOKEN.TIMES) or
     (token == self.TOKEN.SLASH) or
     (token == self.TOKEN.POWER) or
     (token == self.TOKEN.MODULUS) then
    self:NextToken()
    local rightLeaf = self:Expression_LevelLeaf(2)

    if token == self.TOKEN.TIMES   then return self:NewOpcode("mul", leftLeaf,rightLeaf) end
    if token == self.TOKEN.SLASH   then return self:NewOpcode("div", leftLeaf,rightLeaf) end
    if token == self.TOKEN.POWER   then return self:NewOpcode("fpwr",leftLeaf,rightLeaf) end
    if token == self.TOKEN.MODULUS then return self:NewOpcode("mod",leftLeaf,rightLeaf) end
  else
    return leftLeaf
  end
end


-- level1: <level2> + <level0>
function HCOMP:Expression_Level1()
  local leftLeaf = self:Expression_LevelLeaf(2)

  local token = self:PeekToken()
  if (token == self.TOKEN.PLUS) or
     (token == self.TOKEN.MINUS) then -- +-
    -- Treat "-" as negate instead of subtraction FIXME
    if token == self.TOKEN.PLUS then self:NextToken() end

    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("add",leftLeaf,rightLeaf)
  elseif (token == self.TOKEN.LAND) or
         (token == self.TOKEN.LOR) then -- &&, ||
    self:NextToken()
    local rightLeaf = self:Expression_LevelLeaf(0)

    if token == self.TOKEN.LAND then return self:NewOpcode("and",leftLeaf,rightLeaf) end
    if token == self.TOKEN.LOR  then return self:NewOpcode("or",leftLeaf,rightLeaf) end
  elseif (token == self.TOKEN.AND) or
         (token == self.TOKEN.OR) or
         (token == self.TOKEN.XOR) then -- &, |, ^
    self:NextToken()
    local rightLeaf = self:Expression_LevelLeaf(0)

    if token == self.TOKEN.AND then return self:NewOpcode("band",leftLeaf,rightLeaf) end
    if token == self.TOKEN.OR  then return self:NewOpcode("bor", leftLeaf,rightLeaf) end
    if token == self.TOKEN.XOR then return self:NewOpcode("bxor",leftLeaf,rightLeaf) end
  else
    return leftLeaf
  end
end


-- level0: <level1> = <level0>
function HCOMP:Expression_Level0()
  local leftLeaf = self:Expression_LevelLeaf(1)

  if self:MatchToken(self.TOKEN.EQUAL) then -- =
    local rightLeaf = self:Expression_LevelLeaf(0)

    -- Mark this leaf as an explict assign operation
    local operationLeaf = self:NewOpcode("mov",leftLeaf,rightLeaf)
    operationLeaf.ExplictAssign = true
    operationLeaf.ReturnAfterAssign = true
    return operationLeaf
  elseif self:MatchToken(self.TOKEN.LSS) then -- <
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("max",
             self:NewOpcode("fsgn",
               self:NewOpcode("sub",rightLeaf,leftLeaf),
               { TrigonometryHack = true }
             ),
             { Constant = 0 }
           )
  elseif self:MatchToken(self.TOKEN.GTR) then -- >
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("max",
             self:NewOpcode("fsgn",
               self:NewOpcode("neg",
                 self:NewOpcode("sub",rightLeaf,leftLeaf)
               ),
               { TrigonometryHack = true }
             ),
             { Constant = 0 }
           )
  elseif self:MatchToken(self.TOKEN.LEQ) then -- <=
    -- FIXME: returns "0", "1", or "2" instead of just 1 or 0
    -- Does not alter comparsions, but might be annoying?
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("max",
             self:NewOpcode("inc",
               self:NewOpcode("fsgn",
                 self:NewOpcode("sub",rightLeaf,leftLeaf),
                 { TrigonometryHack = true }
               )
             ),
             { Constant = 0 }
           )
  elseif self:MatchToken(self.TOKEN.GEQ) then -- >=
    -- FIXME: returns "0", "1", or "2" instead of just 1 or 0
    -- Does not alter comparsions, but might be annoying?
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("max",
             self:NewOpcode("inc",
               self:NewOpcode("fsgn",
                 self:NewOpcode("neg",
                   self:NewOpcode("sub",rightLeaf,leftLeaf)
                 ),
                 { TrigonometryHack = true }
               )
             ),
             { Constant = 0 }
           )
  elseif self:MatchToken(self.TOKEN.EQL) then -- ==
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("lneg",
             self:NewOpcode("fsgn",
               self:NewOpcode("fabs",
                 self:NewOpcode("sub",rightLeaf,leftLeaf),
                 { TrigonometryHack = true }
               ),
               { TrigonometryHack = true }
             )
           )
  elseif self:MatchToken(self.TOKEN.NEQ) then -- !=
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("fsgn",
             self:NewOpcode("fabs",
               self:NewOpcode("sub",rightLeaf,leftLeaf),
               { TrigonometryHack = true }
             ),
             { TrigonometryHack = true }
           )
  elseif self:MatchToken(self.TOKEN.EQLADD) then -- +=
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("add",leftLeaf,rightLeaf)
  elseif self:MatchToken(self.TOKEN.EQLSUB) then -- -=
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("sub",leftLeaf,rightLeaf)
  elseif self:MatchToken(self.TOKEN.EQLMUL) then -- *=
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("mul",leftLeaf,rightLeaf)
  elseif self:MatchToken(self.TOKEN.EQLDIV) then -- /=
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("div",leftLeaf,rightLeaf)
  elseif self:MatchToken(self.TOKEN.SHR) then -- >>
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("bshr",leftLeaf,rightLeaf)
  elseif self:MatchToken(self.TOKEN.SHL) then -- <<
    local rightLeaf = self:Expression_LevelLeaf(0)
    return self:NewOpcode("bshl",leftLeaf,rightLeaf)
  else
    return leftLeaf
  end
end



-- Compile a single expression (statement) and return corresponding leaf
function HCOMP:Expression()
  local leaf = self:Expression_Level0()
  return leaf
end










--------------------------------------------------------------------------------
-- Constant expression parser
-- Each level function returns 3 values
--   1 Is return value constant (true/false)
--   2 Is return value precise (false if value depends on floating pointer)
--   3 Return value (or magic value)

--level3: (<level0>) or <constant>
function HCOMP:ConstantExpression_Level3()
  local constSign = 1
  if self:MatchToken(self.TOKEN.MINUS) then constSign = -1 end
  if self:MatchToken(self.TOKEN.PLUS) then constSign = 1 end

  if self:MatchToken(self.TOKEN.AND) then -- &pointer
    if self:MatchToken(self.TOKEN.IDENT) then
      local label = self:GetLabel(self.TokenData)
      if label.Type == "Pointer" then
        self:Error("Ident "..self.TokenData.." is not a variable")
      elseif label.Type == "Variable" then
        if label.Value and (not self.Settings.GenerateLibrary)
        then return true,true,label.Value*constSign
        else return true,false,self.Settings.MagicValue
        end
      elseif label.Type == "Stack" then
        -- Pointer to stack value is not a constant
        return false
      elseif label.Type == "Register" then
        -- Register variable is not a constant
        return false
      elseif label.Type == "Unknown" then
        return true,false,self.Settings.MagicValue
      else
        self:Error("Ident "..self.TokenData.." is not a label/pointer")
      end
    else
      return false
    end
  elseif self:MatchToken(self.TOKEN.NUMBER) then
    return true,true,self.TokenData*constSign
  elseif self:MatchToken(self.TOKEN.CHAR) then
    return true,true,self.TokenData*constSign
  elseif self:MatchToken(self.TOKEN.STRING) and (not self.IgnoreStringInExpression) then
    if self.GlobalStringTable[self.TokenData] then
      if self.GlobalStringTable[self.TokenData].Label.Value then
        return true,true,self.GlobalStringTable[self.TokenData].Label.Value*constSign
      else
        return true,false,self.Settings.MagicValue
      end
    else
      if self.StringsTable then
        if self.StringsTable[self.TokenData] then
          if self.StringsTable[self.TokenData].Label.Value then
            return true,true,self.StringsTable[self.TokenData].Label.Value*constSign
          else
            return true,false,self.Settings.MagicValue
          end
        else
          self.StringsTable[self.TokenData] = self:NewLeaf()
          self.StringsTable[self.TokenData].Opcode = "DATA"
          self.StringsTable[self.TokenData].Data = { self.TokenData, 0 }

          local stringLabel = self:GetTempLabel()
          stringLabel.Leaf = self.StringsTable[self.TokenData]
          self.StringsTable[self.TokenData].Label = stringLabel
          self.GlobalStringTable[self.TokenData] = self.StringsTable[self.TokenData]
          return true,false,self.Settings.MagicValue
        end
      else
        return false
      end
    end
  elseif self:MatchToken(self.TOKEN.IDENT) then
    local label = self:GetLabel(self.TokenData)
    if self:MatchToken(self.TOKEN.LSUBSCR) then
      -- Array access is never constant
      return false
    end
    if self:MatchToken(self.TOKEN.LPAREN) then
      -- Function calls are never constant
      return false
    end

    if label.Type == "Pointer" then
      -- Pointers are constant
      if label.Value and (not self.Settings.GenerateLibrary)
      then return true,true,label.Value*constSign
      else return true,false,self.Settings.MagicValue
      end
    elseif label.Type == "Variable" then
      if label.Array then
        -- Array variables must be treated as pointers
        if label.Value and (not self.Settings.GenerateLibrary)
        then return true,true,label.Value*constSign
        else return true,false,self.Settings.MagicValue
        end
      else
        -- Variables are not constant
        return false
      end
    elseif label.Type == "Stack" then
      -- Stack variables are not constant
      return false
    elseif label.Type == "Register" then
      -- Register variable is not a constant
      return false
    elseif label.Type == "Unknown" then
      if self.MostLikelyConstantExpression then
        -- Unknown variables are not constant, but they usually are.
        return true,false,self.Settings.MagicValue
      else
        -- It's probably not a constant expression
        return false
      end

      -- If this variable wasn't really constant, the error will be caught
      -- on the final output stage when all constant expressions are
      -- recalculated
    else
      self:Error("Ident "..self.TokenData.." is not a label/pointer")
    end
  elseif self:MatchToken(self.TOKEN.LPAREN) then
    local isConst,isPrecise,Value = self:ConstantExpression_Level0()
    if not isConst then return false end
    self:MatchToken(self.TOKEN.RPAREN)
    --FIXME: this should be expect when you NEED constant value, and match when you TEST FOR constant value

    return true,isPrecise,Value*constSign
  end

  return false
end


--level2: <level3> * <level2>
function HCOMP:ConstantExpression_Level2()
  local leftConst,leftPrecise,leftValue = self:ConstantExpression_Level3()
  if not leftConst then return false end

  local token = self:PeekToken()
  if (token == self.TOKEN.TIMES) or
     (token == self.TOKEN.SLASH) or
     (token == self.TOKEN.POWER) or
     (token == self.TOKEN.MODULUS) then
    self:NextToken()
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level2()
    if not rightConst then return false end

    if token == self.TOKEN.TIMES   then return true,(leftPrecise and rightPrecise),leftValue*rightValue end
    if token == self.TOKEN.SLASH   then return true,(leftPrecise and rightPrecise),leftValue/rightValue end
    if token == self.TOKEN.POWER   then return true,(leftPrecise and rightPrecise),leftValue^rightValue end
    if token == self.TOKEN.MODULUS then return true,(leftPrecise and rightPrecise),leftValue%rightValue end
  else
    return true,leftPrecise,leftValue
  end
end


--level1: <level2> + <level0>
function HCOMP:ConstantExpression_Level1()
  local leftConst,leftPrecise,leftValue = self:ConstantExpression_Level2()
  if not leftConst then return false end

  local token = self:PeekToken()
  if (token == self.TOKEN.PLUS) or
     (token == self.TOKEN.MINUS) then
    if token == self.TOKEN.PLUS then self:NextToken() end
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

--    if token == self.TOKEN.PLUS  then return true,(leftPrecise and rightPrecise),leftValue+rightValue end
    return true,(leftPrecise and rightPrecise),leftValue+rightValue
--    if token == self.TOKEN.MINUS then return true,(leftPrecise and rightPrecise),leftValue-rightValue end
  else
    return true,leftPrecise,leftValue
  end
end


--level0: <level1> = <level1>
function HCOMP:ConstantExpression_Level0()
  local leftConst,leftPrecise,leftValue = self:ConstantExpression_Level1()
  if not leftConst then return false end

  if self:MatchToken(self.TOKEN.EQUAL) then -- =
    return false
  elseif self:MatchToken(self.TOKEN.LSS) then -- <
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue < rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  elseif self:MatchToken(self.TOKEN.GTR) then -- >
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue > rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  elseif self:MatchToken(self.TOKEN.LEQ) then -- <=
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue <= rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  elseif self:MatchToken(self.TOKEN.GEQ) then -- >=
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue >= rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  elseif self:MatchToken(self.TOKEN.EQL) then -- ==
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue == rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  elseif self:MatchToken(self.TOKEN.NEQ) then -- !=
    local rightConst,rightPrecise,rightValue = self:ConstantExpression_Level0()
    if not rightConst then return false end

    if leftValue ~= rightValue
    then return true,(leftPrecise and rightPrecise),1
    else return true,(leftPrecise and rightPrecise),0
    end
  end

  return true,leftPrecise,leftValue
end


-- Calculate constant expression and return expression
function HCOMP:ConstantExpression(needResultNow,startLevel)
  self:SaveParserState()

  local isConst,isPrecise,value
      if startLevel == 3 then isConst,isPrecise,value = self:ConstantExpression_Level3()
  elseif startLevel == 2 then isConst,isPrecise,value = self:ConstantExpression_Level2()
  elseif startLevel == 1 then isConst,isPrecise,value = self:ConstantExpression_Level1()
  else                        isConst,isPrecise,value = self:ConstantExpression_Level0()
  end

  if isPrecise then
    return true,value
  else
    if needResultNow then
      self:RestoreParserState()
      return false
    end

    if isConst then
      -- Return list of tokens that correspond to parsed expression
      -- This is used to recalculate expression later
      return true,nil,self:GetSavedTokens()
    else
      self:RestoreParserState()
      return false
    end
  end
end
