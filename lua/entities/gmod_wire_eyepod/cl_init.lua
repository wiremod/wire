
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

local EyePod = {}
EyePod.enabled = 0
EyePod.EyeAng = Angle(0,0,0)
EyePod.PreviousState = 0
EyePod.Rotate90 = false

local function UpdateEyePodState( UM )
	if(!UM) then return end
	EyePod.enabled = UM:ReadShort()
	EyePod.EyeAng = UM:ReadAngle()
	EyePod.Rotate90 = UM:ReadBool()
end
usermessage.Hook("UpdateEyePodState", UpdateEyePodState)

local function EyePodEyeControl(UCMD)
	if(EyePod.enabled == 1) then
		UCMD:SetViewAngles( EyePod.EyeAng )
		EyePod.PreviousState = 1
	elseif(EyePod.enabled == 0 and EyePod.PreviousState == 1) then
		if(EyePod.Rotate90 == true) then
			UCMD:SetViewAngles( Angle(0,90,0) )
		else
			UCMD:SetViewAngles( Angle(0,0,0) )
		end
		EyePod.PreviousState = 0
	end
end
hook.Add("CreateMove", "WireEyePodEyeControl", EyePodEyeControl)

