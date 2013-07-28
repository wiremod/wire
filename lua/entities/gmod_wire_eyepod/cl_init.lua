include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

local enabled = false
local rotate90 = false
local freezePitch = true
local freezeYaw = true

local previousEnabled = false

usermessage.Hook("UpdateEyePodState", function(um)
	if not um then return end

	local eyeAng = um:ReadAngle()
	enabled = um:ReadBool()
	rotate90 = um:ReadBool()
	freezePitch = um:ReadBool() and eyeAng.p
	freezeYaw = um:ReadBool() and eyeAng.y
end)

hook.Add("CreateMove", "WireEyePodEyeControl", function(ucmd)
	if enabled then
		currentAng = ucmd:GetViewAngles()

		if freezePitch then
			currentAng.p = freezePitch
		end

		if freezeYaw then
			currentAng.y = freezeYaw
		end

		currentAng.r = 0

		ucmd:SetViewAngles(currentAng)
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
