E2Lib.RegisterExtension("constraintcore", false, "Allows the creation and manipulation of constraints between entities.")

local IsValid = IsValid
local isValidBone = E2Lib.isValidBone
local getBone = E2Lib.getBone
local math_min = math.min
local math_max = math.max
local table_insert = table.insert

local cvFlags = {FCVAR_ARCHIVE}
local maxWeld = CreateConVar( "wire_expression2_max_constraints_weld", "0", cvFlags, nil, 0)
local maxRope = CreateConVar( "wire_expression2_max_constraints_rope", "0", cvFlags, nil, 0)
local maxAxis = CreateConVar( "wire_expression2_max_constraints_axis", "0", cvFlags, nil, 0)
local maxTotal = CreateConVar( "wire_expression2_max_constraints_total", "0", cvFlags, nil, 0)
local maxSlider = CreateConVar( "wire_expression2_max_constraints_slider", "0", cvFlags, nil, 0)
local maxElastic = CreateConVar( "wire_expression2_max_constraints_elastic", "0", cvFlags, nil, 0)
local maxNocollide = CreateConVar( "wire_expression2_max_constraints_nocollide", "0", cvFlags, nil, 0)
local maxHydraulic = CreateConVar( "wire_expression2_max_constraints_hydraulic", "0", cvFlags, nil, 0)
local maxPerEntity = CreateConVar( "wire_expression2_max_consttraints_per_entity", "0", cvFlags, nil, 0)
local maxBallsocket = CreateConVar( "wire_expression2_max_constraints_ballsocket", "0", cvFlags, nil, 0)
local maxAdvBallsocket = CreateConVar( "wire_expression2_max_constraints_ballsocket_adv", "0", cvFlags, nil, 0)

local edictCutOff = CreateConVar( "wire_expression2_constraints_edict_cutoff", "0", cvFlags, "At what edict count will E2s be prevented from creating new rope-like constraints (0 turns the check off)", 0, 8192 )
local shouldCleanup = CreateConVar( "Wire_expression2_constraints_cleanup", "0", cvFlags, "Whether or not Constraint Core should remove all constraints made by an E2 when it's deleted", 0, 1 )

local playerCounts = WireLib.RegisterPlayerTable()

-- Returns the table being used to keep track of counts
local function getCountHolder(self)
	local ply = self.player
	return IsValid( ply ) and playerCounts[ply] or self.data
end

local function clearCreatedConstraints(self)
	if not shouldCleanup:GetBool() then return end

	local data = getCountHolder( self )
	for _, constraint in ipairs( data.allConstraints ) do
		if constraint:IsValid() then
			constraint:Remove()
		end
	end

	data.allConstraints = {}
end

local function setupCounts(holder)
	holder.allConstraints = holder.allConstraints or {}
	holder.constraintCounts = holder.constraintCounts or {}
	holder.entityConstraints = holder.entityConstraints or {}
	holder.totalConstraints = holder.totalConstraints or 0
end

registerCallback("construct", function(self)
	-- Set up counts on both the E2 and the player in case the player is, or becomes invalid
	setupCounts( self.data )

	local ply = self.player
	if IsValid( ply ) then
		playerCounts[ply] = playerCounts[ply] or {}
		setupCounts( playerCounts[ply] )
	end

	self.data.constraintUndos = true
end)


registerCallback("destruct", function(self)
	clearCreatedConstraints(self)
end)

__e2setcost(1)
e2function void enableConstraintUndo(state)
	self.data.constraintUndos = state ~= 0
end

local countLookup = {
	Weld = maxWeld,
	Rope = maxRope,
	Axis = maxAxis,
	Slider = maxSlider,
	Elastic = maxElastic,
	NoCollide = maxNocollide,
	Hydraulic = maxHydraulic,
	Ballsocket = maxBallsocket,
	AdvBallsocket = maxAdvBallsocket,
}


local function checkEnts(self, ent1, ent2)
	if not ent1 or not ent2 then return self:throw("Invalid entity!", false) end

	if not ent1:IsWorld() then
		if not ent1:IsValid() then return self:throw("Invalid entity!", false) end
		if not isOwner(self, ent1) then return self:throw("You are not the owner of the entity!", false) end
	end

	if not ent2:IsWorld() then
		if not ent2:IsValid() then return self:throw("Invalid target entity!", false) end
		if not isOwner(self, ent2) then return self:throw("You are not the owner of the target entity!", false) end
	end

	if ent1:IsPlayer() or ent2:IsPlayer() then return self:throw("Cannot constrain players!", false) end
	return true
end

local function verifyConstraint(self, cons)
	if cons ~= false then return true end
	self:throw( "Constraint creation failed!", false )
end

local function setupEntConstraints(ent)
	local entData = ent.E2Data

	if not entData then
		local Ropes = {}
		ent.E2Data = {Ropes = Ropes}

		return Ropes
	end

	local entRopes = entData.Ropes
	if entRopes then return entRopes end

	local Ropes = {}
	entData.Ropes = Ropes

	return Ropes
end

local function checkCount(self, consType, ent1, ent2)
	local data = getCountHolder( self )
	local typeCounts = data.constraintCounts

	-- Total
	local totalLimit = maxTotal:GetInt()
	if totalLimit > 0 then
		local totalCount = data.totalConstraints
		if totalCount >= totalLimit then
			return self:throw( "Total constraint limit reached!", false )
		end
	end

	-- Type
	local typeLimit = countLookup[consType]:GetInt()
	if typeLimit > 0 then
		local typeCount = typeCounts[consType] or 0
		if typeCount >= typeLimit then
			return self:throw( consType .. " limit reached!", false )
		end
	end

	-- Ents
	local entityLimit = maxPerEntity:GetInt()
	if entityLimit > 0 then
		local entCounts = data.entityConstraints

		local ent1Count = entCounts[ent1] or 0
		local ent2Count = entCounts[ent2] or 0
		if math_max( ent1Count, ent2Count ) >= entityLimit then
			return self:throw( "Entity limit reached!", false )
		end
	end

	return true
end

local function checkEdicts(self)
	local maxEdicts = edictCutOff:GetInt()
	if maxEdicts == 0 then return true end

	if ents.GetEdictCount() >= maxEdicts then
		return self:throw( "Global edict limit reached!", false )
	end

	return true
end

local function addUndo(self, consType, cons, rope)
	local data = self.data
	local ply = self.player
	local cleanupType = rope and "ropeconstraints" or "constraints"

	ply:AddCleanup( cleanupType, cons )
	if rope then ply:AddCleanup( cleanupType, rope ) end

	if not data.constraintUndos then return end

	undo.Create( "e2_" .. consType )
		undo.SetPlayer( ply )
		undo.AddEntity( cons )
		if rope then undo.AddEntity( rope ) end
	undo.Finish()
end

local function increment(self, consType, ent1, ent2, cons)
	local data = getCountHolder( self )
	local entCounts = data.entityConstraints
	local typeCounts = data.constraintCounts
	local totalCount = data.totalConstraints

	-- Total
	data.totalConstraints = totalCount + 1

	-- Type
	typeCounts[consType] = ( typeCounts[consType] or 0 ) + 1

	-- Ents
	entCounts[ent1] = ( entCounts[ent1] or 0 ) + 1
	entCounts[ent2] = ( entCounts[ent2] or 0 ) + 1

	-- Decrement relevant counts
	cons:CallOnRemove( "wire_expression2_constraints_" .. self.uid, function()
		if not IsValid( self.entity ) then return end

		-- Total
		data.totalConstraints = math_max( 0, data.totalConstraints - 1 )

		-- Type
		typeCounts[consType] = math_max( 0, typeCounts[consType] - 1 )

		-- Ents
		entCounts[cons.Ent1] = math_max( 0, entCounts[cons.Ent1] - 1 )
		entCounts[cons.Ent2] = math_max( 0, entCounts[cons.Ent2] - 1 )
	end )
end

local function postCreate(self, consType, ent1, ent2, cons, rope)
	addUndo( self, consType, cons, rope )
	increment( self, consType, ent1, ent2, cons )

	-- Don't bother tracking the constraints if we won't clean them up
	if not shouldCleanup:GetBool() then return end

	local data = getCountHolder( self )
	table_insert( data.allConstraints, cons )
end

local function caps(text)
	if text == "nocollide" then return "NoCollide" end
	if text == "advballsocket" then return "AdvBallsocket" end
	return text:sub(1,1):upper() .. text:sub(2):lower()
end

-- All vectors are LOCAL positions relative to their corresponding entities
__e2setcost(30)


-- == Axis ==

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "Axis", ent1, ent2) then return end

	local cons = constraint.Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, 0, 0)
	postCreate(self, "Axis", ent1, ent2, cons)
end

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2, friction)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "Axis", ent1, ent2) then return end

	local cons = constraint.Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, friction, 0)
	postCreate(self, "Axis", ent1, ent2, cons)
end

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction and <localaxis> rotation axis.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2, friction, vector localaxis)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "Axis", ent1, ent2) then return end

	local cons = constraint.Axis(ent1, ent2, 0, 0, v1, v2, 0, 0, friction, 0, localaxis)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "Axis", ent1, ent2, cons)
end


-- == Ball Socket ==

--- Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>
e2function void ballsocket(entity ent1, vector v, entity ent2)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "Ballsocket", ent1, ent2) then return end

	local cons = constraint.Ballsocket(ent1, ent2, 0, 0, v, 0, 0, 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "Ballsocket", ent1, ent2, cons)
end

--- Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with friction <friction>
e2function void ballsocket(entity ent1, vector v, entity ent2, friction)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "AdvBallsocket", ent1, ent2) then return end

	local cons = constraint.AdvBallsocket(ent1, ent2, 0, 0, v, vector_origin, 0, 0, -180, -180, -180, 180, 180, 180, friction, friction, friction, 0, 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "AdvBallsocket", ent1, ent2, cons)
end

--- Creates an adv ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with many settings
e2function void ballsocket(entity ent1, vector v, entity ent2, vector mins, vector maxs, vector frictions)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "AdvBallsocket", ent1, ent2) then return end

	local cons = constraint.AdvBallsocket(ent1, ent2, 0, 0, v, vector_origin, 0, 0, mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3], frictions[1], frictions[2], frictions[3], 0, 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "AdvBallsocket", ent1, ent2, cons)
end

--- Creates an adv ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with many settings
e2function void ballsocket(entity ent1, vector v, entity ent2, vector mins, vector maxs, vector frictions, rotateonly)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "AdvBallsocket", ent1, ent2) then return end

	local cons = constraint.AdvBallsocket(ent1, ent2, 0, 0, v, vector_origin, 0, 0, mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3], frictions[1], frictions[2], frictions[3], rotateonly, 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "AdvBallsocket", ent1, ent2, cons)
end

--- Creates an angular weld (angles are fixed, position isn't) between <ent1> and <ent2> at <v>, which is local to <ent1>
e2function void weldAng(entity ent1, vector v, entity ent2)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "AdvBallsocket", ent1, ent2) then return end

	local cons = constraint.AdvBallsocket(ent1, ent2, 0, 0, v, vector_origin, 0, 0, 0, -0, 0, 0, 0, 0, 0, 0, 0, 1, 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "AdvBallsocket", ent1, ent2, cons)
end


local function CalcElasticConsts(Phys1, Phys2, Ent1, Ent2)
	local minMass
	if Ent1:IsWorld() then
		minMass = Phys2:GetMass()
	elseif Ent2:IsWorld() then
		minMass = Phys1:GetMass()
	else
		minMass = math_min( Phys1:GetMass(), Phys2:GetMass() )
	end

	local const = minMass * 100
	local damp = const * 0.2

	return const, damp
end


--  == Hydraulic ==
local function createHydraulic(self, index, ent1, ent2, v1, v2, width, bone1, bone2, constant, damping, rdamping, mat, stretch, color)
	if not checkEnts( self, ent1, ent2 ) then return end
	if not checkCount( self, "Hydraulic", ent1, ent2 ) then return end
	if not checkEdicts( self ) then return end
	local constraints = setupEntConstraints( ent1 )

	width = math.Clamp(width, 0, 50)

	local existing = constraints[index]
	if IsValid( existing ) then existing:Remove() end

	if color ~= nil then
		color = Color(color[1], color[2], color[3])
	end
	if not constant or not damping then
		constant, damping = CalcElasticConsts( getBone(ent1,bone1), getBone(ent2,bone2), ent1, ent2 )
	end

	local cons, rope = constraint.Elastic( ent1, ent2, bone1 or 0, bone2 or 0, v1, v2, constant, damping, rdamping or 0, mat ~= "" and mat or "cable/cable2", width or 1, stretch ~= 0, color )
	if not verifyConstraint( self, cons ) then return end

	constraints[index] = cons
	postCreate( self, "Hydraulic", ent1, ent2, cons, rope )
end

e2function void hydraulic(index, entity ent, vector v1, bone bone, vector v2, width)
	local entBone, index = isValidBone(bone)
	createHydraulic(self, index, ent, entBone, v1, v2, width, 0, index)
end

e2function void hydraulic(index, entity ent, vector v1, bone bone, vector v2, constant, damping, rdamping, string mat, width, stretch)
	local entBone, index = isValidBone(bone)
	createHydraulic(self, index, ent, entBone, v1, v2, width, 0, index, constant, damping, rdamping, mat, stretch)
end

e2function void hydraulic(index, entity ent, vector v1, bone bone, vector v2, constant, damping, rdamping, string mat, width, stretch, vector color)
	local entBone, index = isValidBone(bone)
	createHydraulic(self, index, ent, entBone, v1, v2, width, 0, index, constant, damping, rdamping, mat, stretch, color)
end

e2function void hydraulic(index, bone bone1, vector v1, bone bone2, vector v2, width)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, index1, index2)
end

e2function void hydraulic(index, bone bone1, vector v1, bone bone2, vector v2, constant, damping, rdamping, string mat, width, stretch)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, index1, index2, constant, damping, rdamping, mat, stretch)
end

e2function void hydraulic(index, bone bone1, vector v1, bone bone2, vector v2, constant, damping, rdamping, string mat, width, stretch, vector color)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, index1, index2, constant, damping, rdamping, mat, stretch, color)
end

e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, constant, damping, rdamping, string mat, width, stretch, vector color)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, 0, 0, constant, damping, rdamping, mat, stretch, color)
end

-- Note: Winch is just a rename of Hydraulic with the last parameter True.
--- Makes a winch constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, with <width> width.
e2function void winch(index, entity ent1, vector v1, entity ent2, vector v2, width)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, 0, 0, nil, nil, 0, "cable/cable2", 1)
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, with <width> width.
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, width)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, 0, 0)
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, constant and damping, with <width> width, <mat> material, and <stretch> stretch only option.
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, constant, damping, string mat, width, stretch)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, 0, 0, constant, damping, 0, mat, stretch)
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, constant, damping and relative damping, with <width> width, <mat> material, and <stretch> stretch only option.
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, constant, damping, rdamping, string mat, width, stretch)
	createHydraulic(self, index, ent1, ent2, v1, v2, width, 0, 0, constant, damping, rdamping, mat, stretch)
end


-- == Rope ==
local function createRope(self, index, ent1, ent2, v1, v2, bone1, bone2, addlength, width, mat, rigid, color)
	if not checkEnts( self, ent1, ent2 ) then return end
	if not checkCount( self, "Rope", ent1, ent2 ) then return end
	if not checkEdicts( self ) then return end
	local constraints = setupEntConstraints( ent1 )

	local length = ( ent1:LocalToWorld( v1 ) - ent2:LocalToWorld( v2 ) ):Length()

	local existing = constraints[index]
	if IsValid( existing ) then existing:Remove() end

	if color then
		color = Color(color[1], color[2], color[3])
	end

	local cons, rope = constraint.Rope( ent1, ent2, bone1 or 0, bone2 or 0, v1, v2, length, addlength or 0, 0, width or 1, mat ~= "" and mat or "cable/rope", rigid ~= 0,  color )
	if not verifyConstraint( self, cons ) then return end

	constraints[index] = cons
	postCreate( self, "Rope", ent1, ent2, cons, rope )
end

e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2, addlength, width, string mat, rigid, vector color )
	createRope(self, index, ent1, ent2, v1, v2, 0, 0, addlength, width, mat, rigid, color)
end

e2function void rope(index, entity ent, vector v1, bone bone, vector v2)
	local entBone, index = isValidBone(bone)
	createRope(self, index, ent, entBone, v1, v2, 0, index)
end

e2function void rope(index, entity ent, vector v1, bone bone, vector v2, addlength, width, string mat, rigid, vector color )
	local entBone, index = isValidBone(bone)
	createRope(self, index, ent, entBone, v1, v2, 0, index, addlength, width, mat, rigid, color)
end

e2function void rope(index, bone bone1, vector v1, bone bone2, vector v2)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createRope(self, index, ent1, ent2, v1, v2, index1, index2)
end

e2function void rope(index, bone bone1, vector v1, bone bone2, vector v2, addlength, width, string mat, rigid, vector color )
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createRope(self, index, ent1, ent2, v1, v2, index1, index2, addlength, width, mat, rigid, color)
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2)
	createRope(self, index, ent1, ent2, v1, v2)
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent, with <addlength> additional length, <width> width, and <mat> material.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2, addlength, width, string mat)
	createRope(self, index, ent1, ent2, v1, v2, 0, 0, addlength, width, mat)
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent, with <addlength> additional length, <width> width, and <mat> material.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2, addlength, width, string mat, rigid )
	createRope(self, index, ent1, ent2, v1, v2, 0, 0, addlength, width, mat, rigid)
end

__e2setcost(5)

--- Sets a rope/hydraulic/winch stored at index <index> inside <this> (the first entity) to be <length> long.
e2function void entity:setLength(index, length)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if length < 0 then length = 0 end

	local constraints = setupEntConstraints(this)

	local cons = constraints[index]
	if not IsValid(cons) then return end

	if cons.Type == "Rope" then
		cons:SetKeyValue("addlength", length)
	else
		cons:Fire("SetSpringLength", length, 0)
	end
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <constant> constant.
e2function void entity:setConstant(index, constant)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if constant < 0 then constant = 0 end

	local constraints = setupEntConstraints(this)
	if not constraints then return end

	local cons = constraints[index]
	if not IsValid(con) then return end

	cons:Fire("SetSpringConstant", constant, 0)
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <constant> constant and <dampen> damping.
e2function void entity:setConstant(index, constant, damping)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if constant < 0 then constant = 0 end
	if damping < 0 then damping = 0 end

	local constraints = setupEntConstraints(this)
	if not constraints then return end

	local cons = constraints[index]
	if not IsValid(cons) then return end

	cons:Fire("SetSpringConstant", constant, 0)
	cons:Fire("SetSpringDamping", damping, 0)
end

--- Sets a hydraulic/winch stored at index <index> inside <this> to be <dampen> damping.
e2function void entity:setDamping(index, damping)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if damping < 0 then damping = 0 end

	local constraints = setupEntConstraints(this)
	if not constraints then return end

	local cons = constraints[index]
	if not IsValid(con) then return end

	cons:Fire("SetSpringDamping", damping, 0)
end

__e2setcost(30)


-- == Sliders ==
local function createSlider(self, ent1, ent2, v1, v2, width, bone1, bone2, mat, color)
	if not checkEnts( self, ent1, ent2 ) then return end
	if not checkCount( self, "Slider", ent1, ent2 ) then return end
	if not checkEdicts( self ) then return end

	if color then
		color = Color(color[1],color[2],color[3],255)
	end

	local cons, rope = constraint.Slider( ent1, ent2, bone1 or 0, bone2 or 0, v1, v2, width or 1, mat ~= "" and mat or "cable/cable2", color )
	if not verifyConstraint( self, cons ) then return end

	postCreate(self, "Slider", ent1, ent2, cons, rope)
end

e2function void slider(entity ent, vector v1, bone bone, vector v2)
	local entBone, index = isValidBone(bone)
	createSlider(self, ent, entBone, v1, v2, 1, 0, index)
end

e2function void slider(entity ent, vector v1, bone bone, vector v2, width, string mat, vector color)
	local entBone, index = isValidBone(bone)
	createSlider(self, ent, entBone, v1, v2, width, 0, index, mat, color)
end

e2function void slider(bone bone1, vector v1, bone bone2, vector v2)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createSlider(self, ent1, ent2, v1, v2, 1, index1, index2)
end

e2function void slider(bone bone1, vector v1, bone bone2, vector v2, width, string mat, vector color)
	local ent1, index1 = isValidBone(bone1)
	local ent2, index2 = isValidBone(bone2)
	createSlider(self, ent1, ent2, v1, v2, width, index1, index2, mat, color)
end

e2function void slider(entity ent1, vector v1, entity ent2, vector v2, width, string mat, vector color)
	createSlider(self, ent1, ent2, v1, v2, width, 0, 0, mat, color)
end

--- Creates a slider between <ent1> and <ent2> at vector positions local to each ent.
e2function void slider(entity ent1, vector v1, entity ent2, vector v2)
	createSlider(self, ent1, ent2, v1, v2)
end

--- Creates a slider between <ent1> and <ent2> at vector positions local to each ent, with <width> width.
e2function void slider(entity ent1, vector v1, entity ent2, vector v2, width)
	createSlider(self, ent1, ent2, v1, v2, width)
end


-- == NoCollide ==
local function noCollideCreate(self, ent1, ent2, bone1, bone2)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "NoCollide", ent1, ent2) then return end

	local cons = constraint.NoCollide(ent1, ent2, bone1 or 0, bone2 or 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "NoCollide", ent1, ent2, cons)
end

e2function void entity:noCollide(entity target)
	noCollideCreate(self, this, target)
end

e2function void entity:noCollide(bone target)
	local ent, index = isValidBone(target)
	noCollideCreate(self, this, ent, 0, index)
end

e2function void bone:noCollide(entity target)
	local ent, index = isValidBone(this)
	noCollideCreate(self, ent, target, index)
end

e2function void bone:noCollide(bone target)
	local ent1, index1 = isValidBone(this)
	local ent2, index2 = isValidBone(target)
	noCollideCreate(self, ent1, ent2, index1, index2)
end

--- Nocollides <ent1> to <ent2>
[deprecated]
e2function void noCollide(entity ent1, entity ent2)
	noCollideCreate(self, ent1, ent2)
end

--- Nocollides <ent> to entities/players, just like Right Click of No-Collide Stool
[deprecated]
e2function void noCollideAll(entity ent, state)
	if not IsValid(ent) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, ent) then return self:throw("You do not own this prop!", nil) end

	ent:SetCollisionGroup(state == 0 and COLLISION_GROUP_NONE or COLLISION_GROUP_WORLD)
end


-- == Welds ==
local function weldCreate(self, ent1, ent2, bone1, bone2, forcelimit, nocollide)
	if not checkEnts(self, ent1, ent2) then return end
	if not checkCount(self, "Weld", ent1, ent2) then return end

	local cons = constraint.Weld(ent1, ent2, bone1 or 0, bone2 or 0, forcelimit or 0, nocollide ~= 0)
	if not verifyConstraint(self, cons) then return end

	postCreate(self, "Weld", ent1, ent2, cons)
end

e2function void entity:weld(entity target)
	weldCreate(self, this, target)
end

e2function void entity:weld(entity target, forcelimit, nocollide)
	weldCreate(self, this, target, 0, 0, forcelimit, nocollide)
end

e2function void entity:weld(bone target)
	local ent, index = isValidBone(target)
	weldCreate(self, this, ent, 0, index)
end

e2function void entity:weld(bone target, forcelimit, nocollide)
	local ent, index = isValidBone(target)
	weldCreate(self, this, ent, 0, index, forcelimit, nocollide)
end

e2function void bone:weld(entity target)
	local ent, index = isValidBone(this)
	weldCreate(self, ent, target, index)
end

e2function void bone:weld(entity target, forcelimit, nocollide)
	local ent, index = isValidBone(this)
	weldCreate(self, ent, target, index, 0, forcelimit, nocollide)
end

e2function void bone:weld(bone target)
	local ent1, index1 = isValidBone(this)
	local ent2, index2 = isValidBone(target)
	weldCreate(self, ent1, ent2, index1, index2)
end

e2function void bone:weld(bone target, forcelimit, nocollide)
	local ent1, index1 = isValidBone(this)
	local ent2, index2 = isValidBone(target)
	weldCreate(self, ent1, ent2, index1, index2, forcelimit, nocollide)
end

--- Welds <ent1> to <ent2>
[deprecated]
e2function void weld(entity ent1, entity ent2)
	weldCreate(self, ent1, ent2)
end

__e2setcost(5)

--- Breaks EVERY CONSTRAINT on <this>
e2function void entity:constraintBreak()
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end
	constraint.RemoveAll(this)
end

--- Breaks all constraints between <this> and <ent2>
e2function void entity:constraintBreak(entity ent2)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end

	local consts = this.Constraints or ent2.Constraints
	if not consts then return end

	for _, v in ipairs( consts ) do
		if v:IsValid() then
			local case1 = v.Ent1 == this and v.Ent2 == ent2
			local case2 = case1 or ( v.Ent1 == ent2 and v.Ent2 == this )

			if case1 or case2 then v:Remove() end
		end
	end
end

--- Breaks all constraints of type <consType> on <this>
e2function void entity:constraintBreak(string consType)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end
	constraint.RemoveConstraints(this, caps(consType))
end

--- Breaks a constraint of type <consType> between <this> and <ent2>
e2function void entity:constraintBreak(string consType, entity ent2)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not isOwner(self, this) then return self:throw("You do not own this prop!", nil) end

	local consts = this.Constraints or ent2.Constraints
	if not consts then return end

	consType = caps( consType )
	for _, v in ipairs( consts ) do
		if v:IsValid() then
			local correctType = v.Type == consType
			local case1 = correctType and ( v.Ent1 == this and v.Ent2 == ent2 )
			local case2 = correctType and ( case1 or ( v.Ent1 == ent2 and v.Ent2 == this ) )

			if case1 or case2 then
				v:Remove()
				break
			end
		end
	end
end
