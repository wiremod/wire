--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Preprocessor
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
-- Load file
function HCOMP:LoadFile(filename)
  return file.Read(self.Settings.CurrentPlatform.."Chip\\"..filename)
end

function HCOMP:SaveFile(filename,text)
  file.Save(self.Settings.CurrentPlatform.."Chip\\"..filename,text)
end

-- Trim spaces at string sides
local function trimString(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end




--------------------------------------------------------------------------------
-- Begin preprocessing the code
function HCOMP:BeginPreprocess(sourceCode)
  -- Source code that is still to be preprocessed
  --
  -- Works as a stack: the compiler parses the file that is currently at the top
  -- (which is index #self.SourceCode)
  --   [1]: file name
  --   [2]: remaining text to preprocess
  --   [3]: current line number counter
  self.SourceCode = {{ self.FileName, sourceCode, 0 }}

  -- Storage for all the lines of code. Each line is a table with these keys:
  --   Line - number of line in the source file
  --   Text - line text
  --   TextLength - original line length (for determining column)
  --   File - file name for this line
  self.Code = {}

  -- List of preprocessor defines
  self.Defines = {}
  self.Defines["__LINE__"] = 0
  self.Defines["__FILE__"] = ""

  -- Search paths
  self.SearchPaths = {
    "lib",
    "inc"
  }

  -- Level of #ifdef macro nesting
  self.IFDEFLevel = {}

  -- Is inside long commentary (/* ... */)
  self.InComment = false
end




--------------------------------------------------------------------------------
-- Returns true if there is something still to preprocess
function HCOMP:Preprocess()
  -- Try to find out where the line ends
  local lineEnd = string.find(self.SourceCode[#self.SourceCode][2],"\n")
  local lineText

  if lineEnd then -- There is a line break in the sourcecode
    -- Fetch everything before the line break, and replace line break with a whitespace
    lineText = string.sub(self.SourceCode[#self.SourceCode][2],1,lineEnd-1).." "

    -- Go further parsing the source code
    self.SourceCode[#self.SourceCode][2] = string.sub(self.SourceCode[#self.SourceCode][2],lineEnd+1)
  else
    -- Fetch the entire line
    lineText = self.SourceCode[#self.SourceCode][2]

    -- Finish preprocessing top of the stack
    self.SourceCode[#self.SourceCode][2] = ""
  end

  -- Advance to the next line
  self.SourceCode[#self.SourceCode][3] = self.SourceCode[#self.SourceCode][3] + 1

  -- Clear short comments
  local commentStart = string.find(lineText,"//")
  if commentStart then
    -- Replace comment with a whitespace
    lineText = string.sub(lineText,1,commentStart-1).." "
  end

  -- Clear long comments
  if self.InComment then
    local longCommentEnd = string.find(lineText,"*/",1,true)
    if longCommentEnd then
     -- Replace comment with a whitespace
      lineText = " "..string.sub(lineText,longCommentEnd+2)
      self.InComment = false
    else
      lineText = ""
    end
  else
    local longCommentStart = string.find(lineText,"/*",1,true)
    if longCommentStart then
      -- Replace comment with a whitespace
      lineText = string.sub(lineText,1,longCommentStart-1).." "
      self.InComment = true
    end
  end

  -- Replace special characters (tabs) with whitespaces
  lineText = string.gsub(lineText,"\t"," ")

  -- Update special macros
  self.Defines["__LINE__"] = self.SourceCode[#self.SourceCode][3]
  self.Defines["__FILE__"] = "\""..self.SourceCode[#self.SourceCode][1].."\""

  -- Replace defines with their actual values
  for defineName,defineValue in pairs(self.Defines) do
    if (defineValue ~= "") and (defineName ~= defineValue) then -- Only do this for defines that replace
      local pos
      repeat
        pos = string.find(lineText,"[^a-zA-Z0-9_]"..defineName.."[^a-zA-Z0-9_]")
        if pos then
          lineText = string.sub(lineText,1,pos) .. defineValue .. string.sub(lineText,pos+1+#defineName)
        end
      until not pos
    end
  end

  -- Check if line is a macro
  local macroLine = trimString(lineText)
  if string.sub(macroLine,1,1) == "#" then
    -- Find out macro name and parameters
    local macroNameEnd = (string.find(macroLine," ") or 0)
    local macroName = trimString(string.sub(macroLine,2,macroNameEnd-1))
    local macroParameters = trimString(string.sub(macroLine,macroNameEnd+1))

    if macroName == "pragma" then
      local pragmaName = string.lower(trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1)))
      local pragmaCommand = trimString(string.sub(macroParameters,(string.find(macroParameters," ") or 0)+1))

      if pragmaName == "set" then
        local entryName = trimString(string.sub(pragmaCommand,1,(string.find(pragmaCommand," ") or 0)-1))
        local entryValue = trimString(string.sub(pragmaCommand,(string.find(pragmaCommand," ") or 0)+1))

        if entryValue == "true" then
          self.Settings[entryName] = true
        elseif entryValue == "false" then
          self.Settings[entryName] = false
        else
          self.Settings[entryName] = tonumber(entryValue) or entryValue
        end
      elseif pragmaName == "language" then
        if string.lower(pragmaCommand) == "hlzasm" then self.Settings.CurrentLanguage = "HLZASM" end
        if string.lower(pragmaCommand) == "c"      then self.Settings.CurrentLanguage = "C"      end
        if string.lower(pragmaCommand) == "zasm"   then self.Settings.CurrentLanguage = "ZASM"   end
      elseif pragmaName == "crt" then
        local crtFilename = "lib\\"..string.lower(pragmaCommand).."\\init.txt"
        local fileText = self:LoadFile(crtFilename)
        if fileText then
          table.insert(self.SourceCode,{ crtFilename, fileText, 0 })
        else
          self:Error("Unable to include CRT library "..pragmaCommand,
            self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
        end

        self.Defines[string.upper(pragmaCommand)] = ""
        table.insert(self.SearchPaths,"lib\\"..string.lower(pragmaCommand))
      elseif pragmaName == "cpuname" then
        CPULib.CPUName = pragmaCommand
      elseif pragmaName == "searchpath" then
        table.insert(self.SearchPaths,pragmaCommand)
      end
    elseif macroName == "define" then -- #define
      local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
      local defineValue = string.sub(macroParameters,(string.find(macroParameters," ") or 0)+1)
      if tonumber(defineName) then
        self:Error("Bad idea to redefine numbers",
          self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
      end
      self.Defines[defineName] = defineValue
    elseif macroName == "undef" then -- #undef
      local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    elseif macroName == "ifdef" then -- #ifdef
      local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
      if self.Defines[defineName] then
        self.IFDEFLevel[#self.IFDEFLevel+1] = false
      else
        self.IFDEFLevel[#self.IFDEFLevel+1] = true
      end
    elseif macroName == "ifndef" then -- #ifndef
      local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
      if not self.Defines[defineName] then
        self.IFDEFLevel[#self.IFDEFLevel+1] = false
      else
        self.IFDEFLevel[#self.IFDEFLevel+1] = true
      end
    elseif macroName == "else" then -- #else
      if #self.IFDEFLevel == 0 then
        self:Error("Unexpected #else macro",
          self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
      end

      self.IFDEFLevel[#self.IFDEFLevel] = not self.IFDEFLevel[#self.IFDEFLevel]
    elseif macroName == "endif" then -- #endif
      if #self.IFDEFLevel == 0 then
        self:Error("Unexpected #endif macro",
          self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
      end

      self.IFDEFLevel[#self.IFDEFLevel] = nil
    elseif (macroName == "include") or
           (macroName == "#include##") then -- #include or ZASM2 compatible ##include##
      local symL,symR
      local fileName

      -- ZASM2 compatibility syntax support
      if macroName == "#include##" then
        symL,symR = "<",">"
        fileName = trimString(string.sub(macroParameters,1,-1))
      else
        symL,symR = string.sub(macroParameters,1,1),string.sub(macroParameters,-1,-1)
        fileName = trimString(string.sub(macroParameters,2,-2))
      end

      -- Full file name including the path to file
      local fullFileName
      if (symL == "\"") and (symR == "\"") then -- File relative to current one
        fullFileName = self.WorkingDir..fileName
      elseif (symL == "<") and (symR == ">") then -- File relative to root directory
        fullFileName = fileName
      else
        self:Error("Invalid syntax for #include macro (wrong brackets)",
          self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
      end

      -- Search for file on search paths
      local fileText = self:LoadFile(fullFileName)
      if (symL == "<") and (symR == ">") and (not fileText) then
        for _,searchPath in pairs(self.SearchPaths) do
          if not fileText then
            fileText = self:LoadFile(searchPath.."\\"..fullFileName)
            fileName = searchPath.."\\"..fullFileName
          end
        end
      end

      -- Push this file on top of the stack
      if fileText then
        table.insert(self.SourceCode,{ fileName, fileText, 0 })
      else
        self:Error("Cannot open file: "..fileName,self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
      end
    else
      self:Error("Invalid macro: #"..macroName,self.SourceCode[#self.SourceCode][3],1,self.SourceCode[#self.SourceCode][1])
    end
  elseif (lineText ~= "") and (not (self.IFDEFLevel[#self.IFDEFLevel] == true)) then
    -- Add non-empty lines to the sourcecode
    table.insert(self.Code,{
      Line = self.SourceCode[#self.SourceCode][3],
      Text = lineText,
      TextLength = #lineText,
      File = self.SourceCode[#self.SourceCode][1],
    })
  end

  -- Keep preprocessing until everything is done
  if self.SourceCode[#self.SourceCode][2] ~= "" then
    return true
  else
    self.SourceCode[#self.SourceCode] = nil
    if #self.SourceCode == 0 then
      return false
    else
      return true
    end
  end
end
