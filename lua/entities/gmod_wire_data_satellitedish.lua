AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Satellite Dish"
ENT.RenderGroup		= RENDERGROUP_OPAQUE
ENT.WireDebugName = "Satellite Dish"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:ShowOutput()
end

function ENT:ShowOutput()
	self:SetOverlayText( IsValid(self.Transmitter) and "Linked" or "Unlinked" )
end

duplicator.RegisterEntityClass("gmod_wire_data_satellitedish", WireLib.MakeWireEnt, "Data")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Transmitter ) then
	    info.Transmitter = self.Transmitter:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Transmitter = GetEntByID(info.Transmitter)
	self:ShowOutput()
end
