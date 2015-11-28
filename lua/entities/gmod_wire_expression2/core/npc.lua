/******************************************************************************\
  NPC control and such
\******************************************************************************/

E2Lib.RegisterExtension("npc", true, "Allows controlling of NPCs.", "NPCs can be given weapons and ordered to hate other players.")

__e2setcost(5) -- temporary

local function validNPC(entity)
	return IsValid(entity) && entity:IsNPC()
end

e2function void entity:npcGoWalk(vector rv2)
	if !validNPC(this) || !isOwner(self,this) then return end
	this:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	this:SetSchedule( SCHED_FORCED_GO )
end

e2function void entity:npcGoRun(vector rv2)
	if !validNPC(this) || !isOwner(self,this) then return end
	this:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	this:SetSchedule( SCHED_FORCED_GO_RUN )
end

e2function void entity:npcAttack()
	if !validNPC(this) || !isOwner(self,this) then return end
	this:SetSchedule( SCHED_MELEE_ATTACK1 )
end

e2function void entity:npcShoot()
	if !validNPC(this) || !isOwner(self,this) then return end
--	if !this:HasCondition( 6 ) then return end -- COND_NO_WEAPON. See http://maurits.tv/data/garrysmod/wiki/wiki.garrysmod.com/index4389.html
	this:SetSchedule( SCHED_RANGE_ATTACK1 )
end

e2function void entity:npcFace(vector rv2)
	if !validNPC(this) || !isOwner(self,this) then return end
	local Vec = Vector(rv2[1], rv2[2], rv2[3]) - self.entity:GetPos()
	local ang = Vec:Angle()
	this:SetAngles( Angle(0,ang.y,0) )
end

e2function void entity:npcGiveWeapon()
	if !validNPC(this) || !isOwner(self,this) then return end

	local weapon = this:GetActiveWeapon()
	if (weapon:IsValid()) then
		if (weapon:GetClass() == "weapon_smg1") then return end
		weapon:Remove()
	end

	this:Give( "ai_weapon_smg1" )
end

e2function void entity:npcGiveWeapon(string rv2)
	if !validNPC(this) || !isOwner(self,this) then return end

	local weapon = this:GetActiveWeapon()
	if (weapon:IsValid()) then
		if (weapon:GetClass() == "weapon_" .. rv2) then return end
		weapon:Remove()
	end

	this:Give( "ai_weapon_" .. rv2 )
end

e2function void entity:npcStop()
	if !validNPC(this) || !isOwner(self,this) then return end
	this:SetSchedule( SCHED_NONE )
end

e2function entity entity:npcGetTarget()
	if !validNPC(this) or !isOwner(self, this) then return end
	return this:GetEnemy()
end

e2function void entity:npcSetTarget(entity ent)
	if !(IsValid(ent) and (ent:IsNPC() or ent:IsPlayer())) or !validNPC(this) or !isOwner(self, this) then return end
	this:SetEnemy(ent)
end

//--Relationship functions--//

// Disposition: 0 - Error, 1 - hate, 2 - fear, 3 - like, 4 - neutral

local function NpcDisp(string)
	if(string == "hate") then return 1 end
	if(string == "fear") then return 2 end
	if(string == "like") then return 3 end
	if(string == "neutral") then return 4 end
	return 0
end

local function DispToString(number)
	if(number == 1) then return "hate" end
	if(number == 2) then return "fear" end
	if(number == 3) then return "like" end
	if(number == 4) then return "neutral" end
	return 0
end

local function NpcDispString(string)
	if(string == "hate") then return "D_HT" end
	if(string == "fear") then return "D_FR" end
	if(string == "like") then return "D_LI" end
	if(string == "neutral") then return "D_NU" end
	return "D_ER"
end

e2function void entity:npcRelationship(entity rv2, string rv3, rv4)
	if !validNPC(this) || !IsValid(rv2) || !isOwner(self,this) then return end
	local entity = this
	local target = rv2
	local disp = NpcDisp(rv3)
	local prior = rv4
	if disp == 0 then return end
	entity:AddEntityRelationship( target, disp, prior )
end

e2function void entity:npcRelationship(string rv2, string rv3, rv4)
	if !validNPC(this) || !isOwner(self,this) then return end
	local entity = this
	local target = rv2
	local disp = NpcDispString(rv3)
	local prior = math.floor( rv4 / 10 )
	local input = target.." "..disp.." "..tostring(prior)
	if disp == "D_ER" then return end
	entity:AddRelationship( input )
end

e2function number entity:npcRelationshipByOwner(entity rv2, string rv3, rv4)
	if !validNPC(this) || !IsValid(rv2) || !isOwner(self,this) then return 0 end
	local entity = this
	local owner = rv2
	local disp = NpcDisp(rv3)
	local prior = rv4
	if disp == 0 then return 0 end
	local Table = ents.FindByClass("npc_*")

	for i=1,#Table do
		if(isOwner(self, Table[i])) then entity:AddEntityRelationship( Table[i], disp, prior ) end
	end

	return #Table
end

e2function string entity:npcDisp(entity rv2)
	if !validNPC(this) || !IsValid(rv2) || !isOwner(self,this) then return "" end
	local entity = this
	local target = rv2
	local disp = entity:Disposition( target )
	if disp == 0 then return "" end
	return DispToString(disp)
end
