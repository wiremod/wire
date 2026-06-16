-- This part of the wire map interface entity controls
-- the adding and removing of its in-/outputs entities.

function ENT:HandleWireEntNameUpdated()
	if not self.WireEntNameUpdated then
		return
	end

	self:AddEntitiesByName(self.WireEntName)
	self.WireEntNameUpdated = nil
end

function ENT:HandleWireEntsUpdated()
	if not self.WireEntsUpdated then
		return
	end

	local ready = false

	if self.WireEntsRemoved then
		self:TriggerHammerOutputSafe("OnWireEntsRemoved", self)
		self.WireEntsRemoved = nil
		ready = true
	end

	if self.WireEntsAdded then
		if self:GetWiredEntityCount() > 0 then
			-- Avoid triggering "created" event if the list if entity is actually empty.
			self:TriggerHammerOutputSafe("OnWireEntsCreated", self)
			ready = true
		end

		self.WireEntsAdded = nil
	end

	if ready then
		-- Only trigger "ready" if one of the other both had been triggered.
		self:TriggerHammerOutputSafe("OnWireEntsReady", self)
	end

	self.NextNetworkTime = math.max(self.NextNetworkTime or 0, CurTime() + self.MIN_THINK_TIME * 2)
	self.WireEntsUpdated = nil
end

-- Entity add functions
function ENT:AddEntitiesByName(name)
	local entities = self:GetEntitiesByTargetnameOrClass(name)
	self:AddEntitiesByTable(entities)
end

function ENT:AddEntitiesByTable(entitiesToAdd)
	if not entitiesToAdd then return end

	local tmp = {}

	for key, value in pairs(entitiesToAdd) do
		if isentity(key) and IsValid(key) then
			tmp[key] = key
		end

		if isentity(value) and IsValid(value) then
			tmp[value] = value
		end
	end

	for _, wireEnt in pairs(tmp) do
		self:AddSingleEntity(wireEnt)
	end
end

function ENT:AddSingleEntity(wireEnt)
	if not self:IsWireableEntity(wireEnt) then
		return
	end

	local hardLimit = self.WireEntsHardLimit or 0

	if hardLimit >= self:GetMaxSubEntities() * 3 then
		-- Stop adding more things until cleaned up.
		return
	end

	local id = wireEnt:EntIndex()
	local wireEnts = self.WireEntsRegister

	local item = wireEnts[id]
	local oldWireEnt = item and item.ent

	local isInList = IsValid(oldWireEnt) and oldWireEnt == wireEnt

	if isInList and wireEnt._WireMapInterfaceEnt_HasPorts then
		return
	end

	if not isInList then
		if not self.WireEntsUpdated then
			self:TriggerHammerOutputSafe("OnWireEntsStartChanging", self)
		end

		self:OverrideEnt(wireEnt)
	end

	if wireEnt._WMI_AddPorts then
		wireEnt:_WMI_AddPorts(self.WireInputRegister, self.WireOutputRegister)
	end

	wireEnts[id] = {
		ent = wireEnt,
		cid = wireEnt:GetCreationID(),
	}

	if not isInList then
		self.WireEntsHardLimit = hardLimit + 1

		self.WireEntsUpdated = true
		self.WireEntsAdded = true

		self:RequestNetworkEntities()
		self.WireEntsSorted = nil
		self.WireEntsCount = nil
	end

	self:ApplyWireOutputBufferSingle(wireEnt)

	-- Sometimes CurTime() may get lag compensated and "time travels" when the entity is being added by duplicator/gun trigger.
	-- So we delay the think call past the predicted event time to avoid any race conditions.
	self:NextThink(CurTime() + self.MIN_THINK_TIME)
	return wireEnt
end

-- Entity remove functions
function ENT:RemoveAllEntities()
	local wireEnts = self.WireEntsRegister

	for id, item in pairs(wireEnts) do
		self:RemoveSingleEntity(item.ent)
		wireEnts[id] = nil
	end

	self.WireEntsSorted = nil
	self.WireEntsCount = nil
	self.WireEntsHardLimit = nil
end

function ENT:RemoveEntitiesByName(name)
	local entities = self:GetEntitiesByTargetnameOrClass(name)
	self:RemoveEntitiesByTable(entities)
end

function ENT:RemoveEntitiesByTable(entitiesToRemove)
	if not entitiesToRemove then return end

	local tmp = {}

	for key, value in pairs(entitiesToRemove) do
		if isentity(key) and IsValid(key) then
			tmp[key] = key
		end

		if isentity(value) and IsValid(value) then
			tmp[value] = value
		end
	end

	for _, wireEnt in pairs(tmp) do
		self:RemoveSingleEntity(wireEnt)
	end
end

function ENT:RemoveSingleEntity(wireEnt)
	if not IsValid(wireEnt) then return end
	if not IsValid(wireEnt._WireMapInterfaceEnt) then return end
	if wireEnt._WireMapInterfaceEnt ~= self then return end

	local id = wireEnt:EntIndex()
	local wireEnts = self.WireEntsRegister

	if not wireEnts[id] then
		return
	end

	if wireEnt._WMI_RemoveOverrides then
		wireEnt:_WMI_RemoveOverrides(self)
	end

	wireEnts[id] = nil
	self.WireEntsSorted = nil
	self.WireEntsCount = nil
end

function ENT:UnregisterWireEntityInternal(wireEnt)
	if not IsValid(wireEnt) then
		return
	end

	local wireEnts = self.WireEntsRegister
	local id = wireEnt:EntIndex()

	if not wireEnts[id] then
		return
	end

	if not self.WireEntsUpdated then
		self:TriggerHammerOutputSafe("OnWireEntsStartChanging", self)
	end

	wireEnts[id] = nil
	wireEnt._WireMapInterfaceEnt = nil

	local hardLimit = self.WireEntsHardLimit or 0
	self.WireEntsHardLimit = math.max(hardLimit - 1, 0)

	self.WireEntsUpdated = true
	self.WireEntsRemoved = true

	self:RequestNetworkEntities()
	self.WireEntsSorted = nil
	self.WireEntsCount = nil

	-- Sometimes CurTime() may get lag compensated and "time travels" when the entity is being destoryed by gun fire.
	-- So we delay the think past the predicted event time to avoid any race conditions.
	self:NextThink(CurTime() + self.MIN_THINK_TIME)
end

function ENT:SanitizeAndSortWiredEntities()
	local wireEnts = self.WireEntsRegister

	if not wireEnts or table.IsEmpty(wireEnts) then
		self.WireEntsSorted = {}
		self.WireEntsCount = 0
		self.WireEntsHardLimit = nil

		return
	end

	for id, item in pairs(wireEnts) do
		local wireEnt = item.ent

		if not self:IsWireableEntity(wireEnt) or
			not wireEnt._IsWireMapInterfaceSubEntity or
			not wireEnt._WireMapInterfaceEnt_Data or
			not wireEnt._WMI_GetSpawnId
		then
			-- Remove invalid/broken wire entities.

			if IsValid(wireEnt) then
				if wireEnt._WMI_RemoveOverrides then
					wireEnt:_WMI_RemoveOverrides(self)
				end
			end

			wireEnts[id] = nil
		end
	end

	local count = 0
	local wireEntsSorted = {}

	for id, item in SortedPairsByMemberValue(wireEnts, "cid", false) do
		local wireEnt = item.ent

		if self:CheckEntLimit(count, wireEnt) then
			count = count + 1
			wireEntsSorted[count] = wireEnt
		else
			-- Remove newest wire entities first if limit is exhausted.
			if wireEnt._WMI_RemoveOverrides then
				wireEnt:_WMI_RemoveOverrides(self)
			end

			wireEnts[id] = nil
		end
	end

	self.WireEntsSorted = wireEntsSorted
	self.WireEntsCount = count
	self.WireEntsHardLimit = nil
end

function ENT:GetWiredEntities()
	if not self.WireEntsSorted then
		self:SanitizeAndSortWiredEntities()
	end

	return self.WireEntsSorted
end

function ENT:GetWiredEntityCount()
	if not self.WireEntsCount then
		self:SanitizeAndSortWiredEntities()
	end

	return self.WireEntsCount
end

function ENT:SetWiredEntities(entities)
	if not entities then return end

	self:RemoveAllEntities()
	self:AddEntitiesByTable(entities)
end

