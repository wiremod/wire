-- Serverside functionalities of Wire Map Interface

local function validateId(id)
	id = tonumber(id)
	return id ~= nil and id >= -1 and id <= 0xFFFF
end

WireLib.WireMapInterfaceValidateId = validateId

WireLib.WireMapInterfaceLookup = {
    entsBySpawnID = {},
    entsBySpawnIDDuped = {},
    entsByMapID = {},

    add = function(self, wireEntSpawnId, wireEntSpawnIdDuped, wireEntMapId, wireEnt)
		if not wireEntSpawnId then
			-- Never add entities without spawn id, e.g. when not assignable.
			return
		end

        self.entsBySpawnID[wireEntSpawnId] = wireEnt

        if wireEntSpawnIdDuped then
            self.entsBySpawnIDDuped[wireEntSpawnIdDuped] = wireEnt
        end

		if validateId(wireEntMapId) then
			self.entsByMapID[wireEntMapId] = wireEnt
		end

        wireEnt:CallOnRemove("WireMapInterfaceLookupRemove", function()
			self:remove(wireEntSpawnId, wireEntSpawnIdDuped, wireEntMapId, wireEnt)
		end)
    end,

    remove = function(self, wireEntSpawnId, wireEntSpawnIdDuped, wireEntMapId, wireEnt)
		if not wireEntSpawnId then
			self.entsBySpawnID[wireEntSpawnId] = nil
		end

        if wireEntSpawnIdDuped then
            self.entsBySpawnIDDuped[wireEntSpawnIdDuped] = nil
        end

		if validateId(wireEntMapId) then
	        self.entsByMapID[wireEntMapId] = nil
		end

		wireEnt:RemoveCallOnRemove("WireMapInterfaceLookupRemove")
    end,

    getBySpawnID = function(self, wireEntSpawnId)
        return self.entsBySpawnID[wireEntSpawnId]
    end,

    getBySpawnIDDuped = function(self, wireEntSpawnIdDuped)
        return self.entsBySpawnIDDuped[wireEntSpawnIdDuped]
    end,

    getByMapID = function(self, wireEntMapId)
		return self.entsByMapID[wireEntMapId]
    end,
}
