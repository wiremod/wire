/******************************************************************************\
  Expression 2 Text Editor for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

local string_Explode = string.Explode
local table_concat = table.concat
local string_sub = string.sub
local table_remove = table.remove
local math_floor = math.floor
local math_Clamp = math.Clamp
local math_ceil = math.ceil
local string_match = string.match
local string_gmatch = string.gmatch
local string_gsub = string.gsub
local string_rep = string.rep
local string_byte = string.byte
local string_format = string.format
local string_Trim = string.Trim
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

local wire_expression2_autocomplete_controlstyle = CreateClientConVar( "wire_expression2_autocomplete_controlstyle", "0", true, false )

local EDITOR = {}

function EDITOR:Init()
	self:SetCursor("beam")

	self.Rows = {""}
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Size = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}

	self.LineNumberWidth = 2

	self.Blink = RealTime()

	self.ScrollBar = vgui.Create("DVScrollBar", self)
	self.ScrollBar:SetUp(1, 1)

	self.TextEntry = vgui.Create("TextEntry", self)
	self.TextEntry:SetMultiline(true)
	self.TextEntry:SetSize(0, 0)

	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus() end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged() end
	self.TextEntry.OnKeyCodeTyped = function (self, code) self.Parent:_OnKeyCodeTyped(code) end

	self.TextEntry.Parent = self

	self.LastClick = 0

	self.e2fs_functions = {}
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
	local char = math_floor(x / self.FontWidth+0.5)

	line = line + self.Scroll[1]
	char = char + self.Scroll[2]

	if line > #self.Rows then line = #self.Rows end
	local length = #self.Rows[line]
	if char > length + 1 then char = length + 1 end

	return { line, char }
end

local wire_expression2_editor_highlight_on_double_click = CreateClientConVar( "wire_expression2_editor_highlight_on_double_click", "1", true, false )
local wire_expression2_editor_color_dblclickhighlight = CreateClientConVar( "wire_expression2_editor_color_dblclickhighlight", "0_100_0_100", true, false )
local def = Color(0,100,0,100)
local function GetHighlightColor()
	local r,g,b,a = wire_expression2_editor_color_dblclickhighlight:GetString():match( "(%d+)_(%d+)_(%d+)_(%d+)" )
	return tonumber(r) or def.r,tonumber(g) or def.g,tonumber(b) or def.b, tonumber(a) or def.a
end

function EDITOR:OnMousePressed(code)
	if code == MOUSE_LEFT then
		local cursor = self:CursorToCaret()
		if((CurTime() - self.LastClick) < 1 and self.tmp and cursor[1] == self.Caret[1] and cursor[2] == self.Caret[2]) then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.tmp = false

			if (wire_expression2_editor_highlight_on_double_click:GetBool()) then
				self.HighlightedAreasByDoubleClick = {}
				local all_finds = self:FindAll( self:GetSelection(), true )
				if (all_finds) then
					for i=1,#all_finds do
						local start = all_finds[i][1]-1
						local stop = all_finds[i][2]-1
						local caretstart = self:MovePosition( {1,1}, start )
						local caretstop = self:MovePosition( {1,1}, stop )
						local wordstart, wordstop = self:getWordStart( caretstart ), self:getWordEnd( caretstart )

						-- This massive if block checks a) if it's NOT the word the user just highlighted and b) if the string is its own word and not part of another word
						if ((caretstart[1] != self.Start[1] or caretstart[2] != self.Start[2] or
							caretstop[1] != self.Caret[1] or caretstop[2] != self.Caret[2]) and
							(caretstart[1] == wordstart[1] and caretstart[2] == wordstart[2] and
							caretstop[1] == wordstop[1] and caretstop[2] == wordstop[2])) then

								self:HighlightArea( { caretstart, caretstop }, GetHighlightColor() )
								self.HighlightedAreasByDoubleClick[#self.HighlightedAreasByDoubleClick+1] = { caretstart, caretstop }
						end
					end
				end
			end
			return
		elseif (self.HighlightedAreasByDoubleClick) then
			for i=1,#self.HighlightedAreasByDoubleClick do
				self:HighlightArea( self.HighlightedAreasByDoubleClick[i] )
			end
			self.HighlightedAreasByDoubleClick = nil
		end

		self.tmp = true

		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true

		self.Caret = self:CopyPosition( cursor )
		if !input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT) then
			self.Start = self:CopyPosition( cursor )
		end
		self:AC_Check()
	elseif code == MOUSE_RIGHT then
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
				if self:HasSelection() then
					self.clipboard = self:GetSelection()
					self.clipboard = string_gsub(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
					self:SetSelection()
				end
			end)
			menu:AddOption("Copy", function()
				if self:HasSelection() then
					self.clipboard = self:GetSelection()
					self.clipboard = string_gsub(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
				end
			end)
		end

		menu:AddOption("Paste", function()
			if self.clipboard then
				self:SetSelection(self.clipboard)
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
		if (not self:GetParent().E2) then
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

		menu:AddSpacer()

		menu:AddOption( "Copy with BBCode colors", function()
			local str = string_format( "[code][font=%s]", self:GetParent().FontConVar:GetString() )

			local prev_colors
			local first_loop = true

			for i=1,#self.Rows do
			local colors = self:SyntaxColorLine(i)

				for k,v in pairs( colors ) do
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

			self.clipboard = str
			SetClipboardText( str )
		end)

		menu:Open()
	end
end

function EDITOR:OnMouseReleased(code)
	if !self.MouseDown then return end

	if code == MOUSE_LEFT then
		self.MouseDown = nil
		if(!self.tmp) then return end
		self.Caret = self:CursorToCaret()
	end
end

function EDITOR:SetText(text)
	self.Rows = string_Explode("\n", text)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
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
	return string_gsub(table_concat(self.Rows, "\n"), "\r", "")
end

function EDITOR:HighlightLine( line, r, g, b, a )
	if (!self.HighlightedLines) then self.HighlightedLines = {} end
	if (!r and self.HighlightedLines[line]) then
		self.HighlightedLines[line] = nil
		return true
	elseif (r and g and b and a) then
		self.HighlightedLines[line] = { r, g, b, a }
		return true
	end
	return false
end
function EDITOR:ClearHighlightedLines() self.HighlightedLines = nil end

function EDITOR:PaintLine(row)
	if row > #self.Rows then return end

	if !self.PaintRows[row] then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end

	local width, height = self.FontWidth, self.FontHeight

	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		surface_SetDrawColor(48, 48, 48, 255)
		surface_DrawRect(self.LineNumberWidth + 5, (row - self.Scroll[1]) * height, self:GetWide() - (self.LineNumberWidth + 5), height)
	end

	if (self.HighlightedLines and self.HighlightedLines[row]) then
		local color = self.HighlightedLines[row]
		surface_SetDrawColor( color[1], color[2], color[3], color[4] )
		surface_DrawRect(self.LineNumberWidth + 5, (row - self.Scroll[1]) * height, self:GetWide() - (self.LineNumberWidth + 5), height)
	end

	if self:HasSelection() then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]

		surface_SetDrawColor(0, 0, 160, 255)
		local length = self.Rows[row]:len() - self.Scroll[2] + 1

		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if char < 0 then char = 0 end
		if endchar < 0 then endchar = 0 end

		if row == line and line == endline then
			surface_DrawRect(char * width + self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif row == line then
			surface_DrawRect(char * width + self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif row == endline then
			surface_DrawRect(self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif row > line and row < endline then
			surface_DrawRect(self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end


	draw_SimpleText(tostring(row), self.CurrentFont, self.LineNumberWidth + 2, (row - self.Scroll[1]) * height, Color(128, 128, 128, 255), TEXT_ALIGN_RIGHT)

	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if offset < 0 then
			if cell[1]:len() > -offset then
				line = cell[1]:sub(1-offset)
				offset = line:len()

				if cell[2][2] then
					draw_SimpleText(line .. " ", self.CurrentFont .. "_Bold", self.LineNumberWidth+ 6, (row - self.Scroll[1]) * height, cell[2][1])
				else
					draw_SimpleText(line .. " ", self.CurrentFont, self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, cell[2][1])
				end
			else
				offset = offset + cell[1]:len()
			end
		else
			if cell[2][2] then
				draw_SimpleText(cell[1] .. " ", self.CurrentFont .. "_Bold", offset * width + self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, cell[2][1])
			else
				draw_SimpleText(cell[1] .. " ", self.CurrentFont, offset * width + self.LineNumberWidth + 6, (row - self.Scroll[1]) * height, cell[2][1])
			end

			offset = offset + cell[1]:len()
		end
	end


end

function EDITOR:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)

	self.Size[1] = math_floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math_floor((self:GetWide() - (self.LineNumberWidth + 6) - 16) / self.FontWidth) - 1

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:HighlightArea( area, r,g,b,a )
	if (!self.HighlightedAreas) then self.HighlightedAreas = {} end
	if (!r) then
		local _start, _stop = area[1], area[2]
		for k,v in pairs( self.HighlightedAreas ) do
			local start = v[1][1]
			local stop = v[1][2]
			if (start[1] == _start[1] and start[2] == _start[2] and stop[1] == _stop[1] and stop[2] == _stop[2]) then
				table.remove( self.HighlightedAreas, k )
				break
			end
		end
		return true
	elseif (r and g and b and a) then
		self.HighlightedAreas[#self.HighlightedAreas+1] = {area, r, g, b, a }
		return true
	end
	return false
end
function EDITOR:ClearHighlightedAreas() self.HighlightedAreas = nil end

function EDITOR:PaintTextOverlay()

	if self.TextEntry:HasFocus() and self.Caret[2] - self.Scroll[2] >= 0 then
		local width, height = self.FontWidth, self.FontHeight

		if (RealTime() - self.Blink) % 0.8 < 0.4 then
			surface_SetDrawColor(240, 240, 240, 255)
			surface_DrawRect((self.Caret[2] - self.Scroll[2]) * width + self.LineNumberWidth + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
		end

		-- Area highlighting
		if (self.HighlightedAreas) then
			local xofs = self.LineNumberWidth + 6
			for key, data in pairs( self.HighlightedAreas ) do
				local area, r,g,b,a = data[1], data[2], data[3], data[4], data[5]
				surface_SetDrawColor( r,g,b,a )
				local start, stop = self:MakeSelection( area )

				if (start[1] == stop[1]) then -- On the same line
					surface_DrawRect( xofs + (start[2]-self.Scroll[2]) * width, (start[1]-self.Scroll[1]) * height, (stop[2]-start[2]) * width, height )
				elseif (start[1] < stop[1]) then -- Ends below start
					for i=start[1],stop[1] do
						if (i == start[1]) then
							surface_DrawRect( xofs + (start[2]-self.Scroll[2]) * width, (i-self.Scroll[1]) * height, (#self.Rows[start[1]]-start[2]) * width, height )
						elseif (i == stop[1]) then
							surface_DrawRect( xofs + (self.Scroll[2]-1) * width, (i-self.Scroll[1]) * height, (#self.Rows[stop[1]]-stop[2]) * width, height )
						else
							surface_DrawRect( xofs + (self.Scroll[2]-1) * width, (i-self.Scroll[1]) * height, #self.Rows[i] * width, height )
						end
					end
				end
			end
		end

		-- Bracket highlighting by: {Jeremydeath}
		local WindowText = self:GetValue()
		local LinePos = table_concat(self.Rows, "\n", 1, self.Caret[1]-1):len()
		local CaretPos = LinePos+self.Caret[2]+1

		local BracketPairs = {
			["{"] = "}",
			["}"] = "{",
			["["] = "]",
			["]"] = "[",
			["("] = ")",
			[")"] = "("
		}

		local CaretChars = WindowText:sub(CaretPos-1, CaretPos)
		local BrackSt, BrackEnd = CaretChars:find("[%(%){}%[%]]")

		local Bracket = false
		if BrackSt and BrackSt != 0 then
			Bracket = CaretChars:sub(BrackSt or 0,BrackEnd or 0)
		end
		if Bracket and BracketPairs[Bracket] then
			local End = 0
			local EndX = 1
			local EndLine = 1
			local StartX = 1

			if Bracket == "(" or Bracket == "[" or Bracket == "{" then
				BrackSt,End = WindowText:find("%b"..Bracket..BracketPairs[Bracket], CaretPos-1)

				if BrackSt and End then
					local OffsetSt = 1

					local BracketLines = string_Explode("\n",WindowText:sub(BrackSt, End))

					EndLine = self.Caret[1]+#BracketLines-1

					EndX = End-LinePos-2
					if #BracketLines>1 then
						EndX = BracketLines[#BracketLines]:len()-1
					end

					if Bracket == "{" then
						OffsetSt = 0
					end

					if (CaretPos - BrackSt) >= 0 and (CaretPos - BrackSt) <= 1 then
						local width, height = self.FontWidth, self.FontHeight
						local StartX = BrackSt - LinePos - 2
						surface_SetDrawColor(255, 0, 0, 50)
						surface_DrawRect((StartX-(self.Scroll[2]-1)) * width + self.LineNumberWidth + self.FontWidth + OffsetSt - 1, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
						surface_DrawRect((EndX-(self.Scroll[2]-1)) * width + self.LineNumberWidth + 6, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			elseif Bracket == ")" or Bracket == "]" or Bracket == "}" then
				BrackSt,End = WindowText:reverse():find("%b"..Bracket..BracketPairs[Bracket], -CaretPos)
				if BrackSt and End then
					local len = WindowText:len()
					End = len-End+1
					BrackSt = len-BrackSt+1
					local BracketLines = string_Explode("\n",WindowText:sub(End, BrackSt))

					EndLine = self.Caret[1]-#BracketLines+1

					local OffsetSt = -1

					EndX = End-LinePos-2
					if #BracketLines>1 then
						local PrevText = WindowText:sub(1, End):reverse()

						EndX = (PrevText:find("\n",1,true) or 2)-2
					end

					if Bracket != "}" then
						OffsetSt = 0
					end

					if (CaretPos - BrackSt) >= 0 and (CaretPos - BrackSt) <= 1 then
						local width, height = self.FontWidth, self.FontHeight
						local StartX = BrackSt - LinePos - 2
						surface_SetDrawColor(255, 0, 0, 50)
						surface_DrawRect((StartX-(self.Scroll[2]-1)) * width + self.LineNumberWidth + self.FontWidth - 2, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
						surface_DrawRect((EndX-(self.Scroll[2]-1)) * width + self.LineNumberWidth + 8 + OffsetSt, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			end
		end
	end
end

local wire_expression2_editor_display_caret_pos = CreateClientConVar("wire_expression2_editor_display_caret_pos","0",true,false)

function EDITOR:Paint()
	self.LineNumberWidth = self.FontWidth * #tostring(self.Scroll[1]+self.Size[1]+1)

	if !input.IsMouseDown(MOUSE_LEFT) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if !self.PaintRows then
		self.PaintRows = {}
	end

	if self.MouseDown then
		self.Caret = self:CursorToCaret()
	end

	surface_SetDrawColor(0, 0, 0, 255)
	surface_DrawRect(0, 0, self.LineNumberWidth + 4, self:GetTall())

	surface_SetDrawColor(32, 32, 32, 255)
	surface_DrawRect(self.LineNumberWidth + 5, 0, self:GetWide() - (self.LineNumberWidth + 5), self:GetTall())

	self.Scroll[1] = math_floor(self.ScrollBar:GetScroll() + 1)

	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end

	-- Paint the overlay of the text (bracket highlighting and carret postition)
	self:PaintTextOverlay()

	if (wire_expression2_editor_display_caret_pos:GetBool()) then
		local str = "Length: " .. #self:GetValue() .. " Lines: " .. #self.Rows .. " Ln: " .. self.Caret[1] .. " Col: " .. self.Caret[2]
		if (self:HasSelection()) then
			str = str .. " Sel: " .. #self:GetSelection()
		end
		surface_SetFont( "Default" )
		local w,h = surface_GetTextSize( str )
		local _w, _h = self:GetSize()
		draw_WordBox( 4, _w - w - (self.ScrollBar:IsVisible() and 16 or 0) - 10, _h - h - 10, str, "Default", Color( 0,0,0,100 ), Color( 255,255,255,255 ) )
	end

	-- Paint CPU debug hints
	if self.CurrentVarValue then
		local pos = self.CurrentVarValue[1]
		local x, y = (pos[2]+2) * self.FontWidth, (pos[1]-1-self.Scroll[1]) * self.FontHeight
		local txt = CPULib.GetDebugPopupText(self.CurrentVarValue[2])
		if txt then
			draw_WordBox(2, x, y, txt, "E2SmallFont", Color(0,0,0,255), Color(255,255,255,255) )
		end
	end

	if not self:GetParent().E2 then
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

	return true
end

function EDITOR:SetCaret(caret)
	self.Caret = self:CopyPosition(caret)
	self.Start = self:CopyPosition(caret)
	self:ScrollCaret()
end


function EDITOR:CopyPosition(caret)
	return { caret[1], caret[2] }
end

function EDITOR:MovePosition(caret, offset)
	local caret = { caret[1], caret[2] }

	if offset > 0 then
		while true do
			local length = #(self.Rows[caret[1]]) - caret[2] + 2
			if offset < length then
				caret[2] = caret[2] + offset
				break
			elseif caret[1] == #self.Rows then
				caret[2] = caret[2] + length - 1
				break
			else
				offset = offset - length
				caret[1] = caret[1] + 1
				caret[2] = 1
			end
		end
	elseif offset < 0 then
		offset = -offset

		while true do
			if offset < caret[2] then
				caret[2] = caret[2] - offset
				break
			elseif caret[1] == 1 then
				caret[2] = 1
				break
			else
				offset = offset - caret[2]
				caret[1] = caret[1] - 1
				caret[2] = #(self.Rows[caret[1]]) + 1
			end
		end
	end

	return caret
end


function EDITOR:HasSelection()
	return self.Caret[1] != self.Start[1] || self.Caret[2] != self.Start[2]
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
		return string_sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string_sub(self.Rows[start[1]], start[2])

		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end

		return text .. "\n" .. string_sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
end

function EDITOR:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)

	local buffer = self:GetArea(selection)

	if start[1] != stop[1] or start[2] != stop[2] then
		// clear selection
		self.Rows[start[1]] = string_sub(self.Rows[start[1]], 1, start[2] - 1) .. string_sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false

		for i=start[1]+1,stop[1] do
			table_remove(self.Rows, start[1] + 1)
			table_remove(self.PaintRows, start[1] + 1)
			self.PaintRows = {} // TODO: fix for cache errors
		end

		// add empty row at end of file (TODO!)
		if self.Rows[#self.Rows] != "" then
			self.Rows[#self.Rows + 1] = ""
			self.PaintRows[#self.Rows + 1] = false
		end
	end

	if !text or text == "" then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

		self.PaintRows = {}

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

	// insert text
	local rows = string_Explode("\n", text)

	local remainder = string_sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string_sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false

	for i=2,#rows do
		table_insert(self.Rows, start[1] + i - 1, rows[i])
		table_insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end

	local stop = { start[1] + #rows - 1, #(self.Rows[start[1] + #rows - 1]) + 1 }

	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false

	// add empty row at end of file (TODO!)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
		self.PaintRows[#self.Rows + 1] = false
		self.PaintRows = {} // TODO: fix for cache errors
	end

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)

	self.PaintRows = {}

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
	self:SetCaret(self:SetArea(self:Selection(), text))
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
	local text = self.TextEntry:GetValue()
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
		if text == "\n" then return end
		if text == "}" and GetConVarNumber('wire_expression2_autoindent') ~= 0 then
			self:SetSelection(text)
			local row = self.Rows[self.Caret[1]]
			if string_match("{" .. row, "^%b{}.*$") then
				local newrow = unindent(row)
				self.Rows[self.Caret[1]] = newrow
				self.Caret[2] = self.Caret[2] + newrow:len()-row:len()
				self.Start[2] = self.Caret[2]
			end
			return
		end
	end

	self:SetSelection(text)
	self:AC_Check()
end

function EDITOR:OnMouseWheeled(delta)
	if (self.AC_Panel and self.AC_Panel:IsVisible()) then
		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if (mode == 2 or mode == 3) then
			self.AC_Panel.Selected = self.AC_Panel.Selected - delta
			if (self.AC_Panel.Selected > #self.AC_Suggestions) then self.AC_Panel.Selected = 1 end
			if (self.AC_Panel.Selected < 1) then self.AC_Panel.Selected = #self.AC_Suggestions end
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
	local caretstart = caretstart or self:CopyPosition( self.Start )
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
	if (looped and looped >= 2) then return end
	if (str == "") then return end
	local _str = str

	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local wrap_around = wire_expression2_editor_find_wrap_around:GetBool()
	local dir = wire_expression2_editor_find_dir:GetBool()

	-- Check if the match exists anywhere at all
	local temptext = self:GetValue()
	if (ignore_case) then
		temptext = temptext:lower()
		str = str:lower()
	end
	local _start,_stop = temptext:find( str, 1, !use_patterns )
	if (!_start or !_stop) then return false end

	if (dir) then -- Down
		local line = self.Rows[self.Start[1]]
		local text = line:sub(self.Start[2]) .. "\n"
		text = text .. table_concat( self.Rows, "\n", self.Start[1]+1 )
		if (ignore_case) then text = text:lower() end

		local offset = 2
		for loop = 1, 100 do
			local start, stop = text:find( str, offset, !use_patterns )
			if (start and stop) then

				if (whole_word_only) then
					local caretstart = self:MovePosition( self.Start, start )
					caretstart = { caretstart[1], caretstart[2]-1 }
					local caretstop = self:MovePosition( self.Start, stop )
					caretstop = { caretstop[1], caretstop[2]-1 }
					local wstart = self:getWordStart( { caretstart[1], caretstart[2]+1 } )
					local wstop = self:getWordEnd( { caretstart[1], caretstart[2]+1 } )
					if (caretstart[1] == wstart[1] and caretstop[1] == wstop[1] and
						caretstart[2] == wstart[2] and caretstop[2]+1 == wstop[2]) then
							self:HighlightFoundWord( nil, caretstart, caretstop )
							return true
					else
						offset = start+1
					end
				else
					self:HighlightFoundWord( nil, start-1, stop-1 )
					return true
				end

			else
				break
			end
			if (loop == 100) then error("\nInfinite loop protection enabled.\nPlease provide a detailed description of what you were doing when you got this error on www.wiremod.com.\n") return end
		end

		if (wrap_around) then
			self:SetCaret( {1,1} )
			self:Find( _str, (looped or 0) + 1 )
		end
	else
		local text = table_concat( self.Rows, "\n", 1, self.Start[1]-1 )
		local line = self.Rows[self.Start[1]]
		text = text .. "\n" .. line:sub( 1, self.Start[2]-1 )

		local found
		local offset = 2
		for loop = 1, 100 do
			local start, stop = text:find( str, offset, !use_patterns )
			if (start and stop) then
				if (whole_word_only) then
					local caretstart = self:MovePosition( {1,1}, start )
					caretstart = { caretstart[1], caretstart[2]-1 }
					local caretstop = self:MovePosition( {1,1}, stop )
					caretstop = { caretstop[1], caretstop[2]-1 }
					local wstart = self:getWordStart( { caretstart[1], caretstart[2]+1 } )
					local wstop = self:getWordEnd( { caretstart[1], caretstart[2]+1 } )
					if (caretstart[1] == wstart[1] and caretstop[1] == wstop[1] and
						caretstart[2] == wstart[2] and caretstop[2]+1 == wstop[2]) then
							found = { caretstart, caretstop }
							if ((caretstop[1] == self.Start[1] and caretstop[2] >= self.Start[2]) or (caretstop[1] > self.Start[1])) then break end
					else
						offset = start+1
					end
				else
					found = { start-1, stop-1 }

					local caretstop = self:MovePosition( {1,1}, stop )
					if ((caretstop[1] == self.Start[1] and caretstop[2] >= self.Start[2]) or (caretstop[1] > self.Start[1])) then break end
				end
				offset = start+1
			else
				break
			end
			if (loop == 100) then error("\nInfinite loop protection enabled.\nPlease provide a detailed description of what you were doing when you got this error on www.wiremod.com.\n(Except if you were trying to find the patterns '.-' or '.?' or something similar. Then it's your own fault!)\n") return end
		end

		if (found) then
			self:HighlightFoundWord( {1,1}, found[1], found[2] )
			return true
		end

		if (wrap_around) then
			self:SetCaret( {#self.Rows,#self.Rows[#self.Rows]} )
			self:Find( _str, (looped or 0) + 1 )
		end
	end
	return false
end

function EDITOR:Replace( str, replacewith )
	if (str == "" or str == replacewith) then return end

	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	local selection = self:GetSelection()

	local _str = str
	if (!use_patterns) then
		str = str:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
		replacewith = replacewith:gsub( "%%", "%%%1" )
	end

	if (selection:match( str ) != nil) then
		self:SetSelection( selection:gsub( str, replacewith ) )
		return self:Find( _str )
	else
		return self:Find( _str )
	end
end

function EDITOR:ReplaceAll( str, replacewith )
	if (str == "") then return end

	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	if (!use_patterns) then
		str = str:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
		replacewith = replacewith:gsub( "%%", "%%%1" )
	end

	local txt = self:GetValue()

	if ignore_case then
		local txt2 = txt -- Store original cased copy
		str = str:lower() -- Lowercase everything
		txt = txt:lower() -- Lowercase everything

		local pattern = "()"..str.."()"
		if whole_word_only then pattern = "[^a-zA-Z0-9_]()"..str.."()[^a-zA-Z0-9_]" end

		local positions = {}

		for startpos, endpos in string_gmatch( txt, pattern ) do
			positions[#positions+1] = {startpos,endpos}
		end

		-- Do the replacing backwards, or it won't work
		for i=#positions,1,-1 do
			local startpos, endpos = positions[i][1], positions[i][2]
			txt2 = string_sub(txt2,1,startpos-1) .. replacewith .. string_sub(txt2,endpos)
		end

		-- Replace everything with the edited copy
		self:SelectAll()
		self:SetSelection( txt2 )
	else
		if (whole_word_only) then
			local pattern = "([^a-zA-Z0-9_])"..str.."([^a-zA-Z0-9_])"
			txt = " " .. txt
			txt = string_gsub( txt, pattern, "%1"..replacewith.."%2" )
			txt = string_gsub( txt, pattern, "%1"..replacewith.."%2" )
			txt = string_sub( txt, 2 )
		else
			txt = string_gsub( txt, str, replacewith )
		end

		self:SelectAll()
		self:SetSelection( txt )
	end
end

function EDITOR:CountFinds( str )
	if (str == "") then return 0 end

	local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
	local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
	local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()

	if (!use_patterns) then
		str = str:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )
	end

	local txt = self:GetValue()

	if (ignore_case) then
		txt = txt:lower()
		str = str:lower()
	end

	if (whole_word_only) then
		local pattern = "([^a-zA-Z0-9_])"..str.."([^a-zA-Z0-9_])"
		txt = " " .. txt
		local num1, num2 = 0, 0
		txt, num1 = txt:gsub( pattern, "%1%2" )
		if (txt == "") then return num1 end
		txt, num2 = txt:gsub( pattern, "%1%2" )
		return num1+num2
	else
		local num
		txt, num = txt:gsub( str, "" )
		return num
	end
end

function EDITOR:FindAll( str, skip_extras )
	if str == "" then return end

	local txt = self:GetValue()
	local pattern

	if skip_extras then
		pattern = "()" .. str:gsub("[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1") .. "()"
	else
		local use_patterns = wire_expression2_editor_find_use_patterns:GetBool()
		if use_patterns then
			pattern = "()" .. str .. "()"
		else
			pattern = "()" .. str:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" ) .. "()"
		end
		
		local ignore_case = wire_expression2_editor_find_ignore_case:GetBool()
		if ignore_case then
			txt = txt:lower()
			pattern = pattern:lower()
		end

		local whole_word_only = wire_expression2_editor_find_whole_word_only:GetBool()
		if whole_word_only then
			pattern = "[^a-zA-Z0-9_]" .. pattern .. "[^a-zA-Z0-9_]"
		end
	end

	local ret = {}
	for start,stop in txt:gmatch( pattern ) do
		ret[#ret+1] = { start, stop }
	end

	return ret
end

function EDITOR:CreateFindWindow()
	self.FindWindow = vgui.Create( "DFrame", self )

	local pnl = self.FindWindow
	pnl:SetSize( 320, 200 )
	pnl:ShowCloseButton( true )
	pnl:SetDeleteOnClose( false ) -- No need to create a new window every time
	pnl:MakePopup() -- Make it separate from the editor itself
	pnl:SetVisible( false ) -- but hide it for now
	pnl:SetTitle( "Find" )
	pnl:SetScreenLock( true )

	local old = pnl.Close
	function pnl.Close()
		self.ForceDrawCursor = false
		old( pnl )
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
	use_patterns:SetToolTip( "Use/Don't use Lua patterns in the find." )
	use_patterns:SizeToContents()
	use_patterns:SetConVar( "wire_expression2_editor_find_use_patterns" )
	use_patterns:SetPos( 4, 4 )
	local old = use_patterns.Button.SetValue
	use_patterns.Button.SetValue = function( pnl, b )
		if (wire_expression2_editor_find_whole_word_only:GetBool()) then return end
		old( pnl, b )
	end

	local case_sens = vgui.Create( "DCheckBoxLabel", common_panel )
	case_sens:SetText( "Ignore Case" )
	case_sens:SetToolTip( "Ignore/Don't ignore case in the find." )
	case_sens:SizeToContents()
	case_sens:SetConVar( "wire_expression2_editor_find_ignore_case" )
	case_sens:SetPos( 4, 24 )

	local whole_word = vgui.Create( "DCheckBoxLabel", common_panel )
	whole_word:SetText( "Match Whole Word" )
	whole_word:SetToolTip( "Match/Don't match the entire word in the find." )
	whole_word:SizeToContents()
	whole_word:SetConVar( "wire_expression2_editor_find_whole_word_only" )
	whole_word:SetPos( 4, 44 )
	local old = whole_word.Button.Toggle
	whole_word.Button.Toggle = function( pnl )
		old( pnl )
		if (pnl:GetValue()) then use_patterns:SetValue( false ) end
	end

	local wrap_around = vgui.Create( "DCheckBoxLabel", common_panel )
	wrap_around:SetText( "Wrap Around" )
	wrap_around:SetToolTip( "Start/Don't start from the top after reaching the bottom, or the bottom after reaching the top." )
	wrap_around:SizeToContents()
	wrap_around:SetConVar( "wire_expression2_editor_find_wrap_around" )
	wrap_around:SetPos( 130, 4 )

	local dir_down = vgui.Create( "DCheckBoxLabel", common_panel )
	local dir_up = vgui.Create( "DCheckBoxLabel", common_panel )

	dir_up:SetText( "Up" )
	dir_up:SizeToContents()
	dir_up:SetPos( 130, 24 )
	dir_up:SetValue( !wire_expression2_editor_find_dir:GetBool() )
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
	FindNext:SetToolTip( "Find the next match and highlight it." )
	FindNext:SetPos(233,4)
	FindNext:SetSize(70,20)
	FindNext.DoClick = function(pnl)
		self:Find( FindEntry:GetValue() )
	end

	-- Find button
	local Find = vgui.Create( "DButton", findtab )
	Find:SetText("Find")
	Find:SetToolTip( "Find the next match, highlight it, and close the Find window." )
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
	FindNext:SetToolTip( "Find the next match and highlight it." )
	FindNext:SetPos(233,4)
	FindNext:SetSize(70,20)
	FindNext.DoClick = function(pnl)
		self:Find( FindEntry:GetValue() )
	end

	-- Replace next button
	local ReplaceNext = vgui.Create( "DButton", replacetab )
	ReplaceNext:SetText("Replace")
	ReplaceNext:SetToolTip( "Replace the current selection if it matches, else find the next match." )
	ReplaceNext:SetPos(233,29)
	ReplaceNext:SetSize(70,20)
	ReplaceNext.DoClick = function(pnl)
		self:Replace( FindEntry:GetValue(), ReplaceEntry:GetValue() )
	end

	-- Replace all button
	local ReplaceAll = vgui.Create( "DButton", replacetab )
	ReplaceAll:SetText("Replace All")
	ReplaceAll:SetToolTip( "Replace all occurences of the match in the entire file, and close the Find window." )
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
	GoToEntry:SetText("")
	GoToEntry:SetNumeric( true )

	-- Goto Button
	local Goto = vgui.Create( "DButton", gototab )
	Goto:SetText("Go to Line")
	Goto:SetPos(233,4)
	Goto:SetSize(70,20)

	-- Action
	local function GoToAction(panel)
		local val = tonumber(GoToEntry:GetValue())
		if (val) then
			val = math_Clamp(val, 1, #self.Rows)
			self:SetCaret({val, #self.Rows[val] + 1})
		end
		GoToEntry:SetText(tostring(val))
		self.FindWindow:Close()
	end
	GoToEntry.OnEnter = GoToAction
	Goto.DoClick = GoToAction

	pnl.GoToLineTab = pnl.TabHolder:AddSheet( "Go to Line", gototab, "icon16/page_white_go.png", false, false )
	pnl.GoToLineTab.Entry = GoToEntry

	-- Tab buttons
	local old = pnl.FindTab.Tab.OnMousePressed
	pnl.FindTab.Tab.OnMousePressed = function( ... )
		pnl.FindTab.Entry:SetText( pnl.ReplaceTab.Entry:GetValue() or "" )
		local active = pnl.TabHolder:GetActiveTab()
		if (active == pnl.GoToLineTab.Tab) then
			pnl:SetHeight( 200 )
			pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
		end
		old( ... )
	end

	local old = pnl.ReplaceTab.Tab.OnMousePressed
	pnl.ReplaceTab.Tab.OnMousePressed = function( ... )
		pnl.ReplaceTab.Entry:SetText( pnl.FindTab.Entry:GetValue() or "" )
		local active = pnl.TabHolder:GetActiveTab()
		if (active == pnl.GoToLineTab.Tab) then
			pnl:SetHeight( 200 )
			pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
		end
		old( ... )
	end

	local old = pnl.GoToLineTab.Tab.OnMousePressed
	pnl.GoToLineTab.Tab.OnMousePressed = function( ... )
		pnl:SetHeight( 83 )
		pnl.TabHolder:StretchToParent( 1, 23, 1, 1 )
		old( ... )
	end
end

function EDITOR:OpenFindWindow( mode )
	if (!self.FindWindow) then self:CreateFindWindow() end
	self.FindWindow:SetVisible( true )
	self.FindWindow:MakePopup() -- This will move it above the E2 editor if it is behind it.
	self.ForceDrawCursor = true

	local selection = self:GetSelection():Left(100)

	if (mode == "find") then
		if (selection and selection != "") then self.FindWindow.FindTab.Entry:SetText( selection ) end
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.FindTab.Tab )
		self.FindWindow.FindTab.Entry:RequestFocus()
		self.FindWindow:SetHeight( 200 )
		self.FindWindow.TabHolder:StretchToParent( 1, 23, 1, 1 )
	elseif (mode == "find and replace") then
		if (selection and selection != "") then self.FindWindow.ReplaceTab.Entry:SetText( selection ) end
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.ReplaceTab.Tab )
		self.FindWindow.ReplaceTab.Entry:RequestFocus()
		self.FindWindow:SetHeight( 200 )
		self.FindWindow.TabHolder:StretchToParent( 1, 23, 1, 1 )
	elseif (mode == "go to line") then
		self.FindWindow.TabHolder:SetActiveTab( self.FindWindow.GoToLineTab.Tab )
		self.FindWindow.GoToLineTab.Entry:RequestFocus()
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

		self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]))
	end
end

function EDITOR:CanRedo()
	return #self.Redo > 0
end

function EDITOR:DoRedo()
	if #self.Redo > 0 then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil

		self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]))
	end
end

function EDITOR:SelectAll()
	self.Caret = {#self.Rows, #(self.Rows[#self.Rows]) + 1}
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

	if (tab_caret[2] ~= 1) then
		tab_caret[1] = tab_caret[1] + 1
		tab_caret[2] = 1
	end

	-- remember selection
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	if shift then
		-- shift-TAB with a selection --
		local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")

		-- makes sure that the first line is outdented
		self:SetSelection(unindent(tmp))
	else
		-- plain TAB with a selection --
		self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
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
	if (!self:HasSelection()) then return end

	local scroll = self:CopyPosition( self.Scroll )

	-- Remember selection
	local sel_start, sel_caret = self:MakeSelection( self:Selection() )

	if (self:GetParent().E2) then
		local str = self:GetSelection()
		if (removecomment) then
			if (str:find( "^#%[" ) and str:find( "%]#$" )) then
				self:SetSelection( str:gsub( "^#%[(.+)%]#$", "%1" ) )

				if (sel_caret[1] == sel_start[1]) then
					sel_caret[2] = sel_caret[2] - 4
				else
					sel_caret[2] = sel_caret[2] - 2
				end
			end
		else
			self:SetSelection( "#[" .. str .."]#" )

			if (sel_caret[1] == sel_start[1]) then
				sel_caret[2] = sel_caret[2] + 4
			else
				sel_caret[2] = sel_caret[2] + 2
			end
		end
	else
		local str = self:GetSelection()
		if (removecomment) then
			if (str:find( "^/%*" ) and str:find( "%*/$" )) then
				self:SetSelection( str:gsub( "^/%*(.+)%*/$", "%1" ) )

				sel_caret[2] = sel_caret[2] - 2
			end
		else
			self:SetSelection( "/*" .. str .. "*/" )

			if (sel_caret[1] == sel_start[1]) then
				sel_caret[2] = sel_caret[2] + 4
			else
				sel_caret[2] = sel_caret[2] + 2
			end
		end
	end

	-- restore selection
	self.Caret = sel_caret
	self.Start = sel_start
	-- restore scroll position
	self.Scroll = scroll
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

-- CommentSelection
-- Idea by Jeremydeath
-- Rewritten by Divran to use block comment
function EDITOR:CommentSelection( removecomment )
	if (!self:HasSelection()) then return end

	-- Remember scroll position
	local scroll = self:CopyPosition( self.Scroll )

	-- Normalize selection, so it spans whole lines
	local sel_start, sel_caret = self:MakeSelection( self:Selection() )
	sel_start[2] = 1

	if (sel_caret[2] != 1) then
		sel_caret[1] = sel_caret[1] + 1
		sel_caret[2] = 1
	end

	-- Remember selection
	self.Caret = self:CopyPosition( sel_caret )
	self.Start = self:CopyPosition( sel_start )
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end

	if (self:GetParent().E2) then -- For Expression 2
		local mode = self:GetParent().BlockCommentStyleConVar:GetInt()

		if (mode == 0) then -- New (alt 1)
			local str = self:GetSelection()
			if (removecomment) then
				if (str:find( "^#%[\n" ) and str:find( "\n%]#$" )) then
					self:SetSelection( str:gsub( "^#%[\n(.+)\n%]#$", "%1" ) )
					sel_caret[1] = sel_caret[1] - 2
				end
			else
				self:SetSelection( "#[\n" .. str .. "\n]#" )
				sel_caret[1] = sel_caret[1] + 1
				sel_caret[2] = 3
			end
		elseif (mode == 1) then -- New (alt 2)
			local str = self:GetSelection()
			if (removecomment) then
				if (str:find( "^#%[" ) and str:find( "%]#$" )) then
					self:SetSelection( str:gsub( "^#%[(.+)%]#$", "%1" ) )

					sel_caret[2] = sel_caret[2] - 4
				end
			else
				self:SetSelection( "#[" .. self:GetSelection() .. "]#" )
			end
		elseif (mode == 2) then -- Old
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
	else -- For CPU/GPU
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

	-- restore selection
	self.Caret = sel_caret
	self.Start = sel_start
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
		if not line:sub(col, col):match("^[a-zA-Z0-9_]$") then
			col = col - 1
		end
		if not line:sub(col, col):match("^[a-zA-Z0-9_]$") then
			surface_PlaySound("buttons/button19.wav")
			return
		end

		-- TODO substitute this for getWordStart, if it fits.
		local startcol = col
		while startcol > 1 and line:sub(startcol-1, startcol-1):match("^[a-zA-Z0-9_]$") do
			startcol = startcol - 1
		end

		-- TODO substitute this for getWordEnd, if it fits.
		local _,endcol = line:find("[^a-zA-Z0-9_]", col)
		endcol = (endcol or 0) - 1

		word = line:sub(startcol, endcol)
	end
	E2Helper.Show()
	if (self:GetParent().E2) then E2Helper.UseE2(self:GetParent().EditorType) else E2Helper.UseCPU(self:GetParent().EditorType) end
	E2Helper.Show(word)
end

function EDITOR:_OnKeyCodeTyped(code)
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
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string_gsub(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		elseif code == KEY_C then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string_gsub(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
			end
		-- pasting is now handled by the textbox that is used to capture input
		--[[
		elseif code == KEY_V then
			if self.clipboard then
				self:SetSelection(self.clipboard)
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
		elseif code == KEY_Q then
			self:GetParent():Close()
		elseif code == KEY_T then
			self:GetParent():NewTab()
		elseif code == KEY_W then
			self:GetParent():CloseTab()
		elseif code == KEY_PAGEUP then
			local parent = self:GetParent()

			local currentTab = parent:GetActiveTabIndex() - 1
			if currentTab < 1 then currentTab = currentTab + parent:GetNumTabs() end

			parent:SetActiveTabIndex(currentTab)
		elseif code == KEY_PAGEDOWN then
			local parent = self:GetParent()

			local currentTab = parent:GetActiveTabIndex() + 1
			local numTabs = parent:GetNumTabs()
			if currentTab > numTabs then currentTab = currentTab - numTabs end

			parent:SetActiveTabIndex(currentTab)
		elseif code == KEY_UP then
			self.Scroll[1] = self.Scroll[1] - 1
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
		elseif code == KEY_DOWN then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif code == KEY_LEFT then
			if self:HasSelection() and not shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:wordLeft(self.Caret)
			end

			self:ScrollCaret()

			if not shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:wordRight(self.Caret)
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		--[[ -- old code that scrolls on ctrl-left/right:
		elseif code == KEY_LEFT then
			self.Scroll[2] = self.Scroll[2] - 1
			if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
		elseif code == KEY_RIGHT then
			self.Scroll[2] = self.Scroll[2] + 1
		]]
		elseif code == KEY_HOME then
			self.Caret[1] = 1
			self.Caret[2] = 1

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			self.Caret[1] = #self.Rows
			self.Caret[2] = 1

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_D then
			-- Save current selection
			local old_start = self:CopyPosition( self.Start )
			local old_end = self:CopyPosition( self.Caret )
			local old_scroll = self:CopyPosition( self.Scroll )

			local str = self:GetSelection()
			if (str != "") then -- If you have a selection
				self:SetSelection( str:rep(2) ) -- Repeat it
			else -- If you don't
				-- Select the current line
				self.Start = { self.Start[1], 1 }
				self.Caret = { self.Start[1], #self.Rows[self.Start[1]]+1 }
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

	else

		if code == KEY_ENTER then
			local mode = wire_expression2_autocomplete_controlstyle:GetInt()
			if (mode == 4 and self.AC_HasSuggestions and self.AC_Suggestions[1] and self.AC_Panel and self.AC_Panel:IsVisible()) then
				if (self:AC_Use( self.AC_Suggestions[1] )) then return end
			end
			local row = self.Rows[self.Caret[1]]:sub(1,self.Caret[2]-1)
			local diff = (row:find("%S") or (row:len()+1))-1
			local tabs = string_rep("    ", math_floor(diff / 4))
			if GetConVarNumber('wire_expression2_autoindent') ~= 0 and (string_match("{" .. row .. "}", "^%b{}.*$") == nil) then tabs = tabs .. "    " end
			self:SetSelection("\n" .. tabs)
		elseif code == KEY_UP then
			if (self.AC_Panel and self.AC_Panel:IsVisible()) then
				local mode = wire_expression2_autocomplete_controlstyle:GetInt()
				if (mode == 1) then
					self.AC_Panel:RequestFocus()
					return
				end
			end

			if self.Caret[1] > 1 then
				self.Caret[1] = self.Caret[1] - 1

				local length = #(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_DOWN then
			if (self.AC_Panel and self.AC_Panel:IsVisible()) then
				local mode = wire_expression2_autocomplete_controlstyle:GetInt()
				if (mode == 1) then
					self.AC_Panel:RequestFocus()
					return
				end
			end

			if self.Caret[1] < #self.Rows then
				self.Caret[1] = self.Caret[1] + 1

				local length = #(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_LEFT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, -1)
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, 1)
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEUP then
			self.Caret[1] = self.Caret[1] - math_ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math_ceil(self.Size[1] / 2)
			if self.Caret[1] < 1 then self.Caret[1] = 1 end

			local length = #self.Rows[self.Caret[1]]
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret[1] = self.Caret[1] + math_ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math_ceil(self.Size[1] / 2)
			if self.Caret[1] > #self.Rows then self.Caret[1] = #self.Rows end
			if self.Caret[1] == #self.Rows then self.Caret[2] = 1 end

			local length = #self.Rows[self.Caret[1]]
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_HOME then
			local row = self.Rows[self.Caret[1]]
			local first_char = row:find("%S") or row:len()+1
			if self.Caret[2] == first_char then
				self.Caret[2] = 1
			else
				self.Caret[2] = first_char
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			local length = #(self.Rows[self.Caret[1]])
			self.Caret[2] = length + 1

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_BACKSPACE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and #(buffer) > 0 and string_rep(" ", #(buffer)) == buffer then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
				end
			end
		elseif code == KEY_DELETE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and string_rep(" ", #(buffer)) == buffer and #(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1 then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		elseif code == KEY_F1 then
			self:ContextHelp()
		end
	end

	if (code == KEY_TAB and self.AC_Panel and self.AC_Panel:IsVisible()) then
		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if (mode == 0 or mode == 4) then
			self.AC_Panel:RequestFocus()
			if (mode == 4 and self.AC_Panel.Selected == 0) then self.AC_Panel.Selected = 1 end
			return
		end
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
				if self:GetSelection():find("%S") then
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
	end

	if control then
		self:OnShortcut(code)
	end

	self:AC_Check()
end

---------------------------------------------------------------------------------------------------------
-- Auto Completion
-- By Divran
---------------------------------------------------------------------------------------------------------

function EDITOR:IsVarLine()
	local line = self.Rows[self.Caret[1]]
	local word = line:match( "^@(%w+)" )
	return (word == "inputs" or word == "outputs" or word == "persist")
end

function EDITOR:IsDirectiveLine()
	local line = self.Rows[self.Caret[1]]
	return line:match( "^@" ) != nil
end

function EDITOR:getWordStart(caret,getword)
	local line = self.Rows[caret[1]]

	for startpos, endpos in line:gmatch( "()[a-zA-Z0-9_]+()" ) do -- "()%w+()"
		if (startpos <= caret[2] and endpos >= caret[2]) then
			return { caret[1], startpos }, getword and line:sub(startpos,endpos-1) or nil
		end
	end
	return {caret[1],1}
end

function EDITOR:getWordEnd(caret,getword)
	local line = self.Rows[caret[1]]

	for startpos, endpos in line:gmatch( "()[a-zA-Z0-9_]+()" ) do -- "()%w+()"
		if (startpos <= caret[2] and endpos >= caret[2]) then
			return { caret[1], endpos }, getword and line:sub(startpos,endpos-1) or nil
		end
	end
	return {caret[1],#line+1}
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
	local len = #word
	local wordu = word:upper()
	local count = 0

	local suggestions = {}

	for name,value in pairs( wire_expression2_constants ) do
		if (name:sub(1,len) == wordu) then
			count = count + 1
			suggestions[count] = GetTableForConstant( name )
		end
	end

	return suggestions
end

tbl[1] = function( self )
	local word, symbolinfront = self:AC_GetCurrentWord()
	if (word and word != "" and word:sub(1,1) == "_") then
		return FindConstants( self, word )
	end
end

--------------------
-- FindFunctions
-- Adds all matching functions to the suggestions table
--------------------

local function GetTableForFunction()
	return { nice_str = function( t ) return t.data[2] end,
			str = function( t ) return t.data[1] end,
			replacement = function( t, editor )
				local caret = editor:CopyPosition( editor.Caret )
				caret[2] = caret[2] - 1
				local wordend = editor:getWordEnd( caret )
				local has_bracket = editor:GetArea( { wordend, { wordend[1], wordend[2] + 1 } } ) == "(" -- If there already is a bracket, we don't want to add more of them.
				local ret = t:str()
				return ret..(has_bracket and "" or "()"), #ret+1
			end,
			others = function( t ) return t.data[3] end,
			description = function( t )
				if (t.data[4] and E2Helper.Descriptions[t.data[4]]) then
					return E2Helper.Descriptions[t.data[4]]
				end
				if (t.data[1] and E2Helper.Descriptions[t.data[1]]) then
					return E2Helper.Descriptions[t.data[1]]
				end
			end,
			data = {} }
end

local function FindFunctions( self, has_colon, word )
	-- Filter out magic characters
	word = word:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1" )

	local len = #word
	local wordl = word:lower()
	local count = 0
	local suggested = {}
	local suggestions = {}

	for func_id,_ in pairs( wire_expression2_funcs ) do
		if (wordl == func_id:lower():sub(1,len)) then -- Check if the beginning of the word matches
			local name, types = func_id:match( "(.+)(%b())" ) -- Get the function name and types
			local first_type, colon, other_types = types:match( "%((%w*)(:?)(.*)%)" ) -- Sort the function types
			if (((has_colon and colon == ":") or (!has_colon and colon != ":"))) then -- If they both have colons (or not)
				first_type = first_type:upper()
				other_types = other_types:upper()
				if (!suggested[name]) then -- If it hasn't already been suggested
					count = count + 1
					suggested[name] = count

					-- Add to suggestions
					if (colon == ":") then
						local t = GetTableForFunction()
						t.data = { name, first_type .. ":" .. name .. "(" .. other_types .. ")", {}, func_id }
						suggestions[count] = t
					else
						local t = GetTableForFunction()
						t.data = { name, name .. "(" .. first_type .. ")", {}, func_id }
						suggestions[count] = t
					end
				else -- If it has already been suggested
					-- Get previous data
					local others = suggestions[suggested[name]]:others(self)
					local i = #others+1

					-- Add it to the end of the list
					if (colon == ":") then
						local t = GetTableForFunction()
						t.data = { name, first_type .. ":" .. name .. "(" .. other_types .. ")", nil, func_id }
						others[i] = t
					else
						local t = GetTableForFunction()
						t.data = { name, name .. "(" .. first_type .. ")", nil, func_id }
						others[i] = t
					end
				end
			end
		end
	end
	return suggestions
end

tbl[2] = function( self )
	local word, symbolinfront = self:AC_GetCurrentWord()
	if (word and word != "" and word:sub(1,1):upper() != word:sub(1,1)) then
		return FindFunctions( self, (symbolinfront == ":"), word )
	end
end

-----------------------------------------------------------
-- SaveVariables
-- Saves all variables to a table
-----------------------------------------------------------

function EDITOR:AC_SaveVariables()
	local OK, directives,_ = PreProcessor.Execute( self:GetValue() )

	if (!OK or !directives) then
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
	local len = #word
	local wordl = word:lower()
	local count = 0

	local suggested = {}
	local suggestions = {}

	local directives = self.AC_Directives
	if (!directives) then self:AC_SaveVariables() end -- If directives is nil, attempt to find
	directives = self.AC_Directives
	if (!directives) then -- If finding failed, abort
		self:AC_SetVisible( false )
		return
	end

	for k,v in pairs( directives["inputs"][1] ) do
		if (v:lower():sub(1,len) == wordl) then
			if (!suggested[v]) then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	for k,v in pairs( directives["outputs"][1] ) do
		if (v:lower():sub(1,len) == wordl) then
			if (!suggested[v]) then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	for k,v in pairs( directives["persist"][1] ) do
		if (v:lower():sub(1,len) == wordl) then
			if (!suggested[v]) then
				suggested[v] = true
				count = count + 1
				suggestions[count] = GetTableForVariables( v )
			end
		end
	end

	return suggestions
end

tbl[3] = function( self )
	local word, symbolinfront = self:AC_GetCurrentWord()
	if (word and word != "" and word:sub(1,1):upper() == word:sub(1,1)) then
		return FindVariables( self, word )
	end
end

local wire_expression2_autocomplete = CreateClientConVar( "wire_expression2_autocomplete", "1", true, false )
tbl.RunOnCheck = function( self )
	-- Only autocomplete if it's the E2 editor, if it's enabled
	if (!self:GetParent().E2 or !wire_expression2_autocomplete:GetBool()) then
		self:AC_SetVisible( false )
		return false
	end

	local caret = self:CopyPosition( self.Caret )
	caret[2] = caret[2] - 1
	local tokenname = self:GetTokenAtPosition( caret )
	if (tokenname and (tokenname == "string" or tokenname == "comment")) then
		self:AC_SetVisible( false )
		return false
	end

	if (self:IsVarLine() and !self.AC_WasVarLine) then -- If the user IS editing a var line, and they WEREN'T editing a var line before this..
		self.AC_WasVarLine = true
	elseif (!self:IsVarLine() and self.AC_WasVarLine) then -- If the user ISN'T editing a var line, and they WERE editing a var line before this..
		self.AC_WasVarLine = nil
		self:AC_SaveVariables()
	end
	if (self:IsDirectiveLine()) then -- In case you're wondering, DirectiveLine != VarLine (A directive line is any line starting with @, a var line is @inputs, @outputs, and @persists)
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

	if (!notimer) then
		timer.Create("E2_AC_Check", 0, 1, function()
			if self.AC_Check then self:AC_Check(true) end
		end)
		return
	end

	if (!self.AC_AutoCompletion) then self:AC_NewAutoCompletion( tbl ) end -- Default to E2 autocompletion
	if (!self.AC_Panel) then self:AC_CreatePanel() end
	if (self.AC_AutoCompletion.RunOnCheck) then
		local ret = self.AC_AutoCompletion.RunOnCheck( self )
		if (ret == false) then
			return
		end
	end

	self.AC_Suggestions = {}
	self.AC_HasSuggestions = false

	local suggestions = {}
	for i=1,#self.AC_AutoCompletion do
		local _suggestions = self.AC_AutoCompletion[i]( self )
		if (_suggestions != nil and #_suggestions > 0) then
			suggestions = _suggestions
			break
		end
	end

	if (#suggestions > 0) then

		local word, _ = self:AC_GetCurrentWord()

		table_sort( suggestions, function( a, b )
			local diff1 = CheckDifference( word, a.str( a ) )
			local diff2 = CheckDifference( word, b.str( b ) )
			return diff1 < diff2
		end)

		if (word == suggestions[1].str( suggestions[1] ) and #suggestions == 1) then -- The word matches the first suggestion exactly, and there are no more suggestions. No need to bother displaying
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
	if (!suggestion) then return false end
	local ret = false

	-- Get word position
	local wordstart = self:getWordStart( self.Caret )
	local wordend = self:getWordEnd( self.Caret )

	-- Get replacement
	local replacement, caretoffset = suggestion:replacement( self )

	-- Check if anything needs changing
	local selection = self:GetArea( { wordstart, wordend } )
	if (selection == replacement) then -- There's no point in doing anything.
		return false
	end

	-- Overwrite selection
	if (replacement and replacement != "") then
		self:SetArea( { wordstart, wordend }, replacement )

		-- Move caret
		if (caretoffset) then
			self.Start = { wordstart[1], wordstart[2] + caretoffset }
			self.Caret = { wordstart[1], wordstart[2] + caretoffset }
		else
			if (wire_expression2_autocomplete_highlight_after_use:GetBool()) then
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
		if (!self.AC_HasSuggestions or !self.AC_Panel_Visible) then return end

		local mode = wire_expression2_autocomplete_controlstyle:GetInt()
		if (mode == 0) then -- Default style - Tab/CTRL+Tab to choose item;\nEnter/Space to use;\nArrow keys to abort.

			if (input.IsKeyDown( KEY_ENTER ) or input.IsKeyDown( KEY_SPACE )) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif (input.IsKeyDown( KEY_TAB ) and !pnl.AlreadySelected) then -- Select
				if (input.IsKeyDown( KEY_LCONTROL )) then -- If control is held down
					pnl.Selected = pnl.Selected - 1 -- Scroll up
					if (pnl.Selected < 1) then pnl.Selected = #self.AC_Suggestions end
				else -- If control isn't held down
					pnl.Selected = pnl.Selected + 1 -- Scroll down
					if (pnl.Selected > #self.AC_Suggestions) then pnl.Selected = 1 end
				end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl:RequestFocus()
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif (pnl.AlreadySelected and !input.IsKeyDown( KEY_TAB )) then
				pnl.AlreadySelected = nil
			elseif (input.IsKeyDown( KEY_UP ) or input.IsKeyDown( KEY_DOWN ) or input.IsKeyDown( KEY_LEFT ) or input.IsKeyDown( KEY_RIGHT )) then
				self:AC_SetVisible( false )
			end

		elseif (mode == 1) then -- Visual C# Style - Ctrl+Space to use the top match;\nArrow keys to choose item;\nTab/Enter/Space to use;\nCode validation hotkey (ctrl+space) moved to ctrl+b.

			if (input.IsKeyDown( KEY_TAB ) or input.IsKeyDown( KEY_ENTER ) or input.IsKeyDown( KEY_SPACE )) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif (input.IsKeyDown( KEY_DOWN ) and !pnl.AlreadySelected) then -- Select
				pnl.Selected = pnl.Selected + 1 -- Scroll down
				if (pnl.Selected > #self.AC_Suggestions) then pnl.Selected = 1 end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif (input.IsKeyDown( KEY_UP ) and !pnl.AlreadySelected) then -- Select
				pnl.Selected = pnl.Selected - 1 -- Scroll up
				if (pnl.Selected < 1) then pnl.Selected = #self.AC_Suggestions end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif (pnl.AlreadySelected and !input.IsKeyDown( KEY_UP ) and !input.IsKeyDown( KEY_DOWN )) then
				pnl.AlreadySelected = nil
			end

		elseif (mode == 2) then -- Scroller style - Mouse scroller to choose item;\nMiddle mouse to use.

			if (input.IsMouseDown( MOUSE_MIDDLE )) then
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			end

		elseif (mode == 3) then -- Scroller Style w/ Enter - Mouse scroller to choose item;\nEnter to use.

			if (input.IsKeyDown( KEY_ENTER )) then
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			end

		elseif (mode == 4) then -- Eclipse Style - Enter to use top match;\nTab to enter auto completion menu;\nArrow keys to choose item;\nEnter to use;\nSpace to abort.

			if (input.IsKeyDown( KEY_ENTER )) then -- Use
				self:AC_SetVisible( false )
				self:AC_Use( self.AC_Suggestions[pnl.Selected] )
			elseif (input.IsKeyDown( KEY_SPACE )) then
				self:AC_SetVisible( false )
			elseif (input.IsKeyDown( KEY_DOWN ) and !pnl.AlreadySelected) then -- Select
				pnl.Selected = pnl.Selected + 1 -- Scroll down
				if (pnl.Selected > #self.AC_Suggestions) then pnl.Selected = 1 end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif (input.IsKeyDown( KEY_UP ) and !pnl.AlreadySelected) then -- Select
				pnl.Selected = pnl.Selected - 1 -- Scroll up
				if (pnl.Selected < 1) then pnl.Selected = #self.AC_Suggestions end
				self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
				pnl.AlreadySelected = true -- To keep it from scrolling a thousand times a second
			elseif (pnl.AlreadySelected and !input.IsKeyDown( KEY_UP ) and !input.IsKeyDown( KEY_DOWN )) then
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
	for cur_end in txt:gmatch( "[^ \n]+()" ) do
		local w, _ = surface_GetTextSize( txt:sub( prev_newline, cur_end ) )
		if (w > width) then
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

	if (!suggestion or !suggestion.description or !wire_expression2_autocomplete_moreinfo:GetBool()) then -- If the suggestion is invalid, the suggestion does not need additional information, or if the user has disabled additional information, abort
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
	if (suggestion.others) then others = suggestion:others( self ) end

	if (desc and desc != "") then
		desc = "Description:\n" .. desc
	end

	if (#others > 0) then -- If there are other functions with the same name...
		desc = (desc or "") .. ((desc and desc != "") and "\n" or "") .. "Others with the same name:"

		-- Loop through the "others" table to add all of them
		surface_SetFont( "E2SmallFont" )
		for k,v in pairs( others ) do
			local nice_name = v:nice_str( self )

			local namew, nameh = surface_GetTextSize( nice_name )

			local label = vgui.Create("DLabel")
			label:SetText( "" )
			label.Paint = function( pnl )
				local w,h = pnl:GetSize()
				draw_RoundedBox( 1,1,1, w-2,h-2, Color( 65,105,225,255 ) )
				surface_SetFont( "E2SmallFont" )
				surface_SetTextPos( 6, h/2-nameh/2 )
				surface_SetTextColor( 255,255,255,255 )
				surface_DrawText( nice_name )
			end

			infolist:AddItem( label )

			if (namew + 15 > maxw) then maxw = namew + 15 end
			maxh = maxh + 20
		end
	end

	if (!desc or desc == "") then
		panel:SetSize( panel.curw, panel.curh )
		infolist:SetPos( 1000, 1000 )
		return
	end

	-- Wrap the text, set it, and calculate size
	desc = SimpleWrap( desc, maxw )
	desc_label:SetText( desc )
	desc_label:SizeToContents()
	local textw, texth = surface_GetTextSize( desc )

	-- If it's bigger than the size of the panel, change it
	if (panel.curh < texth + 4) then panel:SetTall( texth + 6 ) else panel:SetTall( panel.curh ) end
	if (maxh + texth > panel:GetTall()) then maxw = maxw + 25 end

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

	surface.SetFont( "E2SmallFont" )

	-- Add all suggestions to the list
	for count,suggestion in pairs( self.AC_Suggestions ) do
		local nice_name = suggestion:nice_str( self )
		local name = suggestion:str( self )


		local txt = vgui.Create("DLabel")
		txt:SetText( "" )
		txt.count = count
		txt.suggestion = suggestion

		-- Override paint to give it the "E2 theme" and to make it highlight when selected
		txt.Paint = function( pnl, w, h )
			draw_RoundedBox( 1, 1, 1, w-2, h-2, Color( 65, 105, 225, 255 ) )
			if (panel.Selected == pnl.count) then
				draw_RoundedBox( 0, 2, 2, w - 4 , h - 4, Color(0,0,0,192) )
			end
			-- I honestly dont have a fucking clue.
			-- h2, was being cleaned up instantly for no reason.
			surface.SetFont( "E2SmallFont" )
			local _, h2 = surface.GetTextSize( nice_name )

			surface.SetTextPos( 6, (h / 2) - (h2 / 2) )
			surface.SetTextColor( 255,255,255,255 )
			surface.DrawText( nice_name )
		end

		-- Enable mouse presses
		txt.OnMousePressed = function( pnl, code )
			if (code == MOUSE_LEFT) then
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
		if (w > maxw) then maxw = w end
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
	if (self.AC_Panel_Visible == bool or !self.AC_Panel) then return end
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
	if (!panel) then return end
	self:AC_SetVisible( false )
	panel.list:Clear()
	panel.infolist:Clear()
	panel:SetSize( 100, 202 )
	panel.infolist:SetPos( 1000, 1000 )
	panel.infolist:SetSize( 100, 200 )
	panel.list:StretchToParent( 1,1,1,1 )
end

---------------------------------------------------------------------------------------------------------
-- CPU/GPU hint box
---------------------------------------------------------------------------------------------------------
local oldpos, haschecked = {0,0}, false
function EDITOR:Think()
	if (self:GetParent().E2) then self.Think = nil return end -- E2 doesn't need this

	local caret = self:CursorToCaret()
	local startpos, word = self:getWordStart( caret, true )

	if (word and word != "") then
		if !haschecked then
			oldpos = {startpos[1],startpos[2]}
			haschecked = true
			timer.Simple(0.3,function()
			if not self then return end
			if not self.CursorToCaret then return end
				local caret = self:CursorToCaret()
				local startpos, word = self:getWordStart( caret, true )
				if (startpos[1] == oldpos[1] and startpos[2] == oldpos[2]) then
					self.CurrentVarValue = { startpos, word }
				end
			end)
		elseif ((oldpos[1] != startpos[1] or oldpos[2] != startpos[2]) and haschecked) then
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

---------------------------------------------------------------------------------------------------------

-- helpers for ctrl-left/right
function EDITOR:wordLeft(caret)
	local row = self.Rows[caret[1]]
	if caret[2] == 1 then
		if caret[1] == 1 then return caret end
		caret = { caret[1]-1, #self.Rows[caret[1]-1] }
		row = self.Rows[caret[1]]
	end
	local pos = row:sub(1,caret[2]-1):match("[^%w@]()[%w@]+[^%w@]*$")
	caret[2] = pos or 1
	return caret
end

function EDITOR:wordRight(caret)
	local row = self.Rows[caret[1]]
	if caret[2] > #row then
		if caret[1] == #self.Rows then return caret end
		caret = { caret[1]+1, 1 }
		row = self.Rows[caret[1]]
		if row:sub(1,1) ~= " " then return caret end
	end
	local pos = row:match("[^%w@]()[%w@]",caret[2])
	caret[2] = pos or (#row+1)
	return caret
end

function EDITOR:GetTokenAtPosition( caret )
	local column = caret[2]
	local line = self.PaintRows[caret[1]]
	if (line) then
		local startindex = 1
		for index,data in pairs( line ) do
			startindex = startindex+#data[1]
			if startindex >= column then return data[3] end
		end
	end
end

/***************************** Syntax highlighting ****************************/

function EDITOR:ResetTokenizer(row)
	self.line = self.Rows[row]
	self.position = 0
	self.character = ""
	self.tokendata = ""

	if self:GetParent().E2 then
		if row == self.Scroll[1] then

			-- This code checks if the visible code is inside a string or a block comment
			self.blockcomment = nil
			self.multilinestring = nil
			local singlelinecomment = false

			local str = string_gsub( table_concat( self.Rows, "\n", 1, self.Scroll[1]-1 ), "\r", "" )

			for before, char, after in string_gmatch( str, '()([#"\n])()' ) do
				local before = string_sub( str, before-1, before-1  )
				local after = string_sub( str, after, after )
				if not self.blockcomment and not self.multilinestring and not singlelinecomment then
					if char == '"' then
						self.multilinestring = true
					elseif char == "#" and after == "[" then
						self.blockcomment = true
					elseif char == "#" then
						singlelinecomment = true
					end
				elseif self.multilinestring and char == '"' and before ~= "\\" then
					self.multilinestring = nil
				elseif self.blockcomment and char == "#" and before == "]" then
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
end

function EDITOR:NextCharacter()
	if not self.character then return end

	self.tokendata = self.tokendata .. self.character
	self.position = self.position + 1

	if self.position <= self.line:len() then
		self.character = self.line:sub(self.position, self.position)
	else
		self.character = nil
	end
end

function EDITOR:SkipPattern(pattern)
	-- TODO: share code with NextPattern
	if !self.character then return nil end
	local startpos,endpos,text = self.line:find(pattern, self.position)

	if startpos ~= self.position then return nil end
	local buf = self.line:sub(startpos, endpos)
	if not text then text = buf end

	--self.tokendata = self.tokendata .. text


	self.position = endpos + 1
	if self.position <= #self.line then
		self.character = self.line:sub(self.position, self.position)
	else
		self.character = nil
	end
	return text
end

function EDITOR:NextPattern(pattern)
	if !self.character then return false end
	local startpos,endpos,text = self.line:find(pattern, self.position)

	if startpos ~= self.position then return false end
	local buf = self.line:sub(startpos, endpos)
	if not text then text = buf end

	self.tokendata = self.tokendata .. text


	self.position = endpos + 1
	if self.position <= #self.line then
		self.character = self.line:sub(self.position, self.position)
	else
		self.character = nil
	end
	return true
end

do -- E2 Syntax highlighting
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

		-- keywords that cannot be followed by a "(":
		["else"]     = { [true] = true },
		["break"]    = { [true] = true },
		["continue"] = { [true] = true },
		//["function"] = { [true] = true },
		["return"] = { [true] = true },
		["local"]  = { [true] = true },
	}

	-- fallback for nonexistant entries:
	setmetatable(keywords, { __index=function(tbl,index) return {} end })

	local directives = {
		["@name"] = 0, -- all yellow
		["@model"] = 0,
		["@inputs"] = 1, -- directive yellow, types orange, rest normal
		["@outputs"] = 1,
		["@persist"] = 1,
		["@trigger"] = 2, -- like 1, except that all/none are yellow
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
		["typename"]  = { Color(240, 160,  96), false}, -- orange
		["constant"]  = { Color(240, 160, 240), false}, -- pink
		["userfunction"] = { Color(102, 122, 102), false}, -- dark green
	}

	function EDITOR:SetSyntaxColors( col )
		for k,v in pairs( col ) do
			if (colors[k]) then
				colors[k][1] = v
			end
		end
	end

	function EDITOR:SetSyntaxColor( colorname, colr )
		if (!colors[colorname]) then return end
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

	function EDITOR:SyntaxColorLine(row)
		cols,lastcol = {}, nil


		self:ResetTokenizer(row)
		self:NextCharacter()

		-- 0=name 1=port 2=trigger 3=foreach
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
				if (self.character == '"') then
					self.multilinestring = nil
					self:NextCharacter()
					break
				end
				if (self.character == "\\") then self:NextCharacter() end
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
				if istype( funcname ) then -- Hey... this isn't a function name! :O
					addToken( "typename", funcname )
				else
					addToken( "userfunction", funcname )
				end

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

				if istype( funcname ) or funcname == "void" then -- Hey... this isn't a function name! :O
					addToken( "typename", funcname )
				else
					addToken( "userfunction", funcname )

					if not wire_expression2_funclist[funcname] then
						self.e2fs_functions[funcname] = row
					end
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

					if self:NextPattern( "%[" ) then -- Found a [
						-- Color the bracket
						addToken( "operator", self.tokendata )
						self.tokendata = ""

						while self:NextPattern( "[A-Z][a-zA-Z0-9_]*" ) do -- If we found a variable
							addToken( "variable", self.tokendata )
							self.tokendata = ""

							local spaces = self:SkipPattern( " *" )
							if spaces then addToken( "comment", spaces ) end
						end

						if self:NextPattern( "%]" ) then
							addToken( "operator", "]" )
							self.tokendata = ""
						end
					elseif self:NextPattern( "[A-Z][a-zA-Z0-9_]*" ) then -- If we found a variable
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
					else
						abort = true
						break
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

		while self.character do
			local tokenname = ""
			self.tokendata = ""

			-- eat all spaces
			local spaces = self:SkipPattern(" *")
			if spaces then addToken("operator", spaces) end
			if !self.character then break end

			-- eat next token
			if self:NextPattern("^_[A-Z][A-Z_0-9]*") then
				local word = self.tokendata
				for k,_ in pairs( wire_expression2_constants ) do
					if (k == word) then
						tokenname = "constant"
					end
				end
				if (tokenname == "") then tokenname = "notfound" end
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
					elseif highlightmode == 3 and istype(sstr) then
						tokenname = "typename"
						highlightmode = nil
					else
						tokenname = "notfound"
					end
				else
					-- is this a keyword or a function?
					local char = self.character or ""
					local keyword = char != "("

					local spaces = self:SkipPattern(" *") or ""

					if self.character == "]" then
						-- X[Y,typename]
						tokenname = istype(sstr) and "typename" or "notfound"
					elseif keywords[sstr][keyword] then
						tokenname = "keyword"
						if sstr == "foreach" then highlightmode = 3
						elseif sstr == "return" and self:NextPattern( "void" ) then
							addToken( "keyword", "return" )
							tokenname = "typename"
							self.tokendata = spaces .. "void"
							spaces = ""
						end
					elseif wire_expression2_funclist[sstr] then
						tokenname = "function"

					elseif self.e2fs_functions[sstr] then
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

			elseif self:NextPattern("^[A-Z][a-zA-Z0-9_]*") then
				tokenname = "variable"

			elseif self.character == '"' then
				self:NextCharacter()
				while self.character do -- Find the ending "
					if (self.character == '"') then
						tokenname = "string"
						break
					end
					if (self.character == "\\") then self:NextCharacter() end
					self:NextCharacter()
				end

				if (tokenname == "") then -- If no ending " was found...
					self.multilinestring = true
					tokenname = "string"
				else
					self:NextCharacter()
				end

			elseif self.character == "#" then
				self:NextCharacter()
				if (self.character == "[") then -- Check if there is a [ directly after the #
					while self.character do -- Find the ending ]
						if (self.character == "]") then
							self:NextCharacter()
							if (self.character == "#") then -- Check if there is a # directly after the ending ]
								tokenname = "comment"
								break
							end
						end
						if self.character == "\\" then self:NextCharacter() end
						self:NextCharacter()
					end
					if (tokenname == "") then -- If no ending ]# was found...
						self.blockcomment = true
						tokenname = "comment"
					else
						self:NextCharacter()
					end
				end

				if (tokenname == "") then

					self:NextPattern("[^ ]*") -- Find the whole word

					if PreProcessor["PP_"..self.tokendata:sub(2)] then
						-- there is a preprocessor command by that name => mark as such
						tokenname = "ppcommand"
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
	end -- EDITOR:SyntaxColorLine
end -- do...

do
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
		"INT","FLOAT","CHAR","VOID","PRESERVE","ZAP"
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

	function EDITOR:CPUGPUSyntaxColorLine(row)
		local cols = {}
		self:ResetTokenizer(row)
		self:NextCharacter()

		local isGpu = self:GetParent().EditorType == "GPU"

		while self.character do
			local tokenname = ""
			self.tokendata = ""

			self:NextPattern(" *")
			if !self.character then break end

			if self:NextPattern("^[0-9][0-9.]*") then
				tokenname = "number"
			elseif self:NextPattern("^[a-zA-Z0-9_@.]+:") then
				tokenname = "label"
			elseif self:NextPattern("^[a-zA-Z0-9_]+") then
				local sstr = string.upper(self.tokendata:Trim())
				if opcodeTable[sstr] then
					tokenname = "opcode"
				elseif registersTable[sstr] then
					tokenname = "register"
				elseif keywordsTable[sstr] then
					tokenname = "keyword"
				else
					tokenname = "normal"
				end
			elseif (self.character == "'") or (self.character == "\"")  then
				self:NextCharacter()
				while self.character and (self.character != "'") and (self.character != "\"") do
					if self.character == "\\" then self:NextCharacter() end
					self:NextCharacter()
				end
				self:NextCharacter()
				tokenname = "string"
			elseif self:NextPattern("#include <") then  --(self.character == "<")
				while self.character and (self.character != ">") do
					self:NextCharacter()
				end
				self:NextCharacter()
				tokenname = "filename"
			elseif self:NextPattern("^//.*$") then
				tokenname = "comment"
			elseif (self.character == "#") then
				self:NextCharacter()
				if self:NextPattern("^[a-zA-Z0-9_#]+") then
					local sstr = string.sub(string.upper(self.tokendata:Trim()),2)
					if macroTable[sstr] then
						tokenname = "pmacro"
					else
						tokenname = "memref"
					end
				else
 					tokenname = "memref"
				end
			elseif (self.character == "[") or (self.character == "]") then
				self:NextCharacter()
				tokenname = "memref"
			else
				self:NextCharacter()
				tokenname = "normal"
			end

			color = colors[tokenname]
			if #cols > 1 and color == cols[#cols][2] then
				cols[#cols][1] = cols[#cols][1] .. self.tokendata
			else
				cols[#cols + 1] = {self.tokendata, color}
			end
		end
		return cols
	end -- EDITOR:SyntaxColorLine
end -- do...

-- register editor panel
vgui.Register("Expression2Editor", EDITOR, "Panel");

concommand.Add("wire_expression2_reloadeditor", function(ply, command, args)
	local code = wire_expression2_editor and wire_expression2_editor:GetCode()
	wire_expression2_editor = nil
	ZCPU_Editor = nil
	ZGPU_Editor = nil
	include("wire/client/TextEditor.lua")
	include("wire/client/wire_expression2_editor.lua")
	initE2Editor()
	if code then wire_expression2_editor:SetCode(code) end
end)
