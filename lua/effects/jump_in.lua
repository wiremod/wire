function EFFECT:Init(data)
	local entity = data:GetEntity()
	if not entity:IsValid() then return end

	local low, high = entity:WorldSpaceAABB()
	local origin = data:GetOrigin()

	local emitter = ParticleEmitter(origin)

	for i = 0, math.Clamp(entity:BoundingRadius() * 2, 10, 500) do
		local particle = emitter:Add("effects/spark", origin)

		if particle then
			local velocity = Vector(math.Rand(low.x, high.x), math.Rand(low.y, high.y), math.Rand(low.z, high.z))
			velocity:Sub(origin)
			velocity:Mul(6)

			particle:SetVelocity(velocity)
			particle:SetLifeTime(0)
			particle:SetDieTime(math.Rand(0.1, 0.4))
			particle:SetStartAlpha(0)
			particle:SetEndAlpha(math.Rand(200, 255))
			particle:SetStartSize(0)
			particle:SetEndSize(20)
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
