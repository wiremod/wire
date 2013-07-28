ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Ranger"
ENT.Author      = "Erkle"
ENT.Contact     = "ErkleMad@hotmail.com"


function ENT:SetSkewX(value)
	self:SetNetworkedFloat("SkewX", math.max(-1, math.min(value, 1)))
end

function ENT:SetSkewY(value)
	self:SetNetworkedFloat("SkewY", math.max(-1, math.min(value, 1)))
end


function ENT:GetSkewX()
	return self:GetNetworkedFloat("SkewX") or 0
end

function ENT:GetSkewY()
	return self:GetNetworkedFloat("SkewY") or 0
end


function ENT:SetBeamLength(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end
