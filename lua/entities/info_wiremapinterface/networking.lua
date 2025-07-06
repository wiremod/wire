-- Networking functions

util.AddNetworkString("WireMapInterfaceEntities")

local function resetNetworking()
	local wireMapInterfaceEntities = ents.FindByClass("info_wiremapinterface")
	for i, ent in ipairs(wireMapInterfaceEntities) do
		local delay = 1 + i / 2

		-- Trigger a networking call in a staggered + debounced matter.
		ent.ShouldNetworkEntities = true
		ent.NextNetworkTime = CurTime() + 1 + delay
	end
end

hook.Add("PlayerInitialSpawn", "WireMapInterface_PlayerInitialSpawn", resetNetworking)
hook.Add("PostCleanupMap", "WireMapInterface_PostCleanupMap_SV", resetNetworking)

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

function ENT:NetworkWireEntities()
	-- Network the list and properties of the wire entities.
	-- We need we know about them on the client. For cable rendering, tools etc.

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

	net.Broadcast()
end

