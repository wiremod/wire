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

function MakeGPULibController( pl, Pos, Ang, model, screen )
	model = model or "models/jaanus/wiretool/wiretool_siren.mdl"
	if not WireLib.CanModel(pl, model) then return false end
	--if ( !pl:CheckLimit( "wire_cams" ) ) then return false end

	local controller = ents.Create( "gmod_wire_gpulib_controller" )
	if (!controller:IsValid()) then return false end

	controller:SetAngles( Ang )
	controller:SetPos( Pos )
	controller:SetModel(model)
	controller:Spawn()
	controller:Setup(screen)

	controller:SetPlayer( pl )

	local ttable = {
		pl = pl,
	}
	table.Merge(controller:GetTable(), ttable )

	--pl:AddCount( "wire_gpulib_switchers", controller )

	return controller
end

duplicator.RegisterEntityClass("gmod_wire_gpulib_controller", MakeGPULibController, "Pos", "Ang", "Model", "screen")
