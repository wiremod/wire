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
		outputs.values[k] = v.Value
		outputs.types[k] = v.DataType
	end
	
	Msg("NextTable:\n")
	
	PrintTable( values )

	// this is where storing the values as strings comes in: they are the descriptions for the inputs.
	--WireLib.AdjustSpecialOutputs(self, outputs.names, outputs.types )

	local txt = ""

	for k,v in pairs(values) do
		
		txt = txt .. k .. ": [" .. tostring(v.DataType) .. "]" .. tostring(v.Value) .. "\n"
		
		--Wire_TriggerOutput( self, k, v.Value )
	end

	self:SetOverlayText(txt)

end


function ENT:ReadCell( Address )
	return self.value[Address+1]
end
