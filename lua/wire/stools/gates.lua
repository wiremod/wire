-- Made by Divran 06/01/2012
WireToolSetup.setCategory( "Control" )
WireToolSetup.open( "gates", "Gates", "gmod_wire_gate", nil, "Gates" )

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(30)

-- The limit convars are in lua/wire/wiregates.lua

if SERVER then
	ModelPlug_Register("gate")
end

if CLIENT then
	----------------------------------------------------------------------------------------------------
	-- Tool Info
	----------------------------------------------------------------------------------------------------

	language.Add( "Tool.wire_gates.name", "Gates Tool (Wire)" )
	language.Add( "Tool.wire_gates.desc", "Spawns gates for use with the wire system." )
	language.Add( "Tool.wire_gates.0", "Primary: Create/Update Gate, Secondary: Copy Gate, Reload: Increase angle offset by 45 degrees, Shift+Reload: Unparent gate (If parented)." )

	language.Add( "Tool_wire_gates_searchresultnum", "Number of search results:" )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["parent"] = 0
	TOOL.ClientConVar["noclip"] = 1
	TOOL.ClientConVar["angleoffset"] = 0
	TOOL.ClientConVar["action"] = "+"
	TOOL.ClientConVar["searchresultnum"] = 28

	language.Add( "WireGatesTool_action", "Gate action" )
	language.Add( "WireGatesTool_noclip", "NoCollide" )
	language.Add( "WireGatesTool_parent", "Parent" )
	language.Add( "WireGatesTool_angleoffset", "Spawn angle offset" )
	language.Add( "sboxlimit_wire_gates", "You've hit your gates limit!" )

	function TOOL.BuildCPanel( panel )
		WireDermaExts.ModelSelect(panel, "wire_gates_model", list.Get("Wire_gate_Models"), 3, true)

		local nocollidebox = panel:CheckBox("#WireGatesTool_noclip", "wire_gates_noclip")
		local parentbox = panel:CheckBox("#WireGatesTool_parent","wire_gates_parent")

		panel:Help("When parenting, you should check the nocollide box, or adv duplicator might not dupe the gate.")

		local angleoffset = panel:NumSlider( "#WireGatesTool_angleoffset","wire_gates_angleoffset", 0, 360, 0 )

		function nocollidebox.Button:DoClick()
			self:Toggle()
		end

		function parentbox.Button:DoClick() -- when you check the parent box, check the nocollide box
			self:Toggle()
			if (self:GetChecked() == true) then
				nocollidebox:SetValue(1)
			end
		end

		----------------- GATE SELECTION & SEARCHING

		panel:NumSlider( "#Tool_wire_gates_searchresultnum","wire_gates_searchresultnum", 0, 360, 0 ) 

		-- Create panels
		local searchbox = vgui.Create( "DTextEntry" )
		searchbox:SetToolTip( "Leave empty to show all gates in a tree. Write something to display search results in a list." )

		local tree = vgui.Create( "DTree" )
		local searchlist = vgui.Create( "DListView" )
		searchlist:AddColumn( "Gate Name" )
		searchlist:AddColumn( "Category" )

		local holder = vgui.Create( "DPanel" )
		holder:SetTall( 500 )

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
		local function Search( text )
			text = string_lower(text)

			local results = {}
			for action,gate in pairs( GateActions ) do
				local name = gate.name
				local lowname = string_lower(name)
				if string_find( lowname, text, 1, true ) then -- If it has ANY match at all
					results[#results+1] = { name = gate.name, group = gate.group, action = action, dist = Levenshtein( text, lowname ) }
				end
			end

			table_SortByMember( results, "dist", true )

			return results
		end

		-- Main searching
		local searching
		local anim = 0
		local animstart = 0
		function searchbox:OnTextChanged()
			local text = searchbox:GetValue()
			if text ~= "" then
				if not searching then
					searching = true
					anim = RealTime() + 0.3
					animstart = RealTime()
					holder:InvalidateLayout()

					timer.Simple(0.3,function()
						local w = holder:GetWide() - 4
						tree:SetWide( 0 )
						searchlist:SetWide( w )
						searchlist:SetPos( 2, 2 )
					end)
				end
				local results = Search( text )
				searchlist:Clear()
				for i=1,math.min(#results,GetConVarNumber("wire_gates_searchresultnum")) do
					local result = results[i]

					local line = searchlist:AddLine( result.name, result.group )
					local action = GetConVarString("wire_gates_action")
					if action == result.action then
						line:SetSelected( true )
					end
					line.action = result.action
				end
			else
				if searching then
					searching = false
					anim = RealTime() + 0.3
					animstart = RealTime()
					holder:InvalidateLayout()

					timer.Simple(0.3,function()
						local w = holder:GetWide() - 4
						tree:SetWide( w  )
						searchlist:SetWide( 0 )
						searchlist:SetPos( 2 + w, 2 )
					end)
				end
				searchlist:Clear()
			end
		end

		function searchlist:OnClickLine( line )

			-- Deselect old
			local t = searchlist:GetSelected()
			if t and next(t) then
				t[1]:SetSelected(false)
			end

			line:SetSelected(true) -- Select new
			RunConsoleCommand( "wire_gates_action", line.action )
		end

		panel:AddItem( searchbox )

		-- Set sizes & other settings
		searchlist:SetPos( 500,2 )
		searchlist:SetTall( 496 )
		searchlist:SetParent( holder )
		searchlist:SetMultiSelect( false )

		tree:SetPos( 2,2 )
		tree:SetTall( 496 )
		tree:SetParent( holder )

		timer.Simple(0.1,function()
			local w = holder:GetWide() - 4
			tree:SetWide( w  )
			searchlist:SetWide( 0 )
			searchlist:SetPos( 2 + w, 2 )
		end)

		-- Animation
		function holder:PerformLayout()
			if searching ~= nil then
				local w = holder:GetWide()-4
				if anim >= RealTime() then
					local curanim = anim - RealTime()
					local animpercent = curanim / (anim-animstart)
					local animpercentinv = 1-animpercent

					if searching then
						tree:SetWide( w * animpercent )
						searchlist:SetWide( w * animpercentinv )
						searchlist:SetPos( 2 + w * animpercent, 2 )
					else
						tree:SetWide( w * animpercentinv )
						searchlist:SetWide( w * animpercent )
						searchlist:SetPos( 2 + w * animpercentinv, 2 )
					end

					timer.Simple( 0, function() self:InvalidateLayout() end )
				end
			end
		end

		local function FillSubTree( tree, node, temp )
			node.Icon:SetImage( "icon16/arrow_refresh.png" )

			local subtree = {}
			for k,v in pairs( temp ) do
				subtree[#subtree+1] = { action = k, gate = v, name = v.name }
			end

			table_SortByMember(subtree, "name", true )

			local index = 0
			local max = #subtree

			timer.Create( "wire_gates_fillsubtree_delay"..tostring(subtree), 0, 0, function()
				index = index + 1

				local action, gate = subtree[index].action, subtree[index].gate
				local node2 = node:AddNode( gate.name or "No name found :(" )
				node2.name = gate.name
				node2.action = action
				function node2:DoClick()
					RunConsoleCommand( "wire_gates_Action", self.action )
				end
				node2.Icon:SetImage( "icon16/newspaper.png" )
				tree:InvalidateLayout()

				if index == max then
					timer.Remove("wire_gates_fillsubtree_delay" .. tostring(subtree))
					--timer.Simple(0, function() tree:InvalidateLayout() end)
					if not node.m_bExpanded then
						node:InternalDoClick()
					end
					node.Icon:SetImage( "icon16/folder.png" )
				end
			end )
		end

		for gatetype,gatefuncs in pairs( WireGatesSorted ) do
			local node = tree:AddNode( gatetype .. " Gates" )
			node.Icon:SetImage( "icon16/folder.png" )
			node.first_time = true
			function node:DoClick()
				if self.first_time then
					FillSubTree( tree, self, gatefuncs )
					self.first_time = nil
				end
			end
		end

		-- add it all to the main panel
		panel:AddItem( holder )
	end
end

if SERVER then
	function TOOL:GetConVars() 
		return self:GetClientInfo( "action" ), self:GetClientNumber( "noclip" ) == 1
	end
	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireGate( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

function TOOL:CheckMaxLimit()
	local action	= self:GetClientInfo( "action" )
	return self:GetSWEP():CheckLimit(self.MaxLimitName) and self:GetSWEP():CheckLimit("wire_gate_" .. string.lower( GateActions[action].group ) .. "s")
end


--------------------
-- RightClick
-- Copy gate
--------------------
function TOOL:RightClick( trace )
	if CLIENT then return true end
	if self:CheckHitOwnClass(trace) then
		local action = GateActions[trace.Entity.action]
		assert(action, "Attempted to copy gate " .. tostring(trace.Entity) .. " with no action!")

		self:GetOwner():ConCommand( "wire_gates_action " .. trace.Entity.action )
		self:GetOwner():ChatPrint( "Gate copied ('" .. action.name .. "')." )
		return true
	else
		return false
	end
end

--------------------
-- Reload
-- Increase angle offset by 45 degrees
--------------------
function TOOL:Reload( trace )
	if self:GetOwner():KeyDown( IN_SPEED ) then -- Unparent
		if (!trace or !trace.Hit) then return false end
		if (CLIENT and trace.Entity) then return true end
		if (trace.Entity:GetParent():IsValid()) then

			-- Get its position
			local pos = trace.Entity:GetPos()

			-- Unparent
			trace.Entity:SetParent()

			-- Teleport it back to where it was before unparenting it (because unparenting causes issues which makes the gate teleport to random wierd places)
			trace.Entity:SetPos( pos )

			-- Wake
			local phys = trace.Entity:GetPhysicsObject()
			if (phys) then
				phys:Wake()
			end

			-- Notify
			self:GetOwner():ChatPrint("Entity unparented.")
			return true
		end
		return false
	else
		if game.SinglePlayer() and SERVER then
			self:GetOwner():ConCommand( "wire_gates_angleoffset " .. (self:GetClientNumber( "angleoffset" ) + 45) % 360 )
		elseif CLIENT then
			RunConsoleCommand( "wire_gates_angleoffset", (self:GetClientNumber( "angleoffset" ) + 45) % 360 )
		end
	end

	return false
end

function TOOL:GetAngle( trace )
	local ang = WireToolObj.GetAngle(self, trace)
	ang:RotateAroundAxis( trace.HitNormal, self:GetClientNumber( "angleoffset" ) )
	return ang
end
