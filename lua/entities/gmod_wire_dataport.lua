AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Port"
ENT.WireDebugName = "DataPort"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self.Outputs = Wire_CreateOutputs(self, { "Port0","Port1","Port2","Port3","Port4","Port5","Port6","Port7" })
	self.Inputs = Wire_CreateInputs(self, { "Port0","Port1","Port2","Port3","Port4","Port5","Port6","Port7" })

	self.Ports = {}
	for i = 0,7 do
		self.Ports[i] = 0
	end
	self.OutPorts = {}

	self:NextThink(CurTime())
end

function ENT:Think()
	BaseClass.Think(self)

	for i = 0,7 do
		if self.OutPorts[i] then
			Wire_TriggerOutput(self, "Port"..i, self.OutPorts[i])
			self.OutPorts[i] = nil
		end
	end
	self:NextThink(CurTime())
	return true -- for NextThink
end

function ENT:ReadCell(Address)
	Address = math.floor(Address)
	if (Address >= 0) and (Address <= 7) then
		return self.Ports[Address]
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor(Address)
	if (Address >= 0) and (Address <= 7) then
		self.OutPorts[Address] = value
		return true
	else
		return false
	end
end

function ENT:TriggerInput(iname, value)
	for i = 0,7 do
		if iname == ("Port"..i) then
			self.Ports[i] = value
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_dataport", WireLib.MakeWireEnt, "Data")
