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


	self.Value = {}		-- stores current output value
	self.Last = {}		-- stores last input value for each input

	self.Inputs = Wire_CreateInputs(self, { "1A", "2A", "Switch" })
	self.Outputs = Wire_CreateOutputs(self, { "A" })
end

function ENT:Setup(keygroup1, keygroup2, keygroup3, keygroup4, keygroup5, keygroupoff, toggle, normclose, poles, throws, nokey)

	local outpoles = {"A", "B", "C", "D", "E", "F", "G", "H"} -- output names

	-- Clamp
	throws = throws > 10 and 10 or throws
	poles = poles > #outpoles and #outpoles or poles

	local inputs = {} 	--wont need this outside setup

	self.outputs = {} 	--need to rebuild output names

	self.keygroup1		= keygroup1
	self.keygroup2		= keygroup2
	self.keygroup3		= keygroup3
	self.keygroup4		= keygroup4
	self.keygroup5		= keygroup5
	self.keygroupoff	= keygroupoff
	self.toggle			= toggle
	self.normclose		= normclose or 0
	self.selinput 		= normclose or 0
	self.poles 			= poles
	self.throws 		= throws
	self.nokey			= nokey

	--build inputs and putputs, init all nil values
	for p=1, self.poles do
		self.outputs[p] = outpoles[p]
		self.Value[p] = self.Value[p] or 0
		for t=1, self.throws do
			--inputs[ p * self.poles + t ] = t .. outpoles[p]
			table.insert(inputs, t .. outpoles[p] )
			self.Last[ t .. outpoles[p] ] = self.Last[ t .. outpoles[p] ] or 0
		end
	end
	--add switch input to end of input list
	table.insert(inputs, "Switch")

	Wire_AdjustInputs(self, inputs)
	Wire_AdjustOutputs(self, self.outputs)

	--set the switch to its new normal state
	self:Switch( normclose )

	if not nokey then
		local pl = self:GetPlayer()
		if (keygroupoff) then
			numpad.OnDown( pl, keygroupoff, "WireRelay_On", self, 0 )
			numpad.OnUp( pl, keygroupoff, "WireRelay_Off", self, 0 )
		end
		if (keygroup1) then
			numpad.OnDown( pl, keygroup1, "WireRelay_On", self, 1 )
			numpad.OnUp( pl, keygroup1, "WireRelay_Off", self, 1 )
		end
		if (keygroup2) then
			numpad.OnDown( pl, keygroup2, "WireRelay_On", self, 2 )
			numpad.OnUp( pl, keygroup2, "WireRelay_Off", self, 2 )
		end
		if (keygroup3) then
			numpad.OnDown( pl, keygroup3, "WireRelay_On", self, 3 )
			numpad.OnUp( pl, keygroup3, "WireRelay_Off", self, 3 )
		end
		if (keygroup4) then
			numpad.OnDown( pl, keygroup4, "WireRelay_On", self, 4 )
			numpad.OnUp( pl, keygroup4, "WireRelay_Off", self, 4 )
		end
		if (keygroup5) then
			numpad.OnDown( pl, keygroup5, "WireRelay_On", self, 5 )
			numpad.OnUp( pl, keygroup5, "WireRelay_Off", self, 5 )
		end
	end
end


function ENT:TriggerInput(iname, value)
	if (iname == "Switch") then
		if (math.abs(value) >= 0 and math.abs(value) <= self.throws) then
			self:Switch(math.abs(value))
		end
	elseif (iname) then
		self.Last[iname] = value or 0
		self:Switch(self.selinput)
	end
end


function ENT:Switch( mul )
	if (not self:IsValid()) then return false end
	self.selinput = mul
	for p,v in ipairs(self.outputs) do
		self.Value[p] = self.Last[ mul .. v ] or 0
		Wire_TriggerOutput(self, v, self.Value[p])
	end
	self:ShowOutput()
	return true
end


function ENT:ShowOutput()
	local txt = self.poles .. "P" .. self.throws .. "T "
	if (self.selinput == 0) then
		txt = txt .. "Sel: off"
	else
		txt = txt .. "Sel: " .. self.selinput
	end

	for p,v in ipairs(self.outputs) do
		txt = txt .. "\n" .. v  .. ": " .. self.Value[p]
	end

	self:SetOverlayText( txt )
end


function ENT:InputActivate( mul )
	if ( self.toggle and self.selinput == mul) then --only toggle for the same key
		return self:Switch( self.normclose )
	else
		return self:Switch( mul )
	end
end

function ENT:InputDeactivate( mul )
	if ( self.toggle ) then return true end
	return self:Switch( self.normclose )
end


local function On( pl, ent, mul )
	if (not ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (not ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireRelay_On", On )
numpad.Register( "WireRelay_Off", Off )

duplicator.RegisterEntityClass("gmod_wire_relay", WireLib.MakeWireEnt, "Data", "keygroup1", "keygroup2", "keygroup3", "keygroup4", "keygroup5", "keygroupoff", "toggle", "normclose", "poles", "throws", "nokey")
