AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Friends List"
ENT.WireDebugName	= "Friends List"

if CLIENT then return end -- No more client

local allFriendsLists = {}

function ENT:Initialize()
	BaseClass.Initialize( self )

	WireLib.CreateInputs( self, {
		"CheckEntity (Check if this player is in this friends list.\nIf they are, the 'Checked' output becomes 1 for a short time.) [ENTITY]",
		"CheckSteamID (Check if this SteamID is in this friends list.) [STRING]",
		"CheckEntityID (Check if this player is in this friends list.)",
		"Any (Check if any of the players in this array are in this friends list.) [ARRAY]",
		"All (Check if all of the players in this array are in this friends list.) [ARRAY]"
	} )
	WireLib.CreateOutputs( self, {
		"Checked (Outputs 1 for a short time if a check was passed.)",
		"Friends (Outputs all currently connected players who would pass checks in this friends list.) [ARRAY]",
		"AmountConnected (Outputs the size of the 'Friends' array)",
		"AmountTotal (Outputs the size of the list as provided by the friendslist user interface. Does not take Steam or CPPI sync into account.)"
	} )

	self.friends_lookup = {}
	self.steamids = {}
	self.steamids_lookup = {}
	self.save_on_entity = false
	self:UpdateOutputs()

	allFriendsLists[self] = true
end

function ENT:OnRemove()
	BaseClass.OnRemove( self )
	allFriendsLists[self] = nil
end

function ENT:Setup( save_on_entity, friends_steamids, sync_with_steam, sync_with_cppi )
	self.save_on_entity = false
	self.sync_with_steam = sync_with_steam or false
	self.sync_with_cppi = sync_with_cppi or false
	self:UpdateFriendslist( friends_steamids )
	self.save_on_entity = save_on_entity or false
	self:UpdateOutputs()
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
	for i = 1, #plys do
		local ply = plys[i]

		if not self.friends_lookup[ply] then
			local steamid = ply:SteamID()
			if self.steamids_lookup[steamid] then
				self.friends_lookup[ply] = true
			end
		end
	end

	self:UpdateOutputs()
end

function ENT:Connected( ply )
	local steamid = ply:SteamID()

	-- already added
	if self.friends_lookup[ply] then return end

	if self.steamids_lookup[steamid] then
		self.friends_lookup[ply] = true
		self:UpdateOutputs()
	end
end

function ENT:Disconnected( ply )
	if self.steamids_lookup[ply:SteamID()] and self.friends_lookup[ply] then
		self:UpdateOutputs()
	end

	self.friends_lookup[ply] = nil
end

hook.Add( "PlayerInitialSpawn", "wire_friendslist_connect", function( ply )
	for ent in pairs(allFriendsLists) do ent:Connected( ply ) end
end)
hook.Add( "PlayerDisconnected", "wire_friendslist_disconnect", function( ply )
	for ent in pairs(allFriendsLists) do ent:Disconnected( ply ) end
end)

local checkActions = {}

local function isInArray(r, ply)
	if istable(r) then
		for i=1, #r do
			if IsValid(r[i]) and r[i] == ply then
				return true
			end
		end
	end
end

local function checkSingle(self, ply)
	if self.friends_lookup[ply] then
		return true
	end

	if self.sync_with_steam then
		local friends = E2Lib.getSteamFriends(self:GetPlayer())
		if friends ~= nil and friends[ply] == true then
			return true
		end
	end

	if self.sync_with_cppi and self:GetPlayer().CPPIGetFriends then
		if isInArray(self:GetPlayer():CPPIGetFriends(), ply) then
			return true
		end
	end

	return false
end

function checkActions.CheckEntity(self, ply)
	if not IsValid(ply) then return end
	if not ply:IsPlayer() then return end
	return checkSingle(self, ply)
end

function checkActions.CheckSteamID(self, steamID)
	return checkActions.CheckEntity(self, player.GetBySteamID(steamID))
end

function checkActions.CheckEntityID(self, entID)
	return checkActions.CheckEntity(self, Entity(entID))
end

function checkActions.All(self, r)
	local amountChecked = 0
	local amountPassed = 0
	for i=1,#r do
		if IsValid(r[i]) and r[i]:IsPlayer() then
			amountChecked = amountChecked + 1
			if checkSingle(self, r[i]) then
				amountPassed = amountPassed + 1
			else
				return false
			end
		end
	end

	if amountChecked == 0 then return nil end
	return amountChecked == amountPassed
end

function checkActions.Any(self, r)
	local checkedAtLeastOne = nil
	for i=1,#r do
		if IsValid(r[i]) and r[i]:IsPlayer() then
			checkedAtLeastOne = false -- might seem strange but this is supposed to be false
			if checkSingle(self, r[i]) then
				return true
			end
		end
	end
	return checkedAtLeastOne
end

function ENT:TriggerInput( name, value )
	-- the check function should return true if matched, false if not matched, and nil if no check was performed (not a valid player, etc)
	local check = checkActions[name]( self, value )

	if check == true then
		WireLib.TriggerOutput( self, "Checked", 1 )
	elseif check == false then
		WireLib.TriggerOutput( self, "Checked", -1 )
	elseif check == nil then
		-- this means the entity wasn't valid, no check was performed
		return
	end

	timer.Remove( "wire_friendslist_" .. self:EntIndex() )
	timer.Create( "wire_friendslist_" .. self:EntIndex(), 0.1, 1, function()
		if IsValid( self ) then
			WireLib.TriggerOutput( self, "Checked", 0 )
		end
	end)
end

function ENT:UpdateOutputs()
	local str = {
		"Saved on entity: " .. (self.save_on_entity and "Yes" or "No"),
		"Syncing with Steam Friends: " .. (self.sync_with_steam and "Yes" or "No"),
		"Syncing with CPPI: " .. (self.sync_with_cppi and "Yes" or "No") .. "\n",
		"", -- reserved slot for nr of connected
		#self.steamids .. " total friends",
		"\nConnected:"
	}

	local not_connected = {}
	local connected = {}

	local plys = player.GetHumans()
	for i=1, #plys do
		local ply = plys[i]
		if checkSingle(self, ply) == true then
			str[#str+1] = ply:Nick() .. " (" .. ply:SteamID() .. ")"
			connected[#connected+1] = ply
		end
	end

	for i=1, #self.steamids do
		local steamid = self.steamids[i]
		local ply = player.GetBySteamID( steamid )

		if not IsValid( ply ) then
			not_connected[#not_connected+1] = steamid
		end
	end

	str[4] = #connected .. " connected friends"

	WireLib.TriggerOutput( self, "Friends", connected )
	WireLib.TriggerOutput( self, "AmountConnected", #connected )
	WireLib.TriggerOutput( self, "AmountTotal", #self.steamids )

	local str = table.concat( str, "\n" )
	if #not_connected > 0 then str = str .. "\n\nNot connected:\n" .. table.concat( not_connected, "\n" ) end
	self:SetOverlayText( str )
end

duplicator.RegisterEntityClass("gmod_wire_friendslist", WireLib.MakeWireEnt, "Data", "save_on_entity", "steamids")
