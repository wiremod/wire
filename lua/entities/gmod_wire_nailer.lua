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
	self.Inputs = WireLib.CreateInputs(self, { "Weld", "Axis", "Ballsocket" })
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
	if not WireLib.CanTool(self:GetPlayer(), trace.Entity, "nailer" ) then return false end
	return true
end

function ENT:TriggerInput(name, value)
	if value == 0 then return end

	local up = self:GetUp()

	local trace1 = util.TraceLine( {
		start = self:GetPos(),
		endpos = self:GetPos() + up * self:GetBeamLength(),
		filter = { self }
	} )

	if not self:CanNail( trace1 ) then return end

	local trace2 = util.TraceLine( {
		start = trace1.HitPos,
		endpos = trace1.HitPos + up * 50,
		filter = { trace1.Entity, self }
	} )

	if not self:CanNail( trace2 ) then return end

	if name == "Weld" then
		constraint.Weld( 	trace1.Entity,
							trace2.Entity,
							trace1.PhysicsBone,
							trace2.PhysicsBone,
							self.Flim
						)
	elseif name == "Axis" then
		local phys1 = trace1.Entity:GetPhysicsObject()
		local phys2 = trace2.Entity:GetPhysicsObject()
		if not IsValid( phys1 ) or not IsValid( phys2 ) then return end

		local LPos1 = phys1:WorldToLocal( trace2.HitPos + trace2.HitNormal )
		local LPos2 = phys2:WorldToLocal( trace2.HitPos )

		constraint.Axis(	trace1.Entity,
							trace2.Entity,
							trace1.PhysicsBone,
							trace2.PhysicsBone,
							LPos1, LPos2,
							self.Flim
						)
	elseif name == "Ballsocket" then
		constraint.Ballsocket(	trace1.Entity,
								trace2.Entity,
								trace1.PhysicsBone,
								trace2.PhysicsBone,
								trace2.Entity:WorldToLocal(trace1.HitPos),
								self.Flim
							)
	end

	-- effect on weld (tomb332)
	local effectdata = EffectData()
		effectdata:SetOrigin( trace2.HitPos )
		effectdata:SetNormal( trace1.HitNormal )
		effectdata:SetMagnitude( 5 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( 10 )
	util.Effect( "Sparks", effectdata, false, true )
end

function ENT:ShowOutput()
	self:SetOverlayText(string.format( "Range: %s\nForce limit: %s", math.Round(self:GetBeamLength(),2), math.Round(self.Flim,2) ))
end

WireLib.AddInputAlias( "A", "Weld" )

duplicator.RegisterEntityClass("gmod_wire_nailer", WireLib.MakeWireEnt, "Data", "Flim", "Range", "ShowBeam")
