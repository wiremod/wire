-- Made by Divran 06/01/2012
WireToolSetup.setCategory( "Control" )
WireToolSetup.open( "gates", "Gates", "gmod_wire_gate", nil, "Gates" )

-- The limit convars are in lua/wire/wiregates.lua

if SERVER then
	ModelPlug_Register("gate")
end

cleanup.Register("wire_gates")

if CLIENT then
	----------------------------------------------------------------------------------------------------
	-- Tool Info
	----------------------------------------------------------------------------------------------------

	language.Add( "Tool.wire_gates.name", "Gates Tool (Wire)" )
	language.Add( "Tool.wire_gates.desc", "Spawns gates for use with the wire system." )
	language.Add( "Tool.wire_gates.0", "Primary: Create/Update Gate, Secondary: Copy Gate, Reload: Increase angle offset by 45 degrees, Shift+Reload: Unparent gate (If parented)." )

	language.Add( "Tool_wire_gates_searchresultnum", "Number of search results:" )

	TOOL.ClientConVar["model"] = "models/jaanus/wiretool/wiretool_gate.mdl"
	TOOL.ClientConVar["weld"] = 1
	TOOL.ClientConVar["parent"] = 0
	TOOL.ClientConVar["noclip"] = 1
	TOOL.ClientConVar["angleoffset"] = 0
	TOOL.ClientConVar["action"] = "+"
	TOOL.ClientConVar["searchresultnum"] = 28

	language.Add( "WireGatesTool_action", "Gate action" )
	language.Add( "WireGatesTool_noclip", "NoCollide" )
	language.Add( "WireGatesTool_weld", "Weld" )
	language.Add( "WireGatesTool_parent", "Parent" )
	language.Add( "WireGatesTool_angleoffset", "Spawn angle offset" )
	language.Add( "sboxlimit_wire_gates", "You've hit your gates limit!" )
	language.Add( "undone_gmod_wire_gate", "Undone wire gate" )
	language.Add( "Cleanup_gmod_wire_gate", "Wire Gates" )
	language.Add( "Cleaned_gmod_wire_gate", "Cleaned up wire gates" )

	----------------------------------------------------------------------------------------------------
	-- BuildCPanel
	----------------------------------------------------------------------------------------------------

	function TOOL.BuildCPanel( panel )
		WireDermaExts.ModelSelect(panel, "wire_gates_model", list.Get("Wire_gate_Models"), 3, true)

		local nocollidebox = panel:CheckBox("#WireGatesTool_noclip", "wire_gates_noclip")
		local weldbox = panel:CheckBox("#WireGatesTool_weld", "wire_gates_weld")
		local parentbox = panel:CheckBox("#WireGatesTool_parent","wire_gates_parent")

		panel:AddControl("label",{text="When parenting, you should check the nocollide box, or adv duplicator might not dupe the gate."})

		local angleoffset = panel:NumSlider( "#WireGatesTool_angleoffset","wire_gates_angleoffset", 0, 360, 0 )

		function nocollidebox.Button:DoClick()
			self:Toggle()
		end

		function weldbox.Button:DoClick() -- block the weld checkbox from being toggled while the parent box is checked
			if (parentbox:GetChecked() == false) then
				self:Toggle()
			end
		end

		function parentbox.Button:DoClick() -- when you check the parent box, uncheck the weld box and check the nocollide box
			self:Toggle()
			if (self:GetChecked() == true) then
				weldbox:SetValue(0)
				nocollidebox:SetValue(1)
			end
		end

		----------------- GATE SELECTION & SEARCHING

		local searchresultnum = vgui.Create( "DNumSlider" )
		searchresultnum:SetConVar( "wire_gates_searchresultnum" )
		searchresultnum:SetText( "#Tool_wire_gates_searchresultnum" )
		searchresultnum:SetMin( 1 )
		searchresultnum:SetMax( 100 )
		searchresultnum:SetDecimals( 0 )
		panel:AddItem( searchresultnum )

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
			node.Icon:SetImage( "gui/silkicons/arrow_refresh" )

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
				node2.Icon:SetImage( "gui/silkicons/newspaper" )
				tree:InvalidateLayout()

				if index == max then
					timer.Remove("wire_gates_fillsubtree_delay" .. tostring(subtree))
					--timer.Simple(0, function() tree:InvalidateLayout() end)
					if not node.m_bExpanded then
						node:InternalDoClick()
					end
					node.Icon:SetImage( "gui/silkicons/folder" )
				end
			end )
		end

		for gatetype,gatefuncs in pairs( WireGatesSorted ) do
			local node = tree:AddNode( gatetype .. " Gates" )
			node.Icon:SetImage( "gui/silkicons/folder" )
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

--------------------
-- LeftClick
-- Create/Update Gate
--------------------
function TOOL:LeftClick( trace )
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local ply = self:GetOwner()

	local ent = WireToolMakeGate( self, trace, ply )
	if !isentity(ent) then return true end -- WireToolMakeGate returns a boolean if the player shoots a gate (to update it)

	-- Parenting
	local nocollide
	if self:GetClientNumber( "parent" ) == 1 then
		if (trace.Entity:IsValid()) then

			-- Nocollide the gate to the prop to make adv duplicator (and normal duplicator) find it
			if (!self.ClientConVar.noclip or self:GetClientNumber( "noclip" ) == 1) then
				nocollide = constraint.NoCollide( ent, trace.Entity, 0,trace.PhysicsBone )
			end

			ent:SetParent( trace.Entity )
		end
	end

	-- Welding
	local const
	if self:GetClientNumber( "weld" ) == 1 then
		const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
	end


	undo.Create( "gmod_wire_gate" )
		undo.AddEntity( ent )
		if (const) then undo.AddEntity( const ) end
		if (nocollide) then undo.AddEntity( nocollide ) end
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "gmod_wire_gate", ent )

	return true
end


--------------------
-- RightClick
-- Copy gate
--------------------
function TOOL:RightClick( trace )
	if CLIENT then return true end
	if trace.Entity and trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_gate" then
		local action = GateActions[trace.Entity.action]
		if not action then self:GetOwner():ChatPrint( "Invalid gate (what the-?!?)" ) return end

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

--------------------
-- GetAngle
--------------------
function TOOL:GetAngle( trace )
	local ang = trace.HitNormal:Angle() + Angle(90,0,0)
	ang:RotateAroundAxis( trace.HitNormal, self:GetClientNumber( "angleoffset" ) )
	return ang
end

----------------------------------------------------------------------------------------------------
-- GHOST
----------------------------------------------------------------------------------------------------
if ((game.SinglePlayer() and SERVER) or (!game.SinglePlayer() and CLIENT)) then
	function TOOL:DrawGhost()
		local ent, ply = self.GhostEntity, self:GetOwner()
		if (!ent or !ent:IsValid()) then return end
		local trace = ply:GetEyeTrace()

		if (!trace.Hit or trace.Entity:IsPlayer()) then
			ent:SetNoDraw( true )
			return
		end

		local Pos, Ang = trace.HitPos, self:GetAngle( trace )
		ent:SetPos( Pos )
		ent:SetAngles( Ang )

		ent:SetNoDraw( false )
	end

	function TOOL:Think()
		local model = self:GetModel()
		if (!self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() != model) then
			self:MakeGhostEntity( model, Vector(), Angle() )
		end

		self:DrawGhost()
	end
end
