-- This is a helper entity to store save state data wire map interface entities. (info_wiremapinterface_savestate)
-- Only one per map will be spawned during run time. This is needed because info_wiremapinterface can not and also must not be duplicated/saved.
-- When a game is saved, this entity will be save along with it.
-- When the entity is restored, it deploys its saved data to all interface entities it knows about.

ENT.Base = "base_point"
ENT.Type = "point"

ENT.Spawnable = false
ENT.AdminOnly = true

-- Needed for save game support
ENT.DisableDuplicator = false

-- This entity is for saves only.
-- So block all tools, especially dublicator tools and its area copy feature.
-- This entity not traceable nor visible, so other tools would not matter.
ENT.m_tblToolsAllowed = {}

local g_SaveStateEntity = nil
local g_interfaceEntities = {}
local g_saveState = {}

function ENT:Initialize()
	if self:CreatedByMap() then
		self:Remove()
		g_SaveStateEntity = nil
		return
	end

	if IsValid(g_SaveStateEntity) and g_SaveStateEntity ~= self then
		-- Never allow more than one instance of this entity.
		g_SaveStateEntity:Remove()
	end

	g_SaveStateEntity = self
end

function ENT:OnReloaded()
	-- Easier for debugging.
	self:Remove()
	g_SaveStateEntity = nil

	local wireMapInterfaceEntities = ents.FindByClass("info_wiremapinterface")
	for _, ent in ipairs(wireMapInterfaceEntities) do
		if IsValid(ent) then
			ent:OnReloaded()
		end
	end
end

function ENT:AddInterface(interfaceEnt)
	if not self:IsValidInterface(interfaceEnt) then
		return
	end

	local spawnId = interfaceEnt:GetSpawnId()
	if not spawnId then
		return
	end

	if IsValid(g_interfaceEntities[spawnId]) then
		return
	end

	g_interfaceEntities[spawnId] = interfaceEnt
end

function ENT:IsValidInterface(interfaceEnt)
	if not IsValid(interfaceEnt) then
		return false
	end

	if not interfaceEnt.IsWireMapInterface then
		return false
	end

	if not interfaceEnt:CreatedByMap() then
		return false
	end

	return true
end

function ENT:GetInterfaceByIdCombo(mapId, spawnId)
	if not spawnId then
		return nil
	end

	mapId = tonumber(mapId or 0) or 0

	if not WireLib.WireMapInterfaceValidateId(mapId) then
		return nil
	end

	local interfaceEnt = g_interfaceEntities[spawnId]

	if not self:IsValidInterface(interfaceEnt) then
		interfaceEnt = ents.GetMapCreatedEntity(mapId)

		if not self:IsValidInterface(interfaceEnt) then
			return nil
		end
	end

	if not interfaceEnt:ValidateDupedMapId(mapId, spawnId) then
		return nil
	end

	return interfaceEnt
end

function ENT:PreEntityCopy()
	if self:IsMarkedForDeletion() then
		return
	end

	duplicator.ClearEntityModifier(self, "WireMapInterfaceSaveStateInfo")

	local entries = {}

	for spawnId, interfaceEnt in pairs(g_interfaceEntities) do
		if self:IsValidInterface(interfaceEnt) then
			local saveData = interfaceEnt:OnSaveCopy()

			if saveData then
				entries[spawnId] = saveData

				if not g_saveState[spawnId] then
					g_saveState[spawnId] = saveData
				end
			end
		else
			g_interfaceEntities[spawnId] = nil
		end
	end

	duplicator.StoreEntityModifier(self, "WireMapInterfaceSaveStateInfo", {
		interfaceEntries = entries
	})
end

function ENT:OnDuplicated()
	if self:IsMarkedForDeletion() then
		return
	end

	local entityMods = self.EntityMods
	if not entityMods then
		return
	end

	local wireMapInterfaceSaveStateInfo = entityMods.WireMapInterfaceSaveStateInfo
	if not wireMapInterfaceSaveStateInfo then
		return
	end

	local entries = wireMapInterfaceSaveStateInfo.interfaceEntries
	if not entries then
		return
	end

	for spawnId, saveData in pairs(entries) do
		local interfaceEnt = self:GetInterfaceByIdCombo(saveData.mapId, spawnId)
		if interfaceEnt then
			g_interfaceEntities[spawnId] = interfaceEnt
			g_saveState[spawnId] = saveData

			interfaceEnt:OnDuplicatedSave(saveData)
		end
	end
end

function ENT:PostEntityPaste(ply, ent, createdEntities)
	if self:IsMarkedForDeletion() then
		return
	end

	for spawnId, saveData in pairs(g_saveState) do
		local interfaceEnt = self:GetInterfaceByIdCombo(saveData.mapId, spawnId)

		if interfaceEnt then
			g_interfaceEntities[spawnId] = interfaceEnt
			interfaceEnt:OnSavePaste(ply, saveData, createdEntities)
		end
	end
end

