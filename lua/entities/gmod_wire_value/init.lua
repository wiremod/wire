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
		["ANGLE"]	= "Angle"
	}
	for k,v in pairs(DataTypes) do
		if(v == DataType) then
			return k
		end
	end
	return nil
end

local tbl = {
	["NORMAL"] = tonumber,
	["STRING"] = tostring
}

local function TranslateType( Value, DataType )
    if tbl[DataType] then
        return tbl[DataType]( Value )
    end
    return 0
end

function ENT:Setup(values)

	PrintTable(values )
	self.value = values -- Wirelink. 
	
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
	
	Msg("NextTable:\n")
	
	PrintTable( values )

	// this is where storing the values as strings comes in: they are the descriptions for the inputs.
	WireLib.AdjustSpecialOutputs(self, outputs.names, outputs.types )

	local txt = ""

	for k,v in pairs(values) do
		
		txt = txt .. k .. ": [" .. tostring(v.DataType) .. "]" .. tostring(v.Value) .. "\n"
		print("Type: " .. ReturnType(v.DataType) )
		Wire_TriggerOutput( self, tostring(k), TranslateType(v.Value, ReturnType(v.DataType)) )
	end

	self:SetOverlayText(txt)

end


function ENT:ReadCell( Address )
	return self.value[Address+1]
end
