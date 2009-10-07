
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera"

function ENT:Initialize()
	self.phys = self:GetPhysicsObject()
	if not self.phys:IsValid() then self.phys = self end

	self.IdealPos = self:GetPos()
	self.IdealAng = self:GetAngles()
	self.IdealVel = self.phys:GetVelocity()
end

--[[
function ENT:Think()
	--if ValidEntity(self:GetParent()) then return end
	if self:GetPos() ~= self.IdealPos then
		self:SetPos(self.IdealPos)
	end
	if self:GetAngles() ~= self.IdealAng then
		self:SetAngles(self.IdealAng)
	end
	if self.phys:GetVelocity() ~= self.IdealVel then
		self.phys:SetVelocity(self.IdealVel)
	end
	if self:GetColor() ~= Color(0, 0, 0, 0) then
		self:SetColor(0, 0, 0, 0)
	end
	self:NextThink(CurTime()+0.1)
end
]]

function ENT:ReceiveInfo(iname, value)
	self.IdealAng = self:GetAngles()
	if iname == "X" then
		self.IdealPos.x = value
		self:SetPos(self.IdealPos)
	elseif iname == "Y" then
		self.IdealPos.y = value
		self:SetPos(self.IdealPos)
	elseif iname == "Z" then
		self.IdealPos.z = value
		self:SetPos(self.IdealPos)
	elseif iname == "Position" then
		self.IdealPos = value
		self:SetPos(self.IdealPos)

	elseif iname == "Pitch" then
		self.IdealAng.p = value
		--self:SetAngles(self.IdealAng)
	elseif iname == "Yaw" then
		self.IdealAng.y = value
		--self:SetAngles(self.IdealAng)
	elseif iname == "Roll" then
		self.IdealAng.r = value
		--self:SetAngles(self.IdealAng)
	elseif iname == "Angle" then
		self.IdealAng = value
		--self:SetAngles(self.IdealAng)

	elseif iname == "Direction" then
		self.IdealAng = value:Angle()
		--self:SetAngles(self.IdealAng)
	elseif iname == "Velocity" then
		self.IdealVel = value
		self.phys:SetVelocity(self.IdealVel)
	elseif iname == "Parent" then
		if ValidEntity(value) then
			self:SetParent(value)
		else
			self:SetParent(nil)
		end
	end
	if self:GetAngles() ~= self.IdealAng then
		local parent = self:GetParent()
		self:SetParent(nil)
		self:SetAngles(self.IdealAng)
		self:SetParent(parent)
	end
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end
