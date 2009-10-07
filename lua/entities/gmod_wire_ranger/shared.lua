ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Ranger"
ENT.Author      = "Erkle"
ENT.Contact     = "ErkleMad@hotmail.com"


function ENT:SetSkewX(value)
	self.Entity:SetNetworkedFloat("SkewX", math.max(-1, math.min(value, 1)))
end

function ENT:SetSkewY(value)
	self.Entity:SetNetworkedFloat("SkewY", math.max(-1, math.min(value, 1)))
end


function ENT:GetSkewX()
	return self.Entity:GetNetworkedFloat("SkewX") or 0
end

function ENT:GetSkewY()
	return self.Entity:GetNetworkedFloat("SkewY") or 0
end


function ENT:SetBeamLength(length)
	self.Entity:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end
