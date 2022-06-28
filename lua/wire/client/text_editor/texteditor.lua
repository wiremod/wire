--
-- Expression 2 Text Editor for Garry's Mod
-- Andreas "Syranide" Svensson, me@syranide.com
--

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

local function utf8_bytepos_to_charindex(string, bytepos)
	assert(bytepos >= 1, 'bytepos is negative or zero')
	local char_index = 0
	for char_start, _ in utf8_codes(string) do
		if char_start > bytepos then
			return char_index
		end

		char_index = char_index + 1
	end

	return char_index
end

local function table_reverse_inplace(tbl)
	local count = #tbl
	local reverse_count = math_floor(count / 2)

	for i = 1, reverse_count do
		local temp = tbl[i]
		tbl[i] = tbl[count + 1 - i]
		tbl[count + 1 - i] = temp
	end
end

-- Not so optimal, probably
-- Not handles grapheme clusters
local function utf8_reverse(str)
	local codepoints = { utf8_codepoint(str, 1, -1) }
	table_reverse_inplace(codepoints)
	return utf8_char(unpack(codepoints))
end

local utf8_len = function(str, startpos, endpos)
	local len, error = utf8.len(str, startpos, endpos)

	if len == false then
		error("String has non-UTF-8 byte at "..tostring(error).." \n String: "..str)
	end

	return len
end

WireTextEditor = { Modes = {} }
include("modes/e2.lua")
include("modes/zcpu.lua")
WireTextEditor.Modes.Default = { SyntaxColorLine = function(self, row) return { { self.Rows[row], { Color(255, 255, 255, 255), false } } } end }

local wire_expression2_autocomplete_controlstyle = CreateClientConVar( "wire_expression2_autocomplete_controlstyle", "0", true, false )

local AC_STYLE_DEFAULT = 0 -- Default style - Tab/CTRL+Tab to choose item;\nEnter/Space to use;\nArrow keys to abort.
local AC_STYLE_VISUALCSHARP = 1 -- Visual C# Style - Ctrl+Space to use the top match;\nArrow keys to choose item;\nTab/Enter/Space to use;\nCode validation hotkey (ctrl+space) moved to ctrl+b.
local AC_STYLE_SCROLLER = 2 -- Scroller style - Mouse scroller to choose item;\nMiddle mouse to use.
local AC_STYLE_SCROLLER_ENTER = 3 -- Scroller Style w/ Enter - Mouse scroller to choose item;\nEnter to use.
local AC_STYLE_ECLIPSE = 4 -- Eclipse Style - Enter to use top match;\nTab to enter auto completion menu;\nArrow keys to choose item;\nEnter to use;\nSpace to abort.
local AC_STYLE_ATOM = 5 -- Atom style - Tab/Enter to use, arrow keys to choose

local EDITOR = {}

function EDITOR:Init()
	self:SetCursor("beam")

	self.Rows = {""}
	self.RowsLength = {0}
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Size = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}

	self.CurrentMode = assert(WireTextEditor.Modes.Default)

	self.LineNumberWidth = 2

	self.Blink = RealTime()

	self.ScrollBar = vgui.Create("DVScrollBar", self)
	self.ScrollBar:SetUp(1, 1)

	self.TextEntry = vgui.Create("TextEntry", self)
	self.TextEntry:SetMultiline(true)
	self.TextEntry:SetSize(0, 0)
	self.TextEntry:SetAllowNonAsciiCharacters(true)

	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus() end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged() end
	self.TextEntry.OnKeyCodeTyped = function (self, code) return self.Parent:_OnKeyCodeTyped(code) end

	self.TextEntry.Parent = self

	self.LastClick = 0

	self.e2fs_functions = {}

	self.Colors = {
		dblclickhighlight = Color(0, 100, 0),
	}
end

local function GetCharPosInLine(self, row, search_index)
	local char_index = 1
	local char_pos = 0
	local row_tbl = self.PaintRows[row]

	if row_tbl == nil then
		Error("Line ",row," not exists or not cached")
	end
	
	--MsgN("GetCharPosInLine > @", search_index, " ", self.Rows[row])
	for _, cell in ipairs(row_tbl) do
		local part_text = cell[1]
		local part_bold = cell[2][2]
		local part_text_len = utf8_len(part_text)

		local is_final = char_index + part_text_len >= search_index

		--MsgN("#", i, " Char ", char_index, "/", char_pos,
		--    is_final and " fin " or " imm ", part_text_len, "|", part_text)

		if is_final then
			part_text = utf8_sub(part_text, 1, search_index - char_index)
			part_text_len = search_index - char_index
			--MsgN("# Rewrite ", part_text_len,"|", part_text)
		end

		surface_SetFont(self.CurrentFont .. (part_bold and "_Bold" or ""))
		local part_length = surface_GetTextSize(part_text)

		char_pos = char_pos + part_length
		--MsgN("# Length ", part_length, " Total ", char_pos)

		if is_final then break end

		char_index = char_index + part_text_len
	end

	--char_pos = char_pos + self.FontWidth
	--MsgN("GetCharPosInLine < @", char_index, " Pos ", char_pos)

	return char_pos
end

local function GetCharIndexByPos(self, row, pos)
	local char_fonts = {}

	do
		local font = self.CurrentFont
		local font_bold = self.CurrentFont.."_Bold"

		local text_index = 0
		for _, part in ipairs(self.PaintRows[row]) do
			local part_text = part[1]
			local part_text_len = utf8_len(part_text)
			local font = font

			if part[2][2] then -- is bold?
				font = font_bold
			end

			for _ = 1, part_text_len do
				table_insert(char_fonts, font)
			end

			text_index = text_index + part_text_len
		end
	end

	local char_pos_start = 0
	for i, font in ipairs(char_fonts) do
		surface_SetFont(font)
		local char_len = surface_GetTextSize(utf8_GetChar(self.Rows[row], i))

		if char_pos_start + char_len >= pos then
			return i
		end

		char_pos_start = char_pos_start + char_len
	end

	return self.RowsLength[row] + 1
end

function EDITOR:SetMode(mode_name)
	self.CurrentMode = WireTextEditor.Modes[mode_name or "Default"]
	if not self.CurrentMode then
		Msg("Couldn't find text editor mode '".. tostring(mode_name) .. "'")
		self.CurrentMode = assert(WireTextEditor.Modes.Default, "Couldn't find default text editor mode")
	end
end

function EDITOR:DoAction(name, ...)
	if not self.CurrentMode then return end
	local f = assert(self.CurrentMode, "No current mode set")[name]
	if not f then f = WireTextEditor.Modes.Default[name] end
	if f then return f(self, ...) end
end

function EDITOR:GetParent()
	return self.parentpanel
end

function EDITOR:RequestFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:OnGetFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:CursorToCaret()
	local x, y = self:CursorPos()

	x = x - (self.LineNumberWidth + 6)
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end

	local line = math_floor(y / self.FontHeight)
	local char_pos = x + self.Scroll[2] * self.FontWidth

	line = line + self.Scroll[1]
	if line > #self.Rows then line = #self.Rows end

	return { line, GetCharIndexByPos(self, line, char_pos) }
end

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

local wire_expression2_editor_highlight_on_double_click = CreateClientConVar( "wire_expression2_editor_highlight_on_double_click", "1", true, false )

function EDITOR:DoDoubleClickSelection()
	if not wire_expression2_editor_highlight_on_double_click:GetBool() then
		return
	end

	self.HighlightedAreasByDoubleClick = {}
	local all_finds = self:FindAllWords( self:GetSelection() )
	if not all_finds then
		return
	end

	all_finds[0] = {1,1} -- Set [0] so the [i-1]'s don't fail on the first iteration
	self.HighlightedAreasByDoubleClick[0] = {{1,1}, {1,1}}
	for i = 1,#all_finds do

		-- Instead of finding the caret by searching from the beginning every time, start searching from the previous caret
		local start = all_finds[i][1] - all_finds[i-1][1]
		local stop = all_finds[i][2] - all_finds[i-1][2]
		local caretstart = self:MovePosition( self.HighlightedAreasByDoubleClick[i-1][1], start )
		local caretstop = self:MovePosition( self.HighlightedAreasByDoubleClick[i-1][2], stop )
		self.HighlightedAreasByDoubleClick[i] = { caretstart, caretstop }

		-- This checks if it's NOT the word the user just highlighted
		if caretstart[1] ~= self.Start[1] or caretstart[2] ~= self.Start[2] or
			caretstop[1] ~= self.Caret[1] or caretstop[2] ~= self.Caret[2] then
			local c = self:GetSyntaxColor("dblclickhighlight")
			self:HighlightArea( { caretstart, caretstop }, c.r, c.g, c.b, 100 )
		end
	end
end

function EDITOR:OnMousePressed(code)
	if code == MOUSE_LEFT then
		local cursor = self:CursorToCaret()
		if (CurTime() - self.LastClick) < 1 and self.NotDoubleClick and cursor[1] == self.Caret[1] and cursor[2] == self.Caret[2] then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.NotDoubleClick = false

			self:DoDoubleClickSelection()

			return
		end

		if self.HighlightedAreasByDoubleClick then
			for i=1,#self.HighlightedAreasByDoubleClick do
				self:HighlightArea( self.HighlightedAreasByDoubleClick[i] )
			end
			self.HighlightedAreasByDoubleClick = nil
		end

		self.NotDoubleClick = true

		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true

		self.Caret = self:CopyPosition( cursor )
		if not input.IsKeyDown(KEY_LSHIFT) and not input.IsKeyDown(KEY_RSHIFT) then
			self.Start = self:CopyPosition( cursor )
		end

		self:AC_Check()
	elseif code == MOUSE_RIGHT then
		self:OpenContextMenu()
	end
end

function EDITOR:OnMouseReleased(code)
	if not self.MouseDown then return end

	if code == MOUSE_LEFT then
		self.MouseDown = nil
		if not self.NotDoubleClick then return end
		self.Caret = self:CursorToCaret()
	end
end

function EDITOR:SetText(text)
	self.Rows = string_Explode("\n", text)
	if self.Rows[#self.Rows] ~= "" then
		self.Rows[#self.Rows + 1] = ""
	end

	self.RowsLength = {}
	for i, row in ipairs(self.Rows) do
		self.RowsLength[i] = utf8_len(row)
	end

	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}
	self:AC_Reset()

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:GetValue()
	local val = string_gsub(table_concat(self.Rows, "\n"), "\r", "")
	return val
end

function EDITOR:HighlightLine( line, r, g, b, a )
	if not self.HighlightedLines then self.HighlightedLines = {} end
	if not r and self.HighlightedLines[line] then
		self.HighlightedLines[line] = nil
		return true
	elseif r and g and b and a then
		self.HighlightedLines[line] = { r, g, b, a }
		return true
	end
	return false
end
function EDITOR:ClearHighlightedLines() self.HighlightedLines = nil end

function EDITOR:PaintLineSelection(row)
	local sel_start, sel_end = self:MakeSelection(self:Selection())

	local line_start, line_end = sel_start[1], sel_end[1]

	if row < line_start or row > line_end then
		return -- This line is not in selection
	end

	local char_start_i, char_end_i = sel_start[2], sel_end[2]

	local row_text = self.Rows[row]

	local char_start_pos
	if line_start == row then -- This line contains start of the selection
		char_start_pos = surface_GetTextSize(utf8_sub(row_text, 1, char_start_i - 1))
	else
		char_start_pos = 0
	end

	local char_end_pos
	if line_end == row then -- This line contains end of the selection
		char_end_pos = surface_GetTextSize(utf8_sub(row_text, 1, char_end_i - 1))
	else
		char_end_pos = surface_GetTextSize(row_text)
	end

	char_start_pos = char_start_pos - (self.Scroll[2] - 1) * self.FontWidth
	char_end_pos = char_end_pos - (self.Scroll[2] - 1) * self.FontWidth

	if char_end_pos < 0 then return end -- Selection end is not visible
	if char_start_pos < 0 then char_start_pos = 0 end

	surface_SetDrawColor(0, 0, 160, 255)
	surface_DrawRect(
		self.LineNumberWidth + 6 + char_start_pos,
		(row - self.Scroll[1]) * self.FontHeight,
		char_end_pos - char_start_pos,
		self.FontHeight
	)
end

function EDITOR:PaintLine(row)
	if row > #self.Rows then return end

	if not self.PaintRows[row] then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end

	--local text_width = self.FontWidth
	local text_height = self.FontHeight

	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		surface_SetDrawColor(48, 48, 48, 255)
		surface_DrawRect(
			self.LineNumberWidth + 5,
			(row - self.Scroll[1]) * text_height,
			self:GetWide() - (self.LineNumberWidth + 5),
			text_height
		)
	end

	if self.HighlightedLines and self.HighlightedLines[row] then
		local color = self.HighlightedLines[row]
		surface_SetDrawColor( color[1], color[2], color[3], color[4] )
		surface_DrawRect(
			self.LineNumberWidth + 5,
			(row - self.Scroll[1]) * text_height,
			self:GetWide() - (self.LineNumberWidth + 5),
			text_height
		)
	end

	surface.SetFont(self.CurrentFont)

	if self:HasSelection() then
		self:PaintLineSelection(row)
	end


	draw_SimpleText(
		tostring(row),
		self.CurrentFont, -- Font is set again here
		self.LineNumberWidth + 2,
		(row - self.Scroll[1]) * text_height,
		Color(128, 128, 128, 255),
		TEXT_ALIGN_RIGHT
	)

	local text_pos_y = (row - self.Scroll[1]) * text_height
	local offset = (-self.Scroll[2] + 1) * self.FontWidth
	for _, cell in ipairs(self.PaintRows[row]) do
		local text = cell[1]
		local color = cell[2][1]
		local bold = cell[2][2]

		surface_SetFont(self.CurrentFont .. (bold and "_Bold" or ""))
		local text_width = surface_GetTextSize(text) -- Text height is ignored

		if offset > -text_width then
			if offset < 0 then
				text = utf8_sub(text, 1 - (offset / self.FontWidth))
				text_width = surface_GetTextSize(text)
				offset = 0
			end

			surface_SetTextPos(self.LineNumberWidth + 6 + offset, text_pos_y)
			surface_SetTextColor(color)
			surface_DrawText(text)


		end
		offset = offset + text_width
	end
end

function EDITOR:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)

	self.Size[1] = math_ceil(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math_ceil((self:GetWide() - (self.LineNumberWidth + 6) - 16) / self.FontWidth) - 1

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:HighlightArea( area, r,g,b,a )
	if not self.HighlightedAreas then self.HighlightedAreas = {} end
	if not r then
		local _start, _stop = area[1], area[2]
		for i,v in ipairs( self.HighlightedAreas ) do
			local start = v[1][1]
			local stop = v[1][2]
			if start[1] == _start[1] and start[2] == _start[2] and stop[1] == _stop[1] and stop[2] == _stop[2] then
				table.remove( self.HighlightedAreas, i )
				break
			end
		end
		return true
	elseif r and g and b and a then
		self.HighlightedAreas[#self.HighlightedAreas+1] = {area, r, g, b, a }
		return true
	end
	return false
end
function EDITOR:ClearHighlightedAreas() self.HighlightedAreas = nil end

do
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

	function EDITOR:PaintCaret()
		if not self.TextEntry:HasFocus() then
			return
		end

		local scroll_pos_x = (self.Scroll[2] - 1) * self.FontWidth
		local caret_pos_x = GetCharPosInLine(self, self.Caret[1], self.Caret[2])

		if caret_pos_x < scroll_pos_x then
			return
		end

		if (RealTime() - self.Blink) % 0.8 >= 0.4 then
			return
		end

		local height = self.FontHeight
		surface_SetDrawColor(240, 240, 240, 255)
		surface_DrawRect(
			self.LineNumberWidth + 6 - scroll_pos_x + caret_pos_x,
			(self.Caret[1] - self.Scroll[1]) * height,
			1, height)
	end

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

			local start_char_pos = GetCharPosInLine(self, start_line, start_char)
			local stop_char_pos = GetCharPosInLine(self, stop_line, stop_char)

			if start_line == stop_line then
				surface_DrawRect(
					x_offset + start_char_pos,
					(start_line-self.Scroll[1]) * height,
					stop_char_pos - start_char_pos,
					height
				)
			elseif stop_line > start_line then
				local start_char_end_pos = GetCharPosInLine(self, start_line, self.RowsLength[start_line])
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
					local line_length = GetCharPosInLine(self, i, self.RowsLength[i])

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
					xofs + GetCharPosInLine(self, startPos[1], startPos[2]),
					start_height,
					width,
					height
				)
			end
			if end_height > 0 and end_height <= self.Size[1] * height then
				surface_DrawRect(
					xofs + GetCharPosInLine(self, endPos[1], endPos[2]),
					end_height,
					width,
					height
				)
			end
		end
	end
end

local wire_expression2_editor_display_caret_pos = CreateClientConVar("wire_expression2_editor_display_caret_pos","0",true,false)

function EDITOR:Paint()
	self.LineNumberWidth = self.FontWidth * #tostring(self.Scroll[1]+self.Size[1])

	if not input.IsMouseDown(MOUSE_LEFT) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if self.MouseDown then
		self.Caret = self:CursorToCaret()
	end

	surface_SetDrawColor(0, 0, 0, 255)
	surface_DrawRect(0, 0, self.LineNumberWidth + 4, self:GetTall())

	surface_SetDrawColor(32, 32, 32, 255)
	surface_DrawRect(self.LineNumberWidth + 5, 0, self:GetWide() - (self.LineNumberWidth + 5), self:GetTall())

	self.Scroll[1] = math_floor(self.ScrollBar:GetScroll() + 1)

	for i=self.Scroll[1],self.Scroll[1]+self.Size[1] do
		self:PaintLine(i)
	end

	-- Paint the overlay of the text (bracket highlighting and carret postition)
	self:PaintCaret()
	self:PaintHighlightedAreas()
	self:PaintMatchingBrackets()

	if wire_expression2_editor_display_caret_pos:GetBool() then
		local str = "Length: " .. #self:GetValue() .. " Lines: " .. #self.Rows .. " Ln: " .. self.Caret[1] .. " Col: " .. self.Caret[2]
		if self:HasSelection() then
			str = str .. " Sel: " .. #self:GetSelection()
		end
		surface_SetFont( "Default" )
		local w,h = surface_GetTextSize( str )
		local _w, _h = self:GetSize()
		draw_WordBox( 4, _w - w - (self.ScrollBar:IsVisible() and 16 or 0) - 10, _h - h - 10, str, "Default", Color( 0,0,0,100 ), Color( 255,255,255,255 ) )
	end

	self:DoAction("Paint")

	return true
end

-- Moves the caret to a new position. Optionally also collapses the selection
-- into a single caret. If maintain_selection is nil, then the selection will
-- be maintained only if Shift is pressed.
function EDITOR:SetCaret(caret, maintain_selection)
	self.Caret = self:CopyPosition(caret)

	self.Caret[1] = math.Clamp(self.Caret[1], 1, #self.Rows)
	self.Caret[2] = math.Clamp(self.Caret[2], 1, self.RowsLength[self.Caret[1]] + 1)

	if maintain_selection == nil then
		maintain_selection = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	end

	if not maintain_selection then
		self.Start = self:CopyPosition(self.Caret)
	end

	self:ScrollCaret()
end


function EDITOR:CopyPosition(caret)
	return { caret[1], caret[2] }
end

function EDITOR:MovePosition(caret, offset)
	local row, col = caret[1], caret[2]

	if offset > 0 then
		local numRows = #self.Rows
		while true do
			local length = self.RowsLength[row] - col + 2
			if offset < length then
				col = col + offset
				break
			elseif row == numRows then
				col = col + length - 1
				break
			else
				offset = offset - length
				row = row + 1
				col = 1
			end
		end
	elseif offset < 0 then
		offset = -offset

		while true do
			if offset < col then
				col = col - offset
				break
			elseif row == 1 then
				col = 1
				break
			else
				offset = offset - col
				row = row - 1
				col = self.RowsLength[row] + 1
			end
		end
	end

	return {row, col}
end


function EDITOR:HasSelection()
	return self.Caret[1] ~= self.Start[1] or self.Caret[2] ~= self.Start[2]
end

function EDITOR:Selection()
	return { { self.Caret[1], self.Caret[2] }, { self.Start[1], self.Start[2] } }
end

function EDITOR:MakeSelection(selection)
	local start, stop = selection[1], selection[2]

	if start[1] < stop[1] or (start[1] == stop[1] and start[2] < stop[2]) then
		return start, stop
	else
		return stop, start
	end
end


function EDITOR:GetArea(selection)
	local start, stop = self:MakeSelection(selection)

	if start[1] == stop[1] then
		return utf8_sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = utf8_sub(self.Rows[start[1]], start[2])

		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end

		return text .. "\n" .. utf8_sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
end

function EDITOR:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)

	local buffer = self:GetArea(selection)

	if start[1] ~= stop[1] or start[2] ~= stop[2] then
		-- clear selection
		self.Rows[start[1]] = utf8_sub(self.Rows[start[1]], 1, start[2] - 1) .. utf8_sub(self.Rows[stop[1]], stop[2])
		self.RowsLength[start[1]] = utf8_len(self.Rows[start[1]])
		self.PaintRows[start[1]] = false

		for _ = start[1] + 1, stop[1] do
			table_remove(self.Rows, start[1] + 1)
			table_remove(self.RowsLength, start[1] + 1)
			table_remove(self.PaintRows, start[1] + 1)
		end

		-- add empty row at end of file (TODO!)
		if self.Rows[#self.Rows] ~= "" then
			local index = #self.Rows + 1
			self.Rows[index] = ""
			self.RowsLength[index] = 0
			self.PaintRows[index] = false
		end
	end

	if not text or text == "" then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

		self:OnTextChanged()

		if isredo then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		elseif isundo then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		else
			self.Redo = {}
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start) }
			return start
		end
	end

	-- insert text
	local rows = string_Explode("\n", text)

	local remainder = utf8_sub(self.Rows[start[1]], start[2])
	local first_new_row = utf8_sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.Rows[start[1]] = first_new_row
	self.RowsLength[start[1]] = utf8_len(first_new_row)
	self.PaintRows[start[1]] = false

	for i=2,#rows do
		local index = start[1] + i - 1
		table_insert(self.Rows, index, rows[i])
		table_insert(self.RowsLength, index, utf8_len(rows[i]))
		table_insert(self.PaintRows, index, false)
	end

	stop = { start[1] + #rows - 1, utf8_len(self.Rows[start[1] + #rows - 1]) + 1 }

	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.RowsLength[stop[1]] = utf8_len(self.Rows[stop[1]])
	self.PaintRows[stop[1]] = false

	-- add empty row at end of file (TODO!)
	if self.Rows[#self.Rows] ~= "" then
		local index = #self.Rows + 1
		self.Rows[index] = ""
		self.RowsLength[index] = 0
		self.PaintRows[index] = false
	end

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

	self:OnTextChanged()

	if isredo then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	elseif isundo then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	else
		self.Redo = {}
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop) }
		return stop
	end
end


function EDITOR:GetSelection()
	return self:GetArea(self:Selection())
end

function EDITOR:SetSelection(text)
	self:SetCaret(self:SetArea(self:Selection(), text), false)
end

function EDITOR:OnTextChanged()
end

function EDITOR:_OnLoseFocus()
	if self.TabFocus then
		self:RequestFocus()
		self.TabFocus = nil
	end
end

-- removes the first 0-4 spaces from a string and returns it
local function unindent(line)
	--local i = line:find("%S")
	--if i == nil or i > 5 then i = 5 end
	--return line:sub(i)
	return line:match("^ ? ? ? ?(.*)$")
end

function EDITOR:_OnTextChanged()
	local ctrlv = false
	local text = self.TextEntry:GetText()
	self.TextEntry:SetText("")

	if (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and not (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
		-- ctrl+[shift+]key
		if input.IsKeyDown(KEY_V) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end

	if text == "" then return end
	if not ctrlv then
		if text == "\n" or input.IsKeyDown(KEY_BACKQUOTE) then return end
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
			return
		end
	end

	self:SetSelection(text)
	self:AC_Check()
end

function EDITOR:OnMouseWheeled(delta)
	if self.AC_Panel and self.AC_Panel:IsVisible() then
		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if mode == AC_STYLE_SCROLLER or mode == AC_STYLE_SCROLLER_ENTER then
			self.AC_Panel.Selected = self.AC_Panel.Selected - delta
			if self.AC_Panel.Selected > #self.AC_Suggestions then self.AC_Panel.Selected = 1 end
			if self.AC_Panel.Selected < 1 then self.AC_Panel.Selected = #self.AC_Suggestions end
			self:AC_FillInfoList( self.AC_Suggestions[self.AC_Panel.Selected] )
			self.AC_Panel:RequestFocus()
			return
		else
			self:AC_SetVisible(false)
		end
	end

	self.Scroll[1] = self.Scroll[1] - 4 * delta
	if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	if self.Scroll[1] > #self.Rows then self.Scroll[1] = #self.Rows end
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:OnShortcut()
end

function EDITOR:ScrollCaret()
	if self.Caret[1] - self.Scroll[1] < 2 then
		self.Scroll[1] = self.Caret[1] - 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end

	if self.Caret[1] - self.Scroll[1] > self.Size[1] - 2 then
		self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end

	if self.Caret[2] - self.Scroll[2] < 4 then
		self.Scroll[2] = self.Caret[2] - 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end

	if self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4 then
		self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end

	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

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

function EDITOR:CanUndo()
	return #self.Undo > 0
end

function EDITOR:DoUndo()
	if #self.Undo > 0 then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil

		self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]), false)
	end
end

function EDITOR:CanRedo()
	return #self.Redo > 0
end

function EDITOR:DoRedo()
	if #self.Redo > 0 then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil

		self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]), false)
	end
end

function EDITOR:SelectAll()
	self.Caret = {#self.Rows, self.RowsLength[#self.Rows] + 1}
	self.Start = {1, 1}
	self:ScrollCaret()
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

function EDITOR:Copy()
	if not self:HasSelection() then return end
	self.CurrentMode.clipboard = string_gsub(self:GetSelection(), "\n", "\r\n")
	return SetClipboardText(self.CurrentMode.clipboard)
end

function EDITOR:Cut()
	self:Copy()
	return self:SetSelection("")
end

-- TODO these two functions have no place in here
function EDITOR:PreviousTab()
	local parent = self:GetParent()

	local currentTab = parent:GetActiveTabIndex() - 1
	if currentTab < 1 then currentTab = currentTab + parent:GetNumTabs() end

	parent:SetActiveTabIndex(currentTab)
end

function EDITOR:NextTab()
	local parent = self:GetParent()

	local currentTab = parent:GetActiveTabIndex() + 1
	local numTabs = parent:GetNumTabs()
	if currentTab > numTabs then currentTab = currentTab - numTabs end

	parent:SetActiveTabIndex(currentTab)
end

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

function EDITOR:_OnKeyCodeTyped(code)
	local handled = true
	self.Blink = RealTime()

	local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	if alt then return end

	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

	-- allow ctrl-ins and shift-del (shift-ins, like ctrl-v, is handled by vgui)
	if not shift and control and code == KEY_INSERT then
		shift,control,code = true,false,KEY_C
	elseif shift and not control and code == KEY_DELETE then
		shift,control,code = false,true,KEY_X
	end

	if control then
		if code == KEY_A then
			self:SelectAll()
		elseif code == KEY_Z then
			self:DoUndo()
		elseif code == KEY_Y then
			self:DoRedo()
		elseif code == KEY_X then
			self:Cut()
		elseif code == KEY_C then
			self:Copy()
		-- pasting is now handled by the textbox that is used to capture input
		--[[
		elseif code == KEY_V then
			if self.CurrentMode.clipboard then
				self:SetSelection(self.CurrentMode.clipboard)
			end
		]]
		elseif code == KEY_F then
			self:OpenFindWindow( "find" )
		elseif code == KEY_H then
			self:OpenFindWindow( "find and replace" )
		elseif code == KEY_G then
			self:OpenFindWindow( "go to line" )
		elseif code == KEY_K then
			self:CommentSelection(shift)
		elseif code == KEY_L then
			self.Start = { self.Start[1], 1 }
			self.Caret = { self.Start[1] + 1, 1 }

			if not shift then self:Copy() end
			self:SetSelection("")
		elseif code == KEY_Q then
			self:GetParent():Close()
		elseif code == KEY_T then
			self:GetParent():NewTab()
		elseif code == KEY_W then
			self:GetParent():CloseTab()
		elseif code == KEY_PAGEUP then
			self:PreviousTab()
		elseif code == KEY_PAGEDOWN then
			self:NextTab()
		elseif code == KEY_UP then
			self.Scroll[1] = self.Scroll[1] - 1
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
		elseif code == KEY_DOWN then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif code == KEY_LEFT then
			self:SetCaret(self:wordLeft(self.Caret))
		elseif code == KEY_RIGHT then
			self:SetCaret(self:wordRight(self.Caret))
		--[[ -- old code that scrolls on ctrl-left/right:
		elseif code == KEY_LEFT then
			self.Scroll[2] = self.Scroll[2] - 1
			if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
		elseif code == KEY_RIGHT then
			self.Scroll[2] = self.Scroll[2] + 1
		]]
		elseif code == KEY_HOME then
			self:SetCaret({ 1, 1 })
		elseif code == KEY_END then
			self:SetCaret({ #self.Rows, 1 })
		elseif code == KEY_D then
			self:DuplicateLine()
		else
			handled = false
		end

	else

		if code == KEY_ENTER then
			local mode = wire_expression2_autocomplete_controlstyle:GetInt()
			if mode == AC_STYLE_ECLIPSE and self.AC_HasSuggestions and self.AC_Suggestions[1] and self.AC_Panel and self.AC_Panel:IsVisible() then
				if self:AC_Use( self.AC_Suggestions[1] ) then return end
			end

			local row = utf8_sub(self.Rows[self.Caret[1]], 1,self.Caret[2]-1)
			local diff = string.find(row, "%S")
			if diff ~= nil then
				diff = utf8_bytepos_to_charindex(row, diff) - 1
			else
				diff = utf8_len(row)
			end

			local tabs = string_rep("    ", math_floor(diff / 4))
			if GetConVarNumber('wire_expression2_autoindent') ~= 0 then
				local row = string_gsub(row,'%b""',"") -- erase strings on this line
				local _, num1 = string_gsub(row,"{","") -- count number of opening brackets
				local _, num2 = string_gsub(row,"%b{}","") -- count number of matching bracket pairs
				if num1 > num2 then tabs = tabs .. "    " end
			end

			self:SetSelection("\n" .. tabs)
		elseif code == KEY_UP then
			if self.AC_Panel and self.AC_Panel:IsVisible() then
				local mode = wire_expression2_autocomplete_controlstyle:GetInt()
				if mode == AC_STYLE_VISUALCSHARP or mode == AC_STYLE_ATOM then
					self.AC_Panel:RequestFocus()
					return
				end
			end

			self.Caret[1] = self.Caret[1] - 1
			self:SetCaret(self.Caret)
		elseif code == KEY_DOWN then
			if self.AC_Panel and self.AC_Panel:IsVisible() then
				local mode = wire_expression2_autocomplete_controlstyle:GetInt()
				if mode == AC_STYLE_VISUALCSHARP or mode == AC_STYLE_ATOM then
					self.AC_Panel:RequestFocus()
					return
				end
			end

			self.Caret[1] = self.Caret[1] + 1
			self:SetCaret(self.Caret)
		elseif code == KEY_LEFT then
			if self:HasSelection() and not shift then
				self:SetCaret(self.Caret, false)
			else
				self:SetCaret(self:MovePosition(self.Caret, -1))
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and not shift then
				self:SetCaret(self.Caret, false)
			else
				self:SetCaret(self:MovePosition(self.Caret, 1))
			end
		elseif code == KEY_PAGEUP then
			self.Caret[1] = self.Caret[1] - math_ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math_ceil(self.Size[1] / 2)
			self:SetCaret(self.Caret)
		elseif code == KEY_PAGEDOWN then
			self.Caret[1] = self.Caret[1] + math_ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math_ceil(self.Size[1] / 2)
			self:SetCaret(self.Caret)
		elseif code == KEY_HOME then
			local row = self.Rows[self.Caret[1]]
			local first_char = string.find(row, "%S")
			if first_char ~= nil then
				first_char = utf8_bytepos_to_charindex(row, first_char)
			else
				first_char = utf8_len(row)+1
			end
			if self.Caret[2] == first_char then
				self.Caret[2] = 1
			else
				self.Caret[2] = first_char
			end
			self:SetCaret(self.Caret)
		elseif code == KEY_END then
			local length = self.RowsLength[self.Caret[1]]
			self.Caret[2] = length + 1
			self:SetCaret(self.Caret)
		elseif code == KEY_BACKSPACE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
				local delta = -1
				if self.Caret[2] % 4 == 1 and #buffer > 0 and string_rep(" ", #buffer) == buffer then
					delta = -4
				end
				self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, delta)}))
			end
		elseif code == KEY_DELETE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
				local delta = 1
				if self.Caret[2] % 4 == 1 and string_rep(" ", #buffer) == buffer and self.RowsLength[self.Caret[1]] >= self.Caret[2] + 4 - 1 then
					delta = 4
				end
				self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, delta)}))
			end
		elseif code == KEY_F1 then
			self:ContextHelp()
		else
			handled = false
		end
	end

	if code == KEY_TAB and self.AC_Panel and self.AC_Panel:IsVisible() then
		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if mode == AC_STYLE_DEFAULT or mode == AC_STYLE_ECLIPSE or mode == AC_STYLE_ATOM then
			self.AC_Panel:RequestFocus()
			if (mode == AC_STYLE_ECLIPSE or mode == AC_STYLE_ATOM) and self.AC_Panel.Selected == 0 then self.AC_Panel.Selected = 1 end
			return
		end
		handled = true
	end

	if code == KEY_TAB or (control and (code == KEY_I or code == KEY_O)) then
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
		handled = true
	end

	if control and not handled then
		handled = self:OnShortcut(code)
	end

	self:AC_Check()

	return handled
end

---------------------------------------------------------------------------------------------------------
-- Auto Completion
-- By Divran
---------------------------------------------------------------------------------------------------------

function EDITOR:IsVarLine()
	local line = self.Rows[self.Caret[1]]
	local word = line:match( "^@(%w+)" )
	return word == "inputs" or word == "outputs" or word == "persist"
end

function EDITOR:IsDirectiveLine()
	local line = self.Rows[self.Caret[1]]
	return line:match( "^@" ) ~= nil
end

function EDITOR:getWordStart(caret,getword)
	local line = self.Rows[caret[1]]

	for startpos, endpos in string_gmatch(line, "()[a-zA-Z0-9_]+()") do -- "()%w+()"
		startpos = utf8_bytepos_to_charindex(line, startpos)
		endpos = utf8_bytepos_to_charindex(line, endpos) + 1
		if startpos <= caret[2] and caret[2] <= endpos then
			return { caret[1], startpos }, getword and utf8_sub(line, startpos,endpos-1) or nil
		end
	end
	return {caret[1],1}
end

function EDITOR:getWordEnd(caret,getword)
	local line = self.Rows[caret[1]]
	local linelen = self.RowsLength[caret[1]]

	for startpos, endpos in string_gmatch(line, "()[a-zA-Z0-9_]+()") do -- "()%w+()"
		startpos = utf8_bytepos_to_charindex(line, startpos)
		endpos = utf8_bytepos_to_charindex(line, endpos)
		if startpos <= caret[2] and caret[2] <= endpos then
			if endpos == linelen then
				endpos = endpos + 1
			end
			return { caret[1], endpos }, getword and utf8_sub(line, startpos,endpos-1) or nil
		end
	end
	return {caret[1],linelen+1}
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

function EDITOR:Think()
	self:DoAction("Think")
end

---------------------------------------------------------------------------------------------------------

-- helpers for ctrl-left/right
function EDITOR:wordLeft(caret)
	local row = self.Rows[caret[1]]
	if caret[2] == 1 then
		if caret[1] == 1 then return caret end
		caret = { caret[1]-1, self.RowsLength[caret[1]-1] }
		row = self.Rows[caret[1]]
	end

	local row_sub = utf8_sub(row,1,caret[2]-1)
	local pos = row_sub:match("[^%w@]()[%w@]+[^%w@]*$")
	if pos ~= nil then
		caret[2] = utf8_bytepos_to_charindex(row_sub, pos)
	else
		caret[2] = 1
	end

	return caret
end

function EDITOR:wordRight(caret)
	local row = self.Rows[caret[1]]
	if caret[2] > #row then
		if caret[1] == #self.Rows then return caret end
		caret = { caret[1]+1, 1 }
		row = self.Rows[caret[1]]
		if row[1] ~= " " then return caret end
	end

	local pos = row:match("[^%w@]()[%w@]",caret[2])
	if pos ~= nil then
		caret[2] = utf8_bytepos_to_charindex(row, pos)
	else
		caret[2] = utf8_len(row) + 1
	end

	return caret
end

function EDITOR:GetTokenAtPosition( caret )
	local column = caret[2]
	local line = self.PaintRows[caret[1]]
	if line then
		local startindex = 0
		for _, data in pairs( line ) do
			startindex = startindex+#data[1]
			if startindex >= column then return data[3] end
		end
	end
end

-- Syntax highlighting --------------------------------------------------------

function EDITOR:ResetTokenizer(row)
	self.line = self.Rows[row]
	self.position = 0 -- Position at current line (in codepoints)
	self.character = "" -- Current character (at self.position)
	self.tokendata = "" -- Currently-grabbed part of string

	self:DoAction("ResetTokenizer", row)
end

function EDITOR:NextCharacter()
	--MsgN("NextCharacter(),\tline '",self.line,"'")
	if not self.character then return end

	self.tokendata = self.tokendata .. self.character
	self.position = self.position + 1

	if self.position <= utf8_len(self.line) then
		self.character = utf8_GetChar(self.line, self.position)
	else
		self.character = nil
	end
	--MsgN("\t->Tk'",self.tokendata,"' Ch'",self.character,"'")
end

function EDITOR:SkipPattern(pattern)
	--MsgN("SkipPattern(", pattern,"),\tline '",self.line,"'")

	if not self.character then return nil end


	local position_byte = utf8.offset(self.line, self.position - 1)

	local startpos_byte,endpos_byte,text = string.find(self.line, pattern, position_byte)

	if startpos_byte == nil or endpos_byte <= 0 then return nil end

	--[[
	if endpos_byte <= 0  then
		endpos_byte = 1
	end]]

	local startpos = utf8_bytepos_to_charindex(self.line, startpos_byte)
	local endpos = utf8_bytepos_to_charindex(self.line, endpos_byte)

	if startpos ~= self.position then return nil end

	-- If pattern has no capture group,
	-- use complete string matched by pattern
	if text == nil then
		local buf = utf8_sub(self.line, startpos, endpos)
		text = buf
	end

	self.position = endpos + 1
	if self.position <= utf8_len(self.line) then
		self.character = utf8_GetChar(self.line, self.position)
	else
		self.character = nil
	end
	--MsgN("\t->Tx'",text,"' Ch'",self.character,"'")
	return text
end

function EDITOR:NextPattern(pattern)
	--MsgN("NextPattern")

	local matched = self:SkipPattern(pattern)
	if matched == nil then return false end

	self.tokendata = self.tokendata .. matched

	return true
end

function EDITOR:GetSyntaxColor(name)
	return self.Colors[name] or self:DoAction("GetSyntaxColor", name)
end

function EDITOR:SetSyntaxColors(colors)
	for name, color in pairs(colors) do
		self:SetSyntaxColor(name, color)
	end
end

function EDITOR:SetSyntaxColor(name, color)
	if self.Colors[name] then
		self.Colors[name] = color
	else
		return self:DoAction("SetSyntaxColor", name, color)
	end
end

function EDITOR:SyntaxColorLine(row)
	return self:DoAction("SyntaxColorLine", row)
end

-- register editor panel
vgui.Register("Expression2Editor", EDITOR, "Panel");

concommand.Add("wire_expression2_reloadeditor", function(ply, command, args)
	local code = wire_expression2_editor and wire_expression2_editor:GetCode()
	wire_expression2_editor = nil
	ZCPU_Editor = nil
	ZGPU_Editor = nil
	E2_RELOAD_EDITOR = true
	include("wire/client/text_editor/texteditor.lua")
	include("wire/client/text_editor/wire_expression2_editor.lua")
	E2_RELOAD_EDITOR = nil
	initE2Editor()
	if code then wire_expression2_editor:SetCode(code) end
end)
