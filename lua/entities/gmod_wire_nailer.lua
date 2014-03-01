AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Nailer"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Nailer"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
	self:NetworkVar( "Bool",  0, "ShowBeam" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "A" })
	self:SetBeamLength(2048)
end

function ENT:Setup(flim, Range, ShowBeam)
	self.Flim = math.Clamp(flim, 0, 10000)
	if Range then self:SetBeamLength(Range) end
	if ShowBeam ~= nil then self:SetShowBeam(ShowBeam) end
	self:ShowOutput()
end

function ENT:CanNail(trace)
	-- Bail if we hit world or a player
	if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	-- If there's no physics object then we can't constraint it!
	if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end
	-- The nailer tool no longer exists, but we ask for permission under its name anyway
	if not hook.Run( "CanTool", self:GetOwner(), trace, "nailer" ) then return false end
	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "A" and value ~= 0 then
		local vStart = self:GetPos()
		local vForward = self:GetUp()
		
		local trace1 = util.TraceLine {
			start = vStart,
			endpos = vStart + (vForward * self:GetBeamLength()),
			filter = { self }
		}
		if not self:CanNail(trace1) then return end
			
		local trace2 = util.TraceLine {
			start = trace1.HitPos,
			endpos = trace1.HitPos + (vForward * 50.0),
			filter = { trace1.Entity, self }
		}
		if not self:CanNail(trace2) then return end

		local constraint = constraint.Weld( trace1.Entity, trace2.Entity, trace1.PhysicsBone, trace2.PhysicsBone, self.Flim )

		-- effect on weld (tomb332)
		local effectdata = EffectData()
			effectdata:SetOrigin( trace2.HitPos )
			effectdata:SetNormal( trace1.HitNormal )
			effectdata:SetMagnitude( 5 )
			effectdata:SetScale( 1 )
			effectdata:SetRadius( 10 )
		util.Effect( "Sparks", effectdata )
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("Force Limit: " .. self.Flim )
end

duplicator.RegisterEntityClass("gmod_wire_nailer", WireLib.MakeWireEnt, "Data", "Flim")