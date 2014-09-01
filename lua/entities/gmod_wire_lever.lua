AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Analog Lever"
ENT.WireDebugName	= "Lever"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:SetModel("models/props_wasteland/tram_lever01.mdl") 
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	
	self.EntToOutput = NULL
	
	self.Ang = 0
	self.Value = 0
	self:Setup(0, 1)
	
	self.Inputs = WireLib.CreateInputs(self, {"SetValue", "Min", "Max"})
	self.Outputs = WireLib.CreateOutputs(self, {"Value", "Entity [ENTITY]"})
end

function ENT:Setup(min, max)
	if min then self.Min = min end
	if max then self.Max = max end
end

function ENT:TriggerInput(iname, value)
	if iname == "SetValue" then
		self.Ang = (math.Clamp(value, self.Min, self.Max) - self.Min)/(self.Max - self.Min) * 90 - 45
	elseif (iname == "Min") then
		self.Min = value
	elseif (iname == "Max") then
		self.Max = value
	end
end

function ENT:Use( ply )
	if not IsValid(ply) or not ply:IsPlayer() or IsValid(self.User) then return end
	self.User = ply
	WireLib.TriggerOutput( self, "Entity", ply)
end

function ENT:Think()
	self.BaseClass.Think(self)
	if not IsValid(self.BaseEnt) then return end
	
	if IsValid(self.User) then
		local dist = self.User:GetShootPos():Distance(self:GetPos())
		if dist < 160 and (self.User:KeyDown(IN_USE) or self.User:KeyDown(IN_ATTACK)) then
			local TargPos = self.User:GetShootPos() + self.User:GetAimVector() * dist
			local distMax = TargPos:Distance(self.BaseEnt:GetPos() + self.BaseEnt:GetForward() * 30)
			local distMin = TargPos:Distance(self.BaseEnt:GetPos() + self.BaseEnt:GetForward() * -30)
			local FPos = (distMax - distMin) * 0.5
			distMax = TargPos:Distance(self.BaseEnt:GetPos())
			distMin = TargPos:Distance(self.BaseEnt:GetPos() + self.BaseEnt:GetUp() * 40)
			local HPos = 20 - ((distMin - distMax) * 0.5)
			
			self.Ang = math.Clamp( math.deg( math.atan2( HPos, FPos ) ) - 90, -45, 45 )
		else
			self.User = NULL
			WireLib.TriggerOutput( self, "Entity", NULL)
		end
	end
	
	self.Value = Lerp((self.Ang + 45) / 90, self.Min, self.Max)
	Wire_TriggerOutput(self, "Value", self.Value)
	
	local NAng = self.BaseEnt:GetAngles()
	NAng:RotateAroundAxis( NAng:Right(), -self.Ang )
	local RAng = self.BaseEnt:WorldToLocalAngles(NAng)
	self:SetLocalPos( RAng:Up() * 21 )
	self:SetLocalAngles( RAng )

	self:ShowOutput()
	
	self:NextThink(CurTime()) 
	return true	
end

function ENT:ShowOutput()
	self:SetOverlayText(string.format("(%.2f - %.2f) = %.2f", self.Min, self.Max, self.Value))
end

function ENT:OnRemove( ) 
	if IsValid(self.BaseEnt) then 
		self.BaseEnt:Remove()
		self.BaseEnt = nil
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid(self.BaseEnt) then
		info.baseent = self.BaseEnt:EntIndex()
		constraint.Weld(self, self.BaseEnt, 0, 0, 0, true) -- Just in case the weld has been broken somehow, remake to ensure inclusion in dupe
	end
	info.value = self.Value
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if info.baseent then
		self.BaseEnt = GetEntByID(info.baseent)
	end
	if info.value then
		self.Value = info.value
		self:TriggerInput("SetValue", self.Value)
	end
end

duplicator.RegisterEntityClass("gmod_wire_lever", WireLib.MakeWireEnt, "Data", "Min", "Max" )
