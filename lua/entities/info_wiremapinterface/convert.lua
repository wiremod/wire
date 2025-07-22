-- This part is for converting between map and wire

-- Per type converting functions for
-- converting from map inputs to wire outputs. (String to Value)

local function isEqualList(_, listA, listB)
	if listA == listB then
		return true
	end

	if not listA or not listB then
		return false
	end

	if #listA ~= #listB then
		return false
	end

	for i, va in ipairs(listA) do
		local vb = listB[i]

		if va ~= vb then
			return false
		end
	end

	return true
end

local function isEqualGeneric(_, varA, varB)
	return varA == varB
end

local function isEqualEntity(_, entA, entB)
	if not IsValid(entA) or not IsValid(entB) then
		return false
	end

	return entA == entB
end

local g_supportedTypesById = {
	[0] = { -- Number, default
		wireType = "NORMAL",

		toHammer = function(_, wireValue)
			wireValue = tonumber(wireValue or 0) or 0
			return string.format("%.20g", wireValue)
		end,

		toWire = function(_, hammerValue)
			return tonumber(hammerValue or 0) or 0
		end,

		wireIsEqual = function(_, wireValueA, wireValueB)
			wireValueA = tonumber(wireValueA)
			wireValueB = tonumber(wireValueB)

			if not wireValueA then
				return false
			end

			if not wireValueB then
				return false
			end

			return wireValueA == wireValueB
		end
	},

	[1] = { -- Number, toggle
		wireType = "NORMAL",

		-- Wire Input: Trigger Hammer output only if true. Does not pass the input value from Wire to Hammer.
		-- Wire Output: Toggle the Wire Output when triggered by Hammer. Does not pass the input value from Hammer or Wire.
		isToggle = true,

		toHammer = function(_, wireValue) -- Return a boolean, 0 = false, 1 = true, useful for toggling. It triggers Hammer output only if true.
			return tobool(wireValue)
		end,

		toWire = function(_, hammerValue) -- Is being switched between 0 and 1 each call from Hammer input.
			return tobool(hammerValue) and 1 or 0
		end,

		wireIsEqual = isEqualGeneric,
	},

	[2] = { -- String
		wireType = "STRING",

		toHammer = function(_, wireValue)
			return tostring(wireValue or "")
		end,

		toWire = function(_, hammerValue)
			return hammerValue or ""
		end,

		wireIsEqual = isEqualGeneric,
	},

	[3] = { -- 2D Vector
		wireType = "VECTOR2",

		toHammer = function(_, wireValue)
			wireValue = wireValue or {0, 0}

			local x = tonumber(wireValue[1] or 0) or 0
			local y = tonumber(wireValue[2] or 0) or 0

			return string.format("%.20g %.20g", x, y)
		end,

		toWire = function(_, hammerValue)
			local x, y = unpack(string.Explode(" ", hammerValue or ""))

			x = tonumber(x or 0) or 0
			y = tonumber(y or 0) or 0

			return {x, y}
		end,

		wireIsEqual = isEqualList,
	},

	[4] = { -- 3D Vector
		wireType = "VECTOR",

		toHammer = function(_, wireValue)
			wireValue = wireValue or Vector(0, 0, 0)

			local x = tonumber(wireValue.x or 0) or 0
			local y = tonumber(wireValue.y or 0) or 0
			local z = tonumber(wireValue.z or 0) or 0

			return string.format("%.20g %.20g %.20g", x, y, z)
		end,

		toWire = function(_, hammerValue)
			local x, y, z = unpack(string.Explode(" ", hammerValue or ""))

			x = tonumber(x or 0) or 0
			y = tonumber(y or 0) or 0
			z = tonumber(z or 0) or 0

			return Vector(x, y, z)
		end,

		wireIsEqual = isEqualGeneric,
	},

	[5] = { -- 4D Vector
		wireType = "VECTOR4",

		toHammer = function(_, wireValue)
			val = val or {0, 0, 0, 0}

			local x = tonumber(val[1] or 0) or 0
			local y = tonumber(val[2] or 0) or 0
			local z = tonumber(val[3] or 0) or 0
			local w = tonumber(val[4] or 0) or 0

			return string.format("%.20g %.20g %.20g %.20g", x, y, z, w)
		end,

		toWire = function(_, hammerValue)
			local x, y, z, w = unpack(string.Explode(" ", hammerValue or ""))

			x = tonumber(x or 0) or 0
			y = tonumber(y or 0) or 0
			z = tonumber(z or 0) or 0
			w = tonumber(w or 0) or 0

			return {x, y, z, w}
		end,

		wireIsEqual = isEqualList,
	},

	[6] = { -- Angle
		wireType = "ANGLE",

		toHammer = function(_, wireValue)
			wireValue = wireValue or Angle(0, 0, 0)

			local p = tonumber(wireValue.p or 0) or 0
			local y = tonumber(wireValue.y or 0) or 0
			local r = tonumber(wireValue.r or 0) or 0

			return string.format("%.20g %.20g %.20g", p, y, r)
		end,

		toWire = function(_, hammerValue)
			local p, y, r = unpack(string.Explode(" ", hammerValue or ""))
			p = tonumber(p or 0) or 0
			y = tonumber(y or 0) or 0
			r = tonumber(r or 0) or 0

			return Angle(p, y, r)
		end,

		wireIsEqual = isEqualGeneric,
	},

	[7] = { -- Entity
		wireType = "ENTITY",

		toHammer = function(_, wireValue)
			if not IsValid(wireValue) then return "0" end
			return tostring(wireValue:EntIndex())
		end,

		toWire = function(self, hammerValue)
			local id = tonumber(hammerValue or 0)

			if id ~= nil then
				if id == 0 then
					return game.GetWorld()
				end

				return ents.GetByIndex(id)
			end

			return self:GetFirstEntityByTargetnameOrClass(hammerValue) or NULL
		end,

		wireIsEqual = isEqualEntity,
	},

	[8] = { -- Array/Table
		wireType = "ARRAY",

		toHammer = function(_, wireValue)
			return table.concat(wireValue or {}, " ")
		end,

		toWire = function(_, hammerValue)
			return string.Explode(" ", hammerValue or "")
		end,

		wireIsEqual = isEqualList,
	},
}

function ENT:GetMapToWireConverter(typeId)
	local typeData = g_supportedTypesById[typeId or 0] or g_supportedTypesById[0]
	if not typeData then
		return
	end

	return typeData.toWire, typeData.isToggle or false
end

function ENT:GetWireToMapConverter(typeId)
	local typeData = g_supportedTypesById[typeId or 0] or g_supportedTypesById[0]
	if not typeData then
		return
	end

	return typeData.toHammer, typeData.isToggle or false
end

function ENT:IsEqualWireValue(typeId, wireValueA, wireValueB)
	local typeData = g_supportedTypesById[typeId or 0] or g_supportedTypesById[0]
	if not typeData then
		return false
	end

	return typeData.wireIsEqual(self, wireValueA, wireValueB)
end

function ENT:GetWireTypenameByTypeId(typeId)
	local typeData = g_supportedTypesById[typeId or 0] or g_supportedTypesById[0]
	if not typeData then
		return
	end

	return typeData.wireType
end

