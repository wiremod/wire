AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire Damage Detector"
ENT.WireDebugName = "Damage Detector"

if CLIENT then return end

local Wire_Damage_Detectors = {}

hook.Add("PostEntityTakeDamage", "CheckWireDamageDetectors", function(ent, dmg)
	local curtime = CurTime()

	for _, detector in ipairs(Wire_Damage_Detectors) do
		local tab = detector:GetTable()

		if tab.on then
			if not tab.updated then
				tab.updated = true
				tab.UpdateLinkedEnts(detector, tab)
				detector:NextThink(curtime)
			end

			if tab.key_ents[ent] then
				tab.UpdateDamage(detector, tab, dmg, ent)
			end
		end
	end
end)

function ENT:Initialize()
	table.insert(Wire_Damage_Detectors, self)
	self:PhysicsInit(SOLID_VPHYSICS)

	WireLib.CreateOutputs(self, { "Clk", "Damage", "Attacker [ENTITY]", "Victim [ENTITY]", "Victims [TABLE]", "Position [VECTOR]", "Force [VECTOR]", "Type [STRING]" })
	WireLib.CreateInputs(self, { "On", "Entity (This entity will be added whenever this input changes to a valid entity) [ENTITY]", "Entities (These entities will be added whenever this input changes.\nCan be changed at most once per second.) [ARRAY]", "Reset" })

	self.on = false
	self.updated = false
	self.hit = false
	self.firsthit_dmginfo = {}
	self.linked_entities = {}
	self:LinkEnt(self)

	self.damage = 0
	self.count = 0
	self.key_ents = {}

	-- Store output damage info
	self.victims = {}
	WireLib.TriggerOutput(self, "Victims", self.victims)
end

function ENT:Setup(includeconstrained)
	self.includeconstrained = includeconstrained
end

function ENT:TriggerInput(name, value)
	if name == "On" then
		self.on = value ~= 0
	elseif name == "Entities" then
		if value then
			self:ClearEntities()

			for _, ent in pairs(value) do
				if IsValid(ent) then
					self:LinkEnt(ent)
				end
			end
		end
	elseif name == "Entity" then
		if IsValid(value) then
			self:LinkEnt(value)
		end
	elseif name == "Reset" then
		if value then
			local tab = self:GetTable()
			tab.count = 0
			tab.firsthit_dmginfo = {}
			tab.victims = {}
			tab.damage = 0
			tab.TriggerOutput(self, tab)
		end
	end
end

function ENT:TriggerOutput(tab)
	local attacker = tab.firsthit_dmginfo[1]
	WireLib.TriggerOutput(self, "Attacker", IsValid(attacker) and attacker or NULL)

	local victim = tab.firsthit_dmginfo[2]
	WireLib.TriggerOutput(self, "Victim", IsValid(victim) and victim or NULL)

	WireLib.TriggerOutput(self, "Victims", tab.victims)
	WireLib.TriggerOutput(self, "Position", tab.firsthit_dmginfo[3] or Vector(0, 0, 0))
	WireLib.TriggerOutput(self, "Force", tab.firsthit_dmginfo[4] or Vector(0, 0, 0))
	WireLib.TriggerOutput(self, "Type", tab.firsthit_dmginfo[5] or "")
	WireLib.TriggerOutput(self, "Damage", tab.damage)
	WireLib.TriggerOutput(self, "Clk", tab.count)
end

function ENT:UpdateLinkedEnts(tab)
	local linked = tab.linked_entities

	if #linked == 0 then
		tab.key_ents = {}
		return
	end

	local key_ents = {}
	local include_constrained = tab.includeconstrained == 1
	tab.key_ents = key_ents

	for _, ent in ipairs(linked) do
		if include_constrained then
			tab.UpdateConstrainedEnts(self, tab, ent)
		end

		key_ents[ent] = true
	end
end

function ENT:UpdateConstrainedEnts(tab, ent)
	local key_ents = tab.key_ents

	for ent in pairs(constraint.GetAllConstrainedEntities(ent)) do
		key_ents[ent] = true
	end
end

local dmg_types = {
	[DMG_GENERIC] = "Generic",
	[DMG_CRUSH] = "Crush",
	[DMG_BULLET] = "Bullet",
	[DMG_SLASH] = "Slash",
	[DMG_BURN] = "Burn",
	[DMG_VEHICLE] = "Vehicle",
	[DMG_FALL] = "Fall",
	[DMG_BLAST] = "Explosive",
	[DMG_CLUB] = "Club",
	[DMG_SHOCK] = "Shock",
	[DMG_SONIC] = "Sonic",
	[DMG_ENERGYBEAM] = "Laser",
	[DMG_DROWN] = "Drown",
	[DMG_PARALYZE] = "Paralyze",
	[DMG_POISON] = "Poison",
	[DMG_NERVEGAS] = "Neurotoxin",
	[DMG_RADIATION] = "Radiation",
	[DMG_ACID] = "Toxic",
	[DMG_PHYSGUN] = "Gravgun",
	[DMG_PLASMA] = "Plasma",
	[DMG_AIRBOAT] = "AirboatGun",
	[DMG_ENERGYBEAM] = "Laser",
	[DMG_DIRECT] = "Direct"
}

function ENT:UpdateDamage(tab, dmg, ent)
	local damage = dmg:GetDamage()
	local victims = tab.victims

	if not tab.hit then
		tab.dmgtype = dmg_types[dmg:GetDamageType()] or "Other"
		tab.firsthit_dmginfo = { dmg:GetAttacker(), ent, dmg:GetDamagePosition(), dmg:GetDamageForce(), tab.dmgtype }

		victims = {}
		tab.victims = victims
		tab.hit = true
	end

	if tab.dmgtype == "Explosive" then
		if tab.damage < damage then
			tab.damage = damage
			tab.firsthit_dmginfo[2] = ent
		end
	else
		tab.damage = tab.damage + damage
	end

	local id = tostring(ent:EntIndex())
	victims[id] = damage + (victims[id] or 0)

	tab.count = tab.count + 1
end

function ENT:Think()
	local tab = self:GetTable()
	tab.updated = false
	tab.hit = false

	if tab.damage > 0 then
		tab.TriggerOutput(self, tab)
		tab.damage = 0
	end

	return true
end

function ENT:CheckEnt(checkent)
	for index, ent in ipairs(self.linked_entities) do
		if checkent == ent then
			return true, index
		end
	end

	return false, 0
end

function ENT:LinkEnt(ent)
	if self:CheckEnt(ent) then return false	end

	table.insert(self.linked_entities, ent)

	ent:CallOnRemove("DamageDetector.Unlink" .. self:EntIndex(), function(ent)
		self:UnlinkEnt(ent)
	end)

	return true
end

function ENT:UnlinkEnt(ent)
	local bool, index = self:CheckEnt(ent)

	if bool then
		table.remove(self.linked_entities, index)
		ent:RemoveCallOnRemove("DamageDetector.Unlink" .. self:EntIndex())
	end

	return bool
end

function ENT:ClearEntities()
	for index, ent in ipairs(self.linked_entities) do
		ent:RemoveCallOnRemove("DamageDetector.Unlink" .. self:EntIndex())
	end

	self.linked_entities = {}
end

function ENT:OnRemove()
	table.RemoveByValue(Wire_Damage_Detectors, self)
	self:ClearEntities()
	BaseClass.OnRemove(self)
end

function ENT:PrepareMarksData()
	WireLib.SendMarks(self, self.linked_entities)
end

function ENT:PrepareOverlayData()
	local num = #self.linked_entities
	self:SetOverlayText(string.format("(%s)\nLinked to %s entities%s", (self.includeconstrained == 1) and "Constrained Props" or "Individual Props", num, (num == 1 and self.linked_entities[1] == self) and "\nLinked only to self" or ""))
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self)

	if #self.linked_entities > 0 then
		local tab = {}

		for index, ent in ipairs(self.linked_entities) do
			tab[index] = ent:EntIndex()
		end

		info.linked_entities = tab
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.linked_entities then
		-- Prevent double linking to self
		self:ClearEntities()

		-- Backwards compat
		if isnumber(info.linked_entities) then
			info.linked_entities = { info.linked_entities }
		end

		for index, entid in ipairs(info.linked_entities) do
			local ent = GetEntByID(entid)

			if IsValid(ent) then
				table.insert(self.linked_entities, ent)

				ent:CallOnRemove("DamageDetector.Unlink" .. self:EntIndex(), function(ent)
					self:UnlinkEnt(ent)
				end)
			end
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_damage_detector", WireLib.MakeWireEnt, "Data", "includeconstrained")
