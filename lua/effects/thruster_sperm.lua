function EFFECT:Init(data)
	self:SetCollisionBounds(Vector(-16, -16, -16), Vector(16, 16, 16))

	local origin, normal = data:GetOrigin(), data:GetNormal()
	self:SetPos(origin + normal * 2)

	self.Pos = origin
	self.Normal = normal
	self.Speed = 2
	self.Alpha = 255
end

function EFFECT:Think()
	local speed = FrameTime() * self.Speed

	local alpha = self.Alpha - 250 * speed
	if alpha <= 0 then return false end

	self.Alpha = alpha
	self:SetPos(self:GetPos() + self.Normal * (speed * 128))

	return true
end

local normal_offset = Angle(0, 90, 90)
local sperm = Material("thrusteraddon/sperm")

function EFFECT:Render()
	render.SetMaterial(sperm)

	local normal = self:GetAngles():Forward()
	normal:Add(normal_offset)

	render.DrawQuadEasy(self:GetPos(), normal, 16, 16, Color(255, 255, 255, self.Alpha))
end
