-- I/O code between Hammer and Wiremod

local WireLib = WireLib

local function newPortRegister()
	local register = {}

	register.byPortId = {}
	register.byName = {}
	register.byUid = {}
	register.sequence = {}

	register.wire = {}
	register.wire.names = {}
	register.wire.types = {}
	register.wire.descs = {}

	register.add = function(this, port)
		if not port then
			return
		end

		local portId = port.portId
		if not portId then
			return
		end

		local name = port.name or ""
		if name == "" then
			return
		end

		local uid = port.uid
		if not uid then
			return
		end

		local byPortId = this.byPortId
		local byName = this.byName
		local byUid = this.byUid
		local sequence = this.sequence

		if byUid[uid] and byUid[uid].uid == uid then
			return
		end

		local typeName = port.typeName
		local desc = port.desc or ""

		port = table.Copy(port)

		byPortId[portId] = port
		byName[name] = port
		byUid[uid] = port

		sequence[#sequence + 1] = port

		local wire = this.wire
		local names = wire.names
		local types = wire.types
		local descs = wire.descs

		local index = #names + 1
		names[index] = name -- The port name
		types[index] = typeName -- The port type
		descs[index] = desc -- The port description
	end

	register.empty = function(this)
		table.Empty(this.byPortId)
		table.Empty(this.byName)
		table.Empty(this.byUid)
		table.Empty(this.sequence)

		local wire = register.wire
		table.Empty(wire.names)
		table.Empty(wire.types)
		table.Empty(wire.descs)
	end

	register.hasPorts = function(this)
		local sequence = this.sequence
		return #sequence > 0
	end

	return register
end

function ENT:HandlePortsUpdated()
	if not self.PortsUpdated then
		return
	end

	self.WireEntNameUpdated = true

	self:UpdatePorts()

	self.PortsUpdated = nil
end

-- To cleanup and get the in-/outputs information.
local function copyAndSanitizeToPortRegister(register, registerTmp)
	register = register or newPortRegister()
	register:empty()

	if not registerTmp then
		return register
	end

	for i = 1, #registerTmp do
		-- Ensure to keep things ordered, even with gaps

		local port = registerTmp[i]
		register:add(port)
	end

	return register
end

function ENT:UpdatePorts()
	local wireInputRegister = self.WireInputRegister
	local wireOutputRegister = self.WireOutputRegister

	wireInputRegister = copyAndSanitizeToPortRegister(wireInputRegister, self.WireInputRegisterTmp)
	wireOutputRegister = copyAndSanitizeToPortRegister(wireOutputRegister, self.WireOutputRegisterTmp)

	self.WireInputRegister = wireInputRegister
	self.WireOutputRegister = wireOutputRegister

	local wireEnts = self:GetWiredEntities()

	for key, wireEnt in ipairs(wireEnts) do
		wireEnt:_WMI_AddPorts(self.WireInputRegister, self.WireOutputRegister)
	end
end

local g_hashTmp = {}

function ENT:GetPortUid(port)
	if not port then
		return nil
	end

	local name = port.name or ""
	local portId = port.portId
	local portType = port.type

	if name == "" then
		return nil
	end

	if not portId then
		return nil
	end

	if not portType then
		return nil
	end

	table.Empty(g_hashTmp)

	g_hashTmp[1] = "WMI_"
	g_hashTmp[2] = self:GetCreationID()
	g_hashTmp[3] = self:GetCreationTime()
	g_hashTmp[4] = name
	g_hashTmp[5] = portId
	g_hashTmp[6] = portType

	return util.SHA1(table.concat(g_hashTmp, "_"))
end

function ENT:PrepairOutputGlobals(inputData, wireValue, wireEnt, wireDevice, owner)
	if not IsValid(wireEnt) then
		return
	end

	-- This can be usefull if a lua_run entity is triggered
	-- Because entity.Fire and entity.AcceptInput are not run synchronously in the same frame, we use them in a custom entity.AcceptInput detour.
	-- So we store them for later use in a custom entity.AcceptInput detour.

	local name = inputData.name
	local typeName = inputData.typeName
	local wired = inputData.wiredStateTotal

	local globals = {
		WIRE_NAME = name, -- Input name.
		WIRE_TYPE = typeName, -- Input type (NORMAL, STRING, VECTOR, etc.)
		WIRE_VALUE = wireValue, -- Input value.
		WIRE_WIRED = wired, -- Is the input wired?
		WIRE_CALLER = self, -- This entity.
		WIRE_ACTIVATOR = wireEnt, -- The entity that has the Wire input.
		WIRE_DEVICE = wireDevice, -- The entity where the input data was from, e.g. a Wiremod button.
		WIRE_OWNER = owner, -- The owner of the input device, e.g the player who spawned the Wiremod button.
	}

	local hammerOutputName = inputData.hammerOutputName
	local hammerResetOutputName = inputData.hammerResetOutputName

	self._OutputGlobals = self._OutputGlobals or {}
	self._OutputGlobals[hammerOutputName] = globals
	self._OutputGlobals[hammerResetOutputName] = globals
end

function ENT:SetupOutputGlobals(globals)
	-- This can be usefull if a lua_run entity is triggered

	local G = _G

	globals._old = {
		-- In the case the call might be nested, or some other shenanigans happen, we store the old globals for restore after use.

		WIRE_NAME = G.WIRE_NAME,
		WIRE_VALUE = G.WIRE_VALUE,
		WIRE_TYPE = G.WIRE_TYPE,
		WIRE_WIRED = G.WIRE_WIRED,
		WIRE_CALLER = G.WIRE_CALLER,
		WIRE_ACTIVATOR = G.WIRE_ACTIVATOR,
		WIRE_DEVICE = G.WIRE_DEVICE,
		WIRE_OWNER = G.WIRE_OWNER,
	}

	G.WIRE_NAME = globals.WIRE_NAME
	G.WIRE_VALUE = globals.WIRE_VALUE
	G.WIRE_TYPE = globals.WIRE_TYPE
	G.WIRE_WIRED = globals.WIRE_WIRED
	G.WIRE_CALLER = globals.WIRE_CALLER
	G.WIRE_ACTIVATOR = globals.WIRE_ACTIVATOR
	G.WIRE_DEVICE = globals.WIRE_DEVICE
	G.WIRE_OWNER = globals.WIRE_OWNER
end

function ENT:KillOutputGlobals(globals)
	local oldGlobals = globals and globals._old

	local G = _G

	if oldGlobals then
		G.WIRE_NAME = oldGlobals.WIRE_NAME
		G.WIRE_VALUE = oldGlobals.WIRE_VALUE
		G.WIRE_TYPE = oldGlobals.WIRE_TYPE
		G.WIRE_WIRED = oldGlobals.WIRE_WIRED
		G.WIRE_CALLER = oldGlobals.WIRE_CALLER
		G.WIRE_ACTIVATOR = oldGlobals.WIRE_ACTIVATOR
		G.WIRE_DEVICE = oldGlobals.WIRE_DEVICE
		G.WIRE_OWNER = oldGlobals.WIRE_OWNER

		globals._old = nil
	else
		G.WIRE_NAME = nil
		G.WIRE_VALUE = nil
		G.WIRE_TYPE = nil
		G.WIRE_WIRED = nil
		G.WIRE_CALLER = nil
		G.WIRE_ACTIVATOR = nil
		G.WIRE_DEVICE = nil
		G.WIRE_OWNER = nil
	end
end

local function deturedAcceptInput(this, name, activator, caller, data, ...)
	local wmidata = this._WireMapInterfaceEnt_FirePrepairData

	if not wmidata then
		return false
	end

	local oldAcceptInput = wmidata.AcceptInput
	if not oldAcceptInput then
		return false
	end

	local globals = wmidata.globals

	if not globals then
		this.AcceptInput = oldAcceptInput
		return oldAcceptInput(this, name, activator, caller, data, ...)
	end

	if not IsValid(caller) or not caller.IsWireMapInterface then
		return oldAcceptInput(this, name, activator, caller, data, ...)
	end

	-- We detoured the AcceptInput hook of this entity to make our WIRE_* globals (for lua_run) available during the input call.
	caller:SetupOutputGlobals(globals)

	local status, errOrResult = pcall(oldAcceptInput, this, name, activator, caller, data, ...)

	if not status then
		errOrResult = tostring(errOrResult or "")

		if errOrResult ~= "" then
			message = caller:FormatString(": Lua error in target AcceptInput:\n  Wire input '%s [%s]' -> Hammer output '%s@%s'\n  %s", globals.WIRE_NAME, globals.WIRE_TYPE, caller:FormatEntityString(this), name, errOrResult)
			ErrorNoHaltWithStack(message)
		end

		return false
	end

	caller:KillOutputGlobals(globals)

	return errOrResult
end

function ENT:PrepairEntityForFire(targetEnt, outputName)
	-- Because entity.Fire and entity.AcceptInput are not run synchronously in the same frame, we use add a custom entity.AcceptInput detour to lua_run entities.

	if not self._OutputGlobals then
		return
	end

	local globals = self._OutputGlobals[outputName]
	if not globals then
		return
	end

	local wmidata = targetEnt._WireMapInterfaceEnt_FirePrepairData or {}
	targetEnt._WireMapInterfaceEnt_FirePrepairData = wmidata

	wmidata.globals = globals

	local oldAcceptInput = wmidata.AcceptInput or targetEnt.AcceptInput
	wmidata.AcceptInput = oldAcceptInput

	targetEnt.AcceptInput = deturedAcceptInput
end

function ENT:TriggerWireOutputSafe(wireEnt, wireOutputName, wireValue, ...)
	if not IsValid(wireEnt) then
		return false
	end

	local status, err = pcall(WireLib.TriggerOutput, wireEnt, wireOutputName, wireValue, ...)

	if status then
		return true
	end

	err = tostring(err or "")

	if err ~= "" then
		message = self:FormatString(": Lua error at Wire output '%s':\n%s", wireOutputName, err)
		ErrorNoHaltWithStack(message)
	end

	return false
end

function ENT:TriggerHammerOutputSafe(hammerOutputName, activator, hammerValue, ...)
	if not IsValid(activator) then
		return false
	end

	local status, err = pcall(self.TriggerOutput, self, hammerOutputName, activator, hammerValue, ...)
	if status then
		return true
	end

	err = tostring(err or "")

	if err ~= "" then
		message = self:FormatString(": Lua error at Hammer output '%s':\n%s", hammerOutputName, err)
		ErrorNoHaltWithStack(message)
	end

	return false
end

function ENT:ApplyWireOutputBufferSingle(wireEnt)
	local wireOutputRegister = self.WireOutputRegister

	if not wireOutputRegister then
		return
	end

	for _, outputData in pairs(wireOutputRegister.sequence) do
		local wireValue = outputData.bufferedWireValue

		self:TriggerWireOutputSingle(wireEnt, outputData, wireValue)
	end
end

function ENT:ApplyWireOutputBufferAll()
	local wireOutputRegister = self.WireOutputRegister

	if not wireOutputRegister then
		return
	end

	for _, outputData in pairs(wireOutputRegister.sequence) do
		local wireValue = outputData.bufferedWireValue

		self:TriggerWireOutputAll(outputData, wireValue)
	end
end

-- Wire input
function ENT:TriggerWireInput(wireInputName, wireValue, wired, wireEnt)
	if not IsValid(wireEnt) then return end

	local wireInputRegister = self.WireInputRegister
	if not wireInputRegister then
		return
	end

	local inputData = wireInputRegister.byName[wireInputName]
	if not inputData then
		return
	end

	local portId = inputData.portId
	if not self:CheckPortIdLimit(portId, false) then
		return
	end

	local uid = inputData.uid
	local wireInputTriggerBuffer = self.WireInputTriggerBuffer

	local wiredState = inputData.wiredState or {}
	inputData.wiredState = wiredState

	local oldWired = wiredState[wireEnt] or false
	inputData.wiredStateTotalChanged = false

	if oldWired ~= wired then
		inputData.wiredStateTotal = nil
		inputData.wiredStateTotalChanged = true

		if wired then
			wiredState[wireEnt] = true
		else
			wiredState[wireEnt] = nil
		end
	end

	-- Check if any of known entities are connected and cache it.
	if inputData.wiredStateTotal == nil then
		local wiredStateTotal = false

		for ent, thisWiredState in pairs(wiredState) do
			if not IsValid(ent) then
				thisWiredState = false
				wiredState[ent] = nil
			end

			if thisWiredState then
				wiredStateTotal = true
			end
		end

		inputData.wiredStateTotal = wiredStateTotal
	end

	-- The wired/unwired state across all entities as been changed.
	local wiredStateTotalChanged = inputData.wiredStateTotalChanged or false

	if not self:IsActive() then
		-- Keep the last given trigger if turned off, so we apply it after it was turned on.

		local triggerStateData = wireInputTriggerBuffer[uid] or {}
		wireInputTriggerBuffer[uid] = triggerStateData

		triggerStateData.inputData = inputData
		triggerStateData.wireValue = wireValue
		triggerStateData.wireEnt = wireEnt

		return
	end

	local debounce = inputData.debounce or {}
	inputData.debounce = debounce

	if not wiredStateTotalChanged then
		local oldWireValue = debounce.oldWireValue

		if oldWireValue ~= nil and self:IsEqualWireValue(inputData.type, oldWireValue, wireValue) then
			return
		end

		local nextTime = debounce.nextTime or 0
		if nextTime > CurTime() then
			-- Keep the last given trigger during cool down, so we apply it after next tick, in case the signal "misses the bus".

			local triggerStateData = wireInputTriggerBuffer[uid] or {}
			wireInputTriggerBuffer[uid] = triggerStateData

			triggerStateData.inputData = inputData
			triggerStateData.wireValue = wireValue
			triggerStateData.wireEnt = wireEnt

			return
		end
	end

	wireInputTriggerBuffer[uid] = nil
	self:TriggerHammerOutputFromWire(inputData, wireValue, wireEnt)
end

-- Wire output
function ENT:TriggerWireOutput(portId, hammerValue)
	if not self:CheckPortIdLimit(portId, false) then
		return
	end

	local outputData = self.WireOutputRegister.byPortId[portId]
	if not outputData then
		return
	end

	local wireOutputType = outputData.type

	local convertFunc, isToggle = self:GetMapToWireConverter(wireOutputType)
	if not convertFunc then
		return
	end

	if isToggle then
		-- Toggle state each time the output is triggered
		outputData.toggleState = not outputData.toggleState
		hammerValue = outputData.toggleState
	end

	local debounce = outputData.debounce or {}
	outputData.debounce = debounce

	local oldHammerValue = debounce.oldHammerValue
	if oldHammerValue ~= nil and hammerValue == oldHammerValue then
		return
	end

	local wireValue = convertFunc(self, hammerValue)
	outputData.bufferedWireValue = wireValue

	if not self:IsActive() then
		return
	end

	local oldWireValue = debounce.oldWireValue
	if oldWireValue ~= nil and self:IsEqualWireValue(wireOutputType, oldWireValue, wireValue) then
		return
	end

	self:TriggerWireOutputAll(outputData, wireValue)

	debounce.oldHammerValue = hammerValue
	debounce.oldWireValue = wireValue
end

function ENT:TriggerWireOutputSingle(wireEnt, outputData, wireValue)
	if not outputData then
		return
	end

	if wireValue == nil then
		return
	end

	local wireOutputName = outputData.name

	self:TriggerWireOutputSafe(wireEnt, wireOutputName, wireValue)
end

function ENT:TriggerWireOutputAll(outputData, wireValue)
	if not outputData then
		return
	end

	if wireValue == nil then
		return
	end

	local wireOutputName = outputData.name
	local wireEnts = self:GetWiredEntities()

	for _, wireEnt in ipairs(wireEnts) do
		self:TriggerWireOutputSafe(wireEnt, wireOutputName, wireValue)
	end
end

-- Hammer input
function ENT:TriggerHammerInput(name, data)
	local portId = tonumber(string.match(name, "triggerwireoutput(%d+)")) or 0
	if self:CheckPortIdLimit(portId, false) then
		self:TriggerWireOutput(portId, data)
		return true
	end

	local caller = self._lastCaller

	if name == "addentity" then
		self:AddSingleEntity(caller)
		return true
	end

	if name == "removeentity" then
		self:RemoveSingleEntity(caller)
		return true
	end

	if name == "addentities" then
		self:AddEntitiesByName(data)
		return true
	end

	if name == "removeentities" then
		self:RemoveEntitiesByName(data)
		return true
	end

	if name == "removeallentities" then
		self:RemoveAllEntities()
		return true
	end

	return false
end

-- Hammer output
function ENT:TriggerHammerOutputFromWire(inputData, wireValue, wireEnt)
	if not inputData then
		return
	end

	local uid = inputData.uid
	local wireConnectionChange = inputData.wiredStateTotalChanged or false
	local wired = inputData.wiredStateTotal or false
	local hammerOutputName = inputData.hammerOutputName
	local hammerResetOutputName = inputData.hammerResetOutputName

	-- wireEnt gets the ownership of connected device
	local wireDevice = wireEnt:_WMI_GetInputDevice() or NULL
    local owner = IsValid(wireDevice) and WireLib.GetOwner(wireDevice) or NULL

   	self._lastWireInputEnt = wireEnt
   	self._lastWireDeviceEnt = wireDevice
   	self._lastWireDeviceEntOwner = owner

	local convertFunc, isToggle = self:GetWireToMapConverter(inputData.type)
	if not convertFunc then
		return
	end

	if isToggle then
		wireValue = tobool(wireValue) and 1 or 0
	end

	local hammerValue = convertFunc(self, wireValue)

	local debounce = inputData.debounce or {}
	inputData.debounce = debounce

	if not wireConnectionChange then
		local oldHammerValue = debounce.oldHammerValue
		if oldHammerValue ~= nil and hammerValue == oldHammerValue then
			return
		end
	end

	self:PrepairOutputGlobals(inputData, wireValue, wireEnt, wireDevice, owner)

	if not wired then
		if wireConnectionChange then
			if not isToggle then
				-- Do not trigger with "zero" on reset if we are in toggle mode
				self:TriggerHammerOutputSafe(hammerOutputName, wireEnt, hammerValue)
			end

			self:TriggerHammerOutputSafe(hammerResetOutputName, wireEnt)
		end
	else
		if isToggle then
			if hammerValue then
				-- Will only trigger if this value is true and if it was false before
				self:TriggerHammerOutputSafe(hammerOutputName, wireEnt)
			end
		else
			self:TriggerHammerOutputSafe(hammerOutputName, wireEnt, hammerValue)
		end
	end

	self.WireInputTriggerBuffer[uid] = nil

	debounce.oldWireValue = wireValue
	debounce.oldHammerValue = hammerValue
	debounce.nextTime = CurTime() + self:GetMinTriggerTime()

	inputData.wiredStateTotalChanged = false
end

-- Hammer keyvalues
function ENT:StoreHammerOutputs(key, value)
	local portId = tonumber(string.match(key, "onwireinput(%d+)")) or 0
	if self:CheckPortIdLimit(portId, true) then
		self:StoreOutput(key, value)
		return true
	end

	local portId = tonumber(string.match(key, "onresetwireinput(%d+)")) or 0
	if self:CheckPortIdLimit(portId, true) then
		self:StoreOutput(key, value)
		return true
	end

	if key == "onwireentscreated" then
		self:StoreOutput(key, value)
		return true
	end

	if key == "onwireentsremoved" then
		self:StoreOutput(key, value)
		return true
	end

	if key == "onwireentsready" then
		self:StoreOutput(key, value)
		return true
	end

	if key == "onwireentsstartchanging" then
		self:StoreOutput(key, value)
        return true
    end

    return false
end

local g_blacklistedPortNames = {
	wirelink = true,
	link = true,
	entity = true,
}

function ENT:RegisterWireInputs(key, value)
	local portId, name = string.match(key, "input(%d+)_(%w+)")

	if not portId then
		return
	end

	portId = tonumber(portId or 0) or 0
	name = tostring(name or "")

	if not self:CheckPortIdLimit(portId, true) then
		return false
	end

	if name == "" then
		return false
	end

	local wireInputRegisterTmp = self.WireInputRegisterTmp or {}
	self.WireInputRegisterTmp = wireInputRegisterTmp

	local inputData = wireInputRegisterTmp[portId] or {}
	wireInputRegisterTmp[portId] = inputData

	if name == "lua" then
		-- Used to run given Lua codes.
		-- It is no longer supported as it is considered as unsafe.

		if value ~= "" then
			inputData.warnAboutLua = true
		end
	elseif name == "type" then
		inputData.type = tonumber(value) or 0
		inputData.typeName = self:GetWireTypenameByTypeId(inputData.type)
		inputData.zeroWireValue = WireLib.GetDefaultForType(inputData.typeName)
	elseif name == "desc" then
		inputData.desc = value
	elseif name == "name" then
		if value ~= "" then
			if not g_blacklistedPortNames[value] then
				inputData.name = value
				inputData.portId = portId

				inputData.hammerOutputName = "OnWireInput" .. portId
				inputData.hammerResetOutputName = "OnResetWireInput" .. portId

				if not inputData.type then
					inputData.type = 0
					inputData.typeName = self:GetWireTypenameByTypeId(inputData.type)
					inputData.zeroWireValue = WireLib.GetDefaultForType(inputData.typeName)
				end
			else
				table.Empty(inputData)
				self:PrintWarning(": Can not add input '%s', as the name is reserved.", value)
			end
		else
			table.Empty(inputData)
		end
	end

	if inputData.name then
		if inputData.warnAboutLua then
			self:PrintWarning(", input '%s [%s]': Running Lua code is no longer supported! Trigger an lua_run entity instead.", inputData.name, inputData.typeName)
			inputData.warnAboutLua = nil
		end

		inputData.uid = self:GetPortUid(inputData)
		self.PortsUpdated = true
	end

	return true
end

function ENT:RegisterWireOutputs(key, value)
	local portId, name = string.match(key, "output(%d+)_(%w+)")

	if not portId then
		return
	end

	portId = tonumber(portId or 0) or 0
	name = tostring(name or "")

	if not self:CheckPortIdLimit(portId, true) then
		return false
	end

	if name == "" then
		return false
	end

	local wireOutputRegisterTmp = self.WireOutputRegisterTmp or {}
	self.WireOutputRegisterTmp = wireOutputRegisterTmp

	local outputData = wireOutputRegisterTmp[portId] or {}
	wireOutputRegisterTmp[portId] = outputData

	if name == "type" then
		outputData.type = tonumber(value)
		outputData.typeName = self:GetWireTypenameByTypeId(outputData.type)
		outputData.zeroWireValue = WireLib.GetDefaultForType(outputData.typeName)
	elseif name == "desc" then
		outputData.desc = value
	elseif name == "name" then
		if value ~= "" then
			if not g_blacklistedPortNames[value] then
				outputData.name = value
				outputData.portId = portId

				if not outputData.type then
					outputData.type = 0
					outputData.typeName = self:GetWireTypenameByTypeId(outputData.type)
					outputData.zeroWireValue = WireLib.GetDefaultForType(outputData.typeName)
				end
			else
				table.Empty(outputData)
				self:PrintWarning(": Can not add output '%s', as the name is reserved.", value)
			end
		else
			table.Empty(outputData)
		end
	end

	if outputData.name then
		outputData.uid = self:GetPortUid(outputData)
		self.PortsUpdated = true
	end

	return true
end

function ENT:RegisterWireIO(key, value)
	if self:RegisterWireInputs(key, value) then
		return true
	end

	if self:RegisterWireOutputs(key, value) then
		return true
	end

	return false
end

function ENT:IsConnectedWirelink()
	local wireEnts = self:GetWiredEntities()

	for _, wireEnt in ipairs(wireEnts) do
		local IsConnectedWirelink = wireEnt._WMI_IsConnectedWirelink

		if IsConnectedWirelink and IsConnectedWirelink(wireEnt) then
			return true
		end
	end

	return false
end

function ENT:PollWirelinkStatus()
	if not self:IsActive() then
		return
	end

	local now = CurTime()
	local nextWirelinkPoll = self.NextWirelinkPoll or 0

	if nextWirelinkPoll > now then
		return
	end

	local isWirelinked = self:IsConnectedWirelink()

	local oldIsWirelinked = self.oldIsWirelinked or false
	local wirelinkChanged = oldIsWirelinked ~= isWirelinked
	self.oldIsWirelinked = isWirelinked

	if wirelinkChanged and not isWirelinked then
		self:UnWirelinkAllWireInputs()
	end

	self.NextWirelinkPoll = now + self.MIN_THINK_TIME * 8
end

function ENT:UnWirelinkAllWireInputs()
	local wireEnts = self:GetWiredEntities()
	local wireInputRegister = self.WireInputRegister

	if not wireInputRegister then
		return
	end

	for _, wireEnt in ipairs(wireEnts) do
		for _, inputData in ipairs(wireInputRegister.sequence) do
			local name = inputData.name

			local wireValue = wireEnt:_WMI_GetDirectLinkedInputValue(name)

			if wireValue == nil then
				wireValue = inputData.zeroWireValue
			end

			wireEnt:TriggerInput(name, wireValue)
		end
	end
end

