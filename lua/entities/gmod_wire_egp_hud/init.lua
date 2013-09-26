AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
AddCSLuaFile("HUDDraw.lua")
include("HUDDraw.lua")

ENT.WireDebugName = "E2 Graphics Processor HUD"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.RenderTable = {}

	self:SetUseType(SIMPLE_USE)

	self.Inputs = WireLib.CreateInputs( self, { "0 to 512" } )
	WireLib.CreateWirelinkOutput( nil, self, {true} )

	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false

	self.TopLeft = false
end

function ENT:TriggerInput( name, value )
	if (name == "0 to 512") then
		self:SetNWBool( "Resolution", value != 0 )
	end
end

function ENT:Use( ply )
	umsg.Start( "EGP_HUD_Use", ply ) umsg.Entity( self ) umsg.End()
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

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	local vehicle = self.LinkedVehicle
	if (vehicle) then
		info.egp_hud_vehicle = vehicle:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local vehicle = GetEntByID( info.egp_hud_vehicle )
	if IsValid(vehicle) then
		EGP:LinkHUDToVehicle( self, vehicle )
	end
end
