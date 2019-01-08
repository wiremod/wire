AddCSLuaFile()
DEFINE_BASECLASS( "gmod_wire_plug" )
ENT.PrintName		= "Wire Plug"
ENT.WireDebugName = "DataPlug"

function ENT:GetSocketClass()
	return "gmod_wire_datasocket"
end

if CLIENT then
	function ENT:DrawEntityOutline() end -- never draw outline
	return
end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Memory = nil

	self.Inputs = WireLib.CreateInputs(self, { "Memory" })
	self.Outputs = WireLib.CreateOutputs(self, { "Connected" })
	WireLib.TriggerOutput(self, "Connected", 0)
end

-- Override some functions from gmod_wire_plug
function ENT:Setup() end
function ENT:ResendValues() WireLib.TriggerOutput(self,"Connected",1) end
function ENT:ResetValues() WireLib.TriggerOutput(self,"Connected",0) end

function ENT:ReadCell( Address, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end
	Address = math.floor(Address)

    if IsValid(self.Socket) and self.Socket.OwnMemory and self.Socket.OwnMemory.ReadCell then
		return self.Socket.OwnMemory:ReadCell( Address, infloop + 1 )
	end
	return nil
end

function ENT:WriteCell( Address, value, infloop )
	infloop = infloop or 0
	if infloop > 50 then return end
	Address = math.floor(Address)

	if IsValid(self.Socket) and self.Socket.OwnMemory and self.Socket.OwnMemory.WriteCell then
		return self.Socket.OwnMemory:WriteCell( Address, value, infloop + 1 )
	end
	return false
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "Memory") then
		self.Memory = self.Inputs.Memory.Src
		if IsValid(self.Socket) then
			self.Socket:SetMemory(self.Memory)
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_dataplug", WireLib.MakeWireEnt, "Data")
