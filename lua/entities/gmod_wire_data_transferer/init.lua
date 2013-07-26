
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Data Transferer"


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, {"Send","A","B","C","D","E","F","G","H"})
	self.Outputs = Wire_CreateOutputs(self, {"A","B","C","D","E","F","G","H"})
	self.Sending = false
	self.Activated = false
	self.ActivateTime = 0
	self.DefaultZero = true
	self.IgnoreZero = false
	self.Values = {};
	self.Values["A"] = 0
	self.Values["B"] = 0
	self.Values["C"] = 0
	self.Values["D"] = 0
	self.Values["E"] = 0
	self.Values["F"] = 0
	self.Values["G"] = 0
	self.Values["H"] = 0

	self:SetBeamLength(25000)
end

function ENT:Setup(Range,DefaultZero,IgnoreZero)
	self.IgnoreZero = IgnoreZero
	self.DefaultZero = DefaultZero
	self.Range = Range
	self:SetBeamLength(Range)
end

function ENT:TriggerInput(iname, value)
	if(iname == "Send")then
		self.Sending = value > 0
	else
		self.Values[iname] = value
	end
end

function ENT:Think()
	self:NextThink(CurTime()+0.125)
	if(self.Activated == false && self.DefaultZero)then
		Wire_TriggerOutput(self,"A",0)
		Wire_TriggerOutput(self,"B",0)
		Wire_TriggerOutput(self,"C",0)
		Wire_TriggerOutput(self,"D",0)
		Wire_TriggerOutput(self,"E",0)
		Wire_TriggerOutput(self,"F",0)
		Wire_TriggerOutput(self,"G",0)
		Wire_TriggerOutput(self,"H",0)
	else
		if(CurTime() > self.ActivateTime + 0.5)then
			self.Activated = false
		end
	end


	local vStart = self:GetPos()
	local vForward = self:GetUp()

	local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self:GetBeamLength())
	   trace.filter = { self }
	local trace = util.TraceLine( trace )

	local ent = trace.Entity

	if not IsValid(ent) then
		self:SetColor(Color(255, 255, 255, 255))
		return true
	end

	self:SetColor(Color(0, 255, 0, 255))

	if ent:GetClass() == "gmod_wire_data_transferer" then
		ent:ReceiveValue("A",self.Values.A)
		ent:ReceiveValue("B",self.Values.B)
		ent:ReceiveValue("C",self.Values.C)
		ent:ReceiveValue("D",self.Values.D)
		ent:ReceiveValue("E",self.Values.E)
		ent:ReceiveValue("F",self.Values.F)
		ent:ReceiveValue("G",self.Values.G)
		ent:ReceiveValue("H",self.Values.H)
	elseif ent:GetClass() == "gmod_wire_data_satellitedish" then
		if IsValid(ent.Transmitter) then
			ent.Transmitter:ReceiveValue("A",self.Values.A)
			ent.Transmitter:ReceiveValue("B",self.Values.B)
			ent.Transmitter:ReceiveValue("C",self.Values.C)
			ent.Transmitter:ReceiveValue("D",self.Values.D)
			ent.Transmitter:ReceiveValue("E",self.Values.E)
			ent.Transmitter:ReceiveValue("F",self.Values.F)
			ent.Transmitter:ReceiveValue("G",self.Values.G)
			ent.Transmitter:ReceiveValue("H",self.Values.H)
		else
			self:SetColor(Color(255, 0, 0, 255))
		end
	elseif ent:GetClass() == "gmod_wire_data_store" then
		Wire_TriggerOutput(self,"A",ent.Values.A)
		Wire_TriggerOutput(self,"B",ent.Values.B)
		Wire_TriggerOutput(self,"C",ent.Values.C)
		Wire_TriggerOutput(self,"D",ent.Values.D)
		Wire_TriggerOutput(self,"E",ent.Values.E)
		Wire_TriggerOutput(self,"F",ent.Values.F)
		Wire_TriggerOutput(self,"G",ent.Values.G)
		Wire_TriggerOutput(self,"H",ent.Values.H)
		if(self.Sending)then
			ent.Values.A = self.Inputs["A"].Value
			ent.Values.B = self.Inputs["B"].Value
			ent.Values.C = self.Inputs["C"].Value
			ent.Values.D = self.Inputs["D"].Value
			ent.Values.E = self.Inputs["E"].Value
			ent.Values.F = self.Inputs["F"].Value
			ent.Values.G = self.Inputs["G"].Value
			ent.Values.H = self.Inputs["H"].Value
		end
	else
		self:SetColor(Color(255, 255, 255, 255))
	end
	return true
end

function ENT:ReceiveValue(output,value)
	self.Activated = true
	self.ActivateTime = CurTime()
	if value ~= 0 or not self.IgnoreZero then
		Wire_TriggerOutput(self,output,value)
	end
end

function MakeWireTransferer( pl, Pos, Ang, model, Range, DefaultZero, IgnoreZero )
	if ( !pl:CheckLimit( "wire_data_transferers" ) ) then return false end

	local wire_data_transferer = ents.Create( "gmod_wire_data_transferer" )
	if (!wire_data_transferer:IsValid()) then return false end

	wire_data_transferer:SetAngles( Ang )
	wire_data_transferer:SetPos( Pos )
	wire_data_transferer:SetModel( model )
	wire_data_transferer:Spawn()
	wire_data_transferer:Setup(Range,DefaultZero,IgnoreZero)
	wire_data_transferer:SetPlayer( pl )

	pl:AddCount( "wire_data_transferers", wire_data_transferer )

	return wire_data_transferer
end
duplicator.RegisterEntityClass("gmod_wire_data_transferer", MakeWireTransferer, "Pos", "Ang", "Model", "Range", "DefaultZero", "IgnoreZero")
