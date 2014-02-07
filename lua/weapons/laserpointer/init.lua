AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

SWEP.Weight = 8
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Receiver = nil
SWEP.Pointing = false

function SWEP:Initialize()
	self.Pointing = false
end

function SWEP:Equip( newOwner )
	if IsValid(newOwner.LasReceiver) then
		self.Receiver = newOwner.LasReceiver
		newOwner.LasReceiver = nil
		newOwner:PrintMessage( HUD_PRINTTALK, "Relinked Sucessfully" )
	end
end

function SWEP:PrimaryAttack()
	self.Pointing = !self.Pointing
	self.Weapon:SetNWBool("Active", self.Pointing)
	if self.Pointing and IsValid(self.Receiver) then
		Wire_TriggerOutput(self.Receiver,"Active",1)
	else
		Wire_TriggerOutput(self.Receiver,"Active",0)
	end
end

function SWEP:SecondaryAttack()
	local trace = self:GetOwner():GetEyeTrace()

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_las_receiver" and gamemode.Call("CanTool", self:GetOwner(), trace, "wire_las_receiver") then
		self.Receiver = trace.Entity
		self:GetOwner():PrintMessage( HUD_PRINTTALK, "Linked Sucessfully" )
		return true
	end
end

function SWEP:Think()
	if(self.Pointing && self.Receiver && self.Receiver:IsValid())then
		local trace = self:GetOwner():GetEyeTrace()
		local point = trace.HitPos
		if (COLOSSAL_SANDBOX) then point = point * 6.25 end
		Wire_TriggerOutput(self.Receiver, "X", point.x)
		Wire_TriggerOutput(self.Receiver, "Y", point.y)
		Wire_TriggerOutput(self.Receiver, "Z", point.z)
		Wire_TriggerOutput(self.Receiver, "Pos", point)
		Wire_TriggerOutput(self.Receiver, "RangerData", trace)
		self.Receiver.VPos = point
	end
end
