-- This part of the wire map interface entity controls
-- the adding and removing of its in-/outputs entities.


-- The removing function
-- Its for removing all the wiremod stuff from unused entities.
local function RemoveWire(Entity, SendToCL)
	if (not IsValid(Entity)) then return end

	Wire_Remove(Entity, not SendToCL)

	local self = Entity._WireMapInterfaceEnt
	if (IsValid(self)) then
		self.WireEntsCount = math.max(self.WireEntsCount - 1, 0)
		if (self.WireEnts) then
			self.WireEnts[Entity] = nil
		end
		if (self.WireOutputToggle) then
			self.WireOutputToggle[Entity] = nil
		end
		if (self.Wired) then
			self.Wired[Entity] = nil
		end
	end

	if (not SendToCL) then return end

	Entity:_RemoveOverrides()
	WireLib._RemoveWire(Entity:EntIndex(), true) -- Remove entity from the list, so it doesn't count as a wire able entity anymore.

	umsg.Start("WireMapInterfaceEnt")
		umsg.Entity(Entity)
		umsg.Char(-1)
	umsg.End()

	Entity:RemoveCallOnRemove("WireMapInterface_OnRemove")
	if (table.IsEmpty(Entity.OnDieFunctions)) then
		Entity.OnDieFunctions = nil
	end
end

function ENT:Timedpairs(name, tab, steps, cb, endcb, ...)
	if (table.IsEmpty(tab)) then return end

	local name = self:EntIndex().."_"..tostring(name)
	self.TimedpairsTable = self.TimedpairsTable or {}

	WireLib.Timedpairs(name, tab, steps, function(...)

		if (IsValid(self)) then
			self.TimedpairsTable[name] = true
		end
		return cb(...)

	end, function(...)

		if (IsValid(self)) then
			self.TimedpairsTable[name] = nil
		end
		if (endcb) then
			return endcb(...)
		end

	end, ...)
end

local function CallOnEnd(self, AddedEnts)
	if (not IsValid(self)) then return end

	self.WirePortsChanged = true
	self:GiveWireInterfeceClient(nil, AddedEnts)
	self:TriggerOutput("onwireentscreated", self)
	self:TriggerOutput("onwireentsready", self)
end

function ENT:GiveWireInterfece(EntsToAdd)
	if (not EntsToAdd) then return end
	if (table.IsEmpty(EntsToAdd) or not self.WirePortsChanged) then return end
	local AddedEnts = {}
	self:UpdateData()

	self:Timedpairs("WireMapInterface_Adding", EntsToAdd, 1, function(obj1, obj2, self)
		if (not IsValid(self)) then return false end -- Stop loop when the entity gets removed.
		if (self.WirePortsChanged) then
			self:TriggerOutput("onwireentsstartchanging", self)
		end
		self.WirePortsChanged = nil

		local Entity = (IsEntity(obj1) and obj1) or (IsEntity(obj2) and obj2)

		local Ent, Func = self:AddSingleEntity(Entity, CallOnEnd, AddedEnts)
		if (Ent == "limid_exceeded") then return false end -- Stop loop when maximum got exceeded
		if (not IsValid(Ent) or not Func) then return end

		AddedEnts[Ent] = Func
	end, function(k, v, self) CallOnEnd(self, AddedEnts) end, self)
end

function ENT:GiveWireInterfeceClient(ply, EntsToAdd)
	if (not self.WireEnts) then return end

	self:Timedpairs((IsValid(ply) and (ply:EntIndex().."") or "").."WireMapInterface_Adding_CL", EntsToAdd or self.WireEnts, 1, function(Entity, Func, self)
		if (not IsValid(self)) then return false end -- Stop loop when the entity gets removed.
		if (not IsValid(Entity)) then return end
		if (not self:IsWireableEntity(Entity)) then return end

		Func(self, Entity, ply, not IsValid(ply))
	end, nil, self)
end


-- Entity add functions
function ENT:AddEntitiesByName(Name)
	Name = tostring(Name or "")
	if (Name == "") then return end

	self:AddEntitiesByTable(ents.FindByName(Name))
end

function ENT:AddEntitiesByTable(Table)
	if (not Table) then return end

	self:GiveWireInterfece(Table)
end

local function AddSingleEntityCL(self, Entity, ply, SendToAll)
	if (not IsValid(Entity)) then return end
	if (not IsValid(self)) then return end
	if (not self.WireEnts[Entity]) then return end
	if (not SendToAll and not IsValid(ply)) then return end

	if (SendToAll) then
		umsg.Start("WireMapInterfaceEnt")
	else
		umsg.Start("WireMapInterfaceEnt", ply)
	end
		umsg.Entity(Entity)
		umsg.Char(self.flags % 64)
		-- Allow valid spawnflags only.
	umsg.End()
end

function ENT:AddSingleEntity(Entity, callOnEnd, AddedEnts)
	if (not IsValid(Entity)) then return end
	if (not self:IsWireableEntity(Entity)) then return end
	if (not self:CheckEntLimid(callOnEnd, AddedEnts)) then return "limid_exceeded" end

	if (IsValid(Entity._WireMapInterfaceEnt)) then
		RemoveWire(Entity, true)
	end

	self:OverrideEnt(Entity)
	Entity:CallOnRemove("WireMapInterface_OnRemove", RemoveWire)

	if (self.Inames) then
		Entity.Inputs = WireLib.CreateSpecialInputs(Entity, self.Inames, self.Itypes, self.Idescs)
	end
	if (self.Onames) then
		Entity.Outputs = WireLib.CreateSpecialOutputs(Entity, self.Onames, self.Otypes, self.Odescs)
	end

	self.WireEnts = self.WireEnts or {}
	self.WireEnts[Entity] = AddSingleEntityCL

	return Entity, AddSingleEntityCL
end


-- Entity remove functions
function ENT:RemoveAllEntities(callback)
	for name, _ in pairs(self.TimedpairsTable or {}) do
		WireLib.TimedpairsStop(name)
	end

	self.WirePortsChanged = true

	self:RemoveEntitiesByTable(self.WireEnts, callback)
	self.WireEntsCount = 0
end


function ENT:RemoveEntitiesByName(Name, callback)
	Name = tostring(Name or "")
	if (Name == "") then return end

	self:RemoveEntitiesByTable(ents.FindByName(Name), callback)
end

function ENT:RemoveEntitiesByTable(Table, callback)
	if (not Table) then return end
	if (table.IsEmpty(Table) or not self.WirePortsChanged) then return end

	local Removed = nil
	self:Timedpairs("WireMapInterface_Removing", Table, 1, function(obj1, obj2, self)
		local Entity = (IsEntity(obj1) and obj1) or (IsEntity(obj2) and obj2)

		if (not IsValid(Entity)) then return end
		if (not IsValid(Entity._WireMapInterfaceEnt)) then return end
		if (Entity._WireMapInterfaceEnt ~= self) then return end
		if (self and self.WirePortsChanged) then
			self:TriggerOutput("onwireentsstartchanging", self)
			self.WirePortsChanged = nil
		end

		RemoveWire(Entity, true)
		Removed = true
	end,
	function(k, v, self, callback)
		if (not IsValid(self)) then return end
		self.WirePortsChanged = true

		if (callback) then
			callback(self, Removed)
		end

		if (not Removed) then return end
		self:TriggerOutput("onwireentsremoved", self)
		self:TriggerOutput("onwireentsready", self)
	end, self, callback)

end

function ENT:RemoveSingleEntity(Entity)
	if (not IsValid(Entity)) then return end
	if (not IsValid(Entity._WireMapInterfaceEnt)) then return end
	if (Entity._WireMapInterfaceEnt ~= self) then return end

	RemoveWire(Entity, true)
	self:TriggerOutput("onwireentsremoved", self)
	self:TriggerOutput("onwireentsready", self)
end



function ENT:GetWiredEntities()
	return table.Copy(self.WireEnts or {})
end

function ENT:SetWiredEntities(Table)
	if (not Table) then return end

	local Ents = {}
	local Count = 0
	for obj1, obj2 in pairs(Table) do -- Filter invalid stuff out!
		local Entity = (IsEntity(obj1) and obj1) or (IsEntity(obj2) and obj2)
		if (IsValid(Entity)) then
			Count = Count + 1
			Ents[Count] = Entity
		end
	end
	self:RemoveAllEntities(function(self)
		self:AddEntitiesByTable(Ents)
	end)
end
