-- Serverside functionalities of Wire Map Interface

WireLib._WireMapInterfaceSpawnIdRegister = WireLib._WireMapInterfaceSpawnIdRegister or {}

local g_spawnIdRegisterBySpawnId = WireLib._WireMapInterfaceSpawnIdRegister.bySpawnId or {}
WireLib._WireMapInterfaceSpawnIdRegister.bySpawnId = g_spawnIdRegisterBySpawnId

local g_spawnIdRegisterBySpawnIdDuped = WireLib._WireMapInterfaceSpawnIdRegister.bySpawnIdDuped or {}
WireLib._WireMapInterfaceSpawnIdRegister.bySpawnIdDuped = g_spawnIdRegisterBySpawnIdDuped

local g_spawnIdRegisterByMapId = WireLib._WireMapInterfaceSpawnIdRegister.byMapId or {}
WireLib._WireMapInterfaceSpawnIdRegister.byMapId = g_spawnIdRegisterByMapId

local g_nextCleanup = 0

local function CleanupRegister()
	local now = CurTime()

	if now < g_nextCleanup then
		-- Only cleanup if the last call was more than 10 minutes ago.
		return
	end

	for wireEntSpawnId, wireEnt in ipairs(g_spawnIdRegisterBySpawnId) do
		if not IsValid(wireEnt) then
			g_spawnIdRegisterBySpawnId[wireEntSpawnId] = nil
		end
	end

	for wireEntSpawnIdDuped, wireEnt in ipairs(g_spawnIdRegisterBySpawnIdDuped) do
		if not IsValid(wireEnt) then
			g_spawnIdRegisterBySpawnIdDuped[wireEntSpawnIdDuped] = nil
		end
	end

	for wireEntMapId, wireEnt in ipairs(g_spawnIdRegisterByMapId) do
		if not IsValid(wireEnt) then
			g_spawnIdRegisterByMapId[wireEntMapId] = nil
		end
	end

	g_nextCleanup = now + 60 * 10
end

function WireLib.RegisterWireMapInterfaceSpawnId(wireEntSpawnId, wireEntSpawnIdDuped, wireEntMapId, wireEnt)
	if not wireEntSpawnId then
		return
	end

	if not wireEntMapId then
		return
	end

	if not IsValid(wireEnt) then
		return
	end

	g_spawnIdRegisterBySpawnId[wireEntSpawnId] = wireEnt

	if wireEntSpawnIdDuped then
		g_spawnIdRegisterBySpawnIdDuped[wireEntSpawnIdDuped] = wireEnt
	end

	g_spawnIdRegisterByMapId[wireEntMapId] = wireEnt

	CleanupRegister()
end

function WireLib.UnregisterWireMapInterfaceSpawnId(wireEntSpawnId, wireEntSpawnIdDuped, wireEntMapId)
	if not wireEntSpawnId then
		return
	end

	if not wireEntMapId then
		return
	end

	g_spawnIdRegisterBySpawnId[wireEntSpawnId] = nil

	if wireEntSpawnIdDuped then
	 	g_spawnIdRegisterBySpawnIdDuped[wireEntSpawnIdDuped] = nil
	end

	g_spawnIdRegisterByMapId[wireEntMapId] = nil

	CleanupRegister()
end

function WireLib.GetWireMapInterfaceSubEntityBySpawnId(wireEntSpawnId)
	if not wireEntSpawnId then
		return nil
	end

	local wireEnt = g_spawnIdRegisterBySpawnId[wireEntSpawnId]
	if wireEnt and not wireEnt:IsValid() then
		g_spawnIdRegisterBySpawnId[wireEntSpawnId] = nil
		CleanupRegister()

		return nil
	end

	return wireEnt
end

function WireLib.GetWireMapInterfaceSubEntityBySpawnIdDuped(wireEntSpawnIdDuped)
	if not wireEntSpawnIdDuped then
		return nil
	end

	local wireEnt = g_spawnIdRegisterBySpawnIdDuped[wireEntSpawnIdDuped]
	if not IsValid(wireEnt) then
		g_spawnIdRegisterBySpawnIdDuped[wireEntSpawnIdDuped] = nil
		CleanupRegister()

		return nil
	end

	return wireEnt
end

function WireLib.GetWireMapInterfaceSubEntityByMapId(wireEntMapId, alsoFindViaEngine)
	if not wireEntMapId then
		return nil
	end

	local wireEnt = g_spawnIdRegisterByMapId[wireEntMapId]
	if not IsValid(wireEnt) then
		g_spawnIdRegisterByMapId[wireEntMapId] = nil
		CleanupRegister()

		if alsoFindViaEngine then
			wireEnt = ents.GetMapCreatedEntity(wireEntMapId)

			if not IsValid(wireEnt) then
				return nil
			end
		end
	end

	return wireEnt
end

function WireLib.WireMapInterfaceValidateId(id)
	id = tonumber(id)
	if not id then return false end
	return id==id and id >= -1 and id <= 0xFFFF
end