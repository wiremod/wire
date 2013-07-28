-- This part is for converting between map and wire

-- Per type converting functions for
-- converting from map inputs to wire outputs. (String to Value)
local MapToWireTypes = {
	[0] = {"NORMAL", function(str)	-- Number, default
		return tonumber(str) or 0
	end},

	[1] = {"NORMAL", function(self, ent, I)	-- switches between 0 and 1 each call, useful for toggling.
		if (!IsValid(self) or !IsValid(ent) or !I) then return 0 end

		self.WireOutputToggle = self.WireOutputToggle or {}
		self.WireOutputToggle[ent] = self.WireOutputToggle[ent] or {}
		self.WireOutputToggle[ent][I] = !self.WireOutputToggle[ent][I]

		return self.WireOutputToggle[ent][I] and 1 or 0
	end, true},

	[2] = {"STRING", function(str)	-- String
		return str or ""
	end},

	[3] = {"VECTOR2", function(str)	-- 2D Vector
		local x, y = unpack(string.Explode(" ", str or ""))
		x = tonumber(x) or 0
		y = tonumber(y) or 0

		return {x, y}
	end},

	[4] = {"VECTOR", function(str)	-- 3D Vector
		local x, y, z = unpack(string.Explode(" ", str or ""))
		x = tonumber(x) or 0
		y = tonumber(y) or 0
		z = tonumber(z) or 0

		return Vector(x, y, z)
	end},

	[5] = {"VECTOR4", function(str)	-- 4D Vector
		local x, y, z, w = unpack(string.Explode(" ", str or ""))
		x = tonumber(x) or 0
		y = tonumber(y) or 0
		z = tonumber(z) or 0
		w = tonumber(w) or 0

		return {x, y, z, w}
	end},

	[6] = {"ANGLE", function(str)	-- Angle
		local p, y, r = unpack(string.Explode(" ", str or ""))
		p = tonumber(p) or 0
		y = tonumber(y) or 0
		r = tonumber(r) or 0

		return Angle(p, y, r)
	end},

	[7] = {"ENTITY", function(val)	-- Entity
		return Entity(tonumber(val) or 0) or NULL
	end},

	[8] = {"ARRAY", function(str)	-- Array/Table
		return string.Explode(" ", str or "")
	end},
}

-- Per type converting functions for
-- converting from wire inputs to map outputs. (Value to String)
local WireToMapTypes = {
	[0] = {"NORMAL", function(val)	-- Number, default
		return tostring(val or 0)
	end},

	[1] = {"NORMAL", function(val)	-- Return a boolean, 0 = false, 1 = true, useful for toggling.
		return (tonumber(val) or 0) > 0
	end, true},

	[2] = {"STRING", function(val)	-- String
		return val or ""
	end},

	[3] = {"VECTOR2", function(val)	-- 2D Vector
		val = val or {0, 0}

		local x = math.Round(val[1] or 0)
		local y = math.Round(val[2] or 0)

		return x.." "..y
	end},

	[4] = {"VECTOR", function(val)	-- 3D Vector
		val = val or Vector(0, 0, 0)

		local x = math.Round(val.x or 0)
		local y = math.Round(val.y or 0)
		local z = math.Round(val.z or 0)

		return x.." "..y.." "..z
	end},

	[5] = {"VECTOR4", function(val)	--4D Vector
		val = val or {0, 0, 0, 0}

		local x = math.Round(val[1] or 0)
		local y = math.Round(val[2] or 0)
		local z = math.Round(val[3] or 0)
		local w = math.Round(val[4] or 0)

		return x.." "..y.." "..z.." "..w
	end},

	[6] = {"ANGLE", function(val)	-- Angle
		val = val or Angle(0, 0, 0)

		local p = math.Round(val.p or 0)
		local y = math.Round(val.y or 0)
		local r = math.Round(val.r or 0)

		return p.." "..y.." "..r
	end},

	[7] = {"ENTITY", function(val)	-- Entity
		if (!IsValid(val)) then return "0" end

		return tostring(val:EntIndex())
	end},

	[8] = {"ARRAY", function(val)	-- Array/Table
		return table.concat(val or {}, " ")
	end},
}

-- Converting functions
function ENT:Convert_MapToWire(n)
	local typetab = MapToWireTypes[n or 0] or MapToWireTypes[0]
	return typetab[1], typetab[2], typetab[3]
end
function ENT:Convert_WireToMap(n)
	local typetab = WireToMapTypes[n or 0] or WireToMapTypes[0]
	return typetab[1], typetab[2], typetab[3]
end
