
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local MODEL = Model( "models/props_lab/tpplug.mdl" )

ENT.WireDebugName = "Plug"

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.MySocket = nil

	self.Inputs = Wire_CreateInputs(self.Entity, { "A","B","C","D","E","F","G","H" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A","B","C","D","E","F","G","H" })
end

function ENT:SetValue(index,value)
	if (self.MySocket.Const) and (self.MySocket.Const:IsValid()) then
		Wire_TriggerOutput(self.Entity, index, value)
	else
		Wire_TriggerOutput(self.Entity, index, 0)
	end

	self:ShowOutput()
end

function ENT:OnRemove()
	self.BaseClass.Think(self)

	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:Setup()
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
    if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket:SetValue(iname, value)
	end
	self:ShowOutput()
end

function ENT:SetSocket(socket)
	if (socket == nil) then
		for i,v in pairs(self.Outputs)do
			Wire_TriggerOutput(self.Entity, v.Name, 0)
		end
		self:ShowOutput()
	end
	self.MySocket = socket
end

function ENT:AttachedToSocket(socket)
    for i,v in pairs(self.Inputs)do
        socket:SetValue(v.Name,v.Value)
 	end
	self:ShowOutput()
end

function ENT:ShowOutput(value)
	self.OutText = "Plug:"
	if (self.Inputs) then
		self.OutText = self.OutText .. "\nInputs: "
		if (self.Inputs.A.Value) then
			self.OutText = self.OutText .. " A:" .. self.Inputs.A.Value
		end
		if (self.Inputs.B.Value) then
			self.OutText = self.OutText .. " B:" .. self.Inputs.B.Value
		end
		if (self.Inputs.C.Value) then
			self.OutText = self.OutText .. " C:" .. self.Inputs.C.Value
		end
		if (self.Inputs.D.Value) then
			self.OutText = self.OutText .. " D:" .. self.Inputs.D.Value
		end
		if (self.Inputs.E.Value) then
			self.OutText = self.OutText .. " E:" .. self.Inputs.E.Value
		end
		if (self.Inputs.F.Value) then
			self.OutText = self.OutText .. " F:" .. self.Inputs.F.Value
		end
		if (self.Inputs.G.Value) then
			self.OutText = self.OutText .. " G:" .. self.Inputs.G.Value
		end
		if (self.Inputs.H.Value) then
			self.OutText = self.OutText .. " H:" .. self.Inputs.H.Value
		end
	end
	if (self.Outputs) then
		self.OutText = self.OutText .. "\nOutputs: "
		if (self.Outputs.A.Value) then
			self.OutText = self.OutText .. " A:" .. self.Outputs.A.Value
		end
		if (self.Outputs.B.Value) then
			self.OutText = self.OutText .. " B:" .. self.Outputs.B.Value
		end
		if (self.Outputs.C.Value) then
			self.OutText = self.OutText .. " C:" .. self.Outputs.C.Value
		end
		if (self.Outputs.D.Value) then
			self.OutText = self.OutText .. " D:" .. self.Outputs.D.Value
		end
		if (self.Outputs.E.Value) then
			self.OutText = self.OutText .. " E:" .. self.Outputs.E.Value
		end
		if (self.Outputs.F.Value) then
			self.OutText = self.OutText .. " F:" .. self.Outputs.F.Value
		end
		if (self.Outputs.G.Value) then
			self.OutText = self.OutText .. " G:" .. self.Outputs.G.Value
		end
		if (self.Outputs.H.Value) then
			self.OutText = self.OutText .. " H:" .. self.Outputs.H.Value
		end
	end
	self:SetOverlayText(self.OutText)
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end
