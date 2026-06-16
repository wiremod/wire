--[[
This is the wire map interface entity. (info_wiremapinterface)

This point entity allows you to give other entities wire in-/outputs.
Those wire ports allows you to control thinks on the map with Wiremod
or to let the map return thinks to wire outputs.

It supports many datatypes.
In case it triggers a lua_run entity it temporarily applies these special globals to the Lua environment:
	WIRE_NAME -- Input name
	WIRE_TYPE -- Input type (NORMAL, STRING, VECTOR, etc.)
	WIRE_VALUE -- Input value
	WIRE_WIRED -- Is the input wired?
	WIRE_CALLER -- This entity
	WIRE_ACTIVATOR -- The entity that has the Wire input
	WIRE_DEVICE -- The entity where the input data was from, e.g. a Wiremod button
	WIRE_OWNER -- The owner of the input device, e.g the player who spawned the Wiremod button
]]

local WireAddon = WireAddon
local WireLib = WireLib

ENT.Base = "base_point"
ENT.Type = "point"

ENT.Spawnable = false
ENT.AdminOnly = true

-- Wire Map Interfaces (info_wiremapinterface) should not be allowed to be duplicated/saved.
-- We use an info_wiremapinterface_savestate for that.
ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true
ENT.IsWireMapInterface = nil

if not WireAddon then
	-- Avoids problems with early map spawned entities in case Wiremod fails to load.
	return
end

-- Make sure there is no way to mess around with tools, especially dublicator tools.
-- This entity not traceable nor visible, so tools would not matter.
ENT.m_tblToolsAllowed = {}

-- Esay way to check if it is a wire map interface.
ENT.IsWireMapInterface = true

-- This entity supports more than the 8 ports you see in the editor. This value is the port limit.
ENT.MAX_PORTS = 255

-- Minimum delay between think calls.
ENT.MIN_THINK_TIME = 0.25

include("convert.lua")
include("entitycontrol.lua")
include("entityoverride.lua")
include("gmodoutputs.lua")
include("io.lua")
include("networking.lua")
include("savestate.lua")

local cvar_allow_interface = CreateConVar(
	"sv_wire_mapinterface",
	"1",
	{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_GAMEDLL},
	"Enable or disable all Wire Map Interface entities. Default: 1",
	0,
	1
)

-- Minimum time between Wiremod input triggers.
local cvar_min_trigger_time = CreateConVar(
	"sv_wire_mapinterface_min_trigger_time",
	"0.01",
	{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_GAMEDLL},
	"Sets minimum time between Wiremod input triggers per Wire Map Interface entity and Wiremod input. Default: 0.01",
	0,
	1
)

-- The maximum number of entities per interface entitiy that can get wire ports
local cvar_max_sub_entities = CreateConVar(
	"sv_wire_mapinterface_max_sub_entities",
	"32",
	{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_GAMEDLL},
	"Sets maximum count of sub entities per Wire Map Interface entity that can get wire ports. Default: 32",
	1,
	128
)

local g_classBlacklist = {
	lua_run = true, -- No interface for lua_run!
	func_water = true, -- No interface for water!
	func_water_analog = true, -- No interface for water!
	info_wiremapinterface = true, -- No interface for other Wire Map Interfaces!
	info_wiremapinterface_savestate = true, -- No interface for Wire Map Interfaces savestate helper!
	func_illusionary = true, -- No interface for Non-Solid
}

local g_classBlacklistPatterns = {
	"^(item_[%w_]+)", -- No interface for items!
	"^(info_[%w_]+)", -- No interface for info entities!
	"^(trigger_[%w_]+)", -- No interface for trigger entities!
}

-- This checks if you can give an entity wiremod abilities
function ENT:IsWireableEntity(ent)
	if not IsValid(ent) then
		-- No interface for invalid entities!
		return false
	end

	if IsValid(ent._WireMapInterfaceEnt) and ent._WireMapInterfaceEnt ~= self then
		-- Only one interface per entity!
		return false
	end

	local hasPorts = WireLib.HasPorts(ent) or ent.IsWire or ent.Inputs or ent.Outputs
	if not IsValid(ent._WireMapInterfaceEnt) and not ent._WireMapInterfaceEnt_TmpPorts and hasPorts then
		-- Don't destroy wiremod entites!
		return false
	end

	if not IsValid(ent:GetPhysicsObject()) then return false end -- Only entities with physics can get an interface!
	if ent:GetPhysicsObjectCount() ~= 1 then return false end -- Only entities with single bone physics can get an interface!

	if ent:IsWorld() then return false end -- No interface for the worldspawn!
	if ent:IsVehicle() then return false end -- No interface for vehicles!
	if ent:IsNPC() then return false end -- No interface for NPCs!
	if ent:IsPlayer() then return false end -- No interface for players!
	if ent:IsWeapon() then return false end -- No interface for weapons!
	if ent:IsConstraint() then return false end -- No interface for constraints!
	if ent:IsRagdoll() then return false end -- No interface for ragdolls!

	local class = ent:GetClass()

	if g_classBlacklist[class] then
		return false
	end

	for _, pattern in ipairs(g_classBlacklistPatterns) do
		if string.match(class, pattern) then
			return false
		end
	end

	return true
end

local g_warningColor = Color(255, 100, 100)

function ENT:FormatEntityString(ent)
	local entString = tostring(ent or NULL)

	if IsValid(ent) then
		local name = ent:GetName() or ""
		return string.format("%s[%s]", entString, name)
	end

	return entString
end

function ENT:FormatString(message, ...)
	message = tostring(message or "")

	if message == "" then
		return ""
	end

	local entString = self:FormatEntityString(self)

	message = string.format("Wire Map Interface: %s" .. message, entString, ...)
	return message
end

function ENT:PrintWarning(message, ...)
	message = self:FormatString(message, ...)

	if message == "" then
		return
	end

	MsgC(g_warningColor, message, "\n")
end

function ENT:CheckEntLimit(count, ent)
	local maxSubEntities = self:GetMaxSubEntities()

	if count >= maxSubEntities then
		self:PrintWarning(": Warning, limit of %d linked wire entities reached! Can not add: %s ", maxSubEntities, self:FormatEntityString(ent))
		return false
	end

	return true
end

function ENT:CheckPortIdLimit(portId, warn)
	portId = tonumber(portId or 0) or 0

	if portId == 0 then
		return false
	end

	if portId > self.MAX_PORTS or portId < 0 then
		if warn then
			self:PrintWarning(": Warning, invaid portId given. Expected 0 < portId < %d, got %d!", self.MAX_PORTS, portId)
		end

		return false
	end

	return true
end

-- Protect in-/output entities from non-wire tools
function ENT:FlagGetProtectFromTools()
	if not self:CreatedByMap() then
		-- Prevent abuse by runtime-spawned instances.
		return false
	end

	local flags = self:GetSpawnFlags()
	return bit.band(flags, 1) == 1
end

-- Protect in-/output entities from the physgun
function ENT:FlagGetProtectFromPhysgun()
	if not self:CreatedByMap() then
		return false
	end

	local flags = self:GetSpawnFlags()
	return bit.band(flags, 2) == 2
end

-- Remove in-/output entities on remove
function ENT:FlagGetRemoveEntities()
	if not self:CreatedByMap() then
		return false
	end

	local flags = self:GetSpawnFlags()
	return bit.band(flags, 4) == 4
end

-- Note:
--   bit.band(flags, 8) == 8 Was used for running lua code.
--   It must be left unused as it could cause unexpected side effects on older maps.

-- Start Active
function ENT:FlagGetStartActive()
	local flags = self:GetSpawnFlags()
	return bit.band(flags, 16) == 16
end

-- Render wires clientside
function ENT:FlagGetRenderWires()
	local flags = self:GetSpawnFlags()
	return bit.band(flags, 32) == 32
end

function ENT:Initialize()
	self.Active = self:FlagGetStartActive()
	self.oldIsActive = self:IsActive()

	self.WireEntsRegister = self.WireEntsRegister or {}
	self.WireEntName = self.WireEntName or ""

	self.WireInputRegisterTmp = self.WireInputRegisterTmp or {}
	self.WireOutputRegisterTmp = self.WireOutputRegisterTmp or {}

	self.WireInputTriggerBuffer = self.WireInputTriggerBuffer or {}

	self.PortsUpdated = true

	local recipientFilter = RecipientFilter()
	recipientFilter:RemoveAllPlayers()

	self.NetworkRecipientFilter = recipientFilter

	self.NextNetworkTime = CurTime() + (1 + math.random() * 2) * (self.MIN_THINK_TIME * 4)

	self:AddDupeHooks()
	self:AttachToSaveStateEntity()
end

function ENT:OnReloaded()
	-- Easier for debugging.
	self:RequestNetworkEntities()
	self:AttachToSaveStateEntity()
end

function ENT:IsActive()
	return self.Active and cvar_allow_interface:GetBool()
end

function ENT:GetMinTriggerTime()
	local minTriggerTime = math.max(
		self.MinTriggerTime or 0,
		cvar_min_trigger_time:GetFloat(),
		0
	)

	minTriggerTime = math.min(minTriggerTime, 1)
	return minTriggerTime
end

function ENT:GetMaxSubEntities()
	local maxSubEntities = math.Clamp(
		cvar_max_sub_entities:GetInt(),
		1,
		32
	)

	return maxSubEntities
end

function ENT:IsLuaRunEntity(ent)
	if not IsValid(ent) then
		return false
	end

	return ent:GetClass() == "lua_run"
end

function ENT:ProtectAgainstDangerousIO(targetEnt, outputName, output, data)
	if not string.StartsWith(string.lower(outputName), "onwireinput") then
		-- This protection is only relevant for Hammer outputs linked to Wire inputs.
		return true
	end

	local inputName = output.input
	local inputNameLower = string.lower(inputName)

	local params = output.param or ""
	if params ~= "" then
		-- We would run code from the override parameter set via Hammer, so it is safe. There is no direct user input.
		return true
	end

	if inputNameLower == "addoutput" then
		-- This can be abused to do all sorts of stuff, so don't allow AddOutput from user input. This could even run unauthorized Lua code.
		-- Warn the mapper about their mistake.
		self:PrintWarning(
			", Hammer output '%s' -> Hammer input '%s@%s': Dangerous operation!\n  Do not trigger AddOutput with user input.\n  Change this trigger or use the override parameter instead.\n  This trigger has been blocked and removed.",
			outputName,
			self:FormatEntityString(targetEnt),
			inputName
		)

		return false
	end

	if self:IsLuaRunEntity(targetEnt) and inputNameLower == "runpassedcode" then
		-- Prevent an potential RCE: Block direct user input from being run as unauthorized Lua code.
		-- Warn the mapper about their mistake.
		self:PrintWarning(
			", Hammer output '%s' -> Hammer input '%s@%s': Dangerous operation!\n  Do not run Lua code with user input!\n  This would allow players to take over the Server.\n  Use the override parameter or trigger RunCode instead.\n  This trigger has been blocked and removed.",
			outputName,
			self:FormatEntityString(targetEnt),
			inputName
		)

		return false
	end

	return true
end

function ENT:GetEntitiesByTargetnameOrClass(nameOrClass)
	nameOrClass = tostring(nameOrClass or "")

	if nameOrClass == "" then
		return nil
	end

	if nameOrClass == "!null" then
		-- Non-empty string for void entity.
		return nil
	end

	if nameOrClass == "!player" then
		-- All players

		local players = player.GetAll()
		if #players > 0 then
			return players
		end

		return nil
	end

	if nameOrClass[1] == "!" then
		local ent = self:GetFirstEntityByTargetnameOrClass(nameOrClass)
		if not IsValid(ent) then
			return nil
		end

		return {ent}
	end

	local byName = ents.FindByName(nameOrClass)
	if #byName > 0 then
		return byName
	end

	local byClass = ents.FindByClass(nameOrClass)
	if #byClass > 0 then
		return byClass
	end

	return nil
end

function ENT:GetFirstEntityByTargetnameOrClass(nameOrClass)
	nameOrClass = tostring(nameOrClass or "")

	if nameOrClass == "" then
		return nil
	end

	if nameOrClass == "!null" then
		-- Non-empty string for void entity.
		return nil
	end

	if nameOrClass == "!self" then
		-- This entity.
		return self
	end

	if nameOrClass == "!player" then
		-- First Player.

		local players = player.GetAll()
		if #players > 0 then
			local first = next(players)
			if not IsValid(first) then
				return nil
			end

			return first
		end

		return nil
	end

	if nameOrClass == "!caller" then
		-- The last entity that called an Hammer input,
		-- e.g a trigger_multiple brush.

		local lastCaller = self._lastCaller
		if not IsValid(lastCaller) then
			return nil
		end

		return lastCaller
	end

	if nameOrClass == "!activator" then
		-- The last entity that triggered !caller to call an Hammer input,
		-- e.g. a player that passed though a trigger_multiple brush.

		local lastActivator = self._lastActivator
		if not IsValid(lastActivator) then
			return nil
		end

		return lastActivator
	end

	if nameOrClass == "!input" then
		-- The entity that has the Wire input. (!activator in Hammer Output)

		local lastWireInputEnt = self._lastWireInputEnt
		if not IsValid(lastWireInputEnt) then
			return nil
		end

		return lastWireInputEnt
	end

	if nameOrClass == "!device" then
		-- The entity where the input data was from, e.g. a Wiremod button.

		local lastWireActivatorEnt = self._lastWireDeviceEnt
		if not IsValid(lastWireActivatorEnt) then
			return nil
		end

		return lastWireActivatorEnt
	end

	if nameOrClass == "!owner" then
		-- The owner of !device the !input entity is connected to,
		-- e.g. the player who spawned the Wiremod button.

		local lastOwner = self._lastWireDeviceEntOwner
		if not IsValid(lastOwner)  then
			return nil
		end

		return lastOwner
	end

	local byName = ents.FindByName(nameOrClass)
	if #byName > 0 then
		local first = next(byName)
		if not IsValid(first)  then
			return nil
		end

		return first
	end

	local byClass = ents.FindByClass(nameOrClass)
	if #byClass > 0 then
		local first = next(byClass)
		if not IsValid(first)  then
			return nil
		end

		return first
	end

	return nil
end

function ENT:AcceptInput(name, activator, caller, data)
	self._lastActivator = activator
	self._lastCaller = caller

	name = string.lower(tostring(name or ""))
	if name == "" then return false end

	if name == "activate" then
		self.Active = true
		return true
	end

	if name == "deactivate" then
		self.Active = false
		return true
	end

	if name == "toggle" then
		self.Active = not self.Active
		return true
	end

	if self:TriggerHammerInput(name, data) then
		return true
	end

	return false
end

function ENT:KeyValue(key, value)
	key = string.lower(tostring(key or ""))
	value = tostring(value or "")

	if key == "" then return end

	if self:StoreHammerOutputs(key, value) then
		return
	end

	if key == "wire_entity_name" then
		local oldValue = self.WireEntName or ""
		self.WireEntName = value

		self.WireEntNameUpdated = oldValue ~= value
		return
	end

	if key == "min_trigger_time" then
		self.MinTriggerTime = math.max(tonumber(value or 0) or 0, 0)
		return
	end

	if self:RegisterWireIO(key, value) then
		return
	end
end

function ENT:Think()
	local active = self:IsActive()

	if active ~= self.oldIsActive then
		if active then
			self:ApplyWireOutputBufferAll()
		end

	 	self.oldIsActive = active
	end

	if active then
		local wireInputTriggerBuffer = self.WireInputTriggerBuffer
		local wireInputRegister = self.WireInputRegister
		local now = CurTime()

		for uid, triggerStateData in pairs(wireInputTriggerBuffer) do
			if wireInputRegister.byUid[uid] then
				local inputData = triggerStateData.inputData
				local wireValue = triggerStateData.wireValue
				local wireEnt = triggerStateData.wireEnt

				local debounce = inputData.debounce
				local nextTime = debounce.nextTime or 0

				if nextTime <= now then
					self:TriggerHammerOutputFromWire(inputData, wireValue, wireEnt)
					wireInputTriggerBuffer[uid] = nil
				end
			else
				wireInputTriggerBuffer[uid] = nil
			end
		end
	end

	self:HandleWireEntsUpdated()
	self:HandleShouldNetworkEntities()
	self:HandlePortsUpdated()
	self:HandleWireEntNameUpdated()

	self:PollWirelinkStatus()

	self:NextThink(CurTime() + self.MIN_THINK_TIME)
	return true
end

function ENT:OnRemove()
	local wireEnts = self:GetWiredEntities()

	if self:FlagGetRemoveEntities() then
		for _, wireEnt in ipairs(wireEnts) do
			if wireEnt:IsValid() and not wireEnt:IsMarkedForDeletion() and wireEnt:CreatedByMap() then
				wireEnt:Remove()
			end
		end
	else
		self:RemoveAllEntities()
	end

	table.Empty(wireEnts)
end

