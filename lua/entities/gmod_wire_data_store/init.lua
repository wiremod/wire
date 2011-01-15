
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Data Store"


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Values = {};
	self.Values["A"] = 0
	self.Values["B"] = 0
	self.Values["C"] = 0
	self.Values["D"] = 0
	self.Values["E"] = 0
	self.Values["F"] = 0
	self.Values["G"] = 0
	self.Values["H"] = 0
	self:ShowOutput()
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Think()
end

function ENT:Setup()
end

function ENT:ShowOutput()
	self:SetOverlayText( "Data Store" )
end

function ENT:OnRestore()
    Wire_Restored(self)
end

