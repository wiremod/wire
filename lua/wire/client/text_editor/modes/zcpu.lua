local math_floor = math.floor
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local draw_WordBox = draw.WordBox

local EDITOR = {}

-- CPU hint box
local oldpos, haschecked = {0,0}, false
function EDITOR:Think()
  local caret = self:CursorToCaret()
  local startpos, word = self:getWordStart( caret, true )

  if word and word ~= "" then
    if not haschecked then
      oldpos = {startpos[1],startpos[2]}
      haschecked = true
      timer.Simple(0.3,function()
        if not self then return end
        if not self.CursorToCaret then return end
        local caret = self:CursorToCaret()
        local startpos, word = self:getWordStart( caret, true )
        if startpos[1] == oldpos[1] and startpos[2] == oldpos[2] then
          self.CurrentVarValue = { startpos, word }
        end
      end)
    elseif (oldpos[1] ~= startpos[1] or oldpos[2] ~= startpos[2]) and haschecked then
      haschecked = false
      self.CurrentVarValue = nil
      oldpos = {0,0}
    end
  else
    self.CurrentVarValue = nil
    haschecked = false
    oldpos = {0,0}
  end
end

local colors = {
  ["normal"]   = { Color(255, 255, 136), false},
  ["opcode"]   = { Color(255, 136,   0), false},
  ["comment"]  = { Color(128, 128, 128), false},
  ["register"] = { Color(255, 255, 136), false},
  ["number"]   = { Color(232, 232,   0), false},
  ["string"]   = { Color(255, 136, 136), false},
  ["filename"] = { Color(232, 232, 232), false},
  ["label"]    = { Color(255, 255, 176), false},
  ["keyword"]  = { Color(255, 136,   0), false},
  ["memref"]   = { Color(232, 232,   0), false},
  ["pmacro"]   = { Color(136, 136, 255), false},
  ["error"]    = { Color(240,  96,  96), false},
  --		["compare"]  = { Color(255, 186,  40), true},
}

-- Build lookup table for opcodes
local opcodeTable = {}
for k,v in pairs(CPULib.InstructionTable) do
  if v.Mnemonic ~= "RESERVED" then
    opcodeTable[v.Mnemonic] = true
  end
end

-- Build lookup table for keywords
local keywordsList = {
  "GOTO","FOR","IF","ELSE","WHILE","DO","SWITCH","CASE","CONST","RETURN","BREAK",
  "CONTINUE","EXPORT","INLINE","FORWARD","REGISTER","DB","ALLOC","SCALAR","VECTOR1F",
  "VECTOR2F","UV","VECTOR3F","VECTOR4F","COLOR","VEC1F","VEC2F","VEC3F","VEC4F","MATRIX",
  "STRING","DB","DEFINE","CODE","DATA","ORG","OFFSET","INT48","FLOAT","CHAR","VOID",
  "INT","FLOAT","CHAR","VOID","PRESERVE","ZAP","STRUCT","VECTOR"
}

local keywordsTable = {}
for k,v in pairs(keywordsList) do
  keywordsTable[v] = true
end

-- Build lookup table for registers
local registersTable = {
  EAX = true,EBX = true,ECX = true,EDX = true,ESI = true,EDI = true,
  ESP = true,EBP = true,CS = true,SS = true,DS = true,ES = true,GS = true,
  FS = true,KS = true,LS = true
}
for reg=0,31 do registersTable["R"..reg] = true end
for port=0,1023 do registersTable["PORT"..port] = true end

-- Build lookup table for macros
local macroTable = {
  ["PRAGMA"] = true,
  ["INCLUDE"] = true,
  ["#INCLUDE##"] = true,
  ["DEFINE"] = true,
  ["IFDEF"] = true,
  ["IFNDEF"] = true,
  ["ENDIF"] = true,
  ["ELSE"] = true,
  ["UNDEF"] = true,
}

function EDITOR:CommentSelection(removecomment)
  local comment_char = "//"
  if removecomment then
    -- shift-TAB with a selection --
    local tmp = string_gsub("\n"..self:GetSelection(), "\n"..comment_char, "\n")

    -- makes sure that the first line is outdented
    self:SetSelection(tmp:sub(2))
  else
    -- plain TAB with a selection --
    self:SetSelection(comment_char .. self:GetSelection():gsub("\n", "\n"..comment_char))
  end
end

function EDITOR:BlockCommentSelction(removecomment)
  local sel_start, sel_caret = self:MakeSelection( self:Selection() )
  local str = self:GetSelection()
  if removecomment then
    if str:find( "^/%*" ) and str:find( "%*/$" ) then
      self:SetSelection( str:gsub( "^/%*(.+)%*/$", "%1" ) )

      sel_caret[2] = sel_caret[2] - 2
    end
  else
    self:SetSelection( "/*" .. str .. "*/" )

    if sel_caret[1] == sel_start[1] then
      sel_caret[2] = sel_caret[2] + 4
    else
      sel_caret[2] = sel_caret[2] + 2
    end
  end
  return { sel_start, sel_caret }
end

function EDITOR:ShowContextHelp(word)
  E2Helper.Show()
  E2Helper.UseCPU(self:GetParent().EditorType)
  E2Helper.Show(word)
end

function EDITOR:ResetTokenizer(row)
  if row == self.Scroll[1] then
    -- As above, but for HL-ZASM: Check whether the line self.Scroll[1] starts within a block comment.
    self.blockcomment = nil

    for k=1, self.Scroll[1]-1 do
      local row = self.Rows[k]

      for match in string_gmatch(row, "[/*][/*]") do
        if match == "//" then
          -- single line comment start; skip remainder of line
          break
        elseif match == "/*" then
          self.blockcomment = true
        elseif match == "*/" then
          self.blockcomment = nil
        end
      end
    end
  end
end

function EDITOR:SyntaxColorLine(row)
  local cols = {}
  self:ResetTokenizer(row)
  self:NextCharacter()

  if self.blockcomment then
    if self:NextPattern(".-%*/") then
      self.blockcomment = nil
    else
      self:NextPattern(".*")
    end

    cols[#cols + 1] = {self.tokendata, colors["comment"]}
  end

  local isGpu = self:GetParent().EditorType == "GPU"

  while self.character do
    local tokenname = ""
    self.tokendata = ""

    self:NextPattern(" *")
    if not self.character then break end

    if self:NextPattern("^[a-zA-Z0-9_@.]+:") then
      tokenname = "label"
    elseif self:NextPattern("^[a-zA-Z0-9_@.]+") then
      local sstr = string.upper(self.tokendata:Trim())
      if opcodeTable[sstr] then
        tokenname = "opcode"
      elseif registersTable[sstr] then
        tokenname = "register"
      elseif keywordsTable[sstr] then
        tokenname = "keyword"
      elseif tonumber(self.tokendata) then
        tokenname = "number"
      else
        tokenname = "normal"
      end
    elseif (self.character == "'") or (self.character == "\"") then
      tokenname = "string"
      local delimiter = self.character
      self:NextCharacter()
      while self.character ~= delimiter do
        if not self.character then tokenname = "error" break end
        if self.character == "\\" then self:NextCharacter() end
        self:NextCharacter()
      end
      self:NextCharacter()
    elseif self:NextPattern("^//.*$") then
      tokenname = "comment"
    elseif self:NextPattern("^/%*") then -- start of a multi-line comment
    --addToken("comment", self.tokendata)
    self.blockcomment = true
    if self:NextPattern(".-%*/") then
      self.blockcomment = nil
    else
      self:NextPattern(".*")
    end

    tokenname = "comment"
    elseif self.character == "#" then
      self:NextCharacter()

      if self:NextPattern("include +<") then

        cols[#cols + 1] = {self.tokendata:sub(1,-2), colors["pmacro"]}

        self.tokendata = "<"
        if self:NextPattern("^[a-zA-Z0-9_/\\]+%.txt>") then
          tokenname = "filename"
        else
          self:NextPattern(".*$")
          tokenname = "normal"
        end
      elseif self:NextPattern("include +\"") then

        cols[#cols + 1] = {self.tokendata:sub(1,-2), colors["pmacro"]}

        self.tokendata = "\""
        if self:NextPattern("^[a-zA-Z0-9_/\\]+%.txt\"") then
          tokenname = "filename"
        else
          self:NextPattern(".*$")
          tokenname = "normal"
        end
      elseif self:NextPattern("^[a-zA-Z0-9_@.#]+") then
        local sstr = string.sub(string.upper(self.tokendata:Trim()),2)
        if macroTable[sstr] then
          self:NextPattern(".*$")
          tokenname = "pmacro"
        else
          tokenname = "memref"
        end
      else
        tokenname = "memref"
      end
    elseif self.character == "[" or self.character == "]" then
      self:NextCharacter()
      tokenname = "memref"
    else
      self:NextCharacter()
      tokenname = "normal"
    end

    local color = colors[tokenname]
    if #cols > 1 and color == cols[#cols][2] then
      cols[#cols][1] = cols[#cols][1] .. self.tokendata
    else
      cols[#cols + 1] = {self.tokendata, color}
    end
  end
  return cols
end

function EDITOR:PopulateMenu(menu)
  if not self.chosenfile then return end

  menu:AddSpacer()

  local caretPos = self:CursorToCaret()
  local IsBreakpointSet = CPULib.GetDebugBreakpoint( self.chosenfile, caretPos )

  if not IsBreakpointSet then
    menu:AddOption( "Add Breakpoint", function()
      CPULib.SetDebugBreakpoint( self.chosenfile, caretPos, true )
    end)
    --				menu:AddOption( "Add Conditional Breakpoint", function()
    --					Derma_StringRequestNoBlur( "Add Conditional Breakpoint", "456", "123",
    --					function( strTextOut )
    --						CPULib.SetDebugBreakpoint( caretPos, strTextOut )
    --					end )
    --				end)
  else
    menu:AddOption( "Remove Breakpoint", function()
      CPULib.SetDebugBreakpoint( self.chosenfile, caretPos )
    end)
  end
end

function EDITOR:Paint()
  -- Paint CPU debug hints
  if self.CurrentVarValue then
    local pos = self.CurrentVarValue[1]
    local x, y = (pos[2]+2) * self.FontWidth, (pos[1]-1-self.Scroll[1]) * self.FontHeight
    local txt = CPULib.GetDebugPopupText(self.CurrentVarValue[2])
    if txt then
      draw_WordBox(2, x, y, txt, "E2SmallFont", Color(0,0,0,255), Color(255,255,255,255) )
    end
  end

  if CPULib.DebuggerAttached then
    local debugWindowText = CPULib.GetDebugWindowText()
    for k,v in ipairs(debugWindowText) do
      if v ~= "" then
        local y = (k % 24)
        local x = 15*(1 + math_floor(#debugWindowText / 24) - math_floor(k / 24))
        draw_WordBox(2, self:GetWide()-self.FontWidth*x, self.FontHeight*(-1+y), v, "E2SmallFont", Color(0,0,0,255), Color(255,255,255,255) )
      end
    end
  end
end

WireTextEditor.Modes.ZCPU = EDITOR
