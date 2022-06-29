local string_Explode = string.Explode
local table_concat = table.concat
local table_remove = table.remove
local table_ForceInsert = table.ForceInsert
local math_floor = math.floor
local math_Clamp = math.Clamp
local math_ceil = math.ceil
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_rep = string.rep
local string_byte = string.byte
local string_format = string.format
local string_Trim = string.Trim
local string_lower = string.lower
local string_upper = string.upper
local string_PatternSafe = string.PatternSafe
local math_min = math.min
local table_insert = table.insert
local table_sort = table.sort
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_PlaySound = surface.PlaySound
local surface_SetTextPos = surface.SetTextPos
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local draw_SimpleText = draw.SimpleText
local draw_WordBox = draw.WordBox
local draw_RoundedBox = draw.RoundedBox
local utf8_sub = utf8.sub
local utf8_GetChar = utf8.GetChar
local utf8_codes = utf8.codes
local utf8_codepoint = utf8.codepoint
local utf8_char = utf8.char

-----------------------------------------------------------------

local EDITOR = vgui.GetControlTable("Expression2Editor")
assert(EDITOR ~= nil)

--------------------------------- Key handling

function EDITOR:Tool_HandleKey(code, control, shift, alt)
	if control and code == KEY_F then
		self:OpenFindWindow( "find" )
	elseif control and code == KEY_H then
		self:OpenFindWindow( "find and replace" )
	elseif control and code == KEY_G then
		self:OpenFindWindow( "go to line" )
	elseif control and code == KEY_K then
		self:CommentSelection(shift)
	elseif control and code == KEY_L then
		self.Start = { self.Start[1], 1 }
		self.Caret = { self.Start[1] + 1, 1 }

		if not shift then self:Copy() end
		self:SetSelection("")
	elseif control and code == KEY_D then
		self:DuplicateLine()
	elseif not control and code == KEY_F1 then
		self:ContextHelp()	
	elseif code == KEY_TAB or (control and (code == KEY_I or code == KEY_O)) then
		if code == KEY_O then shift = not shift end
		if code == KEY_TAB and control then shift = not shift end
		if self:HasSelection() then
			self:Indent(shift)
		else
			-- TAB without a selection --
			if shift then
				local newpos = self.Caret[2]-4
				if newpos < 1 then newpos = 1 end
				self.Start = { self.Caret[1], newpos }
				if string.find(self:GetSelection(), "%S") then
					-- TODO: what to do if shift-tab is pressed within text?
					self.Start = self:CopyPosition(self.Caret)
				else
					self:SetSelection("")
				end
			else
				local count = (self.Caret[2] + 2) % 4 + 1
				self:SetSelection(string_rep(" ", count))
			end
		end
		-- signal that we want our focus back after (since TAB normally switches focus)
		if code == KEY_TAB then self.TabFocus = true end
	else
		return false
	end
end

-------- Context menu

function EDITOR:OpenContextMenu()
	self:AC_SetVisible( false )
	local menu = DermaMenu()

	if self:CanUndo() then
		menu:AddOption("Undo", function()
			self:DoUndo()
		end)
	end
	if self:CanRedo() then
		menu:AddOption("Redo", function()
			self:DoRedo()
		end)
	end

	if self:CanUndo() or self:CanRedo() then
		menu:AddSpacer()
	end

	if self:HasSelection() then
		menu:AddOption("Cut", function()
			self:Cut()
		end)
		menu:AddOption("Copy", function()
			self:Copy()
		end)
	end

	menu:AddOption("Paste", function()
		if self.CurrentMode.clipboard then
			self:SetSelection(self.CurrentMode.clipboard)
		else
			self:SetSelection()
		end
	end)

	if self:HasSelection() then
		menu:AddOption("Delete", function()
			self:SetSelection()
		end)
	end

	menu:AddSpacer()

	menu:AddOption("Select all", function()
		self:SelectAll()
	end)

	menu:AddSpacer()

	menu:AddOption("Indent", function()
		self:Indent(false)
	end)
	menu:AddOption("Outdent", function()
		self:Indent(true)
	end)

	if self:HasSelection() then
		menu:AddSpacer()

		menu:AddOption("Comment Block", function()
			self:CommentSelection(false)
		end)
		menu:AddOption("Uncomment Block", function()
			self:CommentSelection(true)
		end)

		menu:AddOption("Comment Selection",function()
			self:BlockCommentSelection( false )
		end)
		menu:AddOption("Uncomment Selection",function()
			self:BlockCommentSelection( true )
		end)
	end

	self:DoAction("PopulateMenu", menu)

	menu:AddSpacer()

	menu:AddOption( "Copy with BBCode colors", function()
		local str = string_format( "[code][font=%s]", self:GetParent().FontConVar:GetString() )

		local prev_colors
		local first_loop = true

		for i = 1,#self.Rows do
			local colors = self:SyntaxColorLine(i)

			for _, v in pairs( colors ) do
				local color = v[2][1]

				if (prev_colors and prev_colors == color) or string_Trim(v[1]) == "" then
					str = str .. v[1]
				else
					prev_colors = color

					if first_loop then
						str = str .. string_format( '[color="#%x%x%x"]', color.r - 50, color.g - 50, color.b - 50 ) .. v[1]
						first_loop = false
					else
						str = str .. string_format( '[/color][color="#%x%x%x"]', color.r - 50, color.g - 50, color.b - 50 ) .. v[1]
					end
				end
			end

			str = str .. "\r\n"

		end

		str = str .. "[/color][/font][/code]"

		self.CurrentMode.clipboard = str
		SetClipboardText( str )
	end)

	menu:Open()
	return menu
end

------------------ Matching brackets rendering

-- match = { matchedWith, searchDown }
local matchSearch = {
	["{"] = { "}", true },
	["}"] = { "{", false },

	["["] = { "]", true },
	["]"] = { "[", false },

	["("] = { ")", true },
	[")"] = { "(", false },
}

local function matchBalanced(self, start_pos, char_open, char_close, dir_down)
	local cp_open = utf8_codepoint(char_open)
	local cp_close = utf8_codepoint(char_close)

	local start_row = start_pos[1]
	local end_row = dir_down and #self.Rows or 1
	local step_row = dir_down and 1 or -1

	local balance = 0

	for row_i = start_row, end_row, step_row do
		local row = self.Rows[row_i]
		local row_length = self.RowsLength[row_i]

		if row_length == 0 then
			goto row_loop_end
		end

		local char_first, char_last
		if dir_down then
			char_first = row_i == start_row and start_pos[2] or 1
			char_last = row_length
		else
			char_first = 1
			char_last = row_i == start_row and start_pos[2] or row_length
		end

		if char_last < char_first then
			goto row_loop_end
		end

		local row_cps = { utf8_codepoint(utf8_sub(row, char_first, char_last),1,-1) }

		if not dir_down then
			table_reverse_inplace(row_cps)
		end

		for i, cp in ipairs(row_cps) do
			if cp ~= cp_open and cp ~= cp_close then
				goto char_loop_end
			end

			local char_pos
			if dir_down then
				char_pos = char_first + i - 1
			else
				char_pos = char_last - i + 1
			end

			local cur_pos = { row_i, char_pos }
			local cur_token = self:GetTokenAtPosition(cur_pos)

			if cur_token == "comment" or cur_token == "string" then
				goto char_loop_end
			end

			if cp == cp_open then
				balance = balance + 1
			else
				balance = balance - 1
			end

			if balance == 0 then
				return cur_pos
			end

			::char_loop_end::
		end

		::row_loop_end::
	end
end


local function isMatchable(self, pos)
	local char = utf8_GetChar(self.Rows[pos[1]], pos[2])
	if not matchSearch[char] then return false end

	local token = self:GetTokenAtPosition(pos)
	if token == "comment" or token == "string" then return false end

	return true
end

local function getMatchingCharacter(self, pos)
	local char = utf8_GetChar(self.Rows[pos[1]], pos[2])
	local info = matchSearch[char]

	return matchBalanced(self, pos, char, info[1], info[2])
end

function EDITOR:PaintMatchingBrackets()
	-- Code assumes that brackets are ASCII brackets,
	-- And part of font containing ASCII is monospaced
	local width, height = self.FontWidth, self.FontHeight

	-- Bracket matching
	local startPos, endPos

	startPos = self:CopyPosition(self.Caret)
	startPos[2] = startPos[2] - 1

	if isMatchable(self, startPos) then
		endPos = getMatchingCharacter(self, startPos)
	end

	-- If we fail to get a match on the left side of the cursor, check the right side
	if not endPos then
		startPos[2] = startPos[2] + 1

		if isMatchable(self, startPos) then
			endPos = getMatchingCharacter(self, startPos)
		end
	end

	if startPos and endPos then
		surface_SetDrawColor(255, 0, 0, 50)

		local xofs = self.LineNumberWidth + 6 - (self.Scroll[2] - 1) * width
		local start_height = (startPos[1] - self.Scroll[1]) * height
		local end_height = (endPos[1] - self.Scroll[1]) * height

		if start_height > 0 and start_height <= self.Size[1] * height then
			surface_DrawRect(
				xofs + self:GetCharPosInLine(startPos[1], startPos[2]),
				start_height,
				width,
				height
			)
		end
		if end_height > 0 and end_height <= self.Size[1] * height then
			surface_DrawRect(
				xofs + self:GetCharPosInLine(endPos[1], endPos[2]),
				end_height,
				width,
				height
			)
		end
	end
end

---------------------------------- Area highlighting painting

function EDITOR:PaintHighlightedAreas()
	local width, height = self.FontWidth, self.FontHeight
	if not self.HighlightedAreas then
		return
	end

	local visible_line_end = self.Scroll[1] + self.Size[1]

	local x_offset = self.LineNumberWidth + 6 - (self.Scroll[2] - 1) * width

	for _, data in ipairs( self.HighlightedAreas ) do

		local area, r,g,b,a = data[1], data[2], data[3], data[4], data[5]
		surface_SetDrawColor( r,g,b,a )
		local start, stop = self:MakeSelection( area )

		local start_line, stop_line = start[1], stop[1]
		local start_char, stop_char = start[2], stop[2]

		if start_line > visible_line_end then
			goto for_areas_end
		end

		if stop_line > visible_line_end then
			stop_line = visible_line_end
			stop_char = self.RowsLength[stop_line]
		end

		local start_char_pos = self:GetCharPosInLine(start_line, start_char)
		local stop_char_pos = self:GetCharPosInLine(stop_line, stop_char)

		if start_line == stop_line then
			surface_DrawRect(
				x_offset + start_char_pos,
				(start_line-self.Scroll[1]) * height,
				stop_char_pos - start_char_pos,
				height
			)
		elseif stop_line > start_line then
			local start_char_end_pos = self:GetCharPosInLine(start_line, self.RowsLength[start_line])
			surface_DrawRect( -- First line
				x_offset + start_char_pos,
				(start_line-self.Scroll[1]) * height,
				start_char_end_pos - start_char_pos,
				height
			)

			surface_DrawRect( -- Last line
				x_offset,
				(stop_line-self.Scroll[1]) * height,
				stop_char_pos,
				height
			)

			for i = start_line + 1, stop_line - 2 do
				local line_length = self:GetCharPosInLine(i, self.RowsLength[i])

				surface_DrawRect(
					x_offset,
					(i-self.Scroll[1]) * height,
					line_length,
					height
				)
			end
		end

		::for_areas_end::
	end
end

---------------------------------- Caret position and text info display

local wire_expression2_editor_display_caret_pos = CreateClientConVar("wire_expression2_editor_display_caret_pos","0",true,false)

function EDITOR:PaintCaretPos()
	if not wire_expression2_editor_display_caret_pos:GetBool() then return end

	local str = "Length: " .. #self:GetValue() .. " Lines: " .. #self.Rows .. " Ln: " .. self.Caret[1] .. " Col: " .. self.Caret[2]
	if self:HasSelection() then
		str = str .. " Sel: " .. #self:GetSelection()
	end
	surface_SetFont( "Default" )
	local w,h = surface_GetTextSize( str )
	local _w, _h = self:GetSize()
	draw_WordBox(
		4, -- bordersize
		_w - w - (self.ScrollBar:IsVisible() and 16 or 0) - 10,
		_h - h - 10,
		str, "Default", -- text, font
		Color( 0,0,0,100 ), Color( 255,255,255,255 ) -- boxcolor, textcolor
	)
end

----------------------------- Text entry hook

function EDITOR:CustomEntryProcess(text, is_paste)
	if is_paste then return end

	if text == "\n" or input.IsKeyDown(KEY_BACKQUOTE) then 
		return true
	end

	if text == "}" and GetConVarNumber('wire_expression2_autoindent') ~= 0 then
		local row = self.Rows[self.Caret[1]]
		self:SetSelection(text)
		if string.match(row,"[^%s]") == nil then
			local caret = self:Selection()[1]
			self:Indent(true)
			self.Caret = caret
			self.Caret[2] = self.RowsLength[caret[1]] + 1
			self.Start[2] = self.Caret[2]
		end
		return true
	end
end

---------------------------- Search and replace

-- Initialize find settings
local wire_expression2_editor_find_use_patterns = CreateClientConVar( "wire_expression2_editor_find_use_patterns", "0", true, false )
local wire_expression2_editor_find_ignore_case = CreateClientConVar( "wire_expression2_editor_find_ignore_case", "0", true, false )
local wire_expression2_editor_find_whole_word_only = CreateClientConVar( "wire_expression2_editor_find_whole_word_only", "0", true, false )
local wire_expression2_editor_find_wrap_around = CreateClientConVar( "wire_expression2_editor_find_wrap_around", "0", true, false )
local wire_expression2_editor_find_dir = CreateClientConVar( "wire_expression2_editor_find_dir", "1", true, false )

function EDITOR:HighlightFoundWord( caretstart, start, stop )
	caretstart = caretstart or self:CopyPosition( self.Start )
	if istable( start ) then
		self.Start = self:CopyPosition( start )
	elseif isnumber( start ) then
		self.Start = self:MovePosition( caretstart, start )
	end
	if istable( stop ) then
		self.Caret = { stop[1], stop[2] + 1 }
	elseif isnumber( stop ) then
		self.Caret = self:MovePosition( caretstart, stop+1 )
	end
	self:ScrollCaret()
end

function EDITOR:Find( str, looped )
	if looped and looped >= 2 then return end
	if str == "" then return end
	local _str = str

	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local wrap_around = wire_expression2_editor_find_wrap_around:GetBool()
	local dir = wire_expression2_editor_find_dir:GetBool()

	-- Check if the match exists anywhere at all
	local temptext = self:GetValue()
	if ignore_case then
		temptext = temptext:lower()
		str = str:lower()
	end
	local _start,_stop = string.find(temptext, str, 1, not use_patterns )
	if not _start or not _stop then return false end

	if dir then -- Down
		local line = self.Rows[self.Start[1]]
		local text = utf8_sub(line, self.Start[2]) .. "\n"
		text = text .. table_concat( self.Rows, "\n", self.Start[1]+1 )
		if ignore_case then text = text:lower() end

		if not use_patterns then
			str = string.PatternSafe(str)
		end

		if whole_word_only then
			str = "%f[%w_]" .. str .. "%f[^%w_]"
		end

		local start, stop = string.find(text, str, 2)
		if start and stop then
			start = utf8_bytepos_to_charindex(text, start)
			stop = utf8_bytepos_to_charindex(text, stop)
			self:HighlightFoundWord(nil, start - 1, stop - 1)
			return true
		end

		if wrap_around then
			self:SetCaret({1, 1}, false)
			return self:Find(_str, (looped or 0) + 1)
		end

		return false
	else -- Up
		local text = table_concat( self.Rows, "\n", 1, self.Start[1]-1 )
		local line = self.Rows[self.Start[1]]
		text = text .. "\n" .. utf8_sub(line, 1, self.Start[2]-1 )

		str = utf8_reverse( str )
		text = utf8_reverse( text )

		if ignore_case then text = text:lower() end

		if not use_patterns then
			str = string.PatternSafe(str)
		end

		if whole_word_only then
			str = "%f[%w_]" .. str .. "%f[^%w_]"
		end

		local start, stop = string.find(text, str, 2)
		if start and stop then
			start = utf8_bytepos_to_charindex(text, start)
			stop = utf8_bytepos_to_charindex(text, stop)
			self:HighlightFoundWord( nil, -(start-1), -(stop+1) )
			return true
		end

		if wrap_around then
			self:SetCaret( { #self.Rows,self.RowsLength[#self.Rows] }, false )
			return self:Find( _str, (looped or 0) + 1 )
		end

		return false
	end
end

function EDITOR:Replace( str, replacewith )
	if str == "" or str == replacewith then return end

	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	local selection = self:GetSelection()

	local _str = str
	if not use_patterns then
		str = string.PatternSafe(str)
		replacewith = string_gsub(replacewith, "%%", "%%%1" )
	end

	if selection:match( str ) ~= nil then
		self:SetSelection( string_gsub(selection, str, replacewith ) )
		return self:Find( _str )
	else
		return self:Find( _str )
	end
end

function EDITOR:ReplaceAll( str, replacewith )
	if str == "" then return end

	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	if not use_patterns then
		str = string.PatternSafe(str)
		replacewith = string_gsub(replacewith, "%%", "%%%1" )
	end

	if ignore_case then
		str = str:lower()
	end

	local pattern
	if whole_word_only then
		pattern = "%f[%w_]()" .. str .. "%f[^%w_]()"
	else
		pattern = "()" .. str .. "()"
	end

	local txt = self:GetValue()

	if ignore_case then
		local txt2 = txt -- Store original cased copy
		txt = txt:lower() -- Lowercase everything

		local positions = {}

		for startpos, endpos in string_gmatch( txt, pattern ) do
			positions[#positions+1] = {startpos,endpos}
		end

		-- Do the replacing backwards, or it won't work
		for i=#positions,1,-1 do
			local startpos, endpos = positions[i][1], positions[i][2]
			txt2 = utf8_sub(txt2,1,startpos-1) .. replacewith .. utf8_sub(txt2,endpos)
		end

		-- Replace everything with the edited copy
		self:SelectAll()
		self:SetSelection( txt2 )
	else
		txt = string_gsub( txt, pattern, replacewith )

		self:SelectAll()
		self:SetSelection( txt )
	end
end

function EDITOR:CountFinds( str )
	if str == "" then return 0 end

	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	if not use_patterns then
		str = string.PatternSafe(str)
	end

	local txt = self:GetValue()

	if ignore_case then
		txt = txt:lower()
		str = str:lower()
	end

	if whole_word_only then
		str = "%f[%w_]()" .. str .. "%f[^%w_]()"
	end

	return select(2, string_gsub(txt, str, ""))
end

function EDITOR:FindAllWords( str )
	if str == "" then return end

	local txt = self:GetValue()
	-- %f[set] is a 'frontier' pattern - it matches an empty string at a position such that the
	-- next character belongs to set and the previous character does not belong to set.
	-- The beginning and the end of the string are handled as if they were the character '\0'.
	-- As a special case, the empty capture () captures the current string position (a number).
	--   - https://www.lua.org/manual/5.3/manual.html#6.4.1
	local pattern = "%f[%w_]()" .. string.PatternSafe(str) .. "%f[^%w_]()"

	local ret = {}
	for start,stop in string_gmatch(txt, pattern) do
		start = utf8_bytepos_to_charindex(txt, start)
		stop = utf8_bytepos_to_charindex(txt, stop)
		ret[#ret+1] = { start, stop }
	end

	return ret
end

function EDITOR:OpenFindWindow( mode )
	if not self.FindWindow then self:CreateFindWindow() end
	self.FindWindow:SetVisible( true )
	self.FindWindow:MakePopup() -- This will move it above the E2 editor if it is behind it.
	self.ForceDrawCursor = true

	local selection = self:GetSelection():Left(100)

	if mode == "find" then
		if selection and selection ~= "" then self.FindWindow.FindTab.Entry:SetText( selection ) end
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.FindTab.Tab )
		self.FindWindow.FindTab.Entry:RequestFocus()
		self.FindWindow:SetHeight( 201 )
		self.FindWindow.TabHolder:StretchToParent( 1, 23, 1, 1 )
	elseif mode == "find and replace" then
		if selection and selection ~= "" then self.FindWindow.ReplaceTab.Entry:SetText( selection ) end
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.ReplaceTab.Tab )
		self.FindWindow.ReplaceTab.Entry:RequestFocus()
		self.FindWindow:SetHeight( 201 )
		self.FindWindow.TabHolder:StretchToParent( 1, 23, 1, 1 )
	elseif mode == "go to line" then
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.GoToLineTab.Tab )
		local caretPos = self.Caret[1]
		self.FindWindow.GoToLineTab.Entry:SetText(caretPos)
		self.FindWindow.GoToLineTab.Entry:RequestFocus()
		self.FindWindow.GoToLineTab.Entry:SelectAllText()
		self.FindWindow.GoToLineTab.Entry:SetCaretPos(tostring(caretPos):len())
		self.FindWindow:SetHeight( 83 )
		self.FindWindow.TabHolder:StretchToParent( 1, 23, 1, 1 )
	end
end

function EDITOR:CreateFindWindow()
	self.FindWindow = vgui.Create( "DFrame", self )

	local pnl = self.FindWindow
	pnl:SetSize( 322, 201 )
	pnl:ShowCloseButton( true )
	pnl:SetDeleteOnClose( false ) -- No need to create a new window every time
	pnl:MakePopup() -- Make it separate from the editor itself
	pnl:SetVisible( false ) -- but hide it for now
	pnl:SetTitle( "Find" )
	pnl:SetScreenLock( true )
	do
		local old = pnl.Close
		function pnl.Close()
			self.ForceDrawCursor = false
			old( pnl )
		end
	end

	-- Center it above the editor
	local x,y = self:GetParent():GetPos()
	local w,h = self:GetSize()
	pnl:SetPos( x+w/2-150, y+h/2-100 )

	pnl.TabHolder = vgui.Create( "DPropertySheet", pnl )
	pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )

	-- Options
	local common_panel = vgui.Create( "DPanel", pnl )
	common_panel:SetSize( 225, 60 )
	common_panel:SetPos( 10, 130 )
	common_panel.Paint = function()
		local w,h = common_panel:GetSize()
		draw_RoundedBox( 4, 0, 0, w, h, Color(0,0,0,150) )
	end

	local use_patterns = vgui.Create( "DCheckBoxLabel", common_panel )
	use_patterns:SetText( "Use Patterns" )
	use_patterns:SetTooltip( "Use/Don't use Lua patterns in the find." )
	use_patterns:SizeToContents()
	use_patterns:SetConVar( "wire_expression2_editor_find_use_patterns" )
	use_patterns:SetPos( 4, 4 )
	do
		local old = use_patterns.Button.SetValue
		use_patterns.Button.SetValue = function( pnl, b )
			if wire_expression2_editor_find_whole_word_only:GetBool() then return end
			old( pnl, b )
		end
	end

	local case_sens = vgui.Create( "DCheckBoxLabel", common_panel )
	case_sens:SetText( "Ignore Case" )
	case_sens:SetTooltip( "Ignore/Don't ignore case in the find." )
	case_sens:SizeToContents()
	case_sens:SetConVar( "wire_expression2_editor_find_ignore_case" )
	case_sens:SetPos( 4, 24 )

	local whole_word = vgui.Create( "DCheckBoxLabel", common_panel )
	whole_word:SetText( "Match Whole Word" )
	whole_word:SetTooltip( "Match/Don't match the entire word in the find." )
	whole_word:SizeToContents()
	whole_word:SetConVar( "wire_expression2_editor_find_whole_word_only" )
	whole_word:SetPos( 4, 44 )
	do
		local old = whole_word.Button.Toggle
		whole_word.Button.Toggle = function( pnl )
			old( pnl )
			if pnl:GetValue() then use_patterns:SetValue( false ) end
		end
	end

	local wrap_around = vgui.Create( "DCheckBoxLabel", common_panel )
	wrap_around:SetText( "Wrap Around" )
	wrap_around:SetTooltip( "Start/Don't start from the top after reaching the bottom, or the bottom after reaching the top." )
	wrap_around:SizeToContents()
	wrap_around:SetConVar( "wire_expression2_editor_find_wrap_around" )
	wrap_around:SetPos( 130, 4 )

	local dir_down = vgui.Create( "DCheckBoxLabel", common_panel )
	local dir_up = vgui.Create( "DCheckBoxLabel", common_panel )

	dir_up:SetText( "Up" )
	dir_up:SizeToContents()
	dir_up:SetPos( 130, 24 )
	dir_up:SetTooltip( "Note: Most patterns won't work when searching up because the search function reverses the string to search backwards." )
	dir_up:SetValue( not wire_expression2_editor_find_dir:GetBool() )
	dir_down:SetText( "Down" )
	dir_down:SizeToContents()
	dir_down:SetPos( 130, 44 )
	dir_down:SetValue( wire_expression2_editor_find_dir:GetBool() )

	function dir_up.Button:Toggle()
		dir_up:SetValue(true)
		dir_down:SetValue(false)
		RunConsoleCommand( "wire_expression2_editor_find_dir", "0" )
	end
	function dir_down.Button:Toggle()
		dir_down:SetValue(true)
		dir_up:SetValue(false)
		RunConsoleCommand( "wire_expression2_editor_find_dir", "1" )
	end

	do
		-- Find tab
		local findtab = vgui.Create( "DPanel" )

		-- Label
		local FindLabel = vgui.Create( "DLabel", findtab )
		FindLabel:SetText( "Find:" )
		FindLabel:SetPos( 4, 4 )
		FindLabel:SetTextColor( Color(0,0,0,255) )

		-- Text entry
		local FindEntry = vgui.Create( "DTextEntry", findtab )
		FindEntry:SetPos(30,4)
		FindEntry:SetSize(200,20)
		FindEntry:RequestFocus()
		FindEntry.OnEnter = function( pnl )
			self:Find( pnl:GetValue() )
			pnl:RequestFocus()
		end

		-- Find next button
		local FindNext = vgui.Create( "DButton", findtab )
		FindNext:SetText("Find Next")
		FindNext:SetTooltip( "Find the next match and highlight it." )
		FindNext:SetPos(233,4)
		FindNext:SetSize(70,20)
		FindNext.DoClick = function(pnl)
			self:Find( FindEntry:GetValue() )
		end

		-- Find button
		local Find = vgui.Create( "DButton", findtab )
		Find:SetText("Find")
		Find:SetTooltip( "Find the next match, highlight it, and close the Find window." )
		Find:SetPos(233,29)
		Find:SetSize(70,20)
		Find.DoClick = function(pnl)
			self.FindWindow:Close()
			self:Find( FindEntry:GetValue() )
		end

		-- Count button
		local Count = vgui.Create( "DButton", findtab )
		Count:SetText( "Count" )
		Count:SetPos( 233, 95 )
		Count:SetSize( 70, 20 )
		Count:SetTooltip( "Count the number of matches in the file." )
		Count.DoClick = function(pnl)
			Derma_Message( self:CountFinds( FindEntry:GetValue() ) .. " matches found.", "", "Ok" )
		end

		-- Cancel button
		local Cancel = vgui.Create( "DButton", findtab )
		Cancel:SetText("Cancel")
		Cancel:SetPos(233,120)
		Cancel:SetSize(70,20)
		Cancel.DoClick = function(pnl)
			self.FindWindow:Close()
		end

		pnl.FindTab = pnl.TabHolder:AddSheet( "Find", findtab, "icon16/page_white_find.png", false, false )
		pnl.FindTab.Entry = FindEntry
	end

	do
		-- Replace tab
		local replacetab = vgui.Create( "DPanel" )

		-- Label
		local FindLabel = vgui.Create( "DLabel", replacetab )
		FindLabel:SetText( "Find:" )
		FindLabel:SetPos( 4, 4 )
		FindLabel:SetTextColor( Color(0,0,0,255) )

		-- Text entry
		local FindEntry = vgui.Create( "DTextEntry", replacetab )
		local ReplaceEntry
		FindEntry:SetPos(30,4)
		FindEntry:SetSize(200,20)
		FindEntry:RequestFocus()
		FindEntry.OnEnter = function( pnl )
			self:Replace( pnl:GetValue(), ReplaceEntry:GetValue() )
			ReplaceEntry:RequestFocus()
		end

		-- Label
		local ReplaceLabel = vgui.Create( "DLabel", replacetab )
		ReplaceLabel:SetText( "Replace With:" )
		ReplaceLabel:SetPos( 4, 32 )
		ReplaceLabel:SizeToContents()
		ReplaceLabel:SetTextColor( Color(0,0,0,255) )

		-- Replace entry
		ReplaceEntry = vgui.Create( "DTextEntry", replacetab )
		ReplaceEntry:SetPos(75,29)
		ReplaceEntry:SetSize(155,20)
		ReplaceEntry:RequestFocus()
		ReplaceEntry.OnEnter = function( pnl )
			self:Replace( FindEntry:GetValue(), pnl:GetValue() )
			pnl:RequestFocus()
		end

		-- Find next button
		local FindNext = vgui.Create( "DButton", replacetab )
		FindNext:SetText("Find Next")
		FindNext:SetTooltip( "Find the next match and highlight it." )
		FindNext:SetPos(233,4)
		FindNext:SetSize(70,20)
		FindNext.DoClick = function(pnl)
			self:Find( FindEntry:GetValue() )
		end

		-- Replace next button
		local ReplaceNext = vgui.Create( "DButton", replacetab )
		ReplaceNext:SetText("Replace")
		ReplaceNext:SetTooltip( "Replace the current selection if it matches, else find the next match." )
		ReplaceNext:SetPos(233,29)
		ReplaceNext:SetSize(70,20)
		ReplaceNext.DoClick = function(pnl)
			self:Replace( FindEntry:GetValue(), ReplaceEntry:GetValue() )
		end

		-- Replace all button
		local ReplaceAll = vgui.Create( "DButton", replacetab )
		ReplaceAll:SetText("Replace All")
		ReplaceAll:SetTooltip( "Replace all occurences of the match in the entire file, and close the Find window." )
		ReplaceAll:SetPos(233,54)
		ReplaceAll:SetSize(70,20)
		ReplaceAll.DoClick = function(pnl)
			self.FindWindow:Close()
			self:ReplaceAll( FindEntry:GetValue(), ReplaceEntry:GetValue() )
		end

		-- Count button
		local Count = vgui.Create( "DButton", replacetab )
		Count:SetText( "Count" )
		Count:SetPos( 233, 95 )
		Count:SetSize( 70, 20 )
		Count:SetTooltip( "Count the number of matches in the file." )
		Count.DoClick = function(pnl)
			Derma_Message( self:CountFinds( FindEntry:GetValue() ) .. " matches found.", "", "Ok" )
		end

		-- Cancel button
		local Cancel = vgui.Create( "DButton", replacetab )
		Cancel:SetText("Cancel")
		Cancel:SetPos(233,120)
		Cancel:SetSize(70,20)
		Cancel.DoClick = function(pnl)
			self.FindWindow:Close()
		end

		pnl.ReplaceTab = pnl.TabHolder:AddSheet( "Replace", replacetab, "icon16/page_white_wrench.png", false, false )
		pnl.ReplaceTab.Entry = FindEntry
	end

	-- Go to line tab
	local gototab = vgui.Create( "DPanel" )

	-- Label
	local GotoLabel = vgui.Create( "DLabel", gototab )
	GotoLabel:SetText( "Go to Line:" )
	GotoLabel:SetPos( 4, 4 )
	GotoLabel:SetTextColor( Color(0,0,0,255) )

	-- Text entry
	local GoToEntry = vgui.Create( "DTextEntry", gototab )
	GoToEntry:SetPos(57,4)
	GoToEntry:SetSize(173,20)
	GoToEntry:SetNumeric( true )

	-- Goto Button
	local Goto = vgui.Create( "DButton", gototab )
	Goto:SetText("Go to Line")
	Goto:SetPos(233,4)
	Goto:SetSize(70,20)

	-- Action
	local function GoToAction(panel)
		local val = tonumber(GoToEntry:GetValue())
		if val then
			val = math_Clamp(val, 1, #self.Rows)
			self:SetCaret({val, self.RowsLength[val] + 1}, false)
		end
		GoToEntry:SetText(tostring(val))
		self.FindWindow:Close()
	end
	GoToEntry.OnEnter = GoToAction
	Goto.DoClick = GoToAction

	pnl.GoToLineTab = pnl.TabHolder:AddSheet( "Go to Line", gototab, "icon16/page_white_go.png", false, false )
	pnl.GoToLineTab.Entry = GoToEntry

	-- Tab buttons
	do
		local old = pnl.FindTab.Tab.OnMousePressed
		pnl.FindTab.Tab.OnMousePressed = function( ... )
			pnl.FindTab.Entry:SetText( pnl.ReplaceTab.Entry:GetValue() or "" )
			local active = pnl.TabHolder:GetActiveTab()
			if active == pnl.GoToLineTab.Tab then
				pnl:SetHeight( 200 )
				pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
			end
			old( ... )
		end
	end

	do
		local old = pnl.ReplaceTab.Tab.OnMousePressed
		pnl.ReplaceTab.Tab.OnMousePressed = function( ... )
			pnl.ReplaceTab.Entry:SetText( pnl.FindTab.Entry:GetValue() or "" )
			local active = pnl.TabHolder:GetActiveTab()
			if active == pnl.GoToLineTab.Tab then
				pnl:SetHeight( 200 )
				pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
			end
			old( ... )
		end
	end

	do
		local old = pnl.GoToLineTab.Tab.OnMousePressed
		pnl.GoToLineTab.Tab.OnMousePressed = function( ... )
			pnl:SetHeight( 86 )
			pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
			pnl.GoToLineTab.Entry:SetText(self.Caret[1])
			old( ... )
		end
	end
end

----------------------------------- Indeting

-- removes the first 0-4 spaces from a string and returns it
local function unindent(line)
	--local i = line:find("%S")
	--if i == nil or i > 5 then i = 5 end
	--return line:sub(i)
	return line:match("^ ? ? ? ?(.*)$")
end

function EDITOR:Indent(shift)
	-- TAB with a selection --
	-- remember scroll position
	local tab_scroll = self:CopyPosition(self.Scroll)

	-- normalize selection, so it spans whole lines
	local tab_start, tab_caret = self:MakeSelection(self:Selection())
	tab_start[2] = 1

	if tab_caret[2] ~= 1 then
		tab_caret[1] = tab_caret[1] + 1
		tab_caret[2] = 1
	end

	-- remember selection
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if self.Caret[2] == 1 then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	if shift then
		-- shift-TAB with a selection --
		local tmp = string_gsub(self:GetSelection(), "\n ? ? ? ?", "\n")

		-- makes sure that the first line is outdented
		self:SetSelection(unindent(tmp))
	else
		-- plain TAB with a selection --
		self:SetSelection("    " .. string_gsub(self:GetSelection(), "\n", "\n    "))
	end
	-- restore selection
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	-- restore scroll position
	self.Scroll = self:CopyPosition(tab_scroll)
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

------------------------------ Commenting

-- Comment the currently selected area
function EDITOR:BlockCommentSelection( removecomment )
	if not self:HasSelection() then return end

	local scroll = self:CopyPosition( self.Scroll )

	local new_selection = self:DoAction("BlockCommentSelection", removecomment)
	if not new_selection then return end

	self.Start, self.Caret = self:MakeSelection(new_selection)
	-- restore scroll position
	self.Scroll = scroll
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

-- CommentSelection
-- Idea by Jeremydeath
-- Rewritten by Divran to use block comment
function EDITOR:CommentSelection( removecomment )
	if not self:HasSelection() then return end

	-- Remember scroll position
	local scroll = self:CopyPosition( self.Scroll )

	-- Normalize selection, so it spans whole lines
	local sel_start, sel_caret = self:MakeSelection( self:Selection() )
	sel_start[2] = 1

	if sel_caret[2] ~= 1 then
		sel_caret[1] = sel_caret[1] + 1
		sel_caret[2] = 1
	end

	-- Remember selection
	self.Caret = self:CopyPosition( sel_caret )
	self.Start = self:CopyPosition( sel_start )
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if self.Caret[2] == 1 then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	local new_selection = self:DoAction("CommentSelection", removecomment)
	if not new_selection then return end

	self.Start, self.Caret = self:MakeSelection(new_selection)

	-- restore scroll position
	self.Scroll = scroll
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

-------------------------------------- Context help
--- TODO: add hint somewhere that you actually can do this

function EDITOR:ContextHelp()
	local word
	if self:HasSelection() then
		word = self:GetSelection()
	else
		local row, col = unpack(self.Caret)
		local line = self.Rows[row]
		if not utf8_sub(line, col, col):match("^[a-zA-Z0-9_]$") then
			col = col - 1
		end
		if not utf8_sub(line, col, col):match("^[a-zA-Z0-9_]$") then
			surface_PlaySound("buttons/button19.wav")
			return
		end

		-- TODO substitute this for getWordStart, if it fits.
		local startcol = col
		while startcol > 1 and utf8_sub(line, startcol-1, startcol-1):match("^[a-zA-Z0-9_]$") do
			startcol = startcol - 1
		end

		-- TODO substitute this for getWordEnd, if it fits.
		local _,endcol = string.find(line, "[^a-zA-Z0-9_]", col)
		if endcol ~= nil then
			endcol = utf8_bytepos_to_charindex(line, endcol) - 1
		else
			endcol = -1
		end

		word = utf8_sub(line, startcol, endcol)
	end

	self:DoAction("ShowContextHelp", word)
end

--------------------------------- Duplicate current line

function EDITOR:DuplicateLine()
	-- Save current selection
	local old_start = self:CopyPosition( self.Start )
	local old_end = self:CopyPosition( self.Caret )
	local old_scroll = self:CopyPosition( self.Scroll )

	local str = self:GetSelection()
	if str ~= "" then -- If you have a selection
		self:SetSelection( str:rep(2) ) -- Repeat it
	else -- If you don't
		-- Select the current line
		self.Start = { self.Start[1], 1 }
		self.Caret = { self.Start[1], self.RowsLength[self.Start[1]]+1 }
		-- Get the text
		local str = self:GetSelection()
		-- Repeat it
		self:SetSelection( str .. "\n" .. str )
	end

	-- Restore selection
	self.Caret = old_end
	self.Start = old_start
	self.Scroll = old_scroll
	self:ScrollCaret()
end