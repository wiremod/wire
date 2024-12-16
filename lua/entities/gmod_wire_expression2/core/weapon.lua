--[[----------------------------------------------------------------------------
  Player-weapon support
------------------------------------------------------------------------------]]

local CanTool = WireLib.CanTool
local isFriend = E2Lib.isFriend

local setAmmoCVar = CreateConVar("wire_expression2_weapon_ammo_set_enable", 0, FCVAR_ARCHIVE, "Whether or not to allow E2s to set ammo for weapons and players")
local giveAmmoCVar = CreateConVar("wire_expression2_weapon_ammo_give_enable", 0, FCVAR_ARCHIVE, "Whether or not to allow E2s to give ammo to players")
local giveWeaponCVar = CreateConVar("wire_expression2_weapon_give_enable", 0, FCVAR_ARCHIVE, "Whether or not to allow E2s to give weapons to players")
local stripWeaponCVar = CreateConVar("wire_expression2_weapon_strip_enable", 0, FCVAR_ARCHIVE, "Whether or not to allow E2s to strip weapons from players")

__e2setcost(2) -- temporary

[nodiscard]
e2function entity entity:weapon()
	if not IsValid(this) then return nil end
	if not this:IsPlayer() and not this:IsNPC() then return nil end

	return this:GetActiveWeapon()
end

[nodiscard]
e2function entity entity:weapon(string weaponclassname)
	if not IsValid(this) then return nil end
	if not this:IsPlayer() and not this:IsNPC() then return nil end

	return this:GetWeapon(weaponclassname)
end

[nodiscard]
e2function number entity:hasWeapon(string classname)
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", 0) end

	return this:HasWeapon(classname) and 1 or 0
end

[nodiscard]
e2function array entity:weapons()
	if not IsValid(this) then return {} end
	if not this:IsPlayer() then return {} end
	return this:GetWeapons()
end

[nodiscard]
e2function string entity:primaryAmmoType()
	if not IsValid(this) then return "" end
	if not this:IsWeapon() then return "" end

	local ammoId = this:GetPrimaryAmmoType()

	return game.GetAmmoName(ammoId) or ""
end

[nodiscard]
e2function string entity:secondaryAmmoType()
	if not IsValid(this) then return "" end
	if not this:IsWeapon() then return "" end

	local ammoId = this:GetSecondaryAmmoType()

	return game.GetAmmoName(ammoId) or ""
end

[nodiscard]
e2function number entity:ammoCount(string ammo_type)
	if not IsValid(this) then return 0 end
	if not this:IsPlayer() then return 0 end

	return this:GetAmmoCount(ammo_type)
end

[nodiscard]
e2function number entity:clip1()
	if not IsValid(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip1()
end

[nodiscard]
e2function number entity:clip1Size()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsWeapon() then return self:throw("Expected a Weapon but got Entity", 0) end

	return this:GetMaxClip1()
end

e2function number entity:setClip1(amount)
	if not setAmmoCVar:GetBool() then return self:throw("The server has disabled setting ammo", 0) end
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsWeapon() then return self:throw("Expected a Weapon but got Entity", 0) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this weapon", 0) end

	return this:SetClip1(amount)
end

[nodiscard]
e2function number entity:clip2()
	if not IsValid(this) then return 0 end
	if not this:IsWeapon() then return 0 end

	return this:Clip2()
end

[nodiscard]
e2function number entity:clip2Size()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsWeapon() then return self:throw("Expected a Weapon but got Entity", 0) end

	return this:GetMaxClip2()
end

e2function number entity:setClip2(amount)
	if not setAmmoCVar:GetBool() then return self:throw("The server has disabled setting ammo", 0) end
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsWeapon() then return self:throw("Expected a Weapon but got Entity", 0) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this weapon", 0) end

	return this:SetClip2(amount)
end

[nodiscard]
e2function string entity:tool()
	if not IsValid(this) then return "" end
	if not this:IsPlayer() then return "" end

	local weapon = this:GetActiveWeapon()
	if not IsValid(weapon) then return "" end
	if weapon:GetClass() ~= "gmod_tool" then return "" end

	return weapon.Mode
end

local function checkGive(self, target, classname)
	if not giveWeaponCVar:GetBool() then return self:throw("The server has disabled giving weapons", false) end
	if not IsValid(target) then return self:throw("Invalid entity!", false) end
	if not target:IsPlayer() then return self:throw("Expected a Player but got Entity", false) end
	if not isFriend(self.player, target) and not CanTool(self.player, target, "wire_expression2") then return self:throw("You cannot target this player", false) end
	if not list.HasEntry("Weapon", classname) then return self:throw("Invalid weapon class '" .. classname .. "'", false) end
	if hook.Run("PlayerGiveSWEP", target, classname, list.Get("Weapon")[classname]) == false then
		return self:throw("The server blocked the weapon from being given", false)
	end

	return true
end

e2function entity entity:giveWeapon(string classname)
	if not checkGive(self, this, classname) then return NULL end

	return this:Give(classname)
end

e2function entity entity:giveWeapon(string classname, noAmmo)
	if not checkGive(self, this, classname) then return NULL end

	return this:Give(classname, noAmmo ~= 0)
end

e2function void entity:selectWeapon(string classname)
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end
	if not list.HasEntry("Weapon", classname) then return self:throw("Invalid weapon class '" .. classname .. "'", nil) end

	this:SelectWeapon(classname)
end

e2function number entity:giveAmmo(amount, string type)
	if not giveAmmoCVar:GetBool() then return self:throw("The server has disabled giving ammo", 0) end
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", 0) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", 0) end
	if not table.HasValue(game.GetAmmoTypes(), type) then return self:throw("Invalid ammo type: '" .. type .. "'", -1) end

	return this:GiveAmmo(amount, type)
end

e2function number entity:giveAmmo(amount, string type, hidePopUp)
	if not giveAmmoCVar:GetBool() then return self:throw("The server has disabled giving ammo", 0) end
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", 0) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", 0) end
	if not table.HasValue(game.GetAmmoTypes(), type) then return self:throw("Invalid ammo type: '" .. type .. "'", -1) end

	return this:GiveAmmo(amount, type, hidePopUp ~= 0)
end

e2function void entity:setAmmo(ammoCount, string type)
	if not setAmmoCVar:GetBool() then return self:throw("The server has disabled setting ammo", 0) end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end
	if not table.HasValue(game.GetAmmoTypes(), type) then return self:throw("Invalid ammo type: '" .. type .. "'", nil) end

	this:SetAmmo(ammoCount, type)
end

e2function void entity:removeAmmo(ammoCount, string type)
	if not setAmmoCVar:GetBool() then return self:throw("The server has disabled setting ammo", nil) end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end
	if not table.HasValue(game.GetAmmoTypes(), type) then return self:throw("Invalid ammo type: '" .. type .. "'", nil) end

	this:RemoveAmmo(ammoCount, type)
end

e2function void entity:removeAllAmmo()
	if not setAmmoCVar:GetBool() then return self:throw("The server has disabled setting ammo", nil) end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end

	this:RemoveAllAmmo()
end

e2function void entity:stripWeapon(string classname)
	if not stripWeaponCVar:GetBool() then return self:throw("The server has disabled stripping weapons", nil) end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end
	if not list.HasEntry("Weapon", classname) then return self:throw("Invalid weapon class '" .. classname .. "'", nil) end

	this:StripWeapon(classname)
end

e2function void entity:stripWeapons()
	if not stripWeaponCVar:GetBool() then return self:throw("The server has disabled stripping weapons", nil) end
	if not IsValid(this) then return self:throw("Invalid entity!", nil) end
	if not this:IsPlayer() then return self:throw("Expected a Player but got Entity", nil) end
	if not isFriend(self.player, this) and not CanTool(self.player, this, "wire_expression2") then return self:throw("You cannot target this player", nil) end

	this:StripWeapons()
end

E2Lib.registerEvent("weaponPickup", {
	{ "Weapon", "e" },
	{ "Owner", "e" }
})

hook.Add("WeaponEquip", "E2_weaponPickup", function(weapon, owner)
	E2Lib.triggerEvent("weaponPickup", { weapon, owner })
end)

E2Lib.registerEvent("weaponSwitched", {
	{ "Player", "e" },
	{ "OldWeapon", "e" },
	{ "NewWeapon", "e" }
})

hook.Add("PlayerSwitchWeapon", "E2_weaponSwitched", function(player, oldWeapon, newWeapon)
	E2Lib.triggerEvent("weaponSwitched", { player, oldWeapon, newWeapon })
end)
