/******************************************************************************\
  Expression 2 Text Editor for Garry's Mod
  Andreas "Syranide" Svensson, me@syranide.com
\******************************************************************************/

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

	x = x - (self.FontWidth * 3 + 6)
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end

	local line = math.floor(y / self.FontHeight)
	local char = math.floor(x / self.FontWidth+0.5)

	line = line + self.Scroll[1]
	char = char + self.Scroll[2]

	if line > #self.Rows then line = #self.Rows end
	local length = string.len(self.Rows[line])
	if char > length + 1 then char = length + 1 end

	return { line, char }
end

function EDITOR:OnMousePressed(code)
	if code == MOUSE_LEFT then
		if((CurTime() - self.LastClick) < 1 and self.tmp and self:CursorToCaret()[1] == self.Caret[1] and self:CursorToCaret()[2] == self.Caret[2]) then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.tmp = false
			return
		end

		self.tmp = true

		self.LastClick = CurTime()
		self:RequestFocus()
		self.Blink = RealTime()
		self.MouseDown = true

		self.Caret = self:CursorToCaret()
		if !input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT) then
			self.Start = self:CursorToCaret()
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
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
					self:SetSelection()
				end
			end)
			menu:AddOption("Copy", function()
				if self:HasSelection() then
					self.clipboard = self:GetSelection()
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
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
	self.Rows = string.Explode("\n", text)
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
	return string.Replace(table.concat(self.Rows, "\n"), "\r", "")
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
function EDITOR:ClearHighlightedLines() self.HighlightedLines = {} end

function EDITOR:PaintLine(row)
	if row > #self.Rows then return end

	if !self.PaintRows[row] then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end

	local width, height = self.FontWidth, self.FontHeight

	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		surface.SetDrawColor(48, 48, 48, 255)
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end

	if (self.HighlightedLines and self.HighlightedLines[row]) then
		local color = self.HighlightedLines[row]
		surface.SetDrawColor( color[1], color[2], color[3], color[4] )
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end

	if self:HasSelection() then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]

		surface.SetDrawColor(0, 0, 160, 255)
		local length = self.Rows[row]:len() - self.Scroll[2] + 1

		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if char < 0 then char = 0 end
		if endchar < 0 then endchar = 0 end

		if row == line and line == endline then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif row == line then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif row == endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif row > line and row < endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end

	draw.SimpleText(tostring(row), self.CurrentFont, width * 3, (row - self.Scroll[1]) * height, Color(128, 128, 128, 255), TEXT_ALIGN_RIGHT)

	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if offset < 0 then
			if cell[1]:len() > -offset then
				line = cell[1]:sub(1-offset)
				offset = line:len()

				if cell[2][2] then
					draw.SimpleText(line .. " ", self.CurrentFont .. "_Bold", width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				else
					draw.SimpleText(line .. " ", self.CurrentFont, width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
				end
			else
				offset = offset + cell[1]:len()
			end
		else
			if cell[2][2] then
				draw.SimpleText(cell[1] .. " ", self.CurrentFont .. "_Bold", offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			else
				draw.SimpleText(cell[1] .. " ", self.CurrentFont, offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, cell[2][1])
			end

			offset = offset + cell[1]:len()
		end
	end


end

function EDITOR:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)

	self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1

	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:PaintTextOverlay()

	if self.TextEntry:HasFocus() and self.Caret[2] - self.Scroll[2] >= 0 then
		local width, height = self.FontWidth, self.FontHeight

		if (RealTime() - self.Blink) % 0.8 < 0.4 then
			surface.SetDrawColor(240, 240, 240, 255)
			surface.DrawRect((self.Caret[2] - self.Scroll[2]) * width + width * 3 + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
		end

		-- Bracket highlighting by: {Jeremydeath}
		local WindowText = self:GetValue()
		local LinePos = table.concat(self.Rows, "\n", 1, self.Caret[1]-1):len()
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

					local BracketLines = string.Explode("\n",WindowText:sub(BrackSt, End))

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
						surface.SetDrawColor(255, 0, 0, 50)
						surface.DrawRect((StartX-(self.Scroll[2]-1)) * width + width * 4 + OffsetSt - 1, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
						surface.DrawRect((EndX-(self.Scroll[2]-1)) * width + width * 3 + 6, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			elseif Bracket == ")" or Bracket == "]" or Bracket == "}" then
				BrackSt,End = WindowText:reverse():find("%b"..Bracket..BracketPairs[Bracket], -CaretPos)
				if BrackSt and End then
					local len = WindowText:len()
					End = len-End+1
					BrackSt = len-BrackSt+1
					local BracketLines = string.Explode("\n",WindowText:sub(End, BrackSt))

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
						surface.SetDrawColor(255, 0, 0, 50)
						surface.DrawRect((StartX-(self.Scroll[2]-1)) * width + width * 4 - 2, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
						surface.DrawRect((EndX-(self.Scroll[2]-1)) * width + width * 3 + 8 + OffsetSt, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			end
		end
	end
end

function EDITOR:Paint()
	if !input.IsMouseDown(MOUSE_LEFT) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if !self.PaintRows then
		self.PaintRows = {}
	end

	if self.MouseDown then
		self.Caret = self:CursorToCaret()
	end

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())

	surface.SetDrawColor(32, 32, 32, 255)
	surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())

	self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)

	self.blockcomment = nil
	self.multilinestring = nil

	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end

	-- Paint the overlay of the text (bracket highlighting and carret postition)
	self:PaintTextOverlay()

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
			local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
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
				caret[2] = string.len(self.Rows[caret[1]]) + 1
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
		return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string.sub(self.Rows[start[1]], start[2])

		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end

		return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
end

function EDITOR:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)

	local buffer = self:GetArea(selection)

	if start[1] != stop[1] or start[2] != stop[2] then
		// clear selection
		self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false

		for i=start[1]+1,stop[1] do
			table.remove(self.Rows, start[1] + 1)
			table.remove(self.PaintRows, start[1] + 1)
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
	local rows = string.Explode("\n", text)

	local remainder = string.sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false

	for i=2,#rows do
		table.insert(self.Rows, start[1] + i - 1, rows[i])
		table.insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end

	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }

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
			if string.match("{" .. row, "^%b{}.*$") then
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

function EDITOR:FindFunction(self,reversed,searchterm,MatchCase)
	//local reversed = self:GetParent().Reversed
	//local searchterm = self:GetParent().String:GetValue()
	if searchterm=="" then return end
	//local oldself = self
	//self = self:GetParent():GetParent()
	if !MatchCase then
		searchterm = string.lower(searchterm)
	end
	local Num,Row = 1,1
	local find = false
	local currentrow = Row
	if !reversed then
		if self.Caret[1] < self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] < self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num+1
		end
		for i=Row, #self.Rows do
			local row = self.Rows[i]
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = i
			Num=1
			if find then break end
		end
	else
		if self.Caret[1] > self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] > self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num-1
		end
		searchterm = string.reverse(searchterm)
		Num=#self.Rows[Row] - Num +2
		for i=1, Row do
			local now = Row-i+1
			local row = self.Rows[now]
			row = string.reverse(row)
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = now
			Num=1
			if find then
				find = #self.Rows[now] - (find - 2) - #searchterm
				break
			end
		end
	end
	if find then
		self.Caret[1] = currentrow
		self.Caret[2] = find+#searchterm
		self.Start[1] = currentrow
		self.Start[2] = find
		self:ScrollCaret()
	/*
	else
		if self.eof && type(self.eof)=="Panel" && self.eof:IsValid() then
			self.eof:Close()
		end
		self.eof = vgui.Create("DFrame", oldself)
		local popup = self.eof
		popup:SetSize(200,100)
		popup:Center()
		popup:SetTitle("End of file")
		popup:MakePopup()
		popup.Text = vgui.Create("DLabel", popup)
		popup.Text:SetPos(20,20)
		popup.Text:SetSize(200,20)
		popup.Text:SetText("File end has been reached")
	//*/
	end
end

function EDITOR:ReplaceNextFunction(self,ToRep,RepWith,MatchCase)
	local oldcoords = {self.Caret[1],self.Caret[2],self.Start[1],self.Start[2]}
	if ToRep == "" then return end
	self:FindFunction(self,false,ToRep,MatchCase)
	if oldcoords[1]!=self.Caret[1] or oldcoords[2]!=self.Caret[2] or oldcoords[3]!=self.Start[1] or oldcoords[4]!=self.Start[2] then
		self:SetArea(self:Selection(),RepWith)
		self.Caret[2]=self.Caret[2]-(#ToRep-#RepWith)
		self:ScrollCaret()
	end
end

function EDITOR:ReplaceAllFunction(self,ToRep,RepWith,MatchCase)
	if ToRep == "" then return end
	if MatchCase then
		local text = string.gsub(self:GetValue(),ToRep,RepWith)
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},text)
		self:ScrollCaret()
		return
	end
	local originaltext = self:GetValue()
	local text = string.lower(originaltext)
	ToRep = string.lower(ToRep)
	local offset = #ToRep-#RepWith
	local totaloffset = 0
	local curpos = 1
	local chardiff = #ToRep
	local success = false
	repeat
		local find = string.find(text,ToRep,curpos,true)
		if find then
			success = true
			originaltext = string.sub(originaltext,1,find+totaloffset-1)..RepWith..string.sub(originaltext,find+totaloffset+#ToRep)
			totaloffset=totaloffset-offset
			curpos = find+chardiff
		end
	until !find
	if success then
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},originaltext)
		self:ScrollCaret()
	end
end

function EDITOR:FindWindow()
	// Does a find box already exist? Kill it
	if self.FW && type(self.FW)=="Panel" && self.FW:IsValid() then
		self.FW:Close()
	end

	// Create the frame, make it highlight the line and show cursor
	local FW = vgui.Create("DFrame",self)
	self.FW = FW
	FW.OldThink = FW.Think
	FW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FW.OldClose = FW.Close
	FW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FW.Reversed = false
	FW:SetSize(250,100)
	FW:ShowCloseButton(true)
	FW:SetTitle("Search")
	FW:MakePopup()
	FW:Center()

	// Search Textbox
	FW.String = vgui.Create("DTextEntry",FW)
	FW.String:SetPos(10,30)
	FW.String:SetSize(230,20)
	FW.String:SetText(self:GetSelection():Left(100))
	FW.String:RequestFocus()
	FW.String.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			self:GetParent().Next.DoClick(self:GetParent().Next)
		end
	end

	// Forward Checkbox
	FW.Forw = vgui.Create("DCheckBox",FW)
	FW.Forw:SetPos(115,55)
	FW.Forw:SetValue(true)
	FW.Forw.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Back:SetValue(self:GetChecked())
			self:GetParent().Reversed = false
			self:SetValue(!self:GetChecked())
		end
	end

	// Backward Checkbox
	FW.Back = vgui.Create("DCheckBox",FW)
	FW.Back:SetPos(115,75)
	FW.Back:SetValue(false)
	FW.Back.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Forw:SetValue(self:GetChecked())
			self:GetParent().Reversed = true
			self:SetValue(!self:GetChecked())
		end
	end

	// Case Sensitive Checkbox
	FW.Case = vgui.Create("DCheckBoxLabel",FW)
	FW.Case:SetPos(10,75)
	FW.Case:SetValue(false)
	FW.Case:SetText("Case Sensitive")
	FW.Case:SizeToContents()

	// Checkbox Labels
	local Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Forw:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Forward")
	Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Back:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Backward")

	// Cancel Button
	FW.CloseB = vgui.Create("DButton",FW)
	FW.CloseB:SetText("Cancel")
	FW.CloseB:SetPos(190,75)
	FW.CloseB:SetSize(50,20)
	FW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end

	// Find Button
	FW.Next = vgui.Create("DButton",FW)
	FW.Next:SetText("Find")
	FW.Next:SetPos(190,52)
	FW.Next:SetSize(50,20)
	FW.Next.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:FindFunction(self,self.FW.Reversed,self.FW.String:GetValue(),self.FW.Case:GetChecked())
	end
end

function EDITOR:FindAndReplaceWindow()
	// Does a find box already exist? Kill it
	if self.FRW && type(self.FRW)=="Panel" && self.FRW:IsValid() then
		self.FRW:Close()
	end

	// Create the frame, make it highlight the line and show cursor
	local FRW = vgui.Create("DFrame",self)
	self.FRW = FRW
	FRW.OldThink = FRW.Think
	FRW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FRW.OldClose = FRW.Close
	FRW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FRW:SetSize(250,142)
	FRW:ShowCloseButton(true)
	FRW:SetTitle("Replace")
	FRW:MakePopup()
	FRW:Center()

	// ToReplace Textentry
	FRW.ToRep = vgui.Create("DTextEntry",FRW)
	FRW.ToRep:SetPos(10,30)
	FRW.ToRep:SetSize(230,20)
	FRW.ToRep:SetText(self:GetSelection():Left(100))
	FRW.ToRep:RequestFocus()
	FRW.ToRep.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			//self:GetParent().Replace.DoClick(self:GetParent().Next)
			self:GetParent().RepWith:RequestFocus()
		end
	end

	// ReplaceWith Textentry
	FRW.RepWith = vgui.Create("DTextEntry",FRW)
	FRW.RepWith:SetPos(10,64)
	FRW.RepWith:SetSize(230,20)

	// Text Labels
	local Label = vgui.Create("DLabel",FRW)
	Label:SetPos(12,50)
	Label:SetText("Replace With:")
	Label:SizeToContents()

	// Case Sensitive Checkbox
	FRW.Case = vgui.Create("DCheckBoxLabel",FRW)
	FRW.Case:SetPos(10,117)
	FRW.Case:SetValue(false)
	FRW.Case:SetText("Case Sensitive")
	FRW.Case:SizeToContents()

	// Cancel Button
	FRW.CloseB = vgui.Create("DButton",FRW)
	FRW.CloseB:SetText("Cancel")
	FRW.CloseB:SetPos(190,115)
	FRW.CloseB:SetSize(50,20)
	FRW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end

	// Replace Button
	FRW.Replace = vgui.Create("DButton",FRW)
	FRW.Replace:SetText("Replace")
	FRW.Replace:SetPos(190,90)
	FRW.Replace:SetSize(50,21)
	FRW.Replace.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceNextFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
	end

	// Replace All Button
	FRW.ReplaceAll = vgui.Create("DButton",FRW)
	FRW.ReplaceAll:SetText("Replace All")
	FRW.ReplaceAll:SetPos(127,90)
	FRW.ReplaceAll:SetSize(60,21)
	FRW.ReplaceAll.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceAllFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
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
	self.Caret = {#self.Rows, string.len(self.Rows[#self.Rows]) + 1}
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

	if (removecomment) then
		local str = self:GetSelection()
		if (str:find( "#[",1,true ) and str:find( "]#", 1, true )) then
			self:SetSelection( self:GetSelection():gsub( "(#%[)(.+)(%]#)", "%2" ) )

			sel_caret[2] = sel_caret[2] - 2
		end
	else
		self:SetSelection( self:GetSelection():gsub( "(.+)", "#%[%1%]#" ) )

		if (sel_caret[1] == sel_start[1]) then
			sel_caret[2] = sel_caret[2] + 4
		else
			sel_caret[2] = sel_caret[2] + 2
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
			if (removecomment) then
				local str = self:GetSelection()
				if (str:find( "#[", 1, true ) and str:find( "]#", 1, true )) then
					self:SetSelection( str:gsub( "(#%[\n)(.+)(\n%]#)", "%2" ) )
					sel_caret[1] = sel_caret[1] - 2
				end
			else
				self:SetSelection( self:GetSelection():gsub( "(.+)", "#%[\n%1\n%]#" ) )
				sel_caret[1] = sel_caret[1] + 2
			end
		elseif (mode == 1) then -- New (alt 2)
			if (removecomment) then
				local str = self:GetSelection()
				if (str:find( "#[", 1, true ) and str:find( "]#", 1, true )) then
					self:SetSelection( str:gsub( "(#%[)(.+)(%]#)", "%2" ) )
				end
			else
				self:SetSelection( self:GetSelection():gsub( "(.+)", "#%[%1%]#" ) )
			end
		elseif (mode == 2) then -- Old
			local comment_char = "#"
			if removecomment then
				-- shift-TAB with a selection --
				local tmp = string.gsub("\n"..self:GetSelection(), "\n"..comment_char, "\n")

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
			local tmp = string.gsub("\n"..self:GetSelection(), "\n"..comment_char, "\n")

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
			surface.PlaySound("buttons/button19.wav")
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
	if self:GetParent().E2 then
		E2Helper.Show(word)
	else
		-- TODO: Add CPU/GPU context help
		WireLib.AddNotify('"'..word..'"', NOTIFY_GENERIC, 5) -- TODO: comment this notify once the CPU context help is in
	end
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
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		elseif code == KEY_C then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
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
			self:FindWindow()
		elseif code == KEY_H then
			self:FindAndReplaceWindow()
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
			local row = self.Rows[self.Caret[1]]:sub(1,self.Caret[2]-1)
			local diff = (row:find("%S") or (row:len()+1))-1
			local tabs = string.rep("    ", math.floor(diff / 4))
			if GetConVarNumber('wire_expression2_autoindent') ~= 0 and (string.match("{" .. row .. "}", "^%b{}.*$") == nil) then tabs = tabs .. "    " end
			self:SetSelection("\n" .. tabs)
		elseif code == KEY_UP then
			if self.Caret[1] > 1 then
				self.Caret[1] = self.Caret[1] - 1

				local length = string.len(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_DOWN then
			if self.Caret[1] < #self.Rows then
				self.Caret[1] = self.Caret[1] + 1

				local length = string.len(self.Rows[self.Caret[1]])
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
			self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
			if self.Caret[1] < 1 then self.Caret[1] = 1 end

			local length = string.len(self.Rows[self.Caret[1]])
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end

			self:ScrollCaret()

			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
			if self.Caret[1] > #self.Rows then self.Caret[1] = #self.Rows end
			if self.Caret[1] == #self.Rows then self.Caret[2] = 1 end

			local length = string.len(self.Rows[self.Caret[1]])
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
			local length = string.len(self.Rows[self.Caret[1]])
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
				if self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer then
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
				if self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1 then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		elseif code == KEY_F1 then
			self:ContextHelp()
		end
	end

	if (code == KEY_TAB and self.AC_HasSuggestions and self.AC_Panel) then
		self.AC_Panel:RequestFocus()
		return
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
				self:SetSelection(string.rep(" ", count))
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
	local byte, min = string.byte, math.min
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
			replacement = function( t ) return t.data[1], #t.data[1] end,
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

	return count, suggestions
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
	return count, suggestions
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
			replacement = function( t ) return t.data[1], #t.data[1] end,
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
		return 0
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

	return count, suggestions
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
		timer.Simple(0,self.AC_Check,self,true)
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

	local count, suggestions = 0, {}
	for i=1,#self.AC_AutoCompletion do
		local _count, _suggestions = self.AC_AutoCompletion[i]( self )
		if (_count != nil) then
			count = _count
			suggestions = _suggestions
			break
		end
	end

	if (count > 0) then

		local word, _ = self:AC_GetCurrentWord()

		table.sort( suggestions, function( a, b )
			local diff1 = CheckDifference( word, a.str( a ) )
			local diff2 = CheckDifference( word, b.str( b ) )
			return diff1 < diff2
		end)

		if (word == suggestions[1].str( suggestions[1] ) and count == 1) then -- The word matches the first suggestion exactly, and there are no more suggestions. No need to bother displaying
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

function EDITOR:AC_Use( suggestion )
	if (!suggestion) then return end

	-- Save caret
	local caret = self:CopyPosition( self.Caret )
	caret[2] = caret[2] - 1

	-- Get word position
	local wordstart = self:getWordStart( caret )
	local wordend = self:getWordEnd( caret )

	-- Change caret to select the word
	self.Start = wordstart
	self.Caret = wordend

	-- Change selection
	local replacement, caretoffset = suggestion:replacement( self )
	if (replacement and replacement != "") then
		caretoffset = caretoffset or #replacement
		self:SetSelection( replacement )
		wordstart[2] = wordstart[2] + caretoffset
	end

	-- Reset caret
	self.Start = wordstart
	self.Caret = wordstart

	self:RequestFocus()
	self.AC_HasSuggestion = false
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
		surface.SetDrawColor( 0,0,0,230 )
		surface.DrawRect( 0,0,pnl:GetWide(), pnl:GetTall() )
	end

	-- Override think, to make it listen for key presses
	panel.Think = function( pnl, code )
		if (!self.AC_HasSuggestions or !self.AC_Panel_Visible) then return end
		if (input.IsKeyDown( KEY_ENTER ) or input.IsKeyDown( KEY_SPACE )) then -- If enter or space is pressed
			self:AC_SetVisible( false )
			self:AC_Use( self.AC_Suggestions[pnl.Selected] )
		elseif (input.IsKeyDown( KEY_TAB ) and !pnl.AlreadyTabbed) then -- If tab is pressed
			if (input.IsKeyDown( KEY_LCONTROL )) then -- If control is held down
				pnl.Selected = pnl.Selected - 1 -- Scroll up
				if (pnl.Selected < 1) then pnl.Selected = #self.AC_Suggestions end
			else -- If control isn't held down
				pnl.Selected = pnl.Selected + 1 -- Scroll down
				if (pnl.Selected > #self.AC_Suggestions) then pnl.Selected = 1 end
			end
			self:AC_FillInfoList( self.AC_Suggestions[pnl.Selected] ) -- Fill the info list
			pnl:RequestFocus()
			pnl.AlreadyTabbed = true -- To keep it from scrolling a thousand times a second
		elseif (pnl.AlreadyTabbed and !input.IsKeyDown( KEY_TAB )) then
			pnl.AlreadyTabbed = nil
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
		local w, _ = surface.GetTextSize( txt:sub( prev_newline, cur_end ) )
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
		surface.SetFont( "E2SmallFont" )
		for k,v in pairs( others ) do
			local nice_name = v:nice_str( self )

			local namew, nameh = surface.GetTextSize( nice_name )

			local label = vgui.Create("DLabel")
			label:SetText( "" )
			label.Paint = function( pnl )
				local w,h = pnl:GetSize()
				draw.RoundedBox( 1,1,1, w-2,h-2, Color( 65,105,225,255 ) )
				surface.SetFont( "E2SmallFont" )
				surface.SetTextPos( 6, h/2-nameh/2 )
				surface.SetTextColor( 255,255,255,255 )
				surface.DrawText( nice_name )
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
	local textw, texth = surface.GetTextSize( desc )

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
	local count = 0
	local maxw = 15

	surface.SetFont( "E2SmallFont" )

	-- Add all suggestions to the list
	for _,suggestion in pairs( self.AC_Suggestions ) do
		local nice_name = suggestion:nice_str( self )
		local name = suggestion:str( self )

		count = count + 1

		local txt = vgui.Create("DLabel")
		txt:SetText( "" )
		txt.count = count
		txt.suggestion = suggestion

		-- Override paint to give it the "E2 theme" and to make it highlight when selected
		txt.Paint = function( pnl )
			local w, h = pnl:GetSize()
			draw.RoundedBox( 1, 1, 1, w-2, h-2, Color( 65, 105, 225, 255 ) )
			if (panel.Selected == pnl.count) then
				draw.RoundedBox( 0, 2, 2, w - 4 , h - 4, Color(0,0,0,192) )
			end
			surface.SetFont( "E2SmallFont" )
			local _, h2 = surface.GetTextSize( nice_name )
			surface.SetTextPos( 6, h/2-h2/2 )
			surface.SetTextColor( 255,255,255,255 )
			surface.DrawText( nice_name )
		end

		-- Enable mouse presses
		txt.OnMousePressed = function( pnl )
			self:AC_SetVisible( false )
			self:AC_Use( pnl.suggestion )
		end

		-- Enable mouse hovering
		txt.OnCursorEntered = function( pnl )
			panel.Selected = pnl.count
			self:AC_FillInfoList( pnl.suggestion )
		end

		panel.list:AddItem( txt )

		-- get the width of the widest suggestion
		local w,_ = surface.GetTextSize( nice_name )
		w = w + 15
		if (w > maxw) then maxw = w end
	end

	-- Size and positions etc
	panel:SetSize( maxw, count * 20 + 2 )
	panel.curw = maxw
	panel.curh = count * 20 + 2
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

		-- keywords that cannot be followed by a "(":
		["else"]     = { [true] = true },
		["break"]    = { [true] = true },
		["continue"] = { [true] = true },
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
		color = colors[tokenname]
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
						if sstr == "foreach" then highlightmode = 3 end
					elseif wire_expression2_funclist[sstr] then
						tokenname = "function"
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
		["normal"]   = { Color(240, 240, 160), false},
		["number"]   = { Color(240, 160, 160), false},
		["opcode"]   = { Color(160, 160, 240), false},
		["compare"]  = { Color(190, 190, 240), false},
		["register"] = { Color(160, 240, 160), false},
		["string"]   = { Color(128, 128, 128), false},
		["label"]    = { Color(160, 240, 255), false},
		["macro"]    = { Color(240, 160, 255), false},
		["comment"]  = { Color(128, 128, 128), false},
		["white"]    = { Color(224, 224, 224), false},
	}

	local directives = {
		DATA   = true,
		CODE   = true,
		db     = true,
		define = true,
		alloc  = true,
	}

	function EDITOR:CPUGPUSyntaxColorLine(row)
		-- cols[n] = { tokendata, color }
		local cols = {}
		self:ResetTokenizer(row)
		self:NextCharacter()

		local gpu = self:GetParent().EditorType == "GPU"

		while self.character do
			local tokenname = ""
			self.tokendata = ""

			self:NextPattern(" *")
			if !self.character then break end

			if self:NextPattern("^[0-9][0-9.]*") then
				tokenname = "number"

			elseif self:NextPattern("^[a-zA-Z0-9_]+:") then
				tokenname = "label"

			elseif self:NextPattern("^[a-zA-Z0-9_]+") then
				local sstr = self.tokendata:Trim()
				local opcode = WireLib.CPU.opcodes[sstr]
				if opcode then
					tokenname = "opcode"
					if opcode >= 1 and opcode <= 7 or opcode == 15 then
						tokenname = "compare"
					end
				elseif gpu and WireLib.CPU.gpuopcodes[sstr] then
					tokenname = "opcode"
				elseif WireLib.CPU.registers[sstr] then
					tokenname = "register"
				elseif directives[sstr] then
					tokenname = "macro"
				else
					tokenname = "normal"
				end

			elseif self.character == "'" then
				self:NextCharacter()
				while self.character and self.character != "'" do
					if self.character == "\\" then self:NextCharacter() end
					self:NextCharacter()
				end
				self:NextCharacter()
				tokenname = "string"

			elseif self:NextPattern("^//.*$") then
				tokenname = "comment"

			else
				self:NextCharacter()
				tokenname = "white"
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
	CPU_Editor = nil
	GPU_Editor = nil
	include("wire/client/TextEditor.lua")
	include("wire/client/wire_expression2_editor.lua")
	initE2Editor()
	if code then wire_expression2_editor:SetCode(code) end
end)
