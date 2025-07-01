function EFFECT:Init(data)
	local entity = data:GetEntity()
	if not entity:IsValid() then return end

	local low, high = entity:WorldSpaceAABB()
	local origin = data:GetOrigin()

	local emitter = ParticleEmitter(entity:GetPos())

	for i = 0, math.Clamp(entity:BoundingRadius() * 2, 10, 500) do
		local position = Vector(math.Rand(low.x, high.x), math.Rand(low.y, high.y), math.Rand(low.z, high.z))
		local particle = emitter:Add("effects/spark", position)

		if particle then
			position:Negate()
			position:Add(origin)
			position:Mul(6)

			particle:SetVelocity(position)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.1, 0.3))
			particle:SetStartAlpha(math.Rand(200, 255))
			particle:SetEndAlpha(0)
			particle:SetStartSize(20)
			particle:SetEndSize(0)
			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(0)
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
