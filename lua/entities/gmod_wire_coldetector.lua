AddCSLuaFile()

DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName = "Wire Collision Detector"
ENT.WireDebugName = "Collision Detector"

if CLIENT then return end

local stickplayer = CreateConVar( "wire_col_detector_stickplayer", 0, 0, "Allow linked entity stick to players" )
local stickprops = CreateConVar( "wire_col_detector_stickprops", 0, 0, "Allow sticking to other players stuff" )

function entitiesCollide(ent,data)
	if not IsValid(ent.ColSensor) or ent.ColSensor.LinkedEnt ~= ent then return end
	ent.ColSensor:ApplyCollide(data,ent)
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.LinkedEnt = self
	self.Inputs = WireLib.CreateInputs( self, {"Stick to world", "Stick to props", "Stick to npc/players"} )
	self.Outputs = WireLib.CreateOutputs(self, {"Collided","Speed","Delta Time","Hit Position [VECTOR]","Hit Normal [VECTOR]","Velocity [VECTOR]","Hit Entity Velocity [VECTOR]","Hit Entity [ENTITY]","Entity Position [VECTOR]","Entity Angle [ANGLE]","Hit Entity Position [VECTOR]","Hit Entity Angle [ANGLE]"})
end

function ENT:Setup(AllowConstrained,NoPhysics)
	self.AllowConstrained = AllowConstrained
	self.NoPhysics = NoPhysics
	self:ShowOutput()
end

function ENT:PhysicsCollide(data,collider)
	if self.LinkedEnt == self then
		self:ApplyCollide(data,self)
	end
end

function ENT:ApplyCollide(data,ent)
	if not self.AllowConstrained and table.HasValue(constraint.GetAllConstrainedEntities(ent),data.HitEntity) then return end
	
	local posxd = ent:GetPhysicsObject():GetPos()
	local anglesxd = ent:GetPhysicsObject():GetAngles()
	if data.HitEntity == nil then return end
	
	self.Collided = true
	self.CurrData = data
	
	WireLib.TriggerOutput(self, "Collided", 1)
	WireLib.TriggerOutput(self, "Delta Time", data.DeltaTime)
	WireLib.TriggerOutput(self, "Hit Entity", data.HitEntity)
	WireLib.TriggerOutput(self, "Hit Position", data.HitPos)
	WireLib.TriggerOutput(self, "Velocity", data.OurOldVelocity)
	WireLib.TriggerOutput(self, "Hit Entity Velocity", data.TheirOldVelocity)
	WireLib.TriggerOutput(self, "Speed", data.Speed)
	WireLib.TriggerOutput(self, "Hit Normal", data.HitNormal)
	WireLib.TriggerOutput(self, "Entity Position", posxd)
	WireLib.TriggerOutput(self, "Entity Angle", anglesxd)
	WireLib.TriggerOutput(self, "Hit Entity Position", ent2pos)
	WireLib.TriggerOutput(self, "Hit Entity Angle", ent2ang)
	
	self:ShowOutput()
	
	if self.StickToWorld == 0 and self.StickToNPC == 0 and self.StickToProp == 0 then return end
	
	if GetConVarNumber("wire_col_detector_stickplayer") == 0 and data.HitEntity:IsPlayer() then return end
	if GetConVarNumber("wire_col_detector_stickprops") == 0 and not gamemode.Call("CanProperty",self:GetPlayer(),"weld",data.HitEntity) then return end
	
	if self.StickToWorld == 0 and data.HitEntity:IsWorld() then return end
	if self.StickToNPC == 0 and (data.HitEntity:IsNPC() or data.HitEntity:IsPlayer()) then return end
	
	local ent2pos = data.HitEntity:GetPos()
	local ent2ang = data.HitEntity:GetAngles()
	
	timer.Simple(0,function()
		if IsValid(ent) and (IsValid(data.HitEntity) or data.HitEntity:IsWorld()) and not IsValid(self.Stick) and  not IsValid(ent:GetParent()) then
			local bonehit = 0
			self.StickTo = data.HitEntity
			
			angle.pitch = ent2ang.pitch-angle.pitch
			angle.yaw = ent2ang.yaw-angle.yaw
			angle.roll = ent2ang.roll-angle.roll
			vec:Rotate(angle)
			
			for i = 0,data.HitEntity:GetPhysicsObjectCount()-1 do
				if data.HitEntity:GetPhysicsObjectNum(i) == data.HitObject then
					bonehit = i
					break
				end
			end
			
			local newentpos = data.HitEntity:GetPos()
			local newentang = data.HitEntity:GetAngles()
			
			data.HitEntity:SetPos(ent2pos)
			data.HitEntity:SetAngles(ent2ang)
			ent:GetPhysicsObject():SetAngles(anglesxd)
			ent:GetPhysicsObject():SetPos(posxd)
			ent:SetAngles(anglesxd)
			ent:SetPos(posxd)
			
			if util.IsValidPhysicsObject( data.HitEntity, 0) && (not self.NoPhysics || data.HitEntity:IsWorld()) then
				self.Stick = constraint.Weld(ent, data.HitEntity,0,bonehit,0,true)
				if data.HitEntity:IsWorld() then
					ent:GetPhysicsObject():EnableMotion(false)
					ent:GetPhysicsObject():Sleep()
				end
			else
				ent:PhysicsDestroy()
				ent:SetSolid(SOLID_NONE)
				ent:FollowBone(data.HitEntity,bonehit)
				
			end
			
			data.HitEntity:SetPos(newentpos)
			data.HitEntity:SetAngles(newentang)
		end
	end)
end

function ENT:RemoveLink()
	self.StickTo = nil
	if IsValid(self.Stick) then
		self.Stick:Remove()
	end
	
	if IsValid(self.LinkedEnt) then
		if IsValid(self.LinkedEnt:GetParent()) then
			self.LinkedEnt:SetParent(nil)
			self.LinkedEnt:PhysicsInit(SOLID_VPHYSICS)
			self.LinkedEnt:SetSolid( SOLID_VPHYSICS )
			timer.Simple(0,function() 
				if IsValid(self.LinkedEnt) then
					self.LinkedEnt:GetPhysicsObject():Wake() 
				end
			end)
		end
	end
	
end

function ENT:TriggerInput( name, value )
	if name == "Stick to world" then
		self.StickToWorld = value
		if value == 0 and self.StickTo and self.StickTo:IsWorld() then
			self:RemoveLink()
		end
	elseif name == "Stick to props" then
		self.StickToProps = value
		if value == 0 and self.StickTo and not self.StickTo:IsNPC() and not self.StickTo:IsPlayer() and not self.StickTo:IsWorld() then
			self:RemoveLink()
		end
	elseif name == "Stick to npc/players" then
		self.StickToNPC=value
		if value == 0 and self.StickTo and (self.StickTo:IsNPC() or self.StickTo:IsPlayer()) then
			self:RemoveLink()
		end
	end
end

function ENT:Think()
	if self.Collided then
		WireLib.TriggerOutput(self, "Collided", 0)
		self.Collided = false
		self:ShowOutput()
	end
end

function ENT:ShowOutput()
	local str
	if IsValid(self.LinkedEnt) then
		str = "Linked Entity: "..util.TypeToString(self.LinkedEnt)
	else
		str = "Entity not linked"
	end
	if self.CurrData then
		str = str.."\nCollided: "..util.TypeToString(self.Collided)
	end
	self:SetOverlayText(str)
end

function ENT:LinkEnt(ent)
	if not util.IsValidPhysicsObject( ent, 0) then return end
	if self.LinkedEnt ~= ent then
		self:RemoveLink()
	end
	self.LinkedEnt = ent
	ent.ColSensor = self
	
	if self.LinkedEnt.PhysicsCollide then
		self.LinkedEnt.PhysicsCollide = function(sel,data,collider)
			if IsValid(self) then
				self:ApplyCollide(data,self.LinkedEnt)
			end
		end
	else
		ent:AddCallback("PhysicsCollide",entitiesCollide)
	end
	
	self:ShowOutput()
 	return true
end

function ENT:UnlinkEnt(ent)
	if not IsValid(self.LinkedEnt) then return false end
	self:RemoveLink()
	self.LinkedEnt.ColSensor = nil
	self.LinkedEnt = self
	self:ShowOutput()
	return true
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.LinkedEnt) then
		info.LinkedEnt = self.LinkedEnt:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if IsValid(GetEntByID( info.LinkedEnt )) then
		self:LinkEnt(GetEntByID( info.LinkedEnt ))
	end
end

duplicator.RegisterEntityClass("gmod_wire_coldetector", WireLib.MakeWireEnt,"Data","AllowConstrained","NoPhysics")
