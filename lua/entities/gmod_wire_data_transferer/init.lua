
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

	self:SetBeamRange(25000)
	self:ShowOutput()
end

function ENT:Setup(Range,DefaultZero,IgnoreZero)
	self.IgnoreZero = IgnoreZero
	self.DefaultZero = DefaultZero
	self:SetBeamRange(Range)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:TriggerInput(iname, value)
	if(iname == "Send")then
		if(value > 0)then
			self.Sending = true
		else
			self.Sending = false
		end
	else
		self.Values[iname] = value
	end
end

function ENT:Think()
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
	   trace.endpos = vStart + (vForward * self:GetBeamRange())
	   trace.filter = { self }
	local trace = util.TraceLine( trace )

	local ent = trace.Entity

	if not (ent && ent:IsValid() &&
	(trace.Entity:GetClass() == "gmod_wire_data_transferer" ||
	 trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ||
	  trace.Entity:GetClass() == "gmod_wire_data_store" ))then
		if(Color(self:GetColor()) != Color(255,255,255,255))then
			self:SetColor(255, 255, 255, 255)
		end
	return false
	end

	if(Color(self:GetColor()) != Color(0,255,0,255))then
		self:SetColor(0, 255, 0, 255)
	end

	if(trace.Entity:GetClass() == "gmod_wire_data_transferer")then
		ent:RecieveValue("A",self.Values.A)
		ent:RecieveValue("B",self.Values.B)
		ent:RecieveValue("C",self.Values.C)
		ent:RecieveValue("D",self.Values.D)
		ent:RecieveValue("E",self.Values.E)
		ent:RecieveValue("F",self.Values.F)
		ent:RecieveValue("G",self.Values.G)
		ent:RecieveValue("H",self.Values.H)
	elseif(trace.Entity:GetClass() == "gmod_wire_data_satellitedish")then
		if(ent.Transmitter && ent.Transmitter:IsValid())then
			ent.Transmitter:RecieveValue("A",self.Values.A)
			ent.Transmitter:RecieveValue("B",self.Values.B)
			ent.Transmitter:RecieveValue("C",self.Values.C)
			ent.Transmitter:RecieveValue("D",self.Values.D)
			ent.Transmitter:RecieveValue("E",self.Values.E)
			ent.Transmitter:RecieveValue("F",self.Values.F)
			ent.Transmitter:RecieveValue("G",self.Values.G)
			ent.Transmitter:RecieveValue("H",self.Values.H)
		else
			self:SetColor(255, 0, 0, 255)
		end
	elseif(trace.Entity:GetClass() == "gmod_wire_data_store")then
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
	end
	self:NextThink(CurTime()+0.125)
end

function ENT:ShowOutput()
	self:SetOverlayText( "Data Transferer" )
end

function ENT:OnRestore()
	Wire_Restored(self)
end

function ENT:RecieveValue(output,value)
	self.Activated = true
	self.ActivateTime = CurTime()
	if value ~= 0 or not self.IgnoreZero then
		Wire_TriggerOutput(self,output,value)
	end
end
