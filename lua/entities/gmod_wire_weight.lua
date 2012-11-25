AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Weight"
ENT.WireDebugName 	= "Weight"
ENT.RenderGroup		= RENDERGROUP_BOTH

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
	self.BaseClass.Think(self)
end

function ENT:Setup()
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Weight: "..tostring(value) )
end


function MakeWireWeight( pl, Pos, Ang, model, frozen )
	if ( !pl:CheckLimit( "wire_weights" ) ) then return false end

	local wire_weight = ents.Create( "gmod_wire_weight" )
	if (!wire_weight:IsValid()) then return false end

	wire_weight:SetAngles( Ang )
	wire_weight:SetPos( Pos )
	wire_weight:SetModel( Model(model or MODEL) )
	wire_weight:Spawn()

	if wire_weight:GetPhysicsObject():IsValid() then
		wire_weight:GetPhysicsObject():EnableMotion(!frozen)
	end

	wire_weight:SetPlayer( pl )
	wire_weight.pl = pl

	pl:AddCount( "wire_weights", wire_weight )
	pl:AddCleanup( "gmod_wire_weight", wire_weight )

	return wire_weight
end
duplicator.RegisterEntityClass("gmod_wire_weight", MakeWireWeight, "Pos", "Ang", "Model", "frozen")
