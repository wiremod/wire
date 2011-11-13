include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

local enabled = false
local eyeAng = Angle(0,0,0)
local previousEnabled = false
local rotate90 = false

usermessage.Hook("UpdateEyePodState", function(um)
	if not um then return end
	enabled = um:ReadBool()
	rotate90 = um:ReadBool()
	eyeAng = um:ReadAngle()
end)

hook.Add("CreateMove", "WireEyePodEyeControl", function(ucmd)
	if enabled then
		ucmd:SetViewAngles(eyeAng)
		previousEnabled = true
	elseif previousEnabled then
		if rotate90 then
			ucmd:SetViewAngles(Angle(0,90,0))
		else
			ucmd:SetViewAngles(Angle(0,0,0))
		end
		previousEnabled = false
	end
end)
