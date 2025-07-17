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
		local receiver = self.Receiver

		WireLib.TriggerOutput(receiver, "X", point.x)
		WireLib.TriggerOutput(receiver, "Y", point.y)
		WireLib.TriggerOutput(receiver, "Z", point.z)
		WireLib.TriggerOutput(receiver, "Pos", point)
		WireLib.TriggerOutput(receiver, "RangerData", trace)

		receiver.VPos = point
	end
end