E2Lib.RegisterExtension("damage", false, "Lets E2 chips trigger on entity damage, and in the future, cause damage.")

local M_CTakeDamageInfo = FindMetaTable("CTakeDamageInfo")

registerType("damage", "xdm", nil,
	nil, nil,
	function(retval)
		if retval == nil then return end
		if not istable(retval) then error("Return value is neither nil nor a table, but a " .. type(retval) .. "!",0) end
		if getmetatable(retval) ~= M_CTakeDamageInfo then error("Return value is not a CTakeDamageInfo!", 0) end
	end,
	function(v)
		return not istable(v) or getmetatable(v) ~= M_CTakeDamageInfo
	end
)

E2Lib.registerConstant("DMG_GENERIC", DMG_GENERIC)
E2Lib.registerConstant("DMG_CRUSH", DMG_CRUSH)
E2Lib.registerConstant("DMG_BULLET", DMG_BULLET)
E2Lib.registerConstant("DMG_SLASH", DMG_SLASH)
E2Lib.registerConstant("DMG_BURN", DMG_BURN)
E2Lib.registerConstant("DMG_VEHICLE", DMG_VEHICLE)
E2Lib.registerConstant("DMG_FALL", DMG_FALL)
E2Lib.registerConstant("DMG_BLAST", DMG_BLAST)
E2Lib.registerConstant("DMG_CLUB", DMG_CLUB)
E2Lib.registerConstant("DMG_SHOCK", DMG_SHOCK)
E2Lib.registerConstant("DMG_SONIC", DMG_SONIC)
E2Lib.registerConstant("DMG_ENERGYBEAM", DMG_ENERGYBEAM)
E2Lib.registerConstant("DMG_PREVENT_PHYSICS_FORCE", DMG_PREVENT_PHYSICS_FORCE)
E2Lib.registerConstant("DMG_NEVERGIB", DMG_NEVERGIB)
E2Lib.registerConstant("DMG_ALWAYSGIB", DMG_ALWAYSGIB)
E2Lib.registerConstant("DMG_DROWN", DMG_DROWN)
E2Lib.registerConstant("DMG_PARALYZE", DMG_PARALYZE)
E2Lib.registerConstant("DMG_NERVEGAS", DMG_NERVEGAS)
E2Lib.registerConstant("DMG_POISON", DMG_POISON)
E2Lib.registerConstant("DMG_RADIATION", DMG_RADIATION)
E2Lib.registerConstant("DMG_DROWNRECOVER", DMG_DROWNRECOVER)
E2Lib.registerConstant("DMG_ACID", DMG_ACID)
E2Lib.registerConstant("DMG_SLOWBURN", DMG_SLOWBURN)
E2Lib.registerConstant("DMG_REMOVENORAGDOLL", DMG_REMOVENORAGDOLL)
E2Lib.registerConstant("DMG_PHYSGUN", DMG_PHYSGUN)
E2Lib.registerConstant("DMG_PLASMA", DMG_PLASMA)
E2Lib.registerConstant("DMG_AIRBOAT", DMG_AIRBOAT)
E2Lib.registerConstant("DMG_DISSOLVE", DMG_DISSOLVE)
E2Lib.registerConstant("DMG_BLAST_SURFACE", DMG_BLAST_SURFACE)
E2Lib.registerConstant("DMG_DIRECT", DMG_DIRECT)
E2Lib.registerConstant("DMG_BUCKSHOT", DMG_BUCKSHOT)
E2Lib.registerConstant("DMG_SNIPER", DMG_SNIPER)
E2Lib.registerConstant("DMG_MISSILEDEFENSE", DMG_MISSILEDEFENSE)

e2function number operator_is(damage dmg)
	return dmg and 1 or 0
end

e2function number damage:isType(number type)
	return this:IsDamageType(type) and 1 or 0
end

e2function number damage:getAmount()
	return this:GetDamage()
end

e2function vector damage:getPosition()
	return this:GetDamagePosition()
end

e2function vector damage:getForce()
	return this:GetDamageForce()
end

e2function entity damage:getInflictor()
	return this:GetInflictor()
end

e2function entity damage:getAttacker()
	return this:GetAttacker()
end

e2function number damage:getAmmoType()
	return this:GetAmmoType()
end

E2Lib.registerEvent("entityDamage", {
	{ "Victim", "e" },
	{ "Damage", "xdm" }
})

hook.Add("EntityTakeDamage", "E2_entityDamage", function(victim, dmg)
	E2Lib.triggerEvent("entityDamage", { victim, dmg })
end)