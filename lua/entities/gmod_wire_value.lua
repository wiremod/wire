AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Value"
ENT.WireDebugName	= "Value"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = WireLib.CreateOutputs(self, { "Out" })
end

local types_lookup = {
	NORMAL = 0,
	ANGLE = Angle(0,0,0),
	VECTOR = Vector(0,0,0),
	VECTOR2 = {0,0},
	VECTOR4 = {0,0,0,0},
	STRING = "",
}

function ENT:SetupLegacy( values )
	local new = {}

	for k,v in pairs( values ) do
		local tp, val = string.match( v, "^ *([^: ]+) *:(.*)$" )
		tp = string.upper(tp or "NORMAL")

		if types_lookup[tp] then
			new[#new+1] = { DataType = tp, Value = val or v }
		end
	end

	self.LegacyOutputs = true
	self:Setup( new )
end

local tonumber = tonumber
local parsers = {}
function parsers.NORMAL( val )
	return tonumber(val)
end
function parsers.VECTOR ( val )
	local x,y,z = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
	if tonumber(x) and tonumber(y) and tonumber(y) then
		return Vector(tonumber(x),tonumber(y),tonumber(z))
	end
end
function parsers.VECTOR2( val )
	local x, y = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *$" )
	if tonumber(x) and tonumber(y) then return {tonumber(x), tonumber(y)} end
end
function parsers.VECTOR4( val )
	local x, y, z, w = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
	if tonumber(x) and tonumber(y) and tonumber(y) and tonumber(w) then
		return {tonumber(x),tonumber(y),tonumber(z),tonumber(w)}
	end
end
function parsers.ANGLE( val )
	local p,y,r = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
	if tonumber(p) and tonumber(y) and tonumber(r) then
		return Angle(tonumber(p),tonumber(y),tonumber(r))
	end
end
parsers.STRING = WireLib.ParseEscapes

function ENT:ParseValue( value, tp )
	if parsers[tp] then
		local ret = parsers[tp]( value )
		if ret then
			return ret
		else
			WireLib.AddNotify( self:GetPlayer(), "Constant Value: Unable to parse value '" .. tostring(value) .. "' as type '" .. tp .. "'.", NOTIFY_ERROR, 5, NOTIFYSOUND_ERROR1 )
			return types_lookup[tp]
		end
	end
end

function ENT:Setup( valuesin )
	if not valuesin then return end

	local _, val = next( valuesin )
	if not val then
		WireLib.AddNotify( self:GetPlayer(), "Constant Value: No values found!", NOTIFY_ERROR, 5, NOTIFYSOUND_ERROR1 )
	elseif not istable( val ) then -- old dupe
		self:SetupLegacy( valuesin )
	else
		self.value = valuesin -- Wirelink/Duplicator Info

		local names = {}
		local types = {}
		local values = {}
		local descs = {}

		for k,v in pairs(valuesin) do
			v.DataType = string.upper( v.DataType )
			if v.DataType == "NUMBER" then v.DataType = "NORMAL" end

			if types_lookup[string.upper( v.DataType )] ~= nil then
				names[k] = tostring( k )
				types[k] = string.upper( v.DataType )
				values[k] = self:ParseValue( v.Value, string.upper( v.DataType ) )
				descs[k] = values[k] ~= nil and v.Value or "*ERROR*"
			else
				WireLib.AddNotify( self:GetPlayer(), "Constant Value: Invalid type '" .. string.upper( v.DataType ) .. "' specified.", NOTIFY_ERROR, 5, NOTIFYSOUND_ERROR1 )
				names[k] = tostring( k )
				types[k] = "STRING"
				values[k] = "INVALID TYPE SPECIFIED"
				descs[k] = "*ERROR*"
			end
		end

		if self.LegacyOutputs then
			-- Gmod12 Constant Values will have outputs like Value1, Value2...
			-- To avoid breaking old dupes, we'll use those names if we're created from an old dupe
			for k,v in pairs(names) do
				names[k] = "Value"..v
			end
		end

		-- this is where storing the values as strings comes in: they are the descriptions for the inputs.
		WireLib.AdjustSpecialOutputs(self, names, types, descs )

		local txt = {}
		for k,v in pairs(valuesin) do
			txt[#txt+1] = string.format( "%s [%s]: %s",names[k],types[k],descs[k])
			WireLib.TriggerOutput( self, names[k], values[k] )
		end
		self:SetOverlayText(table.concat( txt, "\n" ))

		self.types = types
		self.values = values
	end
end

function ENT:ReadCell( Address )
	Address = math.floor(Address)
	local tp = self.types[Address+1]
	-- we can only retrieve numbers here, unfortunately.
	-- This is because the ReadCell function assumes that things like vectors and strings store one of their values per cell,
	-- which the constant value does not. While this could be worked around, it's just not worth the effort imo, and it'd just be confusing to use
	-- If you need to get other types, you'll need to use E2's "Wlk[OutputName,OutputType]" index syntax instead
	if tp == "NORMAL" then
		return self.values[Address+1]
	end

	return 0
end

duplicator.RegisterEntityClass("gmod_wire_value", WireLib.MakeWireEnt, "Data", "value")
