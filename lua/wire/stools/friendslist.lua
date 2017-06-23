WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "friendslist", "Friends List", "gmod_wire_friendslist", nil, "Friends Lists" )

if CLIENT then
	language.Add( "tool.wire_friendslist.name", "Friends List Tool (Wire)" )
	language.Add( "tool.wire_friendslist.desc", "Spawns a friends list entity for use with the wire system." )

	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Copy settings" },
	}

	language.Add( "wire_friendslist_save_on_entity", "Save On Entity" )
	language.Add( "wire_friendslist_save_on_entity_tooltip", "When enabled, the friends list will be saved on the entity and carried across in dupes. When disabled, the friends list will mirror any changes you make in this UI." )
	language.Add( "wire_friendslist_invalid_steamid", "Invalid SteamID" )
	language.Add( "wire_friendslist_connected_players", "Currently connected players" )
	language.Add( "wire_friendslist_not_connected", "Not Connected" )


	WireToolSetup.setToolMenuIcon( "icon16/group.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(8)

TOOL.ClientConVar = {
	model = "models/kobilica/value.mdl",
	save_on_entity = 0
}

local friends = {}

if SERVER then
	util.AddNetworkString( "wire_friendslist" )
	net.Receive( "wire_friendslist", function( length, ply )
		friends[ply] = net.ReadTable()

		-- Update all friendslists which have save_on_entity set to false
		local friendslists = ents.FindByClass( "gmod_wire_friendslist" )
		for i=1,#friendslists do
			local ent = friendslists[i]
			if ent:GetPlayer() == ply then
				ent:UpdateFriendslist( friends[ply] or {} )
			end
		end
	end)

	function TOOL:GetConVars()
		return self:GetClientNumber( "save_on_entity" ) ~= 0, friends[self:GetOwner()] or {}
	end

	hook.Add( "OnEntityCreated", "wire_friendslist_created", function( ent )
		if ent:GetClass() == "gmod_wire_friendslist" then
			timer.Simple( 0, function() -- wait for wire to set the GetPlayer variable
				if IsValid( ent ) then
					ent:UpdateFriendslist( friends[ent:GetPlayer()] or {} )
				end
			end)
		end
	end)

	-- Right click to copy
	function TOOL:RightClick(trace)
		if not self:CheckHitOwnClass(trace) then return false end

		friends[self:GetOwner()] = trace.Entity.steamids
		net.Start( "wire_friendslist" )
			net.WriteTable( trace.Entity.steamids )
		net.Send( self:GetOwner() )
	end
else
	function TOOL:RightClick(trace)
		return self:CheckHitOwnClass(trace)
	end

	local function loadFile()
		if not file.Exists( "wire_friendslist.txt", "DATA" ) then return {} end
		local str = file.Read( "wire_friendslist.txt", "DATA" )
		local t = string.Explode( ",", str )

		local ret = {}
		for i=1,#t do
			local str = string.Trim(t[i])
			if string.match( str, "^STEAM_%d:%d:%d+$") ~= nil then
				ret[#ret+1] = str
			end
		end

		return ret
	end

	local function saveFile( friends )
		file.Write( "wire_friendslist.txt", table.concat(friends,",") )
	end

	local function sendFriends( dontsave )
		if #friends == 0 then return end

		net.Start("wire_friendslist")
			net.WriteTable(friends)
		net.SendToServer()

		if not dontsave then
			saveFile( friends )
		end
	end

	-- Receive values for copying
	local cpanel_list
	net.Receive( "wire_friendslist", function( length )
		friends = net.ReadTable()
		saveFile( friends )

		if not IsValid(cpanel_list) then -- They right clicked without opening the cpanel first, just save the values
			return
		end

		cpanel_list:Clear()
		for i=1,#friends do
			local ply = player.GetBySteamID( friends[i] )
			local col2 = "#wire_friendslist_not_connected"
			if IsValid(ply) then col2 = ply:Nick() end
			cpanel_list:AddLine( friends[i], col2 )
		end
	end)

	local function addSteamID( steamid )
		for i=1,#friends do
			if friends[i] == steamid then return false end
		end

		if string.match( steamid, "^STEAM_%d:%d:%d+$") == nil then
			WireLib.AddNotify( LocalPlayer(), "#wire_friendslist_invalid_steamid", NOTIFY_ERROR, 8, NOTIFYSOUND_ERROR1 )
			return false
		end

		friends[#friends+1] = steamid
		sendFriends()
		return true
	end

	local function removeSteamID( steamid )
		for i=1,#friends do
			if friends[i] == steamid then
				table.remove( friends, i )
				return true
			end
		end
		return false
	end

	hook.Add( "Initialize", "wire_friendslist_init", function()
		timer.Simple( 5, function()
			friends = loadFile()
			sendFriends( true )
		end)
	end)

	function TOOL.BuildCPanel(panel)
		-- Use the same models as the wire constant value
		WireToolHelpers.MakeModelSizer(panel, "wire_friendslist_modelsize")
		ModelPlug_AddToCPanel(panel, "Value", "wire_friendslist", true)

		local save_on_entity = panel:CheckBox( "#wire_friendslist_save_on_entity", "wire_friendslist_save_on_entity" )
		save_on_entity:SetToolTip( "#wire_friendslist_save_on_entity_tooltip" )

		local pnl = vgui.Create( "DPanel", panel )
		pnl:Dock( TOP )
		pnl:DockMargin( 2,2,2,2 )
		pnl:DockPadding( 2,2,2,2 )

		local list = vgui.Create( "DListView", pnl )
		list:AddColumn( "SteamID" )
		list:AddColumn( "Name" )
		list:SetMultiSelect( false )
		list:Dock( TOP )
		list:SetHeight( 200 )
		cpanel_list = list

		local txt = vgui.Create( "DTextEntry", pnl )
		txt:Dock( TOP )

		local btn_add = vgui.Create( "DButton", pnl )
		btn_add:Dock( TOP )
		btn_add:SetText( "Add" )

		function btn_add:DoClick()
			local steamid = string.upper(string.Trim(txt:GetValue()))

			if addSteamID( steamid ) then
				local ply = player.GetBySteamID( steamid )
				local col2 = "#wire_friendslist_not_connected"
				if IsValid(ply) then col2 = ply:Nick() end
				list:AddLine( steamid, col2 )

				txt:SetValue( "" )
			end
		end

		local btn_remove = vgui.Create( "DButton", pnl )
		btn_remove:Dock( TOP )
		btn_remove:SetText( "Remove" )

		function btn_remove:DoClick()
			local selected = list:GetSelectedLine()

			if selected then
				local steamid = list:GetLine( selected ):GetColumnText( 1 )
				list:RemoveLine( selected )

				if removeSteamID( steamid ) then
					sendFriends()
				end
			end
		end

		for i=1,#friends do
			local ply = player.GetBySteamID( friends[i] )
			local col2 = "#wire_friendslist_not_connected"
			if IsValid(ply) then col2 = ply:Nick() end
			list:AddLine( friends[i], col2 )
		end

		local pnl2 = vgui.Create( "DPanel", panel )
		pnl2:Dock( TOP )
		pnl2:DockMargin( 2,2,2,2 )
		pnl2:DockPadding( 2,2,2,2 )

		local lbl = vgui.Create( "DLabel", pnl2 )
		lbl:SetText( "#wire_friendslist_connected_players" )
		lbl:SizeToContents()
		lbl:Dock( TOP )
		lbl:SetTextColor( Color(0,0,0,255) )

		local connected_list = vgui.Create( "DListView", pnl2 )
		connected_list:Dock( TOP )
		connected_list:AddColumn( "SteamID" )
		connected_list:AddColumn( "Name" )
		connected_list:SetHeight( 200 )

		function connected_list:OnRowSelected( index, row )
			txt:SetValue(row:GetColumnText( 1 ))
		end

		local refresh = vgui.Create( "DButton", pnl2 )
		refresh:Dock( TOP )
		refresh:SetText( "Refresh" )
		function refresh:DoClick()
			connected_list:Clear()
			local plys = player.GetHumans()
			for i=1,#plys do
				connected_list:AddLine( plys[i]:SteamID(), plys[i]:Nick() )
			end
		end

		refresh:DoClick()

		-- wanted to use SizeToContents here but it didn't work, thanks garry
		pnl:SetHeight( 268 )
		pnl2:SetHeight( 240 )
	end
end
