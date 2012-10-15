
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Laser Receiver"


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"X", "Y", "Z", "Active", "Pos", "RangerData"}, {"NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "RANGER"})
	self.VPos = Vector(0,0,0)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup()
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end

function ENT:OnRestore()
	Wire_Restored(self)
end

function playerDeath( victim, weapon, killer)
	if(victim:HasWeapon("laserPointer"))then
		local pointer = victim:GetWeapon("laserPointer")
		if(pointer && pointer:IsValid())then
			victim.LasReceiver = pointer.Receiver
		end
	end
end

hook.Add( "PlayerDeath", "laserMemory", playerDeath)
