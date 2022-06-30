local table_ForceInsert = table.ForceInsert
local string_gmatch = string.gmatch
local string_byte = string.byte
local string_lower = string.lower
local string_upper = string.upper
local string_PatternSafe = string.PatternSafe
local math_min = math.min
local table_sort = table.sort
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextPos = surface.SetTextPos
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local utf8_sub = utf8.sub
local utf8_GetChar = utf8.GetChar
local utf8_codes = utf8.codes
local utf8_char = utf8.char

local utf8_len = utf8.len_checked
local utf8_bytepos_to_charindex = utf8.bytepos_to_charindex
local utf8_reverse = utf8.reverse

---------------------------------------------------------------------------------------------------------
-- Auto Completion
-- By Divran
-- Sligthly refactored by stpM64
---------------------------------------------------------------------------------------------------------


local wire_expression2_autocomplete_controlstyle = CreateClientConVar( "wire_expression2_autocomplete_controlstyle", "0", true, false )

local AC_STYLE_DEFAULT = 0 -- Default style - Tab/CTRL+Tab to choose item;\nEnter/Space to use;\nArrow keys to abort.
local AC_STYLE_VISUALCSHARP = 1 -- Visual C# Style - Ctrl+Space to use the top match;\nArrow keys to choose item;\nTab/Enter/Space to use;\nCode validation hotkey (ctrl+space) moved to ctrl+b.
local AC_STYLE_SCROLLER = 2 -- Scroller style - Mouse scroller to choose item;\nMiddle mouse to use.
local AC_STYLE_SCROLLER_ENTER = 3 -- Scroller Style w/ Enter - Mouse scroller to choose item;\nEnter to use.
local AC_STYLE_ECLIPSE = 4 -- Eclipse Style - Enter to use top match;\nTab to enter auto completion menu;\nArrow keys to choose item;\nEnter to use;\nSpace to abort.
local AC_STYLE_ATOM = 5 -- Atom style - Tab/Enter to use, arrow keys to choose




local EDITOR = vgui.GetControlTable("Expression2Editor")
assert(EDITOR ~= nil)

function EDITOR:IsVarLine()
	local line = self.Rows[self.Caret[1]]
	local word = line:match( "^@(%w+)" )
	return word == "inputs" or word == "outputs" or word == "persist"
end

function EDITOR:IsDirectiveLine()
	local line = self.Rows[self.Caret[1]]
	return line:match( "^@" ) ~= nil
end

-----------------------------------------------------------
-- GetCurrentWord
-- Gets the word the cursor is currently at, and the symbol in front
-----------------------------------------------------------

function EDITOR:AC_GetCurrentWord()
	local startpos, word = self:getWordStart( self.Caret, true )
	local symbolinfront = self:GetArea( { { startpos[1], startpos[2] - 1}, startpos } )
	return word, symbolinfront
end

-- Thank you http://lua-users.org/lists/lua-l/2009-07/msg00461.html
-- Returns the minimum number of character changes required to make one of the words equal the other
-- Used to sort the suggestions in order of relevance
local function CheckDifference( word1, word2 )
	local d, sn, tn = {}, #word1, #word2
	local byte, min = string_byte, math_min
	for i = 0, sn do d[i * tn] = i end
	for j = 0, tn do d[j] = j end
	for i = 1, sn do
		local si = byte(word1, i)
		for j = 1, tn do
			d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(word2,j) and 0 or 1))
		end
	end
	return d[#d]
end

-----------------------------------------------------------
-- NewAutoCompletion
-- Sets the autocompletion table
-----------------------------------------------------------

function EDITOR:AC_NewAutoCompletion( tbl )
	self.AC_AutoCompletion = tbl
end

local tbl = {}

-----------------------------------------------------------
-- FindConstants
-- Adds all matching constants to the suggestions table
-----------------------------------------------------------

local function GetTableForConstant( str )
	return { nice_str = function( t ) return t.data[1] end,
			str = function( t ) return t.data[1] end,
			replacement = function( t ) return t.data[1] end,
			data = { str } }
end

local function FindConstants( self, word )
	local len = utf8_len(word)
	local wordu = word:upper()
	local count = 0

	local suggestions = {}

	for name, _ in pairs( wire_expression2_constants ) do
		if utf8_sub(name, 1,len) == wordu then
			count = count + 1
			suggestions[count] = GetTableForConstant( name )
		end
	end

	return suggestions
end

tbl[1] = function( self )
	local word = self:AC_GetCurrentWord()
	if word and word ~= "" and word[1] == "_" then
		return FindConstants( self, word )
	end
end

--------------------
-- FindFunctions
-- Adds all matching functions to the suggestions table
--------------------
do

	local function_tree = {}

	local function GenerateFunctionTree()
		for fn_name,_ in pairs( wire_expression2_funcs ) do
			local current = function_tree


			for _, fn_name_char_cp in utf8_codes(fn_name) do
				local fn_name_char = string_lower(utf8_char(fn_name_char_cp))

				local current2 = current[fn_name_char] or {}
				current[fn_name_char] = current2
				current = current2
			end

			local entry = {}
			function entry:nice_str() return self.data[2] end
			function entry:str() return self.data[1] end
			function entry:replacement(editor)
				local caret = editor:CopyPosition( editor.Caret )
				caret[2] = caret[2] - 1
				local wordend = editor:getWordEnd( caret )
				local has_bracket = editor:GetArea( { wordend, { wordend[1], wordend[2] } } ) == "("
				-- If there already is a bracket, we don't want to add more of them.
				local ret = self:str()
				return ret..(has_bracket and "" or "()"), utf8_len(ret)+1
			end
			function entry:description()
				if self.data[3] and E2Helper.Descriptions[self.data[3]] then
					return E2Helper.Descriptions[self.data[3]]
				end
				if self.data[1] and E2Helper.Descriptions[self.data[1]] then
					return E2Helper.Descriptions[self.data[1]]
				end
			end

			local name, types = fn_name:match( "(.+)(%b())" ) -- Get the function name and types
			local type_1, type_2, type_3 = types:match( "%((%w*)(:?)(.*)%)" ) -- Sort the function types

			local ac_name_full

			if type_2 == ":" then
				ac_name_full = string_upper(type_1)..":"..name.."("..string_upper(type_3)..")"
			else
				ac_name_full = name.."("..string_upper(type_1)..")"
			end

			entry.data = {
				name,
				ac_name_full,
				fn_name
			}

			entry.has_colon = type_2 == ":"

			current.FUNC = table_ForceInsert(current.FUNC, entry)
		end
	end

	hook.Add("InitPostEntity", "Wiremod_E2_Editor", GenerateFunctionTree)
	hook.Add("OnReloaded", "Wiremod_E2_Editor", function()
		function_tree = {}
		GenerateFunctionTree()
	end)

	if E2_RELOAD_EDITOR then
		GenerateFunctionTree()
	end

	local function GetFunctionTreeBranch(word)
		local current = function_tree

		for _, char_cp in utf8_codes(word) do
			local char = string_lower(utf8_char(char_cp))
			current = current[char]
			if current == nil then return nil end
		end

		return current
	end

	local function FlattenTreeRecursive(tree_branch, dest)
		if tree_branch.FUNC ~= nil then
			table.Add(dest, tree_branch.FUNC)
		end

		for key, value in SortedPairs(tree_branch) do
			if key ~= "FUNC" then
				FlattenTreeRecursive(value, dest)
			end
		end
	end

	local function FindFunctions(self, has_colon, word)
		local branch = GetFunctionTreeBranch(string_PatternSafe(word))

		if branch == nil then
			return nil
		end

		local suggestions_raw = {}
		FlattenTreeRecursive(branch, suggestions_raw)

		local suggestions = {}
		local suggestion_extras_by_name = {}

		for _, suggestion in ipairs(suggestions_raw) do
			local name = suggestion:str()

			if suggestion_extras_by_name[name] == nil then
				suggestion_extras_by_name[name] = {}

				suggestion.others = function(sugg) return suggestion_extras_by_name[name] end

				table.insert(suggestions, suggestion)
			else
				suggestion.others = function(sugg) return nil end
				table.insert(suggestion_extras_by_name[name], suggestion)
			end
		end

		return suggestions
	end

	tbl[2] = function( self )
		local word, symbolinfront = self:AC_GetCurrentWord()
		if word and word ~= "" and utf8_GetChar(word,1):upper() ~= utf8_GetChar(word,1) then
			return FindFunctions( self, symbolinfront == ":", word )
		end
	end
end
-----------------------------------------------------------
-- SaveVariables
-- Saves all variables to a table
-----------------------------------------------------------

function EDITOR:AC_SaveVariables()
	local OK, directives, _ = E2Lib.PreProcessor.Execute( self:GetValue() )

	if not OK or not directives then
		return
	end

	self.AC_Directives = directives
end


-----------------------------------------------------------
-- FindVariables
-- Adds all matching variables to the suggestions table
-----------------------------------------------------------

local function GetTableForVariables( str )
	return { nice_str = function( t ) return t.data[1] end,
			str = function( t ) return t.data[1] end,
			replacement = function( t ) return t.data[1] end,
			data = { str } }
end


local function FindVariables( self, word )
	local len = utf8_len(word)
	local wordl = word:lower()
	local count = 0

	local suggested = {}
	local suggestions = {}

	local directives = self.AC_Directives
	if not directives then self:AC_SaveVariables() end -- If directives is nil, attempt to find
	directives = self.AC_Directives
	if not directives then -- If finding failed, abort
		self:AC_SetVisible( false )
		return
	end

	for _, v in pairs( directives["inputs"][1] ) do
		if utf8_sub(v:lower(),1,len) == wordl then
			if not suggested[v] then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	for _, v in pairs( directives["outputs"][1] ) do
		if utf8_sub(v:lower(), 1,len) == wordl then
			if not suggested[v] then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	for _, v in pairs( directives["persist"][1] ) do
		if utf8_sub(v:lower(),1,len) == wordl then
			if not suggested[v] then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	return suggestions
end

tbl[3] = function( self )
	local word = self:AC_GetCurrentWord()
	if word and word ~= "" and utf8_GetChar(word, 1):upper() == utf8_GetChar(word, 1) then
		return FindVariables( self, word )
	end
end

local wire_expression2_autocomplete = CreateClientConVar( "wire_expression2_autocomplete", "1", true, false )
tbl.RunOnCheck = function( self )
	-- Only autocomplete if it's the E2 editor, if it's enabled
	if not self:GetParent().E2 or not wire_expression2_autocomplete:GetBool() then
		self:AC_SetVisible( false )
		return false
	end

	local caret = self:CopyPosition(self.Caret)
	local tokenname = self:GetTokenAtPosition(caret)

	if tokenname and (tokenname == "string" or tokenname == "comment") then
		caret[2] = caret[2] - 1
		tokenname = self:GetTokenAtPosition(caret)

		if tokenname and (tokenname == "string" or tokenname == "comment") then
			self:AC_SetVisible(false)
			return false
		end
	end

	if self:IsVarLine() and not self.AC_WasVarLine then -- If the user IS editing a var line, and they WEREN'T editing a var line before this..
		self.AC_WasVarLine = true
	elseif not self:IsVarLine() and self.AC_WasVarLine then -- If the user ISN'T editing a var line, and they WERE editing a var line before this..
		self.AC_WasVarLine = nil
		self:AC_SaveVariables()
	end
	if self:IsDirectiveLine() then -- In case you're wondering, DirectiveLine ~= VarLine (A directive line is any line starting with @, a var line is @inputs, @outputs, and @persists)
		self:AC_SetVisible( false )
		return false
	end

	return true
end


-----------------------------------------------------------
-- Check
-- Runs the autocompletion
-----------------------------------------------------------

function EDITOR:AC_Check( notimer )

	if not notimer then
		timer.Create("E2_AC_Check", 0, 1, function()
			if self.AC_Check then self:AC_Check(true) end
		end)
		return
	end

	if not self.AC_AutoCompletion then self:AC_NewAutoCompletion( tbl ) end -- Default to E2 autocompletion
	if not self.AC_Panel then self:AC_CreatePanel() end
	if self.AC_AutoCompletion.RunOnCheck then
		local ret = self.AC_AutoCompletion.RunOnCheck( self )
		if ret == false then
			return
		end
	end

	self.AC_Suggestions = {}
	self.AC_HasSuggestions = false

	local suggestions = {}
	for i=1,#self.AC_AutoCompletion do
		local _suggestions = self.AC_AutoCompletion[i]( self )
		if _suggestions ~= nil and #_suggestions > 0 then
			suggestions = _suggestions
			break
		end
	end

	if #suggestions > 0 then

		local word, _ = self:AC_GetCurrentWord()

		table_sort( suggestions, function( a, b )
			local diff1 = CheckDifference( word, a.str( a ) )
			local diff2 = CheckDifference( word, b.str( b ) )
			return diff1 < diff2
		end)

		if word == suggestions[1].str( suggestions[1] ) and #suggestions == 1 then -- The word matches the first suggestion exactly, and there are no more suggestions. No need to bother displaying
			self:AC_SetVisible( false )
			return
		end

		for i=1,10 do
			self.AC_Suggestions[i] = suggestions[i]
		end
		self.AC_HasSuggestions = true

		-- Show the panel
		local panel = self.AC_Panel
		self:AC_SetVisible( true )

		-- Calculate its position
		local caret = self:CopyPosition( self.Caret )
		caret[2] = caret[2] - 1
		local wordstart = self:getWordStart( caret )

		local x = self.FontWidth * (wordstart[2] - self.Scroll[2] + 1) + 22
		local y = self.FontHeight * (wordstart[1] - self.Scroll[1] + 1) + 2

		panel:SetPos( x, y )

		-- Fill the list
		self:AC_FillList()
		return
	end

	self:AC_SetVisible( false )
end

-----------------------------------------------------------
-- Use
-- Replaces the word
-----------------------------------------------------------
local wire_expression2_autocomplete_highlight_after_use = CreateClientConVar("wire_expression2_autocomplete_highlight_after_use","1",true,false)
function EDITOR:AC_Use( suggestion )
	if not suggestion then return false end
	local ret = false

	-- Get word position
	local wordstart = self:getWordStart( self.Caret )
	local wordend = self:getWordEnd( self.Caret )

	-- Get replacement
	local replacement, caretoffset = suggestion:replacement( self )

	-- Check if anything needs changing
	local selection = self:GetArea( { wordstart, wordend } )
	if selection == replacement then -- There's no point in doing anything.
		return false
	end

	-- Overwrite selection
	if replacement and replacement ~= "" then
		self:SetArea( { wordstart, wordend }, replacement )

		-- Move caret
		if caretoffset then
			self.Start = { wordstart[1], wordstart[2] + caretoffset }
			self.Caret = { wordstart[1], wordstart[2] + caretoffset }
		else
			if wire_expression2_autocomplete_highlight_after_use:GetBool() then
				self.Start = wordstart
				self.Caret = {wordstart[1],wordstart[2]+#replacement}
			else
				self.Start = { wordstart[1],wordstart[2]+#replacement }
				self.Caret = { wordstart[1],wordstart[2]+#replacement }
			end
		end
		ret = true
	end

	self:ScrollCaret()

	self:RequestFocus()
	self.AC_HasSuggestion = false
	return ret
end

-----------------------------------------------------------
-- CreatePanel
-----------------------------------------------------------

function EDITOR:AC_CreatePanel()
	-- Create the panel
	local panel = vgui.Create( "DPanel",self )
	panel:SetSize( 100, 202 )
	panel.Selected = {}
	panel.Paint = function( pnl )
		surface_SetDrawColor( 0,0,0,230 )
		surface_DrawRect( 0,0,pnl:GetWide(), pnl:GetTall() )
	end

	-- Override think, to make it listen for key presses
	panel.Think = function( pnl, code )
		if not self.AC_HasSuggestions or not self.AC_Panel_Visible then return end

		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if mode == AC_STYLE_DEFAULT then

			if input.IsKeyDown( KEY_ENTER ) or input.IsKeyDown( KEY_SPACE ) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif input.IsKeyDown( KEY_TAB ) and not pnl.AlreadySelected then -- Select
				if input.IsKeyDown( KEY_LCONTROL ) then -- If control is held down
					pnl.Selected = pnl.Selected - 1 -- Scroll up
					if pnl.Selected < 1 then pnl.Selected = #self.AC_Suggestions end
				else -- If control isn't held down
					pnl.Selected = pnl.Selected + 1 -- Scroll down
					if pnl.Selected > #self.AC_Suggestions then pnl.Selected = 1 end
				end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl:RequestFocus()
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif pnl.AlreadySelected and not input.IsKeyDown( KEY_TAB ) then
				pnl.AlreadySelected = nil
			elseif input.IsKeyDown( KEY_UP ) or input.IsKeyDown( KEY_DOWN ) or input.IsKeyDown( KEY_LEFT ) or input.IsKeyDown( KEY_RIGHT ) then
				self:AC_SetVisible( false )
			end
		elseif mode == AC_STYLE_VISUALCSHARP or mode == AC_STYLE_ATOM then

			if input.IsKeyDown( KEY_TAB ) or input.IsKeyDown( KEY_ENTER ) or input.IsKeyDown( KEY_SPACE ) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif input.IsKeyDown( KEY_DOWN ) and not pnl.AlreadySelected then -- Select
				pnl.Selected = pnl.Selected + 1 -- Scroll down
				if pnl.Selected > #self.AC_Suggestions then pnl.Selected = 1 end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif input.IsKeyDown( KEY_UP ) and not pnl.AlreadySelected then -- Select
				pnl.Selected = pnl.Selected - 1 -- Scroll up
				if pnl.Selected < 1 then pnl.Selected = #self.AC_Suggestions end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif pnl.AlreadySelected and not input.IsKeyDown( KEY_UP ) and not input.IsKeyDown( KEY_DOWN ) then
				pnl.AlreadySelected = nil
			end

		elseif mode == AC_STYLE_SCROLLER then

			if input.IsMouseDown( MOUSE_MIDDLE ) then
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			end

		elseif mode == AC_STYLE_SCROLLER_ENTER then

			if input.IsKeyDown( KEY_ENTER ) then
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			end

		elseif mode == AC_STYLE_ECLIPSE then

			if input.IsKeyDown( KEY_ENTER ) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif input.IsKeyDown( KEY_SPACE ) then
				self:AC_SetVisible( false )
			elseif input.IsKeyDown( KEY_DOWN ) and not pnl.AlreadySelected then -- Select
				pnl.Selected = pnl.Selected + 1 -- Scroll down
				if pnl.Selected > #self.AC_Suggestions then pnl.Selected = 1 end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif input.IsKeyDown( KEY_UP ) and not pnl.AlreadySelected then -- Select
				pnl.Selected = pnl.Selected - 1 -- Scroll up
				if pnl.Selected < 1 then pnl.Selected = #self.AC_Suggestions end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif pnl.AlreadySelected and not input.IsKeyDown( KEY_UP ) and not input.IsKeyDown( KEY_DOWN ) then
				pnl.AlreadySelected = nil
			end

		end
	end

	-- Create list
	local list = vgui.Create( "DPanelList", panel )
	list:StretchToParent( 1,1,1,1 )
	list.Paint = function() end

	-- Create info list
	local infolist = vgui.Create( "DPanelList", panel )
	infolist:SetPos( 1000, 1000 )
	infolist:SetSize( 100, 200 )
	infolist:EnableVerticalScrollbar( true )
	infolist.Paint = function() end

	self.AC_Panel = panel
	panel.list = list
	panel.infolist = infolist
	self:AC_SetVisible( false )
end


-----------------------------------------------------------
-- FillInfoList
-- Fills the "additional information" box
-----------------------------------------------------------

local wire_expression2_autocomplete_moreinfo = CreateClientConVar( "wire_expression2_autocomplete_moreinfo", "1", true, false )

local function SimpleWrap( txt, width )
	local ret = ""

	local prev_end, prev_newline = 0, 0
	for cur_end in string_gmatch(txt, "[^ \n]+()") do
		local w, _ = surface_GetTextSize( txt:sub( prev_newline, cur_end ) )
		if w > width then
			ret = ret .. txt:sub( prev_newline, prev_end ) .. "\n"
			prev_newline = prev_end + 1
		end
		prev_end = cur_end
	end
	ret = ret .. txt:sub( prev_newline )

	return ret
end

function EDITOR:AC_FillInfoList( suggestion )
	local panel = self.AC_Panel

	if not suggestion or not suggestion.description or not wire_expression2_autocomplete_moreinfo:GetBool() then -- If the suggestion is invalid, the suggestion does not need additional information, or if the user has disabled additional information, abort
		panel:SetSize( panel.curw, panel.curh )
		panel.infolist:SetPos( 1000, 1000 )
		return
	end

	local infolist = panel.infolist
	infolist:Clear()

	local desc_label = vgui.Create("DLabel")
	infolist:AddItem( desc_label )

	local desc = suggestion:description( self )

	local maxw = 164
	local maxh = 0

	local others
	if suggestion.others then others = suggestion:others( self ) end

	if desc and desc ~= "" then
		desc = "Description:\n" .. desc
	end

	if #others > 0 then -- If there are other functions with the same name...
		desc = (desc or "") .. ((desc and desc ~= "") and "\n" or "") .. "Others with the same name:"

		-- Loop through the "others" table to add all of them
		surface_SetFont(self.CurrentFont)
		for _, v in pairs( others ) do
			local nice_name = v:nice_str( self )

			local namew, nameh = surface_GetTextSize( nice_name )

			local label = vgui.Create("DLabel")
			label:SetText( "" )
			label.Paint = function( pnl )
				local w,h = pnl:GetSize()
				surface_SetDrawColor(65, 105, 255)
				surface_DrawRect(0, 0, w, h)
				surface_SetFont(self.CurrentFont)
				surface_SetTextPos( 6, h/2-nameh/2 )
				surface_SetTextColor( 255,255,255,255 )
				surface_DrawText( nice_name )
			end

			infolist:AddItem( label )

			if namew + 15 > maxw then maxw = namew + 15 end
			maxh = maxh + 20
		end
	end

	if not desc or desc == "" then
		panel:SetSize( panel.curw, panel.curh )
		infolist:SetPos( 1000, 1000 )
		return
	end

	-- Wrap the text, set it, and calculate size
	desc = SimpleWrap( desc, maxw )
	desc_label:SetText( desc )
	desc_label:SizeToContents()
	local _, texth = surface_GetTextSize( desc )

	-- If it's bigger than the size of the panel, change it
	if panel.curh < texth + 4 then panel:SetTall( texth + 6 ) else panel:SetTall( panel.curh ) end
	if maxh + texth > panel:GetTall() then maxw = maxw + 25 end

	-- Set other positions/sizes/etc
	panel:SetWide( panel.curw + maxw )
	infolist:SetPos( panel.curw, 1 )
	infolist:SetSize( maxw - 1, panel:GetTall() - 2 )
end


-----------------------------------------------------------
-- FillList
-----------------------------------------------------------

function EDITOR:AC_FillList()
	local panel = self.AC_Panel
	panel.list:Clear()
	panel.Selected = 0
	local maxw = 15

	surface.SetFont(self.CurrentFont)

	-- Add all suggestions to the list
	for count,suggestion in pairs( self.AC_Suggestions ) do
		local nice_name = suggestion:nice_str( self )

		local txt = vgui.Create("DLabel")
		txt:SetText( "" )
		txt.count = count
		txt.suggestion = suggestion

		-- Override paint to give it the "E2 theme" and to make it highlight when selected
		txt.Paint = function( pnl, w, h )
			local backgroundColor
			if panel.Selected == pnl.count then
				backgroundColor = Color(49, 80, 169, 192)
			else
				backgroundColor = Color(65, 105, 225, 255)
			end
			surface_SetDrawColor(backgroundColor)
			surface_DrawRect(0, 0, w, h)

			surface.SetFont(self.CurrentFont)
			local _, h2 = surface.GetTextSize( nice_name )

			surface.SetTextPos( 6, (h / 2) - (h2 / 2) )
			surface.SetTextColor( 255,255,255,255 )
			surface.DrawText( nice_name )
		end

		-- Enable mouse presses
		txt.OnMousePressed = function( pnl, code )
			if code == MOUSE_LEFT then
				self:AC_SetVisible( false )
				self:AC_Use( pnl.suggestion )
			end
		end

		-- Enable mouse hovering
		txt.OnCursorEntered = function( pnl )
			panel.Selected = pnl.count
			self:AC_FillInfoList( pnl.suggestion )
		end

		panel.list:AddItem( txt )

		-- get the width of the widest suggestion
		local w,_ = surface_GetTextSize( nice_name )
		w = w + 15
		if w > maxw then maxw = w end
	end

	-- Size and positions etc
	panel:SetSize( maxw, #self.AC_Suggestions * 20 + 2 )
	panel.curw = maxw
	panel.curh = #self.AC_Suggestions * 20 + 2
	panel.list:StretchToParent( 1,1,1,1 )
	panel.infolist:SetPos( 1000, 1000 )
end

-----------------------------------------------------------
-- SetVisible
-----------------------------------------------------------

function EDITOR:AC_SetVisible( bool )
	if self.AC_Panel_Visible == bool or not self.AC_Panel then return end
	self.AC_Panel_Visible = bool
	self.AC_Panel:SetVisible( bool )
	self.AC_Panel.infolist:SetPos( 1000, 1000 )
end

-----------------------------------------------------------
-- Reset
-----------------------------------------------------------

function EDITOR:AC_Reset()
	self.AC_HasSuggestions = false
	self.AC_Suggestions = false
	self.AC_Directives = nil
	local panel = self.AC_Panel
	if not panel then return end
	self:AC_SetVisible( false )
	panel.list:Clear()
	panel.infolist:Clear()
	panel:SetSize( 100, 202 )
	panel.infolist:SetPos( 1000, 1000 )
	panel.infolist:SetSize( 100, 200 )
	panel.list:StretchToParent( 1,1,1,1 )
end

--------------------------------------------------------

function EDITOR:AC_HandleKey(keycode, control, shift, alt)
	if alt then return end
	if not self.AC_Panel or not self.AC_Panel:IsVisible() then return end

	local mode = wire_expression2_autocomplete_controlstyle:GetInt()

	if mode == AC_STYLE_ECLIPSE and keycode == KEY_ENTER and control
	then
		if self.AC_HasSuggestions and self.AC_Suggestions[1] and self:AC_Use( self.AC_Suggestions[1] ) then
			return true
		end
	elseif (mode == AC_STYLE_VISUALCSHARP or mode == AC_STYLE_ATOM) and (keycode == KEY_UP or keycode == KEY_DOWN) and control
	then
		self.AC_Panel:RequestFocus()
		return true
	elseif code == KEY_TAB then
		if (mode == AC_STYLE_DEFAULT or mode == AC_STYLE_ECLIPSE or mode == AC_STYLE_ATOM) then
			self.AC_Panel:RequestFocus()
			if (mode == AC_STYLE_ECLIPSE or mode == AC_STYLE_ATOM) and self.AC_Panel.Selected == 0 then
				self.AC_Panel.Selected = 1
			end
		else
			self:AC_Check()
		end

		return true
	end
end

function EDITOR:AC_HandleMouseScroll(delta)
	if not self.AC_Panel or not self.AC_Panel:IsVisible() then return end

	local mode = wire_expression2_autocomplete_controlstyle:GetInt()
	if mode ~= AC_STYLE_SCROLLER and mode ~= AC_STYLE_SCROLLER_ENTER then
		self:AC_SetVisible(false)
		return
	end

	self.AC_Panel.Selected = self.AC_Panel.Selected - delta
	if self.AC_Panel.Selected > #self.AC_Suggestions then self.AC_Panel.Selected = 1 end
	if self.AC_Panel.Selected < 1 then self.AC_Panel.Selected = #self.AC_Suggestions end
	self:AC_FillInfoList( self.AC_Suggestions[self.AC_Panel.Selected] )
	self.AC_Panel:RequestFocus()
	return true
end