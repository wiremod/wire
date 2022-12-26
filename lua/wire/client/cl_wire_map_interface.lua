-- The client part of the wire map interface.
-- It's for the clientside wire ports adding and removing, also for the rendering stuff.
-- It's in in this folder, because point entities are serverside only.

-- Removing wire stuff and other changes that were done.
local OverRiddenEnts = {}
local function RemoveWire(Entity)
	if (not IsValid(Entity)) then return end

	local ID = Entity:EntIndex()

	Entity._NextRBUpdate = nil
	Entity.ppp = nil
	OverRiddenEnts[ID] = nil
	WireLib._RemoveWire(ID) -- Remove entity, so it doesn't count as a wire able entity anymore.

	for key, value in pairs(Entity._Settings_WireMapInterfaceEnt or {}) do
		if (not value or (value == 0) or (value == "")) then
			Entity[key] = nil
		else
			Entity[key] = value
		end
	end
	Entity._Settings_WireMapInterfaceEnt = nil
end

-- Adding wire stuff and changes.
usermessage.Hook("WireMapInterfaceEnt", function(data)
	local Entity = data:ReadEntity()
	local Flags = data:ReadChar()
	local Remove = (Flags == -1)
	if (not WIRE_CLIENT_INSTALLED) then return end
	if (not IsValid(Entity)) then return end

	if (Remove) then
		RemoveWire(Entity)
		return
	end

	Entity._Settings_WireMapInterfaceEnt = {}

	if (bit.band(Flags, 1) > 0) then -- Protect in-/output entities from non-wire tools
		Entity._Settings_WireMapInterfaceEnt.m_tblToolsAllowed = Entity.m_tblToolsAllowed or false
		Entity.m_tblToolsAllowed = {"wire", "wire_adv", "wire_debugger", "wire_wirelink", "gui_wiring", "multi_wire"}
	end

	if (bit.band(Flags, 2) > 0) then -- Protect in-/output entities from the physgun
		Entity._Settings_WireMapInterfaceEnt.PhysgunDisabled = Entity.PhysgunDisabled or false
		Entity.PhysgunDisabled = true
	end

	local ID = Entity:EntIndex()
	if (bit.band(Flags, 32) > 0) then -- Render Wires
		OverRiddenEnts[ID] = true
	else
		OverRiddenEnts[ID] = nil
	end
end)

-- Render bounds updating
hook.Add("Think", "WireMapInterface_Think", function()
	for ID, _ in pairs(OverRiddenEnts) do
		local self = Entity(ID)
		if (not IsValid(self) or not WIRE_CLIENT_INSTALLED) then
			OverRiddenEnts[ID] = nil

			return
		end

		if (CurTime() >= (self._NextRBUpdate or 0)) then
			self._NextRBUpdate = CurTime() + math.random(30,100) / 10
			Wire_UpdateRenderBounds(self)
		end
	end
end)

-- Rendering
hook.Add("PostDrawOpaqueRenderables", "WireMapInterface_Draw", function()
	for ID, _ in pairs(OverRiddenEnts) do
		local self = Entity(ID)
		if (not IsValid(self) or not WIRE_CLIENT_INSTALLED) then
			OverRiddenEnts[ID] = nil

			return
		end

		Wire_Render(self)
	end
end)
