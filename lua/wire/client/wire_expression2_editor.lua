local Editor = {}

-- ----------------------------------------------------------------------
-- Fonts
-- ----------------------------------------------------------------------

local defaultFont

if system.IsWindows() then
	defaultFont = "Courier New"
elseif system.IsOSX() then
	defaultFont = "Monaco"
else
	defaultFont = "DejaVu Sans Mono"
end

Editor.FontConVar = CreateClientConVar("wire_expression2_editor_font", defaultFont, true, false)
Editor.FontSizeConVar = CreateClientConVar("wire_expression2_editor_font_size", 16, true, false)
Editor.BlockCommentStyleConVar = CreateClientConVar("wire_expression2_editor_block_comment_style", 1, true, false)
Editor.NewTabOnOpen = CreateClientConVar("wire_expression2_new_tab_on_open", "1", true, false)

Editor.Fonts = {}
-- 				Font					Description

-- Windows
Editor.Fonts["Courier New"] = "Windows standard font"
Editor.Fonts["DejaVu Sans Mono"] = ""
Editor.Fonts["Consolas"] = ""
Editor.Fonts["Fixedsys"] = ""
Editor.Fonts["Lucida Console"] = ""

-- Mac
Editor.Fonts["Monaco"] = "Mac standard font"

surface.CreateFont("DefaultBold", {
	font = "defaultbold",
	size = 12,
	weight = 700,
	antialias = true,
	additive = false,
})

Editor.CreatedFonts = {}

function Editor:SetEditorFont(editor)
	if not self.CurrentFont then
		self:ChangeFont(self.FontConVar:GetString(), self.FontSizeConVar:GetInt())
		return
	end

	editor.CurrentFont = self.CurrentFont
	editor.FontWidth = self.FontWidth
	editor.FontHeight = self.FontHeight
end

function Editor:ChangeFont(FontName, Size)
	if not FontName or FontName == "" or not Size then return end

	-- If font is not already created, create it.
	if not self.CreatedFonts[FontName .. "_" .. Size] then
		local fontTable =
		{
			font = FontName,
			size = Size,
			weight = 400,
			antialias = false,
			additive = false,
		}
		surface.CreateFont("Expression2_" .. FontName .. "_" .. Size, fontTable)
		fontTable.weight = 700
		surface.CreateFont("Expression2_" .. FontName .. "_" .. Size .. "_Bold", fontTable)
		self.CreatedFonts[FontName .. "_" .. Size] = true
	end

	self.CurrentFont = "Expression2_" .. FontName .. "_" .. Size
	surface.SetFont(self.CurrentFont)
	self.FontWidth, self.FontHeight = surface.GetTextSize(" ")

	for i = 1, self:GetNumTabs() do
		self:SetEditorFont(self:GetEditor(i))
	end
end

------------------------------------------------------------------------
-- Colors
------------------------------------------------------------------------

local colors = {
	-- Table copied from TextEditor, used for saving colors to convars.
	["directive"] = Color(240, 240, 160), -- yellow
	["number"] = Color(240, 160, 160), -- light red
	["function"] = Color(160, 160, 240), -- blue
	["notfound"] = Color(240, 96, 96), -- dark red
	["variable"] = Color(160, 240, 160), -- light green
	["string"] = Color(128, 128, 128), -- grey
	["keyword"] = Color(160, 240, 240), -- turquoise
	["operator"] = Color(224, 224, 224), -- white
	["comment"] = Color(128, 128, 128), -- grey
	["ppcommand"] = Color(240, 96, 240), -- purple
	["typename"] = Color(240, 160, 96), -- orange
	["constant"] = Color(240, 160, 240), -- pink
	["userfunction"] = Color(102, 122, 102), -- dark green
}

local colors_defaults = {}

local colors_convars = {}
for k, v in pairs(colors) do
	colors_defaults[k] = Color(v.r, v.g, v.b) -- Copy to save defaults
	colors_convars[k] = CreateClientConVar("wire_expression2_editor_color_" .. k, v.r .. "_" .. v.g .. "_" .. v.b, true, false)
end

function Editor:LoadSyntaxColors()
	for k, v in pairs(colors_convars) do
		local r, g, b = v:GetString():match("(%d+)_(%d+)_(%d+)")
		local def = colors_defaults[k]
		colors[k] = Color(tonumber(r) or def.r, tonumber(g) or def.g, tonumber(b) or def.b)
	end

	for i = 1, self:GetNumTabs() do
		self:GetEditor(i):SetSyntaxColors(colors)
	end
end

function Editor:SetSyntaxColor(colorname, colr)
	if not colors[colorname] then return end
	colors[colorname] = colr
	RunConsoleCommand("wire_expression2_editor_color_" .. colorname, colr.r .. "_" .. colr.g .. "_" .. colr.b)

	for i = 1, self:GetNumTabs() do
		self:GetEditor(i):SetSyntaxColor(colorname, colr)
	end
end

------------------------------------------------------------------------

local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
	[" "] = "_",
}

-- overwritten commands
function Editor:Init()
	self.Title = ""
	self.subTitle = ""
	self.LastClick = 0
	self.GuiClick = 0
	self.SimpleGUI = false
	self.Location = ""

	-- colors
	self.colors = {}

	self.C = {}
	self.Components = {}

	-- Load border colors, position, & size
	self:LoadEditorSettings()

	local fontTable = {
		font = "default",
		size = 11,
		weight = 300,
		antialias = false,
		additive = false,
	}
	surface.CreateFont("E2SmallFont", fontTable)
	self.logo = surface.GetTextureID("vgui/e2logo")

	self:InitComponents()
	self:LoadSyntaxColors()

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:SetV(false)

	self:InitShutdownHook()
end

local col_FL = CreateClientConVar("wire_expression2_editor_color_fl", "65_105_225", true, false)
local col_FR = CreateClientConVar("wire_expression2_editor_color_fr", "25_25_112", true, false)
local Dark = CreateClientConVar("wire_expression2_editor_color_dark", "255", true, false)
local SimpleGUI = CreateClientConVar("wire_expression2_editor_color_simplegui", "0", true, false)

local size = CreateClientConVar("wire_expression2_editor_size", "800_600", true, false)
local pos = CreateClientConVar("wire_expression2_editor_pos", "-1_-1", true, false)

function Editor:LoadEditorSettings()
	-- Colors

	local r, g, b = col_FL:GetString():match("(%d+)_(%d+)_(%d+)")
	self.colors.col_FL = Color(tonumber(r), tonumber(g), tonumber(b), 255)
	self.colors.tmp_FL = Color(tonumber(r), tonumber(g), tonumber(b), 255)

	local r, g, b = col_FR:GetString():match("(%d+)_(%d+)_(%d+)")
	self.colors.col_FR = Color(tonumber(r), tonumber(g), tonumber(b), 255)
	self.colors.tmp_FR = Color(tonumber(r), tonumber(g), tonumber(b), 255)

	self.colors.tmp_Dark = Dark:GetFloat()

	self.SimpleGUI = SimpleGUI:GetBool()

	-- Position & Size
	local w, h = size:GetString():match("(%d+)_(%d+)")
	w = tonumber(w)
	h = tonumber(h)

	self:SetSize(w, h)

	local x, y = pos:GetString():match("(%-?%d+)_(%-?%d+)")
	x = tonumber(x)
	y = tonumber(y)

	if x == -1 and y == -1 then
		self:Center()
	else
		self:SetPos(x, y)
	end

	if x < 0 or y < 0 or x + w > ScrW() or x + h > ScrH() then -- If the editor is outside the screen, reset it
		local width, height = math.min(surface.ScreenWidth() - 200, 800), math.min(surface.ScreenHeight() - 200, 620)
		self:SetPos((surface.ScreenWidth() - width) / 2, (surface.ScreenHeight() - height) / 2)
		self:SetSize(width, height)

		self:SaveEditorSettings()
	end
end

function Editor:SaveEditorSettings()
	-- Colors
	local r, g, b = self.colors.col_FL.r, self.colors.col_FL.g, self.colors.col_FL.b
	RunConsoleCommand("wire_expression2_editor_color_fl", r .. "_" .. g .. "_" .. b)
	local r, g, b = self.colors.col_FR.r, self.colors.col_FR.g, self.colors.col_FR.b
	RunConsoleCommand("wire_expression2_editor_color_fr", r .. "_" .. g .. "_" .. b)
	RunConsoleCommand("wire_expression2_editor_color_dark", self.tmp_Dark and "1" or "0")

	RunConsoleCommand("wire_expression2_editor_color_simplegui", self.SimpleGUI and "1" or "0")

	-- Position & Size
	local w, h = self:GetSize()
	RunConsoleCommand("wire_expression2_editor_size", w .. "_" .. h)

	local x, y = self:GetPos()
	RunConsoleCommand("wire_expression2_editor_pos", x .. "_" .. y)
end

function Editor:DefaultEditorColors()
	self.colors.col_FL = Color(65, 105, 225, 255) -- Royal Blue
	self.colors.col_FR = Color(25, 25, 112, 255) -- Midnight Blue
	self.colors.tmp_FL = Color(65, 105, 225, 255)
	self.colors.tmp_FR = Color(25, 25, 112, 255)
	self.colors.tmp_Dark = 255

	self:SaveEditorSettings()
end

function Editor:Paint()
	local w, h = self:GetSize()
	if self.SimpleGUI then
		draw.RoundedBox(4, 0, 0, w, h, self.colors.col_FL)
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(0, 22, w, 1)
	else
		local dif = { (self.colors.col_FR.r - self.colors.col_FL.r) / w, (self.colors.col_FR.g - self.colors.col_FL.g) / w, (self.colors.col_FR.b - self.colors.col_FL.b) / w }
		draw.RoundedBox(4, 0, 0, 10, h, self.colors.col_FL)
		draw.RoundedBox(4, w - 15, 0, 15, h, self.colors.col_FR)

		for i = 5, w - 9, 5 do
			surface.SetDrawColor(math.floor(self.colors.col_FL.r + dif[1] * i), math.floor(self.colors.col_FL.g + dif[2] * i), math.floor(self.colors.col_FL.b + dif[3] * i), self.colors.col_FL.a)
			surface.DrawRect(i, 0, 5, h)
		end
	end
	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(0, 22, w, 1)
	surface.SetDrawColor(255, 255, 255, 255)

	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	return true
end

function Editor:PaintOver()
	local w, h = self:GetSize()

	draw.RoundedBox(4, 0, 0, 118, 21, self.colors.col_FL)
	surface.SetFont("DefaultBold")
	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(10, 6)
	surface.DrawText(self.Title .. self.subTitle)
	--[[
	if(self.E2) then
	surface.SetTexture(self.logo)
	surface.SetDrawColor( 255, 255, 255, 128 )
	surface.DrawTexturedRect( w-148, h-158, 128, 128)
	end
	]] --
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetTextPos(0, 0)
	surface.SetFont("Default")
	return true
end

function Editor:PerformLayout()
	local w, h = self:GetSize()

	for i = 1, #self.Components do
		local c = self.Components[i]
		local c_x, c_y, c_w, c_h = c.x, c.y, c.w, c.h
		if (c.x < 0) then c_x = w + c.x end
		if (c.y < 0) then c_y = h + c.y end
		if (c.w < 0) then c_w = w + c.w - c_x end
		if (c.h < 0) then c_h = h + c.h - c_y end
		c.panel:SetPos(c_x, c_y)
		c.panel:SetSize(c_w, c_h)
	end
end

function Editor:OnMousePressed(mousecode)
	if mousecode ~= 107 then return end -- do nothing if mouseclick is other than left-click
	if not self.pressed then
		self.pressed = true
		self.p_x, self.p_y = self:GetPos()
		self.p_w, self.p_h = self:GetSize()
		self.p_mx = gui.MouseX()
		self.p_my = gui.MouseY()
		self.p_mode = self:getMode()
		if self.p_mode == "drag" then
			if self.GuiClick > CurTime() - 0.2 then
				self:fullscreen()
				self.pressed = false
				self.GuiClick = 0
			else
				self.GuiClick = CurTime()
			end
		end
	end
end

function Editor:OnMouseReleased(mousecode)
	if mousecode ~= 107 then return end -- do nothing if mouseclick is other than left-click
	self.pressed = false
end

function Editor:Think()
	if self.fs then return end
	if self.pressed then
		if not input.IsMouseDown(MOUSE_LEFT) then -- needs this if you let go of the mouse outside the panel
			self.pressed = false
		end
		local movedX = gui.MouseX() - self.p_mx
		local movedY = gui.MouseY() - self.p_my
		if self.p_mode == "drag" then
			local x = self.p_x + movedX
			local y = self.p_y + movedY
			if (x < 10 and x > -10) then x = 0 end
			if (y < 10 and y > -10) then y = 0 end
			if (x + self.p_w < surface.ScreenWidth() + 10 and x + self.p_w > surface.ScreenWidth() - 10) then x = surface.ScreenWidth() - self.p_w end
			if (y + self.p_h < surface.ScreenHeight() + 10 and y + self.p_h > surface.ScreenHeight() - 10) then y = surface.ScreenHeight() - self.p_h end
			self:SetPos(x, y)
		end
		if self.p_mode == "sizeBR" then
			local w = self.p_w + movedX
			local h = self.p_h + movedY
			if (self.p_x + w < surface.ScreenWidth() + 10 and self.p_x + w > surface.ScreenWidth() - 10) then w = surface.ScreenWidth() - self.p_x end
			if (self.p_y + h < surface.ScreenHeight() + 10 and self.p_y + h > surface.ScreenHeight() - 10) then h = surface.ScreenHeight() - self.p_y end
			if (w < 300) then w = 300 end
			if (h < 200) then h = 200 end
			self:SetSize(w, h)
		end
		if self.p_mode == "sizeR" then
			local w = self.p_w + movedX
			if (w < 300) then w = 300 end
			self:SetWide(w)
		end
		if self.p_mode == "sizeB" then
			local h = self.p_h + movedY
			if (h < 200) then h = 200 end
			self:SetTall(h)
		end
	end
	if not self.pressed then
		local cursor = "arrow"
		local mode = self:getMode()
		if (mode == "sizeBR") then cursor = "sizenwse"
		elseif (mode == "sizeR") then cursor = "sizewe"
		elseif (mode == "sizeB") then cursor = "sizens"
		end
		if cursor ~= self.cursor then
			self.cursor = cursor
			self:SetCursor(self.cursor)
		end
	end

	local x, y = self:GetPos()
	local w, h = self:GetSize()

	if w < 518 then w = 518 end
	if h < 200 then h = 200 end
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	if x + w > surface.ScreenWidth() then x = surface.ScreenWidth() - w end
	if y + h > surface.ScreenHeight() then y = surface.ScreenHeight() - h end

	self:SetPos(x, y)
	self:SetSize(w, h)
end

-- special functions

function Editor:fullscreen()
	if self.fs then
		self:SetPos(self.preX, self.preY)
		self:SetSize(self.preW, self.preH)
		self.fs = false
	else
		self.preX, self.preY = self:GetPos()
		self.preW, self.preH = self:GetSize()
		self:SetPos(0, 0)
		self:SetSize(surface.ScreenWidth(), surface.ScreenHeight())
		self.fs = true
	end
end

function Editor:getMode()
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	local ix = gui.MouseX() - x
	local iy = gui.MouseY() - y

	if (ix < 0 or ix > w or iy < 0 or iy > h) then return end -- if the mouse is outside the box
	if (iy < 22) then
		return "drag"
	end
	if (iy > h - 10) then
		if (ix > w - 20) then return "sizeBR" end
		return "sizeB"
	end
	if (ix > w - 10) then
		if (iy > h - 20) then return "sizeBR" end
		return "sizeR"
	end
end

function Editor:addComponent(panel, x, y, w, h)
	local t = #self.Components + 1
	self.Components[t] = {}
	self.Components[t].panel = panel
	self.Components[t].x = x
	self.Components[t].y = y
	self.Components[t].w = w
	self.Components[t].h = h
	return self.Components[t]
end

-- TODO: Fix this function
local function extractNameFromCode(str)
	return str:match("@name ([^\r\n]+)")
end

local function getPreferredTitles(Line, code)
	local title
	local tabtext

	local str = Line
	if str and str ~= "" then
		title = str
		tabtext = str
	end

	local str = extractNameFromCode(code)
	if str and str ~= "" then
		if not title then
			title = str
		end
		tabtext = str
	end

	return title, tabtext
end

function Editor:GetLastTab() return self.LastTab end

function Editor:SetLastTab(Tab) self.LastTab = Tab end

function Editor:GetActiveTab() return self.C['TabHolder'].panel:GetActiveTab() end

function Editor:GetNumTabs() return #self.C['TabHolder'].panel.Items end

function Editor:SetActiveTab(val)
	if self:GetActiveTab() == val then
		val:GetPanel():RequestFocus()
		return
	end
	self:SetLastTab(self:GetActiveTab())
	if isnumber(val) then
		self.C['TabHolder'].panel:SetActiveTab(self.C['TabHolder'].panel.Items[val].Tab)
		self:GetCurrentEditor():RequestFocus()
	elseif val and val:IsValid() then
		self.C['TabHolder'].panel:SetActiveTab(val)
		val:GetPanel():RequestFocus()
	end


	-- Editor subtitle and tab text
	local title, tabtext = getPreferredTitles(self:GetChosenFile(), self:GetCode())

	if title then self:SubTitle("Editing: " .. title) else self:SubTitle() end
	if tabtext then
		if self:GetActiveTab():GetText() ~= tabtext then
			self:GetActiveTab():SetText(tabtext)
			self.C['TabHolder'].panel:InvalidateLayout()
		end
	end
end

function Editor:GetActiveTabIndex()
	local tab = self:GetActiveTab()
	for k, v in pairs(self.C['TabHolder'].panel.Items) do
		if tab == v.Tab then
			return k
		end
	end
	return -1
end


function Editor:SetActiveTabIndex(index)
	local tab = self.C['TabHolder'].panel.Items[index].Tab

	if not tab then return end

	self:SetActiveTab(tab)
end

local function extractNameFromFilePath(str)
	local found = str:reverse():find("/", 1, true)
	if found then
		return str:Right(found - 1)
	else
		return str
	end
end

function Editor:SetSyntaxColorLine(func)
	self.SyntaxColorLine = func
	for i = 1, self:GetNumTabs() do
		self:GetEditor(i).SyntaxColorLine = func
	end
end

function Editor:GetSyntaxColorLine() return self.SyntaxColorLine end

local old
function Editor:FixTabFadeTime()
	if old ~= nil then return end -- It's already being fixed
	local old = self.C['TabHolder'].panel:GetFadeTime()
	self.C['TabHolder'].panel:SetFadeTime(0)
	timer.Simple(old, function() self.C['TabHolder'].panel:SetFadeTime(old) old = nil end)
end

function Editor:CreateTab(chosenfile)
	local editor = vgui.Create("Expression2Editor")
	editor.parentpanel = self

	local sheet = self.C['TabHolder'].panel:AddSheet(extractNameFromFilePath(chosenfile), editor)
	self:SetEditorFont(editor)
	editor.chosenfile = chosenfile

	sheet.Tab.OnMousePressed = function(pnl, keycode, ...)

		if keycode == MOUSE_MIDDLE then
			--self:FixTabFadeTime()
			self:CloseTab(pnl)
			return
		elseif keycode == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption("Close", function()
			--self:FixTabFadeTime()
				self:CloseTab(pnl)
			end)
			menu:AddOption("Close all others", function()
				self:FixTabFadeTime()
				self:SetActiveTab(pnl)
				for i = self:GetNumTabs(), 1, -1 do
					if self.C['TabHolder'].panel.Items[i] ~= sheet then
						self:CloseTab(i)
					end
				end
			end)
			menu:AddSpacer()
			menu:AddOption("Save", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				self:SetActiveTab(pnl)
				self:SaveFile(self:GetChosenFile(), true)
				self:SetActiveTab(self:GetLastTab())
				self:SetLastTab(old)
			end)
			menu:AddOption("Save As", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				self:SetActiveTab(pnl)
				self:SaveFile(self:GetChosenFile(), false, true)
				self:SetActiveTab(self:GetLastTab())
				self:SetLastTab(old)
			end)
			menu:AddSpacer()
			menu:AddOption("Copy file path to clipboard", function()
				if editor.chosenfile and editor.chosenfile ~= "" then
					SetClipboardText(editor.chosenfile)
				end
			end)
			menu:AddOption("Copy all file paths to clipboard", function()
				local str = ""
				for i = 1, self:GetNumTabs() do
					local chosenfile = self:GetEditor(i).chosenfile
					if chosenfile and chosenfile ~= "" then
						str = str .. chosenfile .. ";"
					end
				end
				str = str:sub(1, -2)
				SetClipboardText(str)
			end)
			menu:Open()
			return
		end

		self:SetActiveTab(pnl)
	end

	sheet.Tab.Paint = function(tab)
		local w, h = tab:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if self:GetActiveTab() == tab then
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192))
		elseif self:GetLastTab() == tab then
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 145))
		end
	end

	editor.OnTextChanged = function(panel)
		timer.Create("e2autosave", 5, 1, function()
			self:AutoSave()
		end)
	end
	editor.OnShortcut = function(_, code)
		if code == KEY_S then
			self:SaveFile(self:GetChosenFile())
			if self.E2 then self:Validate() end
		else
			local mode = GetConVar("wire_expression2_autocomplete_controlstyle"):GetInt()
			local enabled = GetConVar("wire_expression2_autocomplete"):GetBool()
			if mode == 1 and enabled then
				if code == KEY_B then
					self:Validate(true)
				elseif code == KEY_SPACE then
					local ed = self:GetCurrentEditor()
					if (ed.AC_Panel and ed.AC_Panel:IsVisible()) then
						ed:AC_Use(ed.AC_Suggestions[1])
					end
				end
			elseif code == KEY_SPACE then
				self:Validate(true)
			end
		end
	end
	editor:RequestFocus()

	local func = self:GetSyntaxColorLine()
	if func ~= nil then -- it's a custom syntax highlighter
		editor.SyntaxColorLine = func
	else -- else it's E2's syntax highlighter
		editor:SetSyntaxColors(colors)
	end

	self:OnTabCreated(sheet) -- Call a function that you can override to do custom stuff to each tab.

	return sheet
end

function Editor:OnTabCreated(sheet) end

-- This function is made to be overwritten

function Editor:GetNextAvailableTab()
	local activetab = self:GetActiveTab()
	for k, v in pairs(self.C['TabHolder'].panel.Items) do
		if v.Tab and v.Tab:IsValid() and v.Tab ~= activetab then
			return v.Tab
		end
	end
end

function Editor:NewTab()
	local sheet = self:CreateTab("generic")
	self:SetActiveTab(sheet.Tab)
	if self.E2 then
		self:NewScript(true)
	end
end

function Editor:CloseTab(_tab)
	local activetab, sheetindex
	if _tab then
		if isnumber(_tab) then
			local temp = self.C['TabHolder'].panel.Items[_tab]
			if temp then
				activetab = temp.Tab
				sheetindex = _tab
			else
				return
			end
		else
			activetab = _tab
			-- Find the sheet index
			for k, v in pairs(self.C['TabHolder'].panel.Items) do
				if activetab == v.Tab then
					sheetindex = k
					break
				end
			end
		end
	else
		activetab = self:GetActiveTab()
		-- Find the sheet index
		for k, v in pairs(self.C['TabHolder'].panel.Items) do
			if activetab == v.Tab then
				sheetindex = k
				break
			end
		end
	end

	self:AutoSave()

	-- There's only one tab open, no need to actually close any tabs
	if self:GetNumTabs() == 1 then
		activetab:SetText("generic")
		self.C['TabHolder'].panel:InvalidateLayout()
		self:NewScript(true)
		return
	end

	-- Find the panel (for the scroller)
	local tabscroller_sheetindex
	for k, v in pairs(self.C['TabHolder'].panel.tabScroller.Panels) do
		if v == activetab then
			tabscroller_sheetindex = k
			break
		end
	end

	self:FixTabFadeTime()

	if activetab == self:GetActiveTab() then -- We're about to close the current tab
		if self:GetLastTab() and self:GetLastTab():IsValid() then -- If the previous tab was saved
			if activetab == self:GetLastTab() then -- If the previous tab is equal to the current tab
				local othertab = self:GetNextAvailableTab() -- Find another tab
				if othertab and othertab:IsValid() then -- If that other tab is valid, use it
					self:SetActiveTab(othertab)
					self:SetLastTab()
				else -- Reset the current tab (backup)
					self:GetActiveTab():SetText("generic")
					self.C['TabHolder'].panel:InvalidateLayout()
					self:NewScript(true)
					return
				end
			else -- Change to the previous tab
				self:SetActiveTab(self:GetLastTab())
				self:SetLastTab()
			end
		else -- If the previous tab wasn't saved
			local othertab = self:GetNextAvailableTab() -- Find another tab
			if othertab and othertab:IsValid() then -- If that other tab is valid, use it
				self:SetActiveTab(othertab)
			else -- Reset the current tab (backup)
				self:GetActiveTab():SetText("generic")
				self.C['TabHolder'].panel:InvalidateLayout()
				self:NewScript(true)
				return
			end
		end
	end

	self:OnTabClosed(activetab) -- Call a function that you can override to do custom stuff to each tab.

	activetab:GetPanel():Remove()
	activetab:Remove()
	table.remove(self.C['TabHolder'].panel.Items, sheetindex)
	table.remove(self.C['TabHolder'].panel.tabScroller.Panels, tabscroller_sheetindex)

	self.C['TabHolder'].panel:InvalidateLayout()
	local w, h = self.C['TabHolder'].panel:GetSize()
	self.C['TabHolder'].panel:SetSize(w + 1, h) -- +1 so it updates
end

function Editor:OnTabClosed(sheet) end

-- This function is made to be overwritten

-- initialization commands

local wire_expression2_editor_browserwidth = CreateClientConVar("wire_expression2_editor_browserwidth", "200", true, false)

function Editor:InitComponents()
	self.Components = {}
	self.C = {}

	local bw = wire_expression2_editor_browserwidth:GetInt()

	-- addComponent( panel, x, y, w, h )
	-- if x, y, w, h is minus, it will stay relative to right or buttom border
	self.C['Close'] = self:addComponent(vgui.Create("DButton", self), -22, 4, 18, 18) -- Close button
	self.C['Inf'] = self:addComponent(vgui.Create("DButton", self), -42, 4, 18, 18) -- Info button
	self.C['Sav'] = self:addComponent(vgui.Create("Button", self), bw + 41, 30, 20, 20) -- Save button
	self.C['NewTab'] = self:addComponent(vgui.Create("Button", self), bw + 62, 30, 20, 20) -- New tab button
	self.C['CloseTab'] = self:addComponent(vgui.Create("Button", self), bw + 83, 30, 20, 20) -- Close tab button
	self.C['SaE'] = self:addComponent(vgui.Create("Button", self), -70, 30, -10, 20) -- Save & Exit button
	self.C['SavAs'] = self:addComponent(vgui.Create("Button", self), -123, 30, -72, 20) -- Save As button
	self.C['Browser'] = self:addComponent(vgui.Create("wire_expression2_browser", self), 10, 30, bw + 7, -10) -- Expression browser
	self.C['TabHolder'] = self:addComponent(vgui.Create("DPropertySheet", self), bw + 15, 52, -5, -27) -- TabHolder
	self:CreateTab("generic")
	self.C['Btoggle'] = self:addComponent(vgui.Create("Button", self), bw + 20, 30, 20, 20) -- Toggle Browser being shown
	self.C['ConBut'] = self:addComponent(vgui.Create("Button", self), -62, 4, 18, 18) -- Control panel open/close
	self.C['Control'] = self:addComponent(vgui.Create("Panel", self), -350, 52, 342, -32) -- Control Panel
	self.C['Credit'] = self:addComponent(vgui.Create("DTextEntry", self), -160, 52, 150, 150) -- Credit box
	self.C['Val'] = self:addComponent(vgui.Create("Button", self), bw + 20, -30, -10, 20) -- Validation line

	self.C['TabHolder'].panel.Paint = function() end

	-- extra component options
	self.C['Close'].panel:SetText("x")
	self.C['Close'].panel.DoClick = function(btn) self:Close() end
	self.C['Credit'].panel:SetTextColor(Color(0, 0, 0, 255))
	self.C['Credit'].panel:SetText("\t\tCREDITS\n\n\tEditor by: \tSyranide and Shandolum\n\n\tTabs (and more) added by Divran.\n\n\tFixed for GMod13 By Ninja101") -- Sure why not ;)
	self.C['Credit'].panel:SetMultiline(true)
	self.C['Credit'].panel:SetVisible(false)
	self.C['Inf'].panel:SetText("i")
	self.C['Inf'].panel.DoClick = function(btn)
		self.C['Credit'].panel:SetVisible(not self.C['Credit'].panel:IsVisible())
	end
	self.C['Sav'].panel:SetText("")
	self.C['Sav'].panel:SetImage("icon16/disk.png")
	self.C['Sav'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
	end
	self.C['Sav'].panel.DoClick = function(button) self:SaveFile(self:GetChosenFile()) end

	self.C['NewTab'].panel:SetText("")
	self.C['NewTab'].panel:SetImage("icon16/page_white_add.png")
	self.C['NewTab'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
	end
	self.C['NewTab'].panel.DoClick = function(button)
		self:NewTab()
	end

	self.C['CloseTab'].panel:SetText("")
	self.C['CloseTab'].panel:SetImage("icon16/page_white_delete.png")
	self.C['CloseTab'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
	end
	self.C['CloseTab'].panel.DoClick = function(button)
		self:CloseTab()
	end

	self.C['SaE'].panel:SetText("")
	self.C['SaE'].panel.Font = "E2SmallFont"
	self.C['SaE'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
		surface.SetFont(button.Font)
		surface.SetTextPos(3, 4)
		surface.SetTextColor(255, 255, 255, 255)
		if self.chip then surface.DrawText("Upload & Exit")
		else surface.DrawText(" Save & Exit")
		end
	end
	self.C['SaE'].panel.DoClick = function(button) self:SaveFile(self:GetChosenFile(), true) end

	self.C['SavAs'].panel:SetText("")
	self.C['SavAs'].panel.Font = "E2SmallFont"
	self.C['SavAs'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
		surface.SetFont(button.Font)
		surface.SetTextPos(3, 4)
		surface.SetTextColor(255, 255, 255, 255)
		surface.DrawText("  Save As")
	end
	self.C['SavAs'].panel.DoClick = function(button) self:SaveFile(self:GetChosenFile(), false, true) end

	self.C['Browser'].panel:AddRightClick(self.C['Browser'].panel.filemenu, 4, "Save to", function()
		Derma_Query("Overwrite this file?", "Save To",
			"Overwrite", function()
				self:SaveFile(self.C['Browser'].panel.File.FileDir)
			end,
			"Cancel")
	end)
	self.C['Browser'].panel.OnFileOpen = function(_, filepath, newtab)
		self:Open(filepath, nil, newtab)
	end

	self.C['Val'].panel:SetText("   Click to validate...")
	self.C['Val'].panel.UpdateColours = function(button, skin)
		return button:SetTextStyleColor(skin.Colours.Button.Down)
	end
	self.C['Val'].panel.SetBGColor = function(button, r, g, b, a)
		self.C['Val'].panel.bgcolor = Color(r, g, b, a)
	end
	self.C['Val'].panel.bgcolor = self.colors.col_FL
	self.C['Val'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, button.bgcolor)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 128)) end
	end
	self.C['Val'].panel.OnMousePressed = function(panel, btn)
		if btn == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption("Copy to clipboard", function()
				SetClipboardText(self.C['Val'].panel:GetValue():sub(4))
			end)
			menu:Open()
		else
			self:Validate(true)
		end
	end
	self.C['Btoggle'].panel:SetText("<")
	self.C['Btoggle'].panel.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
	end
	self.C['Btoggle'].panel.DoClick = function(button)
		if button.hide then
			button.hide = false
			button:SetText("<")
		else
			button.hide = true
			button:SetText(">")
		end
		button.toggle = true
	end
	self.C['Btoggle'].panel.anispeed = 10
	self.C['Btoggle'].panel.Think = function(button)
		if not button.toggle then return end
		local bw = wire_expression2_editor_browserwidth:GetInt()
		if button.hide and self.C['Btoggle'].x > 10 then
			self.C['Btoggle'].x = self.C['Btoggle'].x - button.anispeed
			self.C['Sav'].x = self.C['Sav'].x - button.anispeed
			self.C['NewTab'].x = self.C['NewTab'].x - button.anispeed
			self.C['CloseTab'].x = self.C['CloseTab'].x - button.anispeed
			self.C['TabHolder'].x = self.C['TabHolder'].x - button.anispeed
			self.C['Val'].x = self.C['Val'].x - button.anispeed
			self.C['Browser'].w = self.C['Browser'].w - button.anispeed
		elseif not button.hide and self.C['Btoggle'].x < bw + 20 then
			self.C['Btoggle'].x = self.C['Btoggle'].x + button.anispeed
			self.C['Sav'].x = self.C['Sav'].x + button.anispeed
			self.C['NewTab'].x = self.C['NewTab'].x + button.anispeed
			self.C['CloseTab'].x = self.C['CloseTab'].x + button.anispeed
			self.C['TabHolder'].x = self.C['TabHolder'].x + button.anispeed
			self.C['Val'].x = self.C['Val'].x + button.anispeed
			self.C['Browser'].w = self.C['Browser'].w + button.anispeed
		end

		if self.C['Browser'].panel:IsVisible() and self.C['Browser'].w <= 0 then self.C['Browser'].panel:SetVisible(false)
		elseif not self.C['Browser'].panel:IsVisible() and self.C['Browser'].w > 0 then self.C['Browser'].panel:SetVisible(true)
		end
		self:InvalidateLayout()
		if button.hide then
			if self.C['Btoggle'].x > 10 or self.C['Sav'].x > 30 or self.C['Val'].x < bw + 20 or self.C['Browser'].w > 0 then return end
			button.toggle = false
		else
			if self.C['Btoggle'].x < bw + 20 or self.C['Sav'].x < bw + 40 or self.C['Val'].x < bw + 20 or self.C['Browser'].w < bw then return end
			button.toggle = false
		end
	end
	self.C['ConBut'].panel:SetImage("icon16/wrench.png")
	self.C['ConBut'].panel:SetText("")
	self.C['ConBut'].panel.Paint = function(button) end
	self.C['ConBut'].panel.DoClick = function() self.C['Control'].panel:SetVisible(not self.C['Control'].panel:IsVisible()) end
	self:InitControlPanel(self.C['Control'].panel) -- making it seperate for better overview
	self.C['Control'].panel:SetVisible(false)
	if self.E2 then self:Validate() end
end

function Editor:AutoSave()
	local buffer = self:GetCode()
	if self.savebuffer == buffer or buffer == defaultcode or buffer == "" then return end
	self.savebuffer = buffer
	file.Write(self.Location .. "/_autosave_.txt", buffer)
end

function Editor:AddControlPanelTab(label, icon, tooltip)
	local frame = self.C['Control'].panel
	local panel = vgui.Create("Panel")
	local ret = frame.TabHolder:AddSheet(label, panel, icon, false, false, tooltip)
	ret.Tab.Paint = function(tab)
		local w, h = tab:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if frame.TabHolder:GetActiveTab() == tab then
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192))
		end
	end
	local old = ret.Tab.OnMousePressed
	function ret.Tab.OnMousePressed(...)
		frame:ResizeAll()
		old(...)
	end

	return ret
end

function Editor:InitControlPanel(frame)
	local C = self.C['Control']

	-- Give it the nice gradient look
	frame.Paint = function(pnl)
		local _w, _h = self:GetSize()
		local w, h = pnl:GetSize()
		if self.SimpleGUI then
			draw.RoundedBox(4, 0, 0, w, h, self.colors.col_FL)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 22, w, 1)
		else
			local dif = { (self.colors.col_FR.r - self.colors.col_FL.r) / _w, (self.colors.col_FR.g - self.colors.col_FL.g) / _w, (self.colors.col_FR.b - self.colors.col_FL.b) / _w }
			local i = _w - 350
			draw.RoundedBox(4, 0, 0, 10, h, Color(math.floor(self.colors.col_FL.r + dif[1] * i), math.floor(self.colors.col_FL.g + dif[2] * i), math.floor(self.colors.col_FL.b + dif[3] * i), self.colors.col_FL.a))
			draw.RoundedBox(4, w - 15, 0, 15, h, self.colors.col_FR)

			local _i = 0
			for i = _w - 350 + 5, _w, 5 do
				_i = _i + 5
				surface.SetDrawColor(math.floor(self.colors.col_FL.r + dif[1] * i), math.floor(self.colors.col_FL.g + dif[2] * i), math.floor(self.colors.col_FL.b + dif[3] * i), self.colors.col_FL.a)
				surface.DrawRect(_i, 0, 5, h)
			end
		end
		draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
		draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	end

	-- Add a property sheet to hold the tabs
	local tabholder = vgui.Create("DPropertySheet", frame)
	tabholder:SetPos(2, 4)
	frame.TabHolder = tabholder

	-- They need to be resized one at a time... dirty fix incoming (If you know of a nicer way to do this, don't hesitate to fix it.)
	local function callNext(t, n)
		local obj = t[n]
		local pnl = obj[1]
		if pnl and pnl:IsValid() then
			local x, y = obj[2], obj[3]
			pnl:SetPos(x, y)
			local w, h = pnl:GetParent():GetSize()
			local wofs, hofs = w - x * 2, h - y * 2
			pnl:SetSize(wofs, hofs)
		end
		n = n + 1
		if n <= #t then
			timer.Simple(0, function() callNext(t, n) end)
		end
	end

	function frame:ResizeAll()
		timer.Simple(0, function()
			callNext(self.ResizeObjects, 1)
		end)
	end

	-- Resize them at the right times
	local old = frame.SetSize
	function frame:SetSize(...)
		self:ResizeAll()
		old(self, ...)
	end

	local old = frame.SetVisible
	function frame:SetVisible(...)
		self:ResizeAll()
		old(self, ...)
	end

	-- Function to add more objects to resize automatically
	frame.ResizeObjects = {}
	function frame:AddResizeObject(...)
		self.ResizeObjects[#self.ResizeObjects + 1] = { ... }
	end

	-- Our first object to auto resize is the tabholder. This sets it to position 2,4 and with a width and height offset of w-4, h-8.
	frame:AddResizeObject(tabholder, 2, 4)

	tabholder.Paint = function() end

	-- ------------------------------------------- EDITOR TAB
	local sheet = self:AddControlPanelTab("Editor", "icon16/wrench.png", "Options for the editor itself.")

	-- WINDOW BORDER COLORS

	local dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 4, 4)
	dlist:EnableVerticalScrollbar(true)

	local Label = vgui.Create("DLabel")
	dlist:AddItem(Label)
	Label:SetText("Window border colors")
	Label:SizeToContents()

	local SimpleColors = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(SimpleColors)
	SimpleColors:SetSize(180, 20)
	SimpleColors:SetText("Simple Colors")
	SimpleColors:SetConVar("wire_expression2_editor_color_simplegui")
	function SimpleColors.OnChange(pnl, b)
		self.SimpleGUI = b
	end

	local DarknessColor = vgui.Create("DNumSlider")
	dlist:AddItem(DarknessColor)
	DarknessColor:SetText("Darkness")
	DarknessColor:SetMinMax(0, 255)
	DarknessColor:SetDecimals(0)
	DarknessColor:SetDark(false)
	function DarknessColor.OnValueChanged(pnl, val)
		self.colors.tmp_Dark = val
		self:CalculateColor()
	end

	DarknessColor:SetValue(255)

	local defaultbutton = vgui.Create("DButton")
	defaultbutton:SetText("Default")
	defaultbutton:SetToolTip("Set window border colors to default")
	function defaultbutton.DoClick(btn)
		self:DefaultEditorColors()
	end

	dlist:AddItem(defaultbutton)

	-- Other colors

	local Label = vgui.Create("DLabel")
	dlist:AddItem(Label)
	Label:SetText("Other color options")
	Label:SizeToContents()

	local SkipUpdate = false
	local CurrentColor = "Double click highlight"
	local r, g, b, a = 255, 255, 255, 255

	local temp = vgui.Create("Panel")
	dlist:AddItem(temp)
	temp:SetTall(132)

	-- Create color mixer, number wangs, default button, and drop down menu
	local ColorMixer = vgui.Create("DColorMixer", temp)
	local RBox = vgui.Create("DNumberWang", temp)
	local GBox = vgui.Create("DNumberWang", temp)
	local BBox = vgui.Create("DNumberWang", temp)
	local ABox = vgui.Create("DNumberWang", temp)
	local DefaultButton = vgui.Create("DButton", temp)
	local CurrentColorSelect = vgui.Create("DComboBox", temp)

	-- Add choices
	local Choices = {
		["Double click highlight"] = { "wire_expression2_editor_color_dblclickhighlight", { 0, 100, 0, 100 } },
	}
	for k, v in pairs(Choices) do
		CurrentColorSelect:AddChoice(k)
	end

	-- Manage choices
	CurrentColorSelect.OnSelect = function(panel, index, value)
		if (Choices[value]) then
			local r, g, b, a = GetConVar(Choices[value][1]):GetString():match("(%d+)_(%d+)_(%d+)_(%d+)")
			r, g, b, a = tonumber(r) or Choices[value][2][1], tonumber(g) or Choices[value][2][2], tonumber(b) or Choices[value][2][3], tonumber(a) or Choices[value][2][4]
			RBox:SetValue(r)
			GBox:SetValue(g)
			BBox:SetValue(b)
			ABox:SetValue(a)
			ColorMixer:SetColor(Color(r, g, b, a))
			CurrentColor = value
		end
	end

	-- Default button
	DefaultButton.DoClick = function(pnl)
		r, g, b, a = Choices[CurrentColor][2][1], Choices[CurrentColor][2][2], Choices[CurrentColor][2][3], Choices[CurrentColor][2][4]
		ColorMixer:SetColor(Color(r, g, b, a))
		RBox:SetValue(r)
		GBox:SetValue(g)
		BBox:SetValue(b)
		ABox:SetValue(a)
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
	end

	DefaultButton:SetText("Default")

	ColorMixer:SetSize(130, 130)

	ColorMixer.PerformLayout = function(pnl)
		local w, h = pnl:GetSize()
		pnl.RGB:SetPos(0, 0)
		pnl.RGB:SetSize(20, h)
		pnl.Palette:SetPos(44, 0)
		pnl.Palette:SetSize(w - 44, h)
		pnl.Alpha:SetPos(22, 0)
		pnl.Alpha:SetSize(20, h)
	end

	local old = ColorMixer.Palette.OnMouseReleased
	ColorMixer.Palette.OnMouseReleased = function(...)
		local clr = ColorMixer:GetColor()
		r, g, b, a = clr.r, clr.g, clr.b, 255 - ColorMixer.Alpha:GetValue() * 255
		SkipUpdate = true
		RBox:SetValue(r)
		GBox:SetValue(g)
		BBox:SetValue(b)
		ABox:SetValue(a)
		SkipUpdate = false
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
		old(...)
	end

	local old = ColorMixer.RGB.OnMouseReleased
	ColorMixer.RGB.OnMouseReleased = function(...)
		ColorMixer.Palette:OnMouseReleased()
		old(...)
	end

	local old = ColorMixer.Alpha.OnMouseReleased
	ColorMixer.Alpha.OnMouseReleased = function(...)
		ColorMixer.Palette:OnMouseReleased()
		old(...)
	end

	-- Loop this to make it a little neater
	local temp = { RBox, GBox, BBox, ABox }
	for k, v in pairs(temp) do
		v:SetValue(255)
		v:SetMin(0)
		v:SetMax(255)
		v:SetDecimals(0)
		v:SetWide(64)
		local old = v:GetTextArea().OnEnter
		v:GetTextArea().OnEnter = function(...)
			v:OnValueChanged()
			old(...)
		end
	end

	-- OnValueChanged functions
	RBox.OnValueChanged = function(pnl)
		if SkipUpdate or r == pnl:GetValue() then return end
		r = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b, a))
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
	end
	GBox.OnValueChanged = function(pnl)
		if SkipUpdate or g == pnl:GetValue() then return end
		g = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b, a))
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
	end
	BBox.OnValueChanged = function(pnl)
		if SkipUpdate or b == pnl:GetValue() then return end
		b = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b, a))
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
	end
	ABox.OnValueChanged = function(pnl)
		if SkipUpdate or a == pnl:GetValue() then return end
		a = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b, a))
		RunConsoleCommand(Choices[CurrentColor][1], r .. "_" .. g .. "_" .. b .. "_" .. a)
	end

	-- Positioning
	local x, y = ColorMixer:GetPos()
	local w, _ = ColorMixer:GetSize()
	CurrentColorSelect:SetPos(x + w + 2, y)
	RBox:SetPos(x + w + 2, y + 2 + 20)
	GBox:SetPos(x + w + 2, y + 4 + RBox:GetTall() + 20)
	BBox:SetPos(x + w + 2, y + 6 + RBox:GetTall() * 2 + 20)
	ABox:SetPos(x + w + 2, y + 6 + RBox:GetTall() * 3 + 20)
	DefaultButton:SetPos(x + w + 2, y + 8 + RBox:GetTall() * 4 + 20)
	DefaultButton:SetSize(RBox:GetSize())

	--- - FONTS

	local FontLabel = vgui.Create("DLabel")
	dlist:AddItem(FontLabel)
	FontLabel:SetText("Font:                                   Font Size:")
	FontLabel:SizeToContents()
	FontLabel:SetPos(10, 0)

	local temp = vgui.Create("Panel")
	temp:SetTall(25)
	dlist:AddItem(temp)

	local FontSelect = vgui.Create("DComboBox", temp)
	-- dlist:AddItem( FontSelect )
	FontSelect.OnSelect = function(panel, index, value)
		if value == "Custom..." then
			Derma_StringRequestNoBlur("Enter custom font:", "", "", function(value)
				self:ChangeFont(value, self.FontSizeConVar:GetInt())
				RunConsoleCommand("wire_expression2_editor_font", value)
			end)
		else
			value = value:gsub(" %b()", "") -- Remove description
			self:ChangeFont(value, self.FontSizeConVar:GetInt())
			RunConsoleCommand("wire_expression2_editor_font", value)
		end
	end
	for k, v in pairs(self.Fonts) do
		FontSelect:AddChoice(k .. (v ~= "" and " (" .. v .. ")" or ""))
	end
	FontSelect:AddChoice("Custom...")
	FontSelect:SetSize(240 - 50 - 4, 20)

	local FontSizeSelect = vgui.Create("DComboBox", temp)
	FontSizeSelect.OnSelect = function(panel, index, value)
		value = value:gsub(" %b()", "")
		self:ChangeFont(self.FontConVar:GetString(), tonumber(value))
		RunConsoleCommand("wire_expression2_editor_font_size", value)
	end
	for i = 11, 26 do
		FontSizeSelect:AddChoice(i .. (i == 16 and " (Default)" or ""))
	end
	FontSizeSelect:SetPos(FontSelect:GetWide() + 4, 0)
	FontSizeSelect:SetSize(50, 20)


	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Auto completion options")
	label:SizeToContents()

	local AutoComplete = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(AutoComplete)
	AutoComplete:SetConVar("wire_expression2_autocomplete")
	AutoComplete:SetText("Auto Completion")
	AutoComplete:SizeToContents()
	AutoComplete:SetTooltip("Enable/disable auto completion in the E2 editor.")

	local AutoCompleteExtra = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(AutoCompleteExtra)
	AutoCompleteExtra:SetConVar("wire_expression2_autocomplete_moreinfo")
	AutoCompleteExtra:SetText("More Info (for AC)")
	AutoCompleteExtra:SizeToContents()
	AutoCompleteExtra:SetTooltip("Enable/disable additional information for auto completion.")

	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Auto completion control style")
	label:SizeToContents()

	local AutoCompleteControlOptions = vgui.Create("DComboBox")
	dlist:AddItem(AutoCompleteControlOptions)

	local modes = {}
	modes["Default"] = { 0, "Current mode:\nTab/CTRL+Tab to choose item;\nEnter/Space to use;\nArrow keys to abort." }
	modes["Visual C# Style"] = { 1, "Current mode:\nCtrl+Space to use the top match;\nArrow keys to choose item;\nTab/Enter/Space to use;\nCode validation hotkey (ctrl+space) moved to ctrl+b." }
	modes["Scroller"] = { 2, "Current mode:\nMouse scroller to choose item;\nMiddle mouse to use." }
	modes["Scroller w/ Enter"] = { 3, "Current mode:\nMouse scroller to choose item;\nEnter to use." }
	modes["Eclipse Style"] = { 4, "Current mode:\nEnter to use top match;\nTab to enter auto completion menu;\nArrow keys to choose item;\nEnter to use;\nSpace to abort." }
	-- modes["Qt Creator Style"]			= { 6, "Current mode:\nCtrl+Space to enter auto completion menu;\nSpace to abort; Enter to use top match." } <-- probably wrong. I'll check about adding Qt style later.

	for k, v in pairs(modes) do
		AutoCompleteControlOptions:AddChoice(k)
	end

	modes[0] = modes["Default"][2]
	modes[1] = modes["Visual C# Style"][2]
	modes[2] = modes["Scroller"][2]
	modes[3] = modes["Scroller w/ Enter"][2]
	modes[4] = modes["Eclipse Style"][2]
	AutoCompleteControlOptions:SetToolTip(modes[GetConVar("wire_expression2_autocomplete_controlstyle"):GetInt()])


	AutoCompleteControlOptions.OnSelect = function(panel, index, value)
		panel:SetToolTip(modes[value][2])
		RunConsoleCommand("wire_expression2_autocomplete_controlstyle", modes[value][1])
	end

	local HighightOnUse = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(HighightOnUse)
	HighightOnUse:SetConVar("wire_expression2_autocomplete_highlight_after_use")
	HighightOnUse:SetText("Highlight word after AC use.")
	HighightOnUse:SizeToContents()
	HighightOnUse:SetTooltip("Enable/Disable highlighting of the entire word after using auto completion.\nIn E2, this is only for variables/constants, not functions.")

	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Other options")
	label:SizeToContents()

	local NewTabOnOpen = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(NewTabOnOpen)
	NewTabOnOpen:SetConVar("wire_expression2_new_tab_on_open")
	NewTabOnOpen:SetText("New tab on open")
	NewTabOnOpen:SizeToContents()
	NewTabOnOpen:SetTooltip("Enable/disable loaded files opening in a new tab.\nIf disabled, loaded files will be opened in the current tab.")

	local SaveTabsOnClose = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(SaveTabsOnClose)
	SaveTabsOnClose:SetConVar("wire_expression2_editor_savetabs")
	SaveTabsOnClose:SetText("Save tabs on close")
	SaveTabsOnClose:SizeToContents()
	SaveTabsOnClose:SetTooltip("Save the currently opened tab file paths on shutdown.\nOnly saves tabs whose files are saved.")

	local OpenOldTabs = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(OpenOldTabs)
	OpenOldTabs:SetConVar("wire_expression2_editor_openoldtabs")
	OpenOldTabs:SetText("Open old tabs on load")
	OpenOldTabs:SizeToContents()
	OpenOldTabs:SetTooltip("Open the tabs from the last session on load.\nOnly tabs whose files were saved before disconnecting from the server are stored.")

	local DisplayCaretPos = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(DisplayCaretPos)
	DisplayCaretPos:SetConVar("wire_expression2_editor_display_caret_pos")
	DisplayCaretPos:SetText("Show Caret Position")
	DisplayCaretPos:SizeToContents()
	DisplayCaretPos:SetTooltip("Shows the position of the caret.")

	local HighlightOnDoubleClick = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(HighlightOnDoubleClick)
	HighlightOnDoubleClick:SetConVar("wire_expression2_editor_highlight_on_double_click")
	HighlightOnDoubleClick:SetText("Highlight copies of selected word")
	HighlightOnDoubleClick:SizeToContents()
	HighlightOnDoubleClick:SetTooltip("Find all identical words and highlight them after a double-click.")

	-- Browser width
	local BrowserWidthSlider = vgui.Create("DNumSlider")
	dlist:AddItem(BrowserWidthSlider)
	BrowserWidthSlider:SetText("Browser Width")
	BrowserWidthSlider:SetMinMax(150, 325)
	BrowserWidthSlider:SetDecimals(0)
	BrowserWidthSlider:SetDark(false)
	BrowserWidthSlider:SetConVar("wire_expression2_editor_browserwidth")
	local btoggle = self.C['Btoggle'].panel
	function BrowserWidthSlider.OnValueChanged(pnl, bw)
		if bw == wire_expression2_editor_browserwidth:GetInt() then return end
		btoggle.hide = self.C['Browser'].w > bw
		btoggle.toggle = true
		timer.Create("Expression2_ChangeBrowserWidth", 0, 30, function()
			if btoggle.hide and self.C['Browser'].w < (bw + 10) then
				btoggle.hide = false
				timer.Remove("Expression2_ChangeBrowserWidth")
			end
		end)
	end

	local WorldClicker = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(WorldClicker)
	WorldClicker:SetConVar("wire_expression2_editor_worldclicker")
	WorldClicker:SetText("Enable Clicking Outside Editor")
	WorldClicker:SizeToContents()
	function WorldClicker.OnChange(pnl, bVal)
		self:GetParent():SetWorldClicker(bVal)
	end

	--------------------------------------------- EXPRESSION 2 TAB
	local sheet = self:AddControlPanelTab("Expression 2", "icon16/computer.png", "Options for Expression 2.")

	local dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 2, 2)
	dlist:EnableVerticalScrollbar(true)

	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Clientside expression 2 options")
	label:SizeToContents()

	local AutoIndent = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(AutoIndent)
	AutoIndent:SetConVar("wire_expression2_autoindent")
	AutoIndent:SetText("Auto indenting")
	AutoIndent:SizeToContents()
	AutoIndent:SetTooltip("Enable/disable auto indenting.")

	local Concmd = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(Concmd)
	Concmd:SetConVar("wire_expression2_concmd")
	Concmd:SetText("concmd")
	Concmd:SizeToContents()
	Concmd:SetTooltip("Allow/disallow the E2 from running console commands on you.")

	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Concmd whitelist")
	label:SizeToContents()

	local ConcmdWhitelist = vgui.Create("DTextEntry")
	dlist:AddItem(ConcmdWhitelist)
	ConcmdWhitelist:SetConVar("wire_expression2_concmd_whitelist")
	ConcmdWhitelist:SetToolTip("Separate the commands with commas.")

	local FriendWrite = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(FriendWrite)
	FriendWrite:SetConVar("wire_expression2_friendwrite")
	FriendWrite:SetText("Friend Write")
	FriendWrite:SizeToContents()
	FriendWrite:SetTooltip("Allow/disallow people in your prop protection friends list from reading and writing to your E2s.")

	local label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Expression 2 block comment style")
	label:SizeToContents()

	local BlockCommentStyle = vgui.Create("DComboBox")
	dlist:AddItem(BlockCommentStyle)

	local modes = {}
	modes["New (alt 1)"] = {
		0, [[Current mode:
#[
Text here
Text here
]#]]
	}
	modes["New (alt 2)"] = {
		1, [[Current mode:
#[Text here
Text here]# ]]
	}
	modes["Old"] = {
		2, [[Current mode:
#Text here
#Text here]]
	}

	for k, v in pairs(modes) do
		BlockCommentStyle:AddChoice(k)
	end

	modes[0] = modes["New (alt 1)"][2]
	modes[1] = modes["New (alt 2)"][2]
	modes[2] = modes["Old"][2]
	BlockCommentStyle:SetToolTip(modes[self.BlockCommentStyleConVar:GetInt()])

	BlockCommentStyle.OnSelect = function(panel, index, value)
		panel:SetToolTip(modes[value][2])
		RunConsoleCommand("wire_expression2_editor_block_comment_style", modes[value][1])
	end

	-- SYNTAX HIGHLIGHT COLORS

	local Label = vgui.Create("DLabel")
	dlist:AddItem(Label)
	Label:SetText("Expression 2 syntax highlighting colors")
	Label:SizeToContents()

	local SkipUpdate = false
	local CurrentColor = "directive"
	local r, g, b = 255, 255, 255

	local temp = vgui.Create("Panel")
	dlist:AddItem(temp)
	temp:SetTall(132)

	-- Create color mixer, number wangs, default button, and drop down menu
	local ColorMixer = vgui.Create("DColorMixer", temp)
	local RBox = vgui.Create("DNumberWang", temp)
	local GBox = vgui.Create("DNumberWang", temp)
	local BBox = vgui.Create("DNumberWang", temp)
	local DefaultButton = vgui.Create("DButton", temp)
	local CurrentColorSelect = vgui.Create("DComboBox", temp)

	-- Add choices
	for k, v in pairs(colors) do
		CurrentColorSelect:AddChoice(k)
	end
	-- Manage choices
	CurrentColorSelect.OnSelect = function(panel, index, value)
		CurrentColor = value
		ColorMixer:SetColor(colors[value])
		r = colors[value].r
		g = colors[value].g
		b = colors[value].b
		RBox:SetValue(r)
		GBox:SetValue(g)
		BBox:SetValue(b)
	end

	-- Default button
	DefaultButton.DoClick = function(pnl)
		ColorMixer:SetColor(colors_defaults[CurrentColor])
		r = colors_defaults[CurrentColor].r
		g = colors_defaults[CurrentColor].g
		b = colors_defaults[CurrentColor].b
		RBox:SetValue(r)
		GBox:SetValue(g)
		BBox:SetValue(b)
		self:SetSyntaxColor(CurrentColor, colors_defaults[CurrentColor])
	end

	DefaultButton:SetText("Default")

	ColorMixer:SetSize(130, 130)
	-- ColorMixer:SetPos( 170, 205 )

	-- Remove alpha bar
	ColorMixer.Alpha:SetVisible(false)
	ColorMixer.PerformLayout = function(pnl)
		local w, h = pnl:GetSize()
		pnl.RGB:SetPos(0, 0)
		pnl.RGB:SetSize(20, h)
		pnl.Palette:SetPos(22, 0)
		pnl.Palette:SetSize(w - 22, h)
	end

	local old = ColorMixer.Palette.OnMouseReleased
	ColorMixer.Palette.OnMouseReleased = function(...)
		local clr = ColorMixer:GetColor()
		r, g, b = clr.r, clr.g, clr.b
		SkipUpdate = true
		RBox:SetValue(r)
		GBox:SetValue(g)
		BBox:SetValue(b)
		SkipUpdate = false
		self:SetSyntaxColor(CurrentColor, clr)
		old(...)
	end

	-- Loop this to make it a little neater
	local temp = { RBox, GBox, BBox }
	for k, v in pairs(temp) do
		v:SetValue(255)
		v:SetMin(0)
		v:SetMax(255)
		v:SetDecimals(0)
		v:SetWide(64)
		local old = v:GetTextArea().OnEnter
		v:GetTextArea().OnEnter = function(...)
			v:OnValueChanged()
			old(...)
		end
	end

	-- OnValueChanged functions
	RBox.OnValueChanged = function(pnl)
		if SkipUpdate or r == pnl:GetValue() then return end
		r = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b))
		self:SetSyntaxColor(CurrentColor, Color(r, g, b))
	end
	GBox.OnValueChanged = function(pnl)
		if SkipUpdate or g == pnl:GetValue() then return end
		g = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b))
		self:SetSyntaxColor(CurrentColor, Color(r, g, b))
	end
	BBox.OnValueChanged = function(pnl)
		if SkipUpdate or b == pnl:GetValue() then return end
		b = pnl:GetValue()
		ColorMixer:SetColor(Color(r, g, b))
		self:SetSyntaxColor(CurrentColor, Color(r, g, b))
	end

	-- Positioning
	local x, y = ColorMixer:GetPos()
	local w, _ = ColorMixer:GetSize()
	CurrentColorSelect:SetPos(x + w + 2, y)
	RBox:SetPos(x + w + 2, y + 2 + 20)
	GBox:SetPos(x + w + 2, y + 4 + RBox:GetTall() + 20)
	BBox:SetPos(x + w + 2, y + 6 + RBox:GetTall() * 2 + 20)
	DefaultButton:SetPos(x + w + 2, y + 8 + RBox:GetTall() * 3 + 20)
	DefaultButton:SetSize(RBox:GetSize())


	-- ------------------------------------------- REMOTE UPDATER TAB
	local sheet = self:AddControlPanelTab("Remote Updater", "icon16/world.png", "Update your Expressions/GPUs/CPUs from far away.\nNote: Does not work for CPU/GPU yet.")

	local dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 2, 2)
	dlist:EnableVerticalScrollbar(true)
	dlist:SetSpacing(2)

	local dlist2 = vgui.Create("DPanelList")
	dlist:AddItem(dlist2)
	dlist2:EnableVerticalScrollbar(true)
	-- frame:AddResizeObject( dlist2, 2,2 )
	-- dlist2:SetTall( 444 )
	dlist2:SetSpacing(1)
	dlist2.Paint = function() end

	local UpdateList = vgui.Create("DButton")
	UpdateList:SetText("")
	dlist:AddItem(UpdateList)
	UpdateList.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
		surface.SetFont("E2SmallFont")
		surface.SetTextPos(w / 2 - surface.GetTextSize("Update List (Show only yours)") / 2, 6)
		surface.SetTextColor(255, 255, 255, 255)
		surface.DrawText("Update List (Show only yours)")
	end
	UpdateList.DoClick = function(pnl, showall)
		local E2s = ents.FindByClass("gmod_wire_expression2")
		dlist2:Clear()
		local size = 0
		for k, v in pairs(E2s) do
			local ply = v:GetNWEntity("_player", false)
			if ply and ply == LocalPlayer() or showall then
				local nick
				if not ply or not ply:IsValid() then nick = "Unknown" else nick = ply:Nick() end
				local name = v:GetNWString("name", "generic")
				local panel = vgui.Create("DPanel")
				panel:SetTall(46)
				panel.Paint = function(panel)
					local w, h = panel:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, Color(65, 105, 255, 100))
				end
				dlist2:AddItem(panel)
				size = size + panel:GetTall() + 1

				local label = vgui.Create("DLabel", panel)
				label:SetText("Name: " .. name .. "\nEntity ID: '" .. v:EntIndex() .. "'" .. (showall and "\nOwner: " .. nick or ""))
				label:SizeToContents()
				label:SetWrap(true)
				label:SetPos(4, 4)
				label:SetTextColor(Color(255, 255, 255, 255))

				local btn = vgui.Create("DButton", panel)
				btn:SetText("")
				btn:SetSize(57, 18)
				timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() * 2 - 6, 4) end)
				btn.DoClick = function(pnl)
					WireLib.Expression2Upload(v)
				end
				btn.Paint = function(button)
					local w, h = button:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
					if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
					surface.SetFont("E2SmallFont")
					surface.SetTextPos(3, 4)
					surface.SetTextColor(255, 255, 255, 255)
					surface.DrawText("    Upload")
				end

				local btn = vgui.Create("DButton", panel)
				btn:SetText("")
				btn:SetSize(57, 18)
				timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() - 4, 4) end)
				btn.DoClick = function(pnl)
					RunConsoleCommand("wire_expression_requestcode", v:EntIndex())
				end
				btn.Paint = function(button)
					local w, h = button:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
					if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
					surface.SetFont("E2SmallFont")
					surface.SetTextPos(3, 4)
					surface.SetTextColor(255, 255, 255, 255)
					surface.DrawText("  Download")
				end

				local btn = vgui.Create("DButton", panel)
				btn:SetText("")
				btn:SetSize(75, 18)
				timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() - 4, 24) end)
				btn.DoClick = function(pnl)
					RunConsoleCommand("wire_expression_forcehalt", v:EntIndex())
				end
				btn.Paint = function(button)
					local w, h = button:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
					if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
					surface.SetFont("E2SmallFont")
					surface.SetTextPos(3, 4)
					surface.SetTextColor(255, 255, 255, 255)
					surface.DrawText("  Halt execution")
				end

				local btn2 = vgui.Create("DButton", panel)
				btn2:SetText("")
				btn2:SetSize(39, 18)
				timer.Simple(0, function() btn2:SetPos(panel:GetWide() - btn2:GetWide() - btn:GetWide() - 6, 24) end)
				btn2.DoClick = function(pnl)
					RunConsoleCommand("wire_expression_reset", v:EntIndex())
				end
				btn2.Paint = function(button)
					local w, h = button:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
					if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
					surface.SetFont("E2SmallFont")
					surface.SetTextPos(3, 4)
					surface.SetTextColor(255, 255, 255, 255)
					surface.DrawText("  Reset")
				end
			end
		end
		dlist2:SetTall(size + 2)
		dlist:InvalidateLayout()
	end
	local UpdateList2 = vgui.Create("DButton")
	UpdateList2:SetText("")
	dlist:AddItem(UpdateList2)
	UpdateList2.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
		surface.SetFont("E2SmallFont")
		surface.SetTextPos(w / 2 - surface.GetTextSize("Update List (Show all)") / 2, 6)
		surface.SetTextColor(255, 255, 255, 255)
		surface.DrawText("Update List (Show all)")
	end
	UpdateList2.DoClick = function(pnl) UpdateList:DoClick(true) end
end

function Editor:CalculateColor()
	self.colors.col_FL.r = math.floor(self.colors.tmp_FL.r * self.colors.tmp_Dark / 255)
	self.colors.col_FL.g = math.floor(self.colors.tmp_FL.g * self.colors.tmp_Dark / 255)
	self.colors.col_FL.b = math.floor(self.colors.tmp_FL.b * self.colors.tmp_Dark / 255)

	self.colors.col_FR.r = math.floor(self.colors.tmp_FR.r * self.colors.tmp_Dark / 255)
	self.colors.col_FR.g = math.floor(self.colors.tmp_FR.g * self.colors.tmp_Dark / 255)
	self.colors.col_FR.b = math.floor(self.colors.tmp_FR.b * self.colors.tmp_Dark / 255)

	self:InvalidateLayout()
end

-- used with color-circles
function Editor:TranslateValues(panel, x, y)
	x = x - 0.5
	y = y - 0.5
	local angle = math.atan2(x, y)
	local length = math.sqrt(x * x + y * y)
	length = math.Clamp(length, 0, 0.5)
	x = 0.5 + math.sin(angle) * length
	y = 0.5 + math.cos(angle) * length
	panel:SetHue(math.deg(angle) + 270)
	panel:SetSaturation(length * 2)
	panel:SetRGB(HSVToColor(panel:GetHue(), panel:GetSaturation(), 1))
	panel:SetFrameColor()
	return x, y
end

-- options

-- code1 contains the code that is not to be marked
local code1 = "@name \n@inputs \n@outputs \n@persist \n@trigger \n\n"
-- code2 contains the code that is to be marked, so it can simply be overwritten or deleted.
local code2 = [[#[
    Scopes have been added. If you find any bugs,
    please report them on the forums.

    An option to copy with bbcode color syntax
    highlighting has been added (for use on forums).
    Right click anywhere in the editor to use it.

    Documentation and examples are available at:
    http://wiki.wiremod.com/wiki/Expression_2
    The community is available at http://www.wiremod.com
]#]]
local defaultcode = code1 .. code2 .. "\n"

function Editor:NewScript(incurrent)
	if not incurrent and self.NewTabOnOpen:GetBool() then
		self:NewTab()
	else
		self:AutoSave()
		self:ChosenFile()

		-- Set title
		self:GetActiveTab():SetText("generic")
		self.C['TabHolder'].panel:InvalidateLayout()

		if self.E2 then
			-- add both code1 and code2 to the editor
			self:SetCode(defaultcode)
			local ed = self:GetCurrentEditor()
			-- mark only code2
			ed.Start = ed:MovePosition({ 1, 1 }, code1:len())
			ed.Caret = ed:MovePosition({ 1, 1 }, defaultcode:len())
		else
			self:SetCode("")
		end
	end
end

local wire_expression2_editor_savetabs = CreateClientConVar("wire_expression2_editor_savetabs", "1", true, false)

local id = 0
function Editor:InitShutdownHook()
	id = id + 1

	-- save code when shutting down
	hook.Add("ShutDown", "wire_expression2_ShutDown" .. id, function()
	-- if wire_expression2_editor == nil then return end
		local buffer = self:GetCode()
		if buffer == defaultcode then return end
		file.Write(self.Location .. "/_shutdown_.txt", buffer)

		if wire_expression2_editor_savetabs:GetBool() then
			self:SaveTabs()
		end
	end)
end

function Editor:SaveTabs()
	local strtabs = ""
	local tabs = {}
	for i=1, self:GetNumTabs() do
		local chosenfile = self:GetEditor(i).chosenfile
		if chosenfile and chosenfile ~= "" and not tabs[chosenfile] then
			strtabs = strtabs .. chosenfile .. ";"
			tabs[chosenfile] = true -- Prevent duplicates
		end
	end

	strtabs = strtabs:sub(1, -2)

	file.Write(self.Location .. "/_tabs_.txt", strtabs)
end

local wire_expression2_editor_openoldtabs = CreateClientConVar("wire_expression2_editor_openoldtabs", "1", true, false)

function Editor:OpenOldTabs()
	if not file.Exists(self.Location .. "/_tabs_.txt", "DATA") then return end

	-- Read file
	local tabs = file.Read(self.Location .. "/_tabs_.txt")
	if not tabs or tabs == "" then return end

	-- Explode around ;
	tabs = string.Explode(";", tabs)
	if not tabs or #tabs == 0 then return end

	-- Temporarily remove fade time
	self:FixTabFadeTime()

	local is_first = true
	for k, v in pairs(tabs) do
		if v and v ~= "" then
			if (file.Exists(v, "DATA")) then
				-- Open it in a new tab
				self:LoadFile(v, true)

				-- If this is the first loop, close the initial tab.
				if (is_first) then
					timer.Simple(0, function()
						self:CloseTab(1)
					end)
					is_first = false
				end
			end
		end
	end
end

function Editor:Validate(gotoerror)
	if self.EditorType == "E2" then
		local errors = wire_expression2_validate(self:GetCode())
		if not errors then
			self.C['Val'].panel:SetBGColor(0, 128, 0, 180)
			self.C['Val'].panel:SetText("   Validation successful")
			return true
		end
		if gotoerror then
			local row, col = errors:match("at line ([0-9]+), char ([0-9]+)$")
			if not row then
				row, col = errors:match("at line ([0-9]+)$"), 1
			end
			if row then self:GetCurrentEditor():SetCaret({ tonumber(row), tonumber(col) }) end
		end
		self.C['Val'].panel:SetBGColor(128, 0, 0, 180)
		self.C['Val'].panel:SetText("   " .. errors)
	elseif self.EditorType == "CPU" or self.EditorType == "GPU" or self.EditorType == "SPU" then
		self.C['Val'].panel:SetBGColor(64, 64, 64, 180)
		self.C['Val'].panel:SetText("   Recompiling...")
		CPULib.Validate(self, self:GetCode(), self:GetChosenFile())
	end
	return true
end

function Editor:SetValidatorStatus(text, r, g, b, a)
	self.C['Val'].panel:SetBGColor(r or 0, g or 180, b or 0, a or 180)
	self.C['Val'].panel:SetText("   " .. text)
end

function Editor:SubTitle(sub)
	if not sub then self.subTitle = ""
	else self.subTitle = " - " .. sub
	end
end

local wire_expression2_editor_worldclicker = CreateClientConVar("wire_expression2_editor_worldclicker", "0", true, false)
function Editor:SetV(bool)
	if bool then
		self:MakePopup()
		self:InvalidateLayout(true)
		if self.E2 then self:Validate() end
	end
	self:SetVisible(bool)
	self:SetKeyBoardInputEnabled(bool)
	self:GetParent():SetWorldClicker(wire_expression2_editor_worldclicker:GetBool() and bool) -- Enable this on the background so we can update E2's without closing the editor
	if CanRunConsoleCommand() then
		RunConsoleCommand("wire_expression2_event", bool and "editor_open" or "editor_close")
		if not e2_function_data_received and bool then -- Request the E2 functions
			RunConsoleCommand("wire_expression2_sendfunctions")
		end
	end
end

function Editor:GetChosenFile()
	return self:GetCurrentEditor().chosenfile
end

function Editor:ChosenFile(Line)
	self:GetCurrentEditor().chosenfile = Line
	if Line then
		self:SubTitle("Editing: " .. Line)
	else
		self:SubTitle()
	end
end

function Editor:FindOpenFile(FilePath)
	for i = 1, self:GetNumTabs() do
		local ed = self:GetEditor(i)
		if ed.chosenfile == FilePath then
			return ed
		end
	end
end

function Editor:ExtractName()
	if not self.E2 then self.savefilefn = "filename" return end
	local code = self:GetCode()
	local name = extractNameFromCode(code)
	if name and name ~= "" then
		Expression2SetName(name)
		self.savefilefn = name
	else
		Expression2SetName(nil)
		self.savefilefn = "filename"
	end
end

function Editor:SetCode(code)
	self:GetCurrentEditor():SetText(code)
	self.savebuffer = self:GetCode()
	if self.E2 then self:Validate() end
	self:ExtractName()
end

function Editor:GetEditor(n)
	if self.C['TabHolder'].panel.Items[n] then
		return self.C['TabHolder'].panel.Items[n].Panel
	end
end

function Editor:GetCurrentEditor()
	return self:GetActiveTab():GetPanel()
end

function Editor:GetCode()
	return self:GetCurrentEditor():GetValue()
end

function Editor:Open(Line, code, forcenewtab)
	if self:IsVisible() and not Line and not code then self:Close() end
	self:SetV(true)
	if code then
		if not forcenewtab then
			for i = 1, self:GetNumTabs() do
				if self:GetEditor(i).chosenfile == Line then
					self:SetActiveTab(i)
					self:SetCode(code)
					return
				elseif self:GetEditor(i):GetValue() == code then
					self:SetActiveTab(i)
					return
				end
			end
		end
		local title, tabtext = getPreferredTitles(Line, code)
		local tab
		if self.NewTabOnOpen:GetBool() or forcenewtab then
			tab = self:CreateTab(tabtext).Tab
		else
			tab = self:GetActiveTab()
			tab:SetText(tabtext)
			self.C['TabHolder'].panel:InvalidateLayout()
		end
		self:SetActiveTab(tab)

		self:ChosenFile()
		self:SetCode(code)
		if Line then self:SubTitle("Editing: " .. Line) end
		return
	end
	if Line then self:LoadFile(Line, forcenewtab) return end
end

function Editor:SaveFile(Line, close, SaveAs)
	self:ExtractName()
	if close and self.chip then
		if not self:Validate(true) then return end
		WireLib.Expression2Upload(self.chip, self:GetCode())
		self:Close()
		return
	end
	if not Line or SaveAs or Line == self.Location .. "/" .. ".txt" then
		local str
		if self.C['Browser'].panel.File then
			str = self.C['Browser'].panel.File.FileDir -- Get FileDir
			if str and str ~= "" then -- Check if not nil

				-- Remove "expression2/" or "cpuchip/" etc
				local n, _ = str:find("/", 1, true)
				str = str:sub(n + 1, -1)

				if str and str ~= "" then -- Check if not nil
					if str:Right(4) == ".txt" then -- If it's a file
						str = string.GetPathFromFilename(str):Left(-2) -- Get the file path instead
						if not str or str == "" then
							str = nil
						end
					end
				else
					str = nil
				end
			else
				str = nil
			end
		end
		Derma_StringRequestNoBlur("Save to New File", "", (str ~= nil and str .. "/" or "") .. self.savefilefn,
			function(strTextOut)
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
				self:SaveFile(self.Location .. "/" .. strTextOut .. ".txt", close)
			end)
		return
	end

	file.Write(Line, self:GetCode())

	local panel = self.C['Val'].panel
	timer.Simple(0, function() panel.SetText(panel, "   Saved as " .. Line) end)
	surface.PlaySound("ambient/water/drip3.wav")

	if not self.chip then self:ChosenFile(Line) end
	if close then
		if self.E2 then
			GAMEMODE:AddNotify("Expression saved as " .. Line .. ".", NOTIFY_GENERIC, 7)
		else
			GAMEMODE:AddNotify("Source code saved as " .. Line .. ".", NOTIFY_GENERIC, 7)
		end
		self:Close()
	end
end

function Editor:LoadFile(Line, forcenewtab)
	if not Line or file.IsDir(Line, "DATA") then return end

	local f = file.Open(Line, "r", "DATA")
	if not f then 
		ErrorNoHalt("Erroring opening file: " .. Line)
	else
		local str = f:Read(f:Size())
		f:Close()
		self:AutoSave()
		if not forcenewtab then
			for i = 1, self:GetNumTabs() do
				if self:GetEditor(i).chosenfile == Line then
					self:SetActiveTab(i)
					if forcenewtab ~= nil then self:SetCode(str) end
					return
				elseif self:GetEditor(i):GetValue() == str then
					self:SetActiveTab(i)
					return
				end
			end
		end
		if not self.chip then
			local title, tabtext = getPreferredTitles(Line, str)
			local tab
			if self.NewTabOnOpen:GetBool() or forcenewtab then
				tab = self:CreateTab(tabtext).Tab
			else
				tab = self:GetActiveTab()
				tab:SetText(tabtext)
				self.C['TabHolder'].panel:InvalidateLayout()
			end
			self:SetActiveTab(tab)
			self:ChosenFile(Line)
		end
		self:SetCode(str)
	end
end

function Editor:Close()
	timer.Stop("e2autosave")
	self:AutoSave()

	self:Validate()
	self:ExtractName()
	self:SetV(false)
	self.chip = false

	self:SaveEditorSettings()
end

function Editor:Setup(nTitle, nLocation, nEditorType)
	self.Title = nTitle
	self.Location = nLocation
	self.EditorType = nEditorType
	self.C['Browser'].panel:Setup(nLocation)
	if not nEditorType then
		-- Remove syntax highlighting
		local func = function(self, row) return { { self.Rows[row], { Color(255, 255, 255, 255), false } } } end
		self:SetSyntaxColorLine(func)

		-- Remove validation line
		self.C['TabHolder'].h = -10
		self.C['Val'].panel:SetVisible(false)
	elseif nEditorType == "CPU" or nEditorType == "GPU" or nEditorType == "SPU" then
		-- Set syntax highlighting
		local func = self:GetCurrentEditor().CPUGPUSyntaxColorLine
		self:SetSyntaxColorLine(func)

		-- Add "E2Helper" button
		local E2Help = self:addComponent(vgui.Create("Button", self), -180, 30, -125, 20)
		E2Help.panel:SetText("")
		E2Help.panel.Font = "E2SmallFont"
		E2Help.panel.Paint = function(button)
			local w, h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos(3, 4)
			surface.SetTextColor(255, 255, 255, 255)
			surface.DrawText("  E2Helper")
		end
		E2Help.panel.DoClick = function()
			E2Helper.Show()
			E2Helper.UseCPU(nEditorType)
			E2Helper.Update()
		end
		self.C.E2Help = E2Help

		if nEditorType == "SPU" then
			-- Add "Sound Browser" button
			local SoundBrw = self:addComponent(vgui.Create("Button", self), -262, 30, -182, 20)
			SoundBrw.panel:SetText("")
			SoundBrw.panel.Font = "E2SmallFont"
			SoundBrw.panel.Paint = function(button)
				local w, h = button:GetSize()
				draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
				if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
				surface.SetFont(button.Font)
				surface.SetTextPos(3, 4)
				surface.SetTextColor(255, 255, 255, 255)
				surface.DrawText("  Sound Browser")
			end
			SoundBrw.panel.DoClick = function() RunConsoleCommand("wire_sound_browser_open") end
			self.C.SoundBrw = SoundBrw
		end

		if nEditorType == "CPU" then
			-- Add "step forward" button
			local DebugForward = self:addComponent(vgui.Create("Button", self), -300, 30, -220, 20)
			DebugForward.panel:SetText("")
			DebugForward.panel.Font = "E2SmallFont"
			DebugForward.panel.Paint = function(button)
				if not CPULib.DebuggerAttached then return end
				local w, h = button:GetSize()
				draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
				if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
				surface.SetFont(button.Font)
				surface.SetTextPos(3, 4)
				surface.SetTextColor(255, 255, 255, 255)
				surface.DrawText("  Step Forward")
			end
			DebugForward.panel.DoClick = function()
				local currentPosition = CPULib.Debugger.PositionByPointer[CPULib.Debugger.Variables.IP]
				if currentPosition then
					local linePointers = CPULib.Debugger.PointersByLine[currentPosition.Line .. ":" .. currentPosition.File]
					if linePointers then -- Run till end of line
						RunConsoleCommand("wire_cpulib_debugstep", linePointers[2])
					else -- Run just once
						RunConsoleCommand("wire_cpulib_debugstep")
					end
				else -- Run just once
					RunConsoleCommand("wire_cpulib_debugstep")
				end
				-- Reset interrupt text
				CPULib.InterruptText = nil
			end
			self.C.DebugForward = DebugForward

			-- Add "reset" button
			local DebugReset = self:addComponent(vgui.Create("Button", self), -350, 30, -310, 20)
			DebugReset.panel:SetText("")
			DebugReset.panel.Font = "E2SmallFont"
			DebugReset.panel.Paint = function(button)
				if not CPULib.DebuggerAttached then return end
				local w, h = button:GetSize()
				draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
				if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
				surface.SetFont(button.Font)
				surface.SetTextPos(3, 4)
				surface.SetTextColor(255, 255, 255, 255)
				surface.DrawText("  Reset")
			end
			DebugReset.panel.DoClick = function()
				RunConsoleCommand("wire_cpulib_debugreset")
				-- Reset interrupt text
				CPULib.InterruptText = nil
			end
			self.C.DebugReset = DebugReset

			-- Add "run" button
			local DebugRun = self:addComponent(vgui.Create("Button", self), -395, 30, -360, 20)
			DebugRun.panel:SetText("")
			DebugRun.panel.Font = "E2SmallFont"
			DebugRun.panel.Paint = function(button)
				if not CPULib.DebuggerAttached then return end
				local w, h = button:GetSize()
				draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
				if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
				surface.SetFont(button.Font)
				surface.SetTextPos(3, 4)
				surface.SetTextColor(255, 255, 255, 255)
				surface.DrawText("  Run")
			end
			DebugRun.panel.DoClick = function()
				RunConsoleCommand("wire_cpulib_debugrun")
			end
			self.C.DebugRun = DebugRun
		end

		-- insert default code
		self:SetCode("")
	elseif nEditorType == "E2" then
		-- Add "E2Helper" button
		local E2Help = self:addComponent(vgui.Create("Button", self), -180, 30, -125, 20)
		E2Help.panel:SetText("")
		E2Help.panel.Font = "E2SmallFont"
		E2Help.panel.Paint = function(button)
			local w, h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos(3, 4)
			surface.SetTextColor(255, 255, 255, 255)
			surface.DrawText("  E2Helper")
		end
		E2Help.panel.DoClick = function()
			E2Helper.Show()
			E2Helper.UseE2(nEditorType)
			E2Helper.Update()
		end
		self.C.E2Help = E2Help

		-- Add "Sound Browser" button
		local SoundBrw = self:addComponent(vgui.Create("Button", self), -262, 30, -182, 20)
		SoundBrw.panel:SetText("")
		SoundBrw.panel.Font = "E2SmallFont"
		SoundBrw.panel.Paint = function(button)
			local w, h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos(3, 4)
			surface.SetTextColor(255, 255, 255, 255)
			surface.DrawText("  Sound Browser")
		end
		SoundBrw.panel.DoClick = function() RunConsoleCommand("wire_sound_browser_open") end
		self.C.SoundBrw = SoundBrw

		-- Flag as E2
		self.E2 = true
		self:NewScript(true)
	end
	if (wire_expression2_editor_openoldtabs:GetBool()) then
		self:OpenOldTabs()
	end
	self:InvalidateLayout()
end


vgui.Register("Expression2EditorFrame", Editor, "DFrame")