
local PANEL = {}

AccessorFunc( PANEL, "m_TabID", 			"TabID" )

local expand_all = CreateConVar( "wire_tool_menu_expand_all", 0, {FCVAR_ARCHIVE} )
local search_max_convar = CreateConVar( "wire_tool_menu_search_limit", 28, {FCVAR_ARCHIVE} )
local separate_wire_extras = CreateConVar( "wire_tool_menu_separate_wire_extras", 1, {FCVAR_ARCHIVE} )

--[[---------------------------------------------------------
   Name: Paint
-----------------------------------------------------------]]
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
	SearchBoxPanel:SetTall( 84 )
	SearchBoxPanel:Dock( TOP )
	
	self.SearchBox = vgui.Create( "DTextEntry", SearchBoxPanel )
	self.SearchBox:DockMargin( 4, 4, 4, 0 )
	self.SearchBox:Dock( TOP )
	self:SetupSearchbox()
	
	local parent = self
	function self.SearchBox:OnEnter()
		if #parent.SearchList:GetLines() > 0 then
			parent.SearchList:OnClickLine( parent.SearchList:GetLine( 1 ) )
		end
	end
	
	if WireLib.WireExtrasInstalled then
		-- create this here so that it's below ExpandAll
		local SeparateWireExtras = vgui.Create( "DCheckBoxLabel", SearchBoxPanel )
		SeparateWireExtras:SetText( "Separate Wire Extras" )
		SeparateWireExtras:SetToolTip( "Whether or not to separate wire extras tools into its own category. Requires rejoin to take effect." )
		SeparateWireExtras:SetConVar( "wire_tool_menu_separate_wire_extras" )
		SeparateWireExtras.Label:SetDark(true)
		SeparateWireExtras:DockMargin( 4, 4, 0, 0 )
		SeparateWireExtras:Dock( BOTTOM )
		
		SearchBoxPanel:SetTall( 104 )
	end
	
	local ExpandAll = vgui.Create( "DCheckBoxLabel", SearchBoxPanel ) -- create this here so that it's below the slider
	
	local ResultSlider = vgui.Create( "DNumSlider", SearchBoxPanel )
	ResultSlider:SetText( "Search results:" )
	ResultSlider:SetConVar( "wire_tool_menu_search_limit" )
	ResultSlider:SetMin( 1 )
	ResultSlider:SetMax( 50 )
	ResultSlider:SetDecimals( 0 )
	ResultSlider.Label:SetDark(true)
	ResultSlider:DockMargin( 4, 4, -26, 0 )
	ResultSlider:Dock( BOTTOM )
	
	self.List = vgui.Create( "DTree", LeftPanel )
	
	ExpandAll:SetText( "Expand All" )
	ExpandAll:SetConVar( "wire_tool_menu_expand_all" )
	ExpandAll:DockMargin( 4, 4, 0, 0 )
	ExpandAll:Dock( BOTTOM )
	
	local function expandall( bool, nodes )
		for i=1,#nodes do
			nodes[i]:SetExpanded( bool )
			
			if nodes[i].ChildNodes then
				expandall( bool, nodes[i].ChildNodes:GetChildren() )
			end
		end
	end
	
	local parent = self
	local oldval
	function ExpandAll:OnChange( value )
		if oldval == value then return end -- wtfgarry
		oldval = value
		
		local childNodes = parent.List:Root().ChildNodes:GetChildren()
		expandall( value, childNodes )
	end
	ExpandAll.Label:SetDark(true)
	
	-- Expand all if convar is enabled
	timer.Simple( 1, function()
		if expand_all:GetBool() then
			local childNodes = self.List:Root().ChildNodes:GetChildren()
			expandall( true, childNodes )
		end
	end )
	
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
	self.CategoryLookup = {}
end


function PANEL:SetupSearchbox()
	local searching
	local parent = self
	function self.SearchBox:OnTextChanged()
		local text = self:GetValue()
		if text ~= "" then
			if not searching then
				searching = true
				local x,y = parent.List:GetPos()
				local w,h = parent.List:GetSize()
				parent.SearchList:MoveTo( x, y, 0.1, 0, 1 )
				parent.SearchList:SetSize( w, h )
				parent.SearchList:SetVisible( true )
			end
			local results = parent:Search( text )
			parent.SearchList:Clear()
			for i=1,math.min(#results,search_max_convar:GetInt()) do
				local result = results[i]
				local line = parent.SearchList:AddLine( result.item.Text, result.item.Category )
				line.Name = result.item.ItemName
			end
		else
			if searching then
				searching = false
				local x,y = parent.List:GetPos()
				local w,h = parent.List:GetSize()
				parent.SearchList:MoveTo( x + w, y, 0.1, 0, 1 )
				parent.SearchList:SetSize( w, h )
				timer.Simple( 0.1, function()
					if IsValid( parent ) then
						parent.SearchList:SetVisible( false )
					end
				end )
			end
			parent.SearchList:Clear()
		end
	end
end

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
					local node = self.List:AddNode( v.Text )
					self.CategoryLookup[category] = node
				end
			else
				local curnode = self.CategoryLookup[expl[1]]
				if not curnode then
					curnode = self.List:AddNode( expl[1] )
					self.CategoryLookup[expl[1]] = curnode
				end
				
				for i=2,#expl do
					local str = expl[i]
					
					local path = table.concat(expl,"/",1,i)
					if not self.CategoryLookup[path] then
						local node = self.CategoryLookup[table.concat(expl,"/",1,i-1)]:AddNode( str )
						self.CategoryLookup[path] = node
					end
				end
			end
		end
	end
end

function PANEL:AddToolToCategories( tool, tooltbl )
	for i=1,#tooltbl.Wire_MultiCategories do
		local categoryName = tooltbl.Wire_MultiCategories[i]
		
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

function PANEL:FixWireCategories()
	local t = table.Copy( self.ToolTable )

	for _,category in pairs( t ) do
		if istable(category) then
			for _, tool in pairs( category ) do
				if istable(tool) then
					local tooltbl = weapons.Get("gmod_tool").Tool[tool.ItemName]
					if tooltbl then
						if tooltbl.Wire_MultiCategories then
							self:AddToolToCategories( tool, tooltbl )
						end
					end
				end
			end
		end
	end
end

-----------------------------------------------------------
--  Name: LoadToolsFromTable
-----------------------------------------------------------
function PANEL:LoadToolsFromTable( inTable )
	self.ToolTable = table.Copy( inTable )
	
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
--   Name: AddCategory
-----------------------------------------------------------
function PANEL:AddCategory( Name, Label, tItems, CategoryID )

	--local Category = self.List:AddNode( Label )
	local Category = self.CategoryLookup[Name]
	if not Category then
		-- error("Wire spawn menu error: unable to find category node! (error nr 2)")
		-- fail silently instead, otherwise the entire tool menu fucks up
		return
	end

	Category:SetCookieName( "ToolMenu." .. tostring( Name ) )
	
	local bAlt = true
	
	for k, v in pairs( tItems ) do
	
		v.Category = Label
		v.CategoryID = CategoryID
	
		local item = Category:AddNode( v.Text )
		item.Icon:SetImage( "icon16/wrench.png" )
		
		item.DoClick = function( button )

			spawnmenu.ActivateTool( button.Name )

		end
		
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


local old
hook.Add( "PopulateToolMenu", "Wire_CustomSpawnMenu", function()
	local ToolMenu = vgui.GetControlTable( "ToolMenu" )

	old = ToolMenu.AddToolPanel
	function ToolMenu:AddToolPanel( Name, ToolTable )
		if ToolTable.Label == "Wire" then
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
