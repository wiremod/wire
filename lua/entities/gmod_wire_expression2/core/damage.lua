E2Lib.RegisterExtension("damage", true, "Lets E2 chips trigger on entity damage, and cause damage if wire_expression2_damage_enabled is set to 1.")

local M_CTakeDamageInfo = FindMetaTable("CTakeDamageInfo")

registerType("damage", "xdm", nil,
	nil, nil,
	nil,
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

__e2setcost(1)

e2function number operator_is(damage dmg)
	return dmg and 1 or 0
end

[nodiscard]
e2function number damage:isType(number type)
	return this:IsDamageType(type) and 1 or 0
end

[nodiscard]
e2function number damage:getAmount()
	return this:GetDamage()
end

[nodiscard]
e2function vector damage:getPosition()
	return this:GetDamagePosition()
end

[nodiscard]
e2function vector damage:getForce()
	return this:GetDamageForce()
end

[nodiscard]
e2function entity damage:getInflictor()
	return this:GetInflictor()
end

[nodiscard]
e2function entity damage:getAttacker()
	return this:GetAttacker()
end

[nodiscard]
e2function number damage:getAmmoType()
	return this:GetAmmoType()
end

local Enabled = CreateConVar("wire_expression2_damage_enabled", 0, FCVAR_ARCHIVE, "Whether to enable causing damage in the E2 'damage' extension.")
local MaxRadius = CreateConVar("wire_expression2_damage_maxradius", 2000, FCVAR_ARCHIVE, "Maximum radius able to be applied with the blastDamage E2 function.")

__e2setcost(20)

e2function void entity:takeDamage(number amount)
	if not Enabled:GetBool() then return self:throw("Dealing damage is disabled via wire_expression2_damage_enabled") end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not WireLib.CanDamage(self.player, this) then return self:throw("You cannot damage this entity!", nil) end

	this:TakeDamage(amount, self.player, self.entity)
end

e2function void entity:takeDamage(number amount, entity attacker)
	if not Enabled:GetBool() then return self:throw("Dealing damage is disabled via wire_expression2_damage_enabled") end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not IsValid(attacker) then return self:throw("Invalid attacker entity!", nil) end
	if not E2Lib.isOwner(attacker) then return self:throw("You do not own the attacker entity!", nil) end
	if not WireLib.CanDamage(self.player, this) then return self:throw("You cannot damage this entity!", nil) end

	this:TakeDamage(amount, attacker, self.entity)
end

e2function void entity:takeDamage(number amount, entity attacker, entity inflictor)
	if not Enabled:GetBool() then return self:throw("Dealing damage is disabled via wire_expression2_damage_enabled") end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not IsValid(attacker) then return self:throw("Invalid attacker entity!", nil) end
	if not E2Lib.isOwner(attacker) then return self:throw("You do not own the attacker entity!", nil) end
	if not IsValid(inflictor) then return self:throw("Invalid inflictor entity!", nil) end
	if not E2Lib.isOwner(inflictor) then return self:throw("You do not own the inflictor entity!", nil) end
	if not WireLib.CanDamage(self.player, this) then self:throw("You cannot damage this entity!", nil) end

	this:TakeDamage(amount, attacker, inflictor)
end

__e2setcost(10)

e2function void blastDamage(vector origin, number radius, number damage)
	if not Enabled:GetBool() then return self:throw("Dealing damage is disabled via wire_expression2_damage_enabled") end
	util.BlastDamage(self.entity, self.player, origin, math.Clamp(radius, 0, MaxRadius:GetInt()), damage)
end

E2Lib.registerEvent("entityDamage", {
	{ "Victim", "e" },
	{ "Damage", "xdm" }
})

hook.Add("PostEntityTakeDamage", "E2_entityDamage", function(victim, dmg)
	E2Lib.triggerEvent("entityDamage", { victim, dmg })
end)
