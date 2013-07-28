
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include('shared.lua')

--handle overlay text client side instead (TAD2020)
function ENT:Think()
	self.BaseClass.Think(self)

	local txt

	if (self:GetXYZMode()) then
	    local vel = self:WorldToLocal(self:GetVelocity()+self:GetPos())
		txt =  "Velocity = " .. math.Round((-vel.y or 0)*1000)/1000 .. "," .. math.Round((vel.x or 0)*1000)/1000 .. "," .. math.Round((vel.z or 0)*1000)/1000
	else
	    local vel = self:GetVelocity():Length()
		txt =  "Speed = " .. math.Round((vel or 0)*1000)/1000
	end

	--sadly self:GetPhysicsObject():GetAngleVelocity() does work client side, so read out is unlikely
	/*if (self:GetAngVel()) then
		local ang = self:GetPhysicsObject():GetAngleVelocity()
		txt = txt .. "\nAngVel = P " .. math.Round((ang.y or 0)*1000)/1000 .. ", Y " .. math.Round((ang.z or 0)*1000) /1000 .. ", R " .. math.Round((ang.x or 0)*1000)/1000
	end*/

	self:SetOverlayText( txt )

	self:NextThink(CurTime()+0.04)
	return true
end
