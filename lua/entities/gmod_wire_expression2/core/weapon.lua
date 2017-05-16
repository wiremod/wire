/******************************************************************************\
  Player-weapon support
\******************************************************************************/

__e2setcost(2) -- temporary

e2function entity entity:weapon()
	return IsValid(this) and (this:IsPlayer() or this:IsNPC()) and this:GetActiveWeapon() or NULL
end


e2function entity entity:weapon(string weaponclassname)
	return IsValid(this) and (this:IsPlayer() or this:IsNPC()) and this:GetWeapon(weaponclassname) or NULL
end


e2function string entity:primaryAmmoType()
	return IsValid(this) and this:IsWeapon() and tostring(this:GetPrimaryAmmoType()) or ""
end

e2function string entity:secondaryAmmoType()
	return IsValid(this) and this:IsWeapon() and tostring(this:GetSecondaryAmmoType()) or ""
end

e2function number entity:ammoCount(string ammo_type)
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end

	return this:GetAmmoCount(ammo_type)
end

e2function number entity:clip1()
	if not IsValid(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip1()
end

e2function number entity:clip2()
	if not IsValid(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip2()
end

e2function string entity:tool()
	if not IsValid(this) then return "" end
	if not this:IsPlayer() then return "" end

	local weapon = this:GetActiveWeapon()
	if not IsValid(weapon) then return "" end
	if weapon:GetClass() ~= "gmod_tool" then return "" end

	return weapon.Mode
end
