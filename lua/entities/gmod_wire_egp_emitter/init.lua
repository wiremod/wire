AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "E2 Graphics Processor Emitter"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	--self:DrawShadow( false )

	self.RenderTable = {}

	self:SetUseType(SIMPLE_USE)

	self.Outputs = WireLib.CreateOutputs( self, { "link [WIRELINK]" } )
	WireLib.TriggerOutput( self, "link", self )

	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false

	self.TopLeft = false
end

function ENT:SetEGPOwner( ply )
	self.ply = ply
	self.plyID = ply:UniqueID()
end

function ENT:GetEGPOwner()
	if (!self.ply or !self.ply:IsValid()) then
		local ply = player.GetByUniqueID( self.plyID )
		if (ply) then self.ply = ply end
		return ply
	else
		return self.ply
	end
	return false
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
