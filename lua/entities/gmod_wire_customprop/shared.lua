ENT.Type            = "anim"
ENT.Base            = "base_anim"

ENT.PrintName       = "Wiremod Custom Prop"
ENT.Author          = "Sparky & DeltaMolfar"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PhysMaterial")

	if CLIENT then
		self:NetworkVarNotify("PhysMaterial", self.OnPhysMaterialChanged)
	end
end

local Ent_IsValid = FindMetaTable("Entity").IsValid
local Ent_GetTable = FindMetaTable("Entity").GetTable
return {
	classname = "gmod_wire_customprop",

	readReliableEntity = function(callback)
		index = net.ReadUInt(16)
		creationIndex = net.ReadUInt(32)
		local startTime = CurTime()

		local function check()
			local ent = Entity(index)
			if Ent_IsValid(ent) and ent:GetCreationID() == creationIndex and Ent_GetTable(ent).BuildPhysics ~= nil then
				ProtectedCall(callback, ent)
				return
			end

			if CurTime() - startTime < 10 then
				timer.Simple(0.01, check)
			else
				ProtectedCall(callback, nil)
			end
		end

		check()
	end,

	writeReliableEntity = function(ent)
		net.WriteUInt(ent:EntIndex(), 16)
		net.WriteUInt(ent:GetCreationID(), 32)
	end,

	writeInt32 = function(n)
		return string.char(
			bit.band(n, 0xFF),
			bit.band(bit.rshift(n, 8), 0xFF),
			bit.band(bit.rshift(n, 16), 0xFF),
			bit.band(bit.rshift(n, 24), 0xFF)
		)
	end,

	readInt32 = function(data, pos)
		local b1 = string.byte(data, pos)
		local b2 = string.byte(data, pos + 1)
		local b3 = string.byte(data, pos + 2)
		local b4 = string.byte(data, pos + 3)
		local n = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
		return n, pos + 4
	end,

	writeFloat = function(f)
		-- Handles special cases
		if f == 0 then
			return string.char(0, 0, 0, 0)
		elseif f ~= f then -- NaN
			return string.char(0, 0, 192, 127)
		elseif f == math.huge then
			return string.char(0, 0, 128, 127)
		elseif f == -math.huge then
			return string.char(0, 0, 128, 255)
		end

		local sign = 0
		if f < 0 then sign = 0x80000000; f = -f end

		local mantissa, exponent = math.frexp(f)
		exponent = exponent + 126

		if exponent <= 0 then
			mantissa = mantissa * math.ldexp(0.5, exponent)
			exponent = 0
		elseif exponent >= 255 then
			mantissa = 0
			exponent = 255
		else
			mantissa = (mantissa * 2 - 1) * 0x800000
		end

		local bits = sign + bit.lshift(exponent, 23) + math.floor(mantissa + 0.5)
		return string.char(
			bit.band(bits, 0xFF),
			bit.band(bit.rshift(bits, 8), 0xFF),
			bit.band(bit.rshift(bits, 16), 0xFF),
			bit.band(bit.rshift(bits, 24), 0xFF)
		)
	end,

	readFloat = function(data, pos)
		local b1 = string.byte(data, pos)
		local b2 = string.byte(data, pos + 1)
		local b3 = string.byte(data, pos + 2)
		local b4 = string.byte(data, pos + 3)
		local bits = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216

		local sign = bit.band(bits, 0x80000000) ~= 0 and -1 or 1
		local exponent = bit.band(bit.rshift(bits, 23), 0xFF)
		local mantissa = bit.band(bits, 0x7FFFFF)

		if exponent == 255 then
			if mantissa == 0 then
				return sign * math.huge, pos + 4
			else
				return 0/0, pos + 4 -- NaN
			end
		elseif exponent == 0 then
			if mantissa == 0 then
				return 0, pos + 4
			else
				return sign * math.ldexp(mantissa / 0x800000, -126), pos + 4
			end
		end

		f = sign * math.ldexp(1 + mantissa / 0x800000, exponent - 127)
		return f, pos + 4
	end
}