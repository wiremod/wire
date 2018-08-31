AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Weight"
ENT.WireDebugName 	= "Weight"

if CLIENT then return end -- No more client

local MODEL = Model("models/props_interiors/pot01a.mdl")

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self,{"Weight"})
	self.Outputs = Wire_CreateOutputs(self,{"Weight"})
	self:ShowOutput(self:GetPhysicsObject():GetMass())
end

function ENT:TriggerInput(iname,value)
	if(value>0)then
		value = math.Clamp(value, 0.001, 50000)
		local phys = self:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:SetMass(value)
			phys:Wake()
			self:ShowOutput(value)
			Wire_TriggerOutput(self,"Weight",value)
		end
	end
	return true
end

function ENT:Think()
	BaseClass.Think(self)
end

function ENT:Setup()
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Weight: "..tostring(value) )
end

duplicator.RegisterEntityClass("gmod_wire_weight", WireLib.MakeWireEnt, "Data")
