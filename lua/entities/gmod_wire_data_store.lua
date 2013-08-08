AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Storer"
ENT.WireDebugName = "Data Store"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Values = {A=0, B=0, C=0, D=0, E=0, F=0, G=0, H=0}
end

duplicator.RegisterEntityClass("gmod_wire_data_store", WireLib.MakeWireEnt, "Data")
