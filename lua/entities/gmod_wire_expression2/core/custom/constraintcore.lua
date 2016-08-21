E2Lib.RegisterExtension("constraintcore", false, "Allows the creation and manipulation of constraints between entities.")

registerCallback("construct", function(self)
	self.data.constraintUndos = true
end)

__e2setcost(1)
e2function void enableConstraintUndo(state)
	self.data.constraintUndos = state ~= 0
end

local function checkEnts(self, ent1, ent2)
	if !ent1 || (!ent1:IsValid() && !ent1:IsWorld()) || !ent2 || (!ent2:IsValid() && !ent2:IsWorld()) || ent1 == ent2 then return false end
	if !isOwner(self, ent1) || !isOwner(self, ent2) then return false end
	return true
end
local function addundo(self, prop, message)
	self.player:AddCleanup( "constraints", prop )
	if self.data.constraintUndos then
		undo.Create("e2_"..message)
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	end
end
local function caps(text)
	local capstext = text:sub(1,1):upper() .. text:sub(2):lower()
	if capstext == "Nocollide" then return "NoCollide" end
	if capstext == "Advballsocket" then return "AdvBallsocket" end
	return capstext
end

// All vectors are LOCAL positions relative to their corresponding entities
__e2setcost(30)

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2)
	if not checkEnts(self, ent1, ent2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Axis(ent1, ent2, 0, 0, vec1, vec2, 0, 0, 0, 0), "axis")
end

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2, friction)
	if not checkEnts(self, ent1, ent2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Axis(ent1, ent2, 0, 0, vec1, vec2, 0, 0, friction, 0), "axis")
end

--- Creates an axis between <ent1> and <ent2> at vector positions local to each ent, with <friction> friction and <localaxis> rotation axis.
e2function void axis(entity ent1, vector v1, entity ent2, vector v2, friction, vector localaxis)
	if not checkEnts(self, ent1, ent2) then return end
	local vec1, vec2, laxis = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3]), Vector(localaxis[1], localaxis[2], localaxis[3])
	addundo(self, constraint.Axis(ent1, ent2, 0, 0, vec1, vec2, 0, 0, friction, 0, laxis), "axis")
end

--- Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>
e2function void ballsocket(entity ent1, vector v, entity ent2)
	if !checkEnts(self, ent1, ent2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.Ballsocket(ent1, ent2, 0, 0, vec, 0, 0, 0), "ballsocket")
end

--- Creates a ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with friction <friction>
e2function void ballsocket(entity ent1, vector v, entity ent2, friction)
	if !checkEnts(self, ent1, ent2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(ent1, ent2, 0, 0, Vector(), vec, 0, 0, -180, -180, -180, 180, 180, 180, friction, friction, friction, 0, 0), "ballsocket")
end

--- Creates an adv ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with many settings
e2function void ballsocket(entity ent1, vector v, entity ent2, vector mins, vector maxs, vector frictions)
	if !checkEnts(self, ent1, ent2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(ent1, ent2, 0, 0, Vector(), vec, 0, 0, mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3], frictions[1], frictions[2], frictions[3], 0, 0), "ballsocket")
end

--- Creates an adv ballsocket between <ent1> and <ent2> at <v>, which is local to <ent1>, with many settings
e2function void ballsocket(entity ent1, vector v, entity ent2, vector mins, vector maxs, vector frictions, rotateonly)
	if !checkEnts(self, ent1, ent2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(ent1, ent2, 0, 0, Vector(), vec, 0, 0, mins[1], mins[2], mins[3], maxs[1], maxs[2], maxs[3], frictions[1], frictions[2], frictions[3], rotateonly, 0), "ballsocket")
end

--- Creates an angular weld (angles are fixed, position isn't) between <ent1> and <ent2> at <v>, which is local to <ent1>
e2function void weldAng(entity ent1, vector v, entity ent2)
	if !checkEnts(self, ent1, ent2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(ent1, ent2, 0, 0, Vector(), vec, 0, 0, 0, -0, 0, 0, 0, 0, 0, 0, 0, 1, 0), "ballsocket")
end


local function CalcElasticConsts(Phys1, Phys2, Ent1, Ent2)
	local minMass
	if Ent1:IsWorld() then 
		minMass = Phys2:GetMass()
	elseif Ent2:IsWorld() then 
		minMass = Phys1:GetMass()
	else 
		minMass = math.min( Phys1:GetMass(), Phys2:GetMass() )
	end
	
	local const = minMass * 100
	local damp = const * 0.2
	
	return const, damp
end

// Note: Winch is just a rename of Hydraulic with the last parameter True.
--- Makes a winch constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, with <width> width. 
e2function void winch(index, entity ent1, vector v1, entity ent2, vector v2, width)
	if !checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 || width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end
	
	local constant, dampen = CalcElasticConsts( ent1:GetPhysicsObject(), ent2:GetPhysicsObject(), ent1, ent2 )
	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, dampen, 0, "cable/cable2", width, true )
	addundo(self, ent1.data.Ropes[index], "winch")
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, with <width> width. 
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, width)
	if !checkEnts(self, ent1, ent2) then return end
	if !ent1.data then ent1.data = {} end
	if !ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 || width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end
	
	local constant, dampen = CalcElasticConsts( ent1:GetPhysicsObject(), ent2:GetPhysicsObject(), ent1, ent2 )
	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, dampen, 0, "cable/cable2", width, false )
	addundo(self, ent1.data.Ropes[index], "hydraulic")
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, constant and damping, with <width> width, <mat> material, and <stretch> stretch only option. 
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, constant, damping, string mat, width, stretch)
	if not checkEnts(self, ent1, ent2) then return end
	if not ent1.data then ent1.data = {} end
	if not ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 or width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end

	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, damping, 0, mat, width, tobool(stretch) )
	addundo(self, ent1.data.Ropes[index], "hydraulic")
end

--- Makes a hydraulic constraint (stored at index <index>) between <ent1> and <ent2>, at vectors local to their respective ents, constant, damping and relative damping, with <width> width, <mat> material, and <stretch> stretch only option. 
e2function void hydraulic(index, entity ent1, vector v1, entity ent2, vector v2, constant, damping, rdamping, string mat, width, stretch)
	if not checkEnts(self, ent1, ent2) then return end
	if not ent1.data then ent1.data = {} end
	if not ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 or width > 50 then width = 1 end
	
	if IsValid(ent1.data.Ropes[index]) then
		ent1.data.Ropes[index]:Remove()
	end

	ent1.data.Ropes[index] = constraint.Elastic( ent1, ent2, 0, 0, vec1, vec2, constant, damping, rdamping, mat, width, tobool(stretch) )
	addundo(self, ent1.data.Ropes[index], "hydraulic")
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2)
	if not checkEnts(self, ent1, ent2) then return end
	if not ent1.data then ent1.data = {} end
	if not ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	local length = (ent1:LocalToWorld(vec1) - ent2:LocalToWorld(vec2)):Length()
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	ent1.data.Ropes[index] = constraint.Rope( ent1, ent2, 0, 0, vec1, vec2, length, 0, 0, 1, "cable/rope", false )
	addundo(self, ent1.data.Ropes[index], "rope")
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent, with <addlength> additional length, <width> width, and <mat> material.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2, addlength, width, string mat)
	if not checkEnts(self, ent1, ent2) then return end
	if not ent1.data then ent1.data = {} end
	if not ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	local length = (ent1:LocalToWorld(vec1) - ent2:LocalToWorld(vec2)):Length()
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	ent1.data.Ropes[index] = constraint.Rope( ent1, ent2, 0, 0, vec1, vec2, length, addlength, 0, width, mat, false )
	addundo(self, ent1.data.Ropes[index], "rope")
end

--- Creates a rope between <ent1> and <ent2> at vector positions local to each ent, with <addlength> additional length, <width> width, and <mat> material.
e2function void rope(index, entity ent1, vector v1, entity ent2, vector v2, addlength, width, string mat, rigid )
	if not checkEnts(self, ent1, ent2) then return end
	if not ent1.data then ent1.data = {} end
	if not ent1.data.Ropes then ent1.data.Ropes = {} end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	local length = (ent1:LocalToWorld(vec1) - ent2:LocalToWorld(vec2)):Length()
	
	if IsValid(ent1.data.Ropes[index]) then 
		ent1.data.Ropes[index]:Remove() 
	end
	
	ent1.data.Ropes[index] = constraint.Rope( ent1, ent2, 0, 0, vec1, vec2, length, addlength, 0, width, mat, tobool(rigid) )
	addundo(self, ent1.data.Ropes[index], "rope")
end

__e2setcost(5)

--- Sets a rope/hydraulic/winch stored at index <index> inside <this> (the first entity) to be <length> long.
e2function void entity:setLength(index, length)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if length < 0 then length = 0 end
	if this.data.Ropes then
		local con = this.data.Ropes[index]
		if IsValid(con) then
			if con.Type == "Rope" then
				con:SetKeyValue("addlength", length)
			else
				con:Fire("SetSpringLength", length, 0)
			end
		end
	end
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <constant> constant.
e2function void entity:setConstant(index, constant)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if constant < 0 then constant = 0 end
	if this.data.Ropes then
		local con = this.data.Ropes[index]
		if IsValid(con) then
			con:Fire("SetSpringConstant", constant, 0)
		end
	end
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <constant> constant and <dampen> damping.
e2function void entity:setConstant(index, constant, damping)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if constant < 0 then constant = 0 end
	if damping < 0 then damping = 0 end
	if this.data.Ropes then
		local con = this.data.Ropes[index]
		if IsValid(con) then
			con:Fire("SetSpringConstant", constant, 0)
			con:Fire("SetSpringDamping", damping, 0)
		end
	end
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <dampen> damping.
e2function void entity:setDamping(index, damping)
	if not IsValid(this) then return end
	if not isOwner(self, this) then return false end
	if damping < 0 then damping = 0 end
	if this.data.Ropes then
		local con = this.data.Ropes[index]
		if IsValid(con) then
			con:Fire("SetSpringDamping", damping, 0)
		end
	end
end

__e2setcost(30)

--- Creates a slider between <ent1> and <ent2> at vector positions local to each ent.
e2function void slider(entity ent1, vector v1, entity ent2, vector v2)
	if !checkEnts(self, ent1, ent2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Slider(ent1, ent2, 0, 0, vec1, vec2, 1), "slider")
end

--- Creates a slider between <ent1> and <ent2> at vector positions local to each ent, with <width> width.
e2function void slider(entity ent1, vector v1, entity ent2, vector v2, width)
	if !checkEnts(self, ent1, ent2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Slider(ent1, ent2, 0, 0, vec1, vec2, width), "slider")
end

--- Nocollides <ent1> to <ent2>
e2function void noCollide(entity ent1, entity ent2)
	if !checkEnts(self, ent1, ent2) then return end
	addundo(self, constraint.NoCollide(ent1, ent2, 0, 0), "nocollide") 
end

--- Nocollides <ent> to entities/players, just like Right Click of No-Collide Stool
e2function void noCollideAll(entity ent, state)
	if !IsValid(ent) then return end
	if !isOwner(self, ent) then return false end
	if state != 0 then 
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
	else
		ent:SetCollisionGroup( COLLISION_GROUP_NONE )
	end
end

--- Welds <ent1> to <ent2>
e2function void weld(entity ent1, entity ent2)
	if !checkEnts(self, ent1, ent2) then return end
	addundo(self, constraint.Weld(ent1, ent2, 0, 0, 0, true), "weld")
end

__e2setcost(5)

--- Breaks EVERY CONSTRAINT on <this>
e2function void entity:constraintBreak()
	if !IsValid(this) then return end
	if !isOwner(self, this) then return false end
	constraint.RemoveAll(this)
end

--- Breaks all constraints between <this> and <ent2>
e2function void entity:constraintBreak(entity ent2)
	if !checkEnts(self, this, ent2) then return end
	local consts = this.Constraints
	local consts2 = ent2.Constraints
	if !consts then 
		if !consts2 then return end
		consts = consts2
	end 
	for _,v in pairs( consts ) do
		if IsValid(v) then
			local CTab = v:GetTable()
			if ( CTab.Ent1 == this && CTab.Ent2 == ent2 ) ||  ( CTab.Ent1 == ent2 && CTab.Ent2 == this ) then
				v:Remove()
			end
	 	end
	end
end

--- Breaks all constraints of type <type> on <this>
e2function void entity:constraintBreak(string type)
	if !IsValid(this) then return end
	if !isOwner(self, this) then return false end
	constraint.RemoveConstraints(this, caps(type))
end

--- Breaks a constraint of type <type> between <this> and <ent2>
e2function void entity:constraintBreak(string type, entity ent2)
	if !checkEnts(self, this, ent2) then return end
	local consts = this.Constraints
	local consts2 = ent2.Constraints
	if !consts then 
		if !consts2 then return end
		consts = consts2
	end 
	for _,v in pairs( consts ) do
		if IsValid(v) then
			local CTab = v:GetTable()
			if CTab.Type == caps(type) && ( CTab.Ent1 == this && CTab.Ent2 == ent2 ) ||  ( CTab.Ent1 == ent2 && CTab.Ent2 == this ) then
				v:Remove()
				break
			end
	 	end
	end
end
