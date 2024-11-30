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
Editor.FontAntialiasingConvar = CreateClientConVar("wire_expression2_editor_font_antialiasing", 0, true, false)
Editor.BlockCommentStyleConVar = CreateClientConVar("wire_expression2_editor_block_comment_style", 1, true, false)
Editor.NewTabOnOpen = CreateClientConVar("wire_expression2_new_tab_on_open", "1", true, false)
Editor.ops_sync_subscribe = CreateClientConVar("wire_expression_ops_sync_subscribe",0,true,false)
Editor.ScrollToWarning = CreateClientConVar("wire_expression2_editor_show_warning_on_validate", 1, true, false)

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
	font = "Tahoma",
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
	local antialias = self.FontAntialiasingConvar:GetBool()
	local antialias_suffix = antialias and "_AA" or ""

	-- If font is not already created, create it.
	if not self.CreatedFonts[FontName .. "_" .. Size .. antialias_suffix] then
		local fontTable =
		{
			font = FontName,
			size = Size,
			weight = 400,
			antialias = antialias,
			additive = false,
		}
		surface.CreateFont("Expression2_" .. FontName .. "_" .. Size .. antialias_suffix, fontTable)
		fontTable.weight = 700
		surface.CreateFont("Expression2_" .. FontName .. "_" .. Size .. "_Bold"  .. antialias_suffix, fontTable)
		self.CreatedFonts[FontName .. "_" .. Size .. antialias_suffix] = true
	end

	self.CurrentFont = "Expression2_" .. FontName .. "_" .. Size  .. antialias_suffix
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
	["ppcommandargs"] = Color(128, 128, 128), -- same as comment
	["typename"] = Color(240, 160, 96), -- orange
	["constant"] = Color(240, 160, 240), -- pink
	["userfunction"] = Color(102, 122, 102), -- dark grayish-green
	["eventname"] = Color(74, 194, 116), -- green
	["dblclickhighlight"] = Color(0, 100, 0), -- dark green
	["background"] = Color(32, 32, 32) -- dark-grey
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
	-- don't use any of the default DFrame UI components
	for _, v in pairs(self:GetChildren()) do v:Remove()	end
	self.Title = ""
	self.subTitle = ""
	self.LastClick = 0
	self.GuiClick = 0
	self.SimpleGUI = false
	self.Location = ""

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

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:SetV(false)

	self:InitShutdownHook()
end

local size = CreateClientConVar("wire_expression2_editor_size", "800_600", true, false)
local pos = CreateClientConVar("wire_expression2_editor_pos", "-1_-1", true, false)

function Editor:LoadEditorSettings()

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

	if x < 0 or y < 0 or x + w > ScrW() or y + h > ScrH() then -- If the editor is outside the screen, reset it
		local width, height = math.min(ScrW() - 200, 800), math.min(ScrH() - 200, 620)
		self:SetPos((ScrW() - width) / 2, (ScrH() - height) / 2)
		self:SetSize(width, height)

		self:SaveEditorSettings()
	end
end

function Editor:SaveEditorSettings()

	-- Position & Size
	local w, h = self:GetSize()
	RunConsoleCommand("wire_expression2_editor_size", w .. "_" .. h)

	local x, y = self:GetPos()
	RunConsoleCommand("wire_expression2_editor_pos", x .. "_" .. y)
end


function Editor:PaintOver()
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
		local c_x, c_y, c_w, c_h = c.Bounds.x, c.Bounds.y, c.Bounds.w, c.Bounds.h
		if (c_x < 0) then c_x = w + c_x end
		if (c_y < 0) then c_y = h + c_y end
		if (c_w < 0) then c_w = w + c_w - c_x end
		if (c_h < 0) then c_h = h + c_h - c_y end
		c:SetPos(c_x, c_y)
		c:SetSize(c_w, c_h)
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
			if (x + self.p_w < ScrW() + 10 and x + self.p_w > ScrW() - 10) then x = ScrW() - self.p_w end
			if (y + self.p_h < ScrH() + 10 and y + self.p_h > ScrH() - 10) then y = ScrH() - self.p_h end
			self:SetPos(x, y)
		end
		if self.p_mode == "sizeBR" then
			local w = self.p_w + movedX
			local h = self.p_h + movedY
			if (self.p_x + w < ScrW() + 10 and self.p_x + w > ScrW() - 10) then w = ScrW() - self.p_x end
			if (self.p_y + h < ScrH() + 10 and self.p_y + h > ScrH() - 10) then h = ScrH() - self.p_y end
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
	if x + w > ScrW() then x = ScrW() - w end
	if y + h > ScrH() then y = ScrH() - h end
	if y < 0 then y = 0 end
	if x < 0 then x = 0 end
	if w > ScrW() then w = ScrW() end
	if h > ScrH() then h = ScrH() end

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
		self:SetSize(ScrW(), ScrH())
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
	assert(not panel.Bounds)
	panel.Bounds = { x = x, y = y, w = w, h = h }
	self.Components[#self.Components + 1] = panel
	return panel
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

	str = extractNameFromCode(code)
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

function Editor:GetActiveTab() return self.C.TabHolder:GetActiveTab() end

function Editor:GetNumTabs() return #self.C.TabHolder.Items end

function Editor:SetActiveTab(val)
	if self:GetActiveTab() == val then
		val:GetPanel():RequestFocus()
		return
	end
	self:SetLastTab(self:GetActiveTab())
	if isnumber(val) then
		self.C.TabHolder:SetActiveTab(self.C.TabHolder.Items[val].Tab)
		self:GetCurrentEditor():RequestFocus()
	elseif val and val:IsValid() then
		self.C.TabHolder:SetActiveTab(val)
		val:GetPanel():RequestFocus()
	end
	if self.E2 then self:Validate() end

	self:UpdateActiveTabTitle()
end

function Editor:UpdateActiveTabTitle()
	local title, tabtext = getPreferredTitles(self:GetChosenFile(), self:GetCode())

	if title then self:SubTitle("Editing: " .. title) else self:SubTitle() end
	if tabtext then
		if self:GetActiveTab():GetText() ~= tabtext then
			self:GetActiveTab():SetText(tabtext)
			self.C.TabHolder.tabScroller:InvalidateLayout()
		end
	end
end

function Editor:GetActiveTabIndex()
	local tab = self:GetActiveTab()
	for k, v in pairs(self.C.TabHolder.Items) do
		if tab == v.Tab then
			return k
		end
	end
	return -1
end


function Editor:SetActiveTabIndex(index)
	local tab = self.C.TabHolder.Items[index].Tab

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

function Editor:SetEditorMode(mode_name)
	self.EditorMode = mode_name
	for i = 1, self:GetNumTabs() do
		self:GetEditor(i):SetMode(mode_name)
	end
end

function Editor:GetEditorMode() return self.EditorMode end

local old
function Editor:FixTabFadeTime()
	if old ~= nil then return end -- It's already being fixed
	old = self.C.TabHolder:GetFadeTime()
	self.C.TabHolder:SetFadeTime(0)
	timer.Simple(old, function() self.C.TabHolder:SetFadeTime(old) old = nil end)
end

function Editor:CreateTab(chosenfile)
	local editor = vgui.Create("Expression2Editor")
	editor.parentpanel = self

	local sheet = self.C.TabHolder:AddSheet(extractNameFromFilePath(chosenfile), editor)
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
					if self.C.TabHolder.Items[i] ~= sheet then
						self:CloseTab(i)
					end
				end
			end)
			menu:AddSpacer()
			menu:AddOption("Save", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				local currentTab = self:GetActiveTab()
				self:SetActiveTab(pnl)
				self:SaveFile(self:GetChosenFile(), false)
				self:SetActiveTab(currentTab)
				self:SetLastTab(old)
			end)
			menu:AddOption("Save As", function()
				self:FixTabFadeTime()
				self:SetActiveTab(pnl)
				self:SaveFile(self:GetChosenFile(), false, true)
			end)
			menu:AddOption("Reload", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				self:SetActiveTab(pnl)
				self:LoadFile(editor.chosenfile, false)
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

	editor.OnTextChanged = function(panel)
		timer.Create("e2autosave", 5, 1, function()
			self:AutoSave()
		end)
		hook.Run("WireEditorText", self, editor)
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

	editor:SetMode(self:GetEditorMode())

	self:OnTabCreated(sheet) -- Call a function that you can override to do custom stuff to each tab.

	return sheet
end

function Editor:OnTabCreated(sheet) end

-- This function is made to be overwritten

function Editor:GetNextAvailableTab()
	local activetab = self:GetActiveTab()
	for _, v in pairs(self.C.TabHolder.Items) do
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
			local temp = self.C.TabHolder.Items[_tab]
			if temp then
				activetab = temp.Tab
				sheetindex = _tab
			else
				return
			end
		else
			activetab = _tab
			-- Find the sheet index
			for k, v in pairs(self.C.TabHolder.Items) do
				if activetab == v.Tab then
					sheetindex = k
					break
				end
			end
		end
	else
		activetab = self:GetActiveTab()
		-- Find the sheet index
		for k, v in pairs(self.C.TabHolder.Items) do
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
		self.C.TabHolder:InvalidateLayout()
		self:NewScript(true)
		return
	end

	-- Find the panel (for the scroller)
	local tabscroller_sheetindex
	for k, v in pairs(self.C.TabHolder.tabScroller.Panels) do
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
					self.C.TabHolder:InvalidateLayout()
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
				self.C.TabHolder:InvalidateLayout()
				self:NewScript(true)
				return
			end
		end
	end

	self:OnTabClosed(activetab) -- Call a function that you can override to do custom stuff to each tab.

	activetab:GetPanel():Remove()
	activetab:Remove()
	table.remove(self.C.TabHolder.Items, sheetindex)
	table.remove(self.C.TabHolder.tabScroller.Panels, tabscroller_sheetindex)

	self.C.TabHolder.tabScroller:InvalidateLayout()
	local w, h = self.C.TabHolder:GetSize()
	self.C.TabHolder:SetSize(w + 1, h) -- +1 so it updates
end

function Editor:OnTabClosed(sheet) end

-- This function is made to be overwritten

-- initialization commands
function Editor:InitComponents()
	self.Components = {}
	self.C = {}

	local function PaintFlatButton(panel, w, h)
		if not (panel:IsHovered() or panel:IsDown()) then return end
		derma.SkinHook("Paint", "Button", panel, w, h)
	end

	local DMenuButton = vgui.RegisterTable({
		Init = function(panel)
			panel:SetText("")
			panel:SetSize(24, 20)
			panel:Dock(LEFT)
		end,
		Paint = PaintFlatButton,
		DoClick = function(panel)
			local name = panel:GetName()
			local f = name and name ~= "" and self[name] or nil
			if f then f(self) end
		end
	}, "DButton")

	-- addComponent( panel, x, y, w, h )
	-- if x, y, w, h is minus, it will stay relative to right or buttom border
	self.C.Close = self:addComponent(vgui.Create("DButton", self), -45-4, 0, 45, 22) -- Close button
	self.C.Inf = self:addComponent(vgui.CreateFromTable(DMenuButton, self), -45-4-26, 0, 24, 22) -- Info button
	self.C.ConBut = self:addComponent(vgui.CreateFromTable(DMenuButton, self), -45-4-24-26, 0, 24, 22) -- Control panel open/close

	self.C.Divider = vgui.Create("DHorizontalDivider", self)

	self.C.Browser = vgui.Create("wire_expression2_browser", self.C.Divider) -- Expression browser

	self.C.MainPane = vgui.Create("DPanel", self.C.Divider)
	self.C.Menu = vgui.Create("DPanel", self.C.MainPane)
	self.C.Val = vgui.Create("Wire.IssueViewer", self.C.MainPane) -- Validation line
	self.C.TabHolder = vgui.Create("DPropertySheet", self.C.MainPane)
	self.C.TabHolder:SetPadding(1)

	self.C.Btoggle = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Toggle Browser being shown
	self.C.Sav = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Save button
	self.C.NewTab = vgui.CreateFromTable(DMenuButton, self.C.Menu, "NewTab") -- New tab button
	self.C.CloseTab = vgui.CreateFromTable(DMenuButton, self.C.Menu, "CloseTab") -- Close tab button
	self.C.Reload = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Reload tab button
	self.C.SaE = vgui.Create("DButton", self.C.Menu) -- Save & Exit button
	self.C.SavAs = vgui.Create("DButton", self.C.Menu) -- Save As button

	self.C.Control = self:addComponent(vgui.Create("Panel", self), -350, 52, 342, -32) -- Control Panel
	self.C.Credit = self:addComponent(vgui.Create("DTextEntry", self), -160, 52, 150, 150) -- Credit box
	self.C.Credit:SetEditable(false)

	self:CreateTab("generic")

	-- extra component options

	self.C.Divider:SetLeft(self.C.Browser)
	self.C.Divider:SetRight(self.C.MainPane)
	self.C.Divider:Dock(FILL)
	self.C.Divider:SetDividerWidth(4)
	self.C.Divider:SetCookieName("wire_expression2_editor_divider")
	self.C.Divider:SetLeftMin(0)

	local DoNothing = function() end
	self.C.MainPane.Paint = DoNothing
	--self.C.Menu.Paint = DoNothing

	self.C.Menu:Dock(TOP)
	self.C.TabHolder:Dock(FILL)
	self.C.Val:Dock(BOTTOM)

	self.C.TabHolder:SetPadding(1)

	self.C.Menu:SetHeight(24)
	self.C.Menu:DockPadding(2,2,2,2)
	self.C.Val:SetHeight(self.C.Val.CollapseSize)

	self.C.SaE:SetSize(80, 20)
	self.C.SaE:Dock(RIGHT)
	self.C.SavAs:SetSize(51, 20)
	self.C.SavAs:Dock(RIGHT)

	self.C.Inf:Dock(NODOCK)
	self.C.ConBut:Dock(NODOCK)

	self.C.Close:SetText("r")
	self.C.Close:SetFont("Marlett")
	self.C.Close.DoClick = function(btn) self:Close() end

	self.C.ConBut:SetImage("icon16/wrench.png")
	self.C.ConBut:SetText("")
	self.C.ConBut.Paint = PaintFlatButton
	self.C.ConBut.DoClick = function() self.C.Control:SetVisible(not self.C.Control:IsVisible()) end

	self.C.Inf:SetImage("icon16/information.png")
	self.C.Inf.Paint = PaintFlatButton
	self.C.Inf.DoClick = function(btn)
		self.C.Credit:SetVisible(not self.C.Credit:IsVisible())
	end


	self.C.Sav:SetImage("icon16/disk.png")
	self.C.Sav.DoClick = function(button) self:SaveFile(self:GetChosenFile()) end
	self.C.Sav:SetToolTip( "Save" )

	self.C.NewTab:SetImage("icon16/page_white_add.png")
	self.C.NewTab.DoClick = function(button) self:NewTab() end
	self.C.NewTab:SetToolTip( "New tab" )

	self.C.CloseTab:SetImage("icon16/page_white_delete.png")
	self.C.CloseTab.DoClick = function(button) self:CloseTab() end
	self.C.CloseTab:SetToolTip( "Close tab" )

	self.C.Reload:SetImage("icon16/page_refresh.png")
	self.C.Reload:SetToolTip( "Refresh file" )
	self.C.Reload.DoClick = function(button)
		self:LoadFile(self:GetChosenFile(), false)
	end

	self.C.SaE:SetText("Save and Exit")
	self.C.SaE.DoClick = function(button) self:SaveFile(self:GetChosenFile(), true) end

	self.C.SavAs:SetText("Save As")
	self.C.SavAs.DoClick = function(button) self:SaveFile(self:GetChosenFile(), false, true) end

	self.C.Browser:AddRightClick(self.C.Browser.filemenu, 4, "Save to", function()
		Derma_Query("Overwrite this file?", "Save To",
			"Overwrite", function()
				self:SaveFile(self.C.Browser.File.FileDir)
			end,
			"Cancel")
	end)
	self.C.Browser.OnFileOpen = function(_, filepath, newtab)
		self:Open(filepath, nil, newtab)
	end

	self.C.Val:SetText("   Click to validate...")
	self.C.Val.UpdateColours = function(button, skin)
		return button:SetTextStyleColor(skin.Colours.Button.Down)
	end
	self.C.Val.bgcolor = Color(255, 255, 255)
	self.C.Val.Paint = function(button)
		local w, h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, button.bgcolor)
		if button.Hovered then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0, 0, 0, 128)) end
	end
	self.C.Val.OnMousePressed = function(panel, btn)
		if btn == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption("Copy to clipboard", function()
				SetClipboardText(self.C.Val:GetValue())
			end)
			menu:Open()
		else
			self:Validate(true)
		end
	end
	self.C.Val.OnIssueClicked = function(panel, issue)
		if issue.trace ~= nil then
			self:GetCurrentEditor():SetCaret({issue.trace.start_line, issue.trace.start_col})
		end
	end

	self.C.Val.OnQuickFix = function(panel, issue)
		local editor = self:GetCurrentEditor()

		for _, fix in ipairs(issue.quick_fix) do
			local trace = fix.at
			editor:SetArea(
				{
					{ trace.start_line, trace.start_col },
					{ trace.end_line, trace.end_col }
				},
				fix.replace
			)
		end

		self:Validate()
	end

	self.C.Btoggle:SetImage("icon16/application_side_contract.png")
	function self.C.Btoggle.DoClick(button)
		if button.hide then
			self.C.Divider:LoadCookies()
		else
			self.C.Divider:SetLeftWidth(0)
		end
		self.C.Divider:InvalidateLayout()
		button:InvalidateLayout()
	end

	local oldBtoggleLayout = self.C.Btoggle.PerformLayout
	function self.C.Btoggle.PerformLayout(button)
		oldBtoggleLayout(button)
		if self.C.Divider:GetLeftWidth() > 0 then
			button.hide = false
			button:SetImage("icon16/application_side_contract.png")
		else
			button.hide = true
			button:SetImage("icon16/application_side_expand.png")
		end
	end

	self.C.Credit:SetTextColor(Color(0, 0, 0, 255))
	self.C.Credit:SetText("\t\tCREDITS\n\n\tEditor by: \tSyranide and Shandolum\n\n\tTabs (and more) added by Divran.\n\n\tFixed for GMod13 By Ninja101") -- Sure why not ;)
	self.C.Credit:SetMultiline(true)
	self.C.Credit:SetVisible(false)

	self:InitControlPanel(self.C.Control) -- making it seperate for better overview
	self.C.Control:SetVisible(false)
	if self.E2 then self:Validate() end
end

-- code1 contains the code that is not to be marked
local code1 = "@name \n@inputs \n@outputs \n@persist \n@strict\n\n"
-- code2 contains the code that is to be marked, so it can simply be overwritten or deleted.
local code2 = [[#[
    Documentation, instructions and examples are available at:
    https://github.com/wiremod/wire/wiki/Expression-2
    ^ There you can read about: ^

    - What is @strict and other directives (https://github.com/wiremod/wire/wiki/Expression-2-Directives)
    - What are events (https://github.com/wiremod/wire/wiki/Expression-2-Events)
    - What are lambdas (https://github.com/wiremod/wire/wiki/E2-Guide:-Lambdas)

    You can find our Discord here: https://discord.gg/H8UKY3Y
    You can find our Reddit here:  https://www.reddit.com/r/wiremod
    Please report any bugs here:   https://github.com/wiremod/wire/issues
]#]]
local defaultcode = code1 .. code2 .. "\n"

function Editor:AutoSave()
	local buffer = self:GetCode()
	if self.savebuffer == buffer or buffer == defaultcode or buffer == "" then return end
	self.savebuffer = buffer
	file.Write(self.Location .. "/_autosave_.txt", buffer)
end

function Editor:AddControlPanelTab(label, icon, tooltip)
	local frame = self.C.Control
	local panel = vgui.Create("DPanel")
	local ret = frame.TabHolder:AddSheet(label, panel, icon, false, false, tooltip)
	local old = ret.Tab.OnMousePressed
	function ret.Tab.OnMousePressed(...)
		timer.Simple(0.1,function() frame:ResizeAll() end) -- timers solve everything
		old(...)
	end

	ret.Panel:SetBackgroundColor(Color(96, 96, 96, 255))

	return ret
end

function Editor:InitControlPanel(frame)
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
	local oldFrameSetSize = frame.SetSize
	function frame:SetSize(...)
		self:ResizeAll()
		oldFrameSetSize(self, ...)
	end

	local oldFrameSetVisible = frame.SetVisible
	function frame:SetVisible(...)
		self:ResizeAll()
		oldFrameSetVisible(self, ...)
	end

	-- Function to add more objects to resize automatically
	frame.ResizeObjects = {}
	function frame:AddResizeObject(...)
		self.ResizeObjects[#self.ResizeObjects + 1] = { ... }
	end

	-- Our first object to auto resize is the tabholder. This sets it to position 2,4 and with a width and height offset of w-4, h-8.
	frame:AddResizeObject(tabholder, 2, 4)

	-- ------------------------------------------- EDITOR TAB
	local sheet = self:AddControlPanelTab("Editor", "icon16/wrench.png", "Options for the editor itself.")

	-- WINDOW BORDER COLORS

	local dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 4, 4)
	dlist:EnableVerticalScrollbar(true)

	-- Color Mixer PANEL - Houses label, combobox, mixer, reset button & reset all button.
	local mixPanel = vgui.Create( "panel" )
	mixPanel:SetTall( 240 )
	dlist:AddItem( mixPanel )

	do
		-- Label
		local label = vgui.Create( "DLabel", mixPanel )
		label:Dock( TOP )
		label:SetText( "Syntax Colors" )
		label:SizeToContents()

		-- Dropdown box of convars to change ( affects editor colors )
		local box = vgui.Create( "DComboBox", mixPanel )
		box:Dock( TOP )
		box:SetValue( "Color feature" )
		local active = nil

		-- Mixer
		local mixer = vgui.Create( "DColorMixer", mixPanel )
		mixer:Dock( FILL )
		mixer:SetPalette( true )
		mixer:SetAlphaBar( true )
		mixer:SetWangs( true )
		mixer.ValueChanged = function ( _, clr )
			self:SetSyntaxColor( active, clr )
		end

		for k, _ in pairs( colors_convars ) do
			box:AddChoice( k )
		end

		box.OnSelect = function ( self, index, value, data )
			-- DComboBox doesn't have a method for getting active value ( to my knowledge )
			-- Therefore, cache it, we're in a local scope so we're fine.
			active = value
			mixer:SetColor( colors[ active ] or Color( 255, 255, 255 ) )
		end

		-- Reset ALL button
		local rAll = vgui.Create( "DButton", mixPanel )
		rAll:Dock( BOTTOM )
		rAll:SetText( "Reset ALL to Default" )

		rAll.DoClick = function ()
			for k, v in pairs( colors_defaults ) do
				self:SetSyntaxColor( k, v )
			end
			mixer:SetColor( colors_defaults[ active ] )
		end

		-- Reset to default button
		local reset = vgui.Create( "DButton", mixPanel )
		reset:Dock( BOTTOM )
		reset:SetText( "Set to Default" )

		reset.DoClick = function ()
			self:SetSyntaxColor( active, colors_defaults[ active ] )
			mixer:SetColor( colors_defaults[ active ] )
		end


		-- Select a convar to be displayed automatically
		box:ChooseOptionID( 1 )
	end

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

	local AntialiasEditor = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(AntialiasEditor)
	AntialiasEditor:SetConVar("wire_expression2_editor_font_antialiasing")
	AntialiasEditor:SetText("Enable antialiasing")
	AntialiasEditor:SizeToContents()
	AntialiasEditor:SetTooltip("Enables antialiasing of the editor's text.")
	AntialiasEditor.OnChange = function(check, val)
		self:ChangeFont(self.FontConVar:GetString(), self.FontSizeConVar:GetInt())
	end

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

	label = vgui.Create("DLabel")
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
	modes["Atom/IntelliJ style"] = { 5, "Current mode:\nTab/Enter to use;\nArrow keys to choose." }
	-- modes["Qt Creator Style"]			= { 6, "Current mode:\nCtrl+Space to enter auto completion menu;\nSpace to abort; Enter to use top match." } <-- probably wrong. I'll check about adding Qt style later.

	for k, _ in pairs(modes) do
		AutoCompleteControlOptions:AddChoice(k)
	end

	modes[0] = modes["Default"][2]
	modes[1] = modes["Visual C# Style"][2]
	modes[2] = modes["Scroller"][2]
	modes[3] = modes["Scroller w/ Enter"][2]
	modes[4] = modes["Eclipse Style"][2]
	modes[5] = modes["Atom/IntelliJ style"][2]
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

	label = vgui.Create("DLabel")
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

	local WorldClicker = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(WorldClicker)
	WorldClicker:SetConVar("wire_expression2_editor_worldclicker")
	WorldClicker:SetText("Enable Clicking Outside Editor")
	WorldClicker:SizeToContents()
	function WorldClicker.OnChange(pnl, bVal)
		self:GetParent():SetWorldClicker(bVal)
	end

	local ScrollToWarning = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(ScrollToWarning)
	ScrollToWarning:SetConVar("wire_expression2_editor_show_warning_on_validate")
	ScrollToWarning:SetText("Scroll to warning on validate")
	ScrollToWarning:SizeToContents()
	ScrollToWarning:SetTooltip("Scrolls to the topmost warning in the editor on validate.")


	--------------------------------------------- EXPRESSION 2 TAB
	sheet = self:AddControlPanelTab("Expression 2", "icon16/computer.png", "Options for Expression 2.")

	dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 2, 2)
	dlist:EnableVerticalScrollbar(true)

	label = vgui.Create("DLabel")
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

	label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Concmd whitelist")
	label:SizeToContents()

	local ConcmdWhitelist = vgui.Create("DTextEntry")
	dlist:AddItem(ConcmdWhitelist)
	ConcmdWhitelist:SetConVar("wire_expression2_concmd_whitelist")
	ConcmdWhitelist:SetTooltip("Separate the commands with commas.")

	local Convar = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(Convar)
	Convar:SetConVar("wire_expression2_convar")
	Convar:SetText("convar")
	Convar:SizeToContents()
	Convar:SetTooltip("Allow/disallow the E2 from getting convar values from your player.")

	label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Convar whitelist")
	label:SizeToContents()

	local ConvarWhitelist = vgui.Create("DTextEntry")
	dlist:AddItem(ConvarWhitelist)
	ConvarWhitelist:SetConVar("wire_expression2_convar_whitelist")
	ConvarWhitelist:SetTooltip("Separate the convars with commas.")

	label = vgui.Create("DLabel")
	dlist:AddItem(label)
	label:SetText("Expression 2 block comment style")
	label:SizeToContents()

	local BlockCommentStyle = vgui.Create("DComboBox")
	dlist:AddItem(BlockCommentStyle)

	local blockCommentModes = {}
	blockCommentModes["New (alt 1)"] = {
		0, [[Current mode:
#[
Text here
Text here
]#]]
	}
	blockCommentModes["New (alt 2)"] = {
		1, [[Current mode:
#[Text here
Text here]# ]]
	}
	blockCommentModes["Old"] = {
		2, [[Current mode:
#Text here
#Text here]]
	}

	for k, _ in pairs(blockCommentModes) do
		BlockCommentStyle:AddChoice(k)
	end

	blockCommentModes[0] = blockCommentModes["New (alt 1)"][2]
	blockCommentModes[1] = blockCommentModes["New (alt 2)"][2]
	blockCommentModes[2] = blockCommentModes["Old"][2]
	BlockCommentStyle:SetToolTip(blockCommentModes[self.BlockCommentStyleConVar:GetInt()])

	BlockCommentStyle.OnSelect = function(panel, index, value)
		panel:SetToolTip(blockCommentModes[value][2])
		RunConsoleCommand("wire_expression2_editor_block_comment_style", blockCommentModes[value][1])
	end

	local ops_sync_checkbox = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(ops_sync_checkbox)
	ops_sync_checkbox:SetConVar("wire_expression_ops_sync_subscribe")
	ops_sync_checkbox:SetText("ops/cpu usage syncing for remote uploader (Admin only)")
	ops_sync_checkbox:SizeToContents()
	ops_sync_checkbox:SetTooltip("Opt into live ops/cpu usage for all E2s on the server via the remote uploader tab. If you're not admin, this checkbox does nothing.")

	-- ------------------------------------------- REMOTE UPDATER TAB
	sheet = self:AddControlPanelTab("Remote Updater", "icon16/world.png", "Manage your E2s from far away.")

	dlist = vgui.Create("DPanelList", sheet.Panel)
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

	local painted = 0
	local opened = false
	dlist2.Paint = function() painted = SysTime() + 0.05 end
	timer.Create( "wire_expression2_ops_sync_check", 0, 0, function()
		if painted > SysTime() and not opened then
			opened = true
			if Editor.ops_sync_subscribe:GetBool() then RunConsoleCommand("wire_expression_ops_sync","1") end
		elseif painted < SysTime() and opened then
			opened = false
			RunConsoleCommand("wire_expression_ops_sync","0")
		end
	end)

	local UpdateList = vgui.Create("DButton")
	UpdateList:SetText("Update List (Show only yours)")
	dlist:AddItem(UpdateList)
	UpdateList.DoClick = function(pnl, showall)
		local E2s = ents.FindByClass("gmod_wire_expression2")
		dlist2:Clear()
		local size = 0
		for _, v in ipairs(E2s) do
			local ply = v:GetNWEntity("player", NULL)
			if IsValid(ply) and ply == LocalPlayer() or showall then
				local nick
				if not ply or not ply:IsValid() then nick = "Unknown" else nick = ply:Nick() end
				local name = v:GetNWString("name", "generic")

				local singleline = string.match( name, "(.-)\n" )
				if singleline then name = singleline .. "..." end

				local max = 20
				if #name > max then name = string.sub(name,1,max) .. "..." end

				local panel = vgui.Create("DPanel")
				panel:SetTall((LocalPlayer():IsAdmin() and 74 or 47))
				panel.Paint = function(panel)
					local w, h = panel:GetSize()
					draw.RoundedBox(1, 0, 0, w, h, Color(65, 105, 255, 100))
				end
				dlist2:AddItem(panel)
				size = size + panel:GetTall() + 1

				local label = vgui.Create("DLabel", panel)
				local idx = v:EntIndex()

				local ownerStr
				if CPPI and v:CPPIGetOwner():GetName() ~= nick then
					ownerStr = string.format("Owner: %s | Code Author: %s", v:CPPIGetOwner():GetName(), nick)
				else
					ownerStr = "Owner: " .. nick
				end

				local str = string.format("Name: %s\nEntity ID: '%d'\n%s", name, idx, ownerStr)
				if LocalPlayer():IsAdmin() then
					str = string.format("Name: %s\nEntity ID: '%d'\n%i ops, %i%% %s\ncpu time: %ius\n%s", name, idx, 0, 0, "", 0, ownerStr)
				end

				label:SetText(str)
				label:SizeToContents()
				label:SetWide(280)
				label:SetWrap(true)
				label:SetPos(4, 4)
				label:SetTextColor(Color(255, 255, 255, 255))

				if LocalPlayer():IsAdmin() then
					local hardquota = GetConVar("wire_expression2_quotahard")
					local softquota = GetConVar("wire_expression2_quotasoft")

					function label:Think()
						if not IsValid(v) then
							label.Think = function() end
							return
						end

						local data = v:GetOverlayData()
						if data then
							local prfbench = data.prfbench
							local prfcount = data.prfcount
							local timebench = data.timebench

							local e2_hardquota = hardquota:GetInt()
							local e2_softquota = softquota:GetInt()

							local hardtext = (prfcount / e2_hardquota > 0.33) and "(+" .. tostring(math.Round(prfcount / e2_hardquota * 100)) .. "%)" or ""

							label:SetText(string.format(
								"Name: %s\nEntity ID: '%d'\n%i ops, %i%% %s\ncpu time: %ius\n%s",
								name, idx,
								prfbench, prfbench / e2_softquota * 100, hardtext,
								timebench * 1000000,
								ownerStr
							))
						end
					end
				end

				do
					local btn = vgui.Create("DButton", panel)
					btn:SetText("Upload")
					btn:SetSize(57, 18)
					timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() * 2 - 6, 4) end)
					btn.DoClick = function(pnl)
						WireLib.Expression2Upload(v)
					end
				end

				do
					local btn = vgui.Create("DButton", panel)
					btn:SetText("Download")
					btn:SetSize(57, 18)
					timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() - 4, 4) end)
					btn.DoClick = function(pnl)
						RunConsoleCommand("wire_expression_requestcode", v:EntIndex())
					end
				end

				do
					local btn = vgui.Create("DButton", panel)
					btn:SetText("Halt execution")
					btn:SetSize(75, 18)
					timer.Simple(0, function() btn:SetPos(panel:GetWide() - btn:GetWide() - 4, 24) end)
					btn.DoClick = function(pnl)
						RunConsoleCommand("wire_expression_forcehalt", v:EntIndex())
					end

					local btn2 = vgui.Create("DButton", panel)
					btn2:SetText("Reset")
					btn2:SetSize(39, 18)
					timer.Simple(0, function() btn2:SetPos(panel:GetWide() - btn2:GetWide() - btn:GetWide() - 6, 24) end)
					btn2.DoClick = function(pnl)
						RunConsoleCommand("wire_expression_reset", v:EntIndex())
					end
				end
			end
		end
		dlist2:SetTall(size + 2)
		dlist:InvalidateLayout()
	end
	local UpdateList2 = vgui.Create("DButton")
	UpdateList2:SetText("Update List (Show all)")
	dlist:AddItem(UpdateList2)
	UpdateList2.DoClick = function(pnl) UpdateList:DoClick(true) end
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

function Editor:NewScript(incurrent)
	if not incurrent and self.NewTabOnOpen:GetBool() then
		self:NewTab()
	else
		self:AutoSave()
		self:ChosenFile()

		-- Set title
		self:GetActiveTab():SetText("generic")
		self.C.TabHolder:InvalidateLayout()

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
	for _, v in pairs(tabs) do
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

-- On a successful validation run, will call this with the compiler object
function Editor:SetValidateData(compiler)
	-- Set methods and functions from all includes for syntax highlighting.
	local editor = self:GetCurrentEditor()
	editor.e2fs_functions = compiler.user_functions

	local function_sigs = {}
	for name, overloads in pairs(compiler.user_functions) do
		for args in pairs(overloads) do
			function_sigs[name .. "(" .. args .. ")"] = true
		end
	end

	local allkeys = {}
	for meta, names in pairs(compiler.user_methods) do
		for name, overloads in pairs(names) do
			allkeys[name] = true
			for args in pairs(overloads) do
				function_sigs[name .. "(" .. meta .. ":" .. args .. ")"] = true
			end
		end
	end

	editor.e2fs_methods = allkeys
	editor.e2_functionsig_lookup = function_sigs
end

function Editor:Validate(gotoerror)
	local header_color, header_text = nil, nil
	local problems_errors, problems_warnings = {}, {}

	if self.EditorType == "E2" then
		local errors, _, warnings, compiler = self:Validator(self:GetCode(), self:GetChosenFile())

		if not errors then ---@cast compiler -?
			self:SetValidateData(compiler)

			if warnings then
				header_color = Color(163, 130, 64, 255)

				local nwarnings = #warnings
				local warning = warnings[1]

				if gotoerror and self.ScrollToWarning:GetBool() then
					header_text = "Warning (1/" .. nwarnings .. "): " .. warning.message

					self:GetCurrentEditor():SetCaret { warning.trace.start_line, warning.trace.start_col  }
				else
					header_text = "Validated with " .. nwarnings .. " warning(s)."
				end
				problems_warnings = warnings
			else
				header_color = Color(0, 110, 20, 255)
				header_text ="Validation successful"
			end
		else
			header_color = Color(110, 0, 20, 255)

			local nerrors, error = #errors, errors[1]

			if gotoerror then
				header_text = "Error (1/" .. nerrors .. "): " .. error.message

				if error.trace then
					self:GetCurrentEditor():SetCaret { error.trace.start_line, error.trace.start_col  }
				end
			else
				header_text = "Failed to compile with " .. nerrors .. " errors(s)."
			end

			problems_errors = errors
		end

	elseif self.Validator then
		header_color = Color(64, 64, 64, 180)
		header_text = "Recompiling..."
		self:Validator(self:GetCode(), self:GetChosenFile())
	end

	self.C.Val:Update(problems_errors, problems_warnings, header_text, header_color)
	return true
end

function Editor:SetValidatorStatus(text, r, g, b, a)
	self.C.Val:SetBGColor(r or 0, g or 180, b or 0, a or 180)
	self.C.Val:SetText("   " .. text)
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
	if self.C.TabHolder.Items[n] then
		return self.C.TabHolder.Items[n].Panel
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
	hook.Run("WireEditorOpen", self, Line, code, forcenewtab)
	self:SetV(true)
	if self.chip then
		self.C.SaE:SetText("Upload & Exit")
	else
		self.C.SaE:SetText("Save and Exit")
	end
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
		local _, tabtext = getPreferredTitles(Line, code)
		local tab
		if self.NewTabOnOpen:GetBool() or forcenewtab then
			tab = self:CreateTab(tabtext).Tab
		else
			tab = self:GetActiveTab()
			tab:SetText(tabtext)
			self.C.TabHolder:InvalidateLayout()
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
		if self.C.Browser.File then
			str = self.C.Browser.File.FileDir -- Get FileDir
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
				local save_location = self.Location .. "/" .. strTextOut .. ".txt"
				if file.Exists(save_location, "DATA") then
					Derma_QueryNoBlur("The file '" .. strTextOut .. "' already exists. Do you want to overwrite it?", "File already exists",
					"Yes", function() self:SaveFile(save_location, close) end,
					"No", function() end)
				else
					self:SaveFile(save_location, close)
				end

				self:UpdateActiveTabTitle()
			end)
		return
	end

	if string.GetFileFromFilename(Line) == ".txt" then
		surface.PlaySound("buttons/button10.wav")
		GAMEMODE:AddNotify("Failed to save file without filename!", NOTIFY_ERROR, 7)
		return
	end

	local path = string.GetPathFromFilename(Line)
	if not file.IsDir(path, "DATA") then
		file.CreateDir(path)
	end

	file.Write(Line, self:GetCode())

	local f = file.Open(Line, "r", "DATA")
	if f then
		f:Close()
		local panel = self.C.Val
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
	else
		surface.PlaySound("buttons/button10.wav")
		GAMEMODE:AddNotify("Failed to save file as " .. Line .. ".", NOTIFY_ERROR, 7)
	end
end

function Editor:LoadFile(Line, forcenewtab)
	if not Line or file.IsDir(Line, "DATA") then return end

	local f = file.Open(Line, "r", "DATA")
	if not f then
		ErrorNoHalt("Erroring opening file: " .. Line)
	else
		local str = f:Read(f:Size()) or ""
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

		local _, tabtext = getPreferredTitles(Line, str)
		local tab
		if self.NewTabOnOpen:GetBool() or forcenewtab then
			tab = self:CreateTab(tabtext).Tab
		else
			tab = self:GetActiveTab()
			tab:SetText(tabtext)
			self.C.TabHolder:InvalidateLayout()
		end
		self:SetActiveTab(tab)
		self:ChosenFile(Line)

		self:SetCode(str)
	end
end

function Editor:Close()
	timer.Stop("e2autosave")
	local ok, err = pcall(self.AutoSave, self)
	if not ok then
		WireLib.Notify(nil, "Failed to autosave file while closing E2 editor.\n" .. err, 3)
	end

	ok = pcall(self.Validate, self)
	if not ok then
		WireLib.Notify(nil, "Failed to validate file while closing E2 editor.\n", 2)
	end

	ok, err = pcall(self.ExtractName, self)
	if not ok then
		WireLib.Notify(nil, "Failed to extract name while closing E2 editor.\n" .. err, 3)
	end

	self:SetV(false)
	self.chip = false

	ok, err = pcall(self.SaveEditorSettings, self)
	if not ok then
		WireLib.Notify(nil, "Failed to save editor settings while closing E2 editor.\n" .. err, 3)
	end

	hook.Run("WireEditorClose", self)
end

function Editor:Setup(nTitle, nLocation, nEditorType)
	self.Title = nTitle
	self.Location = nLocation
	self.EditorType = nEditorType
	self.C.Browser:Setup(nLocation)

	self:SetEditorMode(nEditorType or "Default")
	local editorMode = WireTextEditor.Modes[self:GetEditorMode() or "Default"]

	local helpMode = E2Helper.Modes[nEditorType or ""] or E2Helper.Modes[(editorMode and editorMode.E2HelperCategory) or ""]
	if helpMode then -- Add "E2Helper" button
		local E2Help = vgui.Create("Button", self.C.Menu)
		E2Help:SetSize(58, 20)
		E2Help:Dock(RIGHT)
		E2Help:SetText("E2Helper")
		E2Help.DoClick = function()
			E2Helper.Show()
			if editorMode and editorMode.E2HelperCategory then
				E2Helper:SetMode(editorMode.E2HelperCategory)
			else
				E2Helper:SetMode(nEditorType)
			end
		end
		self.C.E2Help = E2Help
	end
	local useValidator = false
	local useSoundBrowser = false
	if editorMode then
		useValidator = editorMode.UseValidator
		useSoundBrowser = editorMode.UseSoundBrowser
		if useValidator and editorMode.Validator then
			self.Validator = editorMode.Validator -- Takes self, self:GetCode(), self:GetChosenFile()
		end
	end

	if not useValidator then
		self.C.Val:SetVisible(false)
	end

	if useSoundBrowser then -- Add "Sound Browser" button
		local SoundBrw = vgui.Create("Button", self.C.Menu)
		SoundBrw:SetSize(85, 20)
		SoundBrw:Dock(RIGHT)
		SoundBrw:SetText("Sound Browser")
		SoundBrw.DoClick = function() RunConsoleCommand("wire_sound_browser_open") end
		self.C.SoundBrw = SoundBrw
	end

	if nEditorType == "E2" then
		self.E2 = true
	end

	self:NewScript(true) -- Opens initial tab, in case OpenOldTabs is disabled or fails.

	if wire_expression2_editor_openoldtabs:GetBool() then
		self:OpenOldTabs()
	end
	self:LoadSyntaxColors()

	self:InvalidateLayout()
end


vgui.Register("Expression2EditorFrame", Editor, "DFrame")
