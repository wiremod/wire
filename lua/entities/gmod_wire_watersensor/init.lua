
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

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:TriggerInput(iname, value)
end

function ENT:ShowOutput()
	local text = "Water Sensor"
	if(self.Outputs["Out"])then
	   if(self.Outputs["Out"].Value>0)then
		   text = text .. "\nSubmerged!"
	   else
		   text = text.. "\nAbove Water"
	   end
	end
	self:SetOverlayText( text )
end

function ENT:OnRestore()
	Wire_Restored(self)
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
