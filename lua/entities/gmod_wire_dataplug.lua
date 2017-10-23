AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Plug"
ENT.WireDebugName = "DataPlug"

if CLIENT then return end -- No more client

local Limit =  math.floor( ( 1 / engine.TickInterval() ) * 5 )
local Reads  = 0
local Writes = 0
timer.Create( '', 1,0,function() Writes = 0 Reads = 0 end)

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.MySocket = nil
	self.Memory = nil

	self.Inputs = Wire_CreateInputs(self, { "Memory" })
	self.Outputs = Wire_CreateOutputs(self, { "Connected" })
	Wire_TriggerOutput(self, "Connected", 0)
end

function ENT:ReadCell( Address )
	if( Reads > Limit ) then return false end
    if IsValid(self.MySocket) and self.MySocket.OwnMemory and self.MySocket.OwnMemory.ReadCell then
    	Reads = Reads + 1
		return self.MySocket.OwnMemory:ReadCell( Address )
	end
	return nil
end


function ENT:WriteCell( Address, value )
	if( Writes > Limit ) then return false end
	if IsValid(self.MySocket) and self.MySocket.OwnMemory and self.MySocket.OwnMemory.WriteCell then		
		Writes = Writes + 1
		return self.MySocket.OwnMemory:WriteCell( Address, value )
	end
	return false
end




function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if IsValid(self.MySocket) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:TriggerInput(iname, value, iter)
	
	if (iname == "Memory") then
		self.Memory = self.Inputs.Memory.Src
		if (self.MySocket) and (self.MySocket:IsValid()) then
			self.MySocket:SetMemory(self.Memory)
		end
	end
	
end


function ENT:SetSocket(socket)
	self.MySocket = socket
	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket:SetMemory(self.Memory)
	else
		Wire_TriggerOutput(self, "Connected", 0)
	end
end

function ENT:AttachedToSocket(socket)
	socket:SetMemory(self.Memory)
	Wire_TriggerOutput(self, "Connected", 1)
end

duplicator.RegisterEntityClass("gmod_wire_dataplug", WireLib.MakeWireEnt, "Data")
