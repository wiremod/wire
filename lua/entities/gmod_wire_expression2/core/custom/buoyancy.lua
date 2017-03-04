e2function void entity:setBuoyancy( number perbuoy )
	if( not this or not this:IsValid() ) then return false end
	phys = this:GetPhysicsObject()
	if( phys and phys:IsValid()) then
		phys:SetBuoyancyRatio( math.Clamp(perbuoy,0,100)/100)
		phys:Wake()
	end
end
