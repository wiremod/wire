/******************************************************************************\
  Player-weapon support
\******************************************************************************/

__e2setcost(2) -- temporary

e2function entity entity:weapon()
	if not validEntity(this) then return nil end
	if not this:IsPlayer() and not this:IsNPC() then return nil end

	return this:GetActiveWeapon()
end


e2function string entity:primaryAmmoType()
	if not validEntity(this) then return "" end
	if not this:IsWeapon() then return "" end

	return this:GetPrimaryAmmoType()
end

e2function string entity:secondaryAmmoType()
	if not validEntity(this) then return "" end
	if not this:IsWeapon() then return "" end

	return this:GetSecondaryAmmoType()
end

e2function number entity:ammoCount(string ammo_type)
	if not validEntity(this) then return 0 end
	if not this:IsPlayer() then return 0 end

	return this:GetAmmoCount(ammo_type)
end

e2function number entity:clip1()
	if not validEntity(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip1()
end

e2function number entity:clip2()
	if not validEntity(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip2()
end

e2function string entity:tool()
	if not validEntity(this) then return "" end
	if not this:IsPlayer() then return "" end

	local weapon = this:GetActiveWeapon()
	if not validEntity(weapon) then return "" end
	if weapon:GetClass() ~= "gmod_tool" then return "" end

	return weapon.Mode
end

__e2setcost(nil) -- temporary

