/******************************************************************************\
  NPC control and such
\******************************************************************************/

__e2setcost(5) -- temporary

function validNPC(entity)
	return validEntity(entity) && entity:IsNPC()
end

registerFunction("npcGoWalk", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	rv1:SetSchedule( SCHED_FORCED_GO )
end)

registerFunction("npcGoRun", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:SetLastPosition( Vector(rv2[1], rv2[2], rv2[3]) )
	rv1:SetSchedule( SCHED_FORCED_GO_RUN )
end)

registerFunction("npcAttack", "e:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:SetSchedule( SCHED_MELEE_ATTACK1 )
end)

registerFunction("npcShoot", "e:", "", function(self,args)
	local op1= args[2]
	local rv1 = op1[1](self,op1)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	if !rv1:HasCondition( COND_NO_WEAPON ) then return end
	rv1:SetSchedule( SCHED_RANGE_ATTACK1 )
end)

registerFunction("npcFace", "e:v", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	local Vec = Vector(rv2[1], rv2[2], rv2[3]) - self.entity:GetPos()
	local ang = Vec:Angle()
	rv1:SetAngles( Angle(0,ang.y,0) )
end)

registerFunction("npcGiveWeapon", "e:", "", function(self,args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:Give( "ai_weapon_smg1" )
end)

registerFunction("npcGiveWeapon", "e:s", "", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:Give( "ai_weapon_" .. rv2 )
end)

registerFunction("npcStop", "e:", "", function(self,args)
	local op1= args[2]
	local rv1 = op1[1](self,op1)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	rv1:SetSchedule( SCHED_NONE )
end)




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

registerFunction("npcRelationship", "e:esn", "", function(self,args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	if !validNPC(rv1) || !validEntity(rv2) || !isOwner(self,rv1) then return end
	local entity = rv1
	local target = rv2
	local disp = NpcDisp(rv3)
	local prior = rv4
	if disp == 0 then return end
	entity:AddEntityRelationship( target, disp, prior )
end)

registerFunction("npcRelationship", "e:ssn", "", function(self,args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	if !validNPC(rv1) || !isOwner(self,rv1) then return end
	local entity = rv1
	local target = rv2
	local disp = NpcDispString(rv3)
	local prior = math.floor( rv4 / 10 )
	local input = target.." "..disp.." "..tostring(prior)
	if disp == "D_ER" then return end
	entity:AddRelationship( input )
end)

registerFunction("npcRelationshipByOwner", "e:esn", "n", function(self,args)
	local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
	local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	if !validNPC(rv1) || !validEntity(rv2) || !isOwner(self,rv1) then return 0 end
	local entity = rv1
	local owner = rv2
	local disp = NpcDisp(rv3)
	local prior = rv4
	if disp == 0 then return 0 end
	local Table = ents.FindByClass("npc_*")
	if(table.Count(Table)==0) then return 0 end

	for i=1,table.Count(Table) do
		if(isOwner(self, Table[i])) then entity:AddEntityRelationship( Table[i], disp, prior ) end
	end

	return table.Count(Table)
end)

registerFunction("npcDisp", "e:e", "s", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !validNPC(rv1) || !validEntity(rv2) || !isOwner(self,rv1) then return "" end
	local entity = rv1
	local target = rv2
	local disp = entity:Disposition( target )
	if disp == 0 then return "" end
	return DispToString(disp)
end)

__e2setcost(nil) -- temporary
