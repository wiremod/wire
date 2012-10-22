
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "User"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "Fire"})
	self.Outputs = Wire_CreateOutputs(self, {})
	self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup(Range)
	self:SetBeamLength(Range)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
			local vStart = self:GetPos()
			local vForward = self:GetUp()

			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self }
			local trace = util.TraceLine( trace )

			if (!trace.Entity) then return false end
				if (!trace.Entity:IsValid() ) then return false end
				if (trace.Entity:IsWorld()) then return false end

			if trace.Entity.Use and trace.Entity.GetPlayer then
				trace.Entity:Use(trace.Entity:GetPlayer(),trace.Entity:GetPlayer(),USE_ON,0)
			else
				trace.Entity:Fire("use","1",0)
			end
		end
	end
end

function ENT:OnRestore()
	Wire_Restored(self)
end
