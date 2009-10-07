/******************************************************************************\
  Player-weapon support
\******************************************************************************/

__e2setcost(2) -- temporary

registerFunction("weapon", "e:", "e", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return nil end
	if(rv1:IsPlayer() or rv1:IsNPC()) then return rv1:GetActiveWeapon() else return nil end
end)


registerFunction("primaryAmmoType", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(rv1:IsWeapon()) then return rv1:GetPrimaryAmmoType() else return "" end
end)

registerFunction("secondaryAmmoType", "e:", "s", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return "" end
	if(rv1:IsWeapon()) then return rv1:GetSecondaryAmmoType() else return "" end
end)

registerFunction("ammoCount", "e:s", "n", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsPlayer()) then return rv1:GetAmmoCount(rv2) else return 0 end
end)

registerFunction("clip1", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsWeapon()) then return rv1:Clip1() else return 0 end
end)

registerFunction("clip2", "e:", "n", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self, op1)
	if(!validEntity(rv1)) then return 0 end
	if(rv1:IsWeapon()) then return rv1:Clip2() else return 0 end
end)

__e2setcost(nil) -- temporary
