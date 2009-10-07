
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Nailer"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(flim)
	self:TriggerInput("A", 0)
	self.Flim = math.Clamp(flim, 0, 10000)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if (value ~= 0) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()

			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * 2048)
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace )

			// Bail if we hit world or a player
			if (  !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return end
			// If there's no physics object then we can't constraint it!
			if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return end

			local tr = {}
				tr.start = trace.HitPos
				tr.endpos = trace.HitPos + (self.Entity:GetUp() * 50.0)
				tr.filter = { trace.Entity, self.Entity }
			local trTwo = util.TraceLine( tr )

			if ( trTwo.Hit && !trTwo.Entity:IsPlayer() ) then
				// Weld them!
				local constraint = constraint.Weld( trace.Entity, trTwo.Entity, trace.PhysicsBone, trTwo.PhysicsBone, self.Flim )

				//effect on weld (tomb332)
				local effectdata = EffectData()
					effectdata:SetOrigin( trTwo.HitPos )
					effectdata:SetNormal( trTwo.HitNormal )
					effectdata:SetMagnitude( 5 )
					effectdata:SetScale( 1 )
					effectdata:SetRadius( 10 )
				util.Effect( "Sparks", effectdata )
			end
		end
	end
end

function ENT:ShowOutput()
	self:SetOverlayText( "Nailer\n" ..
						 "Force Limit: " .. self.Flim )
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

