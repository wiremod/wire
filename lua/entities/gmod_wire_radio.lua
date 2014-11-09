AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Radio"
ENT.WireDebugName = "Radio"

if CLIENT then return end -- No more client

local MODEL = Model( "models/props_lab/binderblue.mdl" )

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs(self, { "Channel"})
	self.Outputs = WireLib.CreateOutputs(self, { "ERRORS!!!" })

	self.Channel = 0
	self.values = 4
	self.RecievedData = {}
	for i=0,31 do
		self.RecievedData[i] = {}
		self.RecievedData[i].Owner = nil
		self.RecievedData[i].Data = 0
	end
	self.SentData = {}
	for i=0,31 do
		self.SentData[i] = 0
	end

	Radio_Register(self)
	Radio_RecieveData(self)
end

function ENT:Setup(channel,values,secure)
	channel = math.floor(tonumber(channel) or 0)
	self.Secure = secure
	self.Old = false
	if (tonumber(values) == nil) then
		values = 4
		self.Old = true
	else
		values = math.Clamp(math.floor(values),1,32)
	end

	self.values = values
	local onames = {}
	if (self.Old == false) then
		for i = 1,self.values do
			onames[i] = tostring(i) --without tostring() you kill the debugger.
		end
	else
		onames = {"A","B","C","D"}
	end

	WireLib.AdjustOutputs(self,onames)
	table.insert(onames,"Channel")
	WireLib.AdjustInputs(self,onames)

	self.Channel = channel
	Radio_ChangeChannel(self)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Channel") then
		self.Channel = math.floor(value)
		Radio_ChangeChannel(self)

	elseif (iname != nil && value != nil) then
		if (self.Old == true) then
			if (iname == "A") then
				Radio_SendData(self,self.Channel,0,value)
			elseif (iname == "B") then
				Radio_SendData(self,self.Channel,1,value)
			elseif (iname == "C") then
				Radio_SendData(self,self.Channel,2,value)
			elseif (iname == "D") then
				Radio_SendData(self,self.Channel,3,value)
			end
		else
			Radio_SendData(self,tonumber(iname)-1,value)
		end
	end
	self:ShowOutput()
end

function ENT:NotifyDataRecieved(subch)
	WireLib.TriggerOutput(self,tostring(subch+1),self.RecievedData[subch].Data)
end

function ENT:ReadCell(Address)
	if (Address >= 0) && (Address < self.values) then
		return self.RecievedData[Address].Data
	else
		return nil
	end
end

function ENT:WriteCell(Address, value)
	if (Address >= 0) && (Address < self.values) then
		Radio_SendData(self,Address,value)
		return true
	else
		return false
	end
end

function ENT:ShowOutput()
	if (self.Old == true) then
		self:SetOverlayText( "(Channel " .. self.Channel .. ") Transmit A: " .. (self.Inputs.A.Value or 0) .. " B: " .. (self.Inputs.B.Value or 0) ..  " C: " .. (self.Inputs.C.Value or 0) ..  " D: " .. (self.Inputs.D.Value or 0) .. "\nReceive A: " .. (self.Outputs.A.Value or 0) .. " B: " .. (self.Outputs.B.Value or 0) ..  " C: " .. (self.Outputs.C.Value or 0) ..  " D: " .. (self.Outputs.D.Value or 0) )
	else
		local overlay = "(Channel " .. self.Channel .. ") Transmit"
		for i=1,self.values do
			overlay = overlay .. " " .. i .. ":" ..
				math.Round((self.SentData[i-1])*1000)/1000
		end
		overlay = overlay .. "\nReceive"
		for i=1,self.values do
			overlay = overlay .. " " .. i .. ":" ..
				math.Round((self.RecievedData[i-1].Data)*1000)/1000
		end
		if (self.Secure == true) then overlay = overlay .. "\nSecured" end
		self:SetOverlayText(overlay)
	end
end

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
	Radio_Register(self)
end

function ENT:OnRemove()
	if (!self.Channel) then return end
	Radio_Unregister(self)
end

duplicator.RegisterEntityClass("gmod_wire_radio", WireLib.MakeWireEnt, "Data", "Channel", "values", "Secure")
