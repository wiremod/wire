-- Stuff that the entity gets for its wire stuff.

local WIREENT = {}
-- Trigger wire input
function WIREENT:TriggerInput(name, value, ...)
	if (not name or (name == "") or not value) then return end

	local Entity = self._WireMapInterfaceEnt
	if (not IsValid(Entity)) then return end
	if (not Entity.TriggerWireInput) then return end

	local Input = self.Inputs[name] or {}
	Entity:TriggerWireInput(name, value, IsValid(Input.Src) == true, self, ...)
end

-- Remove its overrides
function WIREENT:_RemoveOverrides()
	for k, v in pairs(self._Overrides_WireMapInterfaceEnt or {}) do
		self[k] = v
	end
	self._Overrides_WireMapInterfaceEnt = nil

	for k, _ in pairs(self._Added_WireMapInterfaceEnt or {}) do
		self[k] = nil
	end
	self._Added_WireMapInterfaceEnt = nil

	for key, value in pairs(self._Settings_WireMapInterfaceEnt or {}) do
		if (not value or (value == 0) or (value == "")) then
			self[key] = nil
		else
			self[key] = value
		end
	end
	self._Settings_WireMapInterfaceEnt = nil

	self._WireMapInterfaceEnt = nil
	self._RemoveOverride = nil
end

-- Adds its overrides
function ENT:OverrideEnt(Entity)
	Entity._Overrides_WireMapInterfaceEnt = Entity._Overrides_WireMapInterfaceEnt or {}
	Entity._Added_WireMapInterfaceEnt = Entity._Added_WireMapInterfaceEnt or {}

	for k, v in pairs(WIREENT) do
		if ((Entity[k] == nil) or (k == "_Overrides_WireMapInterfaceEnt") or (k == "_Added_WireMapInterfaceEnt") or (k == "_Settings_WireMapInterfaceEnt")) then
			Entity._Overrides_WireMapInterfaceEnt[k] = nil
			Entity._Added_WireMapInterfaceEnt[k] = true
		else
			Entity._Overrides_WireMapInterfaceEnt[k] = v
			Entity._Added_WireMapInterfaceEnt[k] = nil
		end
		Entity[k] = v
	end


	Entity._Settings_WireMapInterfaceEnt = Entity._Settings_WireMapInterfaceEnt or {}

	if (bit.band(self.flags, 1) > 0) then -- Protect in-/output entities from non-wire tools
		Entity._Settings_WireMapInterfaceEnt.m_tblToolsAllowed = Entity.m_tblToolsAllowed or false
		Entity.m_tblToolsAllowed = {"wire", "wire_adv", "wire_debugger", "wire_wirelink", "gui_wiring", "multi_wire"}
	end

	if (bit.band(self.flags, 2) > 0) then -- Protect in-/output entities from the physgun
		Entity._Settings_WireMapInterfaceEnt.PhysgunDisabled = Entity.PhysgunDisabled or false
		Entity.PhysgunDisabled = true
	end

	Entity._WireMapInterfaceEnt = self
end
