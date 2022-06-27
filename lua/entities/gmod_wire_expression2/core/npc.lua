/******************************************************************************\
  NPC control and such
\******************************************************************************/

E2Lib.RegisterExtension("npc", true, "Allows controlling of NPCs.", "NPCs can be given weapons and ordered to hate other players.")

__e2setcost(5) -- temporary

local function validNPC(entity)
	return IsValid(entity) and entity:IsNPC()
end

e2function void entity:npcGoWalk(vector rv2)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	this:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	this:SetSchedule( SCHED_FORCED_GO )
end

e2function void entity:npcGoRun(vector rv2)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	this:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	this:SetSchedule( SCHED_FORCED_GO_RUN )
end

e2function void entity:npcAttack()
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	this:SetSchedule( SCHED_MELEE_ATTACK1 )
end

e2function void entity:npcShoot()
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

--	if !this:HasCondition( 6 ) then return end -- COND_NO_WEAPON. See http://maurits.tv/data/garrysmod/wiki/wiki.garrysmod.com/index4389.html
	this:SetSchedule( SCHED_RANGE_ATTACK1 )
end

e2function void entity:npcFace(vector rv2)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	local Vec = Vector(rv2[1], rv2[2], rv2[3]) - self.entity:GetPos()
	local ang = Vec:Angle()
	this:SetAngles( Angle(0, ang.y ,0) )
end

e2function void entity:npcGiveWeapon()
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	local weapon = this:GetActiveWeapon()
	if weapon:IsValid() then
		if weapon:GetClass() == "weapon_smg1" then return end
		weapon:Remove()
	end

	this:Give( "ai_weapon_smg1" )
end

e2function void entity:npcGiveWeapon(string rv2)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end

	local weapon = this:GetActiveWeapon()
	if weapon:IsValid() then
		if weapon:GetClass() == ("weapon_" .. rv2) then return end
		weapon:Remove()
	end

	this:Give( "ai_weapon_" .. rv2 )
end

e2function void entity:npcStop()
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end
	this:SetSchedule( SCHED_NONE )
end

e2function entity entity:npcGetTarget()
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", nil) end
	return this:GetEnemy()
end

e2function void entity:npcSetTarget(entity ent)
	if !(IsValid(ent) and (ent:IsNPC() or ent:IsPlayer())) or !validNPC(this) or !isOwner(self, this) then return end
	this:SetEnemy(ent)
end

--- Relationship functions ---
-- Disposition: 0 - Error, 1 - hate, 2 - fear, 3 - like, 4 - neutral
-- Error: 0 or D_ER

local NPC_DISP_STR = setmetatable({
	["hate"] = "D_HT",
	["fear"] = "D_FR",
	["like"] = "D_LI",
	["neutral"] = "D_NU"
}, { __index = function() return "D_ER" end })

local NPC_DISP_NUM = setmetatable({
	["hate"] = 1,
	["fear"] = 2,
	["like"] = 3,
	["neutral"] = 4,

	[1] = "hate",
	[2] = "fear",
	[3] = "like",
	[4] = "neutral"
}, {__index = function() return 0 end})

e2function void entity:npcRelationship(entity rv2, string rv3, rv4)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", 0) end
	if not IsValid(rv2) then return self:throw("Invalid entity (arg 1)!", 0) end

	local target = rv2
	local disp = NPC_DISP_NUM[rv3]
	local prior = rv4
	if disp == 0 then return end
	this:AddEntityRelationship( target, disp, prior )
end

e2function void entity:npcRelationship(string rv2, string rv3, rv4)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!") end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!") end

	local target = rv2
	local disp = NPC_DISP_STR[rv3]
	local prior = math.floor( rv4 / 10 )
	local input = string.format("%s %s %s", target, disp, prior)
	if disp == "D_ER" then return end
	this:AddRelationship( input )
end

e2function number entity:npcRelationshipByOwner(entity rv2, string rv3, rv4)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", 0) end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", 0) end
	if not IsValid(rv2) then return self:throw("Invalid entity!", 0) end

	local owner = rv2
	local disp = NPC_DISP_NUM[rv3]
	local prior = rv4
	if disp == 0 then return 0 end
	local npc_tbl = ents.FindByClass("npc_*")

	for _, v in ipairs(npc_tbl) do
		if isOwner(self, v) then
			this:AddEntityRelationship( v, disp, prior )
		end
	end

	return #npc_tbl
end

e2function string entity:npcDisp(entity rv2)
	if not validNPC(this) then return self:throw("Entity e: is not a valid NPC!", "") end
	if not isOwner(self, this) then return self:throw("You do not own this NPC!", "") end
	if not IsValid(rv2) then return self:throw("Invalid entity!", "") end

	local target = rv2
	local disp = this:Disposition( target )
	if disp == 0 then return "" end
	return NPC_DISP_NUM[disp]
end
