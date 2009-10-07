
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Data Store"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
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
	Wire_Remove(self.Entity)
end

function ENT:Think()
end

function ENT:Setup()
end

function ENT:ShowOutput()
	self:SetOverlayText( "Data Store" )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

