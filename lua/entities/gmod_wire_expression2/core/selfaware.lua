/******************************************************************************\
  Selfaware support
\******************************************************************************/

__e2setcost(1) -- temporary

registerFunction("entity", "", "e", function(self, args)
	return self.entity
end)

registerFunction("owner", "", "e", function(self, args)
	return self.player
end)

__e2setcost(nil) -- temporary

registerFunction("setColor", "nnn", "", function(self, args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
	self.entity:SetColor(math.Clamp(rv1, 0, 255), math.Clamp(rv2, 0, 255), math.Clamp(rv3, 0, 255), 255)
end)

registerFunction("selfDestruct", "", "", function(self, args)
    self.entity:Remove()
end)

registerFunction("selfDestructAll", "", "", function(self, args)
    for k,v in pairs(constraint.GetAllConstrainedEntities(self.entity)) do
		if(getOwner(self,v)==self.player) then
			v:Remove()
		end
    end
    //constraint.RemoveAll(self.entity)
    self.entity:Remove()
end)

/******************************************************************************/

registerCallback("construct", function(self)
	self.data.changed = {}
end)

-- This is the prototype for everything that can be compared using the == operator
e2function number changed(value)
	local chg = self.data.changed

	if value == chg[args] then return 0 end

	chg[args] = value
	return 1
end

-- vectors can be of gmod type Vector, so we need to treat them separately
e2function number changed(vector value)
	local chg = self.data.changed

	local this_chg = chg[args]
	if not this_chg then
		chg[args] = value
		return 1
	end
	if this_chg
	and value[1] == this_chg[1]
	and value[2] == this_chg[2]
	and value[3] == this_chg[3]
	then return 0 end

	chg[args] = value
	return 1
end

-- This is the prototype for all table types.
e2function number changed(angle value)
	local chg = self.data.changed

	local this_chg = chg[args]
	if not this_chg then
		chg[args] = value
		return 1
	end
	for i,v in pairs(value) do
		if v ~= this_chg[i] then
			chg[args] = value
			return 1
		end
	end
	return 0
end

local excluded_types = {
	n = true,
	v = true,
	a = true,

	r = true,
	t = true,
}
local comparable_types = {
	s = true,
	e = true,
	xwl = true,
	b = true,
}

registerCallback("postinit", function()
	-- generate this function for all types
	for typeid,_ in pairs(wire_expression_types2) do
		if not excluded_types[typeid] then
			if comparable_types[typeid] then
				registerFunction("changed", typeid, "n", e2_changed_n)
			else
				registerFunction("changed", typeid, "n", e2_changed_a)
			end
		end
	end
end)
