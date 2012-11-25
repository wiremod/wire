AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Relay"
ENT.WireDebugName 	= "Relay"
ENT.Author          = "tad2020"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )


	self.Value = {}		//stores current output value
	self.Last = {}		//stores last input value for each input

	self.Inputs = Wire_CreateInputs(self, { "1A", "2A", "Switch" })
	self.Outputs = Wire_CreateOutputs(self, { "A" })
end

function ENT:Setup(keygroup1, keygroup2, keygroup3, keygroup4, keygroup5, keygroupoff, toggle, normclose, poles, throws)
	self.KeyGroup1		= keygroup1
	self.KeyGroup2		= keygroup2
	self.KeyGroup3		= keygroup3
	self.KeyGroup4		= keygroup4
	self.KeyGroup5		= keygroup5
	self.KeyGroupOff	= keygroupoff
	self.Toggle			= toggle
	self.NormClose		= normclose or 0
	self.SelInput 		= normclose or 0
	self.Poles 			= poles
	self.Throws 		= throws

	local outpoles = {"A", "B", "C", "D", "E", "F", "G", "H"} //output names
	local inputs = {} 	//wont need this outside setup
	self.outputs = {} 	//need to rebuild output names

	//build inputs and putputs, init all nil values
	for p=1, self.Poles do
		self.outputs[p] = outpoles[p]
		self.Value[p] = self.Value[p] or 0
		for t=1, self.Throws do
			//inputs[ p * self.Poles + t ] = t .. outpoles[p]
			table.insert(inputs, ( t .. outpoles[p] ))
			self.Last[ t .. outpoles[p] ] = self.Last[ t .. outpoles[p] ] or 0
		end
	end
	//add switch input to end of input list
	table.insert(inputs, "Switch")

	Wire_AdjustInputs(self, inputs)
	Wire_AdjustOutputs(self, self.outputs)

	//set the switch to its new normal state
	self:Switch( normclose )
end


function ENT:TriggerInput(iname, value)
	if (iname == "Switch") then
		if (math.abs(value) >= 0 && math.abs(value) <= self.Throws) then
			self:Switch(math.abs(value))
		end
	elseif (iname) then
		self.Last[iname] = value or 0
		self:Switch(self.SelInput)
	end
end


function ENT:Switch( mul )
	if (!self:IsValid()) then return false end
	self.SelInput = mul
	for p,v in ipairs(self.outputs) do
		self.Value[p] = self.Last[ mul .. v ] or 0
		Wire_TriggerOutput(self, v, self.Value[p])
	end
	self:ShowOutput()
	return true
end


function ENT:ShowOutput()
	local txt = self.Poles .. "P" .. self.Throws .. "T "
	if (self.SelInput == 0) then
		txt = txt .. "Sel: off"
	else
		txt = txt .. "Sel: " .. self.SelInput
	end

	for p,v in ipairs(self.outputs) do
		txt = txt .. "\n" .. v  .. ": " .. self.Value[p]
	end

	self:SetOverlayText( txt )
end


function ENT:InputActivate( mul )
	if ( self.Toggle && self.SelInput == mul) then //only toggle for the same key
		return self:Switch( self.NormClose )
	else
		return self:Switch( mul )
	end
end

function ENT:InputDeactivate( mul )
	if ( self.Toggle ) then return true end
	return self:Switch( self.NormClose )
end


local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireRelay_On", On )
numpad.Register( "WireRelay_Off", Off )
