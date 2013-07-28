ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Forcer"

function ENT:SetForceBeam(on)
    self:SetNetworkedBool("ForceBeam",on,true)
end

function ENT:GetForceBeam()
    return self:GetNetworkedBool("ForceBeam")
end

function ENT:SetBeamLength(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end
