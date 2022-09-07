AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Advanced Input"
ENT.WireDebugName = "Adv. Input"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self,{"Reset"})
	self.Outputs = Wire_CreateOutputs(self,{"Out"})
end

function ENT:Setup(key_more,key_less,toggle,value_min,value_max,value_start,speed)
	self.keymore = key_more
	self.keyless = key_less

	local pl = self:GetPlayer()
	numpad.OnDown( pl, key_more, "WireAdvInput_On", self, 1 )
	numpad.OnUp( pl, key_more, "WireAdvInput_Off", self, 1 )
	numpad.OnDown( pl, key_less, "WireAdvInput_On", self, -1 )
	numpad.OnUp( pl, key_less, "WireAdvInput_Off", self, -1 )

	self.toggle = (toggle == 1 or toggle == true)
	self.value_min = value_min
	self.value_max = value_max
	self.Value = value_start
	self.value_start = value_start
	self.speed = speed
	self:ShowOutput()
	Wire_TriggerOutput(self,"Out",self.Value)
end

function ENT:TriggerInput(iname, value)
    if(iname == "Reset")then
        if(value ~= 0)then
            self.Value = self.value_start
            self:ShowOutput()
	        Wire_TriggerOutput(self,"Out",self.Value)
	    end
	end
end

function ENT:InputActivate(mul)
	if (self.toggle) then
		return self:Switch( not self.On, mul )
	end
	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if (self.toggle) then return true end
	return self:Switch( false, mul )
end

function ENT:Switch( on, mul )
	if (not self:IsValid()) then return false end
	self.On = on
	if(on) then
		self.dir = mul
	else
		self.dir = 0
	end
	return true
end

function ENT:Think()
	BaseClass.Think(self)
	local timediff = CurTime()-(self.LastThink or 0)
	self.LastThink = (self.LastThink or 0)+timediff
	if (self.On == true) then
		self.Value = self.Value + self.speed * timediff * self.dir
		if (self.Value < self.value_min) then
			self.Value = self.value_min
		elseif (self.Value > self.value_max) then
			self.Value = self.value_max
		end
		self:ShowOutput()
		Wire_TriggerOutput(self,"Out",self.Value)
		self:NextThink(CurTime()+0.02)
		return true
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("(" .. self.value_min .. " - " .. self.value_max .. ") = " .. self.Value)
end

local function On( pl, ent, mul )
	if (not ent:IsValid()) then return false end
	if not gamemode.Call("PlayerUse", pl, ent) then return end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (not ent:IsValid()) then return false end
	if not gamemode.Call("PlayerUse", pl, ent) then return end
	return ent:InputDeactivate( mul )
end
numpad.Register( "WireAdvInput_On",On)
numpad.Register( "WireAdvInput_Off",Off)

duplicator.RegisterEntityClass("gmod_wire_adv_input", WireLib.MakeWireEnt, "Data", "keymore", "keyless", "toggle", "value_min", "value_max", "value_start", "speed", "frozen")
