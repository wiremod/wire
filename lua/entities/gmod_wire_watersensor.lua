AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Water Sensor"
ENT.WireDebugName 	= "Water Sensor"
ENT.RenderGroup		= RENDERGROUP_BOTH

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, {"Out"})
end

function ENT:ShowOutput()
	self:SetOverlayText( (self:WaterLevel()>0) and "Submerged" or "Above Water" )
end

function ENT:Think()
	self.BaseClass.Think(self)
	if(self:WaterLevel()>0)then
		Wire_TriggerOutput(self,"Out",1)
	else
		Wire_TriggerOutput(self,"Out",0)
	end
	self:ShowOutput()
	self:NextThink(CurTime()+0.125)
end

function MakeWireWaterSensor( pl, Pos, Ang, model )
	if ( !pl:CheckLimit( "wire_watersensors" ) ) then return false end

	local wire_watersensor = ents.Create( "gmod_wire_watersensor" )
	if (!wire_watersensor:IsValid()) then return false end

	wire_watersensor:SetAngles( Ang )
	wire_watersensor:SetPos( Pos )
	wire_watersensor:SetModel( Model(model or "models/jaanus/wiretool/wiretool_range.mdl") )
	wire_watersensor:Spawn()

	wire_watersensor:SetPlayer( pl )
	wire_watersensor.pl = pl

	pl:AddCount( "wire_watersensors", wire_watersensor )

	return wire_watersensor
end
duplicator.RegisterEntityClass("gmod_wire_watersensor", MakeWireWaterSensor, "Pos", "Ang", "Model")
