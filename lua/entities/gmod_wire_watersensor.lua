
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Water_Sensor"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, {"Out"})
end

function ENT:TriggerInput(iname, value)
end

function ENT:ShowOutput()
	local text
	if(self.Outputs["Out"])then
	   if(self.Outputs["Out"].Value>0)then
		   text = "Submerged!"
	   else
		   text = "Above Water"
	   end
	end
	self:SetOverlayText( text )
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
	if(!model) then
		wire_watersensor:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
	else
		wire_watersensor:SetModel( Model(model) )
	end
	wire_watersensor:Spawn()

	wire_watersensor:SetPlayer( pl )
	wire_watersensor.pl = pl

	pl:AddCount( "wire_watersensors", wire_watersensor )

	return wire_watersensor
end

duplicator.RegisterEntityClass("gmod_wire_watersensor", MakeWireWaterSensor, "Pos", "Ang", "Model")
