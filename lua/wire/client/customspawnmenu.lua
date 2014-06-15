
local PANEL = {}

local CurrentName -- a small hack to know when to create the wire extras checkbox

AccessorFunc( PANEL, "m_TabID", 			"TabID" )

local expand_all = CreateConVar( "wire_tool_menu_expand_all", 0, {FCVAR_ARCHIVE} )
local separate_wire_extras = CreateConVar( "wire_tool_menu_separate_wire_extras", 1, {FCVAR_ARCHIVE} )
local custom_for_all_tabs = CreateConVar( "wire_tool_menu_custom_menu_for_all_tabs", 0, {FCVAR_ARCHIVE} )

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
	
	if ScrW() > 1600 then
		self:SetWide( 548 )
		self.Divider:SetLeftWidth( 200 )
	elseif ScrW() > 1280 then
		self:SetWide( 460 )
		self.Divider:SetLeftWidth( 160 )
	else
		self:SetWide( 390 )
		self.Divider:SetLeftWidth( 130 )
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
	
	local clearsearch = vgui.Create( "DImageButton", self.SearchBox )
	clearsearch:SetMaterial( "icon16/cross.png" )
	local src = self.SearchBox
	function clearsearch:DoClick()
		src:SetValue( "" )
		src:OnTextChanged()
	end
	clearsearch:DockMargin( 2,2,4,2 )
	clearsearch:Dock( RIGHT )
	clearsearch:SetSize( 14, 10 )
	clearsearch:SetVisible( false )
	self.SearchBox.clearsearch = clearsearch
	
	local parent = self
	function self.SearchBox:OnEnter()
		if #parent.SearchList:GetLines() > 0 then
			parent.SearchList:OnClickLine( parent.SearchList:GetLine( 1 ) )
		end
	end
	
	if WireLib.WireExtrasInstalled and CurrentName == "Wire" then
		-- create this here so that it's below ExpandAll
		local SeparateWireExtras = vgui.Create( "DCheckBoxLabel", SearchBoxPanel )
		SeparateWireExtras:SetText( "Separate Wire Extras" )
		SeparateWireExtras:SetToolTip( "Whether or not to separate wire extras tools into its own category." )
		SeparateWireExtras:SetConVar( "wire_tool_menu_separate_wire_extras" )
		SeparateWireExtras.Label:SetDark(true)
		SeparateWireExtras:DockMargin( 4, 4, 0, 0 )
		SeparateWireExtras:Dock( BOTTOM )
		
		local first = true
		local parent = self
		local oldval
		function SeparateWireExtras:OnChange( value )
			if oldval == value then return end -- wtfgarry
			oldval = value
			
			if first then first = false return end
			
			timer.Simple( 0.1, function()
				parent:ReloadEverything()
			end )
		end
		
		SearchBoxPanel:SetTall( 64 )
	end
	
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
	local searching
	local parent = self
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
			end
			local results = parent:Search( text )
			parent.SearchList:Clear()
			for i=1,#results do
				local result = results[i]
				local line = parent.SearchList:AddLine( result.item.Text, result.item.Category )
				line.Name = result.item.ItemName
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
			end
			parent.SearchList:Clear()
		end
	end
end

----------------------------------------------------------------------
-- Search algorithm
----------------------------------------------------------------------

-- Thank you http://lua-users.org/lists/lua-l/2009-07/msg00461.html
local function Levenshtein( s, t )
	local d, sn, tn = {}, #s, #t
	local byte, min = string.byte, math.min
	for i = 0, sn do d[i * tn] = i end
	for j = 0, tn do d[j] = j end
	for i = 1, sn do
		local si = byte(s, i)
		for j = 1, tn do
			d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
		end
	end
	return d[#d]
end

local string_find = string.find
local table_SortByMember = table.SortByMember
local string_lower = string.lower

-- Searching algorithm
function PANEL:Search( text )
	text = string_lower(text)

	local results = {}
	for categoryID,categories in pairs( self.ToolTable ) do
		for _, v in pairs( categories ) do
			local name = v.Text
			local lowname = string_lower( name )
		
			if string_find( lowname, text, 1, true ) and not string_find( lowname, "(legacy)", 1, true ) and not v.Alias then
				results[#results+1] = {
					item = v,
					dist = Levenshtein( text, lowname )
				}
			end
		end
	end

	table_SortByMember( results, "dist", true )

	return results
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
					--local node = self.List:AddNode( v.Text )
					local node = AddNode( self.List, v.Text, category )
					self.CategoryLookup[category] = node
				end
			else
				local category = expl[1]
				if not self.CategoryLookup[category] then
					--local node = self.List:AddNode( category )
					local node = AddNode( self.List, category, category )
					self.CategoryLookup[category] = node
				end
				
				for i=2,#expl do
					local str = expl[i]
					
					local path = table.concat(expl,"/",1,i)
					if not self.CategoryLookup[path] then
						--local node = self.CategoryLookup[table.concat(expl,"/",1,i-1)]:AddNode( str )
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
					local fav = cookie.GetNumber( "ToolMenu.Wire.Favourites." .. tool.ItemName )
					if fav and fav == 1 then
						self:AddToolToCategories( tool, {"Favourites"} )
					end						
				
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
	
	local bAlt = true
	
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

local function CreateCPanel( panel )
	local checkbox = panel:CheckBox( "Use wire's custom tool menu for all tabs", "wire_tool_menu_custom_menu_for_all_tabs" )
	checkbox:SetToolTip( "Requires rejoin to take effect" )
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
			CurrentName = ToolTable.Name
			local Panel = vgui.Create( "WireToolPanel" )
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
