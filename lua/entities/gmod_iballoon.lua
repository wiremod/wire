AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )
ENT.PrintName       = "Indestructible Balloon"

if CLIENT then return end -- No more client

local MODEL = Model("models/dav0r/balloon/balloon.mdl")

function ENT:Initialize()
	self:SetModel(MODEL)
	self:PhysicsInit(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:SetMass(100)
		phys:Wake()
		phys:EnableGravity(false)
	end
	self:SetForce(1)
	self:StartMotionController()
end

function ENT:SetForce(force)
	self.Force = force*5000
	self:SetNetworkedFloat(0,self.Force)
	self:SetOverlayText("Force: " .. math.floor(force))
end

function ENT:PhysicsSimulate(phys,deltatime)
	-- Angular,Linear,globalforce
	return Vector(0,0,0),Vector(0,0,self.Force)*deltatime,SIM_GLOBAL_FORCE
end

function ENT:OnRestore( )
	self.Force = self:GetNetworkedFloat(0)
end
