E2Lib.RegisterExtension("collcallback", true)

local maxcollclk=CreateConVar( "wire_col_detector_e2_maxcollclk", 100, 0, "Maximum amount of props with collision detection per gate" )
local collallow=CreateConVar( "wire_col_detector_e2_collallow", 1, 0, "Allow collision detection of other players' stuff" )

local registered_ents = {}
registerCallback("construct",function(self)
	self.colDatas={}
	self.colEnts={}
	self.collFilter=true
	self.collIgnoreConstrained=true
	self.colProps=0
end)

hook.Add("EntityRemoved", "Raf2EntityRemoved",function (ent)
	registered_ents[ent]=nil
end)

function entitiesCollide(ent,data)
	for i=1,#registered_ents[ent],1 do
		self=registered_ents[ent][i]
		if !IsValid(self.entity) then
			table.remove(registered_ents[ent],i)
			i=i-1
		else
			if (self.collFilter and #self.colDatas != 0) or (self.collIgnoreConstrained and table.HasValue(constraint.GetAllConstrainedEntities(ent),data.HitEntity)) then return end
			self.colData=data
			self.colData.ourEnt=ent
			self.colData.posFirst=ent:GetPhysicsObject():GetPos()
			self.colData.posSecond=data.HitEntity:GetPhysicsObject():GetPos()
			self.colData.angleFirst=ent:GetPhysicsObject():GetAngles()
			self.colData.angleSecond=data.HitEntity:GetPhysicsObject():GetAngles()
			if self.physicsEarlyCallback then
				self.entity:Execute()
			else
				table.insert(self.colDatas,data)
				timer.Simple(0,function()
					self.colData=self.colDatas[1]
					self.entity:Execute()
					table.remove(self.colDatas,1)
					self.colData=nil
				end)
			end
			self.colData=nil
		end
	end
end
function addCallback(ent,gate)
	if !IsValid(ent) or gate.colProps > maxcollclk:GetInt() or (!collallow:GetBool() and !isOwner(gate,ent)) then return end
	if registered_ents[ent]==nil then
		registered_ents[ent]={}
		if ent.PhysicsCollide then
			ent.PhysicsCollide=function(sel,data,collider)
				entitiesCollide(ent,data)
			end
		else
			ent:AddCallback("PhysicsCollide",entitiesCollide)
		end
	end
	if !table.HasValue(registered_ents[ent],gate) then
		table.insert(registered_ents[ent],gate)
		gate.colProps=gate.colProps+1
	else return end
end
function removeCallback(ent,gate)
	if !registered_ents[ent] then return end
	local tbl=registered_ents[ent]
	for i=1,#tbl,1 do
		if tbl[i] == gate then
			table.remove(registered_ents[ent],i)
			gate.colProps=gate.colProps-1
			return
		end
	end
end

__e2setcost(2)
e2function number isCollClk()
	if !self.colData then return 0 else return 1 end
	
end
e2function number collIgnoreConstrained(constrained)
	self.collIgnoreConstrained=constrained!=0
end
e2function number collFilter(filter)
	self.collFilter=filter!=0
end
e2function number entity:hasCollDetection()
	if !registered_ents[this] then return 0 else return 1 end
	
end
e2function void collEnableEarlyClk(enable)
	self.physicsEarlyCallback=enable!=0
end
__e2setcost(5)
e2function entity collEntity()
	if !self.colData then return NULL end
	return self.colData.ourEnt
end
e2function entity collHitEntity()
	if !self.colData then return NULL end
	return self.colData.HitEntity
end
e2function number collDelta()
	if !self.colData then return 0 end
	return self.colData.DeltaTime
end
e2function number collSpeed()
	if !self.colData then return 0 end
	return self.colData.Speed
end
e2function vector collVelocity()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.OurOldVelocity
end
e2function vector collHitVelocity()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.TheirOldVelocity
end
e2function vector collPos()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.HitPos
end
e2function vector collNormal()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.HitNormal
end
e2function vector collEntityPos()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.posFirst
end
e2function vector collHitEntityPos()
	if !self.colData then return Vector(0,0,0) end
	return self.colData.posSecond
end
e2function angle collEntityAng()
	if !self.colData then return Angle(0,0,0) end
	return self.colData.angleFirst
end
e2function angle collHitEntityAng()
	if !self.colData then return Angle(0,0,0) end
	return self.colData.angleSecond
end
__e2setcost(30)
e2function void entity:addCollDetection()
	addCallback(this,self)
end
e2function void entity:addCollDetection(entity gate)
	if IsValid(gate) and gate:GetClass() == "gmod_wire_expression2" and isOwner(self,gate.context) then
		addCallback(this,gate.context)
	end
end
e2function void entity:removeCollDetection()
	removeCallback(this,self)
end
e2function void entity:removeCollDetection(entity gate)
	if IsValid(gate) and gate:GetClass() == "gmod_wire_expression2" and isOwner(self,gate.context) then
		removeCallback(this,gate.context)
	end
end
__e2setcost(50)
e2function void removeAllCollClk()
	for ent, gates in pairs(registered_ents) do
		removeCallback(ent,self)
	end
end
