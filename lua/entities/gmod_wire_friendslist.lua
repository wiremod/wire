AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Friends List"
ENT.WireDebugName	= "Friends List"

local function sync_all_friends()
	local friends = {}
	for k,v in ipairs(player.GetAll()) do
		--if v:GetFriendStatus() ~= "friend" then continue end--commented for testing purposes
		table.insert(friends, v)
	end
	if not table.IsEmpty(friends) then
		net.Start("wire_sync_steam_friends")
		net.WriteTable(friends)
		net.SendToServer()
	end
end

net.Receive("wire_sync_steam_friends", function()
	sync_all_friends()
	timer.Create("Wire_Friendslist_Sync_Steam", 300, 0, sync_all_friends)
end)

if CLIENT then return end -- No more client

function ENT:Initialize()
	BaseClass.Initialize( self )

	WireLib.CreateInputs( self, {"CheckEntity [ENTITY]", "CheckSteamID [STRING]", "CheckEntityID"} )
	WireLib.CreateOutputs( self, {"Checked", "Friends [ARRAY]", "AmountConnected", "AmountTotal"} )

	self.friends_lookup = {}
	self.steamids = {}
	self.steamids_lookup = {}
	self.save_on_entity = false
	self:UpdateOutputs()
end

util.AddNetworkString("wire_sync_steam_friends")

net.Receive("wire_sync_steam_friends", function(len,ply)
	if not ply.wire_steam_friendslists or ply.wire_steam_friendslists < 1 then return end
	local tab = net.ReadTable()
	ply.wire_steam_friends = tab
	for k,v in ipairs(ents.FindByClass("gmod_wire_friendslist")) do
		v:UpdateOutputs()
	end
end)

function ENT:Setup( save_on_entity, friends_steamids, sync_with_steam )
	self.save_on_entity = false
	self:UpdateFriendslist( friends_steamids )
	self.save_on_entity = save_on_entity or false
	self.sync_with_steam = sync_with_steam or false
	local ply = self:GetPlayer()
	if sync_with_steam then
		ply.wire_steam_friendslists = ply.wire_steam_friendslists and ply.wire_steam_friendslists + 1 or 1
		net.Start("wire_sync_steam_friends")
		net.Send(ply)
	end
	self:UpdateOutputs()
end

function ENT:OnRemove()
	if not self.sync_with_steam then return end
	local ply = self:GetPlayer()
	ply.wire_steam_friendslists = ply.wire_steam_friendslists - 1
end

function ENT:UpdateFriendslist( friends_steamids )
	if self.save_on_entity then return end

	self.friends_lookup = {}

	self.steamids = table.Copy(friends_steamids)
	self.steamids_lookup = {}
	for i=1,#friends_steamids do
		self.steamids_lookup[friends_steamids[i]] = true
	end

	local plys = player.GetHumans()
	for i=1,#plys do
		self:Connected( plys[i] )
	end

	self:UpdateOutputs()
end

function ENT:Connected( ply )
	local steamid = ply:SteamID()

	-- already added
	if self.friends_lookup[ply] then return end

	if self.steamids_lookup[ply:SteamID()] then
		self.friends_lookup[ply] = true
		self:UpdateOutputs()
	end
end

function ENT:Disconnected( ply )
	local steamid = ply:SteamID()

	if self.sync_with_steam and self:GetPlayer() and self:GetPlayer().wire_steam_friends then
		local owner = self:GetPlayer()
		local changed = false
		for k,v in ipairs(owner.wire_steam_friends) do
			if not table.HasValue(owner.wire_steam_friends, v) then continue end
			changed = true
			timer.Simple(0, function() table.remove(owner.wire_steam_friends, k) end)
		end
		if changed then
			timer.Simple(.25, function() self:UpdateOutputs() end)
		end
	else
		-- not already added
		if not self.friends_lookup[ply] then return end

		if self.steamids_lookup[ply:SteamID()] then
			self.friends_lookup[ply] = nil
			self:UpdateOutputs()
		end
	end
end

hook.Add( "PlayerInitialSpawn", "wire_friendslist_connect", function( ply )
	local friendslists = ents.FindByClass( "gmod_wire_friendslist" )
	for i=1,#friendslists do friendslists[i]:Connected( ply ) end
end)
hook.Add( "PlayerDisconnected", "wire_friendslist_disconnect", function( ply )
	local friendslists = ents.FindByClass( "gmod_wire_friendslist" )
	for i=1,#friendslists do friendslists[i]:Disconnected( ply ) end
end)

function ENT:TriggerInput( name, value )
	local ply

	if name == "CheckEntity" then
		ply = value
	elseif name == "CheckSteamID" then
		ply = player.GetBySteamID( value )
	elseif name == "CheckEntityID" then
		ply = Entity(value)
	end

	if not IsValid( ply ) then return end

	if self.friends_lookup[ply] then
		WireLib.TriggerOutput( self, "Checked", 1 )
	else
		WireLib.TriggerOutput( self, "Checked", -1 )
	end

	timer.Remove( "wire_friendslist_" .. self:EntIndex() )
	timer.Create( "wire_friendslist_" .. self:EntIndex(), 0.1, 1, function()
		if IsValid( self ) then
			WireLib.TriggerOutput( self, "Checked", 0 )
		end
	end)
end

function ENT:UpdateOutputs()
	local str = {}
	str[#str+1] = "Saved on entity: " .. (self.save_on_entity and "Yes" or "No") .. "\n"
	str[#str+1] = #self.steamids .. " total friends"
	str[#str+1] = "\nConnected:"

	local ply = self:GetPlayer()

	local not_connected = {}
	local connected = {}
	local total = #self.steamids
	for i=1, total do
		local steamid = self.steamids[i]
		local ply = player.GetBySteamID( steamid )

		if IsValid( ply ) then
			str[#str+1] = ply:Nick() .. " (" .. steamid .. ")"
			connected[#connected+1] = ply
		else
			not_connected[#not_connected+1] = steamid
		end
	end
	if self.sync_with_steam and ply.wire_steam_friends then
		for k,v in pairs(ply.wire_steam_friends) do
			if table.HasValue(connected, v) then continue end
			if not IsValid(v) then continue end
			str[#str+1] = v:Nick() .. " (" .. v:SteamID() .. ")"
			total = total + 1
			table.insert(connected, v)
		end
		--table.Merge(connected, wire_steam_friends)
	end
	table.insert( str, 2, #connected .. " connected friends" )

	WireLib.TriggerOutput( self, "Friends", connected )
	WireLib.TriggerOutput( self, "AmountConnected", #connected )
	WireLib.TriggerOutput( self, "AmountTotal", total )

	local str = table.concat( str, "\n" )
	if #not_connected > 0 then str = str .. "\n\nNot connected:\n" .. table.concat( not_connected, "\n" ) end
	self:SetOverlayText( str )
end

duplicator.RegisterEntityClass("gmod_wire_friendslist", WireLib.MakeWireEnt, "Data", "save_on_entity", "steamids")
