
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include('shared.lua')


function ENT:Think()
	self.BaseClass.Think(self)

	local pos = self.Entity:GetPos()
	if (COLOSSAL_SANDBOX) then pos = pos * 6.25 end
	local txt = "Position = " .. math.Round(pos.x*1000)/1000 .. "," .. math.Round(pos.y*1000)/1000 .. "," .. math.Round(pos.z*1000)/1000

	self.Entity:SetNetworkedBeamString( "GModOverlayText", txt )
	//self.Entity:SetNetworkedString( "GModOverlayText", txt )
	--self.BaseClass.BaseClass.SetOverlayText( self, txt )

	self.Entity:NextThink(CurTime()+0.04)
	return true
end
