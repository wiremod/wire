local Editor = {}


------------------------------------------------------------------------
-- Fonts
------------------------------------------------------------------------

Editor.FontConVar = CreateClientConVar( "wire_expression2_editor_font", "Courier New", true, false )
Editor.FontSizeConVar = CreateClientConVar( "wire_expression2_editor_font_size", 16, true, false )
Editor.BlockCommentStyleConVar = CreateClientConVar( "wire_expression2_editor_block_comment_style", 1, true, false )
Editor.NewTabOnOpen = CreateClientConVar( "wire_expression2_new_tab_on_open", "1", true, false )

Editor.Fonts = {}
-- 				Font					Description

-- Windows
Editor.Fonts["Courier New"] 			= "Default font"
Editor.Fonts["DejaVu Sans Mono"] 		= ""
Editor.Fonts["Consolas"] 				= ""
Editor.Fonts["Fixedsys"] 				= ""
Editor.Fonts["Lucida Console"]			= ""

-- Mac
Editor.Fonts["Monaco"] 					= "Mac standard font"


Editor.CreatedFonts = {}

function Editor:SetEditorFont( editor )
	if (!self.CurrentFont) then
		self:ChangeFont( self.FontConVar:GetString(), self.FontSizeConVar:GetInt() )
		return
	end

	editor.CurrentFont = self.CurrentFont
	editor.FontWidth = self.FontWidth
	editor.FontHeight = self.FontHeight
end

function Editor:ChangeFont( FontName, Size )
	if (!FontName or FontName == "" or !Size) then return end

	-- If font is not already created, create it.
	if (!self.CreatedFonts[FontName .. "_" .. Size]) then
		surface.CreateFont( FontName, Size, 400, false, false, "Expression2_" .. FontName .. "_" .. Size )
		surface.CreateFont( FontName, Size, 700, false, false, "Expression2_" .. FontName .. "_" .. Size .. "_Bold" )
		self.CreatedFonts[FontName .. "_" .. Size] = true
	end

	self.CurrentFont = "Expression2_" .. FontName .. "_" .. Size
	surface.SetFont( self.CurrentFont )
	self.FontWidth, self.FontHeight = surface.GetTextSize( " " )

	for i=1,self:GetNumTabs() do
		self:SetEditorFont( self:GetEditor( i ) )
	end
end

------------------------------------------------------------------------
-- Colors
------------------------------------------------------------------------

local colors = { -- Table copied from TextEditor, used for saving colors to convars.
	["directive"] = Color(240, 240, 160), -- yellow
	["number"]    = Color(240, 160, 160), -- light red
	["function"]  = Color(160, 160, 240), -- blue
	["notfound"]  = Color(240,  96,  96), -- dark red
	["variable"]  = Color(160, 240, 160), -- light green
	["string"]    = Color(128, 128, 128), -- grey
	["keyword"]   = Color(160, 240, 240), -- turquoise
	["operator"]  = Color(224, 224, 224), -- white
	["comment"]   = Color(128, 128, 128), -- grey
	["ppcommand"] = Color(240,  96, 240), -- purple
	["typename"]  = Color(240, 160,  96), -- orange
	["constant"]  = Color(240, 160, 240), -- pink
}

local colors_defaults = {}

local colors_convars = {}
for k,v in pairs( colors ) do
	colors_defaults[k] = Color(v.r,v.g,v.b) -- Copy to save defaults
	colors_convars[k] = CreateClientConVar("wire_expression2_editor_color_"..k,v.r.."_"..v.g.."_"..v.b,true,false)
end

function Editor:LoadSyntaxColors()
	for k,v in pairs( colors_convars ) do
		local r,g,b = v:GetString():match( "(%d+)%_(%d+)%_(%d+)" )
		local def = colors_defaults[k]
		colors[k] = Color( tonumber(r) or def.r,tonumber(g) or def.g,tonumber(b) or def.b )
	end

	for i=1,self:GetNumTabs() do
		self:GetEditor(i):SetSyntaxColors( colors )
	end
end

function Editor:SetSyntaxColor( colorname, colr )
	if (!colors[colorname]) then return end
	colors[colorname] = colr
	RunConsoleCommand("wire_expression2_editor_color_"..colorname,colr.r.."_"..colr.g.."_"..colr.b)

	for i=1,self:GetNumTabs() do
		self:GetEditor(i):SetSyntaxColor( colorname, colr )
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

// overwritten commands
function Editor:Init()
	self.Title = ""
	self.subTitle = ""
	self.LastClick = 0
	self.GuiClick = 0
	self.SimpleGUI = false
	self.Location = ""

	// colors
	self.colors = {}
	self.colors.col_FL = Color( 65, 105, 225, 255 ) //Royal Blue
	self.colors.col_FR = Color( 25, 25, 112, 255 ) //Midnight Blue
	self.colors.tmp_FL = Color( 65, 105, 225, 255 )
	self.colors.tmp_FR = Color( 25, 25, 112, 255 )
	self.colors.tmp_Dark = 255

	self.C = {}
	self.Components = {}

	surface.CreateFont( "default", 11, 300, false, false, "E2SmallFont" )
	self.logo = surface.GetTextureID("vgui/e2logo")

	self:InitComponents()
	self:LoadSyntaxColors()

	local width, height = math.min(surface.ScreenWidth()-200, 800), math.min(surface.ScreenHeight()-200, 620)
	self:SetPos((surface.ScreenWidth() - width) / 2, (surface.ScreenHeight() - height) / 2)
	self:SetSize(width, height)

	//  This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:SetV(false)

	self:InitShutdownHook()
end

function Editor:Paint()
	local w,h = self:GetSize()
	if(self.SimpleGUI) then
		draw.RoundedBox(4, 0, 0, w, h, self.colors.col_FL)
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( 0, 22, w, 1 )
	else
		local dif = {(self.colors.col_FR.r-self.colors.col_FL.r)/w, (self.colors.col_FR.g-self.colors.col_FL.g)/w, (self.colors.col_FR.b-self.colors.col_FL.b)/w }
		draw.RoundedBox(4, 0, 0, 10, h, self.colors.col_FL)
		draw.RoundedBox(4, w-15, 0, 15, h, self.colors.col_FR)

		for i = 5 , w-9, 5 do
			surface.SetDrawColor(math.floor(self.colors.col_FL.r + dif[1]*i), math.floor(self.colors.col_FL.g + dif[2]*i), math.floor(self.colors.col_FL.b + dif[3]*i), self.colors.col_FL.a)
			surface.DrawRect( i, 0, 5, h )
		end
	end
	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	surface.SetDrawColor( 0, 0, 0, 150 )
	surface.DrawRect( 0, 22, w, 1 )
	surface.SetDrawColor( 255, 255, 255, 255 )

	draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	return true
end

function Editor:PaintOver()
	local w,h = self:GetSize()

	draw.RoundedBox( 4, 0, 0, 118, 21, self.colors.col_FL )
	surface.SetFont("DefaultBold")
	surface.SetTextColor( 255, 255, 255, 255 )
	surface.SetTextPos( 10, 6 )
	surface.DrawText(self.Title .. self.subTitle)
	/*if(self.E2) then
	surface.SetTexture(self.logo)
	surface.SetDrawColor( 255, 255, 255, 128 )
	surface.DrawTexturedRect( w-148, h-158, 128, 128)
	end*/
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetTextPos(0,0)
	surface.SetFont("Default")
	return true
end

function Editor:PerformLayout()
	local w,h = self:GetSize()

	for i=1, #self.Components do
		local c = self.Components[i]
		local c_x,c_y,c_w,c_h = c.x,c.y,c.w,c.h
		if(c.x<0) then c_x = w+c.x end
		if(c.y<0) then c_y = h+c.y end
		if(c.w<0) then c_w = w+c.w-c_x end
		if(c.h<0) then c_h = h+c.h-c_y end
		c.panel:SetPos(c_x,c_y)
		c.panel:SetSize(c_w,c_h)
	end
end

function Editor:OnMousePressed(mousecode)
	if(mousecode != 107) then return end // do nothing if mouseclick is other than left-click
	if(!self.pressed) then
		self.pressed        = true
		self.p_x, self.p_y  = self:GetPos()
		self.p_w, self.p_h  = self:GetSize()
		self.p_mx           = gui.MouseX()
		self.p_my           = gui.MouseY()
		self.p_mode         = self:getMode()
		if(self.p_mode == "drag") then
			if(self.GuiClick>CurTime()-0.2) then
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
	if(mousecode != 107) then return end // do nothing if mouseclick is other than left-click
	self.pressed = false
end

function Editor:Think()
	if(self.fs) then return end
	if(self.pressed) then
		if(!input.IsMouseDown( MOUSE_LEFT )) then	// needs this if you let go of the mouse outside the panel
			self.pressed = false
		end
		local movedX = gui.MouseX()-self.p_mx
		local movedY = gui.MouseY()-self.p_my
		if(self.p_mode == "drag") then
			local x = self.p_x + movedX
			local y = self.p_y + movedY
			if(x<10 and x>-10) then x = 0 end
			if(y<10 and y>-10) then y = 0 end
			if(x+self.p_w<surface.ScreenWidth()+10 and x+self.p_w>surface.ScreenWidth()-10) then x = surface.ScreenWidth()-self.p_w end
			if(y+self.p_h<surface.ScreenHeight()+10 and y+self.p_h>surface.ScreenHeight()-10) then y = surface.ScreenHeight()-self.p_h end
			self:SetPos(x,y)
		end
		if(self.p_mode == "sizeBR") then
			local w = self.p_w + movedX
			local h = self.p_h + movedY
			if(self.p_x+w<surface.ScreenWidth()+10 and self.p_x+w>surface.ScreenWidth()-10) then w = surface.ScreenWidth()-self.p_x end
			if(self.p_y+h<surface.ScreenHeight()+10 and self.p_y+h>surface.ScreenHeight()-10) then h = surface.ScreenHeight()-self.p_y end
			if(w<300) then w = 300 end
			if(h<200) then h = 200 end
			self:SetSize(w,h)
		end
		if(self.p_mode == "sizeR") then
			local w = self.p_w + movedX
			if(w<300) then w = 300 end
			self:SetWide(w)
		end
		if(self.p_mode == "sizeB") then
			local h = self.p_h + movedY
			if(h<200) then h = 200 end
			self:SetTall(h)
		end
	end
	if(!self.pressed) then
		local cursor = "arrow"
		local mode = self:getMode()
		if(mode == "sizeBR") then cursor = "sizenwse" end
		if(mode == "sizeR") then cursor = "sizewe" end
		if(mode == "sizeB") then cursor = "sizens" end
		if(cursor != self.cursor) then
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

// special functions

function Editor:fullscreen()
	if(self.fs) then
		self:SetPos(self.preX,self.preY)
		self:SetSize(self.preW,self.preH)
		self.fs = false
	else
		self.preX,self.preY = self:GetPos()
		self.preW,self.preH = self:GetSize()
		self:SetPos(0, 0)
		self:SetSize(surface.ScreenWidth(), surface.ScreenHeight())
		self.fs = true
	end
end

function Editor:getMode()
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	local ix   = gui.MouseX() - x
	local iy   = gui.MouseY() - y

	if(ix<0 or ix>w or iy<0 or iy>h) then return end // if the mouse is outside the box
	if(iy<22) then
		return "drag"
	end
	if(iy>h-10) then
		if(ix>w-20) then return "sizeBR" end
		return "sizeB"
	end
	if(ix>w-10) then
		if(iy>h-20) then return "sizeBR" end
		return "sizeR"
	end
end

function Editor:addComponent(panel,x,y,w,h)
	local t = #self.Components+1
	self.Components[t] = {}
	self.Components[t].panel = panel
	self.Components[t].x = x
	self.Components[t].y = y
	self.Components[t].w = w
	self.Components[t].h = h
	return self.Components[t]
end

-- TODO: Fix this function
local function extractNameFromCode( str )
	return str:match( "@name ([^\r\n]+)" )
end

local function getPreferredTitles( Line, code )
	local title
	local tabtext

	local str = Line
	if (str and str != "") then
		title = str
		tabtext = str
	end

	local str = extractNameFromCode( code )
	if (str and str != "") then
		if (!title) then
			title = str
		end
		tabtext = str
	end

	return title, tabtext
end

function Editor:GetLastTab() return self.LastTab end
function Editor:SetLastTab( Tab ) self.LastTab = Tab end
function Editor:GetActiveTab() return self.C['TabHolder'].panel:GetActiveTab() end
function Editor:GetNumTabs() return #self.C['TabHolder'].panel.Items end
function Editor:SetActiveTab( val )
	if (self:GetActiveTab() == val) then
		val:GetPanel():RequestFocus()
		return
	end
	self:SetLastTab( self:GetActiveTab() )
	if (type(val) == "number") then
		self.C['TabHolder'].panel:SetActiveTab( self.C['TabHolder'].panel.Items[val].Tab )
		self:GetCurrentEditor():RequestFocus()
	elseif (val and val:IsValid()) then
		self.C['TabHolder'].panel:SetActiveTab( val )
		val:GetPanel():RequestFocus()
	end


	-- Editor subtitle and tab text
	local title, tabtext = getPreferredTitles( self:GetChosenFile(), self:GetCode() )

	if (title) then self:SubTitle("Editing: " .. title ) else self:SubTitle() end
	if (tabtext) then
		if (self:GetActiveTab():GetText() != tabtext) then
			self:GetActiveTab():SetText( tabtext )
			self.C['TabHolder'].panel:InvalidateLayout()
		end
	end
end

function Editor:GetActiveTabIndex()
	local tab = self:GetActiveTab()
	for k,v in pairs(self.C['TabHolder'].panel.Items) do
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

local function extractNameFromFilePath( str )
	local found = str:reverse():find( "/", 1, true )
	if (found) then
		return str:Right( found-1 )
	else
		return str
	end
end

function Editor:SetSyntaxColorLine( func )
	self.SyntaxColorLine = func
	for i=1,self:GetNumTabs() do
		self:GetEditor( i ).SyntaxColorLine = func
	end
end
function Editor:GetSyntaxColorLine() return self.SyntaxColorLine end

local old
function Editor:FixTabFadeTime()
	if (old != nil) then return end -- It's already being fixed
	local old = self.C['TabHolder'].panel:GetFadeTime()
	self.C['TabHolder'].panel:SetFadeTime( 0 )
	timer.Simple( old, function() self.C['TabHolder'].panel:SetFadeTime( old ) old = nil end )
end

function Editor:CreateTab( chosenfile )
	local editor = vgui.Create("Expression2Editor")
	editor.parentpanel = self

	local sheet = self.C['TabHolder'].panel:AddSheet( extractNameFromFilePath( chosenfile ), editor )
	self:SetEditorFont( editor )
	editor.chosenfile = chosenfile

	sheet.Tab.OnMousePressed = function( pnl, keycode, ... )

		if (keycode == MOUSE_MIDDLE) then
			--self:FixTabFadeTime()
			self:CloseTab( pnl )
			return
		elseif (keycode == MOUSE_RIGHT) then
			local menu = DermaMenu()
			menu:AddOption( "Close", function()
				--self:FixTabFadeTime()
				self:CloseTab( pnl )
			end)
			menu:AddOption( "Close all others", function()
				self:FixTabFadeTime()
				self:SetActiveTab( pnl )
				for i=self:GetNumTabs(), 1, -1 do
					if (self.C['TabHolder'].panel.Items[i] != sheet) then
						self:CloseTab( i )
					end
				end
			end)
			menu:AddSpacer()
			menu:AddOption( "Save", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				self:SetActiveTab( pnl )
				self:SaveFile( self:GetChosenFile(), true )
				self:SetActiveTab( self:GetLastTab() )
				self:SetLastTab( old )
			end)
			menu:AddOption( "Save As", function()
				self:FixTabFadeTime()
				local old = self:GetLastTab()
				self:SetActiveTab( pnl )
				self:SaveFile( self:GetChosenFile(), false, true )
				self:SetActiveTab( self:GetLastTab() )
				self:SetLastTab( old )
			end)
			menu:Open()
			return
		end

		self:SetActiveTab( pnl )
	end

	sheet.Tab.Paint = function( tab )
		local w,h = tab:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if (self:GetActiveTab() == tab) then
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192))
		elseif (self:GetLastTab() == tab) then
			draw.RoundedBox(0,1,1,w-2,h-2,Color(0,0,0,145))
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
			self:Validate()
		else
			local mode = GetConVar("wire_expression2_autocomplete_controlstyle"):GetInt()
			local enabled = GetConVar("wire_expression2_autocomplete"):GetBool()
			if (mode == 1 and enabled) then
				if (code == KEY_B) then
					self:Validate(true)
				elseif (code == KEY_SPACE) then
					local ed = self:GetCurrentEditor()
					if (ed.AC_Panel and ed.AC_Panel:IsVisible()) then
						ed:AC_Use(ed.AC_Suggestions[1])
					end
				end
			elseif (code == KEY_SPACE) then
				self:Validate(true)
			end
		end
	end
	editor:RequestFocus()

	local func = self:GetSyntaxColorLine()
	if (func != nil) then -- it's a custom syntax highlighter
		editor.SyntaxColorLine = func
	else -- else it's E2's syntax highlighter
		editor:SetSyntaxColors( colors )
	end

	self:OnTabCreated( sheet ) -- Call a function that you can override to do custom stuff to each tab.

	return sheet
end

function Editor:OnTabCreated( sheet ) end -- This function is made to be overwritten

function Editor:GetNextAvailableTab()
	local activetab = self:GetActiveTab()
	for k,v in pairs( self.C['TabHolder'].panel.Items ) do
		if (v.Tab and v.Tab:IsValid() and v.Tab ~= activetab) then
			return v.Tab
		end
	end
end

function Editor:NewTab()
	local sheet = self:CreateTab( "generic" )
	self:SetActiveTab(sheet.Tab)
	if (self.E2) then
		self:NewScript( true )
	end
end

function Editor:CloseTab( _tab )
	local activetab, sheetindex
	if (_tab) then
		if (type(_tab) == "number") then
			local temp = self.C['TabHolder'].panel.Items[_tab]
			if (temp) then
				activetab = temp.Tab
				sheetindex = _tab
			else
				return
			end
		else
			activetab = _tab
			-- Find the sheet index
			for k,v in pairs( self.C['TabHolder'].panel.Items ) do
				if (activetab == v.Tab) then
					sheetindex = k
					break
				end
			end
		end
	else
		activetab = self:GetActiveTab()
		-- Find the sheet index
		for k,v in pairs( self.C['TabHolder'].panel.Items ) do
			if (activetab == v.Tab) then
				sheetindex = k
				break
			end
		end
	end

	self:AutoSave()

	-- There's only one tab open, no need to actually close any tabs
	if (self:GetNumTabs() == 1) then
		activetab:SetText( "generic" )
		self.C['TabHolder'].panel:InvalidateLayout()
		self:NewScript( true )
		return
	end

	-- Find the panel (for the scroller)
	local tabscroller_sheetindex
	for k,v in pairs( self.C['TabHolder'].panel.tabScroller.Panels ) do
		if (v == activetab) then
			tabscroller_sheetindex = k
			break
		end
	end

	self:FixTabFadeTime()

	if (activetab == self:GetActiveTab()) then -- We're about to close the current tab
		if (self:GetLastTab() and self:GetLastTab():IsValid()) then -- If the previous tab was saved
			if (activetab == self:GetLastTab()) then -- If the previous tab is equal to the current tab
				local othertab = self:GetNextAvailableTab() -- Find another tab
				if (othertab and othertab:IsValid()) then -- If that other tab is valid, use it
					self:SetActiveTab( othertab )
					self:SetLastTab()
				else -- Reset the current tab (backup)
					self:GetActiveTab():SetText( "generic" )
					self.C['TabHolder'].panel:InvalidateLayout()
					self:NewScript( true )
					return
				end
			else -- Change to the previous tab
				self:SetActiveTab( self:GetLastTab() )
				self:SetLastTab()
			end
		else -- If the previous tab wasn't saved
			local othertab = self:GetNextAvailableTab() -- Find another tab
			if (othertab and othertab:IsValid()) then -- If that other tab is valid, use it
				self:SetActiveTab( othertab )
			else -- Reset the current tab (backup)
				self:GetActiveTab():SetText( "generic" )
				self.C['TabHolder'].panel:InvalidateLayout()
				self:NewScript( true )
				return
			end
		end
	end

	self:OnTabClosed( activetab ) -- Call a function that you can override to do custom stuff to each tab.

	activetab:GetPanel():Remove()
	activetab:Remove()
	table.remove( self.C['TabHolder'].panel.Items, sheetindex )
	table.remove( self.C['TabHolder'].panel.tabScroller.Panels, tabscroller_sheetindex )

	self.C['TabHolder'].panel:InvalidateLayout()
end

function Editor:OnTabClosed( sheet ) end -- This function is made to be overwritten

// initialization commands

function Editor:InitComponents()
	self.Components = {}
	self.C = {}

	// addComponent( panel, x, y, w, h )
	// if x, y, w, h is minus, it will stay relative to right or buttom border
	self.C['Close']     = self:addComponent(vgui.Create( "DSysButton", self )               , -22,   4,  18,  18)   // Close button
	self.C['Inf']       = self:addComponent(vgui.Create( "DSysButton", self )               , -42,   4,  18,  18)   // Info button
	self.C['Sav']       = self:addComponent(vgui.Create( "Button", self )                   , 191,  30,  20,  20)   // Save button
	self.C['NewTab']	= self:addComponent(vgui.Create( "Button", self )					, 212,  30,  20,  20)   // New tab button
	self.C['CloseTab']	= self:addComponent(vgui.Create( "Button", self )					, 233,  30,  20,  20)   // Close tab button
	self.C['SaE']       = self:addComponent(vgui.Create( "Button", self )                   , -70,  30, -10,  20)   // Save & Exit button
	self.C['SavAs']     = self:addComponent(vgui.Create( "Button", self )                   , -123, 30, -72,  20)   // Save As button
	self.C['Browser']   = self:addComponent(vgui.Create( "wire_expression2_browser", self ) ,  10,  30, 157, -10)   // Expression browser
	self.C['TabHolder'] = self:addComponent(vgui.Create( "DPropertySheet", self )			, 165, 	52,	-5,  -27)	// TabHolder
	self:CreateTab( "generic" )
	self.C['Val']       = self:addComponent(vgui.Create( "Label", self )                    , 170, -30, -10,  20)   // Validation line
	self.C['Btoggle']   = self:addComponent(vgui.Create( "Button", self )                   , 170,  30,  20,  20)   // Toggle Browser being shown
	self.C['ConBut']    = self:addComponent(vgui.Create( "Button", self )                   , -62,  4,   18,  18)   // Control panel open/close
	self.C['Control']   = self:addComponent(vgui.Create( "Panel", self )                    ,-350,  52, 342, -32)   // Control Panel
	self.C['Credit']    = self:addComponent(vgui.Create( "TextEntry", self )                ,-160,  52, 150, 100)   // Credit box

	self.C['TabHolder'].panel.Paint = function() end

	// extra component options
	self.C['Close'].panel:SetType( "close" )
	self.C['Close'].panel:SetDrawBorder( false )
	self.C['Close'].panel:SetDrawBackground( false )
	self.C['Close'].panel.DoClick = function ( button ) self:Close() end
	self.C['Credit'].panel:SetText("\t\tCREDITS\n\n\tEditor by: \tSyranide and Shandolum\n\n\tTabs (and more) added by Divran.")
	self.C['Credit'].panel:SetMultiline(true)
	self.C['Credit'].panel:SetVisible(false)
	self.C['Inf'].panel:SetType( "question" )
	self.C['Inf'].panel:SetDrawBorder( false )
	self.C['Inf'].panel:SetDrawBackground( false )
	self.C['Inf'].panel.OnCursorEntered = function() self.C['Credit'].panel:SetVisible(true) end
	self.C['Inf'].panel.OnCursorExited = function() self.C['Credit'].panel:SetVisible(false) end
	self.C['Sav'].panel:SetText("")
	self.C['Sav'].panel.Icon = surface.GetTextureID( "vgui/spawnmenu/save" )
	self.C['Sav'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetTexture(button.Icon)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['Sav'].panel.DoClick = function( button ) self:SaveFile( self:GetChosenFile() ) end

	self.C['NewTab'].panel:SetText("")
	self.C['NewTab'].panel.Icon = surface.GetTextureID( "gui/silkicons/page_white_add" )
	self.C['NewTab'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetTexture(button.Icon)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['NewTab'].panel.DoClick = function( button )
		self:NewTab()
	end

	self.C['CloseTab'].panel:SetText("")
	self.C['CloseTab'].panel.Icon = surface.GetTextureID( "gui/silkicons/page_white_delete" )
	self.C['CloseTab'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetTexture(button.Icon)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['CloseTab'].panel.DoClick = function( button )
		self:CloseTab()
	end

	self.C['SaE'].panel:SetText("")
	self.C['SaE'].panel.Font = "E2SmallFont"
	self.C['SaE'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetFont(button.Font)
		surface.SetTextPos( 3, 4 )
		surface.SetTextColor( 255, 255, 255, 255 )
		if(self.chip) then surface.DrawText("Upload & Exit")
		else surface.DrawText(" Save & Exit") end
	end
	self.C['SaE'].panel.DoClick = function( button ) self:SaveFile( self:GetChosenFile(), true ) end

	self.C['SavAs'].panel:SetText("")
	self.C['SavAs'].panel.Font = "E2SmallFont"
	self.C['SavAs'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
		surface.SetFont(button.Font)
		surface.SetTextPos( 3, 4 )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.DrawText("  Save As")
	end
	self.C['SavAs'].panel.DoClick = function( button ) self:SaveFile( self:GetChosenFile(), false, true ) end

	self.C['Browser'].panel.OnFileClick = function(panel)
		if(panel.sDir and panel.sDir == panel.File.FileDir and CurTime()-LastClick < 1) then
			self:LoadFile(panel.sDir)
		else
			panel.sDir = panel.File.FileDir
			LastClick = CurTime()
		end
	end
	self.C['Browser'].panel:AddRightClick( self.C['Browser'].panel.filemenu,4, "Save to" , function()
		Derma_Query(
			"Overwrite this file?", "Save To",
			"Overwrite", function()
				self:SaveFile( self.C['Browser'].panel.File.FileDir)
			end,
			"Cancel"
		)
	end )
	self.C['Val'].panel:SetText( "   Click to validate..." )
	self.C['Val'].panel.OnMousePressed = function(panel) self:Validate(true) end
	self.C['Btoggle'].panel:SetText("<")
	self.C['Btoggle'].panel.Paint = function(button)
		local w,h = button:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
	end
	self.C['Btoggle'].panel.DoClick = function(button)
		if(button.hide) then
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
		if(!button.toggle) then return end
		if(button.hide and self.C['Btoggle'].x > 10) then
			self.C['Btoggle'].x 	= self.C['Btoggle'].x-button.anispeed
			self.C['Sav'].x 		= self.C['Sav'].x-button.anispeed
			self.C['NewTab'].x 		= self.C['NewTab'].x-button.anispeed
			self.C['CloseTab'].x 	= self.C['CloseTab'].x-button.anispeed
			self.C['TabHolder'].x 	= self.C['TabHolder'].x-button.anispeed
			self.C['Val'].x 		= self.C['Val'].x-button.anispeed
			self.C['Browser'].w 	= self.C['Browser'].w-button.anispeed
		elseif(!button.hide and self.C['Btoggle'].x < 170) then
			self.C['Btoggle'].x 	= self.C['Btoggle'].x+button.anispeed
			self.C['Sav'].x 		= self.C['Sav'].x+button.anispeed
			self.C['NewTab'].x 		= self.C['NewTab'].x+button.anispeed
			self.C['CloseTab'].x 	= self.C['CloseTab'].x+button.anispeed
			self.C['TabHolder'].x 		= self.C['TabHolder'].x+button.anispeed
			self.C['Val'].x 		= self.C['Val'].x+button.anispeed
			self.C['Browser'].w 	= self.C['Browser'].w+button.anispeed
		end

		if(self.C['Browser'].panel:IsVisible() and self.C['Browser'].w <= 0) then self.C['Browser'].panel:SetVisible(false)
		elseif(!self.C['Browser'].panel:IsVisible() and self.C['Browser'].w > 0) then self.C['Browser'].panel:SetVisible(true) end
		self:InvalidateLayout()
		if(button.hide) then
			if(self.C['Btoggle'].x > 10 or self.C['Sav'].x > 30 or self.C['Val'].x < 170 or self.C['Browser'].w > 0) then return end
			button.toggle = false
		else
			if(self.C['Btoggle'].x < 170 or self.C['Sav'].x < 190 or self.C['Val'].x < 170 or self.C['Browser'].w < 150) then return end
			button.toggle = false
		end

	end
	self.C['ConBut'].panel.Icon = surface.GetTextureID( "gui/silkicons/wrench" )
	self.C['ConBut'].panel:SetText("")
	self.C['ConBut'].panel.Paint = function(button)
		local w,h = button:GetSize()
		surface.SetTexture(button.Icon)
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect( 2, 2, w-4, h-4)
	end
	self.C['ConBut'].panel.DoClick = function() self.C['Control'].panel:SetVisible(!self.C['Control'].panel:IsVisible()) end
	self:InitControlPanel(self.C['Control'].panel)	//making it seperate for better overview
	self.C['Control'].panel:SetVisible(false)
	self:Validate()
end

function Editor:AutoSave()
	local buffer = self:GetCode()
	if self.savebuffer == buffer then return end
	self.savebuffer = buffer
	file.Write(self.Location .. "/_autosave_.txt", buffer)
end

function Editor:AddControlPanelTab( label, icon, tooltip )
	local frame = self.C['Control'].panel
	local panel = vgui.Create( "Panel" )
	local ret = frame.TabHolder:AddSheet( label, panel, icon, false, false, tooltip )
	ret.Tab.Paint = function( tab )
		local w,h = tab:GetSize()
		draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
		if (frame.TabHolder:GetActiveTab() == tab) then
			draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192))
		end
	end
	local old = ret.Tab.OnMousePressed
	function ret.Tab.OnMousePressed( ... )
		frame:ResizeAll()
		old( ... )
	end

	return ret
end

function Editor:InitControlPanel(frame)
	local C = self.C['Control']

	-- Give it the nice gradient look
	frame.Paint = function( pnl )
		local _w,_h = self:GetSize()
		local w,h = pnl:GetSize()
		if(self.SimpleGUI) then
			draw.RoundedBox(4, 0, 0, w, h, self.colors.col_FL)
			surface.SetDrawColor( 0, 0, 0, 150 )
			surface.DrawRect( 0, 22, w, 1 )
		else
			local dif = {(self.colors.col_FR.r-self.colors.col_FL.r)/_w, (self.colors.col_FR.g-self.colors.col_FL.g)/_w, (self.colors.col_FR.b-self.colors.col_FL.b)/_w }
			local i = _w-350
			draw.RoundedBox(4, 0, 0, 10, h, Color(math.floor(self.colors.col_FL.r + dif[1]*i), math.floor(self.colors.col_FL.g + dif[2]*i), math.floor(self.colors.col_FL.b + dif[3]*i), self.colors.col_FL.a))
			draw.RoundedBox(4, w-15, 0, 15, h, self.colors.col_FR)

			local _i = 0
			for i = _w-350+5, _w, 5 do
				_i = _i + 5
				surface.SetDrawColor(math.floor(self.colors.col_FL.r + dif[1]*i), math.floor(self.colors.col_FL.g + dif[2]*i), math.floor(self.colors.col_FL.b + dif[3]*i), self.colors.col_FL.a)
				surface.DrawRect( _i, 0, 5, h )
			end
		end
		draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
		draw.RoundedBox(4, 7, 27, w - 14, h - 34, Color(0, 0, 0, 192))
	end

	-- Add a property sheet to hold the tabs
	local tabholder = vgui.Create( "DPropertySheet", frame )
	tabholder:SetPos( 2,4 )
	frame.TabHolder = tabholder

	-- They need to be resized one at a time... dirty fix incoming (If you know of a nicer way to do this, don't hesitate to fix it.)
	local function callNext( t, n )
		local obj = t[n]
		local pnl = obj[1]
		if (pnl and pnl:IsValid()) then
			local x,y = obj[2], obj[3]
			pnl:SetPos( x, y )
			local w,h = pnl:GetParent():GetSize()
			local wofs, hofs = w-x*2, h-y*2
			pnl:SetSize( wofs, hofs )
		end
		n=n+1
		if (n<=#t) then
			timer.Simple(0,callNext,t,n)
		end
	end
	function frame:ResizeAll() timer.Simple(0,callNext,self.ResizeObjects,1) end

	-- Resize them at the right times
	local old = frame.SetSize
	function frame:SetSize( ... )
		self:ResizeAll()
		old( self, ... )
	end
	local old = frame.SetVisible
	function frame:SetVisible( ... )
		self:ResizeAll()
		old( self, ... )
	end

	-- Function to add more objects to resize automatically
	frame.ResizeObjects = {}
	function frame:AddResizeObject( ... )
		self.ResizeObjects[#self.ResizeObjects+1] = {...}
	end

	-- Our first object to auto resize is the tabholder. This sets it to position 2,4 and with a width and height offset of w-4, h-8.
	frame:AddResizeObject( tabholder, 2, 4 )

	tabholder.Paint = function() end

	--------------------------------------------- EDITOR TAB
	local sheet = self:AddControlPanelTab( "Editor", "gui/silkicons/wrench", "Options for the editor itself." )

	-- WINDOW BORDER COLORS

	local dlist = vgui.Create("DPanelList",sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject( dlist, 4, 4 )
	dlist:EnableVerticalScrollbar( true )

	local SimpleColors = vgui.Create( "Label" )
	dlist:AddItem( SimpleColors )
	SimpleColors:SetSize(180,20)
	SimpleColors:SetText("Simple Colors = off")
	SimpleColors.OnMousePressed = function(check)
		if(self.SimpleGUI) then
			self.SimpleGUI = false
			check:SetText("Simple Colors = off")
		else
			self.SimpleGUI = true
			check:SetText("Simple Colors = on")
		end
		self:InvalidateLayout()
	end
	local temp = vgui.Create( "Panel" )
	dlist:AddItem( temp )
	temp:SetTall( 70 )
	local FLColor = vgui.Create( "DColorCircle", temp )
	FLColor:SetSize(64,64)
	FLColor.SetFrameColor = function(panel)
		self.colors.tmp_FL = panel:GetRGB()
		self:CalculateColor()
	end
	FLColor.TranslateValues = function(panel, x, y ) return self:TranslateValues(panel, x, y ) end
	local FRColor = vgui.Create( "DColorCircle", temp )
	FRColor:SetPos(120,0)
	FRColor:SetSize(64,64)
	FRColor.SetFrameColor = function(panel)
		self.colors.tmp_FR = panel:GetRGB()
		self:CalculateColor()
	end
	FRColor.TranslateValues = function(panel, x, y ) return self:TranslateValues(panel, x, y ) end
	local DarknessColor = vgui.Create( "DSlider" )
	dlist:AddItem( DarknessColor )
	DarknessColor:SetSize(180,30)
	DarknessColor.TranslateValues = function(panel, x, y )
		self.colors.tmp_Dark = 255-math.floor(x*255)
		self:CalculateColor()
		return x, 0.5
	end
	DarknessColor:SetSlideX(0)

	---- FONTS

	local FontLabel = vgui.Create( "DLabel" )
	dlist:AddItem( FontLabel )
	FontLabel:SetText( "Font:                                   Font Size:" )
	FontLabel:SizeToContents()
	FontLabel:SetPos( 10, 0 )

	local temp = vgui.Create("Panel")
	temp:SetTall( 25 )
	dlist:AddItem( temp )

	local FontSelect = vgui.Create( "DMultiChoice", temp )
	--dlist:AddItem( FontSelect )
	FontSelect.OnSelect = function( panel, index, value )
		if (value == "Custom...") then
			Derma_StringRequestNoBlur( "Enter custom font:", "", "", function( value )
				self:ChangeFont( value, self.FontSizeConVar:GetInt() )
				RunConsoleCommand( "wire_expression2_editor_font", value )
			end)
		else
			value = value:gsub( " %b()", "" ) -- Remove description
			self:ChangeFont( value, self.FontSizeConVar:GetInt() )
			RunConsoleCommand( "wire_expression2_editor_font", value )
		end
	end
	for k,v in pairs( self.Fonts ) do
		FontSelect:AddChoice( k .. (v != "" and " (" .. v .. ")" or "") )
	end
	FontSelect:AddChoice( "Custom..." )
	FontSelect:SetEditable( false )
	FontSelect:SetSize( 240 - 50 - 4, 20 )

	local FontSizeSelect = vgui.Create( "DMultiChoice", temp )
	FontSizeSelect.OnSelect = function( panel, index, value )
		value = value:gsub( " %b()", "" )
		self:ChangeFont( self.FontConVar:GetString(), tonumber(value) )
		RunConsoleCommand( "wire_expression2_editor_font_size", value )
	end
	for i=11,26 do
		FontSizeSelect:AddChoice( i .. (i == 16 and " (Default)" or "") )
	end
	FontSizeSelect:SetEditable( false )
	FontSizeSelect:SetPos( FontSelect:GetWide() + 4, 0 )
	FontSizeSelect:SetSize( 50, 20 )


	local label = vgui.Create("DLabel")
	dlist:AddItem( label )
	label:SetText( "Auto completion options" )
	label:SizeToContents()

	local AutoComplete = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( AutoComplete )
	AutoComplete:SetConVar( "wire_expression2_autocomplete" )
	AutoComplete:SetText( "Auto Completion" )
	AutoComplete:SizeToContents()
	AutoComplete:SetTooltip( "Enable/disable auto completion in the E2 editor." )

	local AutoCompleteExtra = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( AutoCompleteExtra )
	AutoCompleteExtra:SetConVar( "wire_expression2_autocomplete_moreinfo" )
	AutoCompleteExtra:SetText( "More Info (for AC)" )
	AutoCompleteExtra:SizeToContents()
	AutoCompleteExtra:SetTooltip( "Enable/disable additional information for auto completion." )

	local label = vgui.Create("DLabel")
	dlist:AddItem( label )
	label:SetText( "Auto completion control style" )
	label:SizeToContents()

	local AutoCompleteControlOptions = vgui.Create( "DMultiChoice" )
	dlist:AddItem( AutoCompleteControlOptions )

	local modes = {}
	modes["Default"] 					= { 0, "Current mode:\nTab/CTRL+Tab to choose item;\nEnter/Space to use;\nArrow keys to abort." }
	modes["Visual C# Style"] 			= { 1, "Current mode:\nCtrl+Space to use the top match;\nArrow keys to choose item;\nTab/Enter/Space to use;\nCode validation hotkey (ctrl+space) moved to ctrl+b." }
	modes["Scroller"] 		 			= { 2, "Current mode:\nMouse scroller to choose item;\nMiddle mouse to use." }
	modes["Scroller w/ Enter"] 		 	= { 3, "Current mode:\nMouse scroller to choose item;\nEnter to use." }
	modes["Eclipse Style"]				= { 4, "Current mode:\nEnter to use top match;\nTab to enter auto completion menu;\nArrow keys to choose item;\nEnter to use;\nSpace to abort." }
	--modes["Qt Creator Style"]			= { 6, "Current mode:\nCtrl+Space to enter auto completion menu;\nSpace to abort; Enter to use top match." } <-- probably wrong. I'll check about adding Qt style later.


	for k,v in pairs( modes ) do
		AutoCompleteControlOptions:AddChoice( k )
	end

	modes[0] = modes["Default"][2]
	modes[1] = modes["Visual C# Style"][2]
	modes[2] = modes["Scroller"][2]
	modes[3] = modes["Scroller w/ Enter"][2]
	modes[4] = modes["Eclipse Style"][2]
	AutoCompleteControlOptions:SetEditable( false )
	AutoCompleteControlOptions:SetToolTip( modes[self.BlockCommentStyleConVar:GetInt()] )


	AutoCompleteControlOptions.OnSelect = function( panel, index, value )
		panel:SetToolTip( modes[value][2] )
		RunConsoleCommand( "wire_expression2_autocomplete_controlstyle", modes[value][1] )
	end

	local NewTabOnOpen = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( NewTabOnOpen )
	NewTabOnOpen:SetConVar( "wire_expression2_new_tab_on_open" )
	NewTabOnOpen:SetText( "New tab on open" )
	NewTabOnOpen:SizeToContents()
	NewTabOnOpen:SetTooltip( "Enable/disable loaded files opening in a new tab.\nIf disabled, loaded files will be opened in the current tab." )

	--------------------------------------------- EXPRESSION 2 TAB
	local sheet = self:AddControlPanelTab( "Expression 2", "gui/silkicons/world", "Options for Expression 2." )

	local dlist = vgui.Create("DPanelList",sheet.Panel)
	dlist.Paint = function() end
	frame:AddResizeObject( dlist, 2, 2 )
	dlist:EnableVerticalScrollbar( true )

	local label = vgui.Create("DLabel")
	dlist:AddItem( label )
	label:SetText( "Clientside expression 2 options" )
	label:SizeToContents()

	local AutoIndent = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( AutoIndent )
	AutoIndent:SetConVar( "wire_expression2_autoindent" )
	AutoIndent:SetText( "Auto indenting" )
	AutoIndent:SizeToContents()
	AutoIndent:SetTooltip( "Enable/disable auto indenting." )

	local Concmd = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( Concmd )
	Concmd:SetConVar( "wire_expression2_concmd" )
	Concmd:SetText( "concmd" )
	Concmd:SizeToContents()
	Concmd:SetTooltip( "Allow/disallow the E2 from running console commands on you." )

	local label = vgui.Create("DLabel")
	dlist:AddItem( label )
	label:SetText( "Concmd whitelist" )
	label:SizeToContents()

	local ConcmdWhitelist = vgui.Create( "DTextEntry" )
	dlist:AddItem( ConcmdWhitelist )
	ConcmdWhitelist:SetConVar( "wire_expression2_concmd_whitelist" )
	ConcmdWhitelist:SetToolTip( "Separate the commands with commas." )

	local FriendWrite = vgui.Create( "DCheckBoxLabel" )
	dlist:AddItem( FriendWrite )
	FriendWrite:SetConVar( "wire_expression2_friendwrite" )
	FriendWrite:SetText( "Friend Write" )
	FriendWrite:SizeToContents()
	FriendWrite:SetTooltip( "Allow/disallow people in your prop protection friends list from reading and writing to your E2s." )

	local label = vgui.Create("DLabel")
	dlist:AddItem( label )
	label:SetText( "Expression 2 block comment style" )
	label:SizeToContents()

	local BlockCommentStyle = vgui.Create( "DMultiChoice" )
	dlist:AddItem( BlockCommentStyle )

	local modes = {}
	modes["New (alt 1)"] = { 0, [[Current mode:
#[
Text here
Text here
]#]] }
	modes["New (alt 2)"] = { 1, [[Current mode:
#[Text here
Text here]# ]] }
	modes["Old"] 		 = { 2, [[Current mode:
#Text here
#Text here]] }

	for k,v in pairs( modes ) do
		BlockCommentStyle:AddChoice( k )
	end

	modes[0] = modes["New (alt 1)"][2]
	modes[1] = modes["New (alt 2)"][2]
	modes[2] = modes["Old"][2]
	BlockCommentStyle:SetEditable( false )
	BlockCommentStyle:SetToolTip( modes[self.BlockCommentStyleConVar:GetInt()] )

	BlockCommentStyle.OnSelect = function( panel, index, value )
		panel:SetToolTip( modes[value][2] )
		RunConsoleCommand( "wire_expression2_editor_block_comment_style", modes[value][1] )
	end

	-- SYNTAX HIGHLIGHT COLORS

	local Label = vgui.Create( "DLabel" )
	dlist:AddItem( Label )
	Label:SetText( "Expression 2 syntax highlighting colors" )
	Label:SizeToContents()

	local SkipUpdate = false
	local CurrentColor = "directive"
	local r, g, b = 255,255,255

	local temp = vgui.Create("Panel")
	dlist:AddItem( temp )
	temp:SetTall( 132 )

	-- Create color mixer, number wangs, default button, and drop down menu
	local ColorMixer = vgui.Create( "DColorMixer", temp )
	local RBox = vgui.Create( "DNumberWang", temp )
    local GBox = vgui.Create( "DNumberWang", temp )
    local BBox = vgui.Create( "DNumberWang", temp )
	local DefaultButton = vgui.Create( "DButton", temp )
	local CurrentColorSelect = vgui.Create( "DMultiChoice", temp )

	-- Add choices
	for k,v in pairs( colors ) do
		CurrentColorSelect:AddChoice( k )
	end
	-- Manage choices
	CurrentColorSelect.OnSelect = function( panel, index, value )
		CurrentColor = value
		ColorMixer:SetColor( colors[value] )
		r = colors[value].r
		g = colors[value].g
		b = colors[value].b
		RBox:SetValue( r )
		GBox:SetValue( g )
		BBox:SetValue( b )
	end
	CurrentColorSelect:SetEditable( false )

	-- Default button
	DefaultButton.DoClick = function( pnl )
		ColorMixer:SetColor( colors_defaults[CurrentColor] )
		r = colors_defaults[CurrentColor].r
		g = colors_defaults[CurrentColor].g
		b = colors_defaults[CurrentColor].b
		RBox:SetValue( r )
		GBox:SetValue( g )
		BBox:SetValue( b )
		self:SetSyntaxColor( CurrentColor, colors_defaults[CurrentColor] )
	end

	DefaultButton:SetText("Default")

	ColorMixer:SetSize( 130,130 )
	--ColorMixer:SetPos( 170, 205 )

	-- Remove alpha bar
    ColorMixer.AlphaBar:SetVisible( false )
    ColorMixer.PerformLayout = function( pnl )
		local w,h = pnl:GetSize()
		pnl.RGBBar:SetPos( 0, 0 )
		pnl.RGBBar:SetSize( 20, h )
		pnl.ColorCube:SetPos( 22, 0 )
		pnl.ColorCube:SetSize( w - 22, h )
    end

	local old = ColorMixer.ColorCube.OnMouseReleased
	ColorMixer.ColorCube.OnMouseReleased = function( ... )
		local clr = ColorMixer:GetColor()
		r, g, b = clr.r, clr.g, clr.b
		SkipUpdate = true
		RBox:SetValue( r )
		GBox:SetValue( g )
		BBox:SetValue( b )
		SkipUpdate = false
		self:SetSyntaxColor( CurrentColor, clr )
		old( ... )
	end

	local old = ColorMixer.RGBBar.OnMouseReleased
	ColorMixer.RGBBar.OnMouseReleased = function(...)
		ColorMixer.ColorCube:OnMouseReleased()
		old(...)
	end

	-- Loop this to make it a little neater
	local temp = { RBox, GBox, BBox }
	for k,v in pairs( temp ) do
		v:SetValue( 255 )
		v:SetMin( 0 )
		v:SetMax( 255 )
		v:SetDecimals( 0 )
		v:SetWide( 64 )
		local old = v:GetTextArea().OnEnter
		v:GetTextArea().OnEnter = function( ... )
			v:OnValueChanged()
			old( ... )
		end
	end

	-- OnValueChanged functions
	RBox.OnValueChanged = function( pnl )
		if (SkipUpdate or r == pnl:GetValue()) then return end
		r = pnl:GetValue()
		ColorMixer:SetColor( Color(r,g,b) )
		self:SetSyntaxColor( CurrentColor, Color(r,g,b) )
	end
	GBox.OnValueChanged = function( pnl )
		if (SkipUpdate or g == pnl:GetValue()) then return end
		g = pnl:GetValue()
		ColorMixer:SetColor( Color(r,g,b) )
		self:SetSyntaxColor( CurrentColor, Color(r,g,b) )
	end
	BBox.OnValueChanged = function( pnl )
		if (SkipUpdate or b == pnl:GetValue()) then return end
		b = pnl:GetValue()
		ColorMixer:SetColor( Color(r,g,b) )
		self:SetSyntaxColor( CurrentColor, Color(r,g,b) )
	end

	-- Positioning
	local x,y = ColorMixer:GetPos()
	local w,_ = ColorMixer:GetSize()
	CurrentColorSelect:SetPos( x + w + 2, y )
	RBox:SetPos( x + w + 2, y + 2 + 20 )
	GBox:SetPos( x + w + 2, y + 4 + RBox:GetTall() + 20 )
	BBox:SetPos( x + w + 2, y + 6 + RBox:GetTall() * 2 + 20 )
	DefaultButton:SetPos( x + w + 2, y + 8 + RBox:GetTall() * 3 + 20 )
	DefaultButton:SetSize( RBox:GetSize() )
end

function Editor:CalculateColor()
	self.colors.col_FL.r = math.floor(self.colors.tmp_FL.r*self.colors.tmp_Dark/255)
	self.colors.col_FL.g = math.floor(self.colors.tmp_FL.g*self.colors.tmp_Dark/255)
	self.colors.col_FL.b = math.floor(self.colors.tmp_FL.b*self.colors.tmp_Dark/255)

	self.colors.col_FR.r = math.floor(self.colors.tmp_FR.r*self.colors.tmp_Dark/255)
	self.colors.col_FR.g = math.floor(self.colors.tmp_FR.g*self.colors.tmp_Dark/255)
	self.colors.col_FR.b = math.floor(self.colors.tmp_FR.b*self.colors.tmp_Dark/255)

	self:InvalidateLayout()
end

// used with color-circles
function Editor:TranslateValues(panel, x, y )
	x = x - 0.5
	y = y - 0.5
	local angle = math.atan2( x, y )
	local length = math.sqrt( x*x + y*y )
	length = math.Clamp( length, 0, 0.5 )
	x = 0.5 + math.sin( angle ) * length
	y = 0.5 + math.cos( angle ) * length
	panel:SetHue( math.Rad2Deg( angle ) + 270 )
	panel:SetSaturation( length * 2 )
	panel:SetRGB( HSVToColor( panel:GetHue(), panel:GetSaturation(), 1 ) )
	panel:SetFrameColor()
	return x, y
end
// options

-- code1 contains the code that is not to be marked
local code1 = "@name \n@inputs \n@outputs \n@persist \n@trigger \n\n"
-- code2 contains the code that is to be marked, so it can simply be overwritten or deleted.
local code2 = [[#[
    The options menu has been redesigned - it's much more
    organized now.

    Auto completion has been added!
    Options for it can be found in the options menu.

    Syntax highlighting color options have been added in the
    options menu.

    Documentation and examples are available at:
    http://wiki.garrysmod.com/?title=Wire_Expression2
    The community is available at http://www.wiremod.com
]#]]
local defaultcode = code1 .. code2

function Editor:NewScript( incurrent )
	if (!incurrent and self.NewTabOnOpen:GetBool()) then
		self:NewTab()
	else
		self:AutoSave()
		self:ChosenFile()

		-- Set title
		self:GetActiveTab():SetText( "generic" )
		self.C['TabHolder'].panel:InvalidateLayout()

		if (self.E2) then
			-- add both code1 and code2 to the editor
			self:SetCode(defaultcode)
			local ed = self:GetCurrentEditor()
			-- mark only code2
			ed.Start = ed:MovePosition({ 1, 1 }, code1:len())
			ed.Caret = ed:MovePosition({ 1, 1 }, defaultcode:len())
		end

	end
end

local id = 0
function Editor:InitShutdownHook()
	id = id + 1

	-- save code when shutting down
	hook.Add("ShutDown", "wire_expression2_ShutDown"..id, function()
		--if wire_expression2_editor == nil then return end
		local buffer = self:GetCode()
		if buffer == defaultcode then return end
		file.Write(self.Location .. "/_shutdown_.txt", buffer)
	end)
end

local chipmap = {
	E2 = "wire_expression2_validate",
	CPU = "wire_cpu_validate",
	GPU = "wire_cpu_validate",
}

function Editor:Validate(gotoerror)
	local validator = chipmap[self.EditorType]
	if not validator then return end
	validator = _G[validator]
	if not validator then return end

	self:ExtractName()
	local errors = validator(self:GetCode())
	if not errors then
		self.C['Val'].panel:SetBGColor(0, 128, 0, 180)
		self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
		self.C['Val'].panel:SetText( "   Validation successful" )
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
	self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
	self.C['Val'].panel:SetText( "   " .. errors )
	return false
end

function Editor:SetValidatorStatus( text, r,g,b,a )
	self.C['Val'].panel:SetBGColor( r or 0,g or 180,b or 0,a or 180 )
	self.C['Val'].panel:SetText( "   " .. text )
end

function Editor:SubTitle(sub)
	if(!sub) then self.subTitle = ""
	else self.subTitle = " - " .. sub end
end

function Editor:SetV(bool)
	if(bool) then
		self:MakePopup()
		self:SetVisible(true)
		self:InvalidateLayout(true)
		self:SetKeyBoardInputEnabled(true)
		self:Validate()
	else
		self:SetVisible(false)
		self:SetKeyBoardInputEnabled()
	end
	if CanRunConsoleCommand() then RunConsoleCommand("wire_expression2_event", bool and "editor_open" or "editor_close") end
end

function Editor:GetChosenFile()
	return self:GetCurrentEditor().chosenfile
end

function Editor:ChosenFile(Line)
	self:GetCurrentEditor().chosenfile = Line
	if(Line) then
		self:SubTitle("Editing: " .. Line)
	else
		self:SubTitle()
	end
end

function Editor:FindOpenFile( FilePath )
	for i=1,self:GetNumTabs() do
		local ed = self:GetEditor(i)
		if (ed.chosenfile == FilePath) then
			return ed
		end
	end
end

function Editor:ExtractName()
	if(!self.E2) then self.savefilefn = "filename" return end
	local code = self:GetCode()
	local name = extractNameFromCode( code )
	if (name and name != "") then
		Expression2SetName( name )
		self.savefilefn = name
	else
		Expression2SetName(nil)
		self.savefilefn = "filename"
	end
end

function Editor:SetCode(code)
	self:GetCurrentEditor():SetText(code)
	self.savebuffer = self:GetCode()
	self:Validate()
	self:ExtractName()
end

function Editor:GetEditor( n )
	return self.C['TabHolder'].panel.Items[ n ].Panel
end

function Editor:GetCurrentEditor()
	return self:GetActiveTab():GetPanel()
end

function Editor:GetCode()
	return self:GetCurrentEditor():GetValue()
end

function Editor:Open(Line,code,forcenewtab)
	if(self:IsVisible() and !Line and !code) then self:Close() end
	self:SetV(true)
	if(code) then
		if (!forcenewtab) then
			for i=1, self:GetNumTabs() do
				if (self:GetEditor(i).chosenfile == Line) then
					self:SetActiveTab( i )
					self:SetCode( code )
					return
				elseif (self:GetEditor(i):GetValue() == code) then
					self:SetActiveTab( i )
					return
				end
			end
		end
		local title, tabtext = getPreferredTitles( Line, code )
		local tab
		if (self.NewTabOnOpen:GetBool() or forcenewtab) then
			tab = self:CreateTab( tabtext ).Tab
		else
			tab = self:GetActiveTab()
			tab:SetText( tabtext )
			self.C['TabHolder'].panel:InvalidateLayout()
		end
		self:SetActiveTab( tab )

		self:ChosenFile()
		self:SetCode(code)
		if(Line) then self:SubTitle("Editing: " .. Line) end
		return
	end
	if(Line) then self:LoadFile(Line, forcenewtab) return end
end

function Editor:SaveFile(Line, close, SaveAs)
	self:ExtractName()
	if(close and self.chip) then
		if(!self:Validate(true)) then return end
		wire_expression2_upload()
		self:Close()
		return
	end
	if(!Line or SaveAs or Line == self.Location .. "/" .. ".txt") then
		local str
		if (self.C['Browser'].panel.File) then
			str = self.C['Browser'].panel.File.FileDir -- Get FileDir
			if (str and str != "") then -- Check if not nil

				-- Remove "Expression2/" or "CPU/" etc
				local n, _ = str:find( "/", 1, true )
				str = str:sub( n+1, -1 )

				if (str and str != "") then -- Check if not nil
					if (str:Right(4) == ".txt") then -- If it's a file
						str = string.GetPathFromFilename( str ):Left(-2) -- Get the file path instead
						if (!str or str == "") then
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
		Derma_StringRequestNoBlur( "Save to New File", "", (str != nil and str .. "/" or "" ) .. self.savefilefn,
		function( strTextOut )
			strTextOut = string.gsub(strTextOut, ".", invalid_filename_chars)
			self:SaveFile( self.Location .. "/" .. strTextOut .. ".txt", close )
		end )
		return
	end

	file.Write(Line, self:GetCode())

	local panel = self.C['Val'].panel
	timer.Simple(0,panel.SetText, panel, "   Saved as "..Line)
	surface.PlaySound("ambient/water/drip3.wav")

	if(!self.chip) then self:ChosenFile(Line) end
	if(close) then
		GAMEMODE:AddNotify( "Expression saved as "..Line..".", NOTIFY_GENERIC, 7 )
		self:Close()
	end
end

function Editor:LoadFile( Line, forcenewtab )
	if(!Line or file.IsDir( Line )) then return end
	local str = file.Read(Line)
	if str == nil then
		Error("ERROR LOADING FILE!")
	else
		self:AutoSave()
		if (!forcenewtab) then
			for i=1, self:GetNumTabs() do
				if (self:GetEditor(i).chosenfile == Line) then
					self:SetActiveTab( i )
					self:SetCode( str )
					return
				elseif (self:GetEditor(i):GetValue() == str) then
					self:SetActiveTab( i )
					return
				end
			end
		end
		if(!self.chip) then
			local title, tabtext = getPreferredTitles( Line, str )
			local tab
			if (self.NewTabOnOpen:GetBool() or forcenewtab) then
				tab = self:CreateTab( tabtext ).Tab
			else
				tab = self:GetActiveTab()
				tab:SetText( tabtext )
				self.C['TabHolder'].panel:InvalidateLayout()
			end
			self:SetActiveTab( tab )
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
end

function Editor:Setup(nTitle, nLocation, nEditorType)
	self.Title = nTitle
	self.Location = nLocation
	self.EditorType = nEditorType
	self.C['Browser'].panel:Setup(nLocation)
	if(!nEditorType) then
		-- Remove syntax highlighting
		local func = function(self, row) return {{self.Rows[row], { Color(255, 255, 255, 255), false}}} end
		self:SetSyntaxColorLine( func )

		-- Remove validation line
		self.C['TabHolder'].h = -10
		self.C['Val'].panel:SetVisible(false)
	elseif nEditorType == "CPU" or nEditorType == "GPU" then
		-- Set syntax highlighting
		local func = self:GetCurrentEditor().CPUGPUSyntaxColorLine
		self:SetSyntaxColorLine( func )

		-- Add "E2Helper" button
		local E2Help = self:addComponent(vgui.Create("Button", self), -180, 30, -125, 20)
		E2Help.panel:SetText("")
		E2Help.panel.Font = "E2SmallFont"
		E2Help.panel.Paint = function(button)
			local w,h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos( 3, 4 )
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.DrawText("  E2Helper")
		end
		E2Help.panel.DoClick = function()
			E2Helper.Show()
			E2Helper.CPUMode:Toggle()
			E2Helper.CostColumn:SetName("Type")
			E2Helper.ReturnsColumn:SetName("For What")
			E2Helper.ReturnEntry:SetText(nEditorType)
			E2Helper.Update()
		end
		self.C.E2Help = E2Help

		-- insert default code
		local code = "// "..nEditorType.." Syntax Higlighting \n// By -HP-"
		self:SetCode(code)

		-- mark all code
		local ed = self:GetCurrentEditor()
		ed.Start = ed:MovePosition({ 1, 1 }, 0)
		ed.Caret = ed:MovePosition({ 1, 1 }, code:len())
	elseif nEditorType == "E2" then
		-- Add "E2Helper" button
		local E2Help = self:addComponent(vgui.Create("Button", self), -180, 30, -125, 20)
		E2Help.panel:SetText("")
		E2Help.panel.Font = "E2SmallFont"
		E2Help.panel.Paint = function(button)
			local w,h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos( 3, 4 )
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.DrawText("  E2Helper")
		end
		E2Help.panel.DoClick = function()
			E2Helper.Show()
			E2Helper.E2Mode:Toggle()
			local val = E2Helper.ReturnEntry:GetValue()
			if (val and (val == "CPU" or val == "GPU")) then E2Helper.ReturnEntry:SetText("") end
			E2Helper.CostColumn:SetName("Cost")
			E2Helper.ReturnsColumn:SetName("Returns")
			E2Helper.Update()
		end
		self.C.E2Help = E2Help

		-- Add "Sound Browser" button
		local SoundBrw = self:addComponent(vgui.Create("Button", self), -262, 30, -182, 20)
		SoundBrw.panel:SetText("")
		SoundBrw.panel.Font = "E2SmallFont"
		SoundBrw.panel.Paint = function(button)
			local w,h = button:GetSize()
			draw.RoundedBox(1, 0, 0, w, h, self.colors.col_FL)
			if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
			surface.SetFont(button.Font)
			surface.SetTextPos( 3, 4 )
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.DrawText("  Sound Browser")
		end
		SoundBrw.panel.DoClick = function() RunConsoleCommand("wire_sound_browser_open") end
		self.C.SoundBrw = SoundBrw

		-- Flag as E2
		self.E2 = true
		self:NewScript( true )
	end
	self:InvalidateLayout()
end


vgui.Register( "Expression2EditorFrame" , Editor , "DFrame" )
