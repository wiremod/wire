
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Data Transferer"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, {"Send","A","B","C","D","E","F","G","H"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"A","B","C","D","E","F","G","H"})
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
	Wire_Remove(self.Entity)
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
		Wire_TriggerOutput(self.Entity,"A",0)
		Wire_TriggerOutput(self.Entity,"B",0)
		Wire_TriggerOutput(self.Entity,"C",0)
		Wire_TriggerOutput(self.Entity,"D",0)
		Wire_TriggerOutput(self.Entity,"E",0)
		Wire_TriggerOutput(self.Entity,"F",0)
		Wire_TriggerOutput(self.Entity,"G",0)
		Wire_TriggerOutput(self.Entity,"H",0)
	else
		if(CurTime() > self.ActivateTime + 0.5)then
			self.Activated = false
		end
	end


	local vStart = self.Entity:GetPos()
	local vForward = self.Entity:GetUp()

	local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self:GetBeamRange())
	   trace.filter = { self.Entity }
	local trace = util.TraceLine( trace )

	local ent = trace.Entity

	if not (ent && ent:IsValid() &&
	(trace.Entity:GetClass() == "gmod_wire_data_transferer" ||
	 trace.Entity:GetClass() == "gmod_wire_data_satellitedish" ||
	  trace.Entity:GetClass() == "gmod_wire_data_store" ))then
		if(Color(self.Entity:GetColor()) != Color(255,255,255,255))then
			self.Entity:SetColor(255, 255, 255, 255)
		end
	return false
	end

	if(Color(self.Entity:GetColor()) != Color(0,255,0,255))then
		self.Entity:SetColor(0, 255, 0, 255)
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
			self.Entity:SetColor(255, 0, 0, 255)
		end
	elseif(trace.Entity:GetClass() == "gmod_wire_data_store")then
		Wire_TriggerOutput(self.Entity,"A",ent.Values.A)
		Wire_TriggerOutput(self.Entity,"B",ent.Values.B)
		Wire_TriggerOutput(self.Entity,"C",ent.Values.C)
		Wire_TriggerOutput(self.Entity,"D",ent.Values.D)
		Wire_TriggerOutput(self.Entity,"E",ent.Values.E)
		Wire_TriggerOutput(self.Entity,"F",ent.Values.F)
		Wire_TriggerOutput(self.Entity,"G",ent.Values.G)
		Wire_TriggerOutput(self.Entity,"H",ent.Values.H)
		if(self.Sending)then
			ent.Values.A = self.Entity.Inputs["A"].Value
			ent.Values.B = self.Entity.Inputs["B"].Value
			ent.Values.C = self.Entity.Inputs["C"].Value
			ent.Values.D = self.Entity.Inputs["D"].Value
			ent.Values.E = self.Entity.Inputs["E"].Value
			ent.Values.F = self.Entity.Inputs["F"].Value
			ent.Values.G = self.Entity.Inputs["G"].Value
			ent.Values.H = self.Entity.Inputs["H"].Value
		end
	end
	self.Entity:NextThink(CurTime()+0.125)
end

function ENT:ShowOutput()
	self:SetOverlayText( "Data Transferer" )
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

function ENT:RecieveValue(output,value)
	self.Activated = true
	self.ActivateTime = CurTime()
	if value ~= 0 or not self.IgnoreZero then
		Wire_TriggerOutput(self.Entity,output,value)
	end
end
