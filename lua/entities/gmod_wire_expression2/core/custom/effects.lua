E2Lib.RegisterExtension("effects", false, "Allows E2s to play arbitrary effects.")

local wire_expression2_effect_burst_max = CreateConVar("wire_expression2_effect_burst_max", 4, FCVAR_ARCHIVE)
local wire_expression2_effect_burst_rate = CreateConVar("wire_expression2_effect_burst_rate", 0.1, FCVAR_ARCHIVE)

-- Use hook Expression2_CanEffect to blacklist/whitelist effects
local effect_blacklist = {
	dof_node = true
}

local function isAllowed(self)
	return self.data.effect_burst >= 0
end

local function fire(self, this, name)
	local data = self.data

	data.effect_burst = data.effect_burst - 1

	local timerid = "E2_effect_burst_count_" .. self.entity:EntIndex()
	if not timer.Exists(timerid) then
		timer.Create(timerid, wire_expression2_effect_burst_rate:GetFloat(), 0, function()
			if not IsValid(self.entity) then
				timer.Remove(timerid)
				return
			end

			data.effect_burst = data.effect_burst + 1
			if data.effect_burst == wire_expression2_effect_burst_max:GetInt() then
				timer.Remove(timerid)
			end
		end)
	end

	util.Effect(name, this, true, true)
end

registerType("effect", "xef", nil,
	nil,
	nil,
	nil,
	function(v)
		return type(v)~="CEffectData"
	end
)

__e2setcost(1)

e2function effect effect()
	return EffectData()
end

e2function effect effect:setOrigin(vector pos)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetOrigin(pos)
	return this
end

e2function effect effect:setStart(vector pos)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetStart(pos)
	return this
end

e2function effect effect:setMagnitude(number mag)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetMagnitude(mag)
	return this
end

e2function effect effect:setAngles(angle ang)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetAngles(ang)
	return this
end

e2function effect effect:setScale(number scale)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetScale(scale)
	return this
end

e2function effect effect:setEntity(entity ent)
	if not this then return self:throw("Invalid effect!", nil) end
	if not IsValid(ent) then return self:throw("Invalid entity!", nil) end

	this:SetEntity(ent)
	return this
end

e2function effect effect:setNormal(vector norm)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetNormal(norm)
	return this
end

e2function effect effect:setSurfaceProp(number prop)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetSurfaceProp(prop)
	return this
end

e2function effect effect:setRadius(number radius)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetRadius(radius)
	return this
end

e2function effect effect:setMaterialIndex(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetMaterialIndex(index)
	return this
end

e2function effect effect:setHitBox(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetHitBox(index)
	return this
end

e2function effect effect:setFlags(number flags)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetFlags(flags)
	return this
end

e2function effect effect:setEntIndex(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetEntIndex(index)
	return this
end

e2function effect effect:setDamageType(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetDamageType(index)
	return this
end

e2function effect effect:setColor(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetColor(math.Clamp(index, 0, 255))
	return this
end

e2function effect effect:setAttachment(number index)
	if not this then return self:throw("Invalid effect!", nil) end

	this:SetAttachment(index)
	return this
end

e2function void effect:play(string name)
	if not this then return self:throw("Invalid effect!", nil) end
	if not isAllowed(self) then return self:throw("Effect play() burst limit reached!", nil) end

	name = name:lower()
	if effect_blacklist[name] then return self:throw("This effect is blacklisted!", nil) end
	if hook.Run("Expression2_CanEffect", name, self) == false then return self:throw("A hook prevented this function from running", nil) end

	fire(self, this, name)
end

e2function number effectCanPlay()
	return isAllowed(self) and 1 or 0
end

e2function number effectCanPlay(string name)
	if not isAllowed(self) then return 0 end
	if effect_blacklist[name] then return 0 end
	if hook.Run("Expression2_CanEffect", name:lower(), self) == false then return 0 end

	return 1
end

registerCallback("construct", function(self)
	self.data.effect_burst = wire_expression2_effect_burst_max:GetInt()
end)
