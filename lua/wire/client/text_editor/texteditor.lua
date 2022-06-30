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

local utf8_len = utf8.len_checked
local utf8_bytepos_to_charindex = utf8.bytepos_to_charindex
local utf8_reverse = utf8.reverse



WireTextEditor = { Modes = {} }
include("modes/e2.lua")
include("modes/zcpu.lua")
WireTextEditor.Modes.Default = { SyntaxColorLine = function(self, row) return { { self.Rows[row], { Color(255, 255, 255, 255), false } } } end }

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

-- TODO: cache me
function EDITOR:GetCharPosInLine(row, search_index)
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

	-- TODO: realy slow due to utf8_sub!
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
				-- TODO: replace with string.sub, cache offset
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

function EDITOR:PaintCaret()
	if not self.TextEntry:HasFocus() then
		return
	end

	local scroll_pos_x = (self.Scroll[2] - 1) * self.FontWidth
	local caret_pos_x = self:GetCharPosInLine(self.Caret[1], self.Caret[2])

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
	self:PaintCaretPos()


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

	if self:CustomEntryProcess(text, ctrlv) then
		return
	end

	self:SetSelection(text)
	self:AC_Check()
end

function EDITOR:OnMouseWheeled(delta)
	if self:AC_HandleMouseScroll(delta) then return end

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



function EDITOR:_OnKeyCodeTyped(code)
	local handled = true
	self.Blink = RealTime()

	local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	

	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)

	-- allow ctrl-ins and shift-del (shift-ins, like ctrl-v, is handled by vgui)
	if not shift and control and code == KEY_INSERT then
		shift,control,code = true,false,KEY_C
	elseif shift and not control and code == KEY_DELETE then
		shift,control,code = false,true,KEY_X
	end

	if self:AC_HandleKey(code, control, shift, alt) then
		return
	end

	if self:Tool_HandleKey(code, control, shift, alt) then
		self:AC_Check()
		return true
	end

	if alt then return end

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
		else
			handled = false
		end

	else

		if code == KEY_ENTER then
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
			self.Caret[1] = self.Caret[1] - 1
			self:SetCaret(self.Caret)
		elseif code == KEY_DOWN then
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
		else
			handled = false
		end
	end



	if control and not handled then
		handled = self:OnShortcut(code)
	end

	self:AC_Check()

	return handled
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

include("autocomplete.lua")
include("tools.lua")

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
