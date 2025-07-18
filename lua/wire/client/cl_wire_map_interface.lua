-- Clientside functionalities of Wire Map Interface
-- This is mostly for predection and rendering

local g_wireTools = {
	"wire",
	"wire_adv",
	"wire_debugger",
	"wire_wirelink",
	"multi_wire",
}

local g_wiredEntities = {}
local g_wiredEntitiesRemove = {}
local g_nextThink = 0
local g_hooksAdded = false

-- Remove wire stuff and other changes that were done.
local function RemoveWire(item)
	local wmiId = item.wmiId
	local entId = item.entId

	local ent = item.ent

	item.init = nil
	item.ent = nil
	item.renderWires = nil

	if not IsValid(ent) then
		ent = ents.GetByIndex(entId)
	end

	if IsValid(ent) then
		local oldSettings = item.oldSettings or {}

		if not oldSettings.m_tblToolsAllowed then
			ent.m_tblToolsAllowed = false
		else
			ent.m_tblToolsAllowed = oldSettings.m_tblToolsAllowed
		end

		if not oldSettings.PhysgunDisabled then
			ent.PhysgunDisabled = nil
		else
			ent.PhysgunDisabled = oldSettings.PhysgunDisabled
		end
	end

	item.oldSettings = nil
	item.nextRenderBoundsUpdate = nil

	local wmiWiredEntitiesRemove = g_wiredEntitiesRemove[wmiId]
	if wmiWiredEntitiesRemove then
		wmiWiredEntitiesRemove[entId] = nil

		if table.IsEmpty(wmiWiredEntitiesRemove) then
			g_wiredEntitiesRemove[wmiId] = nil
		end
	end

	local wmiWiredEntities = g_wiredEntities[wmiId]
	if wmiWiredEntities then
		wmiWiredEntities[entId] = nil

		if table.IsEmpty(wmiWiredEntities) then
			g_wiredEntities[wmiId] = nil
		end
	end
end

-- Add wire stuff for rendering and prediction.
local function AddWire(item)
	local wmiId = item.wmiId
	local entId = item.entId
	local protectFromTools = item.protectFromTools
	local protectFromPhysgun = item.protectFromPhysgun

	local ent = ents.GetByIndex(entId)
	if not IsValid(ent) then
		return
	end

	item.ent = ent
	item.init = true

	local oldSettings = item.oldSettings or {}
	item.oldSettings = oldSettings

	local isCreatedByMap = ent:CreatedByMap()

	-- Protect in-/output entities from non-wire tools
	if not ent.m_tblToolsAllowed then
		oldSettings.m_tblToolsAllowed = false
	else
		oldSettings.m_tblToolsAllowed = table.Copy(ent.m_tblToolsAllowed)
	end

	if protectFromTools and isCreatedByMap then
		ent.m_tblToolsAllowed = ent.m_tblToolsAllowed or {}
		table.Add(ent.m_tblToolsAllowed, g_wireTools)
	end

	-- Protect in-/output entities from the physgun
	oldSettings.PhysgunDisabled = ent.PhysgunDisabled or false

	if protectFromPhysgun and isCreatedByMap then
		ent.PhysgunDisabled = true
	end

	item.nextRenderBoundsUpdate = 0

	local wmiWiredEntitiesRemove = g_wiredEntitiesRemove[wmiId]
	if wmiWiredEntitiesRemove then
		wmiWiredEntitiesRemove[entId] = nil

		if table.IsEmpty(wmiWiredEntitiesRemove) then
			g_wiredEntitiesRemove[wmiId] = nil
		end
	end
end

local function pollWireItems()
	for _, wmiWiredEntitiesRemove in pairs(g_wiredEntitiesRemove) do
		for _, item in pairs(wmiWiredEntitiesRemove) do
			RemoveWire(item)
		end
	end

	for wmiId, wmiWiredEntities in pairs(g_wiredEntities) do
		for entId, item in pairs(wmiWiredEntities) do
			if not IsValid(item.ent) then
				if item.init then
					-- Entity disappeared unexpectedly, so unregister it.
					local wmiWiredEntitiesRemove = g_wiredEntitiesRemove[wmiId] or {}
					g_wiredEntitiesRemove[wmiId] = wmiWiredEntitiesRemove

					wmiWiredEntitiesRemove[entId] = item
				else
					AddWire(item)
				end
			end
		end
	end
end

local function AddHooks()
	hook.Add("PostCleanupMap", "WireMapInterface_PostCleanupMap_CL", function()
		table.Empty(g_wiredEntities)
		table.Empty(g_wiredEntitiesRemove)
		g_nextThink = 0
	end)

	hook.Add("Think", "WireMapInterface_Think", function()
		local now = CurTime()

		if now < g_nextThink then
			return
		end

		g_nextThink = now + 1

		pollWireItems()

		-- Render bounds updating
		for _, wmiWiredEntities in pairs(g_wiredEntities) do
			for _, item in pairs(wmiWiredEntities) do
				if item.init and item.renderWires and now >= item.nextRenderBoundsUpdate then
					local ent = item.ent

					if IsValid(ent) and not ent:IsDormant() then
						Wire_UpdateRenderBounds(ent)
						item.nextRenderBoundsUpdate = now + math.random(30, 100) / 10
					end
				end
			end
		end
	end)

	-- Rendering
	hook.Add("PostDrawOpaqueRenderables", "WireMapInterface_Draw", function()
		for _, wmiWiredEntities in pairs(g_wiredEntities) do
			for _, item in pairs(wmiWiredEntities) do
				if item.init and item.renderWires then
					local ent = item.ent

					if IsValid(ent) and not ent:IsDormant() then
						Wire_Render(ent)
					end
				end
			end
		end
	end)

	g_hooksAdded = true
end

net.Receive("WireMapInterfaceEntities", function()
	local wmiId = net.ReadUInt(MAX_EDICT_BITS)
	local protectFromTools = net.ReadBool()
	local protectFromPhysgun = net.ReadBool()
	local renderWires = net.ReadBool()
	local count = net.ReadUInt(6)

	local wmiWiredEntities = g_wiredEntities[wmiId] or {}
	g_wiredEntities[wmiId] = wmiWiredEntities

	local wmiWiredEntitiesRemove = g_wiredEntitiesRemove[wmiId] or {}
	g_wiredEntitiesRemove[wmiId] = wmiWiredEntitiesRemove

	for entId, item in pairs(wmiWiredEntities) do
		-- Clear all that belongs to the current WMI.
		wmiWiredEntitiesRemove[entId] = item
	end

	for i = 1, count do
		local entId = net.ReadUInt(MAX_EDICT_BITS)

		-- Unclear listed items.
		wmiWiredEntitiesRemove[entId] = nil

		-- Add listed items.
		local item = wmiWiredEntities[entId] or {}
		wmiWiredEntities[entId] = item

		item.entId = entId
		item.wmiId = wmiId
		item.protectFromTools = protectFromTools
		item.protectFromPhysgun = protectFromPhysgun
		item.renderWires = renderWires
	end

	if not g_hooksAdded and not table.IsEmpty(wmiWiredEntities) then
		AddHooks()
	end
end)

