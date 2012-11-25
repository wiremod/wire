AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Camera"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName = "Camera"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self.phys = self:GetPhysicsObject()
	if not self.phys:IsValid() then self.phys = self end

	self.IdealPos = self:GetPos()
	self.IdealAng = self:GetAngles()
	self.IdealVel = self.phys:GetVelocity()
end

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
		if not isvector(value) then
			if istable(value) and #value == 3 then
				value = Vector(unpack(value))
			else
				return
			end
		end
		self.IdealPos = value
		self:SetPos(self.IdealPos)
	elseif iname == "Pitch" then
		self.IdealAng.p = value
	elseif iname == "Yaw" then
		self.IdealAng.y = value
	elseif iname == "Roll" then
		self.IdealAng.r = value
	elseif iname == "Angle" then
		self.IdealAng = value
	elseif iname == "Direction" then
		if not isvector(value) then
			if istable(value) and #value == 3 then
				value = Vector(unpack(value))
			else
				return
			end
		end
		self.IdealAng = value:Angle()
	elseif iname == "Velocity" then
		self.IdealVel = value
		self.phys:SetVelocity(self.IdealVel)
	elseif iname == "Parent" then
		if IsValid(value) then
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
