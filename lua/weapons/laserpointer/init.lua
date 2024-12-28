AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.Weight = 8
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Receiver = nil
SWEP.Pointing = false

function SWEP:Initialize()
	self.Pointing = false
end

function SWEP:Equip(newOwner)
	if IsValid(newOwner.LasReceiver) then
		self.Receiver = newOwner.LasReceiver
		newOwner.LasReceiver = nil
		newOwner:PrintMessage(HUD_PRINTTALK, "Relinked Sucessfully")
	end
end

function SWEP:PrimaryAttack()
	self.Pointing = not self.Pointing
	self:SetLaserEnabled(self.Pointing)

	if self.Pointing and IsValid(self.Receiver) then
		Wire_TriggerOutput(self.Receiver,"Active", 1)
	else
		Wire_TriggerOutput(self.Receiver,"Active", 0)
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local trace = owner:GetEyeTrace()

	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_las_receiver" and gamemode.Call("CanTool", owner, trace, "wire_las_receiver") then
		self.Receiver = trace.Entity
		owner:PrintMessage(HUD_PRINTTALK, "Linked Sucessfully")

		return true
	end
end

function SWEP:Think()
	if self.Pointing and IsValid(self.Receiver) then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local trace

		if IsValid(owner) then
			trace = owner:GetEyeTrace()
		else
			local att = self:GetAttachment(self:LookupAttachment("muzzle"))
			trace = util.TraceLine({ start = att.Pos, endpos = att.Pos + att.Ang:Forward() * 16384, filter = self })
		end

		local point = trace.HitPos

		Wire_TriggerOutput(self.Receiver, "X", point.x)
		Wire_TriggerOutput(self.Receiver, "Y", point.y)
		Wire_TriggerOutput(self.Receiver, "Z", point.z)
		Wire_TriggerOutput(self.Receiver, "Pos", point)
		Wire_TriggerOutput(self.Receiver, "RangerData", trace)

		self.Receiver.VPos = point
	end
end
