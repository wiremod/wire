AddCSLuaFile( "cl_init.lua" )
include('cl_init.lua')

ENT.WireDebugName = "GPULib Controller"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	WireLib.CreateInputs(self, { "Target [ENTITY]" })
	WireLib.CreateOutputs(self, { "Screen [ENTITY]", "Target [ENTITY]", "LocalPosition [VECTOR]", "LocalAngle [ANGLE]", "Resolution" })

	self:ShowOutput()
end

function ENT:Setup(screen)
	self.screen = screen
	WireLib.TriggerOutput(self, "Screen", screen)
	self:UpdateTarget()
end

function ENT:Think()
	local target = self.screen.GPUEntity
	if not IsValid(self.target) or target ~= self.target then
		self:UpdateTarget()
	end
end

function ENT:UpdateTarget()
	local target = self.screen.GPUEntity
	if not IsValid(target) then target = self.screen end
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

function ENT:TriggerInput(iname, value)
	if iname == "Target" then
		if not IsValid(value) then value = self.screen end
		GPULib.switchscreen(self.screen, value)
		self:UpdateTarget()
	end
end

function ENT:ShowOutput()
	local text = "GPULib controller"
	self:SetOverlayText( text )
end

/*
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if self.CamPod and self.CamPod:IsValid() then
		info.pod = self.CamPod:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if info.pod then
		self.CamPod = GetEntByID(info.pod)
		if not self.CamPod then
			self.CamPod = ents.GetByIndex(info.pod)
		end
	end
end
*/

function MakeGPULibController( pl, Pos, Ang, model, screen )
	if (pl!=nil) then if ( !pl:CheckLimit( "wire_cams" ) ) then return false end end

	local controller = ents.Create( "gmod_wire_gpulib_controller" )
	if (!controller:IsValid()) then return false end

	controller:SetAngles( Ang )
	controller:SetPos( Pos )
	controller:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
	controller:Spawn()
	controller:Setup(screen)

	controller:SetPlayer( pl )

	local ttable = {
		pl = pl,
	}
	table.Merge(controller:GetTable(), ttable )

	if (pl!=nil) then pl:AddCount( "wire_gpulib_switchers", controller ) end

	return controller
end

duplicator.RegisterEntityClass("gmod_wire_gpulib_controller", MakeGPULibController, "Pos", "Ang", "Model", "screen")
