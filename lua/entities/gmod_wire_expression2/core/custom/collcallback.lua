E2Lib.RegisterExtension("collcallback", true)

local wire_col_detector_e2_maxcollclk = CreateConVar( "wire_col_detector_e2_maxcollclk", 100, 0, "Maximum amount of props with collision detection per gate" )
local wire_col_detector_e2_collallow = CreateConVar( "wire_col_detector_e2_collallow", 1, 0, "Allow collision detection of other players' stuff" )

local registered_ents = {}

registerCallback("construct", function(self)
	self.colDatas = {}
	self.colEnts = {}
	self.collFilter = true
	self.collIgnoreConstrained = true
	self.colProps = 0
end)

hook.Add("EntityRemoved", "E2CollClkEntityRemoved", function(ent)
	registered_ents[ent]=nil
end)

local function entitiesCollide(ent, data)
	for i = 1, #registered_ents[ent], 1 do
		self = registered_ents[ent][i]
		if not IsValid(self.entity) then
			table.remove(registered_ents[ent], i)
			i = i-1
		else
			if (self.collFilter and #self.colDatas ~= 0) or (self.collIgnoreConstrained and table.HasValue(constraint.GetAllConstrainedEntities(ent), data.HitEntity)) then return end
			
			self.colData = data
			self.colData.ourEnt = ent
			self.colData.posFirst = data.PhysObject:GetPos()
			self.colData.angleFirst = ent.PhysObject:GetAngles()
			
			if IsValid(data.HitObject) then
				self.colData.posSecond = data.HitObject:GetPos()
				self.colData.angleSecond = data.HitObject:GetAngles()
			else
				self.colData.posSecond = data.HitEntity:GetPos()
				self.colData.angleSecond = data.HitEntity:GetAngles()
			end
			
			for i = 0, ent:GetPhysicsObjectCount()-1 do
				if ent:GetPhysicsObjectNum(i) == data.PhysObject then
					data.boneFirst = i
					break
				end
			end
			
			for i = 0, data.HitEntity:GetPhysicsObjectCount()-1 do
				if data.HitEntity:GetPhysicsObjectNum(i) == data.HitObject then
					data.boneSecond = i
					break
				end
			end
			
			if self.physicsEarlyCallback then
				self.entity:Execute()
			else
				table.insert(self.colDatas, data)
				timer.Simple(0, function()
					self.colData = self.colDatas[1]
					self.entity:Execute()
					table.remove(self.colDatas, 1)
					self.colData = nil
				end)
			end
			self.colData = nil
		end
	end
end

local function addCallback(ent, gate)
	if not IsValid(ent) or gate.colProps > wire_col_detector_e2_maxcollclk:GetInt() then return end
	if not wire_col_detector_e2_collallow:GetBool() and not isOwner(gate, ent) then return end
	
	if registered_ents[ent] == nil then
		registered_ents[ent] = {}
		if ent.PhysicsCollide then
			ent.PhysicsCollide = function(sel, data, collider)
				entitiesCollide(ent, data)
			end
		else
			ent:AddCallback("PhysicsCollide", entitiesCollide)
		end
	end
	
	if not table.HasValue(registered_ents[ent], gate) then
		table.insert(registered_ents[ent], gate)
		gate.colProps = gate.colProps+1
	else return end
end

local function removeCallback(ent, gate)
	if not registered_ents[ent] then return end
	local tbl = registered_ents[ent]
	for i = 1, #tbl, 1 do
		if tbl[i] == gate then
			table.remove(registered_ents[ent], i)
			gate.colProps = gate.colProps-1
			return
		end
	end
end

__e2setcost(2)
e2function number isCollClk()
	if not self.colData then return 0 else return 1 end
end

e2function number collIgnoreConstrained(constrained)
	self.collIgnoreConstrained = constrained ~= 0
end

e2function number collFilter(filter)
	self.collFilter = filter ~= 0
end

e2function number entity:hasCollDetection()
	if not registered_ents[this] then return 0 else return 1 end
end

e2function void collEnableEarlyClk(enable)
	self.physicsEarlyCallback = enable ~= 0
end

__e2setcost(5)
e2function entity collEntity()
	if not self.colData then return NULL end
	return self.colData.ourEnt
end

e2function entity collHitEntity()
	if not self.colData then return NULL end
	return self.colData.HitEntity
end

e2function number collDelta()
	if not self.colData then return 0 end
	return self.colData.DeltaTime
end

e2function number collSpeed()
	if not self.colData then return 0 end
	return self.colData.Speed
end

e2function vector collVelocity()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.OurOldVelocity
end

e2function vector collHitVelocity()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.TheirOldVelocity
end

e2function vector collPos()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.HitPos
end

e2function vector collNormal()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.HitNormal
end

e2function vector collEntityPos()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.posFirst
end

e2function vector collHitEntityPos()
	if not self.colData then return Vector(0, 0, 0) end
	return self.colData.posSecond
end

e2function angle collEntityAng()
	if not self.colData then return Angle(0, 0, 0) end
	return self.colData.angleFirst
end

e2function angle collHitEntityAng()
	if not self.colData then return Angle(0, 0, 0) end
	return self.colData.angleSecond
end

e2function bone collEntityBone()
	if not self.colData then return nil end
	return getBone(self.colData.ourEnt,self.colData.boneFirst)
end

e2function bone collHitEntityBone()
	if not self.colData then return nil end
	return getBone(self.colData.HitEntity,self.colData.boneSecond)
end

__e2setcost(30)
e2function void entity:addCollDetection()
	addCallback(this, self)
end

e2function void entity:addCollDetection(entity gate)
	if IsValid(gate) and gate:GetClass() == "gmod_wire_expression2" and isOwner(self, gate.context) then
		addCallback(this, gate.context)
	end
end

e2function void entity:removeCollDetection()
	removeCallback(this, self)
end

e2function void entity:removeCollDetection(entity gate)
	if IsValid(gate) and gate:GetClass() == "gmod_wire_expression2" and isOwner(self, gate.context) then
		removeCallback(this, gate.context)
	end
end

__e2setcost(50)
e2function void removeAllCollClk()
	for ent, gates in pairs(registered_ents) do
		removeCallback(ent, self)
	end
end
