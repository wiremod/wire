-- Dupe and save support and validation

local WireLib = WireLib
local WireMapInterfaceLookup = WireLib.WireMapInterfaceLookup

local g_saveStateEntity = nil
local g_mapName = nil

function ENT:GetSaveStateEntity()
	if IsValid(g_saveStateEntity) and not g_saveStateEntity:IsMarkedForDeletion() then
		return g_saveStateEntity
	end

	g_saveStateEntity = nil

	local entities = ents.FindByClass("info_wiremapinterface_savestate")
	for _, ent in ipairs(entities) do
		if IsValid(ent) and not ent:IsMarkedForDeletion() then
			g_saveStateEntity = ent
			return g_saveStateEntity
		end
	end

	local ent = ents.Create("info_wiremapinterface_savestate")
	if not IsValid(ent) then
		return nil
	end

	ent:SetPos(self:GetPos())
	ent:Spawn()
	ent:Activate()

	g_saveStateEntity = ent
	return ent
end

function ENT:AttachToSaveStateEntity()
	local saveState = self:GetSaveStateEntity()
	if IsValid(saveState) then
		saveState:AddInterface(self)
	end
end

function ENT:GetSubEntityByIdCombo(entIdx, mapId, spawnId, createdEntities)
	if not spawnId then
		return nil
	end

	entIdx = tonumber(entIdx)
	mapId = tonumber(mapId)

	if not WireLib.WireMapInterfaceValidateId(entIdx) then
		return nil
	end

	if not WireLib.WireMapInterfaceValidateId(mapId) then
		return nil
	end

	if self:HashSubEntityMapId(entIdx, mapId) ~= spawnId then
		return nil
	end

	local wireEnt = nil

	if createdEntities then
		wireEnt = createdEntities[entIdx]
	end

	if not createdEntities or not IsValid(wireEnt) then
		wireEnt = WireMapInterfaceLookup:getBySpawnIDDuped(spawnId)

		if not IsValid(wireEnt) then
			wireEnt = WireMapInterfaceLookup:getByMapID(mapId)

			if not IsValid(wireEnt) then
				wireEnt = ents.GetMapCreatedEntity(mapId)

				if not IsValid(wireEnt) then
					wireEnt = WireMapInterfaceLookup:getBySpawnID(spawnId)

					if not IsValid(wireEnt) then
						return nil
					end
				end
			end
		end
	end

	return wireEnt
end

function ENT:OnSaveCopy()
	if not self:CreatedByMap() then
		return nil
	end

	local entries = {}
	local wireEnts = self:GetWiredEntities()

	for _, wireEnt in ipairs(wireEnts) do
		local wireEntSpawnId = self:GetSubEntitySpawnId(wireEnt)

		if wireEntSpawnId then
			local entList = entries[wireEntSpawnId] or {}
			entries[wireEntSpawnId] = entList

			entList[wireEnt:EntIndex()] = wireEnt:_WMI_BuildDupeData(self)
		end
	end

	local saveData = {
		spawnId = self:GetSpawnId(),
		mapId = self:MapCreationID(),
		entries = entries,
	}

	return saveData
end

function ENT:OnDuplicatedSave(saveData)
	if not self:CreatedByMap() then
		return
	end

	if not saveData.entries then
		return
	end

	for wireEntSpawnId, entList in pairs(saveData.entries) do
		for entIdx, dupeData in pairs(entList) do
			local wireMapInterfaceEntDupeInfo = dupeData.wireMapInterfaceEntDupeInfo

			if wireMapInterfaceEntDupeInfo then
				local mapId = wireMapInterfaceEntDupeInfo.mapId
				local wireEnt = self:GetSubEntityByIdCombo(entIdx, mapId, wireEntSpawnId)

				if IsValid(wireEnt) and not wireEnt._WMI_ApplyDupeData then
					self:OverrideEntFromDupe(wireEnt, wireMapInterfaceEntDupeInfo)
				end
			end
		end
	end
end

function ENT:OnSavePaste(ply, saveData, createdEntities)
	if not self:CreatedByMap() then
		return
	end

	if not saveData.entries then
		return
	end

	for wireEntSpawnId, entList in pairs(saveData.entries) do
		for entIdx, dupeData in pairs(entList) do
			local wireMapInterfaceEntDupeInfo = dupeData.wireMapInterfaceEntDupeInfo

			if wireMapInterfaceEntDupeInfo then
				local mapId = wireMapInterfaceEntDupeInfo.mapId
				local wireEnt = self:GetSubEntityByIdCombo(entIdx, mapId, wireEntSpawnId, createdEntities)

				if IsValid(wireEnt) and wireEnt._WMI_ApplyDupeData then
					wireEnt:_WMI_ApplyDupeData(ply, dupeData, createdEntities, self)
				end
			end
		end
	end
end

local function buildSpawnId(...)
	if not g_mapName then
		g_mapName = game.GetMap()
	end

	local tmp = {...}

	tmp = table.concat(tmp, "_")

	local id = string.format(
		"WMI_%s_%s_buildSpawnId",
		g_mapName,
		tmp
	)

	-- This not fire proof security, but this is more of a user convenience thing than anything else.
	-- It just prevents unexpected issues from map foreign dupes made by user error.
	-- This is used to check if the dupe/save belongs to the map and the particular Wire Map Interface instance.
	-- Entities not passing the validation will still be pasted and spawned, but they will not get any addional Wiremod functionalities whatsoever.
	-- The validation might not pass across map recompiles, especially if MapCreationIDs change.

	-- In theroy it would be quite possible to crack or bypass this validation with a forged dupe/save file.
	-- For that you just would need to know how was hashed and how the targeted map has been built.

	-- However in practice it would be quite tedious to do so and it would also only be useful if the map has a vulnerability.
	-- In this context the risks a rigged dupe file can pose are quite minimal.

	id = util.SHA1(id)
	return id
end

function ENT:HashMapId(interfaceMapId)
	interfaceMapId = tonumber(interfaceMapId)

	if not WireLib.WireMapInterfaceValidateId(interfaceMapId) then
		return nil
	end

	-- Get a compact and unique spawn identifier per map and interface.
	local id = buildSpawnId(
		interfaceMapId,
		"HashMapId"
	)

	return id
end

function ENT:HashSubEntityMapId(subEntIdx, subEntMapId)
	if not self:CreatedByMap() then
		return nil
	end

	subEntIdx = tonumber(subEntIdx)
	subEntMapId = tonumber(subEntMapId)

	if not WireLib.WireMapInterfaceValidateId(subEntIdx) then
		return nil
	end

	if not WireLib.WireMapInterfaceValidateId(subEntMapId) then
		return nil
	end

	-- Get a compact and unique spawn identifier per map, interface and sub entity.
	local id = buildSpawnId(
		self:MapCreationID(),
		subEntIdx,
		subEntMapId,
		"HashSubEntityMapId"
	)

	return id
end

function ENT:GetSpawnId()
	if not self:CreatedByMap() then
		return nil
	end

	if self.SpawnId then
		return self.SpawnId
	end

	local id = self:HashMapId(self:MapCreationID())

	self.SpawnId = id
	return id
end

function ENT:GetSubEntitySpawnId(subEnt)
	if not IsValid(subEnt) then
		return nil
	end

	if not subEnt._WMI_GetSpawnId then
		return false
	end

	local spawnId = subEnt:_WMI_GetSpawnId(self)
	if not spawnId then
		return nil
	end

	return spawnId
end

function ENT:ValidateDupedMapId(mapCreationID, spawnIdC)
	if not mapCreationID then
		return false
	end

	local spawnIdA = self:GetSpawnId()
	if not spawnIdA then
		return false
	end

	local spawnIdB = self:HashMapId(mapCreationID)
	if not spawnIdB then
		return false
	end

	if spawnIdA ~= spawnIdB then
		return false
	end

	if spawnIdC ~= nil then
		if spawnIdA ~= spawnIdC then
			return false
		end

		if spawnIdB ~= spawnIdC then
			return false
		end
	end

	return true
end

