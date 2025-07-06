-- Networking functions

util.AddNetworkString("WireMapInterfaceEntities")

local function resetNetworking(ply)
	local wireMapInterfaceEntities = ents.FindByClass("info_wiremapinterface")
	for i, ent in ipairs(wireMapInterfaceEntities) do
		local delay = 1 + i / 2

		-- Trigger a networking call in a staggered + debounced matter.
 		local nextNetworkTime = math.max(ent.NextNetworkTime, CurTime() + delay)
		ent:RequestNetworkEntities(ply, nextNetworkTime)
	end
end

gameevent.Listen("player_activate")
hook.Add("player_activate", "WireMapInterface_PlayerActivate", function(data)
	-- Make sure the newly spawned player is ready for networking.
	-- Networking in PlayerInitialSpawn is said to be unreliable.

	local ply = Player(data.userid)
	resetNetworking(ply)
end)

hook.Add("PostCleanupMap", "WireMapInterface_PostCleanupMap_SV", function()
	-- Reset networking on map clear. It repairs it in case it got desynced.
	resetNetworking()
end)

function ENT:HandleShouldNetworkEntities()
	if not self.ShouldNetworkEntities then
		return
	end

	local now = CurTime()
	local nextNetworkTime = self.NextNetworkTime

	if not nextNetworkTime or nextNetworkTime > now then
		-- Debounce the network calls.
		-- The client does not need the changed data that often.
		return
	end

 	self:NetworkWireEntities()
	self:AttachToSaveStateEntity()

	self.ShouldNetworkEntities = false
	self.NextNetworkTime = now + self.MIN_THINK_TIME * 4
end

function ENT:RequestNetworkEntities(ply, networkAtTime)
	self.ShouldNetworkEntities = true

	if networkAtTime then
		self.NextNetworkTime = networkAtTime
	end

	local recipientFilter = self.NetworkRecipientFilter

	if not IsValid(ply) then
		recipientFilter:AddAllPlayers()
		return
	end

	recipientFilter:AddPlayer(ply)
end

function ENT:NetworkWireEntities()
	-- Network the list and properties of the wire entities.
	-- We need we know about them on the client. For cable rendering, tools etc.

	local recipientFilter = self.NetworkRecipientFilter

 	if recipientFilter:GetCount() <= 0 then
		return
	end

	net.Start("WireMapInterfaceEntities")

	net.WriteUInt(self:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(self:FlagGetProtectFromTools())
	net.WriteBool(self:FlagGetProtectFromPhysgun())
	net.WriteBool(self:FlagGetRenderWires())
	net.WriteUInt(self:GetWiredEntityCount(), 6)

	local wireEnts = self:GetWiredEntities()

	for _, wireEnt in ipairs(wireEnts) do
		net.WriteUInt(wireEnt:EntIndex(), MAX_EDICT_BITS)
	end

	net.Send(recipientFilter)

	recipientFilter:RemoveAllPlayers()
end

