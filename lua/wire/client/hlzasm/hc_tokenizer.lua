--------------------------------------------------------------------------------
-- All symbols (tokens) recognized by parser
HCOMP.TOKEN_TEXT = {}
HCOMP.TOKEN_TEXT["IDENT"]     = {{"ZASM","C","HLZASM"},{}} -- ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz _
HCOMP.TOKEN_TEXT["NUMBER"]    = {{"ZASM","C","HLZASM"},{}} -- 0123456789
HCOMP.TOKEN_TEXT["LPAREN"]    = {{"ZASM","C","HLZASM"},{"("}}
HCOMP.TOKEN_TEXT["RPAREN"]    = {{"ZASM","C","HLZASM"},{")"}}
HCOMP.TOKEN_TEXT["LBRACKET"]  = {{       "C","HLZASM"},{"{"}}
HCOMP.TOKEN_TEXT["RBRACKET"]  = {{       "C","HLZASM"},{"}"}}
HCOMP.TOKEN_TEXT["LSUBSCR"]   = {{"ZASM","C","HLZASM"},{"["}}
HCOMP.TOKEN_TEXT["RSUBSCR"]   = {{"ZASM","C","HLZASM"},{"]"}}
HCOMP.TOKEN_TEXT["COLON"]     = {{"ZASM","C","HLZASM"},{";"}}
HCOMP.TOKEN_TEXT["DCOLON"]    = {{"ZASM","C","HLZASM"},{":"}}
HCOMP.TOKEN_TEXT["HASH"]      = {{"ZASM","C","HLZASM"},{"#"}}
HCOMP.TOKEN_TEXT["TIMES"]     = {{"ZASM","C","HLZASM"},{"*"}}
HCOMP.TOKEN_TEXT["SLASH"]     = {{"ZASM","C","HLZASM"},{"/"}}
HCOMP.TOKEN_TEXT["MODULUS"]   = {{       "C","HLZASM"},{"%"}}
HCOMP.TOKEN_TEXT["PLUS"]      = {{"ZASM","C","HLZASM"},{"+"}}
HCOMP.TOKEN_TEXT["MINUS"]     = {{"ZASM","C","HLZASM"},{"-"}}
HCOMP.TOKEN_TEXT["AND"]       = {{       "C","HLZASM"},{"&"}}
HCOMP.TOKEN_TEXT["OR"]        = {{       "C","HLZASM"},{"|"}}
HCOMP.TOKEN_TEXT["XOR"]       = {{       "C","HLZASM"},{"^"}}
HCOMP.TOKEN_TEXT["POWER"]     = {{       "C","HLZASM"},{"^^"}}
HCOMP.TOKEN_TEXT["INC"]       = {{       "C","HLZASM"},{"++"}}
HCOMP.TOKEN_TEXT["DEC"]       = {{       "C","HLZASM"},{"--"}}
HCOMP.TOKEN_TEXT["SHL"]       = {{       "C","HLZASM"},{"<<"}}
HCOMP.TOKEN_TEXT["SHR"]       = {{       "C","HLZASM"},{">>"}}
HCOMP.TOKEN_TEXT["EQL"]       = {{       "C","HLZASM"},{"=="}}
HCOMP.TOKEN_TEXT["NEQ"]       = {{       "C","HLZASM"},{"!="}}
HCOMP.TOKEN_TEXT["LEQ"]       = {{       "C","HLZASM"},{"<="}}
HCOMP.TOKEN_TEXT["LSS"]       = {{       "C","HLZASM"},{"<"}}
HCOMP.TOKEN_TEXT["GEQ"]       = {{       "C","HLZASM"},{">="}}
HCOMP.TOKEN_TEXT["GTR"]       = {{       "C","HLZASM"},{">"}}
HCOMP.TOKEN_TEXT["NOT"]       = {{       "C","HLZASM"},{"!"}}
HCOMP.TOKEN_TEXT["EQUAL"]     = {{       "C","HLZASM"},{"="}}
HCOMP.TOKEN_TEXT["LAND"]      = {{       "C","HLZASM"},{"&&"}}
HCOMP.TOKEN_TEXT["LOR"]       = {{       "C","HLZASM"},{"||"}}
HCOMP.TOKEN_TEXT["EQLADD"]    = {{       "C","HLZASM"},{"+="}}
HCOMP.TOKEN_TEXT["EQLSUB"]    = {{       "C","HLZASM"},{"-="}}
HCOMP.TOKEN_TEXT["EQLMUL"]    = {{       "C","HLZASM"},{"*="}}
HCOMP.TOKEN_TEXT["EQLDIV"]    = {{       "C","HLZASM"},{"/="}}
HCOMP.TOKEN_TEXT["COMMA"]     = {{"ZASM","C","HLZASM"},{","}}
HCOMP.TOKEN_TEXT["DOT"]       = {{"ZASM","C","HLZASM"},{"."}}

HCOMP.TOKEN_TEXT["GOTO"]      = {{"C","HLZASM"},{"GOTO"}}
HCOMP.TOKEN_TEXT["FOR"]       = {{"C","HLZASM"},{"FOR"}}
HCOMP.TOKEN_TEXT["IF"]        = {{"C","HLZASM"},{"IF"}}
HCOMP.TOKEN_TEXT["ELSE"]      = {{"C","HLZASM"},{"ELSE"}}
HCOMP.TOKEN_TEXT["WHILE"]     = {{"C","HLZASM"},{"WHILE"}}
HCOMP.TOKEN_TEXT["DO"]        = {{"C","HLZASM"},{"DO"}}
HCOMP.TOKEN_TEXT["SWITCH"]    = {{"C","HLZASM"},{"SWITCH"}}
HCOMP.TOKEN_TEXT["CASE"]      = {{"C","HLZASM"},{"CASE"}}
HCOMP.TOKEN_TEXT["CONST"]     = {{"C","HLZASM"},{"CONST"}}
HCOMP.TOKEN_TEXT["RETURN"]    = {{"C","HLZASM"},{"RETURN"}}
HCOMP.TOKEN_TEXT["BREAK"]     = {{"C","HLZASM"},{"BREAK"}}
HCOMP.TOKEN_TEXT["CONTINUE"]  = {{"C","HLZASM"},{"CONTINUE"}}
HCOMP.TOKEN_TEXT["EXPORT"]    = {{"C","HLZASM"},{"EXPORT"}}
HCOMP.TOKEN_TEXT["INLINE"]    = {{"C","HLZASM"},{"INLINE"}}
HCOMP.TOKEN_TEXT["FORWARD"]   = {{"C","HLZASM"},{"FORWARD"}}
HCOMP.TOKEN_TEXT["LREGISTER"] = {{"C","HLZASM"},{"REGISTER"}}

HCOMP.TOKEN_TEXT["DB"]        = {{"ZASM","HLZASM"},{"DB"}}
HCOMP.TOKEN_TEXT["ALLOC"]     = {{"ZASM","HLZASM"},{"ALLOC"}}
HCOMP.TOKEN_TEXT["VECTOR"]    = {{"ZASM","HLZASM"},{"SCALAR","VECTOR1F","VECTOR2F","UV","VECTOR3F",
                                                    "VECTOR4F","COLOR","VEC1F","VEC2F","VEC3F","VEC4F","MATRIX"}}

HCOMP.TOKEN_TEXT["STRALLOC"]  = {{"ZASM","HLZASM"},{"STRING"}}
HCOMP.TOKEN_TEXT["DB"]        = {{"ZASM","HLZASM"},{"DB"}}
HCOMP.TOKEN_TEXT["DEFINE"]    = {{"ZASM","HLZASM"},{"DEFINE"}}
HCOMP.TOKEN_TEXT["CODE"]      = {{"ZASM","HLZASM"},{"CODE"}}
HCOMP.TOKEN_TEXT["DATA"]      = {{"ZASM","HLZASM"},{"DATA"}}
HCOMP.TOKEN_TEXT["ORG"]       = {{"ZASM","HLZASM"},{"ORG"}}
HCOMP.TOKEN_TEXT["OFFSET"]    = {{"ZASM","HLZASM"},{"OFFSET"}}
HCOMP.TOKEN_TEXT["TYPE"]      = {{"ZASM","HLZASM"},{"VOID","FLOAT","CHAR","INT48","VECTOR"}}
HCOMP.TOKEN_TEXT["CTYPE"]     = {            {"C"},{"VOID","FLOAT","CHAR","INT","VECTOR"}}
HCOMP.TOKEN_TEXT["USERTYPE"]  = {{"ZASM","C","HLZASM"},{}}

HCOMP.TOKEN_TEXT["PRESERVE"]  = {{"HLZASM"},{"PRESERVE"}}
HCOMP.TOKEN_TEXT["ZAP"]       = {{"HLZASM"},{"ZAP"}}

HCOMP.TOKEN_TEXT["REGISTER"]  = {{"ZASM","HLZASM"},{"EAX","EBX","ECX","EDX","ESI","EDI","ESP","EBP"}}
HCOMP.TOKEN_TEXT["SEGMENT"]   = {{"ZASM","HLZASM"},{"CS","SS","DS","ES","GS","FS","KS","LS"}}
HCOMP.TOKEN_TEXT["OPCODE"]    = {{"ZASM","HLZASM"},{}} -- mov, cmp, etc...
HCOMP.TOKEN_TEXT["STRING"]    = {{"ZASM","C","HLZASM"},{}} -- buffer of chars
HCOMP.TOKEN_TEXT["CHAR"]      = {{"ZASM","C","HLZASM"},{}} -- single character
HCOMP.TOKEN_TEXT["EOF"]       = {{"ZASM","C","HLZASM"},{}} -- end of file

-- Add ZCPU ports
for port=0,1023 do
  HCOMP.TOKEN_TEXT["REGISTER"][2][1024+port] = "PORT"..port
end

-- Add extended registers
for reg=0,31 do
  HCOMP.TOKEN_TEXT["REGISTER"][2][96+reg] = "R"..reg
end




--------------------------------------------------------------------------------
-- Generate table of all possible tokens
HCOMP.TOKEN = {}
HCOMP.TOKEN_NAME = {}
HCOMP.TOKEN_NAME2 = {}
local IDX = 1
for tokenName,tokenData in pairs(HCOMP.TOKEN_TEXT) do
  HCOMP.TOKEN[tokenName] = IDX
  HCOMP.TOKEN_NAME[IDX] = tokenName
  HCOMP.TOKEN_NAME2[IDX] = {}

  for k,v in pairs(tokenData[2]) do
    HCOMP.TOKEN_NAME2[IDX][k] = v
  end
--  print(tokenName,IDX)
  IDX = IDX + 1
end

-- Create lookup tables for faster parsing
local temp = ""
HCOMP.PARSER_LOOKUP = {}
for symID,symList in pairs(HCOMP.TOKEN_TEXT) do
  for _,languageName in pairs(symList[1]) do
    HCOMP.PARSER_LOOKUP[languageName] = HCOMP.PARSER_LOOKUP[languageName] or {}
    for symSubID,symText in pairs(symList[2]) do
      if symID == "VECTOR" then -- Special case for vector symbols
        HCOMP.PARSER_LOOKUP[languageName][symText] = { symText, HCOMP.TOKEN[symID] }
      else
        HCOMP.PARSER_LOOKUP[languageName][symText] = { symSubID, HCOMP.TOKEN[symID] }
      end
    end
  end
end

print(temp)

-- Add opcodes to the lookup table
for _,languageName in pairs(HCOMP.TOKEN_TEXT["OPCODE"][1]) do
  HCOMP.PARSER_LOOKUP[languageName] = HCOMP.PARSER_LOOKUP[languageName] or {}
  for opcodeName,opcodeNo in pairs(HCOMP.OpcodeNumber) do
    HCOMP.PARSER_LOOKUP[languageName][string.upper(opcodeName)] = { opcodeName, HCOMP.TOKEN.OPCODE }
  end
end




--------------------------------------------------------------------------------
-- Skip a single line in input
function HCOMP:nextLine()
 table.remove(self.Code,1)
 if not self.Code[1] then
   self.Code[1] = { Line = 0, TextLength = 0, Text = "", File = "internal error" }
 end
end

-- Return next character
function HCOMP:getChar()
  local char = string.sub(self.Code[1].Text,1,1)
  if char == "" then
    self:nextLine()
    char = string.sub(self.Code[1].Text,1,1)
  end
  return char
end

-- Skip current char
function HCOMP:nextChar()
  if self.Code[1].Text == "" then
    self:nextLine()
  else
    self.Code[1].Text = string.sub(self.Code[1].Text,2)
  end
end




--------------------------------------------------------------------------------
-- Tokenize the code
function HCOMP:Tokenize() local TOKEN = self.TOKEN
  -- Skip whitespaces
  while (self:getChar() == " ") or (self:getChar() == "\t") do self:nextChar() end

  -- Store this line as previous
  self.PreviousCodeLine = self.Code[1].Text

  -- Read token position
  local tokenPosition = { Line = self.Code[1].Line,
                          Col  = self.Code[1].TextLength - #self.Code[1].Text + 1,
                          File = self.Code[1].File }

  -- Check for end of file
  if self:getChar() == "" then
    table.insert(self.Tokens,{
      Type = TOKEN.EOF,
      Data = nil,
      Position = tokenPosition,
    })
    return false
  end

  --  Is it a string
  if (self:getChar() == "'") or (self:getChar() == "\"") then
    local stringType = self:getChar()
    self:nextChar() -- Skip leading character

    local fetchString = ""
    while (self.Code[1].Text ~= "") and (self:getChar() ~= "'") and (self:getChar() ~= "\"") do

      if self:getChar() == "\\" then
        self:nextChar()
            if self:getChar() == "'"  then fetchString = fetchString .. "'"
        elseif self:getChar() == "\"" then fetchString = fetchString .. "\""
        elseif self:getChar() == "a"  then fetchString = fetchString .. "\a"
        elseif self:getChar() == "b"  then fetchString = fetchString .. "\b"
        elseif self:getChar() == "c"  then fetchString = fetchString .. "\c"
        elseif self:getChar() == "f"  then fetchString = fetchString .. "\f"
        elseif self:getChar() == "r"  then fetchString = fetchString .. "\r"
        elseif self:getChar() == "n"  then fetchString = fetchString .. "\n"
        elseif self:getChar() == "t"  then fetchString = fetchString .. "\t"
        elseif self:getChar() == "v"  then fetchString = fetchString .. "\v"
        elseif self:getChar() == "0"  then fetchString = fetchString .. "\0"
        end
        self:nextChar()
      else
        fetchString = fetchString .. self:getChar()
        self:nextChar()
      end
    end
    self:nextChar() -- Skip trailing character

    if (stringType == "'") and (#fetchString == 1) then
      table.insert(self.Tokens,{
        Type = TOKEN.CHAR,
        Data = string.byte(fetchString),
        Position = tokenPosition,
      })
    else
      --if stringType == "'" then
      --  self:Warning("Using character definition syntax for defining a string - might cause problems")
      --end
      table.insert(self.Tokens,{
        Type = TOKEN.STRING,
        Data = fetchString,
        Position = tokenPosition,
      })
    end
    return true
  end

  -- Fetch entire token
  local token = ""
  while string.find(self:getChar(),"[%w_.@]") do
    token = token .. self:getChar()
    self:nextChar()
  end

  if token == "" then
    token = self:getChar()
    self:nextChar()

    if (token == "^") and (self:getChar() == "^") then token = token .. "^" self:nextChar() end
    if (token == "+") and (self:getChar() == "+") then token = token .. "+" self:nextChar() end
    if (token == "-") and (self:getChar() == "-") then token = token .. "-" self:nextChar() end
    if (token == "<") and (self:getChar() == "<") then token = token .. "<" self:nextChar() end
    if (token == ">") and (self:getChar() == ">") then token = token .. ">" self:nextChar() end
    if (token == "=") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "!") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "<") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == ">") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "&") and (self:getChar() == "&") then token = token .. "&" self:nextChar() end
    if (token == "|") and (self:getChar() == "|") then token = token .. "|" self:nextChar() end
    if (token == "+") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "-") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "*") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
    if (token == "/") and (self:getChar() == "=") then token = token .. "=" self:nextChar() end
  end

  -- Determine which token it is
  local tokenLookupTable = self.PARSER_LOOKUP[self.Settings.CurrentLanguage][string.upper(token)]
  if tokenLookupTable then
    table.insert(self.Tokens,{
      Type = tokenLookupTable[2],
      Data = tokenLookupTable[1],
      Position = tokenPosition,
    })
    return true
  end

  -- Maybe its a number
  if tonumber(token) then
    table.insert(self.Tokens,{
      Type = TOKEN.NUMBER,
      Data = tonumber(token),
      Position = tokenPosition,
    })
    return true
  end

  -- Wow it must have been ident afterall
  table.insert(self.Tokens,{
    Type = TOKEN.IDENT,
    Data = token,
    Position = tokenPosition,
  })
  return true
end




--------------------------------------------------------------------------------
-- Print a string of tokens as an expression
function HCOMP:PrintTokens(tokenList)
  local text = ""
  if type(tokenList) ~= "table" then error("[global 1:1] Internal error 516 ("..tokenList..")") end

  for _,token in ipairs(tokenList) do
    if (token.Type == self.TOKEN.NUMBER) or
       (token.Type == self.TOKEN.OPCODE) then
        text = text..token.Data
    elseif token.Type == self.TOKEN.IDENT then
      if self.Settings.GenerateLibrary then
        if not self.LabelLookup[token.Data] then
          self.LabelLookup[token.Data] = "_"..self.LabelLookupCounter
          self.LabelLookupCounter = self.LabelLookupCounter + 1
        end
        text = text..self.LabelLookup[token.Data]
      else
        text = text..token.Data
      end
    elseif token.Type == self.TOKEN.STRING then
      text = text.."\""..token.Data.."\""
    elseif token.Type == self.TOKEN.CHAR then
      if token.Data >= 32 then
        text = text.."'"..string.char(token.Data).."'"
      else
        text = text.."'\\"..token.Data.."'"
      end
    else
      text = text..(self.TOKEN_NAME2[token.Type][token.Data or 1] or "<?>")
    end
  end
  return text
end




--------------------------------------------------------------------------------
-- Expects next token to be tok, otherwise will raise an error
function HCOMP:ExpectToken(tok)
  if not self.Tokens[self.CurrentToken] then
    if tok == self.TOKEN.EOF then
      self:Error("Expected "..HCOMP.TOKEN_NAME[tok]..", got "..HCOMP.TOKEN_NAME[self.TOKEN.EOF].." instead")
    end
  end

  if self.Tokens[self.CurrentToken].Type == tok then
    self.TokenType = self.Tokens[self.CurrentToken].Type
    self.TokenData = self.Tokens[self.CurrentToken].Data
    self.CurrentToken = self.CurrentToken + 1
  else
    self:Error("Expected "..HCOMP.TOKEN_NAME[tok]..", got "..HCOMP.TOKEN_NAME[self.Tokens[self.CurrentToken].Type].." instead")
  end
end




-- Returns true and skips a token if it matches this one
function HCOMP:MatchToken(tok)
  if not self.Tokens[self.CurrentToken] then
    return tok == self.TOKEN.EOF
  end

  if self.Tokens[self.CurrentToken].Type == tok then
    self.TokenType = self.Tokens[self.CurrentToken].Type
    self.TokenData = self.Tokens[self.CurrentToken].Data
    self.CurrentToken = self.CurrentToken + 1
    return true
  else
    return false
  end
end




-- Go to next token
function HCOMP:NextToken()
  self.CurrentToken = self.CurrentToken + 1
end




-- Returns next token type. Looks forward into stream if offset is specified
function HCOMP:PeekToken(offset)
  if self.Tokens[self.CurrentToken+(offset or 0)] then
    return self.Tokens[self.CurrentToken+(offset or 0)].Type
  else
    return self.TOKEN.EOF
  end
end




-- Store current parser state (so code could be reparsed again later)
function HCOMP:SaveParserState()
  self.SavedToken = self.CurrentToken
end




-- Get all tokens between saved state and current state. This is used for
-- reparsing expressions during resolve stage.
function HCOMP:GetSavedTokens(firstToken)
  local savedTokens = {}
  for tokenIdx = firstToken or self.SavedToken,self.CurrentToken do -- -1
    table.insert(savedTokens,self.Tokens[tokenIdx])
  end
  savedTokens.TokenList = true
  return savedTokens
end




-- Restore parser state. Can accept a list of tokens and restore state to that
-- (see GetSavedTokens())
function HCOMP:RestoreParserState(tokenList)
  if tokenList then
    self.Tokens = tokenList
    self.CurrentToken = 1
  else
    self.CurrentToken = self.SavedToken
  end
end




-- Returns current position in source file
function HCOMP:CurrentSourcePosition()
  if self.Tokens[self.CurrentToken-1] then
    return self.Tokens[self.CurrentToken-1].Position
  else
    return { Line = 1, Col = 1, File = "HL-ZASM" }
  end
end
