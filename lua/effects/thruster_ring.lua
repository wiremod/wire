function EFFECT:Init(data)
	self:SetCollisionBounds(Vector(-16, -16, -16), Vector(16, 16, 16))

	local origin, normal = data:GetOrigin(), data:GetNormal()
	self:SetPos(origin + normal * 2)
	self:SetNormal(normal)

	self.Size = 16
	self.Alpha = 255
	self.GrowthRate = data:GetMagnitude()
end

function EFFECT:Think()
	local speed = FrameTime() * 2

	local alpha = self.Alpha - 250 * speed
	if alpha <= 0 then return false end

	local size = self.Size + (255 - alpha) * self.GrowthRate
	if size <= 0 then return false end

	self.Alpha = alpha
	self.Size = size
	self:SetPos(self:GetPos() + self:GetNormal() * (speed * 128))

	return true
end

local ring = Material("effects/select_ring")

function EFFECT:Render()
	render.SetMaterial(ring)
	render.DrawQuadEasy(self:GetPos(), self:GetAngles():Forward(), self.Size, self.Size, Color(math.random(10, 100), math.random(100, 220), math.random(240, 255), self.Alpha))
end
