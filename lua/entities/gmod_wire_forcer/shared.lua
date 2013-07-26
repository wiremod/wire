ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Forcer"

function ENT:SetBeamHighlight(on)
    self:SetNetworkedBool("BeamHighlight",on,true)
end

function ENT:GetBeamHighlight()
    return self:GetNetworkedBool("BeamHighlight")
end

function ENT:SetBeamLength(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end
