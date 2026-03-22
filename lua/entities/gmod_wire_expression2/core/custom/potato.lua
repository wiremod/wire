E2Lib.RegisterExtension("potato", false, "Кастомные функции Картошечки.")

__e2setcost(5)

e2function number entity:isBuild()
	if not IsValid(this) then return self:throw("Invalid entity!", 0) end
	if not this:IsPlayer() then return self:throw("Entity is not a player!", 0) end
	return this:IsBuild() and 1 or 0
end