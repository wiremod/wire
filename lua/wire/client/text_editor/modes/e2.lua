local table_concat = table.concat
local string_sub = string.sub
local string_gmatch = string.gmatch
local string_gsub = string.gsub

local EDITOR = {
	UseValidator = true,
	Validator = function(editor,source,file)
		return E2Lib.Validate(source)
	end,
	UseSoundBrowser = true,
}

local function istype(tp)
	return wire_expression_types[tp:upper()] or tp == "number"
end

-- keywords[name][nextchar!="("]
local keywords = {
	-- keywords that can be followed by a "(":
	["if"]       = { [true] = true, [false] = true },
	["elseif"]   = { [true] = true, [false] = true },
	["while"]    = { [true] = true, [false] = true },
	["for"]      = { [true] = true, [false] = true },
	["foreach"]  = { [true] = true, [false] = true },
	["switch"] 	 = { [true] = true, [false] = true },
	["case"]     = { [true] = true, [false] = true },
	["default"]  = { [true] = true, [false] = true },
	["catch"]    = { [true] = true, [false] = true },
	["function"] = { [true] = true, [false] = true },

	-- keywords that cannot be followed by a "(":
	["else"]     = { [true] = true },
	["break"]    = { [true] = true },
	["continue"] = { [true] = true },
	["return"] = { [true] = true },
	["local"]  = { [true] = true },
	["let"] = { [true] = true },
	["const"] = { [true] = true },
	["try"]    = { [true] = true },
	["do"] = { [true] = true },
	["event"] = { [true] = true },
	["#include"] = { [true] = true }
}

EDITOR.Keywords = keywords

-- fallback for nonexistant entries:
setmetatable(keywords, { __index=function(tbl,index) return {} end })

-- Directive colors
local FULL = 0       -- Entire thing is yellow
local VARS = 1 -- Directive yellow + Rest are green/variable + Orange types
local PARTIAL = 2       -- Directive yellow + lowercase yellow, uppercase variable

local directives = {
	["@name"]       = FULL,
	["@model"]      = FULL,
	["@inputs"]     = VARS,
	["@outputs"]    = VARS,
	["@persist"]    = VARS,
	["@trigger"]    = PARTIAL,
	["@autoupdate"] = PARTIAL,
	["@strict"]     = PARTIAL
}

local colors = {
	["directive"] = { Color(240, 240, 160), false}, -- yellow
	["number"]    = { Color(240, 160, 160), false}, -- light red
	["function"]  = { Color(160, 160, 240), false}, -- blue
	["notfound"]  = { Color(240,  96,  96), false}, -- dark red
	["variable"]  = { Color(160, 240, 160), false}, -- light green
	["string"]    = { Color(128, 128, 128), false}, -- grey
	["keyword"]   = { Color(160, 240, 240), false}, -- turquoise
	["operator"]  = { Color(224, 224, 224), false}, -- white
	["comment"]   = { Color(128, 128, 128), false}, -- grey
	["ppcommand"] = { Color(240,  96, 240), false}, -- purple
	["ppcommandargs"] = { Color(128, 128, 128), false}, -- same as comment
	["typename"]  = { Color(240, 160,  96), false}, -- orange
	["constant"]  = { Color(240, 160, 240), false}, -- pink
	["userfunction"] = { Color(102, 122, 102), false}, -- dark grayish-green
	["eventname"] = { Color(74, 194, 116), false}, -- green
	["background"] = { Color(32,32,32), false} -- dark-grey
}

function EDITOR:GetSyntaxColor(name)
	return colors[name][1]
end

function EDITOR:SetSyntaxColor( colorname, colr )
	if not colors[colorname] then return end
	colors[colorname][1] = colr
end

-- cols[n] = { tokendata, color }
local cols = {}
local lastcol
local function addToken(tokenname, tokendata)
	local color = colors[tokenname]
	if lastcol and color == lastcol[2] then
		lastcol[1] = lastcol[1] .. tokendata
	else
		cols[#cols + 1] = { tokendata, color, tokenname }
		lastcol = cols[#cols]
	end
end

local function acceptIdent(self)
	return self:NextPattern("^[A-Z][a-zA-Z0-9_]*") or self:NextPattern("^_")
end

local function addOptional(self, pattern, tokendata)
	local s = self:SkipPattern(pattern)
	if s then
		self.tokendata = ""
		addToken(tokendata, s)
	end
end

function EDITOR:CommentSelection(removecomment)
	local sel_start, sel_caret = self:MakeSelection( self:Selection() )
	local mode = self:GetParent().BlockCommentStyleConVar:GetInt()

	if mode == 0 then -- New (alt 1)
		local str = self:GetSelection()
		if removecomment then
			if str:find( "^#%[\n" ) and str:find( "\n%]#$" ) then
				self:SetSelection( str:gsub( "^#%[\n(.+)\n%]#$", "%1" ) )
				sel_caret[1] = sel_caret[1] - 2
			end
		else
			self:SetSelection( "#[\n" .. str .. "\n]#" )
			sel_caret[1] = sel_caret[1] + 1
			sel_caret[2] = 3
		end
	elseif mode == 1 then -- New (alt 2)
		local str = self:GetSelection()
		if removecomment then
			if str:find( "^#%[" ) and str:find( "%]#$" ) then
				self:SetSelection( str:gsub( "^#%[(.+)%]#$", "%1" ) )

				sel_caret[2] = sel_caret[2] - 4
			end
		else
			self:SetSelection( "#[" .. self:GetSelection() .. "]#" )
		end
	elseif mode == 2 then -- Old
		local comment_char = "#"
		if removecomment then
			-- shift-TAB with a selection --
			local tmp = string_gsub("\n"..self:GetSelection(), "\n"..comment_char, "\n")

			-- makes sure that the first line is outdented
			self:SetSelection(tmp:sub(2))
		else
			-- plain TAB with a selection --
			self:SetSelection(comment_char .. self:GetSelection():gsub("\n", "\n"..comment_char))
		end
	else
		ErrorNoHalt( "Invalid block comment style" )
	end

	return { sel_start, sel_caret }
end

function EDITOR:BlockCommentSelection(removecomment)
	local sel_start, sel_caret = self:MakeSelection( self:Selection() )
	local str = self:GetSelection()
	if removecomment then
		if str:find( "^#%[" ) and str:find( "%]#$" ) then
			self:SetSelection( str:gsub( "^#%[(.+)%]#$", "%1" ) )

			if sel_caret[1] == sel_start[1] then
				sel_caret[2] = sel_caret[2] - 4
			else
				sel_caret[2] = sel_caret[2] - 2
			end
		end
	else
		self:SetSelection( "#[" .. str .."]#" )

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
	E2Helper.UseE2(self:GetParent().EditorType)
	E2Helper.Show(word)
end

function EDITOR:ResetTokenizer(row)
	if row == self.Scroll[1] then

		-- This code checks if the visible code is inside a string or a block comment
		self.blockcomment = nil
		self.multilinestring = nil
		local singlelinecomment = false

		local str = string_gsub( table_concat( self.Rows, "\n", 1, self.Scroll[1]-1 ), "\r", "" )

		for pos, char in string_gmatch( str, '()([#"\n])' ) do
			if not self.blockcomment and not self.multilinestring and not singlelinecomment then
				if char == '"' then
					self.multilinestring = true
				elseif char == "#" and string_sub( str, pos + 1, pos + 1 ) == "[" then
					self.blockcomment = true
				elseif char == "#" then
					singlelinecomment = true
				end
			elseif self.multilinestring and char == '"' then
				local escapecount = 0
				while pos - escapecount - 1 > 0 and string_sub( str, pos - escapecount - 1, pos - escapecount -1 ) == "\\" do
					escapecount = escapecount + 1
				end
				if escapecount % 2 == 0 then
					self.multilinestring = nil
				end
			elseif self.blockcomment and char == "#" and string_sub( str, pos - 1, pos - 1  ) == "]" then
				self.blockcomment = nil
			elseif singlelinecomment and char == "\n" then
				singlelinecomment = false
			end
		end
	end


	for k,v in pairs( self.e2fs_functions ) do
		if v == row then
			self.e2fs_functions[k] = nil
		end
	end
end

function EDITOR:SyntaxColorLine(row)
	cols,lastcol = {}, nil


	self:ResetTokenizer(row)
	self:NextCharacter()

	-- 0=name 1=port 2=trigger 3=foreach 4=foreachkey 5=foreachvalue
	local highlightmode = nil

	if self.blockcomment then
		if self:NextPattern(".-]#") then
			self.blockcomment = nil
		else
			self:NextPattern(".*")
		end

		addToken("comment", self.tokendata)
	elseif self.multilinestring then
		while self.character do -- Find the ending "
			if self.character == '"' then
				self.multilinestring = nil
				self:NextCharacter()
				break
			end
			if self.character == "\\" then self:NextCharacter() end
			self:NextCharacter()
		end

		addToken("string", self.tokendata)
	elseif self:NextPattern("^@[^ ]*") then
		highlightmode = directives[self.tokendata]

		-- check for unknown directives
		if not highlightmode then
			return {
				{ "@", colors.directive },
				{ self.line:sub(2), colors.notfound }
			}
		end

		-- check for plain text directives
		if highlightmode == 0 then return {{ self.line, colors.directive }} end

		-- parse the rest like regular code
		cols = {{ self.tokendata, colors.directive }}
	end

	local found = self:SkipPattern( "( *function)" )
	if found then
		addToken( "keyword", found ) -- Add "function"
		self.tokendata = "" -- Reset tokendata

		local spaces = self:SkipPattern( " *" )
		if spaces then addToken( "comment", spaces ) end

		if self:NextPattern( "[a-z][a-zA-Z0-9]*%s%s*[a-z][a-zA-Z0-9]*:[a-z][a-zA-Z0-9_]*" ) then -- Everything specified (returntype typeindex:funcname)
			local returntype, spaces, typeindex, funcname = self.tokendata:match( "([a-z][a-zA-Z0-9]*)(%s%s*)([a-z][a-zA-Z0-9]*):([a-z][a-zA-Z0-9_]*)" )

			if istype( returntype ) or returntype == "void" then
				addToken( "typename", returntype )
			else
				addToken( "notfound", returntype )
			end
			addToken( "comment", spaces )
			if istype( typeindex ) then
				addToken( "typename", typeindex )
			else
				addToken( "notfound", typeindex )
			end
			addToken( "operator", ":" )
			addToken( "userfunction", funcname )

			if not wire_expression2_funclist[funcname] then
				self.e2fs_functions[funcname] = row
			end

			self.tokendata = ""
		elseif self:NextPattern( "[a-z][a-zA-Z0-9]*%s%s*[a-z][a-zA-Z0-9_]*" ) then -- returntype funcname
			local returntype, spaces, funcname = self.tokendata:match( "([a-z][a-zA-Z0-9]*)(%s%s*)([a-z][a-zA-Z0-9_]*)" )

			if istype( returntype ) or returntype == "void" then
				addToken( "typename", returntype )
			else
				addToken( "notfound", returntype )
			end
			addToken( "comment", spaces )
			addToken( "userfunction", funcname )

			if not wire_expression2_funclist[funcname] then
				self.e2fs_functions[funcname] = row
			end

			self.tokendata = ""
		elseif self:NextPattern( "[a-z][a-zA-Z0-9]*:[a-z][a-zA-Z0-9_]*" ) then -- typeindex:funcname
			local typeindex, funcname = self.tokendata:match( "([a-z][a-zA-Z0-9]*):([a-z][a-zA-Z0-9_]*)" )

			if istype( typeindex ) then
				addToken( "typename", typeindex )
			else
				addToken( "notfound", typeindex )
			end
			addToken( "operator", ":" )
			addToken( "userfunction", funcname )

			if not wire_expression2_funclist[funcname] then
				self.e2fs_functions[funcname] = row
			end

			self.tokendata = ""
		elseif self:NextPattern( "[a-z][a-zA-Z0-9_]*" ) then -- funcname
			local funcname = self.tokendata:match( "[a-z][a-zA-Z0-9_]*" )

			addToken( "userfunction", funcname )

			if not wire_expression2_funclist[funcname] then
				self.e2fs_functions[funcname] = row
			end

			self.tokendata = ""
		end

		if self:NextPattern( "%(" ) then -- We found a bracket
			-- Color the bracket
			addToken( "operator", self.tokendata )

			while self.character and self.character ~= ")" do -- Loop until the ending bracket
				self.tokendata = ""

				local spaces = self:SkipPattern( " *" )
				if spaces then addToken( "comment", spaces ) end

				-- Exception for the spread "..." operator
				local dots = self:SkipPattern( "%.%.%." )
				if dots then addToken( "operator", dots ) end

				local invalidInput = self:SkipPattern( "[^A-Z:%[_]*" )
				if invalidInput then addToken( "notfound", invalidInput ) end

				if self:NextPattern( "%[" ) then -- Found a [
					-- Color the bracket
					addToken( "operator", self.tokendata )
					self.tokendata = ""

					while acceptIdent(self) do -- If we found a variable
						addToken( "variable", self.tokendata )
						self.tokendata = ""

						local spaces = self:SkipPattern( " *" )
						if spaces then addToken( "comment", spaces ) end
					end

					if self:NextPattern( "%]" ) then
						addToken( "operator", "]" )
						self.tokendata = ""
					end
				elseif acceptIdent(self) then -- If we found a variable
					-- Color the variable
					addToken( "variable", self.tokendata )
					self.tokendata = ""
				end

				if self:NextPattern( ":" ) then -- Check for the colon
					addToken( "operator", ":" )
					self.tokendata = ""
				end

				-- Find the type
				if self:NextPattern( "[a-z][a-zA-Z0-9_]*" ) then
					if istype( self.tokendata ) or self.tokendata == "void" then -- If it's a type
						addToken( "typename", self.tokendata )
					else -- aww
						addToken( "notfound", self.tokendata )
					end
				end

				local spaces = self:SkipPattern( " *" )
				if spaces then addToken( "comment", spaces ) end

				-- If we found a comma, skip it
				if self.character == "," then addToken( "operator", "," ) self:NextCharacter() end
			end
		end

		self.tokendata = ""
		if self:NextPattern( "%) *{?" ) then -- check for ending bracket (and perhaps an ending {?)
			addToken( "operator", self.tokendata )
		end
	end

	local found = self:SkipPattern("( *event)")
	if found then
		addToken( "keyword", found ) -- Add "event"
		self.tokendata = "" -- Reset tokendata

		local spaces = self:SkipPattern( " *" )
		if spaces then addToken( "comment", spaces ) end

		if self:NextPattern( "%w+" ) then -- event <name>
			local eventname = self.tokendata:match( "%w+" )
			addToken("eventname", eventname)

			self.tokendata = ""
		end

		if self:NextPattern( "%(" ) then -- We found a bracket
			addToken( "operator", self.tokendata )

			while self.character and self.character ~= ")" do -- Loop until the ending bracket
				self.tokendata = ""

				local spaces = self:SkipPattern( " *" )
				if spaces then addToken( "comment", spaces ) end

				-- Exception for the spread "..." operator
				local dots = self:SkipPattern( "%.%.%." )
				if dots then addToken( "operator", dots ) end

				local invalidInput = self:SkipPattern( "[^A-Z:%[_]*" )
				if invalidInput then addToken( "notfound", invalidInput ) end

				if self:NextPattern( "%[" ) then -- Found a [
					-- Color the bracket
					addToken( "operator", self.tokendata )
					self.tokendata = ""

					while acceptIdent(self) do -- If we found a variable
						addToken( "variable", self.tokendata )
						self.tokendata = ""

						local spaces = self:SkipPattern( " *" )
						if spaces then addToken( "comment", spaces ) end
					end

					if self:NextPattern( "%]" ) then
						addToken( "operator", "]" )
						self.tokendata = ""
					end
				elseif acceptIdent(self) then -- If we found a variable
					-- Color the variable
					addToken( "variable", self.tokendata )
					self.tokendata = ""
				end

				if self:NextPattern( ":" ) then -- Check for the colon
					addToken( "operator", ":" )
					self.tokendata = ""
				end

				-- Find the type
				if self:NextPattern( "[a-z][a-zA-Z0-9_]*" ) then
					if istype( self.tokendata ) or self.tokendata == "void" then -- If it's a type
						addToken( "typename", self.tokendata )
					else -- aww
						addToken( "notfound", self.tokendata )
					end
				end

				local spaces = self:SkipPattern( " *" )
				if spaces then addToken( "comment", spaces ) end

				-- If we found a comma, skip it
				if self.character == "," then addToken( "operator", "," ) self:NextCharacter() end
			end
		end

		self.tokendata = ""
		if self:NextPattern( "%) *{?" ) then -- check for ending bracket (and perhaps an ending {?)
			addToken( "operator", self.tokendata )
		end
	end

	local found = self:SkipPattern("(} *)")
	if found then
		addToken("operator", found)
		self.tokendata = ""
	end

	local found = self:SkipPattern("( *catch)")
	if found then
		addToken("keyword", found)
		self.tokendata = ""
		addOptional(self, " *", "comment")

		if self:NextPattern("%(") then
			addToken("operator", self.tokendata)
			self.tokendata = ""
			addOptional(self, " *", "comment")

			if acceptIdent(self) then
				addToken("variable", self.tokendata)
				self.tokendata = ""
				addOptional(self, " *", "comment")

				if self:NextPattern(":") then
					addToken("operator", self.tokendata)
					self.tokendata = ""
					addOptional(self, " *", "comment")
					self.tokendata = ""

					if self:NextPattern("[a-z][a-zA-Z0-9_]*") then
						addToken("typename", self.tokendata)
					end
				end
			end
		end
	end

	while self.character do
		local tokenname = ""
		self.tokendata = ""

		-- eat all spaces
		local spaces = self:SkipPattern(" *")
		if spaces then addToken("operator", spaces) end
		if not self.character then break end

		-- eat next token
		if self:NextPattern("^_[A-Z][A-Z_0-9]*") then
			local word = self.tokendata
			for k in pairs( wire_expression2_constants ) do
				if k == word then
					tokenname = "constant"
				end
			end
			if tokenname == "" then tokenname = "notfound" end
		elseif self:NextPattern("^0[xb][0-9A-F]+") then
			tokenname = "number"
		elseif self:NextPattern("^[0-9][0-9.e]*") then
			tokenname = "number"

		elseif self:NextPattern("^[a-z][a-zA-Z0-9_]*") then
			local sstr = self.tokendata
			if highlightmode then
				if highlightmode == 1 and istype(sstr) then
					tokenname = "typename"
				elseif highlightmode == 2 and (sstr == "all" or sstr == "none") then
					tokenname = "directive"
				elseif (highlightmode == 4 or highlightmode == 5) and istype(sstr) then
					tokenname = "typename"

					if highlightmode == 5 then
						highlightmode = nil
					end
				else
					tokenname = "notfound"
				end
			else
				-- is this a keyword or a function?
				local char = self.character or ""
				local keyword = char ~= "("

				local spaces = self:SkipPattern(" *") or ""

				if self.character == "]" then
					-- X[Y,typename]
					tokenname = istype(sstr) and "typename" or "notfound"
				elseif keywords[sstr][keyword] then
					tokenname = "keyword"
					if sstr == "foreach" or sstr == "function" then
						highlightmode = 3
					elseif sstr == "return" and self:NextPattern( "void" ) then
						addToken( "keyword", "return" )
						tokenname = "typename"
						self.tokendata = spaces .. "void"
						spaces = ""
					end
				elseif wire_expression2_funclist[sstr] then
					tokenname = "function"

				elseif self.e2fs_functions[sstr] or self.e2fs_methods[sstr] then
					tokenname = "userfunction"

				else
					tokenname = "notfound"

					local correctName = wire_expression2_funclist_lowercase[sstr:lower()]
					if correctName then
						self.tokendata = ""
						for i = 1,#sstr do
							local c = sstr:sub(i,i)
							if correctName:sub(i,i) == c then
								tokenname = "function"
							else
								tokenname = "notfound"
							end
							if i == #sstr then
								self.tokendata = c
							else
								addToken(tokenname, c)
							end
						end
					end
				end
				addToken(tokenname, self.tokendata)
				tokenname = "operator"
				self.tokendata = spaces
			end

		elseif acceptIdent(self) then
			if self.tokendata == "This" then
				tokenname = "typename"
			else
				tokenname = "variable"
			end

			if highlightmode == 3 then
				highlightmode = 4
			elseif highlightmode == 4 then
				highlightmode = 5
			end
		elseif self.character == '"' then
			self:NextCharacter()
			while self.character do -- Find the ending "
				if self.character == '"' then
					tokenname = "string"
					break
				end
				if self.character == "\\" then self:NextCharacter() end
				self:NextCharacter()
			end

			if tokenname == "" then -- If no ending " was found...
				self.multilinestring = true
				tokenname = "string"
			else
				self:NextCharacter()
			end

		elseif self.character == "#" then
			self:NextCharacter()
			if self.character == "[" then -- Check if there is a [ directly after the #
				while self.character do -- Find the ending ]
					if self.character == "]" then
						self:NextCharacter()
						if self.character == "#" then -- Check if there is a # directly after the ending ]
							tokenname = "comment"
							break
						end
					end
					if self.character == "\\" then self:NextCharacter() end
					self:NextCharacter()
				end
				if tokenname == "" then -- If no ending ]# was found...
					self.blockcomment = true
					tokenname = "comment"
				else
					self:NextCharacter()
				end
			end

			if tokenname == "" then

				self:NextPattern("[^ ]*") -- Find the whole word

				if E2Lib.PreProcessor["PP_"..self.tokendata:sub(2)] then
					-- there is a preprocessor command by that name => mark as such
					addToken("ppcommand", self.tokendata)
					self.tokendata = ""

					self:NextPattern(".*")
					tokenname = "ppcommandargs"
				elseif self.tokendata == "#include" then
					tokenname = "keyword"
				else
					-- eat the rest and mark as a comment
					self:NextPattern(".*")
					tokenname = "comment"
				end

			end
		else
			self:NextCharacter()

			tokenname = "operator"
		end

		addToken(tokenname, self.tokendata)
	end

	return cols
end

WireTextEditor.Modes.E2 = EDITOR
