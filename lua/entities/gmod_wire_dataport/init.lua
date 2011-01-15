AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "DataPort"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	//makeoutputs = {}
	//for i = 0,7 do
	//	makeoutputs[i] = "Port"..i
	//end
	//self.Outputs = Wire_CreateOutputs(self, makeoutputs)

	self.Outputs = Wire_CreateOutputs(self, { "Port0","Port1","Port2","Port3","Port4","Port5","Port6","Port7" })
	self.Inputs = Wire_CreateInputs(self, { "Port0","Port1","Port2","Port3","Port4","Port5","Port6","Port7" })

	self.Ports = {}
	for i = 0,7 do
		self.Ports[i] = 0
	end
	self:SetOverlayText( "Data port" )
end

/*function ENT:Think()
	self.BaseClass.Think(self)
end*/

function ENT:ReadCell( Address )
	if (Address >= 0) && (Address <= 7) then
		return self.Ports[Address]
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if (Address >= 0) && (Address <= 7) then
		Wire_TriggerOutput(self, "Port"..Address, value)
		return true
	else
		return false
	end
end

function ENT:TriggerInput(iname, value)
	for i = 0,7 do
		if (iname == "Port"..i) then
			self.Ports[i] = value
		end
	end
end
