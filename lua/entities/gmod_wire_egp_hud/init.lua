AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("huddraw.lua")
include("huddraw.lua")

DEFINE_BASECLASS("base_wire_entity")

ENT.WireDebugName = "E2 Graphics Processor HUD"

util.AddNetworkString("EGP_HUD_Use")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.RenderTable = {}
	self.Users = {}
	self.IsEGPHUD = true

	self:SetResolution(false)

	self:SetUseType(SIMPLE_USE)
	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )

	WireLib.CreateInputs(self, {
		"0 to 512 (If enabled, changes the resolution of the egp hud to be between 0 and 512 instead of the user's monitor's resolution.\nWill cause objects to look stretched out on most screens, so your UI will need to be designed with this in mind.\nIt's recommended to use the egpScrW, egpScrH, and egpScrSize functions instead.)",
		"Vehicles (Links all vehicles of passed array to this egp HUD) [ARRAY]",
	})

	WireLib.CreateOutputs(self, { "wirelink [WIRELINK]" })

	WireLib.TriggerOutput(self, "wirelink", self)

	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false

	self.TopLeft = false
end

function ENT:TriggerInput( name, value )
	if (name == "0 to 512") then
		self:SetResolution(value ~= 0)
	elseif name == "Vehicles" then
		for k, v in ipairs( value ) do
			if( TypeID(v) ~= TYPE_ENTITY ) then continue end
			if( not IsValid(v) ) then continue end
			self:LinkEnt( v )
		end
	end
end

function ENT:Use(ply)
	EGP.EGPHudConnect(self, not self.Users[ply], ply)
end

function ENT:SetEGPOwner(ply)
	self.ply = ply
	self.plyID = ply:AccountID()
end

function ENT:GetEGPOwner()
	if not self.ply or not self.ply:IsValid() then
		local ply = player.GetByAccountID(self.plyID)
		if ply then self.ply = ply end
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
