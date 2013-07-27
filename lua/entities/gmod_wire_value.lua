AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Value"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

local function ReturnType( DataType )
	// Supported Data Types.
	// Should be requested by client and only kept serverside.
	local DataTypes = {
		["NORMAL"] = "number",
		["STRING"] = "string",
		["VECTOR"] = "vector",
		["ANGLE"]  = "angle"
	}
	for k,v in pairs(DataTypes) do
		if(v == DataType:lower()) then
			return k
		end
	end
	return nil
end

local function StringToNumber( str )
	local val = tonumber(str) or 0
	return val
end

local function StringToVector( str )
	if str != nil and str != "" then
		local tbl = string.Split(str, ",")
		if #tbl >= 2 and #tbl <=3 then
			local vec = Vector(0,0,0)
			vec.x = StringToNumber(tbl[1])
			vec.y = StringToNumber(tbl[2])
			if #tbl == 3 then
				vec.z = StringToNumber(tbl[3])
			end
			return vec
		end
	end
	return Vector(0,0,0)
end

local function StringToAngle( str )
	if str != nil and str != "" then
		local tbl = string.Split(str, ",")
		if #tbl == 3 then
			local ang = Angle(0,0,0)
			ang.p = StringToNumber(tbl[1])
			ang.y = StringToNumber(tbl[2])
			ang.r = StringToNumber(tbl[3])
			return ang
		end
	end
	return Angle(0,0,0)
end

local tbl = {
	["NORMAL"] = StringToNumber,
	["STRING"] = tostring,
	["VECTOR"] = StringToVector,
	["ANGLE"] = StringToAngle,
}

local function TranslateType( Value, DataType )
    if tbl[DataType] then
        return tbl[DataType]( Value )
    end
    return 0
end

function ENT:Setup(valuesin, legacynames)
	self.value = valuesin -- Wirelink/Duplicator Info 
	
	local names = {}
	local types = {}
	local values = {}
	local descs = {}
	
	for k,v in pairs(valuesin) do
		names[k] = tostring( k )
		types[k] = ReturnType(v.DataType)
		values[k] = TranslateType(v.Value, ReturnType(v.DataType))
		descs[k] = v.Value
	end
	if legacynames then
		-- Gmod12 Constant Values will have outputs like Value1, Value2... 
		-- To avoid breaking old dupes, we'll use those names if we're created from an old dupe
		for k,v in pairs(names) do
			names[k] = "Value"..v
		end
	end

	// this is where storing the values as strings comes in: they are the descriptions for the inputs.
	WireLib.AdjustSpecialOutputs(self, names, types, descs )

	local txt = ""
	for k,v in pairs(valuesin) do
		txt = txt .. names[k] .. " [" .. tostring(v.DataType) .. "]: " .. descs[k] .. "\n"
		Wire_TriggerOutput( self, names[k], values[k] )
	end
	self:SetOverlayText(string.Left(txt,#txt-1)) -- Cut off the last \n
end

function ENT:ReadCell( Address )
	return self.value[Address+1]
end

function MakeWireValue( ply, Pos, Ang, model, value )
	if (!ply:CheckLimit("wire_values")) then return false end

	local wire_value = ents.Create("gmod_wire_value")
	if (!wire_value:IsValid()) then return false end
	
	wire_value:SetAngles(Ang)
	wire_value:SetPos(Pos)
	wire_value:SetModel(model)
	wire_value:Spawn()
	if value then
		local _,val = next(value)
		if istable(val) then
			-- The new Gmod13 format, good
			wire_value:Setup(value)
		else
			-- The old Gmod12 dupe format, lets convert it
			local convertedValues = {}
			local convtbl = {
				["NORMAL"] = "Number",
				["ANGLE"] = "Angle",
				["VECTOR"] = "Vector",
				["VECTOR2"] = "Vector",
				["VECTOR4"] = "Vector",
				["STRING"] = "String",
			}
			for k,v in pairs(value) do
				local theType,theValue = string.match (v, "^ *([^: ]+) *:(.*)$")
				theType = string.upper(theType or "NORMAL")
				
				if not convtbl[theType] then
					theType = "NORMAL"
				end
				
				table.insert(convertedValues, { DataType=convtbl[theType], Value=theValue or v } )
			end
			wire_value:Setup( convertedValues, true )
		end
	end
	wire_value:SetPlayer(ply)

	ply:AddCount("wire_values", wire_value)

	return wire_value
end
duplicator.RegisterEntityClass("gmod_wire_value", MakeWireValue, "Pos", "Ang", "Model", "value")
