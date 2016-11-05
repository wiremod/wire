AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Damage Detector"
ENT.Author          = "Jimlad"
ENT.WireDebugName = "Damage Detector"

if CLIENT then return end -- No more client

local DEFAULT = {n={},ntypes={},s={},stypes={},size=0}

-- Global table to keep track of all detectors
local Wire_Damage_Detectors = {}

-- Damage detection function
local function CheckWireDamageDetectors( ent, inflictor, attacker, amount, dmginfo )
	if amount > 0 then
		for k,_ in pairs(Wire_Damage_Detectors) do
			local detector = k
			if IsValid(detector) then
				if detector.on then
					if not detector.updated then
						detector:UpdateLinkedEnts()
						detector.updated = true
						detector:NextThink(CurTime()) -- Update link info once per tick per detector at most
					end
					if detector.key_ents[ent] then
						detector:UpdateDamage( dmginfo, ent )
					end
				end
			else
				Wire_Damage_Detectors[k] = nil
			end
		end
	end
end
hook.Add("EntityTakeDamage", "CheckWireDamageDetectors", function( ent, dmginfo )
	if not next(Wire_Damage_Detectors) then return end
	local r, e = xpcall( CheckWireDamageDetectors, debug.traceback, ent, dmginfo:GetInflictor(), dmginfo:GetAttacker(), dmginfo:GetDamage(), dmginfo )
	if not r then print( "Wire damage detector error: " .. e ) end
end)


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Clk", "Damage", "Attacker", "Victim", "Victims", "Position", "Force", "Type" } , { "NORMAL", "NORMAL", "ENTITY", "ENTITY", "TABLE", "VECTOR", "VECTOR", "STRING" } )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "On", "Entity", "Entities", "Reset" }, { "NORMAL", "ENTITY", "ARRAY", "NORMAL" } )

	self.on = false
	self.updated = false -- Tracks whether constraints were updated that tick
	self.hit = false -- Tracks whether detector registered any damage that tick

	self.firsthit_dmginfo = {} -- Stores damage info representing damage during an interval
	
	self.linked_entities = {} -- numerical array
	self.linked_entities_lookup = {} -- lookup table indexed by entities
	
	self:LinkEnt( self )

	self.count = 0

	-- Store output damage info
	self.victims = table.Copy(DEFAULT)
	WireLib.TriggerOutput( self, "Victims", self.victims )
	self.damage = 0

	Wire_Damage_Detectors[self] = true
end

--[[*****************************
	How entities are stored:
	self.linked_entities_lookup: Table: Lookup table used for linking and unlinking
	self.linked_entities	Array: Entities the detector is directly linked to.
	self.key_ents		KeyTable: Entities to check damage on (including constrained ents), only updated when the damage hook is called,.Contains entities as table keys
*****************************]]

function ENT:OnRemove()
	Wire_Damage_Detectors[self] = nil
	Wire_Remove(self)
	self:ClearEntities()
end

-- Update overlay
function ENT:ShowOutput()
	local text
	if self.includeconstrained == 0 then
		text = "(Individual Props)\n"
	else
		text = "(Constrained Props)\n"
	end

	if #self.linked_entities == 0 then
		text = text .. "Not linked"
	else
		if #self.linked_entities == 1 and self.linked_entities[1] == self then
			text = text .. "Linked to self"
		else
			text = text .. "Linked to " .. #self.linked_entities .. " entities."
		end
	end
	
	self:SetOverlayText( text )

	self:SetOverlayText(text)
end

function ENT:Setup( includeconstrained )
	self.includeconstrained = includeconstrained
	self:ShowOutput()
end

function ENT:LinkEnt( ent )
	if self.linked_entities_lookup[ent] then return false end
	
	self.linked_entities_lookup[ent] = true
	self.linked_entities[#self.linked_entities+1] = ent
	ent:CallOnRemove( "DDetector.Unlink", function( ent )
		if IsValid( self ) then
			self:UnlinkEnt( ent )
		end
	end )
	
	self:ShowOutput()
	WireLib.SendMarks( self, self.linked_entities )
	return true
end

function ENT:UnlinkEnt( ent )
	if not self.linked_entities_lookup[ent] then return false end
	
	self.linked_entities_lookup[ent] = nil
	
	for i=1,#self.linked_entities do
		if self.linked_entities[i] == ent then
			table.remove( self.linked_entities, i )
			break
		end
	end
	
	ent:RemoveCallOnRemove( "DDetector.Unlink" )
	
	self:ShowOutput()
	WireLib.SendMarks( self, self.linked_entities )
	return true
end

function ENT:ClearEntities()
	for i=1, #self.linked_entities do
		if IsValid( self.linked_entities[i] ) then -- generally, all entities should be kept valid automatically by the CallOnRemove functions, but CallOnRemove isn't called for players apparently
			self.linked_entities[i]:RemoveCallOnRemove( "DDetector.Unlink" )
		end
	end
	
	self.linked_entities = {}
	self.linked_entities_lookup = {}
	
	self:ShowOutput()
	WireLib.SendMarks( self, self.linked_entities )
	return true
end

function ENT:TriggerInput( iname, value )
	if iname == "On" then
		self.on = value ~= 0
	elseif iname == "Entities" then -- Populate linked_entities from "Array"
		if value then
			self:ClearEntities()
			
			for _, v in pairs( value ) do
				if IsValid( v ) then
					self:LinkEnt( v )
				end
			end
		end
	elseif iname == "Entity" then
		if IsValid( value )then
			self:LinkEnt( value )
		end
	elseif iname == "Reset" then
		if value then
			self.count = 0
			self.firsthit_dmginfo = {}
			self.victims = table.Copy(DEFAULT)
			self.damage = 0
			self:TriggerOutput()
		end
	end
end

function ENT:TriggerOutput() -- Entity outputs won't trigger again until they change
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
	if #self.linked_entities == 0 then return end

	self.key_ents = {}

	for i=1, #self.linked_entities do -- include linked_entities
		local ent = self.linked_entities[i]
		if IsValid( ent ) then
			if self.includeconstrained == 1 then -- Don't update constrained entities unless we have to
				self:UpdateConstrainedEnts( ent )
			end
			
			self.key_ents[ent] = true
		else
			self.linked_entities[ent] = nil
		end
	end
end

function ENT:UpdateConstrainedEnts( ent ) -- Finds all entities constrained to 'ent'
	local ents = constraint.GetAllConstrainedEntities( ent )
	
	for _,v in pairs( ents ) do
		self.key_ents[v] = true
	end
end

function ENT:UpdateDamage( dmginfo, ent ) -- Update damage table
	local damage = dmginfo:GetDamage()

	if !self.hit then -- Only register the first target's damage info
		self.firsthit_dmginfo = {
			dmginfo:GetAttacker(),
			ent,
			dmginfo:GetDamagePosition(),
			dmginfo:GetDamageForce()
		}

		-- Damage type (handle common types)
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
			self.firsthit_dmginfo[2] = ent
		end
	else
		self.damage = self.damage + damage
	end

	-- Update victims table (ent, damage)
	local entID = tostring(ent:EntIndex())
	self.victims.s[entID] = ( self.victims[entID] or 0 ) + damage
	self.victims.stypes[entID] = "n"

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

duplicator.RegisterEntityClass("gmod_wire_damage_detector", WireLib.MakeWireEnt, "Data", "includeconstrained")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	
	if #self.linked_entities > 0 then
		info.linked_entities = {}
		
		for i=1,#self.linked_entities do
			if IsValid( self.linked_entities[i] ) then
				info.linked_entities[i] = self.linked_entities[i]:EntIndex()
			else
				self.linked_entities[i] = nil
			end
		end
	end
	
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	
	if info.linked_entities then
		if type( info.linked_entities ) == "number" then -- old dupe compatibility
			self:LinkEnt( GetEntByID( info.linked_entities ) )
		else
			for i=1,#info.linked_entities do
				self:LinkEnt( GetEntByID( info.linked_entities[i] ) )
			end
		end
	end
	
	self:ShowOutput()
	-- wait a while after dupe before sending marks, because the entity doesn't exist clientside yet
	timer.Simple( 0.1, function() if IsValid( self ) then WireLib.SendMarks( self, self.linked_entities ) end end )
end
