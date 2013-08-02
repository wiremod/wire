
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Wire FX Emitter"

function ENT:Initialize()
	self:SetModel( "models/props_lab/tpplug.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	self.Inputs = WireLib.CreateInputs(self, {"On", "Effect", "Delay", "Direction [VECTOR]"})
end

function ENT:Setup(delay, effect)
	if delay then self:SetDelay(delay) end
	if effect then self:SetEffect(effect) end
end

function ENT:TriggerInput( inputname, value, iter )
	if inputname == "Direction" then
		self:SetFXDir(value:GetNormal())
	elseif inputname == "Effect" then
		self:SetEffect(math.Clamp(value - value % 1, 1, self.fxcount))
	elseif inputname == "On" then
		self:SetOn(value ~= 0)
	elseif inputname == "Delay" then
		self:SetDelay(math.Clamp(value, 0.05, 20))
	--elseif (inputname == "Position") then -- removed for excessive mingability
	--	self:SetFXPos(value)
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	-- Old dupes stored this info here rather than as RegisterEntityClass vars
	if info.Effect then self:SetEffect(info.Effect) end
	if info.Delay then self:SetDelay(info.Delay) end
end

duplicator.RegisterEntityClass("gmod_wire_fx_emitter", MakeWireEnt, "Data", "delay", "effect" )
-- Note: delay and effect are here for backwards compatibility, they're now stored in the DataTable
