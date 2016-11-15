AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "E2 Graphics Processor"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType( SIMPLE_USE )

	self.RenderTable = {}

	WireLib.CreateOutputs( self, { "User [ENTITY]" } )
	WireLib.CreateWirelinkOutput( nil, self, {true} )

	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false

	self.TopLeft = false
end

function ENT:Use( ply )
	WireLib.TriggerOutput( self, "User", ply )
end

function ENT:Think()
	WireLib.TriggerOutput( self, "User", nil )
end

function ENT:SetEGPOwner( ply )
	self.ply = ply
	self.plyID = IsValid(ply) and ply:UniqueID() or "World"
end

function ENT:GetEGPOwner()
	if not self.ply or not self.ply:IsValid() then
		local ply = player.GetByUniqueID( self.plyID )
		if ply then self.ply = ply end
		return ply
	else
		return self.ply
	end
	return false
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
