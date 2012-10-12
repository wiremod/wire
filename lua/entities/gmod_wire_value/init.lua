AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Value"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self, { "Out" })
end

local function ReturnType( DataType )
	// Supported Data Types.
	// Should be requested by client and only kept serverside.
	local DataTypes = 
	{
		["NORMAL"] = "Number",
		["STRING"]	= "String",
		["VECTOR"] = "Vector",
		["ANGLE"]	= "Angle",
	}
	for k,v in pairs(DataTypes) do
		if(v:lower() == DataType:lower()) then
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
function ENT:OldSetup( values )
	local newValues = {}
	local convtbl =
	{
		["NORMAL"] = "Number",
		["ANGLE"] = "Angle",
		["VECTOR"] = "Vector",
		["VECTOR2"] = "Vector",
		["VECTOR4"] = "Vector",
		["STRING"] = "String",
	}
	for k,v in pairs(values) do
		local theType,theValue = string.match (v, "^ *([^: ]+) *:(.*)$")
		theType = string.upper(theType)
		
		if convtbl[theType] == nil then
			theType = "Number"
		end
		
		table.insert(newValues, { DataType=convtbl[theType], Value=theValue } )
	end
	
	return newValues
end

function ENT:Setup(values)
	self.value = (values) -- Wirelink/Duplicator Info 
	
	local outputs = 
	{
		names = {},
		types = {},
		values = {}
	}
	
	for k,v in pairs(values) do
		outputs.names[k] = tostring( k )
		outputs.values[k] = TranslateType(v.Value, ReturnType(v.DataType))
		outputs.types[k] = ReturnType(v.DataType)
	end
	
	// this is where storing the values as strings comes in: they are the descriptions for the inputs.
	WireLib.AdjustSpecialOutputs(self, outputs.names, outputs.types )

	local txt = ""

	for k,v in pairs(values) do
		local theVal = TranslateType(v.Value, ReturnType(v.DataType))
		txt = txt .. k .. ": [" .. tostring(v.DataType) .. "] " .. tostring(theVal) .. "\n"
		Wire_TriggerOutput( self, tostring(k), theVal )
	end

	self:SetOverlayText(txt)

end


function ENT:ReadCell( Address )
	return self.value[Address+1]
end
