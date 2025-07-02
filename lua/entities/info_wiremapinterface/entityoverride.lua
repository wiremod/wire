-- Stuff that the entity gets for its wire stuff.

local WireLib = WireLib
local WireMapInterfaceLookup = WireLib.WireMapInterfaceLookup

local WIREENT = {}

local g_wirelinkName = "wirelink"
local g_wireTools = {
	"wire",
	"wire_adv",
	"wire_debugger",
	"wire_wirelink",
	"multi_wire",
}

local g_memberBlacklist = {
	_IsWireMapInterfaceSubEntity = true,
	_WireMapInterfaceEnt_TmpPorts = true,
	_WireMapInterfaceEnt_HasPorts = true,
	_WireMapInterfaceEnt_SpawnId = true,
	_WireMapInterfaceEnt_MapId = true,
	_WireMapInterfaceEnt_Data = true,
	_WireMapInterfaceEnt = true,
	_WMI_OverrideEnt = true,
	_WMI_RemoveOverrides = true,
	PhysgunDisabled = true,
	m_tblToolsAllowed = true,
	Inputs = true,
	Outputs = true,
	IsWire = true,
	WireDebugName = true,
}

function WIREENT:_WMI_GetConnectedWireInputSource(name)
	local wireinputs = self.Inputs
	if not wireinputs then return nil end

	local wireinput = wireinputs[name]
	if not wireinput then return nil end
	if not IsValid(wireinput.Src) then return nil end

	return wireinput.Src
end

function WIREENT:_WMI_GetConnectedWireWirelinkSource()
	local wireoutputs = self.Outputs
	if not wireoutputs then return nil end

	local wireoutput = wireoutputs[g_wirelinkName]
	if not wireoutput then return nil end
	if not wireoutput.Connected then return nil end

	for key, connectedItem in ipairs(wireoutput.Connected) do
		if IsValid(connectedItem.Entity) then
			return connectedItem.Entity
		end
	end

	return nil
end

function WIREENT:_WMI_IsConnectedWireInput(name)
	if not self:_WMI_GetConnectedWireInputSource(name) then return false end
	return true
end

function WIREENT:_WMI_IsConnectedWireOutput(name)
	local wireoutputs = self.Outputs
	if not wireoutputs then return false end

	local wireoutput = wireoutputs[name]
	if not wireoutput then return false end
	if not wireoutput.Connected then return false end

	for key, connectedItem in ipairs(wireoutput.Connected) do
		if IsValid(connectedItem.Entity) then
			return true
		end
	end

	return false
end

function WIREENT:_WMI_IsConnectedWirelink()
	if not self.extended then
		-- wirelink had not been created yet
		return false
	end

	if self:_WMI_IsConnectedWireOutput(g_wirelinkName) then
		-- wirelink had been connected via Wire Tool
		return true
	end

	return false
end

-- Trigger wire input
function WIREENT:TriggerInput(name, value, ext, ...)
	if not name then return end
	if name == "" then return end
	if not value then return end

	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then return end

	local interfaceEnt = self._WireMapInterfaceEnt
	if not IsValid(interfaceEnt) then return end
	if not interfaceEnt.TriggerWireInput then return end

	-- Ensure the Wirelink is actually physically connected. Otherwise it is not possible to detect disconnections.
	-- It is also needed for the custom ownership management this entity has. This entity may change Wiremod owner depeding on the ownership other connected entities.
	-- So using E2 with E:wirelink() does not work for this, as it would bypass prop protection or other protection the map/server has for this map entity.
	local isWirelink = self:_WMI_IsConnectedWirelink() and ext and ext.wirelink
	local wired = self:_WMI_IsConnectedWireInput(name) or isWirelink

	if not isWirelink then
		local realValueBuffer = wmidata.realValueBuffer or {}
		wmidata.realValueBuffer = realValueBuffer

		realValueBuffer[name] = value
	end

	local device = self:_WMI_GetInputDevice(isWirelink and g_wirelinkName or name)

	if not isWirelink then
		wmidata.lastDirectInputDevice = device
	else
		wmidata.lastDirectInputDevice = nil
	end

	interfaceEnt:TriggerWireInput(name, value, wired, self)
end

function WIREENT:_WMI_GetDirectLinkedInputValue(name)
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return nil
	end

	local realValueBuffer = wmidata.realValueBuffer
	if not realValueBuffer then
		return nil
	end

	return realValueBuffer[name]
end

function WIREENT:_WMI_GetInputDevice(name)
	if not name then
		local device = self:_WMI_GetConnectedWireWirelinkSource()

		if not IsValid(device) then
			device = self:_WMI_GetLastDirectInputDevice()
		end

		return device
	end

	if name == g_wirelinkName then
		return self:_WMI_GetConnectedWireWirelinkSource()
	end

	return self:_WMI_GetConnectedWireInputSource(name)
end

function WIREENT:_WMI_GetLastDirectInputDevice()
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return nil
	end

	local device = wmidata.lastDirectInputDevice
	if not IsValid(device) then
		return nil
	end

	return device
end

function WIREENT:_WMI_FindWireMapInterfaceEnt(interface)
	if not interface then
		return nil
	end

	local mapId = interface.mapId
	local spawnId = interface.spawnId

	if not spawnId then
		return nil
	end

	mapId = tonumber(mapId)

	if not WireLib.WireMapInterfaceValidateId(mapId) then
		return nil
	end

	local interfaceEnt = ents.GetMapCreatedEntity(mapId)
	if not IsValid(interfaceEnt) then
		return nil
	end

	if not interfaceEnt.IsWireMapInterface then
		return nil
	end

	if not interfaceEnt:ValidateDupedMapId(mapId, spawnId) then
		return nil
	end

	return interfaceEnt
end

local g_functionCallNesting_GetPlayer = 0

function WIREENT:GetPlayer(...)
	-- Fake the owner of the map owned entity if we don't have one. It is needed for E2 wirelink to work.
	-- It uses the owner of the contected entity e.g. the E2 chip.

	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return nil
	end

	if wmidata.oldMethods.GetPlayer then
		local ply = wmidata.oldMethods.GetPlayer(self, ...)

		if IsValid(ply) then
			return ply
		end
	end

	local dupe = wmidata.dupe
	if dupe and IsValid(dupe.owner) then
		return dupe.owner
	end

	if not self:_WMI_IsConnectedWirelink() then
		-- Owner fake is exclusive to wirelink
		return nil
	end

	local device = self:_WMI_GetInputDevice()
	if not IsValid(device) or device == self then
		return nil
	end

	if g_functionCallNesting_GetPlayer > 5 then
		-- prevent recursive loop
		return nil
	end

	g_functionCallNesting_GetPlayer = g_functionCallNesting_GetPlayer + 1

	local fakeOwner = WireLib.GetOwner(device)

	g_functionCallNesting_GetPlayer = math.max(g_functionCallNesting_GetPlayer - 1, 0)

	return fakeOwner
end

function WIREENT:OnEntityCopyTableFinish(dupedata, ...)
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	if wmidata.oldMethods.OnEntityCopyTableFinish then
		wmidata.oldMethods.OnEntityCopyTableFinish(self, dupedata, ...)
	end

	-- Prevent weird stuff from happening on garry dupe/save
	dupedata.Inputs = nil
	dupedata.Outputs = nil
	dupedata.IsWire = nil

	local oldMembers = wmidata.oldMembers or {}
	for k, v in pairs(oldMembers) do
		dupedata[k] = nil
	end

	local oldSettings = wmidata.oldSettings or {}
	for k, v in pairs(oldSettings) do
		dupedata[k] = nil
	end

	for k, v in pairs(g_memberBlacklist) do
		dupedata[k] = nil
	end
end

function WIREENT:PreEntityCopy(...)
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	if wmidata.oldMethods.PreEntityCopy then
		wmidata.oldMethods.PreEntityCopy(self, ...)
	end

	duplicator.ClearEntityModifier(self, "WireDupeInfo")
	duplicator.ClearEntityModifier(self, "WireMapInterfaceEntDupeInfo")

	local dupeData = self:_WMI_BuildDupeData()

	if dupeData.wireDupeInfo then
		duplicator.StoreEntityModifier(self, "WireDupeInfo", dupeData.wireDupeInfo)
	end

	if dupeData.wireMapInterfaceEntDupeInfo then
		duplicator.StoreEntityModifier(self, "WireMapInterfaceEntDupeInfo", dupeData.wireMapInterfaceEntDupeInfo)
	end
end

function WIREENT:PostEntityPaste(ply, ent, createdEntities, ...)
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	if wmidata.oldMethods.PostEntityPaste then
		wmidata.oldMethods.PostEntityPaste(self, ply, ent, createdEntities, ...)
	end

	if not IsValid(ent) then
		return
	end

	local entityMods = ent.EntityMods
	if not entityMods then
		return
	end

	local dupeData = {
		wireDupeInfo = entityMods.WireDupeInfo,
		wireMapInterfaceEntDupeInfo = entityMods.WireMapInterfaceEntDupeInfo,
	}

	ent:_WMI_ApplyDupeData(ply, dupeData, createdEntities)
end

function WIREENT:_WMI_BuildDupeData(interfaceEnt)
	local data = {}
	local wmiDupeInfo = {}

	data.wireDupeInfo = WireLib.BuildDupeInfo(self)
	data.wireMapInterfaceEntDupeInfo = wmiDupeInfo

	if not IsValid(interfaceEnt) then
		interfaceEnt = self._WireMapInterfaceEnt

		if not IsValid(interfaceEnt) then
			return data
		end
	end

	local interfaceMapId = nil
	if interfaceEnt:CreatedByMap() then
		interfaceMapId = interfaceEnt:MapCreationID()
	end

	local wmidata = self._WireMapInterfaceEnt_Data or {}

	wmiDupeInfo.entIdx = self:EntIndex()
	wmiDupeInfo.mapId = self:_WMI_MapCreationIdDuped()
	wmiDupeInfo.spawnId = self:_WMI_GetSpawnId(interfaceEnt)

	wmiDupeInfo.interface = {
		mapId = interfaceMapId,
		spawnId = interfaceEnt:GetSpawnId(),
	}

	wmiDupeInfo.tmpPorts = {
		inputs = wmidata.inputs,
		outputs = wmidata.outputs,
	}

	return data
end

function WIREENT:_WMI_ApplyDupeData(ply, dupeData, createdEntities, interfaceEnt)
	if not dupeData then
		return
	end

	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	local wireMapInterfaceEntDupeInfo = dupeData.wireMapInterfaceEntDupeInfo or {}
	local wireDupeInfo = dupeData.wireDupeInfo or {}

	local interface = wireMapInterfaceEntDupeInfo.interface
	local tmpPorts = wireMapInterfaceEntDupeInfo.tmpPorts
	local spawnId = wireMapInterfaceEntDupeInfo.spawnId
	local entIdx = wireMapInterfaceEntDupeInfo.entIdx
	local mapId = wireMapInterfaceEntDupeInfo.mapId

	local dupe = wmidata.dupe or {}
	wmidata.dupe = dupe
	dupe.owner = ply

	dupe.mapId = mapId
	dupe.entIdx = entIdx
	dupe.spawnId = spawnId

	local dupeInterfaceEnt = dupe.interfaceEnt
	dupe.interfaceEnt = nil

	if not IsValid(interfaceEnt) then
		interfaceEnt = dupeInterfaceEnt

		if not IsValid(interfaceEnt) then
			interfaceEnt = self:_WMI_FindWireMapInterfaceEnt(interface)

			if not IsValid(interfaceEnt) then
				self:_WMI_RemoveOverrides()
				return
			end
		end
	end

	if not interfaceEnt:IsWireableEntity(self) then
		self:_WMI_RemoveOverrides(interfaceEnt)
		return
	end

	dupe.interfaceEnt = interfaceEnt

	if interfaceEnt:HashSubEntityMapId(entIdx, mapId) ~= spawnId then
		self:_WMI_RemoveOverrides(interfaceEnt)
		return
	end

	self:_WMI_ApplyWireDupeData(ply, wireDupeInfo, createdEntities, tmpPorts)
	interfaceEnt:AddSingleEntity(self)
end

local function GetEntityLookupFunction(createdEntities)
	return function(idx, default)
		if idx == nil then
			return default
		end

		if idx == 0 then
			return game.GetWorld()
		end

		local ent = createdEntities[idx]
		if IsValid(ent) then
			return ent
		end

		return default
	end
end

function WIREENT:_WMI_ApplyWireDupeData(ply, wireDupeInfo, createdEntities, tmpPorts)
	self:_WMI_AddTmpPorts(tmpPorts)

	local lookupFunc = GetEntityLookupFunction(createdEntities)
	WireLib.ApplyDupeInfo(ply, self, wireDupeInfo, lookupFunc)
end

function WIREENT:_WMI_MapCreationIdDuped()
	local wmidata = self._WireMapInterfaceEnt_Data

	if wmidata then
		local dupe = wmidata.dupe

		if dupe and dupe.mapId then
			return dupe.mapId
		end
	end

	local mapId = self._WireMapInterfaceEnt_MapId
	if mapId then
		return mapId
	end

	return self:MapCreationID()
end

function WIREENT:_WMI_GetSpawnIdDuped(interfaceEnt)
	local wmidata = self._WireMapInterfaceEnt_Data

	if wmidata then
		local dupe = wmidata.dupe

		if dupe and dupe.spawnId then
			return dupe.spawnId
		end
	end

	return WIREENT._WMI_GetSpawnId(self, interfaceEnt)
end

function WIREENT:_WMI_GetSpawnId(interfaceEnt)
	if self._WireMapInterfaceEnt_SpawnId then
		return self._WireMapInterfaceEnt_SpawnId
	end

	self._WireMapInterfaceEnt_SpawnId = nil

	if not IsValid(interfaceEnt) then
		local interfaceEnt = self._WireMapInterfaceEnt

		if not IsValid(interfaceEnt) then
			local wmidata = self._WireMapInterfaceEnt_Data
			if not wmidata then
				return nil
			end

			local dupe = wmidata.dupe
			if not dupe then
				return nil
			end

			interfaceEnt = dupe.interfaceEnt
			if not IsValid(interfaceEnt) then
				return nil
			end
		end
	end

	local id = interfaceEnt:HashSubEntityMapId(
		self:EntIndex(),
		WIREENT._WMI_MapCreationIdDuped(self)
	)

	self._WireMapInterfaceEnt_SpawnId = id

	return id
end

-- Remove its overrides
function WIREENT:_WMI_RemoveOverrides(interfaceEnt)
	local wmidata = self._WireMapInterfaceEnt_Data

	if not IsValid(interfaceEnt) then
		interfaceEnt = self._WireMapInterfaceEnt
	end

	self:RemoveCallOnRemove("WireMapInterface_OnRemove")
	duplicator.ClearEntityModifier(self, "WireDupeInfo")
	duplicator.ClearEntityModifier(self, "WireMapInterfaceEntDupeInfo")

	local spawnId = WIREENT._WMI_GetSpawnId(self, interfaceEnt)
	local spawnIdDuped = WIREENT._WMI_GetSpawnIdDuped(self, interfaceEnt)
	local mapId = WIREENT._WMI_MapCreationIdDuped(self)

	WireMapInterfaceLookup:remove(spawnId, spawnIdDuped, mapId, self)
	WireLib.Remove(self)

	if IsValid(interfaceEnt) then
		interfaceEnt:UnregisterWireEntityInternal(self)
	end

	for k, v in pairs(g_memberBlacklist) do
		self[k] = nil
	end

	-- Once we have a mapId, keep it forever, in case this entity is re-added to WMI again.
	self._WireMapInterfaceEnt_MapId = mapId

	if not wmidata then
		return
	end

	local oldMembers = wmidata.oldMembers
	if oldMembers then
		for memberName, oldMember in pairs(oldMembers) do
			if not g_memberBlacklist[memberName] then
				self[memberName] = oldMember
			end
		end
	end

	local oldSettings = wmidata.oldSettings
	if oldSettings then
		if not oldSettings.m_tblToolsAllowed then
			self.m_tblToolsAllowed = false
		else
			self.m_tblToolsAllowed = oldSettings.m_tblToolsAllowed
		end

		if not oldSettings.PhysgunDisabled then
			self.PhysgunDisabled = nil
		else
			self.PhysgunDisabled = oldSettings.PhysgunDisabled
		end
	end

	table.Empty(wmidata)
end

-- Adds its overrides
function WIREENT:_WMI_OverrideEnt(interfaceEnt)
	self._WMI_RemoveOverrides = WIREENT._WMI_RemoveOverrides

	local wmidata = self._WireMapInterfaceEnt_Data or {}
	self._WireMapInterfaceEnt_Data = wmidata

	self._IsWireMapInterfaceSubEntity = true

	self.WireDebugName = string.format(
		"Wire Map Interface [%s]",
		self:GetClass()
	)

	local spawnId = WIREENT._WMI_GetSpawnId(self, interfaceEnt)
	local spawnIdDuped = WIREENT._WMI_GetSpawnIdDuped(self, interfaceEnt)
	local mapId = WIREENT._WMI_MapCreationIdDuped(self)

	self._WireMapInterfaceEnt_MapId = mapId
	WireMapInterfaceLookup:add(spawnId, spawnIdDuped, mapId, self)

	local oldMembers = wmidata.oldMembers or {}
	wmidata.oldMembers = oldMembers

	local oldMethods = wmidata.oldMethods or {}
	wmidata.oldMethods = oldMethods

	for memberName, newMember in pairs(WIREENT) do
		local oldMember = self[memberName]

		if not g_memberBlacklist[memberName] and oldMember ~= newMember then
			oldMembers[memberName] = oldMember

			if not oldMember or isfunction(oldMember) then
				oldMethods[memberName] = oldMember
			end

			self[memberName] = newMember
		end
	end

	self:CallOnRemove("WireMapInterface_OnRemove", function(this)
		if this._WMI_RemoveOverrides then
			this:_WMI_RemoveOverrides()
		end
	end)
end

function WIREENT:_WMI_AddPorts(wireInputRegister, wireOutputRegister)
	if not IsValid(self._WireMapInterfaceEnt) then return end

	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	if wireInputRegister and wireInputRegister:hasPorts() then
		local split = wireInputRegister.wire

		wmidata.inputs = table.Copy(split)
		wmidata.inputs.descs = nil

		if not self.Inputs then
			self.Inputs = WireLib.CreateSpecialInputs(self, split.names, split.types, split.descs)
		else
			self.Inputs = WireLib.AdjustSpecialInputs(self, split.names, split.types, split.descs)
		end

		self._WireMapInterfaceEnt_TmpPorts = nil
		self._WireMapInterfaceEnt_HasPorts = true
	end

	if wireOutputRegister and wireOutputRegister:hasPorts() then
		local split = wireOutputRegister.wire

		wmidata.outputs = table.Copy(split)
		wmidata.outputs.descs = nil

		if not self.Outputs then
			self.Outputs = WireLib.CreateSpecialOutputs(self, split.names, split.types, split.descs)
		else
			self.Outputs = WireLib.AdjustSpecialOutputs(self, split.names, split.types, split.descs)
		end

		self._WireMapInterfaceEnt_TmpPorts = nil
		self._WireMapInterfaceEnt_HasPorts = true
	end
end

function WIREENT:_WMI_AddTmpPorts(tmpPorts)
	-- Add Ports from dupe as a dummy, so connections will not get lost when pasted too early.
	if not tmpPorts then
		return
	end

	if self._WireMapInterfaceEnt_HasPorts then
		return
	end

	local inputs = tmpPorts.inputs
	local outputs = tmpPorts.outputs

	if inputs then
		if not self.Inputs then
			self.Inputs = WireLib.CreateSpecialInputs(self, inputs.names, inputs.types)
		else
			self.Inputs = WireLib.AdjustSpecialInputs(self, inputs.names, inputs.types)
		end

		self._WireMapInterfaceEnt_TmpPorts = true
	end

	if outputs then
		if not self.Outputs then
			self.Outputs = WireLib.CreateSpecialOutputs(self, outputs.names, outputs.types)
		else
			self.Outputs = WireLib.AdjustSpecialOutputs(self, outputs.names, outputs.types)
		end

		self._WireMapInterfaceEnt_TmpPorts = true
	end
end

function WIREENT:_WMI_SetInterface(interfaceEnt)
	local wmidata = self._WireMapInterfaceEnt_Data
	if not wmidata then
		return
	end

	local oldSettings = wmidata.oldSettings or {}
	wmidata.oldSettings = oldSettings

	-- Only apply tool/physgun limits if the entity was spawned by the map.
	-- This prevents impossible-to-remove spam by e.g. rigged dupes.
	local isCreatedByMap = self:CreatedByMap()

	-- Protect in-/output entities from non-wire tools
	if not self.m_tblToolsAllowed then
		oldSettings.m_tblToolsAllowed = false
	else
		oldSettings.m_tblToolsAllowed = table.Copy(self.m_tblToolsAllowed)
	end

	if interfaceEnt:FlagGetProtectFromTools() and isCreatedByMap then
		self.m_tblToolsAllowed = self.m_tblToolsAllowed or {}
		table.Add(self.m_tblToolsAllowed, g_wireTools)
	end

	-- Protect in-/output entities from the physgun
	oldSettings.PhysgunDisabled = self.PhysgunDisabled or false

	if interfaceEnt:FlagGetProtectFromPhysgun() and isCreatedByMap then
		-- Still save the old values for restore, but do not change them if run time created/duped.
		self.PhysgunDisabled = true
	end

	self._WireMapInterfaceEnt = interfaceEnt
	self._IsWireMapInterfaceSubEntity = true
end

function ENT:OverrideEnt(wireEnt)
	if not IsValid(wireEnt) then
		return
	end

	if not wireEnt._IsWireMapInterfaceSubEntity then
		WIREENT._WMI_OverrideEnt(wireEnt, self)
	end

	if not IsValid(self._WireMapInterfaceEnt) and wireEnt._WMI_SetInterface then
		wireEnt:_WMI_SetInterface(self)
	end
end

local function OverrideEntFromDupe(wireEnt, wireMapInterfaceEntDupeInfo, interfaceEnt)
	if not IsValid(wireEnt) then
		return
	end

	if wireEnt._IsWireMapInterfaceSubEntity then
		-- Already initialized
		return
	end

	local mapId = wireMapInterfaceEntDupeInfo.mapId
	local entIdx = wireMapInterfaceEntDupeInfo.entIdx
	local spawnId = wireMapInterfaceEntDupeInfo.spawnId
	local interface = wireMapInterfaceEntDupeInfo.interface

	if not IsValid(interfaceEnt) then
		interfaceEnt = WIREENT._WMI_FindWireMapInterfaceEnt(wireEnt, interface)

		if not IsValid(interfaceEnt) then
			WIREENT._WMI_RemoveOverrides(wireEnt)
			return
		end
	end

	if not interfaceEnt:IsWireableEntity(wireEnt) then
		WIREENT._WMI_RemoveOverrides(wireEnt, interfaceEnt)
		return
	end

	if interfaceEnt:HashSubEntityMapId(entIdx, mapId) ~= spawnId then
		WIREENT._WMI_RemoveOverrides(wireEnt, interfaceEnt)
		return
	end

	local wmidata = wireEnt._WireMapInterfaceEnt_Data or {}
	wireEnt._WireMapInterfaceEnt_Data = wmidata

	local dupe = wmidata.dupe or {}
	wmidata.dupe = dupe

	dupe.mapId = mapId
	dupe.entIdx = entIdx
	dupe.spawnId = spawnId
	dupe.interfaceEnt = interfaceEnt

	-- Modify the entity like the Wire Map Interface does, but without attaching it yet. It's needed for wireEnt:PostEntityPaste() to be run properly.
	-- The attachment is done in wireEnt:PostEntityPaste(), because it has the CreatedEntities table Wiremod needs.
	WIREENT._WMI_OverrideEnt(wireEnt, interfaceEnt)

	-- Ensure that the temporary ports are added super early, so other wire entities can connect to them as soon as they are duped.
	wireEnt:_WMI_AddTmpPorts(wireMapInterfaceEntDupeInfo.tmpPorts)
end

function ENT:OverrideEntFromDupe(wireEnt, wireMapInterfaceEntDupeInfo)
	OverrideEntFromDupe(wireEnt, wireMapInterfaceEntDupeInfo, self)
end

local g_dupeHooksAdded = false

function ENT:AddDupeHooks()
	if g_dupeHooksAdded then
		return
	end

	duplicator.RegisterEntityModifier("WireMapInterfaceEntDupeInfo", function(ply, wireEnt, wireMapInterfaceEntDupeInfo)
		-- Make sure to prepair the Wire Map Interface sub entity when duped, so it can be found and linked too.
		OverrideEntFromDupe(wireEnt, wireMapInterfaceEntDupeInfo)
	end)

	hook.Add("Wire_ApplyDupeInfo", "Wire_InitFromWireMapInterfaceEntDupeInfo", function(ply, inputEnt, outputEnt, inputData)
		-- Make sure we initialize the Wire Map Interface sub entity before connecting our inputs to it. It will not initialize twice.

		local entityMods = inputEnt.EntityMods
		if entityMods then
			local wireMapInterfaceEntDupeInfo = entityMods.WireMapInterfaceEntDupeInfo

			if wireMapInterfaceEntDupeInfo then
				OverrideEntFromDupe(inputEnt, wireMapInterfaceEntDupeInfo)
			end
		end

		local entityMods = outputEnt.EntityMods
		if entityMods then
			local wireMapInterfaceEntDupeInfo = entityMods.WireMapInterfaceEntDupeInfo

			if wireMapInterfaceEntDupeInfo then
				OverrideEntFromDupe(outputEnt, wireMapInterfaceEntDupeInfo)
			end
		end
	end)

	g_dupeHooksAdded = true
end

