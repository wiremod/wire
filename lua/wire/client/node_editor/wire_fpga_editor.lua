local Editor = {}

Editor.NewTabOnOpen = CreateClientConVar("wire_fpga_new_tab_on_open", "1", true, false)

surface.CreateFont("DefaultBold", {
	font = "Tahoma",
	size = 12,
	weight = 700,
	antialias = true,
	additive = false,
})

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

local size = CreateClientConVar("wire_fpga_editor_size", "800_600", true, false)
local pos = CreateClientConVar("wire_fpga_editor_pos", "-1_-1", true, false)

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
	RunConsoleCommand("wire_fpga_editor_size", w .. "_" .. h)

	local x, y = self:GetPos()
	RunConsoleCommand("wire_fpga_editor_pos", x .. "_" .. y)
end


function Editor:PaintOver()
	surface.SetFont("DefaultBold")
	surface.SetTextColor(255, 255, 255, 255)
	surface.SetTextPos(10, 6)
	surface.DrawText(self.Title .. self.subTitle)
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

	self:UpdateActiveTabTitle()
end

function Editor:ExtractNameFromEditor()
	return self:GetCurrentEditor():GetName()
end

function Editor:UpdateActiveTabTitle()
	local title = self:GetChosenFile()
	local tabtext = self:ExtractNameFromEditor()

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

local old
function Editor:FixTabFadeTime()
	if old ~= nil then return end -- It's already being fixed
	old = self.C.TabHolder:GetFadeTime()
	self.C.TabHolder:SetFadeTime(0)
	timer.Simple(old, function() self.C.TabHolder:SetFadeTime(old) old = nil end)
end

function Editor:CreateTab(chosenfile)
	local editor = vgui.Create("FPGAEditor")
	editor.ParentPanel = self

	local sheet = self.C.TabHolder:AddSheet(chosenfile, editor)
	editor.chosenfile = chosenfile

	sheet.Tab.OnMousePressed = function(pnl, keycode, ...)

		if keycode == MOUSE_MIDDLE then
			self:CloseTab(pnl)
			return
		elseif keycode == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption("Close", function()
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
				self:UpdateActiveTabTitle()
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
		timer.Create("fpgaautosave", 5, 1, function()
			self:AutoSave()
		end)
	end
	editor.OnShortcut = function(_, code)
		if code == KEY_S then
			self:SaveFile(self:GetChosenFile())
		end
	end
	editor:RequestFocus()

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
	local sheet = self:CreateTab("gate")
	self:SetActiveTab(sheet.Tab)

	self:NewChip(true)
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
		activetab:SetText("gate")
		self.C.TabHolder:InvalidateLayout()
		self:NewChip(true)
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
					self:GetActiveTab():SetText("gate")
					self.C.TabHolder:InvalidateLayout()
					self:NewChip(true)
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
				self:GetActiveTab():SetText("gate")
				self.C.TabHolder:InvalidateLayout()
				self:NewChip(true)
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

	self.C.Browser = vgui.Create("wire_expression2_browser", self.C.Divider) -- Expression 2 file browser
	do
		local pnl = self.C.Browser.SearchBox
		local old = pnl.OnLoseFocus

		function pnl.OnLoseFocus()
			old(pnl)
			self:GetCurrentEditor():RequestFocus()
		end
	end


	self.C.MainPane = vgui.Create("DPanel", self.C.Divider)
	self.C.Menu = vgui.Create("DPanel", self.C.MainPane)
	self.C.TabHolder = vgui.Create("DPropertySheet", self.C.MainPane)

	self.C.Btoggle = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Toggle Browser being shown
	self.C.Sav = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Save button
	self.C.NewTab = vgui.CreateFromTable(DMenuButton, self.C.Menu, "NewTab") -- New tab button
	self.C.CloseTab = vgui.CreateFromTable(DMenuButton, self.C.Menu, "CloseTab") -- Close tab button
	self.C.Reload = vgui.CreateFromTable(DMenuButton, self.C.Menu) -- Reload tab button
	self.C.SaE = vgui.Create("DButton", self.C.Menu) -- Save & Exit button
	self.C.SavAs = vgui.Create("DButton", self.C.Menu) -- Save As button

	self.C.Control = self:addComponent(vgui.Create("Panel", self), -350, 52, 342, -32) -- Control Panel
	self.C.Credit = self:addComponent(vgui.Create("DTextEntry", self), -160, 52, 150, 190) -- Credit box
	self.C.Credit:SetEditable(false)

	-- extra component options

	self.C.Divider:SetLeft(self.C.Browser)
	self.C.Divider:SetRight(self.C.MainPane)
	self.C.Divider:Dock(FILL)
	self.C.Divider:SetDividerWidth(4)
	self.C.Divider:SetCookieName("wire_fpga_editor_divider")
	self.C.Divider:SetLeftMin(0)

	local DoNothing = function() end
	self.C.MainPane.Paint = DoNothing

	self.C.Menu:Dock(TOP)
	self.C.TabHolder:Dock(FILL)

	self.C.TabHolder:SetPadding(1)

	self.C.Menu:SetHeight(24)
	self.C.Menu:DockPadding(2,2,2,2)

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
	self.C.Sav:SetTooltip( "Save" )

	self.C.NewTab:SetImage("icon16/page_white_add.png")
	self.C.NewTab.DoClick = function(button) self:NewTab() end
	self.C.NewTab:SetTooltip( "New tab" )

	self.C.CloseTab:SetImage("icon16/page_white_delete.png")
	self.C.CloseTab.DoClick = function(button) self:CloseTab() end
	self.C.CloseTab:SetTooltip( "Close tab" )

	self.C.Reload:SetImage("icon16/page_refresh.png")
	self.C.Reload:SetTooltip( "Refresh file" )
	self.C.Reload.DoClick = function(button)
		self:LoadFile(self:GetChosenFile(), false)
		self:UpdateActiveTabTitle()
	end

	self.C.SaE:SetText("Save and Exit")
	self.C.SaE.DoClick = function(button) self:SaveFile(self:GetChosenFile(), true) end

	self.C.SavAs:SetText("Save As")
	self.C.SavAs.DoClick = function(button) self:SaveFile(self:GetChosenFile(), false, true) end

	--Helper
	self.C.Helper = vgui.Create("DFrame", self)
	self.C.Helper:SetSize(1200, 700)
	self.C.Helper:Center()
	self.C.Helper:ShowCloseButton(true)
	self.C.Helper:SetDeleteOnClose(false)
	self.C.Helper:SetVisible(false)
	self.C.Helper:SetTitle("FPGA Help")
	self.C.Helper:SetScreenLock(true)
	local html = vgui.Create("DHTML" , self.C.Helper)
	html:Dock(FILL)
	html:OpenURL("https://wiremod.github.io/Miscellaneous/fpgahelp.html")
	html:SetAllowLua(false)

	self.C.Help = vgui.Create("Button", self.C.Menu)
	self.C.Help:SetSize(80, 20)
	self.C.Help:Dock(RIGHT)
	self.C.Help:DockMargin(0,0,20,0)
	self.C.Help:SetText("Help")
	self.C.Help.DoClick = function()
		self.C.Helper:SetVisible(true)
		self.C.Helper:MakePopup()
	end

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
	self.C.Credit:SetText("\t\tCREDITS\n\n\tEditor by: \tSyranide and Shandolum\n\n\tTabs (and more) added by Divran.\n\n\tFixed for GMod13 By Ninja101 \n\n\tRewritten into a node editor by Lysdal") -- Sure why not ;)
	self.C.Credit:SetMultiline(true)
	self.C.Credit:SetVisible(false)

	self:InitControlPanel(self.C.Control) -- making it seperate for better overview
	self.C.Control:SetVisible(false)

	self:CreateTab("gate")
end

function Editor:AutoSave()
	local buffer = self:GetData()
	if self.savebuffer == buffer or buffer == "" then return end
	self.savebuffer = buffer
	file.CreateDir(self.Location)
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

	local NewTabOnOpen = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(NewTabOnOpen)
	NewTabOnOpen:SetConVar("wire_fpga_new_tab_on_open")
	NewTabOnOpen:SetText("New tab on open")
	NewTabOnOpen:SizeToContents()
	NewTabOnOpen:SetTooltip("Enable/disable loaded files opening in a new tab.\nIf disabled, loaded files will be opened in the current tab.")

	local SaveTabsOnClose = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(SaveTabsOnClose)
	SaveTabsOnClose:SetConVar("wire_fpga_editor_savetabs")
	SaveTabsOnClose:SetText("Save tabs on close")
	SaveTabsOnClose:SizeToContents()
	SaveTabsOnClose:SetTooltip("Save the currently opened tab file paths on shutdown.\nOnly saves tabs whose files are saved.")

	local OpenOldTabs = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(OpenOldTabs)
	OpenOldTabs:SetConVar("wire_fpga_editor_openoldtabs")
	OpenOldTabs:SetText("Open old tabs on load")
	OpenOldTabs:SizeToContents()
	OpenOldTabs:SetTooltip("Open the tabs from the last session on load.\nOnly tabs whose files were saved before disconnecting from the server are stored.")

	local WorldClicker = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(WorldClicker)
	WorldClicker:SetConVar("wire_fpga_editor_worldclicker")
	WorldClicker:SetText("Enable Clicking Outside Editor")
	WorldClicker:SizeToContents()
	function WorldClicker.OnChange(pnl, bVal)
		self:GetParent():SetWorldClicker(bVal)
	end

	local Minimap = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(Minimap)
	Minimap:SetConVar("wire_fpga_editor_minimap")
	Minimap:SetText("Show minimap")
	Minimap:SizeToContents()
	Minimap:SetTooltip("Enable or disable the minimap in the editor.")
	--------------------------------------------- FPGA TAB
	sheet = self:AddControlPanelTab("FPGA", "icon16/computer.png", "Options for FPGA.")

	dlist = vgui.Create("DPanelList", sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject(dlist, 4, 4)
	dlist:EnableVerticalScrollbar(true)

	local AllowInsideView = vgui.Create("DCheckBoxLabel")
	dlist:AddItem(AllowInsideView)
	AllowInsideView:SetConVar("wire_fpga_allow_inside_view")
	AllowInsideView:SetText("Allow inside view")
	AllowInsideView:SizeToContents()
	AllowInsideView:SetTooltip("Other people will be able to hover over your FPGAs and see the internal gates. They won't be able to download your chip, but just see a simplified visual representation.")


	dlist:InvalidateLayout()
end

----- FPGA Options ------------------
local wire_fpga_allow_inside_view = CreateClientConVar("wire_fpga_allow_inside_view", "0", true, false)

function FPGAGetOptions()
	return WireLib.von.serialize({
		allow_inside_view = wire_fpga_allow_inside_view:GetBool() or false
	}, false)
end

function FPGASendOptions()
	FPGASendOptionsToServer(FPGAGetOptions())
end

cvars.AddChangeCallback("wire_fpga_allow_inside_view", FPGASendOptions)
-------------------------------------


function Editor:NewChip(incurrent)
	if not incurrent and self.NewTabOnOpen:GetBool() then
		self:NewTab()
	else
		self:AutoSave()
		self:ChosenFile()

		-- Set title
		self:GetActiveTab():SetText("gate")

		self.C.TabHolder:InvalidateLayout()
		self:ClearData()
	end
end

local wire_fpga_editor_savetabs = CreateClientConVar("wire_fpga_editor_savetabs", "1", true, false)

local id = 0
function Editor:InitShutdownHook()
	id = id + 1

	-- save code when shutting down
	hook.Add("ShutDown", "wire_fpga_ShutDown" .. id, function()
		local buffer = self:GetData()
		if not self:GetCurrentEditor():HasNodes() then return end

		file.CreateDir(self.Location)
		file.Write(self.Location .. "/_shutdown_.txt", buffer)

		if wire_fpga_editor_savetabs:GetBool() then
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

	file.CreateDir(self.Location)
	file.Write(self.Location .. "/_tabs_.txt", strtabs)
end

local wire_fpga_editor_openoldtabs = CreateClientConVar("wire_fpga_editor_openoldtabs", "1", true, false)

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

function Editor:SubTitle(sub)
	if not sub then self.subTitle = ""
	else self.subTitle = " - " .. sub
	end
end

local wire_fpga_editor_worldclicker = CreateClientConVar("wire_fpga_editor_worldclicker", "0", true, false)
function Editor:SetV(bool)
	if bool then
		self:MakePopup()
		self:InvalidateLayout(true)
	end
	self:SetVisible(bool)
	self:SetKeyboardInputEnabled(bool)
	self:GetParent():SetWorldClicker(wire_fpga_editor_worldclicker:GetBool() and bool) -- Enable this on the background so we can update FPGA's without closing the editor
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
	self.savefilefn = self:ExtractNameFromEditor()
	return
end

function Editor:ClearCopyData()
	self.copyBuffer = nil
	self.copyBufferSize = 0
	self.copyOffset = nil
end

function Editor:SetCopyData(buffer, offset)
	self.copyBuffer = buffer
	self.copyBufferSize = table.Count(buffer)
	self.copyOffset = offset
end

function Editor:GetCopyData()
	if self.copyBuffer then
		return {self.copyBuffer, self.copyOffset}
	else
		return {nil, nil}
	end
end

function Editor:GetCopyDataSize()
	if self.copyBufferSize then
		return self.copyBufferSize
	end
	return 0
end


function Editor:SetData(data)
	self:GetCurrentEditor():SetData(data)
	self.savebuffer = self:GetData()
	self:ExtractName()
end

function Editor:ClearData()
	self:GetCurrentEditor():ClearData()
	self.savebuffer = self:GetData()
end

function Editor:GetEditor(n)
	if self.C.TabHolder.Items[n] then
		return self.C.TabHolder.Items[n].Panel
	end
end

function Editor:GetData()
	local data = self:GetCurrentEditor():GetData()

	local last_data = ""
	if #data < 64 then
		last_data = data
	else
		last_data = data:sub(-64 + #data % 8)
	end

	FPGASetToolInfo(self:ExtractNameFromEditor(), #data, last_data)
	return data
end

function Editor:GetCurrentEditor()
	return self:GetActiveTab():GetPanel()
end

function Editor:Open(Line, data, forcenewtab)
	if self:IsVisible() and not Line and not data then self:Close() end
	hook.Run("WireFPGAEditorOpen", self, Line, data, forcenewtab)
	self:SetV(true)
	self.C.SaE:SetText("Save and Exit")
	if data then
		if not forcenewtab then
			for i = 1, self:GetNumTabs() do
				if self:GetEditor(i).chosenfile == Line then
					self:SetActiveTab(i)
					self:SetData(data)
					return
				elseif self:GetEditor(i):GetValue() == data then
					self:SetActiveTab(i)
					return
				end
			end
		end

		local tab
		if self.NewTabOnOpen:GetBool() or forcenewtab then
			tab = self:CreateTab("Download").Tab
		else
			tab = self:GetActiveTab()
		end
		self:SetActiveTab(tab)

		self:ChosenFile()
		self:SetData(data)

		self:UpdateActiveTabTitle()

		if Line then self:SubTitle("Editing: " .. Line) end
		return
	end
	if Line then self:LoadFile(Line, forcenewtab) return end
end

function Editor:SaveFile(Line, close, SaveAs)
	self:ExtractName()

	if close and self.chip then
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
				strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars):lower()
				self:SaveFile(self.Location .. "/" .. strTextOut .. ".txt", close)
			end)
		return
	end

	file.CreateDir(string.GetPathFromFilename(Line))
	file.Write(Line, self:GetData())

	surface.PlaySound("ambient/water/drip3.wav")

	if not self.chip then self:ChosenFile(Line) end

	self:UpdateActiveTabTitle()

	if close then
		GAMEMODE:AddNotify("FPGA saved as " .. Line .. ".", NOTIFY_GENERIC, 7)
		self:Close()
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
					if forcenewtab ~= nil then self:SetData(str) end
					return
				elseif self:GetEditor(i):GetData() == str then
					self:SetActiveTab(i)
					return
				end
			end
		end

		local tab
		if self.NewTabOnOpen:GetBool() or forcenewtab then
			tab = self:CreateTab("").Tab
		else
			tab = self:GetActiveTab()
		end
		self:SetActiveTab(tab)
		self:ChosenFile(Line)
		self:SetData(str)
		self:UpdateActiveTabTitle()
	end
end

function Editor:Close()
	timer.Stop("fpgaautosave")
	self:AutoSave()

	self:ExtractName()
	self:SetV(false)
	self.chip = false

	self:SaveEditorSettings()

	hook.Run("WireFPGAEditorClose", self)
end


function Editor:Setup(nTitle, nLocation)
	self.Title = nTitle
	self.Location = nLocation
	self.C.Browser:Setup(nLocation)

	self:NewChip(true) -- Opens initial tab, in case OpenOldTabs is disabled or fails.

	if wire_fpga_editor_openoldtabs:GetBool() then
		self:OpenOldTabs()
	end

	self:InvalidateLayout()
end

vgui.Register("FPGAEditorFrame", Editor, "DFrame")
if SERVER then MsgC(Color(0, 100, 255), "FPGA Editor loaded!\n") end