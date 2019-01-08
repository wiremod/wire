AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("huddraw.lua")
include("huddraw.lua")

DEFINE_BASECLASS("base_wire_entity")

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

function ENT:LinkEnt( ent )
	ent = WireLib.GetClosestRealVehicle(ent,self:GetPos(),self:GetPlayer())

	if IsValid( ent ) and ent:IsVehicle() then
		if self.LinkedVehicles and self.LinkedVehicles[ent] then
			return false
		end

		EGP:LinkHUDToVehicle( self, ent )
		return true
	else
		return false, tostring(ent) .. " is invalid or is not a vehicle"
	end
end

function ENT:OnRemove()
	EGP:UnlinkHUDFromVehicle( self )
end

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	local vehicles = self.LinkedVehicles
	if vehicles then
		local _vehicles = {}
		for k,v in pairs( vehicles ) do
			_vehicles[#_vehicles+1] = k:EntIndex()
		end
		info.egp_hud_vehicles = _vehicles
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	local vehicles = info.egp_hud_vehicles
	if vehicles then
		for i=1,#vehicles do
			local vehicle = GetEntByID( vehicles[i] )

			if IsValid( vehicle ) then
				self:LinkEnt( vehicle )
			end
		end
	end
end
