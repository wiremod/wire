ENT.Type			= "anim"
ENT.Base			= "base_anim"

ENT.PrintName		= "Wiremod Custom Prop"
ENT.Author			= "Sparky & DeltaMolfar"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

-- Reason why there are more max convexes but less max vertices by default is that client's ENT:BuildPhysics is the main bottleneck.
-- It seems to require more time exponentially to the vertices amount.
-- The same amount of vertices in total, but broken into different convexes greatly reduces the performance hit.
CreateConVar("wire_customprops_hullsize_max", 2048, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The max hull size of a custom prop")
CreateConVar("wire_customprops_minvertexdistance", 0.2, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The min distance between two vertices in a custom prop.")
CreateConVar("wire_customprops_vertices_max", 64, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How many vertices custom props can have.", 4)
CreateConVar("wire_customprops_convexes_max", 12, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How many convexes custom props can have.", 1)
CreateConVar("wire_customprops_max", 16, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The maximum number of custom props a player can spawn. (0 to disable)", 0)

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PhysMaterial")

	if CLIENT then
		self:NetworkVarNotify("PhysMaterial", self.OnPhysMaterialChanged)
	end
end

local Ent_IsValid = FindMetaTable("Entity").IsValid
local Ent_GetTable = FindMetaTable("Entity").GetTable

local writeInt16 = function(n)
	return string.char(
		bit.band(n, 0xFF),
		bit.band(bit.rshift(n, 8), 0xFF)
	)
end

local readInt16 = function(data, pos)
	local b1 = string.byte(data, pos)
	local b2 = string.byte(data, pos + 1)
	local n = b1 + b2 * 256
	return n, pos + 2
end

local quantizeFloat16 = function(f, min, max)
	local range = max - min
	if range <= 0 then return 0 end
	local v = math.floor((math.max(min, math.min(max, f)) - min) / range * 65535 + 0.5)
	return v
end

local dequantizeFloat16 = function(i, min, max)
	local range = max - min
	if range <= 0 then return min end
	return min + (i / 65535) * range
end

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

	writeInt16 = writeInt16,

	readInt16 = readInt16,

	quantizeFloat16 = quantizeFloat16,

	dequantizeFloat16 = dequantizeFloat16,

	writeQuantizedFloat16 = function(f, min, max)
		local i = quantizeFloat16(f, min, max)
		return writeInt16(i)
	end,

	readQuantizedFloat16 = function(data, pos, min, max)
		local i, pos2 = readInt16(data, pos)
		return dequantizeFloat16(i, min, max), pos2
	end,
}