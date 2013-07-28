
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include('shared.lua')

--handle overlay text client side instead (TAD2020)
function ENT:Think()
	self.BaseClass.Think(self)

	local model = self:GetModel()

	if model == "models/bull/various/gyroscope.mdl" then

        local lineOfNodes = self:WorldToLocal( ( Vector(0,0,1):Cross( self:GetUp() ) ):GetNormal( ) + self:GetPos() )

		self:SetPoseParameter( "rot_yaw"  ,  math.deg( math.atan2( lineOfNodes[2] , lineOfNodes[1] ) ) )
		self:SetPoseParameter( "rot_roll" , -math.deg( math.acos( self:GetUp():DotProduct( Vector(0,0,1) ) )  or 0 ) )
	end

    local ang = self:GetAngles()
	if (ang.p < 0 && !self:GetOut180()) then ang.p = ang.p + 360 end
	if (ang.y < 0 && !self:GetOut180()) then ang.y = ang.y + 360 end
	if (ang.r < 0 && !self:GetOut180()) then ang.r = ang.r + 360
	elseif (ang.r > 180 && self:GetOut180()) then ang.r = ang.r - 360 end
	self:ShowOutput(ang.p, ang.y, ang.r)

	self:NextThink(CurTime()+0.04)
	return true
end

function ENT:ShowOutput(p, y, r)
	self:SetOverlayText( "Angles = " .. math.Round(p*1000)/1000 .. "," .. math.Round(y*1000)/1000 .. "," .. math.Round(r*1000)/1000 )
end
