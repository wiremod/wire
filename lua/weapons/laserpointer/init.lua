AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function SWEP:Equip(newOwner)
	if IsValid(newOwner.LasReceiver) then
		self.Receiver = newOwner.LasReceiver
		newOwner.LasReceiver = nil
		newOwner:PrintMessage(HUD_PRINTTALK, "Relinked Successfully!")
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