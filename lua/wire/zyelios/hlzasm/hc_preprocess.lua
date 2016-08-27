--------------------------------------------------------------------------------
-- HCOMP / HL-ZASM compiler
--
-- Preprocessor macro parser
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Load file
function HCOMP:LoadFile(filename)
  return file.Read("data/"..self.Settings.CurrentPlatform.."Chip/"..filename, "GAME") -- So we also get /addons/wire/data/
end

-- Save file
function HCOMP:SaveFile(filename,text)
  file.Write(self.Settings.CurrentPlatform.."Chip/"..filename,text)
end

-- Trim spaces at string sides
local function trimString(str)
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end




--------------------------------------------------------------------------------
-- Handle preprocessor macro
function HCOMP:ParsePreprocessMacro(lineText,macroPosition)
  -- Trim spaces
  local macroLine = trimString(lineText)

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
      if string.lower(pragmaCommand) == "zasm"   then self.Settings.CurrentLanguage = "ZASM"   end
    elseif pragmaName == "crt" then
      local crtFilename = "lib\\"..string.lower(pragmaCommand).."\\init.txt"
      local fileText = self:LoadFile(crtFilename)
      if fileText then
        table.insert(self.Code, 1, { Text = fileText, Line = 1, Col = 1, File = crtFilename, NextCharPos = 1 })
      else
        self:Error("Unable to include CRT library "..pragmaCommand,
          macroPosition.Line,macroPosition.Col,macroPosition.File)
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
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
    self.Defines[defineName] = defineValue
  elseif macroName == "undef" then -- #undef
    local defineName = trimString(string.sub(macroParameters,1,(string.find(macroParameters," ") or 0)-1))
    if tonumber(defineName) then
      self:Error("Bad idea to undefine numbers",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
	self.Defines[defineName] = nil
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
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end

    self.IFDEFLevel[#self.IFDEFLevel] = not self.IFDEFLevel[#self.IFDEFLevel]
  elseif macroName == "endif" then -- #endif
    if #self.IFDEFLevel == 0 then
      self:Error("Unexpected #endif macro",
        macroPosition.Line,macroPosition.Col,macroPosition.File)
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
        macroPosition.Line,macroPosition.Col,macroPosition.File)
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
      table.insert(self.Code, 1, { Text = fileText, Line = 1, Col = 1, File = fileName, NextCharPos = 1 })
    else
      self:Error("Cannot open file: "..fileName,
        macroPosition.Line,macroPosition.Col,macroPosition.File)
    end
  else
    self:Error("Invalid macro: #"..macroName,
      macroPosition.Line,macroPosition.Col,macroPosition.File)
  end
end
