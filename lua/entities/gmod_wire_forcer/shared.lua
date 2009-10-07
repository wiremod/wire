ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Forcer"

function ENT:SetForceBeam(on)
    self.Entity:SetNetworkedBool("ForceBeam",on,true)
end

function ENT:GetForceBeam()
    return self.Entity:GetNetworkedBool("ForceBeam")
end

function ENT:SetBeamLength(length)
	self.Entity:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end
