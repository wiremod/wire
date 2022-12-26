AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Satellite Dish"
ENT.WireDebugName = "Satellite Dish"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:ShowOutput()
end

function ENT:LinkEnt( transmitter )
	if not IsValid(transmitter) or transmitter:GetClass() ~= "gmod_wire_data_transferer" then
		return false, "Satellite Dishes can only be linked to Wire Data Transferers!"
	end
	self.Transmitter = transmitter
	self:ShowOutput()
	WireLib.SendMarks(self, {transmitter})
	return true
end
function ENT:UnlinkEnt()
	self.Transmitter = nil
	self:ShowOutput()
	WireLib.SendMarks(self, {})
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText( IsValid(self.Transmitter) and "Linked" or "Unlinked" )
end

duplicator.RegisterEntityClass("gmod_wire_data_satellitedish", WireLib.MakeWireEnt, "Data")

function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Transmitter ) then
	    info.Transmitter = self.Transmitter:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Transmitter = GetEntByID(info.Transmitter)
	self:ShowOutput()
end
