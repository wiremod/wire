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
--Schedule Functions--

local function strToSch(str)
	local str2 = string.upper(str)
	local SCH = {}
	SCH["SCHED_NONE"] = SCHED_NONE
	SCH["SCHED_IDLE_STAND"] = SCHED_IDLE_STAND
	SCH["SCHED_IDLE_WALK"] = SCHED_IDLE_WALK
	SCH["SCHED_IDLE_WANDER"] = SCHED_IDLE_WANDER
	SCH["SCHED_WAKE_ANGRY"] = SCHED_WAKE_ANGRY
	SCH["SCHED_ALERT_FACE"] = SCHED_ALERT_FACE
	SCH["SCHED_ALERT_FACE_BESTSOUND"] = SCHED_ALERT_FACE_BESTSOUND
	SCH["SCHED_ALERT_REACT_TO_COMBAT_SOUND"] = SCHED_ALERT_REACT_TO_COMBAT_SOUND
	SCH["SCHED_ALERT_SCAN"] = SCHED_ALERT_SCAN
	SCH["SCHED_ALERT_STAND"] = SCHED_ALERT_STAND
	SCH["SCHED_ALERT_WALK"] = SCHED_ALERT_WALK
	SCH["SCHED_INVESTIGATE_SOUND"] = SCHED_INVESTIGATE_SOUND
	SCH["SCHED_COMBAT_FACE"] = SCHED_COMBAT_FACE
	SCH["SCHED_COMBAT_SWEEP"] = SCHED_COMBAT_SWEEP
	SCH["SCHED_FEAR_FACE"] = SCHED_FEAR_FACE
	SCH["SCHED_COMBAT_STAND"] = SCHED_COMBAT_STAND
	SCH["SCHED_COMBAT_WALK"] = SCHED_COMBAT_WALK
	SCH["SCHED_CHASE_ENEMY"] = SCHED_CHASE_ENEMY
	SCH["SCHED_CHASE_ENEMY_FAILED"] = SCHED_CHASE_ENEMY_FAILED
	SCH["SCHED_VICTORY_DANCE"] = SCHED_VICTORY_DANCE
	SCH["SCHED_TARGET_FACE"] = SCHED_TARGET_FACE
	SCH["SCHED_TARGET_CHASE"] = SCHED_TARGET_CHASE
	SCH["SCHED_SMALL_FLINCH"] = SCHED_SMALL_FLINCH
	SCH["SCHED_BIG_FLINCH"] = SCHED_BIG_FLINCH
	SCH["SCHED_BACK_AWAY_FROM_ENEMY"] = SCHED_BACK_AWAY_FROM_ENEMY
	SCH["SCHED_MOVE_AWAY_FROM_ENEMY"] = SCHED_MOVE_AWAY_FROM_ENEMY
	SCH["SCHED_BACK_AWAY_FROM_SAVE_POSITION"] = SCHED_BACK_AWAY_FROM_SAVE_POSITION
	SCH["SCHED_TAKE_COVER_FROM_ENEMY"] = SCHED_TAKE_COVER_FROM_ENEMY
	SCH["SCHED_TAKE_COVER_FROM_BEST_SOUND"] = SCHED_TAKE_COVER_FROM_BEST_SOUND
	SCH["SCHED_FLEE_FROM_BEST_SOUND"] = SCHED_FLEE_FROM_BEST_SOUND
	SCH["SCHED_TAKE_COVER_FROM_ORIGIN"] = SCHED_TAKE_COVER_FROM_ORIGIN
	SCH["SCHED_FAIL_TAKE_COVER"] = SCHED_FAIL_TAKE_COVER
	SCH["SCHED_RUN_FROM_ENEMY"] = SCHED_RUN_FROM_ENEMY
	SCH["SCHED_RUN_FROM_ENEMY_FALLBACK"] = SCHED_RUN_FROM_ENEMY_FALLBACK
	SCH["SCHED_MOVE_TO_WEAPON_RANGE"] = SCHED_MOVE_TO_WEAPON_RANGE
	SCH["SCHED_ESTABLISH_LINE_OF_FIRE"] = SCHED_ESTABLISH_LINE_OF_FIRE
	SCH["SCHED_ESTABLISH_LINE_OF_FIRE_FALLBACK"] = SCHED_ESTABLISH_LINE_OF_FIRE_FALLBACK
	SCH["SCHED_PRE_FAIL_ESTABLISH_LINE_OF_FIRE"] = SCHED_PRE_FAIL_ESTABLISH_LINE_OF_FIRE
	SCH["SCHED_FAIL_ESTABLISH_LINE_OF_FIRE"] = SCHED_FAIL_ESTABLISH_LINE_OF_FIRE
	SCH["SCHED_SHOOT_ENEMY_COVER"] = SCHED_SHOOT_ENEMY_COVER
	SCH["SCHED_COWER"] = SCHED_COWER
	SCH["SCHED_MELEE_ATTACK1"] = SCHED_MELEE_ATTACK1
	SCH["SCHED_MELEE_ATTACK2"] = SCHED_MELEE_ATTACK2
	SCH["SCHED_RANGE_ATTACK1"] = SCHED_RANGE_ATTACK1
	SCH["SCHED_RANGE_ATTACK2"] = SCHED_RANGE_ATTACK2
	SCH["SCHED_SPECIAL_ATTACK1"] = SCHED_SPECIAL_ATTACK1
	SCH["SCHED_SPECIAL_ATTACK2"] = SCHED_SPECIAL_ATTACK2
	SCH["SCHED_STANDOFF"] = SCHED_STANDOFF
	SCH["SCHED_ARM_WEAPON"] = SCHED_ARM_WEAPON
	SCH["SCHED_DISARM_WEAPON"] = SCHED_DISARM_WEAPON
	SCH["SCHED_HIDE_AND_RELOAD"] = SCHED_HIDE_AND_RELOAD
	SCH["SCHED_RELOAD"] = SCHED_RELOAD
	SCH["SCHED_AMBUSH"] = SCHED_AMBUSH
	SCH["SCHED_DIE"] = SCHED_DIE
	SCH["SCHED_DIE_RAGDOLL"] = SCHED_DIE_RAGDOLL
	SCH["SCHED_WAIT_FOR_SCRIPT"] = SCHED_WAIT_FOR_SCRIPT
	SCH["SCHED_AISCRIPT"] = SCHED_AISCRIPT
	SCH["SCHED_SCRIPTED_WALK"] = SCHED_SCRIPTED_WALK
	SCH["SCHED_SCRIPTED_RUN"] = SCHED_SCRIPTED_RUN
	SCH["SCHED_SCRIPTED_CUSTOM_MOVE"] = SCHED_SCRIPTED_CUSTOM_MOVE
	SCH["SCHED_SCRIPTED_WAIT"] = SCHED_SCRIPTED_WAIT
	SCH["SCHED_SCRIPTED_FACE"] = SCHED_SCRIPTED_FACE
	SCH["SCHED_SCENE_GENERIC"] = SCHED_SCENE_GENERIC
	SCH["SCHED_NEW_WEAPON"] = SCHED_NEW_WEAPON
	SCH["SCHED_NEW_WEAPON_CHEAT"] = SCHED_NEW_WEAPON_CHEAT
	SCH["SCHED_SWITCH_TO_PENDING_WEAPON"] = SCHED_SWITCH_TO_PENDING_WEAPON
	SCH["SCHED_GET_HEALTHKIT"] = SCHED_GET_HEALTHKIT
	SCH["SCHED_WAIT_FOR_SPEAK_FINISH"] = SCHED_WAIT_FOR_SPEAK_FINISH
	SCH["SCHED_MOVE_AWAY"] = SCHED_MOVE_AWAY
	SCH["SCHED_MOVE_AWAY_FAIL"] = SCHED_MOVE_AWAY_FAIL
	SCH["SCHED_MOVE_AWAY_END"] = SCHED_MOVE_AWAY_END
	SCH["SCHED_FORCED_GO"] = SCHED_FORCED_GO
	SCH["SCHED_FORCED_GO_RUN"] = SCHED_FORCED_GO_RUN
	SCH["SCHED_NPC_FREEZE"] = SCHED_NPC_FREEZE
	SCH["SCHED_PATROL_WALK"] = SCHED_PATROL_WALK
	SCH["SCHED_COMBAT_PATROL"] = SCHED_COMBAT_PATROL
	SCH["SCHED_PATROL_RUN"] = SCHED_PATROL_RUN
	SCH["SCHED_RUN_RANDOM"] = SCHED_RUN_RANDOM
	SCH["SCHED_FALL_TO_GROUND"] = SCHED_FALL_TO_GROUND
	SCH["SCHED_DROPSHIP_DUSTOFF"] = SCHED_DROPSHIP_DUSTOFF
	SCH["SCHED_FLINCH_PHYSICS"] = SCHED_FLINCH_PHYSICS
	SCH["SCHED_FAIL"] = SCHED_FAIL
	SCH["SCHED_FAIL_NOSTOP"] = SCHED_FAIL_NOSTOP
	SCH["SCHED_RUN_FROM_ENEMY_MOB"] = SCHED_RUN_FROM_ENEMY_MOB
	SCH["SCHED_DUCK_DODGE"] = SCHED_DUCK_DODGE
	SCH["SCHED_INTERACTION_MOVE_TO_PARTNER"] = SCHED_INTERACTION_MOVE_TO_PARTNER
	SCH["SCHED_INTERACTION_WAIT_FOR_PARTNER"] = SCHED_INTERACTION_WAIT_FOR_PARTNER
	SCH["SCHED_SLEEP"] = SCHED_SLEEP
	return SCH[str2]

end

local function strToState(st)
	local st2 = string.upper(st)
	local STS = {}
	STS["NPC_STATE_NONE"] = NPC_STATE_NONE
	STS["NPC_STATE_IDLE"] = NPC_STATE_IDLE
	STS["NPC_STATE_DEAD"] = NPC_STATE_DEAD
	STS["NPC_STATE_COMBAT"] = NPC_STATE_COMBAT
	STS["NPC_STATE_ALERT"] = NPC_STATE_ALERT
	STS["NPC_STATE_SCRIPT"] = NPC_STATE_SCRIPT
	STS["NPC_STATE_PRONE"] = NPC_STATE_PRONE
	STS["NPC_STATE_INVALID"] = NPC_STATE_INVALID
	STS["NPC_STATE_PLAYDEAD"] = NPC_STATE_PLAYDEAD
	return STS[str2]
end

local function stateToStr(st)
	local st2 = string.upper(st)
	local STS = {}
	STS[NPC_STATE_NONE] = "NPC_STATE_NONE"
	STS[NPC_STATE_IDLE] = "NPC_STATE_IDLE"
	STS[NPC_STATE_DEAD] = "NPC_STATE_DEAD"
	STS[NPC_STATE_COMBAT] = "NPC_STATE_COMBAT"
	STS[NPC_STATE_ALERT] = "NPC_STATE_ALERT"
	STS[NPC_STATE_SCRIPT] = "NPC_STATE_SCRIPT"
	STS[NPC_STATE_PRONE] = "NPC_STATE_PRONE"
	STS[NPC_STATE_INVALID] = "NPC_STATE_INVALID"
	STS[NPC_STATE_PLAYDEAD] = "NPC_STATE_PLAYDEAD"
	return STS[str2]
end

e2function void entity:setSchedule(string schedule)
	if not IsValid(this) and this:IsNPC() then return end
	if not strToSch(schedule)>=0 or not strToSch(schedule)<88 then return end
	this:SetSchedule(strToSch(schedule))
end

e2function void entity:setState(string state)
	if not IsValid(this) and this:IsNPC() then return end
	if not strToSch(schedule)>=-1 or not strToSch(schedule)<=7 then return end
	this:SetNPCState(strToState(state))
end

e2function string entity:getState()
	if not IsValid(this) and this:IsNPC() then return end
	if not strToSch(schedule)>=-1 or not strToSch(schedule)<=7 then return end
	return stateToStr(this:GetNPCState())
end

e2function number entity:hasSchedule(string schedule)
	if not IsValid(this) and this:IsNPC() then return 0 end
	if not strToSch(schedule)>=0 or not strToSch(schedule)<88 then return 0 end
	if this:IsCurrentSchedule(strToSch(schedule)) then return 1 else return 0 end
end
