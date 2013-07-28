-- Stuff that the entity gets for its wire stuff.

local WIREENT = {}
-- Trigger wire input
function WIREENT:TriggerInput(name, value, ...)
	if (!name or (name == "") or !value) then return end

	local Entity = self._WireMapInterfaceEnt
	if (!IsValid(Entity)) then return end
	if (!Entity.TriggerWireInput) then return end

	local Input = self.Inputs[name] or {}
	Entity:TriggerWireInput(name, value, (IsValid(Input.Src) == true), self, ...)
end

-- Copied from the gmod base entity, it's changed to work with wire ports.
-- It's only changed for this entity.
-- This function is used to store an output.
function WIREENT:StoreOutput(name, info)
	local rawData = string.Explode(",", info)

	local Output = {}
	Output.entities = rawData[1] or ""
	Output.input = rawData[2] or ""
	Output.param = rawData[3] or ""
	Output.delay = tonumber(rawData[4]) or 0
	Output.times = tonumber(rawData[5]) or -1

	self._OutputsToMap = self._OutputsToMap or {}
	-- This table (self._OutputsToMap) got renamed,
	-- because it was called self.Outputs,
	-- that caused conflicts with wiremod!

	self._OutputsToMap[name] = self._OutputsToMap[name] or {}
	table.insert(self._OutputsToMap[name], Output)
end

-- Nice helper function, this does all the work.
-- Returns false if the output should be removed from the list.
local function FireSingleOutput(output, this, activator)
	if (output.times == 0) then return false end
	local delay = output.delay
	local entitiesToFire = {}

	if (output.entities == "!activator") then
		entitiesToFire = {activator}
	elseif (output.entities == "!self") then
		entitiesToFire = {this}
	elseif (output.entities == "!player") then
		entitiesToFire = player.GetAll()
	else
		entitiesToFire = ents.FindByName(output.entities)
	end

	for _,ent in pairs(entitiesToFire) do
		if (IsValid(ent)) then
			if (delay == 0) then
				ent:Input(output.input, activator, this, output.param)
			else
				timer.Simple(delay, function()
					if (IsValid(ent)) then
						ent:Input(output.input, activator, this, output.param)
					end
				 end)
			end
		end
	end

	if (output.times ~= -1) then
		output.times = output.times - 1
	end

	return ((output.times > 0) or (output.times == -1))
end

-- This function is used to store an output.
function WIREENT:TriggerOutput(name, activator)
	if (!self._OutputsToMap) then return end
	local OutputsToMap = self._OutputsToMap[name]
	if (!OutputsToMap) then return end

	for idx,op in pairs(OutputsToMap) do
		if (!FireSingleOutput(op, self, activator)) then
			self._OutputsToMap[name][idx] = nil
		end
	end
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
		if (!value or (value == 0) or (value == "")) then
			self[key] = nil
		else
			self[key] = value
		end
	end
	self._Settings_WireMapInterfaceEnt = nil

	if (self.Outputs) then
		table.Merge(self.Outputs, self._OutputsToMap)
	end
	self._OutputsToMap = nil

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
