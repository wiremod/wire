
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "User"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "Fire"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {})
	self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(Range)
	self:SetBeamLength(Range)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
			local vStart = self.Entity:GetPos()
			local vForward = self.Entity:GetUp()

			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self.Entity }
			local trace = util.TraceLine( trace )

			if (!trace.Entity) then return false end
				if (!trace.Entity:IsValid() ) then return false end
				if (trace.Entity:IsWorld()) then return false end

			if trace.Entity.Use and trace.Entity.GetPlayer then
				trace.Entity:Use(trace.Entity:GetPlayer())
			else
				trace.Entity:Fire("use","1",0)
			end
		end
	end
end

function ENT:ShowOutput()
	local text = "User"
	self:SetOverlayText( text )
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end
