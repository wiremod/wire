AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Damage Detector"
ENT.Author          = "Jimlad"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName = "Damage Detector"

if CLIENT then return end -- No more client

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,istable=true}

// Global table to keep track of all detectors
local Wire_Damage_Detectors = {}

// Damage detection function
local function CheckWireDamageDetectors( ent, inflictor, attacker, amount, dmginfo )
	if amount > 0  then
		local entID = ent:EntIndex()
		for k,_ in pairs(Wire_Damage_Detectors) do
			local detector = ents.GetByIndex(k)
			if IsValid(detector) and detector.on then
				if !detector.updated then
					detector:UpdateLinkedEnts()
					detector.updated = true
					detector:NextThink(CurTime())		-- Update link info once per tick per detector at most
				end
				if detector.key_ents[entID] then
					detector:UpdateDamage( dmginfo, entID )
				end
			end
		end
	end
end
hook.Add("EntityTakeDamage", "CheckWireDamageDetectors", function( ent, dmginfo )
	if not next(Wire_Damage_Detectors) then return end
	local r, e = pcall( CheckWireDamageDetectors, ent, dmginfo:GetInflictor(), dmginfo:GetAttacker(), dmginfo:GetDamage(), dmginfo )
	if !r then print( "Wire damage detector error: " .. e ) end
end)


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Clk", "Damage", "Attacker", "Victim", "Victims", "Position", "Force", "Type" } , { "NORMAL", "NORMAL", "ENTITY", "ENTITY", "TABLE", "VECTOR", "VECTOR", "STRING" } )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "On", "Entity", "Entities", "Reset" }, { "NORMAL", "ENTITY", "ARRAY", "NORMAL" } )

	self.on = 0
	self.updated = false		-- Tracks whether constraints were updated that tick
	self.hit = false			-- Tracks whether detector registered any damage that tick

	self.firsthit_dmginfo = {}		-- Stores damage info representing damage during an interval
	self.linked_entities = {}

	self.count = 0

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
		text = "(Individual Props)\n"
	else
		text = "(Constrained Props)\n"
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

function ENT:Setup( includeconstrained )
	self.includeconstrained = includeconstrained
	self:ShowOutput()
end

function ENT:LinkEntity( ent )
	self.linked_entities = {}
	self.linked_entities[0] = ent:EntIndex()		-- [0] is used to store single links (e.g. manual links)
	ent:CallOnRemove("DDetector.UnLink", function(ent)
		if IsValid(self) and self.linked_entities and self.linked_entities[0] == ent then self:Unlink() end
	end)
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
				if IsValid(v) then
					table.insert(self.linked_entities, v:EntIndex())
				end
			end
		end
	elseif (iname == "Entity") then
		if value then
			self.linked_entities = {}
			if IsValid(value) then
				self.linked_entities[1] = value:EntIndex()
			end
		end
	elseif (iname == "Reset") then
		if value then
            self.count = 0
            self.firsthit_dmginfo = {}
            self.victims = table.Copy(DEFAULT)
		end
	end
end

function ENT:TriggerOutput()		-- Entity outputs won't trigger again until they change

	local attacker = self.firsthit_dmginfo[1]
	WireLib.TriggerOutput( self, "Attacker", IsValid(attacker) and attacker or NULL)

	local victim = self.firsthit_dmginfo[2]
	WireLib.TriggerOutput( self, "Victim", IsValid(victim) and victim or NULL)

	self.victims.size = table.Count(self.victims.s)
	WireLib.TriggerOutput( self, "Victims", self.victims or table.Copy(DEFAULT) )
	WireLib.TriggerOutput( self, "Position", self.firsthit_dmginfo[3] or Vector(0,0,0) )
	WireLib.TriggerOutput( self, "Force", self.firsthit_dmginfo[4] or Vector(0,0,0) )
	WireLib.TriggerOutput( self, "Type", self.firsthit_dmginfo[5] or "" )
	WireLib.TriggerOutput( self, "Damage", self.damage or 0 )

	WireLib.TriggerOutput( self, "Clk", self.count )
end

function ENT:UpdateLinkedEnts()		-- Check to see if prop is registered by the detector
	if !self.linked_entities then return nil end

	self.key_ents = {}

	if self.includeconstrained == 1 then		-- Don't update constrained entities unless we have to
		self:UpdateConstrainedEnts()
	end

	for _,v in pairs (self.linked_entities) do		-- include linked_entities
		if IsValid( ents.GetByIndex(v) ) then
			self.key_ents[v] = true
		end
	end
end

function ENT:UpdateConstrainedEnts()		-- Finds all entities constrained to linked_entities
	for _,v in pairs (self.linked_entities) do
		local ent = ents.GetByIndex(v)
		if IsValid(ent) and constraint.HasConstraints(ent) and !self.key_ents[v] then
			for _,w in pairs( constraint.GetAllConstrainedEntities(ent) ) do
				if IsValid(w) then
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
			ents.GetByIndex(entID),
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
			self.firsthit_dmginfo[2] = ents.GetByIndex(entID)
		end
	else
		self.damage = self.damage + damage
	end

	// Update victims table (ent, damage)
	self.victims.s[tostring(entID)] = ( self.victims[tostring(entID)] or 0 ) + damage
	self.victims.stypes[tostring(entID)] = "n"

	self.count = self.count + 1
	if self.count == math.huge then self.count = 0 end -- This shouldn't ever happen... unless you're really REALLY bored
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

function MakeWireDamageDetector( pl, Pos, Ang, model, includeconstrained )
	if !pl:CheckLimit( "wire_damage_detectors" ) then return false end

	local wire_damage_detector = ents.Create( "gmod_wire_damage_detector" )
	if !IsValid(wire_damage_detector) then return false end

	wire_damage_detector:SetAngles( Ang )
	wire_damage_detector:SetPos( Pos )
	wire_damage_detector:SetModel( model )
	wire_damage_detector:Spawn()

	wire_damage_detector:Setup( includeconstrained )
	wire_damage_detector:LinkEntity( wire_damage_detector )	-- Link the detector to itself by default

	wire_damage_detector:SetPlayer( pl )
	wire_damage_detector.pl = pl

	pl:AddCount( "wire_damage_detectors", wire_damage_detector )

	return wire_damage_detector
end
duplicator.RegisterEntityClass("gmod_wire_damage_detector", MakeWireDamageDetector, "Pos", "Ang", "Model", "includeconstrained")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid( ents.GetByIndex(self.linked_entities[0]) ) then
	    info.linked_entities = self.linked_entities[0]
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if IsValid( GetEntByID(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = GetEntByID(info.linked_entities):EntIndex()
	elseif IsValid( ents.GetByIndex(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = info.linked_entities
	end
	self:ShowOutput()
end
