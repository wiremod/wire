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

function ENT:TriggerInput(iname, value)
	if iname == "A" then
		if value ~= 0 then
			 local vStart = self:GetPos()
			 local vForward = self:GetUp()

			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * self:GetBeamLength())
				 trace.filter = { self }
			 local trace = util.TraceLine( trace )

			-- Bail if we hit world or a player
			if not trace.Entity:IsValid() or trace.Entity:IsPlayer() then return end
			-- If there's no physics object then we can't constraint it!
			if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return end

			local tr = {}
				tr.start = trace.HitPos
				tr.endpos = trace.HitPos + (self:GetUp() * 50.0)
				tr.filter = { trace.Entity, self }
			local trTwo = util.TraceLine( tr )

			if trTwo.Hit and not trTwo.Entity:IsPlayer() then
				if (trace.Entity:GetOwner() ~= self:GetOwner() and not self:CheckOwner(trace.Entity)) or (trTwo.Entity:GetOwner() ~= self:GetOwner() and not self:CheckOwner(trTwo.Entity)) then return end
				-- Weld them!
				local constraint = constraint.Weld( trace.Entity, trTwo.Entity, trace.PhysicsBone, trTwo.PhysicsBone, self.Flim )

				-- effect on weld (tomb332)
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
	self:SetOverlayText("Force Limit: " .. self.Flim )
end

-- Free Fall's Owner Check Code
function ENT:CheckOwner(ent)
	ply = self:GetPlayer()

	hasCPPI = istable( CPPI )
	hasEPS = istable( eps )
	hasPropSecure = istable( PropSecure )
	hasProtector = istable( Protector )

	if not hasCPPI and not hasPropProtection and not hasSPropProtection and not hasEPS and not hasPropSecure and not hasProtector then return true end

	local t = hook.GetTable()

	local fn = t.CanTool.PropProtection
	hasPropProtection = isfunction( fn )
	if hasPropProtection then
		-- We're going to get the function we need now. It's local so this is a bit dirty
		local gi = debug.getinfo( fn )
		for i=1, gi.nups do
			local k, v = debug.getupvalue( fn, i )
			if k == "Appartient" then
				propProtectionFn = v
			end
		end
	end

	local fn = t.CanTool[ "SPropProtection.EntityRemoved" ]
	hasSPropProtection = isfunction( fn )
	if hasSPropProtection then
		local gi = debug.getinfo( fn )
		for i=1, gi.nups do
			local k, v = debug.getupvalue( fn, i )
			if k == "SPropProtection" then
				SPropProtectionFn = v.PlayerCanTouch
			end
		end
	end

	local owns
	if hasCPPI then
		owns = ent:CPPICanPhysgun( ply )
	elseif hasPropProtection then -- Chaussette's Prop Protection (preferred over PropSecure)
		owns = propProtectionFn( ply, ent )
	elseif hasSPropProtection then -- Simple Prop Protection by Spacetech
		if ent:GetNetworkedString( "Owner" ) ~= "" then -- So it doesn't give an unowned prop
			owns = SPropProtectionFn( ply, ent )
		else
			owns = false
		end
	elseif hasEPS then -- EPS
		owns = eps.CanPlayerTouch( ply, ent )
	elseif hasPropSecure then -- PropSecure
		owns = PropSecure.IsPlayers( ply, ent )
	elseif hasProtector then -- Protector
		owns = Protector.Owner( ent ) == ply:UniqueID()
	end

	return owns
end

duplicator.RegisterEntityClass("gmod_wire_nailer", WireLib.MakeWireEnt, "Data", "Flim")
