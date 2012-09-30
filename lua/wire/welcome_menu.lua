------------------------------------------------------------------------------------------------
-- Wiremod Community Welcome & Information Popup
-- This makes a popup appear when you spawn in a server, containing information about wiremod.
-- Made by Divran
------------------------------------------------------------------------------------------------

local WireLib = WireLib
WireLib.WelcomeMenu = {}
local Menu = WireLib.WelcomeMenu

if (SERVER) then

	resource.AddFile("materials/gui/silkicons/help.vmt")

	-- Open the menu on spawn
	hook.Add("PlayerInitialSpawn","Wire_Welcome_Popup",function(ply)
		timer.Simple(5,function()
			if (ply and ply:IsValid()) then -- Sometimes the player crashes
				ply:ConCommand("Wire_Welcome_Menu 1337") -- "1337" is to let the client know that the server is the one requesting it, and not the player.
			end
		end)
	end)

end

if (CLIENT) then

	local function CreateCPanel( Panel )
		Panel:ClearControls()
		Panel:AddHeader()

		local lbl =  vgui.Create("DLabel")
		lbl:SetText([[You can also open the menu using the console command:
'Wire_Welcome_Menu']])
		lbl:SizeToContents()
		Panel:AddItem( lbl )

		local btn = vgui.Create("DButton")
		btn:SetText("Open Welcome Menu")
		function btn:DoClick()
			Menu:OpenMenu()
		end
		Panel:AddItem( btn )
	end

	hook.Add("PopulateToolMenu","WireLib_WMenu_PopulateToolMenu",function()
		spawnmenu.AddToolMenuOption( "Wire", "Administration", "WMenu", "Welcome Menu", "", "", CreateCPanel, nil )
	end)

	-- Helper function
	local function filterversion( version )
		if (type(version) == "number") then return version elseif (type(version) != "string") then return 0 end
		version = version:gsub( "[^%d]+", "" )
		return tonumber(version) or 0
	end

	Menu.ConVars = {}
	Menu.ConVars.Blocked = CreateClientConVar("Wire_Welcome_Menu_Blocked","0",true,false)
	Menu.ConVars.UpdateNotificationBlocked = CreateClientConVar("Wire_Welcome_Menu_HideUpdateNotification","1",true,false) --quick fix because the update notification is not closeable
	Menu.Menu = {}

	------------------------------------------------------------------------------------------------
	-- Update Notification
	-- These few functions create and take care of the update notification menu,
	-- which will notify the user if there is an update to Wiremod, as well as provide a link to see what's new.
	------------------------------------------------------------------------------------------------

	Menu.UpdateNotification = {}
	local UN = Menu.UpdateNotification
	function UN:CreateMenu()
		local pnl = vgui.Create("DFrame")
		self.Panel = pnl
		function pnl:Paint()
			draw.RoundedBox( 4, 0,0,self:GetWide(),self:GetTall(), Menu.Colors.BGColor  )
		end
		pnl:SetSize( 219, 152 )
		pnl:SetPos( 100, ScrH() / 2 - pnl:GetTall() / 2 )
		pnl:SetDraggable( true )
		pnl:SetScreenLock( true )
		pnl:SetDeleteOnClose( false )
		pnl:ShowCloseButton( false ) -- We want to create our own close button
		--pnl:MakePopup()
		pnl:SetVisible( false )
		pnl:SetTitle( "WireMod Update Notification" )

		local txt = vgui.Create("Wire_WMenu_Label",pnl)
		txt:SetText([[You are using an older version of
Wiremod. Please update your SVN.


Tip: Open the context menu (default 'C')
to enable the cursor.]] )
		txt:SizeToContents()
		txt:SetPos( 4, 24 )
		UN.txt = txt
		Menu:AddColoring( txt.SetColor, txt )

		local btn = vgui.Create("Wire_WMenu_Button",pnl)
		btn:SetSize( 104, 20 )
		btn:SetPos( 4, pnl:GetTall()-24 )
		btn:SetText("OK")
		function btn:DoClick()
			UN:CloseMenu()
		end

		local btn = vgui.Create("Wire_WMenu_Button",pnl)
		btn:SetSize( 104, 20 )
		btn:SetPos( 111, pnl:GetTall()-24 )
		btn:SetText("What's new?")
		function btn:DoClick()
			gui.OpenURL("http://www.wiremod.com/forum/wiremod-svn-log/")
			UN:CloseMenu()
		end

		local hide = vgui.Create("DCheckBoxLabel",pnl)
		hide:SetText("Don't show this notification again." )
		hide:SetToolTip("This can also be changed in the options tab of the Wire Welcome Menu.\nType 'Wire_Welcome_Menu' into console to open it.")
		hide:SizeToContents()
		hide:SetConVar("Wire_Welcome_Menu_HideUpdateNotification")
		hide:SetPos( 4, pnl:GetTall()-42 )
	end

	function UN:OpenMenu(version,onlineversion)
		if (!UN.Panel) then
			UN:CreateMenu()
		end
		UN.Panel:SetVisible( true )
		UN.txt:SetText([[You are using an older version of
Wiremod. Please update your SVN.
Your version: ]] .. version .. [[

Latest version: ]] .. onlineversion .. [[

Tip: Open the context menu (default 'C')
to enable the cursor.]] )
	end

	function UN:CloseMenu()
		UN.Panel:SetVisible( false )
	end

	function UN:ClientHasBlocked()
		return Menu.ConVars.UpdateNotificationBlocked:GetBool()
	end

	UN.NotifiedVersion = 0
	function UN:CheckForUpdate()
		if (self:ClientHasBlocked()) then return end
		local version = filterversion(WireLib.LocalVersion)
		WireLib.GetOnlineWireVersion(function(onlineversion)
			if (version and onlineversion and version < onlineversion and self.NotifiedVersion < onlineversion) then
				self.NotifiedVersion = onlineversion
				self:OpenMenu(version,onlineversion)
			end
		end)
	end

	timer.Simple(60,function() -- 60 second run the first time, 10 minutes after that.
		UN:CheckForUpdate()
		timer.Create("Wire_UpdateNotification_Timer",600,0,function() UN:CheckForUpdate()  end)
	end)

	------------------------------------------------------------------------------------------------
	-- Open the menu
	-- Use these functions if you want to manually open or close the menu, without using the console command
	------------------------------------------------------------------------------------------------

	-- Opens the welcome menu
	function Menu:OpenMenu()
		if (!self.Menu or !self.Menu.Panel) then self:CreateMenu() end
		self.Menu.Panel:SetVisible( true )
		local CurTab = self:GetCurrentTab()
		self:SizeTo( CurTab.W, CurTab.H, nil )
		Menu._IsOpen = true
	end

	-- Closes the welcome menu
	function Menu:CloseMenu()
		if (!self.Menu or !self.Menu.Panel) then return end
		local bool = self:SizeTo( 0, 0, nil, function() self.Menu.Panel:SetVisible( false ) end )
		if (bool == false) then -- Size function failed, force close
			self.Menu.Panel:SetVisible( false )
		end
		Menu._IsOpen = false
	end

	-- Returns true if the client has blocked the welcome menu
	function Menu:ClientHasBlocked()
		return Menu.ConVars.Blocked:GetBool()
	end

	Menu._IsOpen = false

	-- Returns true if the menu is open, else false
	function Menu:IsOpen()
		return self._IsOpen
	end

	concommand.Add("Wire_Welcome_Menu",function(ply,cmd,args)
		if (args[1] and args[1] == "1337") then -- The server requested it, check if the client has blocked the popup
			if (Menu:ClientHasBlocked()) then return end -- The client has blocked the popup.
		end
		Menu:OpenMenu()
	end)

	------------------------------------------------------------------------------------------------
	-- Load colors
	-- This function is called automatically, and you should not need to call it.
	-- Arguments: None
	------------------------------------------------------------------------------------------------

	Menu.ConVars.BGColor 			= CreateClientConVar("Wire_Welcome_Menu_Colors_BGColor","25_25_25_255",true,false)
	Menu.ConVars.ButtonColor 		= CreateClientConVar("Wire_Welcome_Menu_Colors_ButtonColor","75_75_75_255",true,false)
	Menu.ConVars.ButtonHoverColor	= CreateClientConVar("Wire_Welcome_Menu_Colors_ButtonHoverColor","100_100_100_255",true,false)
	Menu.ConVars.ButtonClickColor	= CreateClientConVar("Wire_Welcome_Menu_Colors_ButtonClickColor","150_150_150_255",true,false)
	Menu.ConVars.LabelBGColor		= CreateClientConVar("Wire_Welcome_Menu_Colors_LabelBGColor","150_150_150_210",true,false)
	Menu.ConVars.TextColor 			= CreateClientConVar("Wire_Welcome_Menu_Colors_TextColor","0_0_0_255",true,false)

	-- Default Colors
	Menu.Colors = {}
	Menu.Colors.BGColor = Color(25,25,25,255)
	Menu.Colors.ButtonColor = Color(75,75,75,255)
	Menu.Colors.ButtonHoverColor = Color(100,100,100,255)
	Menu.Colors.ButtonClickColor = Color(150,150,150,255)
	Menu.Colors.LabelBGColor = Color( 150,150,150,210)
	Menu.Colors.TextColor = Color(0,0,0,255)
	Menu.ColorDefaults = table.Copy(Menu.Colors)

	Menu.ItemsToBeColored = {}

	function Menu:LoadColors()
		for k,v in pairs( self.Colors ) do
			local cvar = self.ConVars[k]:GetString()
			local r,g,b,a = string.match( cvar, "(%d+)%_(%d+)%_(%d+)%_(%d+)" )
			local clr = Color(r,g,b,a)
			self.Colors[k] = clr
		end
	end

	function Menu:ApplyColors(ignore)
		ignore = ignore or {}
		for k,v in ipairs( self.ItemsToBeColored ) do
			if (ignore[k] != true) then
				local ColorType = v[2]
				if (ColorType) then
					local clr = self.Colors[ColorType]
					if (clr) then
						v[1](v[3],clr)
					end
				end
			end
		end
	end

	function Menu:AddColoring( Func, ColorType, ... )
		local id = #self.ItemsToBeColored+1
		self.ItemsToBeColored[id] = { Func, ColorType, ... }
		return id
	end

	------------------------------------------------------------------------------------------------
	-- Create the menu
	-- This function is called automatically, and you should not need to call it.
	-- Arguments: None
	------------------------------------------------------------------------------------------------

	function Menu:CreateMenu()

		-- Sizes
		self.Menu.Sizes = {}
		self.Menu.Sizes.CurrentWidth = 0
		self.Menu.Sizes.CurrentHeight = 0
		self.Menu.Sizes.TargetWidth = 500
		self.Menu.Sizes.TargetHeight = 500
		self.Menu.Sizes.CurrentRate = 20
		self.Menu.Sizes.DefaultRate = 20
		self.Menu.Sizes.DefaultWidth = 500
		self.Menu.Sizes.DefaultHeight = 500

		local pnl = vgui.Create("DFrame")
		self.Menu.Panel = pnl
		function pnl:Paint()
			draw.RoundedBox( 4, 0,0,self:GetWide(),self:GetTall(), Menu.Colors.BGColor  )
		end
		pnl:SetSize( 0, 0 )
		pnl:SetPos( ScrW() / 2 - self.Menu.Sizes.DefaultWidth / 2, ScrH() / 2 - self.Menu.Sizes.DefaultHeight / 2 )
		pnl:SetDraggable( true )
		pnl:SetScreenLock( true )
		pnl:SetDeleteOnClose( false )
		pnl:ShowCloseButton( false ) -- We want to create our own close button
		pnl:MakePopup()
		pnl:SetVisible( false )
		pnl:SetTitle( "Wiremod Welcome and Information Menu" )

		local psheet = vgui.Create("DPropertySheet",pnl)
		self.Menu.TabHolder = psheet

		local cbox = vgui.Create("DCheckBoxLabel",pnl)
		self.Menu.BlockCheck = cbox
		cbox:SetConVar( "Wire_Welcome_Menu_Blocked" )
		cbox:SetText( "Don't show this menu again." )
		cbox:SizeToContents()

		local cbtn = vgui.Create("Wire_WMenu_Button",pnl)
		self.Menu.CloseButton = cbtn
		cbtn:SetText( "Close" )
		cbtn:SetSize( 100, 20 )
		cbtn.DoClick = function()
			self:CloseMenu()
		end

		hook.Call("Wire_WMenu_AddTabs",Menu,Menu)
		self:Scale()

		timer.Simple(0.5,function()
			self:LoadColors()
			self:ApplyColors()
		end)
	end

	------------------------------------------------------------------------------------------------
	-- Set Positions
	-- This function is called automatically, and you should not need to call it.
	-- Arguments: None
	------------------------------------------------------------------------------------------------

	function Menu:Scale()
		local w,h = self.Menu.Sizes.CurrentWidth, self.Menu.Sizes.CurrentHeight

		-- Panel
		self.Menu.Panel:SetSize( w, h )

		local x, y = self.Menu.Panel:GetPos()
		if (x + w > ScrW()) then
			x = ScrW() - w
		end
		if (y + h > ScrH()) then
			y = ScrH() - h
		end
		self.Menu.Panel:SetPos( x, y )

		-- TabHolder
		self.Menu.TabHolder:StretchToParent( 2, 23, 4, 30 )

		-- CheckBox
		self.Menu.BlockCheck:SetPos( 6, h - 23 )

		-- CloseButton
		self.Menu.CloseButton:SetPos( w - 105, h - 25 )
	end

	------------------------------------------------------------------------------------------------
	-- SizeTo
	-- Animates the menu. This function is called automatically, and you should not need to call it.
	-- If any of the arguments are nil, the function assumes default values.
	-- Arguments: Target Width, Target Height, Rate, Callback (this function is called once the resize is complete)
	------------------------------------------------------------------------------------------------

	Menu._IsResizing = false

	function Menu:IsResizing()
		return self._IsResizing
	end

	-- SizeTo's think
	timer.Create("Wire_WMenu_Think",0.01,0,function()
	--hook.Add("Tick","Wire_WMenu_Think",function()
		if (!Menu:IsResizing()) then return end -- Only run if the menu is resizing
		local self = Menu.Menu.Sizes

		if (!self.TargetWidth or !self.TargetHeight or
			!self.CurrentHeight or !self.CurrentWidth) then
			return
		else
			local DoScale = false
			if (self.CurrentHeight != self.TargetHeight) then
				self.CurrentHeight = self.CurrentHeight + math.Clamp( self.TargetHeight - self.CurrentHeight, -self.CurrentRate, self.CurrentRate )
				DoScale = true
			end
			if (self.CurrentWidth != self.TargetWidth) then
				self.CurrentWidth = self.CurrentWidth + math.Clamp( self.TargetWidth - self.CurrentWidth, -self.CurrentRate, self.CurrentRate )
				DoScale = true
			end
			if (DoScale) then
				Menu:Scale()
				hook.Call("Wire_WMenu_Scale",Menu,Menu,self.CurrentWidth,self.CurrentHeight)
			else
				if (Menu._CallbackFunc) then
					Menu._CallbackFunc()
				end
				hook.Call("Wire_WMenu_Scale",Menu,Menu,self.CurrentWidth,self.CurrentHeight)
				hook.Call("Wire_WMenu_ScaleComplete",Menu,Menu,self.CurrentWidth,self.CurrentHeight)
				Menu._IsResizing = false
			end
		end
	end)

	function Menu:SizeTo( Width, Height, Rate, Callback )
		if (self:IsResizing()) then return false end

		Rate = Rate or self.Menu.Sizes.DefaultRate
		Width = Width or self.Menu.Sizes.DefaultWidth
		Height = Height or self.Menu.Sizes.DefaultHeight

		if (self.CurrentHeight == Height and self.CurrentWidth == Width) then return false end

		self.Menu.Sizes.TargetWidth = Width
		self.Menu.Sizes.TargetHeight = Height
		self.Menu.Sizes.CurrentRate = Rate

		self._IsResizing = true

		self._CallbackFunc = Callback
	end

	------------------------------------------------------------------------------------------------
	-- Add Tab
	-- Use this function to add tabs to the menu
	-- Arguments: Tab Name, Panel object, gui Icon, Tab Description, DrawPanel Bool (if false, override paint to stop the panel from being drawn)
	------------------------------------------------------------------------------------------------

	Menu.Tabs = {}
	Menu.CurrentTab = 1

	function Menu:AddTab( Name, Panel, Icon, Description, DrawPanel, W, H )
		if (!Name or !Panel) then return end

		if (DrawPanel == false) then
			Panel.Paint = function() end
		end

		local Sheet = self.Menu.TabHolder:AddSheet( Name, Panel, Icon, false, false, Description )

		local n = #self.Tabs+1

		local OldFunc = Sheet.Tab.OnMousePressed
		function Sheet.Tab:OnMousePressed(...)
			if (!Menu:IsResizing()) then
				Menu:SizeTo( Menu.Tabs[n].W, Menu.Tabs[n].H )
				Menu.CurrentTab = n
				OldFunc(self,...)
			end
		end
		Sheet.Tab.n = n
		function Sheet.Tab:Paint()
			local clr = Menu.Colors.ButtonColor
			if (n == Menu.CurrentTab) then
				clr = Menu.Colors.ButtonHoverColor
			end
			draw.RoundedBox( 4, 0,0,self:GetWide(),self:GetTall(),clr)
		end

		self.Tabs[n] = { W = W, H = H, Name = Name, Panel = Panel, Sheet = Sheet }

		return n, self.Tabs[n]
	end

	function Menu:GetCurrentTab()
		return self.Tabs[self.CurrentTab]
	end

	------------------------------------------------------------------------------------------------
	-- Add the default tabs
	-- Use a hook like this to add tabs to the menu
	------------------------------------------------------------------------------------------------


	local e2tex = surface.GetTextureID( "expression 2/cog" )
	local function e2paint(self)
		local w,h = self:GetWide(),self:GetTall()

		surface.SetDrawColor(25,25,25,255)
		surface.DrawRect(0,0,w,h)

		surface.SetDrawColor(150,34,34,255)
		surface.SetTexture(e2tex)

		surface.DrawTexturedRectRotated(256,256, 455, 455, RealTime() * 10)
		surface.DrawTexturedRectRotated(30, 30,227.5, 227.5, RealTime() * -20 + 12.5)
	end

	local wirelogotex = surface.GetTextureID( "wirelogo" )
	local function wirepaint(self)
		local w,h = self:GetWide(),self:GetTall()

		surface.SetDrawColor(25,25,25,255)
		surface.DrawRect(0,0,w,h)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(wirelogotex)

		surface.DrawTexturedRectRotated( w/2, h/2, 256*1.3,64*1.3,0 )
	end

	hook.Add("Wire_WMenu_AddTabs","DefaultTabs",function( self )

		------------------------------------------------------------------------------------------------
		-- Welcome Tab
		------------------------------------------------------------------------------------------------
		local pnl = vgui.Create("DPanel")
		pnl.Paint = wirepaint
		local txt = vgui.Create("Wire_WMenu_Label",pnl)
		txt:SetText([[Welcome! This server is running Wiremod.
This menu is a welcome screen and advertisement for Wiremod,
as well as a centre for support and tutorials.

If you wish to open this menu again after checking the
checkbox below to block it, use the command
'Wire_Welcome_Menu'
in console.]] )
		txt:SizeToContents()
		txt:SetPos( 90, 53 )
		self:AddColoring( txt.SetColor, txt )

		hook.Add("Wire_WMenu_Scale","Default_Scale_1",function(self, W, H)
			if (self:GetCurrentTab().Name == "Welcome") then
				txt:Center()
			end
		end)

		self:AddTab( "Welcome", pnl, "gui/silkicons/emoticon_smile", nil, true, 500, 300 )

		------------------------------------------------------------------------------------------------
		-- Help and Support tab
		------------------------------------------------------------------------------------------------
		local pnl = vgui.Create("DPanel")
		pnl.Paint = e2paint
		local index, info = self:AddTab( "Help and Support", pnl, "gui/silkicons/help", "Find answers to your questions!",true, 500, 332 )

		local txt = vgui.Create("Wire_WMenu_Label",pnl)
		txt:SetText([[This is the Help and Support tab.
Here you'll find links to useful posts on the Wiremod forums helping you with the installation
of the addon, and tutorials on how to use it.
Click "Open" to open it in the steam in-game browser, and "Copy" to copy the link to your
clipboard.

Installation problems:                            Tutorials:                               SVN Updates/News:]])
		txt:SizeToContents()
		txt:SetPos( 4, 2 )
		txt:SetColor( Color(0,0,0,255) )

		local w,h = 108, 48
		local w1, h1 = 4, txt:GetTall()+6

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1, h1 )
		a:SetURL( "Ultimate Guide", "The ultimate guide to fixing problems with and installing Wiremod\nhttp://www.wiremod.com/forum/installation-malfunctions-support/6417-ultimate-guide-fixing-problems-wiremod-revised-7-11-10-a.html", "http://www.wiremod.com/forum/installation-malfunctions-support/6417-ultimate-guide-fixing-problems-wiremod-revised-7-11-10-a.html" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1, h1+h )
		a:SetURL( "FAQ", "Frequently asked questions\nhttp://www.wiremod.com/forum/installation-malfunctions-support/7079-frequently-asked-questions-yes-top-banner-means-read.html", "http://www.wiremod.com/forum/installation-malfunctions-support/7079-frequently-asked-questions-yes-top-banner-means-read.html" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1, h1+h*2 )
		a:SetURL( "SVN Tutorial", "Divran's SVN Tutorial\nhttp://www.facepunch.com/showthread.php?t=688324", "http://www.facepunch.com/showthread.php?t=688324" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w, h1 )
		a:SetURL( "E2 Wiki", "Expression 2 Wiki\nhttp://wiki.garrysmod.com/?title=Wire_Expression2", "http://wiki.garrysmod.com/?title=Wire_Expression2" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w, h1+h )
		a:SetURL( "E2 Tutorials", "Contains links to several Expression 2 tutorials\nhttp://www.wiremod.com/forum/expression-2-discussion-help/22593-e2-all-about-tutorials-links-them-tips-making-them.html", "http://www.wiremod.com/forum/expression-2-discussion-help/22593-e2-all-about-tutorials-links-them-tips-making-them.html" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w, h1+h*2 )
		a:SetURL( "GPU/CPU Tutorials", "GPU/CPU tutorials forum\nhttp://www.wiremod.com/forum/cpu-tutorials/", "http://www.wiremod.com/forum/cpu-tutorials/" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w*2, h1 )
		a:SetURL( "Wiremod Wiki", "Wiremod Wiki\nhttp://wiki.garrysmod.com/?title=Wiremod", "http://wiki.garrysmod.com/?title=Wiremod" )


		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w*2, h1+h )
		a:SetURL( "Gates Tutorials", "Contains links to several gates tutorials\nhttp://www.wiremod.com/forum/gate-nostalgia-old-school-wiring-discussion-help/22736-gates-all-about-tutorials-links-them-tips-making-them.html", "http://www.wiremod.com/forum/gate-nostalgia-old-school-wiring-discussion-help/22736-gates-all-about-tutorials-links-them-tips-making-them.html" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w*3, h1 )
		a:SetURL( "News", "News and announcements\nhttp://www.wiremod.com/forum/wiremod-announcements/", "http://www.wiremod.com/forum/wiremod-announcements/" )

		local a = vgui.Create("Wire_WMenu_Copypasta",pnl)
		a:SetPos( w1+w*3, h1+h )
		a:SetURL( "WireMod SVN Log", "WireMod Log\nhttp://www.wiremod.com/forum/wiremod-svn-log/", "http://www.wiremod.com/forum/wiremod-svn-log/" ) --"http://www.ninja101.co.uk/wm/" )

		------------------------------------------------------------------------------------------------
		-- Wire Version Check Tab
		------------------------------------------------------------------------------------------------

		local pnl = vgui.Create("DPanel")
		pnl.Paint = wirepaint
		local index, info = self:AddTab("Wire Version", pnl, "gui/silkicons/newspaper", "Check if you need to update", true, 500, 300 )

		local btn = vgui.Create("Wire_WMenu_Button",pnl)
		btn:SetText("Check for newer version")
		btn:SetSize( 350, 20 )
		btn:SetPos( 60, 60 )

		local lbl = vgui.Create("Wire_WMenu_Label",pnl)
		lbl:SetText("Click the button below to check.")
		lbl:SetPos( 4, 5 )
		lbl:SetSize( 475, 40 )
		lbl:SetBGColor( Color(75,75,185,255) )

		local lbl2 = vgui.Create("Wire_WMenu_Label",pnl)

		local function versioncheck(rev)
			if (!rev) then
				lbl:SetText("Error: Failed to get online version.")
				lbl:SetColor( nil ) -- Default color
				lbl:SetBGColor( Color(0,0,0,255) )
			else
				local onlineversion = filterversion(rev)
				local localversion = filterversion(WireLib.LocalVersion)
				local serverversion = filterversion(WireLib.Version)

				if (!onlineversion or onlineversion == 0) then
					lbl:SetText("Error: Failed to get online version.")
					lbl:SetColor( nil ) -- Default color
					lbl:SetBGColor( Color(0,0,0,255) )
				else

					local add = "Both you and the server have the latest version."
					lbl:SetBGColor( Color(75,185,75,255) )
					if (localversion < onlineversion and serverversion < onlineversion) then
						add = "Both you and the server have an old version."
						lbl:SetBGColor( Color(185,75,75,255) )
					elseif (localversion < onlineversion and serverversion >= onlineversion) then
						add = "You have an old version, but the server has the latest."
						lbl:SetBGColor( Color(185,75,75,255) )
					elseif (localversion >= onlineversion and serverversion < onlineversion) then
						add = "You have the latest, but the server has an old version."
						lbl:SetBGColor( Color(185,75,75,255) )
					end

					lbl:SetText("Online wire version found: " .. onlineversion .. "\n"..add)
					lbl:SetColor12( Color(0,0,0,255) )
					if (serverversion == 0) then serverversion = "Failed to get server's version." end
					if (localversion == 0) then localversion = "Failed to get client's version." end
					lbl2:SetText("Your Wiremod version is: " .. (WireLib.LocalVersion or localversion) .. "\n" ..
								"The server's Wiremod version is: " .. (WireLib.Version or serverversion) .. "\n" ..
								"The latest Wiremod version is: " .. onlineversion)
					Menu.UpdateNotification = onlineversion
				end
			end
		end

		function btn:DoClick()
			lbl:SetText("Checking...")
			lbl:SetColor12( nil )
			lbl:SetBGColor( Color(75,75,185,255) )
			if (!WireLib.Version or WireLib.Version == "-unknown-") then RunConsoleCommand("Wire_RequestVersion") end
			WireLib.GetOnlineWireVersion(versioncheck)
		end
		local sver = tonumber(WireLib.Version)
		if (!sver or sver == 0) then sver = "- click above to check -" end
		lbl2:SetText("Your Wiremod version is: " .. WireLib.LocalVersion .. "\n" ..
					"The server's Wiremod version is: " .. sver .. "\n" ..
					"The latest Wiremod version is: - click above to check -")
		lbl2:SetPos( 110, 160 )
		lbl2:SetColor( Color(0,0,0,255) )
		lbl2:SizeToContents()

		------------------------------------------------------------------------------------------------
		-- Options Tab
		------------------------------------------------------------------------------------------------

		local pnl = vgui.Create("DPanel")
		pnl.Paint = e2paint
		local index, info = self:AddTab("Options", pnl, "gui/silkicons/wrench", "Change options for this menu.", true, 500, 270 )

		local pnl2 = vgui.Create("DPanel",pnl)
		pnl2:SetPos( 200, 4 )
		pnl2:SetSize( 275, 150 )
		pnl2:SetBGColor( self.Colors.LabelBGColor )
		self:AddColoring( pnl2.SetBGColor, "LabelBGColor", pnl2 )

		local h = pnl2:GetTall()

		local apply = vgui.Create("Wire_WMenu_Button",pnl)
		apply:SetText("Apply")
		apply:SetSize( 80,20 )
		apply:SetPos( 316, 8 + h - 28 )

		local defaults = vgui.Create("Wire_WMenu_Button",pnl)
		defaults:SetText("Defaults")
		defaults:SetSize( 70,20 )
		defaults:SetPos( 400, 8 + h - 28 )

		local clr = vgui.Create("DColorMixer",pnl)
		clr:SetPos( 4, 4 )
		clr:SetSize( 210, 150 )
		clr:SetColor( Color(255,255,255,255) )
		clr.alpha = 255

		local tbl = {}
		local opt
		for k,v in pairs( self.Colors ) do
			opt = vgui.Create("DRadioButtonLabel",pnl)
			opt:SetText( k .. string.format(" - [%d,%d,%d,%d]", v.r, v.g, v.b, v.a ) )
			opt:SetTextColor(Color(0,0,0,255))
			opt._Color = k
			opt._CurrentColor = Color(v.r,v.g,v.b,v.a)
			local n = #tbl
			tbl[n+1] = opt
			function opt:OnChange( bool )
				if (bool) then
					clr._RadioBtn = self
					clr:SetColor( self._CurrentColor )
				end
			end
			self:AddColoring( function( e, c )
				e._CurrentColor = Color(c.r,c.g,c.b,c.a)
				e:SetText( e._Color .. string.format(" - [%d,%d,%d,%d]", c.r, c.g, c.b, c.a ) )
			end, k, opt )
			opt:SetPos( 205, 8 + n * 20 )
			opt:SetSize( 400, 20 )
		end
		opt:SetPartners( unpack(tbl) )

		opt:Toggle()

		function clr:ColorCubeChanged()
			local c = self._RadioBtn._CurrentColor
			local c2 = self:GetColor()
			c.r = c2.r
			c.g = c2.g
			c.b = c2.b
			self._RadioBtn:SetText( self._RadioBtn._Color .. string.format(" - [%d,%d,%d,%d]", c.r, c.g, c.b, c.a ) )
		end
		local oldfunc
		if VERSION >= 150 then
			oldfunc = clr.RGB.OnChange
			function clr.RGB.OnChange( ctrl, color )
				oldfunc(ctrl,color)
				local c = clr._RadioBtn._CurrentColor
				local c2 = clr:GetColor()
				c.r = c2.r
				c.g = c2.g
				c.b = c2.b
				clr._RadioBtn:SetText( clr._RadioBtn._Color .. string.format(" - [%d,%d,%d,%d]", c.r, c.g, c.b, c.a ) )
			end
		else
			oldfunc = clr.RGBBar.OnColorChange
			
			function clr.RGBBar.OnColorChange( ctrl, color )
				oldfunc(ctrl,color)
				local c = clr._RadioBtn._CurrentColor
				local c2 = clr:GetColor()
				c.r = c2.r
				c.g = c2.g
				c.b = c2.b
				clr._RadioBtn:SetText( clr._RadioBtn._Color .. string.format(" - [%d,%d,%d,%d]", c.r, c.g, c.b, c.a ) )
			end
		end
		clr.Alpha.OnChange = function( ctrl, alpha )
			alpha = alpha*255
			clr._RadioBtn._CurrentColor.a = alpha
			local c = clr._RadioBtn._CurrentColor
			clr._RadioBtn:SetText( clr._RadioBtn._Color .. string.format(" - [%d,%d,%d,%d]", c.r, c.g, c.b, alpha ) )
		end

		function apply:DoClick()
			for k,v in ipairs( tbl ) do
				local cl = v._CurrentColor
				--local a = clr.alpha
				local col = string.format("%d_%d_%d_%d",cl.r, cl.g, cl.b, cl.a)
				RunConsoleCommand("Wire_Welcome_Menu_Colors_"..v._Color,col)
				Menu.Colors[v._Color] = cl -- Color(cl.r,cl.g,cl.b,cl.a)
			end
			Menu:ApplyColors()
		end

		function defaults:DoClick()
			for k,v in pairs( Menu.ColorDefaults ) do
				local col = string.format("%d_%d_%d_%d",v.r, v.g, v.b, v.a)
				RunConsoleCommand("Wire_Welcome_Menu_Colors_"..k,col)
				Menu.Colors[k] = v
			end
			Menu:ApplyColors()
			clr:SetColor( Menu.ColorDefaults[clr._RadioBtn._Color] )
		end

		local hide = vgui.Create("DCheckBoxLabel",pnl)
		local hide_x = 4
		hide:SetPos( hide_x, 0 )
		hide:SetText("Hide Update Notification.")
		hide:SizeToContents()
		hide:SetToolTip("Hide the update notification that appears whenever there is an update to wiremod.")
		hide:SetConVar("Wire_Welcome_Menu_HideUpdateNotification")

		hook.Add("Wire_WMenu_Scale","Default_Scale_2",function(self, W, H)
			if (self:GetCurrentTab().Name == "Options") then
				hide:SetPos( hide_x, H - 102 )
			end
		end)
	end)
end
