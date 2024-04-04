--[[
This is the wire map interface entity by Grocel. (info_wiremapinterface)

This point entity allows you to give other entities wire in-/outputs.
Those wire ports allows you to control thinks on the map with Wiremod
or to let the map return thinks to wire outputs.

It supports many datatypes and custom lua codes.
A lua code is run when its input triggers.
It has special globals:
	WIRE_NAME = Input name
	WIRE_VALUE = Input value
	WIRE_WIRED = Is the input wired?
	WIRE_CALLER = This entity
	WIRE_ACTIVATOR = The entity that has the input

Keep in mind that you have to know what you do
and that you have to activate spawnflag 8 to make it work.
Spawnflag 8 is better known as "Run given Lua codes (For advanced users!)" in the Hammer Editor.

Please don't change things unless you know what you do. You may break maps if do something wrong.
]]

include("convert.lua")
include("entitycontrol.lua")
include("entityoverride.lua")

local ALLOW_INTERFACE = CreateConVar("sv_wire_mapinterface", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_GAMEDLL}, "Aktivate or deaktivate the wire map interface. Default: 1")


local Ents = {}
hook.Add("PlayerInitialSpawn", "WireMapInterface_PlayerInitialSpawn", function(ply)
	if (not IsValid(ply)) then return end
	for Ent, time in ipairs(Ents) do
		if (not IsValid(Ent)) then break end

		timer.Simple(time + 0.1, function()
			if (not IsValid(ply)) then return end
			if (not IsValid(Ent)) then return end
			if (not Ent.GiveWireInterfeceClient) then return end

			Ent:GiveWireInterfeceClient(ply)
		end)
	end
end)

-- This is a point entity
ENT.Base = "base_point"
ENT.Type = "point"

local MAX_PORTS = 256 -- This entity supports more than the 8 ports you see in the editor. This value is the port limit.
local MAX_ENTITIES = 32 -- The maximum number of entities per interface entitiy that can get wire ports
local MIN_TRIGGER_TIME = 0.01 -- Minimum triggering Time for in- and outputs.

-- This checks if you can give an entity wiremod abilities
function ENT:IsWireableEntity(Entity)
	if (not IsValid(Entity)) then return false end -- No interface for invalid entities!
	if (IsValid(Entity._WireMapInterfaceEnt) and (Entity._WireMapInterfaceEnt ~= self)) then return false end -- Only one interface per entity!
	if (not IsValid(Entity._WireMapInterfaceEnt) and (WireLib.HasPorts(Entity) or Entity.IsWire or Entity.Inputs or Entity.Outputs)) then return false end -- Don't destroy wiremod entites!

	if (Entity:IsWorld()) then return false end -- No interface for the worldspawn!
	if (Entity:IsVehicle()) then return false end -- No interface for vehicles!
	if (Entity:IsNPC()) then return false end -- No interface for NPCs!
	if (Entity:IsPlayer()) then return false end -- No interface for players!
	if (Entity:IsWeapon()) then return false end -- No interface for weapons!
	if (string.match(Entity:GetClass(), "^(item_[%w_]+)")) then return false end -- No interface for items!
	if (Entity:IsConstraint()) then return false end -- No interface for constraints!

	if (Entity:GetPhysicsObjectCount() > 1) then return false end -- No interface for ragdolls!
	if (IsValid(Entity:GetPhysicsObject())) then return true end -- Everything with a single physics object can get an interface!

	return true
end

function ENT:CheckEntLimid(CallOnMax, ...)
	if (self.WireEntsCount > MAX_ENTITIES) then
		MsgN(self.ErrorName..": Warning, to many wire entities linked!")
		if (CallOnMax) then
			CallOnMax(self, ...)
		end
		return false
	end
	self.WireEntsCount = self.WireEntsCount + 1
	return true
end

-- Run the given lua code
local function RunLua(I, name, value, wired, self, Ent)
	local lua = self.Ins[I].lua or ""
	if ((lua == "") or not self.RunLuaCode) then return end

	local func = CompileString(lua, self.ErrorName.." (Input "..I..")", false)
	local Err
	if isfunction(func) then
		-- Globals
		WIRE_NAME = name -- Input name
		WIRE_VALUE = value -- Input value
		WIRE_WIRED = wired -- Is the input wired?
		WIRE_CALLER = self -- This entity
		WIRE_ACTIVATOR = Ent -- The entity that has the input

		local status, err = xpcall(func, debug.traceback)
		if (not status) then
			Err = err or ""
		end

		-- Remove globals
		WIRE_NAME = nil
		WIRE_VALUE = nil
		WIRE_WIRED = nil
		WIRE_CALLER = nil
		WIRE_ACTIVATOR = nil
	else
		Err = func
	end

	if (Err and (Err ~= "")) then
		ErrorNoHalt(Err.."\n")
	end
end

-- Wire input
function ENT:TriggerWireInput(name, value, wired, Ent)
	if (not WireAddon) then return end
	if (not IsValid(Ent)) then return end
	if ((not self.Active or not ALLOW_INTERFACE:GetBool()) and wired) then
		self.SavedIn = self.SavedIn or {}
		self.SavedIn[name] = {value, wired, Ent}

		return
	end

	self.Wired = self.Wired or {}
	self.Wired[Ent] = self.Wired[Ent] or {}
	local WireRemoved = ((self.Wired[Ent][name] or false) ~= wired) and not wired
	self.Wired[Ent][name] = wired

	self.Timer = self.Timer or {}
	self.Timer.In = self.Timer.In or {}
	if (((CurTime() - (self.Timer.In[name] or 0)) < (self.min_trigger_time or MIN_TRIGGER_TIME)) and not WireRemoved) then return end
	self.Timer.In[name] = CurTime()

	self.Data = self.Data or {}
	self.Data.In = self.Data.In or {}
	if ((self.Data.In[name] == value) and not WireRemoved) then return end
	self.Data.In[name] = value

	local I = self.InsIDs[name] or 0
	if ((I > 0) and (I <= MAX_PORTS) and self.InsExist[I]) then
		local _, Convert, Toggle = self:Convert_WireToMap(self.Ins[I].type)
		if (not Convert) then return end
		local Output = "onwireinput"..I

		-- Map output
		if (not wired) then
			if (WireRemoved) then
				if (not Toggle) then
					self:TriggerOutput(Output, Ent, Convert(value))
				end
				self:TriggerOutput("onresetwireinput"..I, Ent)

				RunLua(I, name, value, wired, self, Ent)
			end
		else
			if (Toggle) then
				if (Convert(value)) then
					self:TriggerOutput(Output, Ent)

					RunLua(I, name, value, wired, self, Ent)
				end
			else
				self:TriggerOutput(Output, Ent, Convert(value))

				RunLua(I, name, value, wired, self, Ent)
			end
		end
	end
end

-- Wire output
function ENT:TriggerWireOutput(ent, i, val)
	if (not IsValid(ent)) then return false end

	local OutputName = self.Outs[i].name or ""
	if (OutputName == "") then return false end

	local _, Convert, Toggle = self:Convert_MapToWire(self.Outs[i].type)
	if (not Convert) then return false end

	if (Toggle) then
		Wire_TriggerOutput(ent, OutputName, Convert(self, ent, i))
	else
		Wire_TriggerOutput(ent, OutputName, Convert(val))
	end
	return true
end

-- Map input
function ENT:AcceptInput(name, activator, caller, data)
	if (not WireAddon) then return false end
	name = string.lower(tostring(name or ""))
	if (name == "") then return false end

	if (name == "activate") then
		self.Active = true
		return true
	end

	if (name == "deactivate") then
		self.Active = false
		return true
	end

	if (name == "toggle") then
		self.Active = not self.Active
		return true
	end

	if (self.Active and ALLOW_INTERFACE:GetBool()) then
		local pattern = "(%d+)"
		local I = tonumber(string.match(name, "triggerwireoutput"..pattern)) or 0

		if I > 0 and I <= MAX_PORTS and self.OutsExist[I] then
			self.Timer = self.Timer or {}
			self.Timer.Out = self.Timer.Out or {}

			if ((CurTime() - (self.Timer.Out[name] or 0)) < (self.min_trigger_time or MIN_TRIGGER_TIME)) then return false end
			self.Timer.Out[name] = CurTime()

			-- Wire output
			for Ent, _ in pairs(self.WireEnts or {}) do
				self:TriggerWireOutput(Ent, I, data)
			end

			return true
		end
	end

	if (not self.WirePortsChanged) then return false end

	if (name == "addentity") then
		local Ent, Func = self:AddSingleEntity(caller)

		if (not IsValid(Ent) or not Func) then return false end
		timer.Simple(0.02, function() Func( self, Ent, nil, true) end)

		self:TriggerOutput("onwireentscreated", self)
		self:TriggerOutput("onwireentsready", self)
		return true
	end

	if (name == "removeentity") then
		self:RemoveSingleEntity(caller)
		return true
	end

	if (name == "addentities") then
		self:AddEntitiesByName(data)
		return true
	end

	if (name == "removeentities") then
		self:RemoveEntitiesByName(data)
		return true
	end

	if (name == "removeallentities") then
		self:RemoveAllEntities()
		return true
	end

	return false
end

function ENT:KeyValue(key, value)
	if (not WireAddon) then return end

	key = string.lower(tostring(key or ""))
	value = tostring(value or "")

	if ((key == "") or (value == "")) then return end

	local pattern = "(%d+)"
	local I = tonumber(string.match(key, "onwireinput"..pattern)) or 0
	if ((I > 0) and (I <= MAX_PORTS)) then
		self:StoreOutput(key, value)
	end

	local I = tonumber(string.match(key, "onresetwireinput"..pattern)) or 0
	if ((I > 0) and (I <= MAX_PORTS)) then
		self:StoreOutput(key, value)
	end

	if ((key == "onwireentscreated") or (key == "onwireentsremoved") or
		(key == "onwireentsready") or (key == "onwireentsstartchanging")) then
		self:StoreOutput(key, value)
	end

	if (key == "wire_entity_name") then
		self.WireEntName = value
	end

	if (key == "min_trigger_time") then
		self.min_trigger_time = math.max(tonumber(value) or 0, MIN_TRIGGER_TIME)
	end

	local pattern = "(%d+)_(%l+)"
	local I, name = string.match(key, "input"..pattern)
	local I, name = tonumber(I) or 0, tostring(name or "")
	if ((I > 0) and (I <= MAX_PORTS) and (name ~= "")) then
		self.Ins = self.Ins or {}
		self.InsIDs = self.InsIDs or {}
		self.InsExist = self.InsExist or {}

		self.Ins[I] = self.Ins[I] or {}
		if (name == "lua") then
			self.Ins[I][name] = value
		elseif (name == "type") then
			self.Ins[I][name] = tonumber(value)
		elseif (name == "desc") then
			self.Ins[I][name] = value
		elseif (name == "name") then
			self.InsIDs[value] = I
			self.InsExist[I] = true
			self.Ins[I][name] = value
		end
	end

	local I, name = string.match(key, "output"..pattern)
	local I, name = tonumber(I) or 0, tostring(name or "")
	if I > 0 and I <= MAX_PORTS and name ~= "" then
		self.Outs = self.Outs or {}
		self.OutsExist = self.OutsExist or {}

		self.Outs[I] = self.Outs[I] or {}
		if (name == "type") then
			self.Outs[I][name] = tonumber(value)
		elseif (name == "desc") then
			self.Outs[I][name] = value
		elseif (name == "name") then
			self.OutsExist[I] = true
			self.Outs[I][name] = value
		end
	end
end

local Count = 1
function ENT:Initialize()
	if (not WireAddon) then return end
	self.WireEnts = self.WireEnts or {}
	self.WireEntsCount = 0
	self.WireEntName = self.WireEntName or ""

	self:UpdateData()
	self.Active = (bit.band(self.flags, 16) > 0) -- Start Active
	self.oldActive = self.Active
	self.old_ALLOW_INTERFACE_bool = ALLOW_INTERFACE:GetBool()

	local Name = self:GetName() or ""
	local ErrorName = "Wire Map Interface: "..tostring(self)

	if (Name == "") then
		self.ErrorName = ErrorName
	else
		self.ErrorName = ErrorName.."['"..Name.."']"
	end


	local time = Count * 0.3 + 0.5

	if (self.WireEntName == "") then
		self.WirePortsChanged = true
	else
		timer.Simple(time, function()
			if (not IsValid(self)) then return end
			self.WirePortsChanged = true

			self:AddEntitiesByName(self.WireEntName)
		end)
	end

	Ents[self] = time
	Count = Count + 1
end

-- To cleanup and get the in-/outputs information.
local function SplitTable(tab, self)
	if (not IsValid(self)) then return end

	if (not tab) then return end
	if (#tab == 0) then return end
	local tab = table.Copy(tab)

	local allowlua = self.RunLuaCode

	local names, types, descs = {}, {}, {}
	local Index = 0

	for i = 1, #tab do
		local Port = tab[i]
		if (Port) then
			local name = Port.name -- The port name for checking
			if (name) then -- Do not add ports with no names
				Index = Index + 1

				names[Index] = name -- The port name
				types[Index] = self:Convert_MapToWire(Port.type) -- The port type
				descs[Index] = Port.desc -- The port description
				if (not allowlua) then
					tab[i].lua = nil -- remove lua codes if the lua mode isn't on.
				end
			else
				tab[i] = nil -- Resort and cleanup the given table for later using
			end
		end
	end

	return names, types, descs, tab
end

function ENT:UpdateData()
	self.flags = self:GetSpawnFlags()
	self.RunLuaCode = (bit.band(self.flags, 8) > 0) -- Run given Lua codes

	self.Inames, self.Itypes, self.Idescs, self.Ins = SplitTable(self.Ins, self)
	self.Onames, self.Otypes, self.Odescs, self.Outs = SplitTable(self.Outs, self)
end

function ENT:Think()
	if (not WireAddon) then return end

	local ALLOW_INTERFACE_bool = ALLOW_INTERFACE:GetBool()
	if ((self.Active ~= self.oldActive) or (ALLOW_INTERFACE_bool ~= self.old_ALLOW_INTERFACE_bool)) then
		if (self.Active and ALLOW_INTERFACE_bool) then
			self.SavedIn = self.SavedIn or {}
			for name, values in pairs(self.SavedIn) do
				self:TriggerWireInput(name, unpack(values))
				self.SavedIn[name] = nil
			end
		end
		self.oldActive = self.Active
		self.old_ALLOW_INTERFACE_bool = ALLOW_INTERFACE_bool
	end
end

function ENT:OnRemove()
	if (not WireAddon) then return end

	self.flags = self:GetSpawnFlags()

	if (bit.band(self.flags, 4) > 0) then -- Remove in-/output entities on remove
		for obj1, obj2 in pairs(self.WireEnts or {}) do
			local Entity = (IsEntity(obj1) and obj1) or (IsEntity(obj2) and obj2)

			if (IsValid(Entity)) then
				SafeRemoveEntity(Entity)
			end
		end
	else
		self:RemoveAllEntities()
	end
end
