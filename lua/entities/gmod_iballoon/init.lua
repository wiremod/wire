AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
--same as normal balloon but invincible
local MODEL = Model("models/dav0r/balloon/balloon.mdl")

function ENT:Initialize()
	self.Entity:SetModel(MODEL)
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:SetMass(100)
		phys:Wake()
		phys:EnableGravity(false)
	end
	self:SetForce(1)
	self.Entity:StartMotionController()
end

function ENT:SetForce(force)
	self.Force = force*5000
	self.Entity:SetNetworkedFloat(0,self.Force)
	self:SetOverlayText("Force: " .. math.floor(force))
end

function ENT:PhysicsSimulate(phys,deltatime)
	-- Angular,Linear,globalforce
	return Vector(0,0,0),Vector(0,0,self.Force)*deltatime,SIM_GLOBAL_FORCE
end

function ENT:OnRestore( )
	self.Force = self.Entity:GetNetworkedFloat(0)
end
