AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Data Port"
ENT.RenderGroup		= RENDERGROUP_BOTH
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

	self.Entity:NextThink(CurTime())
end

function ENT:Think()
	self.BaseClass.Think(self)

	for i = 0,7 do
		if self.OutPorts[i] then
			Wire_TriggerOutput(self, "Port"..i, self.OutPorts[i])
			self.OutPorts[i] = nil
		end
	end
	self.Entity:NextThink(CurTime())
	return true -- for NextThink
end

function ENT:ReadCell(Address)
	if (Address >= 0) && (Address <= 7) then
		return self.Ports[Address]
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	if (Address >= 0) && (Address <= 7) then
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

function MakeWireDataPort( pl, Pos, Ang, model )
	if ( !pl:CheckLimit( "wire_dataports" ) ) then return false end

	local wire_dataport = ents.Create( "gmod_wire_dataport" )
	if (!wire_dataport:IsValid()) then return false end
	wire_dataport:SetModel(model)

	wire_dataport:SetAngles( Ang )
	wire_dataport:SetPos( Pos )
	wire_dataport:Spawn()
	wire_dataport:SetPlayer(pl)

	pl:AddCount( "wire_dataports", wire_dataport )

	return wire_dataport
end
duplicator.RegisterEntityClass("gmod_wire_dataport", MakeWireDataPort, "Pos", "Ang", "Model")