/******************************************************************************\
  Constraint support V1.5
\******************************************************************************/

//---------------------------//
//--Helper Functions--//
//---------------------------//

-- caps("heLlO") == "Hello"
local function caps(text)
	local capstext = text:sub(1,1):upper() .. text:sub(2):lower()
	if capstext == "Nocollide" then return "NoCollide" end
	if capstext == "Advballsocket" then return "AdvBallsocket" end
	return capstext
end

-- Returns con.Ent1 or con.Ent2, whichever is not equivalent to ent. Optionally subscripts con with num beforehand.
local function ent1or2(ent,con,num)
	if not con then return nil end
	if num then
		con = con[num]
		if not con then return nil end
	end
	if con.Ent1==ent then return con.Ent2 end
	return con.Ent1
end

/******************************************************************************/


__e2setcost(20)

local function GetAllConstrainedEntities( ent, ResultTable )
	ResultTable[ ent ] = ent
	
	for _, con in pairs( ent.Constraints or {} ) do
		for i=1, 6 do
			local e = con["Ent"..i]
			if e  and not ResultTable[e] and e:IsValid() then
				GetAllConstrainedEntities(e, ResultTable)
			end
		end
	end

	return ResultTable
end
--- Returns an '''array''' containing all entities directly or indirectly constrained to <this>, except <this> itself.
e2function array entity:getConstraints()
	if not IsValid(this) then return {} end
	if not constraint.HasConstraints(this) then return {} end

	local keytable = GetAllConstrainedEntities(this, {})
	local array = {}
	local i = 1
	for _,ent in pairs(keytable) do
		if ent ~= this then
			array[i] = ent
			i = i + 1
		end
	end
	self.prf = self.prf + i * 30
	return array
end

__e2setcost(5)

--- Returns the number of constraints on <this>.
e2function number entity:hasConstraints()
	if not IsValid(this) then return 0 end

	return #constraint.GetTable(this)
end

--- Returns the number of constraints of type <constraintType> on <this>.
e2function number entity:hasConstraints(string constraintType)
	if not IsValid(this) then return 0 end

	local constype = caps(constraintType)
	local ConTable = constraint.GetTable(this)
	local count = 0
	for k, con in ipairs(ConTable) do
		if con.Type == constype then
			count = count + 1
		end
	end
	return count
end

--- Returns 1 if <this> is constrained to anything, 0 otherwise.
e2function number entity:isConstrained()
	if not IsValid(this) then return 0 end
	if not constraint.HasConstraints(this) then return 0 end

	return 1
end

--- Returns the first entity <this> was welded to.
e2function entity entity:isWeldedTo()
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.FindConstraint(this, "Weld"))
end

--- Returns the <index>th entity <this> was welded to.
e2function entity entity:isWeldedTo(index)
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.FindConstraints(this, "Weld"), math.floor(index))
end

--- Returns the first entity <this> was constrained to.
e2function entity entity:isConstrainedTo()
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.GetTable(this),1)
end

--- Returns the <index>th entity <this> was constrained to.
e2function entity entity:isConstrainedTo(index)
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.GetTable(this), math.floor(index))
end

--- Returns the first entity <this> was constrained to with the given constraint type <constraintType>.
e2function entity entity:isConstrainedTo(string constraintType)
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.FindConstraint(this, caps(constraintType)))
end

--- Returns the <index>th entity <this> was constrained to with the given constraint type <constraintType>.
e2function entity entity:isConstrainedTo(string constraintType, index)
	if not IsValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return ent1or2(this,constraint.FindConstraints(this, caps(constraintType)), math.floor(index))
end

--- Returns the '''entity''' <this> is parented to.
e2function entity entity:parent()
	if not IsValid(this) then return nil end
	return this:GetParent()
end

--- Returns the '''bone''' <this> is parented to.
e2function bone entity:parentBone()
	if not IsValid(this) then return nil end

	local ent = this:GetParent()
	if not IsValid(ent) then return nil end
	local bonenum = this:GetParentPhysNum()
	return getBone(ent, bonenum)
end

__e2setcost(20)

--- Returns an '''array''' containing all the children of the entity - that is, every entity whose parent is this entity.
e2function array entity:children()
	return IsValid(this) and this:GetChildren() or {}
end
