--------------------------------------------------------------------------------
-- ZASM2 compatible syntax
--------------------------------------------------------------------------------




-- Syntax lookup for vector definitions
local VectorSyntax = {
  FLOAT    = { {} },
  SCALAR   = { {} },
  VECTOR1F = { {"x"} },
  VECTOR2F = { {"x"},{"y"} },
  VECTOR3F = { {"x"},{"y"},{"z"} },
  VECTOR4F = { {"x"},{"y"},{"z"},{"w"} },
  VEC1F    = { {"x"} },
  VEC2F    = { {"x"},{"y"} },
  VEC3F    = { {"x"},{"y"},{"z"} },
  VEC4F    = { {"x"},{"y"},{"z"},{"w"} },
  UV       = { {"x","u"},{"y","v"} },
  COLOR    = { {"x","r"},{"y","g"},{"z","b"},{"w","a"} },
  MATRIX   = {},
}
for i=0,15 do VectorSyntax.MATRIX[i+1] = {tostring(i)} end




--------------------------------------------------------------------------------
-- Compile an opcode (called after if self:MatchToken(TOKEN.OPCODE))
function HCOMP:Opcode() local TOKEN = self.TOKEN
  local opcodeName = self.TokenData
  local opcodeNo = self.OpcodeNumber[self.TokenData]
  local operandCount = self.OperandCount[opcodeNo]

  -- Check if opcode is obsolete or old
  if self.OpcodeObsolete[opcodeName] then
    self:Warning("Instruction \""..opcodeName.."\" is obsolete")
  end
  if self.OpcodeOld[opcodeName] then
    self:Warning("Mnemonic \""..opcodeName.."\" is an old mnemonic for this instruction. Please use the newer mnemonic \""..self.OpcodeOld[opcodeName].."\".")
  end

  -- Create leaf
  local opcodeLeaf = self:NewLeaf()
  opcodeLeaf.Opcode = opcodeName
  opcodeLeaf.ExplictAssign = true

  -- Parse operands
  for i=1,operandCount do
    local segmentOffset,constantValue,expressionLeaf
    local isMemoryReference,useSpecialMemorySyntax

    -- Check if it's a special memory reference ([<...>])
    if self:MatchToken(TOKEN.LSUBSCR) then
      isMemoryReference = true
      useSpecialMemorySyntax = true
    end

    -- Check for segment prefix (ES:<...> or ES+<...>)
    if ((self:PeekToken() == TOKEN.SEGMENT) or (self:PeekToken() == TOKEN.REGISTER)) and
       ((self:PeekToken(1) == TOKEN.DCOLON) or
        (useSpecialMemorySyntax and (self:PeekToken(1) == TOKEN.PLUS))) then -- next character is : or +
      if self:MatchToken(TOKEN.SEGMENT) then
        -- 1 to  8: CS .. LS
        segmentOffset = self.TokenData
      elseif self:MatchToken(TOKEN.REGISTER) then
        if self.TokenData >= 96 then -- 17+: extended registers
          segmentOffset = 17 + self.TokenData - 96
        else -- 9 to 16: EAX .. EBP
          segmentOffset = self.TokenData + 8
        end
      end

      if useSpecialMemorySyntax then
        if not self:MatchToken(TOKEN.DCOLON) then self:ExpectToken(TOKEN.PLUS) end
      else
        self:ExpectToken(TOKEN.DCOLON)
      end
    end

    -- Check if it's a memory reference (#<...>)
    if not useSpecialMemorySyntax then
      if self:MatchToken(TOKEN.HASH) then isMemoryReference = true end
    end

    -- Parse operand expression (use previous result if previous const wasnt related to seg offset)
    local c,v,e = self:ConstantExpression()
    if c then -- Constant value
      if v
      then constantValue = v -- Exact value
      else constantValue = e -- Expression to be recalculated later
      end
    else -- Expression
      expressionLeaf = self:Expression()
      if expressionLeaf.Opcode then
        self:Warning("Using complex expression as operand: might corrupt user register")
      end
      -- FIXME: warning about using extra registers?
    end

    -- Check for segment prefix again (reversed syntax <...>:ES)
    if self:MatchToken(TOKEN.DCOLON) then
      if (not segmentOffset) and
         ((self:PeekToken() == TOKEN.SEGMENT) or (self:PeekToken() == TOKEN.REGISTER)) then
        if self:MatchToken(TOKEN.SEGMENT) then
          -- 1 to  8: CS .. LS
          segmentOffset = self.TokenData
        elseif self:MatchToken(TOKEN.REGISTER) then
          if self.TokenData >= 96 then -- 17+: extended registers
            segmentOffset = 17 + self.TokenData - 96
          else -- 9 to 16: EAX .. EBP
            segmentOffset = self.TokenData + 8
          end
        end
      else
        self:Error("Invalid segment offset syntax")
      end
    end

    -- Trailing bracket for [...] memory syntax
    if useSpecialMemorySyntax then
      self:ExpectToken(TOKEN.RSUBSCR)
    end

    -- Create operand
    if isMemoryReference then
      if expressionLeaf then
        if expressionLeaf.Register then
          opcodeLeaf.Operands[i] = { MemoryRegister = expressionLeaf.Register, Segment = segmentOffset }
        else
          opcodeLeaf.Operands[i] = { MemoryPointer = expressionLeaf, Segment = segmentOffset }
        end
      else
        opcodeLeaf.Operands[i] = { MemoryPointer = constantValue, Segment = segmentOffset }
      end
    else
      if expressionLeaf then
        if expressionLeaf.Register then
          if (expressionLeaf.Register >= 16) and (expressionLeaf.Register <= 23) and (segmentOffset) then
            -- Swap EBX:ES with ES:EBX (because the former one is invalid in ZCPU)
            local register = expressionLeaf.Register
            local segment = segmentOffset

            -- Convert segment register index to register index
            if (segment >= 1) and (segment <= 8)  then expressionLeaf.Register = segment + 15 end
            if (segment >= 9) and (segment <= 16) then expressionLeaf.Register = segment - 8 end

            -- Convert register index to segment register index
            if (register >= 1)  and (register <= 8)  then segmentOffset = register + 8 end
            if (register >= 16) and (register <= 23) then segmentOffset = register - 15 end
          end
          opcodeLeaf.Operands[i] = { Register = expressionLeaf.Register, Segment = segmentOffset }
        else
          if segmentOffset then
            opcodeLeaf.Operands[i] = self:NewLeaf()
            opcodeLeaf.Operands[i].Opcode = "add"
            opcodeLeaf.Operands[i].Operands[1] = { Register = segmentOffset+15 }
            opcodeLeaf.Operands[i].Operands[2] = expressionLeaf
          else
            opcodeLeaf.Operands[i] = expressionLeaf
          end
        end
      else
        opcodeLeaf.Operands[i] = { Constant = constantValue, Segment = segmentOffset }
      end
    end

    -- Attach information from expression
    if expressionLeaf then
      opcodeLeaf.Operands[i].PreviousLeaf = expressionLeaf.PreviousLeaf
    end

    -- Syntax
    if i < operandCount then
      self:ExpectToken(TOKEN.COMMA)
    else
      if self:MatchToken(TOKEN.COMMA) then
        self:Error("Invalid operand count")
      end
    end
  end

  -- Check if first operand is a non-preserved register
  if self.BusyRegisters then
    if opcodeLeaf.Operands[1] and opcodeLeaf.Operands[1].Register and
       (self.BusyRegisters[opcodeLeaf.Operands[1].Register] == false) and
       (self.BlockDepth > 0) then
      self:Warning("Warning: using an unpreserved register")
    end

    if opcodeLeaf.Operands[1] and opcodeLeaf.Operands[1].MemoryRegister and
       (self.BusyRegisters[opcodeLeaf.Operands[1].MemoryRegister] == false) and
       (self.BlockDepth > 0) then
      self:Warning("Warning: using an unpreserved register")
    end
  end

  -- Add opcode to tail
  self:AddLeafToTail(opcodeLeaf)
  self:MatchToken(TOKEN.COLON)
  return true
end


--------------------------------------------------------------------------------
-- Start a new block
function HCOMP:BlockStart(blockType)
  if self.BlockDepth == 0 then
    -- Create leaf that corresponds to ENTER instruction
    self.HeadLeaf = self:NewLeaf()
    self.HeadLeaf.Opcode = "enter"
    self.HeadLeaf.Operands[1] = { Constant = self.Settings.MagicValue }
    self:AddLeafToTail(self.HeadLeaf)

    self.LocalLabels = {}
    self.StackPointer = 0
    if self.GenerateInlineFunction then
      self.ParameterPointer = 0 -- Skip EBP
    else
      self.ParameterPointer = 1 -- Skip EBP and return address
    end

    self.StringsTable = {}

    self.BlockType = {}
    self.SpecialLeaf = {}

    -- Create busy registers list
    self.BusyRegisters = { false,false,false,false,false,false,true,true }
  end

  -- Create a leaf that corresponds to label for BREAK
  local breakLeaf = self:NewLeaf()
  breakLeaf.Opcode = "LABEL"
  breakLeaf.Label = self:GetTempLabel()
  breakLeaf.Label.Type = "Pointer"
  breakLeaf.Label.Leaf = breakLeaf

  -- Create a leaf that corresponds to label for CONTINUE
  local continueLeaf = self:NewLeaf()
  continueLeaf.Opcode = "LABEL"
  continueLeaf.Label = self:GetTempLabel()
  continueLeaf.Label.Type = "Pointer"
  continueLeaf.Label.Leaf = continueLeaf
  self:AddLeafToTail(continueLeaf)

  self.SpecialLeaf[#self.SpecialLeaf+1] = {
    Break = breakLeaf,
    Continue = continueLeaf,
    JumpBack = self:NewLeaf(),
  }

  if (blockType == "FOR") or
     (blockType == "WHILE") or
     (blockType == "DO") then
    self.CurrentContinueLeaf = self.SpecialLeaf[#self.SpecialLeaf].Continue
    self.CurrentBreakLeaf = self.SpecialLeaf[#self.SpecialLeaf].Break
  end

  -- Push block type
  table.insert(self.BlockType,blockType or "FUNCTION")
  self.BlockDepth = self.BlockDepth + 1
end


--------------------------------------------------------------------------------
-- End the block
function HCOMP:BlockEnd()
  -- If required, add leaf that jumps back to block start
  if self.SpecialLeaf[#self.SpecialLeaf].JumpBack.Opcode ~= "INVALID" then
    self.SpecialLeaf[#self.SpecialLeaf].JumpBack.CurrentPosition = self:CurrentSourcePosition()
    self:AddLeafToTail(self.SpecialLeaf[#self.SpecialLeaf].JumpBack)
  end

  -- Add leaf that corresponds to break label
  self.SpecialLeaf[#self.SpecialLeaf].Break.CurrentPosition = self:CurrentSourcePosition()
  self:AddLeafToTail(self.SpecialLeaf[#self.SpecialLeaf].Break)

  -- Pop current continue leaf if required
  if self.CurrentContinueLeaf == self.SpecialLeaf[#self.SpecialLeaf].Continue then
    if self.SpecialLeaf[#self.SpecialLeaf-1] then
      self.CurrentContinueLeaf = self.SpecialLeaf[#self.SpecialLeaf-1].Continue
      self.CurrentBreakLeaf = self.SpecialLeaf[#self.SpecialLeaf-1].Break
    else
      self.CurrentContinueLeaf = nil
      self.CurrentBreakLeaf = nil
    end
  end

  -- Pop unused leaves
  self.SpecialLeaf[#self.SpecialLeaf] = nil

  -- Pop block type
  local blockType = self.BlockType[#self.BlockType]
  self.BlockType[#self.BlockType] = nil

  self.BlockDepth = self.BlockDepth - 1
  if self.BlockDepth == 0 then
    -- Update head leaf with new stack data
    self.HeadLeaf.Operands[1].Constant = -self.StackPointer
    if (self.StackPointer == 0) and
       (self.ParameterPointer == 0) and
       (not self.Settings.AlwaysEnterLeave) then self.HeadLeaf.Opcode = "DATA" end

    -- Create leaf for exiting local scope
    local leaveLeaf = self:NewLeaf()
    leaveLeaf.Opcode = "leave"
    if (self.StackPointer ~= 0) or
       (self.ParameterPointer ~= 0) or
       (self.Settings.AlwaysEnterLeave) then
      self:AddLeafToTail(leaveLeaf)
    end

    -- Create leaf for returning from call
    if blockType == "FUNCTION" then
      if not self.GenerateInlineFunction then
        local retLeaf = self:NewLeaf()
        retLeaf.Opcode = "ret"
        self:AddLeafToTail(retLeaf)
      end
    end

    -- Write down strings table
    for string,leaf in pairs(self.StringsTable) do
      self:AddLeafToTail(leaf)
    end
    self.StringsTable = nil

    -- Add local labels to lookup list
    for labelName,labelData in pairs(self.LocalLabels) do
      self.DebugInfo.Labels["local."..labelName] = { StackOffset = labelData.StackOffset }
    end

    self.LocalLabels = nil
    self.StackPointer = nil
    self.ParameterPointer = nil

    self.BlockType = nil
    self.SpecialLeaf = nil

    -- Zap all registers preserved inside the function
    self.BusyRegisters = nil

    -- Disable inlining
    if self.GenerateInlineFunction then
      self.Functions[self.GenerateInlineFunction].InlineCode = self.InlineFunctionCode
      self.GenerateInlineFunction = nil
      self.InlineFunctionCode = nil
    end

    -- Disable parent label
    self.CurrentParentLabel = nil
  end
end


--------------------------------------------------------------------------------
-- Parse ELSE clause
function HCOMP:ParseElse(blockIF,jumpOverCondLeaf)
  -- Add a jump over the else clause
  local jumpLeaf = self:NewLeaf()
  jumpLeaf.Opcode = "jmp"
  jumpLeaf.Operands[1] = {} -- will fill this later
  self:AddLeafToTail(jumpLeaf)

  -- Alter the conditional jump so it goes to else clause
  local jumpOverLabelLeaf = self:NewLeaf()
  local jumpOverLabel = self:GetTempLabel()
  jumpOverLabelLeaf.Opcode = "LABEL"
  jumpOverLabel.Type = "Pointer"
  jumpOverLabel.Leaf = jumpOverLabelLeaf
  jumpOverLabelLeaf.Label = jumpOverLabel
  self:AddLeafToTail(jumpOverLabelLeaf)

  if blockIF then
    -- Delete old label from global list and replace it with new one
    self.SpecialLeaf[#self.SpecialLeaf].ConditionalJumpOver.Operands[1] =
      { PointerToLabel = jumpOverLabel }

    -- End the block
    self:BlockEnd()
  else
    jumpOverCondLeaf.Operands[1] = { PointerToLabel = jumpOverLabel }
  end

  -- Enter the ELSE block
  local needBlock = self:MatchToken(self.TOKEN.LBRACKET)
  if needBlock then
    self:BlockStart("ELSE")
  end

  if needBlock then
    -- Alter the jump so it points to exit of the else clause
    jumpLeaf.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Break.Label }
  else
    -- Parse next statement if dont need a block
    self:Statement()

    -- Generate exit label
    local exitLabelLeaf = self:NewLeaf()
    local exitLabel = self:GetTempLabel()
    exitLabelLeaf.Opcode = "LABEL"
    exitLabel.Type = "Pointer"
    exitLabel.Leaf = exitLabelLeaf
    exitLabelLeaf.Label = exitLabel

    -- Add exit label and alter the jump
    self:AddLeafToTail(exitLabelLeaf)
    jumpLeaf.Operands[1] = { PointerToLabel = exitLabel }
  end
end


--------------------------------------------------------------------------------
function HCOMP:DeclareRegisterVariable()
  if self.BlockDepth > 0 then
    for reg=1,6 do
      if not self.BusyRegisters[reg] then
        self.BusyRegisters[reg] = true
        return reg
      end
    end
    self:Error("Out of free registers for declaring local variables")
  else
    self:Error("Unable to declare a register variable")
  end
end


--------------------------------------------------------------------------------
-- Compile a variable/function. Returns corresponding labels
function HCOMP:DefineVariable(isFunctionParam,isForwardDecl,isRegisterDecl) local TOKEN = self.TOKEN
  -- Get variable type
  self:ExpectToken(TOKEN.TYPE)
  local varType = self.TokenData
  local varSize = 1
  if varType == 5 then varSize = 4 end

  -- Variable labels list
  local labelsList = {}

  -- Parse all variables to define
  while true do
    -- Get pointer level (0, *, **, ***, etc)
    local pointerLevel = 0
    while self:MatchToken(TOKEN.TIMES) do pointerLevel = pointerLevel + 1 end

    -- Get variable name
    self:ExpectToken(TOKEN.IDENT)
    local varName = self.TokenData

    -- Try to read information about array size, stuff
    local arraySize
    while self:MatchToken(TOKEN.LSUBSCR) do -- varname[<arr size>]
      if self:MatchToken(TOKEN.RSUBSCR) then -- varname[]
        if isFunctionParam then -- just a pointer to an array
          pointerLevel = 1
        end
      else
        local c,v = self:ConstantExpression(true) -- need precise value here, no ptrs allowed
        if c then
          if not arraySize then arraySize = {} end
          arraySize[#arraySize+1] = v
        else
          self:Error("Array size must be constant")
        end

        self:ExpectToken(TOKEN.RSUBSCR)
      end
    end

    local bytesArraySize
    if arraySize then
      for k,v in pairs(arraySize) do
        bytesArraySize = (bytesArraySize or 0) + v*varSize
      end
    end

    if self:MatchToken(TOKEN.LPAREN) then -- Define function
      -- Create function entrypoint
      local label
      label = self:DefineLabel(varName)

      label.Type = "Pointer"
      label.Defined = true

      -- Make all further leaves parented to this label
      self.CurrentParentLabel = label

      -- Create label leaf
      label.Leaf = self:NewLeaf()
      label.Leaf.Opcode = "LABEL"
      label.Leaf.Label = label
      self:AddLeafToTail(label.Leaf) --isInlined

      -- Define a function
      local _,functionVariables = nil,{}

      self:BlockStart()
      if not self:MatchToken(TOKEN.RPAREN) then
        _,functionVariables = self:DefineVariable(true)
        self:ExpectToken(TOKEN.RPAREN)

        -- Add comments about function into assembly listing
        if self.Settings.GenerateComments then
          for i=1,#functionVariables do
            label.Leaf.Comment = (label.Leaf.Comment or "")..(functionVariables[i].Name)
            if i < #functionVariables then label.Leaf.Comment = label.Leaf.Comment.."," end
          end
        end
      end

      -- Forward declaration, mess up label name
      if isForwardDecl then
        local newName = label.Name.."@"
        for i=1,#functionVariables do
          newName = newName..functionVariables[i].Name..functionVariables[i].Type
          if i < #functionVariables then
            newName = newName.."_"
          end
        end
        self:RedefineLabel(label.Name,newName)
      end

      if self.Settings.GenerateComments then label.Leaf.Comment = varName.."("..(label.Leaf.Comment or "")..")" end
      self:ExpectToken(TOKEN.LBRACKET)
      return true,functionVariables,varName,varType,pointerLevel
    else -- Define variable
      -- Check if there's an initializer
      local initializerLeaves,initializerValues
      if self:MatchToken(TOKEN.EQUAL) then
        if not self.LocalLabels then -- Check rules for global init
          if self:MatchToken(TOKEN.LBRACKET) then -- Array initializer
            if not bytesArraySize then self:Error("Cannot initialize value: not an array") end

            initializerValue = {}
            while not self:MatchToken(TOKEN.RBRACKET) do
              local c,v = self:ConstantExpression(true)
              if not c
              then self:Error("Cannot have expressions in global initializers")
              else table.insert(initializerValue,v)
              end
              self:MatchToken(TOKEN.COMMA)
            end
          else -- Single initializer
            if bytesArraySize then self:Error("Cannot initialize value: is an array") end

            local c,v = self:ConstantExpression(true)
            if not c then
--              initializerLeaves = { self:Expression() }
              self:Error("Cannot have expressions in global initializers")
            else
              initializerValue = { v }
            end
          end
        else -- Local init always an expression
          if self:MatchToken(TOKEN.LBRACKET) then -- Array initializer
            if not bytesArraySize then self:Error("Cannot initialize value: not an array") end

            initializerLeaves = {}
            while not self:MatchToken(TOKEN.RBRACKET) do
              table.insert(initializerLeaves,self:Expression())
              self:MatchToken(TOKEN.COMMA)
            end

            if #initializerLeaves > 256 then
              self:Error("Too much local variable initializers")
            end
          else
            if bytesArraySize then self:Error("Cannot initialize value: is an array") end
            initializerLeaves = { self:Expression() }
          end
        end
      end

      -- Define a variable
      if self.LocalLabels then -- check if var is local
        local label = self:DefineLabel(varName,true)

        if isRegisterDecl then
          label.Type = "Register"
          label.Value = self:DeclareRegisterVariable()
        else
          label.Type = "Stack"
        end
        label.Defined = true
        if varType == 5 then label.ForceType = "vector" end

        -- If label has associated array size, mark it as an array
        if bytesArraySize then label.Array = bytesArraySize end

        if not isRegisterDecl then
          if not isFunctionParam then
            -- Add a new local variable (stack pointer increments)
            self.StackPointer = self.StackPointer - (bytesArraySize or varSize)
            label.StackOffset = self.StackPointer
          else
            -- Add a new function variable
            self.ParameterPointer = self.ParameterPointer + (bytesArraySize or varSize)
            label.StackOffset = self.ParameterPointer
          end
        end

        -- Initialize local variable
        if isRegisterDecl then
          if initializerLeaves then
            local movLeaf = self:NewLeaf()
            movLeaf.Opcode = "mov"
            movLeaf.Operands[1] = { Register = label.Value }
            movLeaf.Operands[2] = initializerLeaves[1]
            movLeaf.ExplictAssign = true
            self:AddLeafToTail(movLeaf)
          end
        else
          if initializerLeaves then
            for i=1,#initializerLeaves do -- FIXME: find a nicer way to initialize
              local movLeaf = self:NewLeaf()
              movLeaf.Opcode = "mov"
              movLeaf.Operands[1] = { Stack = label.StackOffset+i-1 }
              movLeaf.Operands[2] = initializerLeaves[i]
              movLeaf.ExplictAssign = true
              self:AddLeafToTail(movLeaf)
            end
            for i=#initializerLeaves+1,bytesArraySize or 1 do
              local movLeaf = self:NewLeaf()
              movLeaf.Opcode = "mov"
              movLeaf.Operands[1] = { Stack = label.StackOffset+i-1 }
              movLeaf.Operands[2] = { Constant = 0 }
              movLeaf.ExplictAssign = true
              self:AddLeafToTail(movLeaf)
            end
          end
        end

        table.insert(labelsList,{ Name = varName, Type = varType, PtrLevel = pointerLevel })
      else
        -- Define a new global variable
        local label = self:DefineLabel(varName)

        if isRegisterDecl then
          label.Type = "Register"
          label.Value = self:DeclareRegisterVariable()
        else
          label.Type = "Variable" --FIXME: "Pointer" for pointer vars
        end
        label.Defined = true
        if varType == 5 then label.ForceType = "vector" end

        -- If label has associated array size, mark it as an array
        if bytesArraySize then label.Array = bytesArraySize end

        label.Leaf = self:NewLeaf()
        label.Leaf.ParentLabel = self.CurrentParentLabel or label
        label.Leaf.Opcode = "DATA"
        if initializerValue then
          label.Leaf.Data = initializerValue
          label.Leaf.ZeroPadding = (bytesArraySize or varSize) - #initializerValue
        else
          label.Leaf.ZeroPadding = bytesArraySize or varSize
        end
        label.Leaf.Label = label
        self:AddLeafToTail(label.Leaf)

        table.insert(labelsList,{ Name = varName, Type = varType, PtrLevel = pointerLevel })
      end
    end

    if not self:MatchToken(TOKEN.COMMA) then
      return true,labelsList
    else
      if self:MatchToken(TOKEN.TYPE) then --int x, char y, float z
        varType = self.TokenData
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Compile a single statement
function HCOMP:Statement() local TOKEN = self.TOKEN
  -- Parse end of line colon
  if self:MatchToken(TOKEN.COLON) then return true end

  -- Check for EOF
  if self:MatchToken(TOKEN.EOF) then return false end

  -- Parse variable/function definition
  local exportSymbol = self:MatchToken(TOKEN.EXPORT)
  local inlineFunction = self:MatchToken(TOKEN.INLINE)
  local forwardFunction = self:MatchToken(TOKEN.FORWARD)
  local registerValue = self:MatchToken(TOKEN.LREGISTER)

  if self:PeekToken() == TOKEN.TYPE then
    if inlineFunction then
      self.GenerateInlineFunction = true
      self.InlineFunctionCode = {}
    end

    local isDefined,variableList,functionName,returnType,returnPtrLevel = self:DefineVariable(false,forwardFunction,registerValue)
    if isDefined then
      if functionName then
        self.Functions[functionName] = {
          FunctionName = functionName,
          Parameters = variableList,
          ReturnType = returnType,
          ReturnPtrLevel = returnPtrLevel,
        }
        if exportSymbol then
          self.ExportedSymbols[functionName] = self.Functions[functionName]
        end
        if inlineFunction then
          self.GenerateInlineFunction = functionName
        end
      else
        if exportSymbol then
          self:Error("Exporting variables not supported right now by the compiler")
        end
      end
    end

    if inlineFunction and (not functionName) then
      self:Error("Can only inline functions")
    end
    if forwardFunction and (not functionName) then
      self:Error("Can only forward-declare functions")
    end
    return isDefined
  end

  if inlineFunction or exportSymbol or forwardFunction or registerValue then
    self:Error("Function definition or symbol definition expected")
  end

  -- Parse preserve/zap
  if self:MatchToken(TOKEN.PRESERVE) or self:MatchToken(TOKEN.ZAP) then
    local tokenType = self.TokenType
    if self.BlockDepth > 0 then
      while self:MatchToken(TOKEN.REGISTER) do
        self.BusyRegisters[self.TokenData] = tokenType == TOKEN.PRESERVE
        self:MatchToken(TOKEN.COMMA)
      end
      self:MatchToken(TOKEN.COLON)
      return true
    else
      self:Error("Can only zap/preserve registers inside functions/local blocks")
    end
  end

  -- Parse assembly instruction
  if self:MatchToken(TOKEN.OPCODE) then return self:Opcode() end

  -- Parse VECTOR macro
  if self:MatchToken(TOKEN.VECTOR) then
    if self.BlockDepth > 0 then
      self:Warning("Defining a vector inside a function block might cause issues")
    end

    -- Vector type (VEC2F, etc)
    local vectorType = self.TokenData

    -- Vector name
    self:ExpectToken(TOKEN.IDENT)
    local vectorName = self.TokenData

    -- Create leaf and label for vector name
    local vectorNameLabelLeaf = self:NewLeaf()
    vectorNameLabelLeaf.Opcode = "LABEL"

    local vectorNameLabel = self:DefineLabel(vectorName)
    vectorNameLabel.Type = "Pointer"
    vectorNameLabel.Defined = true
    vectorNameLabel.Leaf = vectorNameLabelLeaf
    vectorNameLabel.DebugAsVector = #VectorSyntax[vectorType]
    vectorNameLabelLeaf.Label = vectorNameLabel
    self:AddLeafToTail(vectorNameLabelLeaf)

    -- Create leaves for all vector labels and their data
    local vectorLeaves = {}
    for index,labelNames in pairs(VectorSyntax[vectorType]) do
      -- Create leaves for labels
      for labelIndex,labelName in pairs(labelNames) do
        local vectorLabelLeaf = self:NewLeaf()
        vectorLabelLeaf.Opcode = "LABEL"

        local vectorLabel = self:GetLabel(vectorName.."."..labelName)
        vectorLabel.Type = "Pointer"
        vectorLabel.Defined = true
        vectorLabel.Leaf = vectorLabelLeaf
        vectorLabelLeaf.Label = vectorLabel
        self:AddLeafToTail(vectorLabelLeaf)
      end

      -- Create leaf for data
      vectorLeaves[index] = self:NewLeaf()
      vectorLeaves[index].Opcode = "DATA"
      vectorLeaves[index].Data = { 0 }
      self:AddLeafToTail(vectorLeaves[index])

      if vectorType == "COLOR" then
        vectorLeaves[index].Data = { 255 }
      end
    end

    -- Parse initialization
    self.MostLikelyConstantExpression = true
    if self:MatchToken(TOKEN.COMMA) then
      for index,labelNames in pairs(VectorSyntax[vectorType]) do
        local c,v,e = self:ConstantExpression(false)
        if c then
          vectorLeaves[index].Data[1] = v or e
        else
          self:Error("Vector initialization must be constant")
        end

        if (index == #VectorSyntax[vectorType]) and self:MatchToken(TOKEN.COMMA) then
          self:Error("Too much values for intialization")
        end
        if (index < #VectorSyntax[vectorType]) and (not self:MatchToken(TOKEN.COMMA)) then
          return true
        end
      end
    end
    self.MostLikelyConstantExpression = false
    return true
  end

  -- Parse DATA macro
  if self:MatchToken(TOKEN.DATA) then
    local jmpLeaf = self:NewLeaf()
    jmpLeaf.Opcode = "jmp"
    jmpLeaf.Operands[1] = {
      Constant = {{ Type = TOKEN.IDENT, Data = "_code", Position = self:CurrentSourcePosition() }}
    }
    self:AddLeafToTail(jmpLeaf)
    return true
  end

  -- Parse CODE macro
  if self:MatchToken(TOKEN.CODE) then
    local label = self:DefineLabel("_code")
    label.Type = "Pointer"

    label.Leaf = self:NewLeaf()
    label.Leaf.Opcode = "LABEL"
    label.Leaf.Label = label
    self:AddLeafToTail(label.Leaf)
    return true
  end

  -- Parse ORG macro
  if self:MatchToken(TOKEN.ORG) then
    -- org x
    local markerLeaf = self:NewLeaf()
    markerLeaf.Opcode = "MARKER"

    local c,v = self:ConstantExpression(true)
    if c then markerLeaf.SetWritePointer = v
    else self:Error("ORG offset must be constant") end

    self:AddLeafToTail(markerLeaf)
    return true
  end

  -- Parse DB macro
  if self:MatchToken(TOKEN.DB) then
    -- db 1,...
    self.IgnoreStringInExpression = true
    self.MostLikelyConstantExpression = true
    local dbLeaf = self:NewLeaf()
    dbLeaf.Opcode = "DATA"
    dbLeaf.Data = {}
    local c,v,e = self:ConstantExpression(false)
    while c or (self:PeekToken() == TOKEN.STRING) do
      -- Insert data into leaf
      if self:MatchToken(TOKEN.STRING) then
        table.insert(dbLeaf.Data,self.TokenData)
      else
        table.insert(dbLeaf.Data,v or e)
      end

      -- Only keep parsing if next token is comma
      if self:MatchToken(TOKEN.COMMA) then
        c,v,e = self:ConstantExpression(false)
      else
        c = false
      end
    end
    self.IgnoreStringInExpression = false
    self.MostLikelyConstantExpression = false

    self:AddLeafToTail(dbLeaf)
    return true
  end

  -- Parse STRING macro
  if self:MatchToken(TOKEN.STRALLOC) then
    -- string name,1,...
    self:ExpectToken(TOKEN.IDENT)

    -- Create leaf and label for vector name
    local stringNameLabelLeaf = self:NewLeaf()
    stringNameLabelLeaf.Opcode = "LABEL"

    local stringNameLabel = self:DefineLabel(self.TokenData)
    stringNameLabel.Type = "Pointer"
    stringNameLabel.Defined = true
    stringNameLabel.Leaf = stringNameLabelLeaf
    stringNameLabelLeaf.Label = stringNameLabel
    self:AddLeafToTail(stringNameLabelLeaf)
    self:ExpectToken(TOKEN.COMMA)

    self.IgnoreStringInExpression = true
    self.MostLikelyConstantExpression = true
    local stringLeaf = self:NewLeaf()
    stringLeaf.Opcode = "DATA"
    stringLeaf.Data = {}
    local c,v,e = self:ConstantExpression(false)
    while c or (self:PeekToken() == TOKEN.STRING) do
      -- Insert data into leaf
      if self:MatchToken(TOKEN.STRING) then
        table.insert(stringLeaf.Data,self.TokenData)
      else
        table.insert(stringLeaf.Data,v or e)
      end

      -- Only keep parsing if next token is comma
      if self:MatchToken(TOKEN.COMMA) then
        c,v,e = self:ConstantExpression(false)
      else
        c = false
      end
    end
    table.insert(stringLeaf.Data,0)
    self.IgnoreStringInExpression = false
    self.MostLikelyConstantExpression = false

    self:AddLeafToTail(stringLeaf)
    return true
  end

  -- Parse DEFINE macro
  if self:MatchToken(TOKEN.DEFINE) then
    -- define label,value
    self:ExpectToken(TOKEN.IDENT)
    local defineLabel = self:DefineLabel(self.TokenData)
    defineLabel.Type = "Pointer"
    defineLabel.Defined = true

    self:ExpectToken(TOKEN.COMMA)

    self.MostLikelyConstantExpression = true
    local c,v,e = self:ConstantExpression(false)
    if c then
      if v then
        defineLabel.Value = v
      else
        defineLabel.Expression = e
      end
    else
      self:Error("Define value must be constant")
    end
    self.MostLikelyConstantExpression = false

    return true
  end

  -- Parse ALLOC macro
  if self:MatchToken(TOKEN.ALLOC) then
    -- alloc label,size,value
    -- alloc label,value
    -- alloc label
    -- alloc size
    local allocLeaf = self:NewLeaf()
    local allocLabel,allocSize,allocValue = nil,1,0
    local expectSize = false
    allocLeaf.Opcode = "DATA"

    -- Add a label to this alloc
    if self:MatchToken(TOKEN.IDENT) then
      allocLabel = self:DefineLabel(self.TokenData)
      allocLabel.Type = "Pointer"
      allocLabel.Defined = true
      allocLabel.DebugAsVariable = true

      allocLabel.Leaf = allocLeaf
      allocLeaf.Label = allocLabel

      if self:MatchToken(TOKEN.COMMA) then expectSize = true end
    end

    -- Read size
    self.MostLikelyConstantExpression = true
    if (not allocLabel) or (expectSize) then
      local c,v = self:ConstantExpression(true) -- need precise value here, no ptrs allowed
      if c then allocSize = v
      else self:Error("Alloc size must be constant") end
    end

    if allocLabel and expectSize then
      if self:MatchToken(TOKEN.COMMA) then
        local c,v = self:ConstantExpression(true) -- need precise value here, no ptrs allowed
        if c then allocValue = v
        else self:Error("Alloc value must be constant") end
      else
        allocValue = allocSize
        allocSize = 1
      end
    end
    self.MostLikelyConstantExpression = false

    -- Initialize alloc
    allocLeaf.ZeroPadding = allocSize
    self:AddLeafToTail(allocLeaf)
    return true
  end





  -- Parse RETURN
  if self:MatchToken(TOKEN.RETURN) and self.HeadLeaf then
    if not self:MatchToken(TOKEN.COLON) then
      local returnExpression = self:Expression()
      local returnLeaf = self:NewLeaf()
      returnLeaf.Opcode = "mov"
      returnLeaf.Operands[1] = { Register = 1 }
      returnLeaf.Operands[2] = returnExpression
      returnLeaf.ExplictAssign = true
      self:AddLeafToTail(returnLeaf)
    end

    -- Check if this is the last return in the function
--    self:MatchToken(TOKEN.COLON)
--    if self:MatchToken(TOKEN.RBRACKET) then
--      if self.BlockDepth > 0 then
--        self:BlockEnd()
--        return true
--      else
--        self:Error("Unexpected bracket")
--      end
--    end


    if not self.GenerateInlineFunction then
      -- Create leaf for exiting local scope
      local leaveLeaf = self:NewLeaf()
      leaveLeaf.Opcode = "leave"
      if (self.StackPointer ~= 0) or
         (self.ParameterPointer ~= 0) or
         (self.Settings.AlwaysEnterLeave) then
        self:AddLeafToTail(leaveLeaf)
      end

      -- Create leaf for returning from call
      local retLeaf = self:NewLeaf()
      retLeaf.Opcode = "ret"
      self:AddLeafToTail(retLeaf)
    end

    return true
  end

  -- Parse IF syntax
  if self:MatchToken(TOKEN.IF) then
    -- Parse condition
    self:ExpectToken(TOKEN.LPAREN)
    local firstToken = self.CurrentToken
    self:SaveParserState()
    local conditionLeaf = self:Expression()
    local conditionText = "if ("..self:PrintTokens(self:GetSavedTokens(firstToken))
    self:ExpectToken(TOKEN.RPAREN)

    -- Enter the IF block
    local needBlock = self:MatchToken(TOKEN.LBRACKET)
    if needBlock then
      self:BlockStart("IF")
    end

    -- Calculate condition
    local cmpLeaf = self:NewLeaf()
    cmpLeaf.Opcode = "cmp"
    cmpLeaf.Operands[1] = { Constant = 0 }
    cmpLeaf.Operands[2] = conditionLeaf
    cmpLeaf.Comment = conditionText
    self:AddLeafToTail(cmpLeaf)

    if not needBlock then
      -- Generate conditional jump over the block
      local jumpOverLabelLeaf = self:NewLeaf()
      local jumpOverLabel = self:GetTempLabel()
      jumpOverLabelLeaf.Opcode = "LABEL"
      jumpOverLabel.Type = "Pointer"
      jumpOverLabel.Leaf = jumpOverLabelLeaf
      jumpOverLabelLeaf.Label = jumpOverLabel

      local jumpLeaf = self:NewLeaf()
      jumpLeaf.Opcode = "jge"
      jumpLeaf.Operands[1] = { PointerToLabel = jumpOverLabel }
      self:AddLeafToTail(jumpLeaf)

      -- Parse next statement if dont need a block
      self:Statement()

      -- Add exit label
      self:AddLeafToTail(jumpOverLabelLeaf)

      -- Check for out-of-block ELSE
      if self:MatchToken(TOKEN.ELSE) then
        self:ParseElse(false,jumpLeaf)
      end
    else
      -- Generate conditional jump over the block
      local jumpLeaf = self:NewLeaf()
      jumpLeaf.Opcode = "jge"
      jumpLeaf.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Break.Label }
      self:AddLeafToTail(jumpLeaf)

      self.SpecialLeaf[#self.SpecialLeaf].ConditionalJumpOver = jumpLeaf
    end

    return true
  end

  -- Parse WHILE syntax
  if self:MatchToken(TOKEN.WHILE) then
    local returnLabel

    -- Parse condition
    self:ExpectToken(TOKEN.LPAREN)
    local firstToken = self.CurrentToken
    self:SaveParserState()
    local conditionLeaf = self:Expression()
    local conditionText = "if ("..self:PrintTokens(self:GetSavedTokens(firstToken))
    self:ExpectToken(TOKEN.RPAREN)

    -- Enter the WHILE block
    local needBlock = self:MatchToken(TOKEN.LBRACKET)
    if needBlock then
      self:BlockStart("WHILE")
    end

    if not needBlock then
      -- Generate return label
      local returnLabelLeaf = self:NewLeaf()
      returnLabel = self:GetTempLabel()
      returnLabelLeaf.Opcode = "LABEL"
      returnLabel.Type = "Pointer"
      returnLabel.Leaf = returnLabelLeaf
      returnLabelLeaf.Label = returnLabel
      self:AddLeafToTail(returnLabelLeaf)
    end

    -- Calculate condition
    local cmpLeaf = self:NewLeaf()
    cmpLeaf.Opcode = "cmp"
    cmpLeaf.Operands[1] = { Constant = 0 }
    cmpLeaf.Operands[2] = conditionLeaf
    cmpLeaf.Comment = conditionText
    self:AddLeafToTail(cmpLeaf)

    if not needBlock then
      -- Generate conditional jump over the block
      local jumpOverLabelLeaf = self:NewLeaf()
      local jumpOverLabel = self:GetTempLabel()
      jumpOverLabelLeaf.Opcode = "LABEL"
      jumpOverLabel.Type = "Pointer"
      jumpOverLabel.Leaf = jumpOverLabelLeaf
      jumpOverLabelLeaf.Label = jumpOverLabel

      local jumpOverLeaf = self:NewLeaf()
      jumpOverLeaf.Opcode = "jz"
      jumpOverLeaf.Operands[1] = { PointerToLabel = jumpOverLabel }
      self:AddLeafToTail(jumpOverLeaf)

      -- Parse next statement if dont need a block
      self:Statement()

      -- Generate the jump back leaf
      local jumpBackLeaf = self:NewLeaf()
      jumpBackLeaf.Opcode = "jmp"
      jumpBackLeaf.Operands[1] = { PointerToLabel = returnLabel }
      self:AddLeafToTail(jumpBackLeaf)

      -- Add exit label
      self:AddLeafToTail(jumpOverLabelLeaf)
    else
      -- Generate conditional jump over the block
      local jumpOverLeaf = self:NewLeaf()
      jumpOverLeaf.Opcode = "jz"
      jumpOverLeaf.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Break.Label }
      self:AddLeafToTail(jumpOverLeaf)

      -- Set the jump back leaf
      self.SpecialLeaf[#self.SpecialLeaf].JumpBack.Opcode = "jmp"
      self.SpecialLeaf[#self.SpecialLeaf].JumpBack.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Continue.Label }
    end

    return true
  end

  -- Parse FOR syntax
  if self:MatchToken(TOKEN.FOR) then
    local returnLabel

    -- Parse syntax
    self:ExpectToken(TOKEN.LPAREN)
    local initLeaf = self:Expression()
    initLeaf.Comment = "init loop"
    self:ExpectToken(TOKEN.COLON)
    local conditionLeaf = self:Expression()
    conditionLeaf.Comment = "condition"
    self:ExpectToken(TOKEN.COLON)
    local stepLeaf = self:Expression()
    stepLeaf.Comment = "loop step"
    self:ExpectToken(TOKEN.RPAREN)

    self:AddLeafToTail(initLeaf)

    -- Enter the FOR block
    local needBlock = self:MatchToken(TOKEN.LBRACKET)
    if needBlock then
      self:BlockStart("FOR")
    end

    if not needBlock then
      -- Generate return label
      local returnLabelLeaf = self:NewLeaf()
      returnLabel = self:GetTempLabel()
      returnLabelLeaf.Opcode = "LABEL"
      returnLabel.Type = "Pointer"
      returnLabel.Leaf = returnLabelLeaf
      returnLabelLeaf.Label = returnLabel
      self:AddLeafToTail(returnLabelLeaf)
    end

    -- Calculate condition
    local cmpLeaf = self:NewLeaf()
    cmpLeaf.Opcode = "cmp"
    cmpLeaf.Operands[1] = { Constant = 0 }
    cmpLeaf.Operands[2] = conditionLeaf
    self:AddLeafToTail(cmpLeaf)

    if not needBlock then
      -- Generate conditional jump over the block
      local jumpOverLabelLeaf = self:NewLeaf()
      local jumpOverLabel = self:GetTempLabel()
      jumpOverLabelLeaf.Opcode = "LABEL"
      jumpOverLabel.Type = "Pointer"
      jumpOverLabel.Leaf = jumpOverLabelLeaf
      jumpOverLabelLeaf.Label = jumpOverLabel

      local jumpOverLeaf = self:NewLeaf()
      jumpOverLeaf.Opcode = "jz"
      jumpOverLeaf.Operands[1] = { PointerToLabel = jumpOverLabel }
      self:AddLeafToTail(jumpOverLeaf)

      -- Parse next statement if dont need a block
      self:Statement()

      -- Generate the jump back leaf
      local jumpBackLeaf = self:NewLeaf()
      jumpBackLeaf.Opcode = "jmp"
      jumpBackLeaf.Operands[1] = { PointerToLabel = returnLabel }
      self:AddLeafToTail(stepLeaf)
      self:AddLeafToTail(jumpBackLeaf)

      -- Add exit label
      self:AddLeafToTail(jumpOverLabelLeaf)
    else
      -- Generate conditional jump over the block
      local jumpOverLeaf = self:NewLeaf()
      jumpOverLeaf.Opcode = "jz"
      jumpOverLeaf.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Break.Label }
      self:AddLeafToTail(jumpOverLeaf)

      -- Set the jump back leaf
      self.SpecialLeaf[#self.SpecialLeaf].JumpBack.Opcode = "jmp"
      self.SpecialLeaf[#self.SpecialLeaf].JumpBack.Operands[1] = { PointerToLabel = self.SpecialLeaf[#self.SpecialLeaf].Continue.Label }
      self.SpecialLeaf[#self.SpecialLeaf].JumpBack.PreviousLeaf = stepLeaf
    end

    return true
  end

  -- Parse CONTINUE
  if self:MatchToken(TOKEN.CONTINUE) then
    if (self.BlockDepth > 0) and (self.CurrentContinueLeaf) then
      local jumpBackLeaf = self:NewLeaf()
      jumpBackLeaf.Opcode = "jmp"
      jumpBackLeaf.Operands[1] = { PointerToLabel = self.CurrentContinueLeaf.Label }
      self:AddLeafToTail(jumpBackLeaf)
      return true
    else
      self:Error("Nowhere to continue here")
    end
  end

  -- Parse BREAK
  if self:MatchToken(TOKEN.BREAK) then
    if (self.BlockDepth > 0) and (self.CurrentBreakLeaf) then
      local jumpLeaf = self:NewLeaf()
      jumpLeaf.Opcode = "jmp"
      jumpLeaf.Operands[1] = { PointerToLabel = self.CurrentBreakLeaf.Label }
      self:AddLeafToTail(jumpLeaf)
      return true
    else
      self:Error("Nowhere to break from here")
    end
  end

  -- Parse GOTO
  if self:MatchToken(TOKEN.GOTO) then
    local gotoExpression = self:Expression()

    local jumpLeaf = self:NewLeaf()
    jumpLeaf.Opcode = "jmp"
    jumpLeaf.Operands[1] = gotoExpression
    self:AddLeafToTail(jumpLeaf)
    return true
  end

  -- Parse block open bracket
  if self:MatchToken(TOKEN.LBRACKET) then
    self:BlockStart("LBLOCK")
    return true
  end

  -- Parse block close bracket
  if self:MatchToken(TOKEN.RBRACKET) then
    if self.BlockDepth > 0 then
      local blockType = self.BlockType[#self.BlockType]
      if (blockType == "IF") and self:MatchToken(TOKEN.ELSE) then -- Add ELSE block
        self:ParseElse(true)
      else
        self:BlockEnd()
      end
      return true
    else
      self:Error("Unexpected bracket")
    end
  end

  -- Parse possible label definition
  local firstToken = self.CurrentToken
  self:SaveParserState()

  if self:MatchToken(TOKEN.IDENT) then
    if (self:PeekToken() == TOKEN.COMMA) or (self:PeekToken() == TOKEN.DCOLON) then
      -- Label definition for sure
      while true do
        local label = self:DefineLabel(self.TokenData)
        label.Type = "Pointer"
        label.Defined = true

        label.Leaf = self:NewLeaf()
        label.Leaf.Opcode = "LABEL"
        label.Leaf.Label = label
        self:AddLeafToTail(label.Leaf)

        self:MatchToken(TOKEN.COMMA)
        if not self:MatchToken(TOKEN.IDENT) then break end
      end
      self:ExpectToken(TOKEN.DCOLON)
      self:MatchToken(TOKEN.COLON)
      return true
    else
      self:RestoreParserState()
    end
  end

  -- If nothing else, must be some kind of an expression
  local expressionLeaf = self:Expression()
  self:AddLeafToTail(expressionLeaf)

  -- Add expression to leaf comment
  if self.Settings.GenerateComments then
    expressionLeaf.Comment = self:PrintTokens(self:GetSavedTokens(firstToken))
  end

  -- Skip a colon
  self:MatchToken(TOKEN.COLON)
  return true
end
