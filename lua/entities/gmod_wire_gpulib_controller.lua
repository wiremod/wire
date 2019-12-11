AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire GPULib Controller"
ENT.WireDebugName = "GPULib Controller"

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	WireLib.CreateInputs(self, { "Target [ENTITY]" })
	WireLib.CreateOutputs(self, { "Screen [ENTITY]", "Target [ENTITY]", "LocalPosition [VECTOR]", "LocalAngle [ANGLE]", "Resolution" })
end

function ENT:Setup()
end

function ENT:SetScreen(screen)
	self.screen = screen
	WireLib.TriggerOutput(self, "Screen", screen)
	if IsValid(self.target) then
		GPULib.switchscreen(self.screen, self.target)
	end
	self:UpdateTarget()
end

function ENT:Think()
	self:UpdateTarget()
end

function ENT:UpdateTarget()
	local target = self.screen and self.screen.GPUEntity
	if not IsValid(target) then target = self.screen end

	if self.target ~= target then
		self.target = target
		if IsValid(target) then
			WireLib.TriggerOutput(self, "Target", target)
			local monitor, pos, ang = GPULib.GPU.GetInfo({ Entity = target }) -- TODO: think of a cleaner way
			WireLib.TriggerOutput(self, "LocalPosition", monitor.offset)
			WireLib.TriggerOutput(self, "LocalAngle", monitor.rot)
			WireLib.TriggerOutput(self, "Resolution", monitor.RS)
		else
			WireLib.TriggerOutput(self, "Target", NULL)
			WireLib.TriggerOutput(self, "LocalPosition", Vector(0,0,0))
			WireLib.TriggerOutput(self, "LocalAngle", Angle(0,0,0))
			WireLib.TriggerOutput(self, "Resolution", 0)
		end
	end
end

function ENT:TriggerInput(iname, value)
	if iname == "Target" and self.screen and self.screen:IsValid() then
		if not IsValid(value) then value = self.screen end
		GPULib.switchscreen(self.screen, value)
		self:UpdateTarget()
	end
end

duplicator.RegisterEntityClass("gmod_wire_gpulib_controller", WireLib.MakeWireEnt, "Data")

function ENT:LinkEnt(screen)
	if not IsValid(screen) then return false, "Invalid entity" end
	self:SetScreen(screen)
	return true
end
function ENT:UnlinkEnt()
	self:SetScreen(nil)
	return true
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.screen) then
		info.screen = self.screen:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self:SetScreen(GetEntByID(info.screen))
	self:UpdateTarget()
end

