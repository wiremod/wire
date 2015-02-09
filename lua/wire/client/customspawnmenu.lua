
local PANEL = {}

AccessorFunc( PANEL, "m_TabID", 			"TabID" )

local expand_all = CreateConVar( "wire_tool_menu_expand_all", 0, {FCVAR_ARCHIVE} )
local separate_wire_extras = CreateConVar( "wire_tool_menu_separate_wire_extras", 1, {FCVAR_ARCHIVE} )
local hide_duplicates = CreateConVar( "wire_tool_menu_hide_duplicates", 0, {FCVAR_ARCHIVE} )
local custom_for_all_tabs = CreateConVar( "wire_tool_menu_custom_menu_for_all_tabs", 0, {FCVAR_ARCHIVE} )
local tab_width = CreateConVar( "wire_tool_menu_tab_width", -1, {FCVAR_ARCHIVE} )
local horizontal_divider_width = CreateConVar( "wire_tool_menu_horizontal_divider_width", 0.28, {FCVAR_ARCHIVE} )

-- Helper functions
local function expandall( bool, nodes )
	for i=1,#nodes do
		nodes[i]:SetExpanded( bool )
		if nodes[i].WireCookieText then cookie.Set( nodes[i].WireCookieText, bool and 1 or 0 ) end
		
		if nodes[i].ChildNodes then
			expandall( bool, nodes[i].ChildNodes:GetChildren() )
		end
	end
end

local function expandbycookie( nodes )
	for i=1,#nodes do
		local b = cookie.GetNumber( nodes[i].WireCookieText )
		
		if b and b == 1 then
			nodes[i]:SetExpanded( b and b == 1 )
			
			if nodes[i].ChildNodes then
				expandbycookie( nodes[i].ChildNodes:GetChildren() )
			end
		else
			nodes[i]:SetExpanded( false )
		end				
	end
end


----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
function PANEL:Init()
	self.Divider = vgui.Create( "DHorizontalDivider", self )
	self.Divider:Dock( FILL )
	self.Divider:SetDividerWidth( 6 )
	
	local width = tab_width:GetInt()
	local divider_width = horizontal_divider_width:GetFloat()
	if width > ScrW() * 0.6 then -- too big! you won't be able to see the rest of the spawn menu if it's this big, let's make it smaller
		width = ScrW() * 0.6
	elseif width == -1 then -- set up default value
		width = 390
		if ScrW() > 1600 then width = 548
		elseif ScrW() > 1280 then width = 460 end
	elseif width < 390 then -- too small! you won't be able to see the tools, make it bigger
		width = 390
	end
	
	if width ~= tab_width:GetInt() then -- things changed, update convars
		divider_width = 0.28 -- reset horizontal divider width
		RunConsoleCommand( "wire_tool_menu_tab_width", width )
		RunConsoleCommand( "wire_tool_menu_horizontal_divider_width", divider_width )
	end
	
	self:SetWide( width )
	self.Divider:SetLeftWidth( width * divider_width )
	
	local old = self.Divider.OnMouseReleased
	function self.Divider.OnMouseReleased( ... )
		local width_percent = math.Round(self.Divider:GetLeftWidth() / self:GetWide(),2)
		RunConsoleCommand( "wire_tool_menu_horizontal_divider_width", width_percent )
		old( ... )
	end
	
	local LeftPanel = vgui.Create( "DPanel" )
	self.Divider:SetLeft( LeftPanel )
	
	local SearchBoxPanel = vgui.Create( "DPanel", LeftPanel )
	SearchBoxPanel:SetTall( 44 )
	SearchBoxPanel:DockPadding( 2,2,2,2 )
	SearchBoxPanel:Dock( TOP )
	
	self.SearchBox = vgui.Create( "DTextEntry", SearchBoxPanel )
	self.SearchBox:DockMargin( 2, 2, 2, 0 )
	self.SearchBox:Dock( TOP )
	self:SetupSearchbox()
		
	local ExpandAll = vgui.Create( "DCheckBoxLabel", SearchBoxPanel ) -- create this here so that it's below the slider
	
	self.List = vgui.Create( "DTree", LeftPanel )
	
	ExpandAll:SetText( "Expand All" )
	ExpandAll:SetConVar( "wire_tool_menu_expand_all" )
	ExpandAll:DockMargin( 4, 4, 0, 0 )
	ExpandAll:Dock( BOTTOM )
	
	local first = true
	
	local parent = self
	local oldval
	function ExpandAll:OnChange( value )
		if oldval == value then return end -- wtfgarry
		oldval = value
		
		local childNodes = parent.List:Root().ChildNodes:GetChildren()
		
		if first then
			-- this was the only way to get this to run at the right time... garry bypassing hacks wohoo
			-- it works because DCheckBox:OnChange is called when the player first sees the checkbox (aka when they open the wire tool tab)
			first = false
			expandbycookie( childNodes ) 
		else
			expandall( value, childNodes )
		end
	end
	ExpandAll.Label:SetDark(true)
	
	self.List:Dock( FILL )
	
	self.SearchList = vgui.Create( "DListView", LeftPanel )
	local x,y = self.List:GetPos()
	local w,h = self.List:GetSize()
	self.SearchList:SetPos( x + w, 160 )
	self.SearchList:SetSize( w, h )
	self.SearchList:SetVisible( false )
	self.SearchList:AddColumn( "Name" )
	self.SearchList:AddColumn( "Category" )
	self.SearchList:SetMultiSelect( false )
	
	function self.SearchList:OnClickLine( line )
		-- Deselect old
		local t = self:GetSelected()
		if t and next(t) then
			t[1]:SetSelected(false)
		end

		line:SetSelected(true) -- Select new
		spawnmenu.ActivateTool( line.Name )
	end

	self.SubSearchList = vgui.Create( "DListView", LeftPanel )
	self.SubSearchList:AddColumn( "Name" )
	self.SubSearchList:AddColumn( "Tool" )
	self.SubSearchList:SetMultiSelect( false )
	self.SubSearchList:SetVisible( false )

	local searchlist = self.SearchList
	function self.SubSearchList:OnClickLine( line )

		-- Deselect old
		local t = self:GetSelected()
		if t and next(t) then
			t[1]:SetSelected(false)
		end

		-- select new line
		line:SetSelected( true )

		-- click SearchList's OnClickLine for this tool so that the tool is switched
		for i=1,#searchlist.Lines do
			if searchlist.Lines[i].Name == line.item.tool_mode then
				searchlist:OnClickLine( searchlist.Lines[i] )
				break
			end
		end

		-- call this item's onclick function
		if line.item.onclick then
			line.item.onclick( line.item )
		end
	end
	
	self.Content = vgui.Create( "DCategoryList" )
	self.Divider:SetRight( self.Content )

	local searchlist = self.SearchList
	function LeftPanel:PerformLayout()
		searchlist:SetWide( self:GetWide() )
	end
	
	self.ToolTable = {}
	self.OriginalToolTable = {}
	self.CategoryLookup = {}
end

----------------------------------------------------------------------
-- ReloadEverything
-- Called when a user adds/removes favourites or checks/unchecks
-- the wire extras checkbox
----------------------------------------------------------------------
function PANEL:ReloadEverything()
	self.List:Root():Remove()
	self.List:Init()
	self.SearchList:Clear()
	self.SearchBox:SetValue( "" )
	self.SearchBox:OnTextChanged()
	
	self.CategoryLookup = {}
	self.ToolTable = {}
	
	self:LoadToolsFromTable( self.OriginalToolTable )
	expandbycookie( self.List:Root().ChildNodes:GetChildren() )
end


----------------------------------------------------------------------
-- SetupSearchbox
-- This was so big, I moved it into its own function
-- rather than doing it in PANEL:Init()
----------------------------------------------------------------------
function PANEL:SetupSearchbox()
	local clearsearch = vgui.Create( "DImageButton", self.SearchBox )
	clearsearch:SetMaterial( "icon16/cross.png" )
	local src = self.SearchBox
	function clearsearch:DoClick()
		src:SetValue( "" )
		src:OnTextChanged()
		src:SetValue( "Search..." )
	end
	clearsearch:DockMargin( 2,2,4,2 )
	clearsearch:Dock( RIGHT )
	clearsearch:SetSize( 14, 10 )
	clearsearch:SetVisible( false )
	self.SearchBox.clearsearch = clearsearch
	
	-- OnEnter
	local parent = self
	function self.SearchBox:OnEnter( select_next )
		local lines = #parent.SearchList:GetLines()
		if lines > 0 then -- if we have no lines at all, do nothing
			local line = parent.SearchList:GetSelectedLine() or 0
			if select_next then -- if tabbed, select next line
				if lines > line then
					parent.SearchList:OnClickLine( parent.SearchList:GetLine( line+1 ) )
				else
					parent.SearchList:OnClickLine( parent.SearchList:GetLine( 1 ) )
				end
			elseif line == 0 then -- if not tabbed, only select first line if no line is selected
				parent.SearchList:OnClickLine( parent.SearchList:GetLine( 1 ) )
			end				
		end
	end
	
	local old = self.SearchBox.OnGetFocus
	function self.SearchBox:OnGetFocus()
		if self:GetValue() == "Search..." then -- If "Search...", erase it
			self:SetValue( "" )
		end
		old( self )
	end
	
	-- On lose focus
	local old = self.SearchBox.OnLoseFocus
	function self.SearchBox:OnLoseFocus()
		if self.Tabbed then -- regain focus if tabbed
			self:RequestFocus()
			self.Tabbed = nil
		else
			if self:GetValue() == "" then -- if empty, reset "Search..." text
				timer.Simple( 0, function() self:SetValue( "Search..." ) end )
			end
			old( self )
		end
	end
	
	-- detecting tab to select next item in search result
	local old = self.SearchBox.OnKeyCodeTyped
	function self.SearchBox:OnKeyCodeTyped( code )
		if code == 67 then -- tab
			self:OnEnter( true )
			self.Tabbed = true
		else
			old( self, code )
		end
	end
	
	self.SearchBox:SetValue( "Search..." )

	local searching
	function self.SearchBox:OnTextChanged()
		timer.Remove( "wire_customspawnmenu_hidesearchbox" )
	
		local text = self:GetValue()
		if text ~= "" then
			if not searching then
				searching = true
				local x,y = parent.List:GetPos()
				local w,h = parent.List:GetSize()
				parent.SearchList:SetPos( x + w, y )
				parent.SearchList:MoveTo( x, y, 0.1, 0, 1 )
				parent.SearchList:SetSize( w, h )
				parent.SearchList:SetVisible( true )
				self.clearsearch:SetVisible( true )

				parent.SubSearchList:SetPos( x, y + h / 2 - 2 )
				parent.SubSearchList:SetSize( w, h / 2 + 2 )
				parent.SubSearchList:SetVisible( false )
			end
			local results, sub_results = parent:Search( text )
			parent.SearchList:Clear()
			for i=1,#results do
				local result = results[i]
				local line = parent.SearchList:AddLine( result.item.Text, result.item.Category )
				line.Name = result.item.ItemName
				line.WireFavouritesCookieText = result.item.WireFavouritesCookieText
				
				function line:OnRightClick()
					-- the menu wasn't clickable unless the search list had focus for some reason
					parent.SearchList:RequestFocus()
				
					local menu = DermaMenu()
					
					local b = cookie.GetNumber( self.WireFavouritesCookieText )
					if b and b == 1 then
						menu:AddOption( "Remove from favourites", function() cookie.Set( self.WireFavouritesCookieText, 0 ) parent:ReloadEverything() end )
					else
						menu:AddOption( "Add to favourites", function() cookie.Set( self.WireFavouritesCookieText, 1 ) parent:ReloadEverything() end )
					end
					menu:Open()
					
					return true
				end
			end

			parent.SubSearchList:Clear()
			if #sub_results > 0 then
				parent.SearchList:SetTall( parent.List:GetTall() / 2 )
				parent.SubSearchList:SetVisible( true )

				for i=1,#sub_results do
					local result = sub_results[i]
					local line = parent.SubSearchList:AddLine( result.text, result.tool_name )
					line.item = result
					if result.selected then
						line:SetSelected( true )
					end
				end
			else
				parent.SearchList:SetTall( parent.List:GetTall() )
				parent.SubSearchList:SetVisible( false )
			end
		else
			if searching then
				searching = false
				local x,y = parent.List:GetPos()
				local w,h = parent.List:GetSize()
				parent.SearchList:SetPos( x, y )
				parent.SearchList:MoveTo( x + w, y, 0.1, 0, 1 )
				parent.SearchList:SetSize( w, h )
				timer.Create( "wire_customspawnmenu_hidesearchbox", 0.1, 1, function()
					if IsValid( parent ) then
						parent.SearchList:SetVisible( false )
					end
				end )
				self.clearsearch:SetVisible( false )

				parent.SearchList:SetTall( parent.List:GetTall() )
				parent.SubSearchList:SetVisible( false )
			end
			parent.SearchList:Clear()
		end
	end
end

----------------------------------------------------------------------
-- Search algorithm
----------------------------------------------------------------------

local string_find = string.find
local table_SortByMember = table.SortByMember
local string_lower = string.lower

-- Searching algorithm
function PANEL:Search( text )
	text = string_lower(text)

	local results = {}
	local sub_results = {}

	local first_word, sub_text = string.match( text, "([^ ]-) (.*)")

	for categoryID,categories in pairs( self.ToolTable ) do
		for _, v in pairs( categories ) do
			local lowname = string_lower( v.Text )
			local lowname_other = string_lower( v.ItemName )
		
			local a = string_find( lowname, text, 1, true )
			local b = string_find( lowname_other, text, 1, true )
			local c = first_word and string_find( lowname, first_word, 1, true ) or false
			local d = first_word and string_find( lowname_other, first_word, 1, true ) or false
			if (a or b or c or d) and not string_find( lowname, "(legacy)", 1, true ) and not v.Alias then
				local add_to_results = a or b

				-- If this tool has its own searching, run it
				if first_word and sub_text then
					local tool_object = LocalPlayer():GetWeapon("gmod_tool"):GetToolObject(v.ItemName)
					if tool_object then
						local search_func = tool_object.Search
						if search_func then
							local results = tool_object:Search( sub_text )

							for i=1,#results do
								results[i].tool_name = v.Text
								results[i].tool_mode = v.ItemName
								sub_results[#sub_results+1] = results[i]
							end


							add_to_results = #results > 0
						end
					end
				end

				if add_to_results then -- only add to results if the entire search text matches, or if this tool has its own search and that has a match
					results[#results+1] = {
						item = v,
						dist = math.min(WireLib.levenshtein( text, lowname ),WireLib.levenshtein( text, lowname_other ))
					}
				end
			end
		end
	end

	table_SortByMember( results, "dist", true )
	table_SortByMember( sub_results, "dist", true )

	return results, sub_results
end

-- Helper function
local function AddNode( list, text, cookietext )
	local node = list:AddNode( text )
	
	node.Label:SetFont( "DermaDefaultBold" )
	
	cookietext = "ToolMenu.Wire." .. cookietext
	node.WireCookieText = cookietext
	
	function node:DoClick()
		local b = not self.m_bExpanded
		self:SetExpanded( b )
		
		cookie.Set( cookietext, b and 1 or 0 )
	end
	node.Expander.DoClick = function() node:DoClick() end
	
	function node:DoRightClick()
		local menu = DermaMenu()
			
		local b = self.m_bExpanded
		if b then
			menu:AddOption( "Collapse all", function()
				self:SetExpanded( false )
				expandall( false, self.ChildNodes:GetChildren() )
			end )
		else
			menu:AddOption( "Expand all", function()
				self:SetExpanded( true )
				expandall( true, self.ChildNodes:GetChildren() )
			end )
		end
		menu:Open()
		
		return true
	end
	
	return node
end

----------------------------------------------------------------------
-- CreateCategories
-- Creates the categories before placing tools in them to ensure
-- they are created in the correct order, and only once
----------------------------------------------------------------------
function PANEL:CreateCategories()
	for k,v in pairs( self.ToolTable ) do
		if istable( v ) then			
			local category = v.ItemName		
			
			local expl = string.Explode("/",category)
			
			if not separate_wire_extras:GetBool() and expl[1] == "Wire Extras" then
				table.remove( expl, 1 )
				v.ItemName = string.gsub( v.ItemName, "Wire Extras/", "" )
				v.Text = string.gsub( v.Text, "Wire Extras/", "" )
				category = v.ItemName
			end
			
			if #expl == 1 then
				if not self.CategoryLookup[category] then
					local node = AddNode( self.List, v.Text, category )
					self.CategoryLookup[category] = node
				end
			else
				local category = expl[1]
				if not self.CategoryLookup[category] then
					local node = AddNode( self.List, category, category )
					self.CategoryLookup[category] = node
				end
				
				for i=2,#expl do
					local str = expl[i]
					
					local path = table.concat(expl,"/",1,i)
					if not self.CategoryLookup[path] then
						local node = AddNode( self.CategoryLookup[table.concat(expl,"/",1,i-1)], str, path )
						self.CategoryLookup[path] = node
					end
				end
			end
		end
	end
end


----------------------------------------------------------------------
-- AddToolToCategories
-- Handles multiple categories by copying the tool and moving the copies into said categories
----------------------------------------------------------------------
function PANEL:AddToolToCategories( tool, categories )
	for i=1,#categories do
		local categoryName = categories[i]
		
		local added = false
		
		local copy = table.Copy( tool )
		copy.Alias = true
				
		for _, category in pairs( self.ToolTable ) do	
			if category.ItemName == categoryName then
				added = true
				category[#category+1] = copy
				table_SortByMember( category, "Text", true )
			end
		end
		
		if not added then
			local new = {
				ItemName = categoryName,
				Text = categoryName,
			}
			
			new[1] = copy
			self.ToolTable[#self.ToolTable+1] = new
		end			
	end
end

----------------------------------------------------------------------
-- FixWireCategories
-- Handles multi categories and favourites
----------------------------------------------------------------------
function PANEL:FixWireCategories()
	local t = table.Copy( self.ToolTable )

	for _,category in pairs( t ) do
		if istable(category) then
			for _, tool in pairs( category ) do
				if istable(tool) then
					-- favourites
					local fav = cookie.GetNumber( "ToolMenu.Wire.Favourites." .. tool.ItemName )
					if fav and fav == 1 then
						self:AddToolToCategories( tool, {"Favourites"} )
					end						
				
					-- multi categories
					if not hide_duplicates:GetBool() then
						local tooltbl = weapons.Get("gmod_tool").Tool[tool.ItemName]
						if tooltbl then
							if tooltbl.Wire_MultiCategories then
								self:AddToolToCategories( tool, tooltbl.Wire_MultiCategories )
							end
						end
					end
				end
			end
		end
	end
end

-----------------------------------------------------------
-- Name: LoadToolsFromTable
-----------------------------------------------------------
function PANEL:LoadToolsFromTable( inTable )
	self.OriginalToolTable = table.Copy( inTable )
	self.ToolTable = table.Copy( inTable )
	
	-- If this tab has no favourites category, add one at the top
	if self.ToolTable[1].ItemName ~= "Favourites" then
		table.insert( self.ToolTable, 1, { ItemName = "Favourites", Text = "Favourites" } )
	end
	
	-- First, we copy all tools into their multi categories
	self:FixWireCategories()
	
	-- Then we create the categories, so everything goes to the right place
	self:CreateCategories()
	
	-- Then, we add all tools to the DTree
	for k, v in pairs( self.ToolTable ) do
	
		if ( istable( v ) ) then
		
			-- Remove these from the table so we can
			-- send the rest of the table to the other 
			-- function
					
			local Name = v.ItemName
			local Label = v.Text
			v.ItemName = nil
			v.Text = nil
			
			self:AddCategory( Name, Label, v )			
		end
	end
end

-----------------------------------------------------------
-- Name: AddCategory
-----------------------------------------------------------
function PANEL:AddCategory( Name, Label, tItems, CategoryID )

	local Category = self.CategoryLookup[Name]
	if not Category then
		return
	end
	
	for k, v in pairs( tItems ) do
	
		v.Category = Label
		v.CategoryID = CategoryID
	
		local item = Category:AddNode( v.Text )
		item.Icon:SetImage( "icon16/wrench.png" )
		
		function item:DoClick()

			spawnmenu.ActivateTool( self.Name )

		end
		
		local parent = self
		function item:DoRightClick()
			local menu = DermaMenu()
			
			local b = cookie.GetNumber( self.WireFavouritesCookieText )
			if b and b == 1 then
				menu:AddOption( "Remove from favourites", function() cookie.Set( self.WireFavouritesCookieText, 0 ) parent:ReloadEverything() end )
			else
				menu:AddOption( "Add to favourites", function() cookie.Set( self.WireFavouritesCookieText, 1 ) parent:ReloadEverything() end )
			end
			menu:Open()
			
			return true
		end
		
		item.WireFavouritesCookieText	= "ToolMenu.Wire.Favourites." .. v.ItemName
		v.WireFavouritesCookieText		= item.WireFavouritesCookieText
		item.ControlPanelBuildFunction	= v.CPanelFunction
		item.Command					= v.Command
		item.Name						= v.ItemName
		item.Controls					= v.Controls
		item.Text						= v.Text
	
	end
	
	self:InvalidateLayout()
end

function PANEL:SetActive( cp )
	local kids = self.Content:GetCanvas():GetChildren()
	for k, v in pairs( kids ) do
		v:SetVisible( false )
	end

	self.Content:AddItem( cp )
	cp:SetVisible( true )
	cp:Dock( TOP )
end

vgui.Register( "WireToolPanel", PANEL, "Panel" )

local wire_tab
local all_tabs = {}

local function setUpTabReloadOnChange( checkbox )
	checkbox.first = true
	function checkbox:OnChange( value )
		if self.oldval == value then return end -- wtfgarry
		self.oldval = value
		
		if self.first then self.first = false return end
		
		timer.Simple( 0.1, function()
			if IsValid( wire_tab ) then
				wire_tab:ReloadEverything()
			end
		end )
	end
end

local function CreateCPanel( panel )
	local checkbox = panel:CheckBox( "Use wire's custom tool menu for all tabs", "wire_tool_menu_custom_menu_for_all_tabs" )
	checkbox:SetToolTip( "Requires rejoin to take effect" )
	
	if WireLib.WireExtrasInstalled then
		local SeparateWireExtras = panel:CheckBox( "Separate Wire Extras", "wire_tool_menu_separate_wire_extras" )
		SeparateWireExtras:SetToolTip( "Whether or not to separate wire extras tools into its own category." )

		setUpTabReloadOnChange( SeparateWireExtras )
	end
	
	local HideDuplicates = panel:CheckBox( "Hide tool duplicates", "wire_tool_menu_hide_duplicates" )
	setUpTabReloadOnChange( HideDuplicates )
	panel:Help( "It makes sense to have certain tools in multiple categories at once. However, if you don't want this, you can disable it here. The tools will then only appear in their primary category." )
	
	local TabWidth = panel:NumSlider( "Tab width", "wire_tool_menu_tab_width", 300, 3000, 0 )
	panel:Help( [[Set the width of all tabs.
Defaults:
Screen width > 1600px: 548px,
Screen width > 1280px: 460px,
Screen width < 1280px: 390px.
Note:
Can't be smaller than the width of any non-custom tab, and can't be greater than screenwidth * 0.6.
Changes will take effect 3 seconds after you edit the value.]] )

	function TabWidth:ValueChanged( value )
		timer.Remove( "wire_tab_width_changed" )
		timer.Create( "wire_tab_width_changed", 3, 1, function()
			all_tabs[1]:GetParent():SetWide( 390 )
			for i=1,#all_tabs do -- change the width of all registered tabs
				all_tabs[i]:SetWidth( math.Clamp( value, 390, ScrW() * 0.6 ) )
			end
			all_tabs[1]:GetParent():PerformLayout()
		end)
	end
end

----------------------------------------------------------------------
-- Incoming garry hack
----------------------------------------------------------------------

local tabs = {}

-- Allow any addon to register to be given a custom menu
function WireLib.registerTabForCustomMenu( tab )
	tabs[tab] = true
end

-- Register ourselves
WireLib.registerTabForCustomMenu( "Wire" )

local old
hook.Add( "PopulateToolMenu", "Wire_CustomSpawnMenu", function()
	spawnmenu.AddToolMenuOption( "Wire", "Options", "Custom Tool Menu Options", "Custom Tool Menu Options", "", "", CreateCPanel )

	local ToolMenu = vgui.GetControlTable( "ToolMenu" )

	old = ToolMenu.AddToolPanel
	function ToolMenu:AddToolPanel( Name, ToolTable )
		if tabs[ToolTable.Name] or custom_for_all_tabs:GetBool() == true then
			local Panel = vgui.Create( "WireToolPanel" )
			
			if ToolTable.Name == "Wire" then
				wire_tab = Panel -- for wire tab options menu
			end
			all_tabs[#all_tabs+1] = Panel -- list of all registered tabs
			
			Panel:SetTabID( Name )
			Panel:LoadToolsFromTable( ToolTable.Items )
		
			self:AddSheet( ToolTable.Label, Panel, ToolTable.Icon )
			self.ToolPanels[ Name ] = Panel
		else		
			return old( self, Name, ToolTable )
		end
	end
end)

hook.Add( "PostReloadToolsMenu", "Wire_CustomSpawnMenu", function()
	local ToolMenu = vgui.GetControlTable( "ToolMenu" )
	ToolMenu.AddToolPanel = old
	old = nil
end)
