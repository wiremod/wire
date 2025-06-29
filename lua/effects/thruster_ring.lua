function EFFECT:Init(data)
	self:SetCollisionBounds(Vector(-16, -16, -16), Vector(16, 16, 16))

	local origin, normal = data:GetOrigin(), data:GetNormal()
	self:SetPos(origin + normal * 2)

	self.Size = 16
	self.Normal = normal
	self.Alpha = 255
	self.GrowthRate = data:GetMagnitude()
end

function EFFECT:Think()
	local speed = FrameTime() * 2
	local alpha = self.Alpha - 250 * speed
	if alpha <= 0 then return false end

	self.Alpha = alpha
	self.Size = self.Size + (255 - alpha) * self.GrowthRate
	self:SetPos(self:GetPos() + self.Normal * (speed * 128))

	return true
end

local ring = Material("effects/select_ring")

function EFFECT:Render()
	render.SetMaterial(ring)
	render.DrawQuadEasy(self:GetPos(), self.Normal, self.Size, self.Size, Color(math.random(10, 100), math.random(100, 220), math.random(240, 255), self.Alpha))
end
