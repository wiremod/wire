
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

ENT.WireDebugName = "Damage Detector"

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,istable=true,depth=0}

// Global table to keep track of all detectors
local Wire_Damage_Detectors = {}

// Unlink if linked prop removed
local function linkRemoved( ent )
	local entID = ent:EntIndex()
	for k, v in pairs( Wire_Damage_Detectors ) do
		local detector = ents.GetByIndex(k)
		if detector.linked_entities then
			if entID == detector.linked_entities[0] then
				detector:Unlink()
			end
		end
	end
end
hook.Add("EntityRemoved", "DamageDetector_LinkRemoved", linkRemoved)

// Damage detection function
local function CheckWireDamageDetectors( ent, inflictor, attacker, amount, dmginfo )
	if amount > 0  then
		local entID = ent:EntIndex()
		for k,_ in pairs(Wire_Damage_Detectors) do
			local detector = ents.GetByIndex(k)
			if ValidEntity(detector) and detector.on then
				if !detector.updated then
					detector:UpdateLinkedEnts()
					detector.updated = true
					detector:NextThink(CurTime()+0.001)		-- Update link info once per tick per detector at most
				end
				if detector.key_ents[entID] then
					detector:UpdateDamage( dmginfo, entID )
				end
			end
		end
	end
end
hook.Add("EntityTakeDamage", "CheckWireDamageDetectors", function( ent, inflictor, attacker, amount, dmginfo )
	local r, e = pcall( CheckWireDamageDetectors, ent, inflictor, attacker, amount, dmginfo )
	if !r then print( "Wire damage detector error: " .. e ) end
end)


function ENT:Initialize()
	local self = self

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Damage", "Attacker", "Victim", "Victims", "Position", "Force", "Type" } , { "NORMAL", "ENTITY", "ENTITY", "TABLE", "VECTOR", "VECTOR", "STRING" } )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "On", "Entity", "Entities" }, { "NORMAL", "ENTITY", "ARRAY" } )

	self.on = 0
	self.updated = false		-- Tracks whether constraints were updated that tick
	self.hit = false			-- Tracks whether detector registered any damage that tick

	self.firsthit_dmginfo = {}		-- Stores damage info representing damage during an interval
	self.output_dmginfo = {}		-- Stores the current damage info outputs
	self.linked_entities = {}

	// Store output damage info
	self.victims = table.Copy(DEFAULT)
	WireLib.TriggerOutput( self, "Victims", self.victims )
	self.damage = 0

	Wire_Damage_Detectors[self:EntIndex()] = true
end

/******************************
	How entities are stored:
	self.linked_entities	Array: Entities the detector is directly linked to. Contains entIDs as values
	self.key_ents		KeyTable: Entities to check damage on (including constrained ents), only updated when the damage hook is called,.Contains entIDs as table keys
******************************/

function ENT:OnRemove()
	Wire_Damage_Detectors[self:EntIndex()] = nil
	Wire_Remove(self)
end

// Update overlay
function ENT:ShowOutput()
	local text
	if self.includeconstrained == 0 then
		text = ( "Damage Detector\n" ..
				 "(Individual Props)\n" )
	else
		text = ( "Damage Detector\n" ..
				 "(Constrained Props)\n" )
	end

	local linkedent
	if self.linked_entities and self.linked_entities[0] then
		linkedent = ents.GetByIndex( self.linked_entities[0] )
	end

	if IsValid( linkedent ) then
		if linkedent == self then
			text = text .. "Linked - Self"
		else
			text = text .. "Linked - " .. linkedent:GetModel()
		end
	else
		text = text .. "Not linked"
	end

	self:SetOverlayText(text)
end

function ENT:SetOverlayText(txt)
	self:SetNetworkedBeamString("GModOverlayText", txt)
end

function ENT:Setup( includeconstrained )
	self.includeconstrained = includeconstrained
	self:ShowOutput()
end

function ENT:LinkEntity( ent )
	self.linked_entities = {}
	self.linked_entities[0] = ent:EntIndex()		-- [0] is used to store single links (e.g. manual links)
	self:ShowOutput()
end

function ENT:Unlink()
	self.linked_entities = {}
	self:ShowOutput()
end

function ENT:TriggerInput( iname, value )
	if (iname == "On") then
		if value > 0 then self.on = true
		else self.on = false end
	elseif (iname == "Entities") then		-- Populate linked_entities from "Array"
		if value then
			self.linked_entities = {}
			for _,v in pairs(value) do
				if ValidEntity(v) then
					table.insert(self.linked_entities, v:EntIndex())
				end
			end
		end
	elseif (iname == "Entity") then
		if value then
			self.linked_entities = {}
			if ValidEntity(value) then
				self.linked_entities[1] = value:EntIndex()
			end
		end
	end
end

function ENT:TriggerOutput()		-- Entity outputs won't trigger again until they change

	timer.Remove( "wire_damage_detector_" .. tostring(self) )

	local attacker = self.firsthit_dmginfo[1]
	if ValidEntity(attacker) then
		WireLib.TriggerOutput( self, "Attacker", attacker )
	else
		WireLib.TriggerOutput( self, "Attacker", null )
	end

	local victim = self.firsthit_dmginfo[2]
	if ValidEntity( ents.GetByIndex(victim) ) then
		WireLib.TriggerOutput( self, "Victim", ents.GetByIndex(victim) )
	else
		WireLib.TriggerOutput( self, "Victim", null )
	end

	self.victims.size = table.Count(self.victims.s)
	WireLib.TriggerOutput( self, "Victims", self.victims or table.Copy(DEFAULT) )
	WireLib.TriggerOutput( self, "Position", self.firsthit_dmginfo[3] or Vector(0,0,0) )
	WireLib.TriggerOutput( self, "Force", self.firsthit_dmginfo[4] or Vector(0,0,0) )
	WireLib.TriggerOutput( self, "Type", self.firsthit_dmginfo[5] or "" )

	WireLib.TriggerOutput( self, "Damage", self.damage or 0 )
	timer.Create( "wire_damage_detector_" .. tostring(self), 0, 1, WireLib.TriggerOutput, self, "Damage", 0 )
end

function ENT:UpdateLinkedEnts()		-- Check to see if prop is registered by the detector
	if !self.linked_entities then return nil end

	self.key_ents = {}

	if self.includeconstrained == 1 then		-- Don't update constrained entities unless we have to
		self:UpdateConstrainedEnts()
	end

	for _,v in pairs (self.linked_entities) do		-- include linked_entities
		if ValidEntity( ents.GetByIndex(v) ) then
			self.key_ents[v] = true
		end
	end
end

function ENT:UpdateConstrainedEnts()		-- Finds all entities constrained to linked_entities
	for _,v in pairs (self.linked_entities) do
		local ent = ents.GetByIndex(v)
		if ValidEntity(ent) and constraint.HasConstraints(ent) and !self.key_ents[v] then
			for _,w in pairs( constraint.GetAllConstrainedEntities(ent) ) do
				if ValidEntity(w) then
					self.key_ents[w:EntIndex()] = true
				end
			end
		end
	end
end

function ENT:UpdateDamage( dmginfo, entID )		-- Update damage table
	local damage = dmginfo:GetDamage()

	if !self.hit then		-- Only register the first target's damage info
		self.firsthit_dmginfo = {
			dmginfo:GetAttacker(),
			entID,
			dmginfo:GetDamagePosition(),
			dmginfo:GetDamageForce()
		}

		// Damage type (handle common types)
		self.dmgtype = ""
		if dmginfo:IsExplosionDamage() then self.dmgtype = "Explosive"
		elseif dmginfo:IsBulletDamage() or dmginfo:IsDamageType(DMG_BUCKSHOT) then self.dmgtype = "Bullet"
		elseif dmginfo:IsDamageType(DMG_SLASH) or dmginfo:IsDamageType(DMG_CLUB) then self.dmgtype = "Melee"
		elseif dmginfo:IsFallDamage() then self.dmgtype = "Fall"
		elseif dmginfo:IsDamageType(DMG_CRUSH) then self.dmgtype = "Crush"
		end

		self.victims = table.Copy(DEFAULT)
		self.firsthit_dmginfo[5] = self.dmgtype

		self.hit = true
	end

	if self.dmgtype == "Explosive" then		-- Explosives will output the entity that receives the most damage
		if self.damage < damage then
			self.damage = damage
			self.firsthit_dmginfo[2] = entID
		end
	else
		self.damage = self.damage + damage
	end

	// Update victims table (ent, damage)
	self.victims.s[tostring(entID)] = ( self.victims[tostring(entID)] or 0 ) + damage
	self.victims.stypes[tostring(entID)] = "n"
end

function ENT:Think()
	self.updated = false
	self.hit = false
	if self.damage > 0 then
		self:TriggerOutput()
		self.damage = 0
	end
	return true
end

// Advanced Duplicator Support

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if ValidEntity( ents.GetByIndex(self.linked_entities[0]) ) then
	    info.linked_entities = self.linked_entities[0]
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if ValidEntity( GetEntByID(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = GetEntByID(info.linked_entities):EntIndex()
	elseif ValidEntity( ents.GetByIndex(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = info.linked_entities
	end
	self:ShowOutput()
end
