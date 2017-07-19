local ENTITY = FindMetaTable("Entity")
local Entity_GetDTAngle, Entity_GetDTBool, Entity_GetDTEntity, Entity_GetDTFloat, Entity_GetDTInt, Entity_GetDTString, Entity_GetDTVector = ENTITY.GetDTAngle, ENTITY.GetDTBool, ENTITY.GetDTEntity, ENTITY.GetDTFloat, ENTITY.GetDTInt, ENTITY.GetDTString, ENTITY.GetDTVector
if not (isfunction(Entity_GetDTAngle) and isfunction(Entity_GetDTBool) and isfunction(Entity_GetDTEntity) and isfunction(Entity_GetDTFloat) and isfunction(Entity_GetDTInt) and isfunction(Entity_GetDTString) and isfunction(Entity_GetDTVector)) then
	ErrorNoHalt("[Wiremod] Please notify the developers on GitHub to remove E2 netdatatable extension, because DT functions does NOT exists any more!\n")
	return
end

E2Lib.RegisterExtension("netdatatable", false, "Allows E2 chips to use 'Entity:GetDT*' GLua functions", "Could allow users to read out sensitive information on certain entity (only if it still uses DT functionality)")

local check_datatable = function(self, this, key)
	if not IsValid(this) and this ~= game.GetWorld() then return false end
	-- This is where "CanWireE2datatable" interface has been introduced. A new interface allows (3rd-party) entities to set this to
	-- either a boolean or a function. If the result is equal to "false", then the E2 will be blocked from reading particular entity's datatable;
	-- otherwise, if the result is equal to "true" or if the field is undefined, then the E2 will be allowed to read any entity's datatable field.
	if isbool(this.CanWireE2datatable) and not this.CanWireE2datatable then return false end
	if isfunction(this.CanWireE2datatable) and this:CanWireE2datatable(self.entity, key) == false then return false end
	return true
end
local DATATABLE_SIZE = 64

__e2setcost(10)

e2function angle entity:getDTAngle(number key)
	key = floor(key) % DATATABLE_SIZE
	if check_datatable(self, this, key) then
		key = Entity_GetDTAngle(this, key)
		return { key.p, key.y, key.r }
	end
	return { 0, 0, 0 }
end

e2function number entity:getDTBool(number key)
	key = floor(key) % DATATABLE_SIZE
	return check_datatable(self, this, key) and Entity_GetDTBool(this, key) and 1 or 0
end

e2function entity entity:getDTEntity(number key)
	key = floor(key) % DATATABLE_SIZE
	return check_datatable(self, this, key) and Entity_GetDTEntity(this, key) or NULL
end

e2function number entity:getDTFloat(number key)
	key = floor(key) % DATATABLE_SIZE
	return check_datatable(self, this, key) and Entity_GetDTFloat(this, key) or 0
end

e2function number entity:getDTInt(number key)
	key = floor(key) % DATATABLE_SIZE
	return check_datatable(self, this, key) and Entity_GetDTInt(this, key) or 0
end

e2function string entity:getDTString(number key)
	key = floor(key) % DATATABLE_SIZE
	return check_datatable(self, this, key) and Entity_GetDTString(this, key) or ""
end

e2function vector entity:getDTVector(number key)
	key = floor(key) % DATATABLE_SIZE
	if check_datatable(self, this, key) then
		key = Entity_GetDTVector(this, key)
		return { key.x, key.y, key.z }
	end
	return { 0, 0, 0 }
end
