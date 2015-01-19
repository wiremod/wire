E2Lib.RegisterExtension("effects",false)

registerType("effect", "ef", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		local _type = type(retval)
		if _type~="CEffectData" then error("Return value is neither nil nor a CEffectData, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v)~="CEffectData"
	end
)

__e2setcost(1)

registerOperator("ass", "ef", "ef", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)

	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)
                
e2function effect effect()
	return EffectData()
end

e2function effect effect:setOrigin(vector pos)
	if not this then return end
	
	this:SetOrigin(Vector( pos[1], pos[2], pos[3] ))
	return this
end

e2function effect effect:setStart(vector pos)
	if not this then return end
	
	this:SetStart(Vector( pos[1], pos[2], pos[3] ))
	return this
end

e2function effect effect:setMagnitude(number mag)
	if not this then return end
	
	this:SetMagnitude(mag)
	return this
end

e2function effect effect:setAngles(angle ang)
	if not this then return end
	
	this:SetAngles(ang)
	return this
end

e2function effect effect:setScale(number scale)
	if not this then return end
	
	this:SetScale(scale)
	return this
end

e2function effect effect:setEntity(entity ent)
	if not this then return end
	if not IsValid(ent) then return end
	
	this:SetEntity(ent)
	return this
end

e2function effect effect:setNormal(vector norm)
	if not this then return end
	
	this:SetNormal(Vector( norm[1], norm[2], norm[3] ))
	return this
end

e2function effect effect:setSurfaceProp(number prop)
	if not this then return end
	
	this:SetSurfaceProp(prop)
	return this
end

e2function effect effect:setRadius(number radius)
	if not this then return end
	
	this:SetRadius(radius)
	return this
end

e2function effect effect:setMaterialIndex(number index)
	if not this then return end
	
	this:SetMaterialIndex(index)
	return this
end

e2function effect effect:setHitBox(number index)
	if not this then return end
	
	this:SetHitBox(index)
	return this
end

e2function effect effect:setFlags(number flags)
	if not this then return end
	
	this:SetFlags(flags)
	return this
end

e2function effect effect:setEntIndex(number index)
	if not this then return end
	
	this:SetEntIndex(index)
	return this
end

e2function effect effect:setDamageType(number index)
	if not this then return end
	
	this:SetDamageType(index)
	return this
end

e2function effect effect:setColor(number index)
	if not this then return end
	index = math.Clamp(index,0,255)
	this:SetColor(index)
	return this
end

e2function effect effect:setAttachment(number index)
	if not this then return end
	
	this:SetAttachment(index)
	return this
end

e2function void effect:play(string name)
	if not this then return end
	
	util.Effect(name,this,false)
end
