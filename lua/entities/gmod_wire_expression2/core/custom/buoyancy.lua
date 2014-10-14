e2function void entity:setBuoyancy( number perbuoy )
  if(IsValid(this)) then
    local phys = this:GetPhysicsObject()
    if(IsValid(phys)) then
      phys:Wake()
      phys:SetBuoyancyRatio( math.Clamp(perbuoy,0,100)/100)
    end
  end
end
