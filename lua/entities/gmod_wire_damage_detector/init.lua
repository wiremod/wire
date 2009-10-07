
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

ENT.WireDebugName = "Damage Detector"

local damage_detectors = {}

function ENT:Initialize()
	local self = self.Entity

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Damage", "Attacker", "Inflictor", "Victim" } , { "NORMAL", "ENTITY", "ENTITY", "ENTITY" } )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "On", "Entity", "Entities" }, { "NORMAL", "ENTITY", "ARRAY" } )

	self.on = 0
	self.updated = false

	self.firsthit_dmginfo = {}		-- Stores damage info representing damage during an interval
	self.output_dmginfo = {}		-- Stores the current damage info outputs
	self.damage = 0

	damage_detectors[self:EntIndex()] = true
end

/******************************
	How entities are stored:
	self.linked_entities	Array: Entities the detector is directly linked to. Contains entIDs as values
	self.key_ents		KeyTable: Entities to check damage on (including constrained ents), only updated when the damage hook is called,.Contains entIDs as table keys
******************************/

function ENT:OnRemove()
	damage_detectors[self.Entity:EntIndex()] = nil
	Wire_Remove(self.Entity)
end

function ENT:ShowOutput()
	if self.includeconstrained == 0 then
		self:SetOverlayText( "Damage Detector\n" ..
							 "(Individual Props)" )
	else
		self:SetOverlayText( "Damage Detector\n" ..
							 "(Constrained Props)" )
	end
end

function ENT:SetOverlayText(txt)
	self.Entity:SetNetworkedBeamString("GModOverlayText", txt)
end

function ENT:Setup( includeconstrained )
	self.includeconstrained = includeconstrained
	self:ShowOutput()
end

function ENT:LinkEntity( ent )
	self.linked_entities = {}
	self.linked_entities[0] = ent:EntIndex()		-- [0] is used to store single links (e.g. manual links)
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
			local attacker = self.firsthit_dmginfo[1]
			if ValidEntity(attacker) then
				if self.output_dmginfo[1] != attacker then
					self.output_dmginfo[1] = attacker
					Wire_TriggerOutput( self.Entity, "Attacker", attacker )
				end
			end

			local inflictor = self.firsthit_dmginfo[2]
			if ValidEntity(inflictor) then
				if self.output_dmginfo[2] != inflictor then
					self.output_dmginfo[2] = inflictor
					Wire_TriggerOutput( self.Entity, "Inflictor", inflictor )
				end
			end

			local victim = self.firsthit_dmginfo[3]
			if ValidEntity( ents.GetByIndex(victim) ) then
				if self.output_dmginfo[3] != victim then
					self.output_dmginfo[3] = victim
					Wire_TriggerOutput( self.Entity, "Victim", ents.GetByIndex(victim) )
				end
			end

			Wire_TriggerOutput( self.Entity, "Damage", self.damage )
			Wire_TriggerOutput( self.Entity, "Damage", 0 )		-- Set damage back to 0 after it's been dealt
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

function ENT:UpdateDamage( dmginfo, entID )
	if !self.updated then		-- Only register the first target's damage info
		self.firsthit_dmginfo = {
			dmginfo:GetAttacker(),
			dmginfo:GetInflictor(),
			entID
			}
	end

	local damage = dmginfo:GetDamage()

	if dmginfo:IsExplosionDamage() then		-- Explosives will affect the entity that receives the most damage
		if self.damage < damage then
			self.damage = damage
			self.firsthit_dmginfo[3] = entID
		end
	else
		self.damage = self.damage + damage
	end
end

function ENT:Think()
	self.updated = false
	if self.damage > 0 then
		self:TriggerOutput()
		self.damage = 0
	end
	return true
end

local function CheckWireDamageDetectors( ent, inflictor, attacker, amount, dmginfo )
	if amount > 0  then
		local entID = ent:EntIndex()
		for k,_ in pairs(damage_detectors) do
			local detector = ents.GetByIndex(k)
			if ValidEntity(detector) and detector.on then
				if !detector.updated then
					detector:UpdateLinkedEnts()
					detector:NextThink(CurTime()+0.001)		-- Update link info once per tick per detector at most
				end
				if detector.key_ents[entID] then
					detector:UpdateDamage( dmginfo, entID )
				end
				detector.updated = true
			end
		end
	end
end
hook.Add( "EntityTakeDamage", "CheckWireDamageDetectors", CheckWireDamageDetectors )

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

	if IsValid( GetEntByID(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = GetEntByID(info.linked_entities):EntIndex()
	elseif IsValid( ents.GetByIndex(info.linked_entities) ) then
		self.linked_entities = {}
		self.linked_entities[0] = info.linked_entities
	end
	self:ShowOutput()
end
