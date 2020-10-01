AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

SWEP.Weight = 8
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Receiver = nil
SWEP.Active = false

function SWEP:Initialize()
	self.Active = false
end

function SWEP:Equip( newOwner )
	if not IsValid(newOwner.LasReceiver) then return end

	self.Receiver = newOwner.LasReceiver
	newOwner.LasReceiver = nil
	newOwner:PrintMessage( HUD_PRINTTALK, "Relinked Sucessfully" )
end

function SWEP:PrimaryAttack()
	self.Active = not self.Active

	local activeOutput = 0
	if self.Active and IsValid(self.Receiver) then activeOutput = 1 end

	self:TriggerOutput("Active", activeOutput)
end

function SWEP:SecondaryAttack()
	local aimTrace = self:GetBeamTrace()

	local receiver = aimTrace.Entity

	if not IsValid(receiver) then return end
	if receiver:GetClass() ~= "gmod_wire_las_receiver" then return end

	local canTool = gamemode.Call("CanTool", self.Wielder, aimTrace, "wire_las_receiver")
	if not canTool then return end

	self.Receiver = aimTrace.Entity
	self.Wielder:PrintMessage(HUD_PRINTTALK, "Linked Sucessfully")

	return true
end

function SWEP:OnDrop()
	self:TriggerOutput("Active", 0)
	self.Receiver = nil
end

function SWEP:TriggerOutput(name, value)
	Wire_TriggerOutput(self.Receiver, name, value)
end

function SWEP:Think()
	if not self.Active and self.Receiver and self.Receiver:IsValid() then return end

	local beamTrace = self:GetBeamTrace()
	local point = beamTrace.HitPos

	if COLOSSAL_SANDBOX then point = point * 6.25 end

	self:TriggerOutput("X", point.x)
	self:TriggerOutput("Y", point.y)
	self:TriggerOutput("Z", point.z)
	self:TriggerOutput("Pos", point)
	self:TriggerOutput("RangerData", beamTrace)
	self.Receiver.VPos = point
end
