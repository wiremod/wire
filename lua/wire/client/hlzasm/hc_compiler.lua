--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- This is a high-level assembly language compiler, based on ZASM2 and C syntax.
--
-- I tried to make the compiler as understandable as possible, but you will need
-- to read the source files in this order to understand internal workings of
-- the compiler. Each of these files performs own task, and is independant of others.
--
--    hc_opcodes: lists all opcodes that are recognized by the compiler
--   hc_compiler: compiler initialization
--                error reporting
--                parser functions
-- hc_preprocess: preprocessor macro parsing
--  hc_tokenizer: turns source code into tokens
--   hc_codetree: unwraps code tree into generated code
--     hc_output: resolves labels and generates
--     hc_syntax: parses language syntax
-- hc_expression: parses expressions
--   hc_optimize: optimizes the resulting code
--------------------------------------------------------------------------------
HCOMP = {}




--------------------------------------------------------------------------------
-- Files required by the compiler
include("wire/client/hlzasm/hc_opcodes.lua")
include("wire/client/hlzasm/hc_expression.lua")
include("wire/client/hlzasm/hc_preprocess.lua")
include("wire/client/hlzasm/hc_syntax.lua")
include("wire/client/hlzasm/hc_codetree.lua")
include("wire/client/hlzasm/hc_optimize.lua")
include("wire/client/hlzasm/hc_output.lua")
include("wire/client/hlzasm/hc_tokenizer.lua")





--------------------------------------------------------------------------------
-- Formats the prefix according to one of the three possible ways to raise error
function HCOMP:formatPrefix(param1,param2,param3)
  local line,col,file
  if param2 then -- Specify line/col/file directly
    line = param1
    col = param2
    file = param3
  elseif param1 then -- Specify parameter by block
    if param1.CurrentPosition then
      line = param1.CurrentPosition.Line
      col = param1.CurrentPosition.Col
      file = param1.CurrentPosition.File
    end
  else -- Get position from parser
    local currentPosition = self:CurrentSourcePosition()
    line = currentPosition.Line
    col = currentPosition.Col
    file = currentPosition.File
  end

  if (not file) or (not line) or (not col) then
    error("[global 1:1] Internal error 048")
  end

  -- Format prefix for reporting warnings/errors
  return "["..file.." "..line..":"..col.."]",file,line,col
end




-- Display an error message. There are three ways to call it:
--
-- Error(msg)
--   Raise an error when parsing code
-- Error(msg,block)
--   Raise an error when generating or outputting block
-- Error(msg,line,col,filename)
--   Raise an error when preprocessing
function HCOMP:Error(msg,param1,param2,param3)
  local prefix,file,line,col = self:formatPrefix(param1,param2,param3)
  self.ErrorMessage = prefix..": "..msg
  self.ErrorPosition = { Line = line, Col = col, File = file }
  error(self.ErrorMessage)
end




-- Display a warning message
--
-- Same rules for calling as for Error()
function HCOMP:Warning(msg,param1,param2,param3)
  print(self:formatPrefix(param1,param2,param3)..": Warning: "..msg)
end




-- Print a line to specific file
function HCOMP:PrintLine(file,...)
  if self.Settings.OutputToFile then
    local ffile = self.Settings[file] or file
    local outputString = ""
    local argc = select("#",...)
    for i=1,argc do
      if i < argc then
        outputString = outputString..select(i,...).."\t"
      else
        outputString = outputString..select(i,...)
      end
    end
    outputString = outputString.."\n"
    self.OutputText[ffile] = (self.OutputText[ffile] or "") .. outputString

    -- Forced garbage collection for very large output
    if #self.OutputText[ffile] > 96000 then
      collectgarbage("step")
    end
  else
    print(...)
  end
end




--------------------------------------------------------------------------------
-- Emit a code byte to the output stream
function HCOMP:WriteByte(byte,block)
  if self.WriteByteCallback then
    self.WriteByteCallback(self.WriteByteCaller,self.WritePointer,byte)
  end

  if not byte then error("[global 1:1] Internal error 108") end

  -- Remember debug data
  if block.CurrentPosition then
    local currentPositionKey = block.CurrentPosition.Line..":"..block.CurrentPosition.File
    self.DebugInfo.PositionByPointer[self.WritePointer] = block.CurrentPosition
    if self.DebugInfo.PointersByLine[currentPositionKey] then
      self.DebugInfo.PointersByLine[currentPositionKey][2] = self.WritePointer
    else
      self.DebugInfo.PointersByLine[currentPositionKey] = { self.WritePointer, self.WritePointer }
    end
  else
    self.DebugInfo.PositionByPointer[self.WritePointer] = { Line = 0, Col = 0, File = "undefined" }
  end

  -- Output binary listing
  if self.Settings.OutputBinaryListing then
    if not self.CurrentBinaryListingLine then
      self.CurrentBinaryListingLine = "db "
    end
    self.CurrentBinaryListingLine = self.CurrentBinaryListingLine .. byte .. ","
    if #self.CurrentBinaryListingLine > 60 then
      self:PrintLine("binlist",string.sub(self.CurrentBinaryListingLine,1,#self.CurrentBinaryListingLine-1))
      self.CurrentBinaryListingLine = nil
    end
  end
  self.WritePointer = self.WritePointer + 1
end




--------------------------------------------------------------------------------
-- Start compiling the sourcecode. File name will define working directory
--
-- Will call writeByteCallback(writeByteCaller,Address,Value) to output a byte
function HCOMP:StartCompile(sourceCode,fileName,writeByteCallback,writeByteCaller)
  -- Remember callbacks for the writing functions
  self.WriteByteCallback = writeByteCallback
  self.WriteByteCaller = writeByteCaller

  -- Set the working directory
  self.FileName = string.sub(fileName,string.find(fileName,"\\$") or 1)
  if string.GetPathFromFilename then
    local filePath = string.GetPathFromFilename(fileName)
    self.WorkingDir = ".\\"..string.sub(filePath,(string.find(filePath,"Chip") or -4)+5)
  else
    self.WorkingDir = ".\\"
  end

  -- Initialize compiler settings
  self.Settings = {}

  -- Internal settings
  self.Settings.CurrentLanguage = "HLZASM" -- C, ZASM2, PASCAL
  self.Settings.CurrentPlatform = "CPU"
  self.Settings.MagicValue = -700500 -- This magic value will appear in invalid output code
  self.Settings.OptimizeLevel = 0 -- 0: none, 1: low, 2: high; high optimize level might mangle code for perfomance

  -- Verbosity settings
  self.Settings.OutputCodeTree = false -- Output code tree for the source
  self.Settings.OutputResolveListing = false -- Output code listing for resolve stage
  self.Settings.OutputFinalListing = false -- Output code listing for final stage
  self.Settings.OutputTokenListing = false -- Output tokenized code
  self.Settings.OutputBinaryListing = false -- Output final binary as listing
  self.Settings.OutputDebugListing = false -- Output debug data as listing
  self.Settings.OutputToFile = false -- Output listings to files instead of console
  self.Settings.OutputOffsetsInListing = true -- Output binary offsets in listings
  self.Settings.OutputLabelsInListing = true -- Output labels in final listing
  self.Settings.GenerateComments = true -- Generates comments in output listing

  -- Code generation settings
  self.Settings.FixedSizeOutput = false -- Output fixed-size instructions
  self.Settings.SeparateDataSegment = false -- Puts all variables into separate data segment
  self.Settings.GenerateLibrary = false -- Generate precompiled library
  self.Settings.AlwaysEnterLeave = false -- Always generate the enter/leave blocks
  self.Settings.NoUnreferencedLeaves = true -- Dont generate functions, variables that are not referenced
  self.Settings.DataSegmentOffset = 0 -- Data segment offset for separate data segment

  -- Search paths
  self.SearchPaths = {
    "lib",
    "inc"
  }

  -- Prepare parser
  self.Stage = 1
  self.Tokens = {}
  self.Code = {{ Text = sourceCode, Line = 1, Col = 1, File = self.FileName }}

  -- Structs
  self.Structs = {}
  self.StructSize = {}

  -- Prepare debug information
  self.DebugInfo = {}
  self.DebugInfo.Labels = {}
  self.DebugInfo.PositionByPointer = {}
  self.DebugInfo.PointersByLine = {}

  -- Exported function list (library generation)
  self.ExportedSymbols = {}
  self.LabelLookup = {}
  self.LabelLookupCounter = 0

  -- All functions defined so far
  self.Functions = {}

  -- All macros defined so far
  self.Defines = {}
  self.Defines["__LINE__"] = 0
  self.Defines["__FILE__"] = ""
  self.IFDEFLevel = {}

  -- Output text
  self.OutputText = {}
end




--------------------------------------------------------------------------------
-- Call this until the function returns false (it returns false when there
-- is nothing more to do)
function HCOMP:Compile()
  return self:UnprotectedCompile()
--  local status,result = pcall(self.UnprotectedCompile,self)
--  if not status then
--    print("ERROR: "..result)
--  else
--    return result
--  end
end




-- Unprotected function that does the actual compiling
function HCOMP:UnprotectedCompile()
  if self.Stage == 1 then
    -- Tokenize stage
    --
    -- At this stage sourcecode is converted to list of tokens

    local stageResult = self:Tokenize()
    if not stageResult then
      -- Output tokens if required
      if self.Settings.OutputTokenListing then
        for k,v in pairs(self.Tokens) do
          self:PrintLine("toklist",k,self.TOKEN_NAME[v.Type],v.Data,v.Position.File.." "..v.Position.Line..":"..v.Position.Col)
        end
      end

      -- Clean up preprocessor variables
      self.Code = nil
      self.SourceCode = nil
      self.Defines = nil

      -- Go to the first token
      self.CurrentToken = 1

      -- Sest up variables for code parsing
      self.CodeTree = {} -- Code tree that will be built (see hc_codetree.lua)
      self.GlobalLabels = {} -- Table of globally defined labels
      self.LabelCounter = 0 -- Counter for internal labels (for IF, CASE, etc)
      self.UserRegisters = {} -- Registers used by user in global scope
      self.BlockDepth = 0 -- Nesting depth of the {..} block
      self.GlobalStringTable = {} -- Global table for string leaves

      -- Reset parsing the blocks
      self.SpecialLeaf = nil
      self.LocalLabels = nil
      self.StackPointer = nil
      self.TokenData = nil
      self.StringsTable = nil
      self.ParameterPointer = nil
      self.BlockType = nil

      -- Set special labels
      self:SetSpecialLabels()

      self.Stage = 2
    end
    return true
  elseif self.Stage == 2 then
    -- Parse code stage
    --
    -- At this stage code is parsed, and code tree is built

    local stageResult = self:Statement()
    if not stageResult then
      -- Index for code tree leaves
      self.CurrentLeafIndex = 1

      -- Create storage for generated code
      self.GeneratedCode = {}
      self.Stage = 3
    end
    return true
  elseif self.Stage == 3 then
    -- Generate stage
    --
    -- This will generate code based on the code tree that was created by the
    -- parser

    local stageResult = false
    if self.CodeTree[self.CurrentLeafIndex] and self:StageGenerateLeaf(self.CodeTree[self.CurrentLeafIndex]) then
      stageResult = true
    end

    if not stageResult then
      self.CurrentLeafIndex = self.CurrentLeafIndex + 1
      if not self.CodeTree[self.CurrentLeafIndex] then
        self.Stage = 4
      end
    end
    return true
  elseif self.Stage == 4 then
    -- Code optimize stage
    --
    -- At this stage code is optimized for the known patterns

    local stageResult

    -- Do not perform this stage if optimization is set to 0
    if self.Settings.OptimizeLevel == 0 then
      stageResult = false
    else
      stageResult = self:OptimizeCode()
    end
    if not stageResult then
      -- Initialize iteration through generated code
      self.CurrentBlockIndex = 1
      self.Stage = 5

      -- Set write pointers
      self.PointerOffset = 0
      self.WritePointer = 0
      self.DataPointer = 0
    end
    return true
  elseif self.Stage == 5 then
    -- Resolve stage
    --
    -- This will attempt to output the code without actually writing it.
    -- All the labels will be resolved at this stage

    local stageResult = false
    if self.GeneratedCode[self.CurrentBlockIndex] and self:Resolve(self.GeneratedCode[self.CurrentBlockIndex]) then
      stageResult = true
    end
    if not stageResult then
      self.CurrentBlockIndex = self.CurrentBlockIndex + 1
      if not self.GeneratedCode[self.CurrentBlockIndex] then
        -- Set special labels
        self:SetSpecialLabels()

        -- Initialize iteration through generated code
        self.CurrentBlockIndex = 1
        self.Stage = 6

        -- Set write pointers
        self.PointerOffset = 0
        self.WritePointer = 0
        self.DataPointer = 0
      end
    end

    return true
  elseif self.Stage == 6 then
    -- Output stage
    --
    -- The code will be output as binary at this stage

    local stageResult = false
    if self.GeneratedCode[self.CurrentBlockIndex] and self:Output(self.GeneratedCode[self.CurrentBlockIndex]) then
      stageResult = true
    end
    if not stageResult then
      self.CurrentBlockIndex = self.CurrentBlockIndex + 1
      if not self.GeneratedCode[self.CurrentBlockIndex] then
        self.Stage = 7

        -- Generate labels for the debugger
        for labelName,labelData in pairs(self.GlobalLabels) do
          if string.sub(labelName,1,2) ~= "__" then
            if labelData.DebugAsVector then
              self.DebugInfo.Labels[string.upper(labelData.Name)] = {
                Vector = labelData.Value,
                Size = labelData.DebugAsVector -- vector size
              }
            elseif (labelData.Type == "Variable") or (labelData.DebugAsVariable) then
              self.DebugInfo.Labels[string.upper(labelData.Name)] = {
                Offset = labelData.Value
              }
            elseif labelData.Type == "Pointer" then
              self.DebugInfo.Labels[string.upper(labelData.Name)] = {
                Pointer = labelData.Value
              }
            end
          end
        end

        -- Write binary output
        if self.Settings.OutputBinaryListing then
          if self.CurrentBinaryListingLine then
            self:PrintLine("binlist",string.sub(self.CurrentBinaryListingLine,1,#self.CurrentBinaryListingLine-1))
            self.CurrentBinaryListingLine = nil
          end
        end

        -- Write the debug data
        if self.Settings.OutputDebugListing then
          self:PrintLine("dbglist","Labels:")
          self:PrintLine("dbglist","Name","Offset","Type")
          for k,v in pairs(self.DebugInfo.Labels) do
                if v.Offset      then self:PrintLine("dbglist",k,v.Offset,"MEMORY")
            elseif v.Pointer     then self:PrintLine("dbglist",k,v.Pointer,"POINTER")
            elseif v.StackOffset then self:PrintLine("dbglist",k,v.StackOffset,"STACK")
            end
          end

          self:PrintLine("dbglist","Position by pointer:")
          self:PrintLine("dbglist","Pointer","Line","Column","File")
          for k,v in pairs(self.DebugInfo.PositionByPointer) do
            self:PrintLine("dbglist",k,v.Line,v.Col,v.File)
          end

          self:PrintLine("dbglist","Pointers by line:")
          self:PrintLine("dbglist","Line","Start","End")
          for k,v in pairs(self.DebugInfo.PointersByLine) do
            self:PrintLine("dbglist",k,v[1],v[2])
          end
        end

        -- Write header file for library
        if self.Settings.GenerateLibrary then
          if self.DBString then
            self:PrintLine("lib",self.DBString)
            self.DBString = nil
          end

          self:PrintLine("lib","")

          for symName,symData in pairs(self.ExportedSymbols) do
            local printText = "#pragma export "
            if symData.FunctionName then
              printText = printText .. string.lower(self.TOKEN_TEXT["TYPE"][2][symData.ReturnType])
              printText = printText .. string.rep("*",symData.ReturnPtrLevel)

              printText = printText .. " " .. symData.FunctionName .. "("
              for varIdx,varData in pairs(symData.Parameters) do
                printText = printText .. string.lower(self.TOKEN_TEXT["TYPE"][2][varData.Type])
                printText = printText .. string.rep("*",varData.PtrLevel)
                printText = printText .. " " .. varData.Name
                if varIdx < #symData.Parameters then
                  printText = printText .. ", "
                end
              end
              printText = printText .. ")"
            end
            self:PrintLine("lib",printText)
          end
        end

        -- Clean up
        self.LabelLookup = nil
        self.LabelLookupCounter = nil

        -- Close all output files
        for k,v in pairs(self.OutputText) do self:SaveFile(self.WorkingDir..k..".txt",v) end
      end
    end

    return true
  else
    return false
  end
end




--------------------------------------------------------------------------------
-- Get label (local or global one). Second result returns true if label is new
-- Third result returns if label was referenced before
function HCOMP:GetLabel(name,declareLocalVariable)
  local trueName = string.upper(name)

  -- Should we treat unknown variables as local label definition
  -- This assumes self.LocalLabel is defined at this point
  if declareLocalVariable then
    if self.LocalLabels[trueName] then
      return self.LocalLabels[trueName],not self.LocalLabels[trueName].Defined
    else
      self.LocalLabels[trueName] = {
        Type = "Unknown",
        Name = name,
        Position = self:CurrentSourcePosition(),
      }
      return self.LocalLabels[trueName],true
    end
  else
    -- If in local mode then try to resolve label amongst the local ones first
    if self.LocalLabels and self.LocalLabels[trueName] then
      return self.LocalLabels[trueName],not self.LocalLabels[trueName].Defined
    elseif self.GlobalLabels[trueName] then
      local wasReferenced = self.GlobalLabels[trueName].Referenced
      self.GlobalLabels[trueName].Referenced = true
      return self.GlobalLabels[trueName],not self.GlobalLabels[trueName].Defined,wasReferenced
    else
      self.GlobalLabels[trueName] = {
        Type = "Unknown",
        Name = name,
        Position = self:CurrentSourcePosition(),
        Referenced = true,
      }
      return self.GlobalLabels[trueName],true,false
    end
  end
end



-- Define a new label
function HCOMP:DefineLabel(name,declareLocalVariable)
  local label,isNew,wasReferenced = self:GetLabel(name,declareLocalVariable)
  if not isNew then                        --
    if label.Position then
      self:Error("Variable redefined: \""..name.."\", previously defined at "..
                 self:formatPrefix(label.Position.Line,label.Position.Col,label.Position.File))
    else
      self:Error("Variable redefined: \""..name.."\"")
    end
  end

  -- Clear referenced flag if required
  label.Referenced = false or wasReferenced
  return label
end



-- Redefine label under new name
function HCOMP:RedefineLabel(oldName,newName)
  local label = self:GetLabel(oldName)
  self.GlobalLabels[string.upper(label.Name)] = nil

  label.Name = newName
  local prevLabel = self.GlobalLabels[string.upper(label.Name)]
  if prevLabel then
    if prevLabel.Position then
      self:Error("Variable redefined: \""..newName.."\", previously defined at "..
                 self:formatPrefix(prevLabel.Position.Line,prevLabel.Position.Col,prevLabel.Position.File))
    else
      self:Error("Variable redefined: \""..newName.."\"")
    end
  else
    self.GlobalLabels[string.upper(label.Name)] = label
  end
end




-- Get a new temporary/internal label for use in complex language structures
function HCOMP:GetTempLabel()
  local labelName = "__"..self.LabelCounter
  self.GlobalLabels[labelName] = {
    Type = "Unknown",
    Name = labelName,
  }

  self.LabelCounter = self.LabelCounter + 1
  return self.GlobalLabels[labelName]
end




-- Set a label to specific value (used for special labels)
function HCOMP:SetLabel(name,value)
  local label = self:GetLabel(name)
  label.Type = "Pointer"
  label.Value = value
end




-- Set special labels
function HCOMP:SetSpecialLabels()
  -- Set special labels
  if self.Settings.CurrentLanguage ~= "C" then
    self:SetLabel("programsize",self.WritePointer)
  end
  self:SetLabel("__PROGRAMSIZE__",self.WritePointer)
  self:SetLabel("__DATE_YEAR__",  tonumber(os.date("%Y")))
  self:SetLabel("__DATE_MONTH__", tonumber(os.date("%m")))
  self:SetLabel("__DATE_DAY__",   tonumber(os.date("%d")))
  self:SetLabel("__DATE_HOUR__",  tonumber(os.date("%H")))
  self:SetLabel("__DATE_MINUTE__",tonumber(os.date("%M")))
  self:SetLabel("__DATE_SECOND__",tonumber(os.date("%S")))

  if self.Settings.CurrentPlatform == "GPU" then
    self:SetLabel("regClk",           65535)
    self:SetLabel("regReset",         65534)
    self:SetLabel("regHWClear",       65533)
    self:SetLabel("regVertexMode",    65532)
    self:SetLabel("regHalt",          65531)
    self:SetLabel("regRAMReset",      65530)
    self:SetLabel("regAsyncReset",    65529)
    self:SetLabel("regAsyncClk",      65528)
    self:SetLabel("regAsyncFreq",     65527)
    self:SetLabel("regIndex",         65526)

    self:SetLabel("regHScale",        65525)
    self:SetLabel("regVScale",        65524)
    self:SetLabel("regHWScale",       65523)
    self:SetLabel("regRotation",      65522)
    self:SetLabel("regTexSize",       65521)
    self:SetLabel("regTexDataPtr",    65520)
    self:SetLabel("regTexDataSz",     65519)
    self:SetLabel("regRasterQ",       65518)
    self:SetLabel("regTexBuffer",     65517)


    self:SetLabel("regWidth",         65515)
    self:SetLabel("regHeight",        65514)
    self:SetLabel("regRatio",         65513)
    self:SetLabel("regParamList",     65512)

    self:SetLabel("regCursorX",       65505)
    self:SetLabel("regCursorY",       65504)
    self:SetLabel("regCursor",        65503)
    self:SetLabel("regCursorButtons", 65502)

    self:SetLabel("regBrightnessW",   65495)
    self:SetLabel("regBrightnessR",   65494)
    self:SetLabel("regBrightnessG",   65493)
    self:SetLabel("regBrightnessB",   65492)
    self:SetLabel("regContrastW",     65491)
    self:SetLabel("regContrastR",     65490)
    self:SetLabel("regContrastG",     65489)
    self:SetLabel("regContrastB",     65488)

    self:SetLabel("regCircleQuality", 65485)
    self:SetLabel("regOffsetX",       65484)
    self:SetLabel("regOffsetY",       65483)
    self:SetLabel("regRotation",      65482)
    self:SetLabel("regScale",         65481)
    self:SetLabel("regCenterX",       65480)
    self:SetLabel("regCenterY",       65479)
    self:SetLabel("regCircleStart",   65478)
    self:SetLabel("regCircleEnd",     65477)
    self:SetLabel("regLineWidth",     65476)
    self:SetLabel("regScaleX",        65475)
    self:SetLabel("regScaleY",        65474)
    self:SetLabel("regFontAlign",     65473)
    self:SetLabel("regFontHalign",    65473)
    self:SetLabel("regZOffset",       65472)
    self:SetLabel("regFontValign",    65471)
    self:SetLabel("regCullDistance",  65470)
    self:SetLabel("regCullMode",      65469)
    self:SetLabel("regLightMode",     65468)
    self:SetLabel("regVertexArray",   65467)
    self:SetLabel("regTexRotation",   65466)
    self:SetLabel("regTexScale",      65465)
    self:SetLabel("regTexCenterU",    65464)
    self:SetLabel("regTexCenterV",    65463)
    self:SetLabel("regTexOffsetU",    65462)
    self:SetLabel("regTexOffsetV",    65461)
  end
end




--------------------------------------------------------------------------------
-- Converts integer to binary representation
function HCOMP:IntegerToBinary(n)
  -- Check sign
  n = math.floor(n or 0)
  if n < 0 then
    local bits = self:IntegerToBinary(2^48 + n)
    bits[48-1] = 1
    return bits
  end

  -- Convert to binary
  local bits = {}
  local cnt = 0
  while (n > 0) and (cnt < 48) do
    local bit = n % 2
    bits[cnt] = bit

    n = (n-bit)/2
    cnt = cnt + 1
  end

  -- Fill in missing zero bits
  while cnt < 48 do
    bits[cnt] = 0
    cnt = cnt + 1
  end

  return bits
end




--------------------------------------------------------------------------------
-- Converts binary representation back to integer
function HCOMP:BinaryToInteger(bits)
  local n = #bits
  local result = 0

  -- Convert to integer
  for i = 0, 48-2 do
    result = result + (bits[i] or 0) * (2 ^ i)
  end

  -- Add sign
  if bits[48-1] == 1 then
    return -2^(48-1)+result
  else
    return result
  end
end




--------------------------------------------------------------------------------
-- Binary OR
function HCOMP:BinaryOr(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, 48-1 do
    bits[i] = math.min(1,bits_m[i]+bits_n[i])
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary AND
function HCOMP:BinaryAnd(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, 48-1 do
    bits[i] = bits_m[i]*bits_n[i]
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary NOT
function HCOMP:BinaryNot(n)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, 48-1 do
    bits[i] = 1-bits_n[i]
  end
  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary XOR
function HCOMP:BinaryXor(m,n)
  local bits_m = self:IntegerToBinary(m)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = 0, 48-1 do
    bits[i] = (bits_m[i]+bits_n[i]) % 2
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary shift right
function HCOMP:BinarySHR(n,cnt)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  local rslt = #bits_n
  for i = 0, 48-cnt-1 do
    bits[i] = bits_n[i+cnt]
  end
  for i = 48-cnt,rslt-1 do
    bits[i] = 0
  end

  return self:BinaryToInteger(bits)
end




--------------------------------------------------------------------------------
-- Binary shift left
function HCOMP:BinarySHL(n,cnt)
  local bits_n = self:IntegerToBinary(n)
  local bits = {}

  for i = cnt,48-1 do
    bits[i] = bits_n[i-cnt]
  end
  for i = 0,cnt-1 do
    bits[i] = 0
  end

  return self:BinaryToInteger(bits)
end
