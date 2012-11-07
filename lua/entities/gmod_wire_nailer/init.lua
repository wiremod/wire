
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Nailer"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "A" })
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup(flim)
	self:TriggerInput("A", 0)
	self.Flim = math.Clamp(flim, 0, 10000)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if iname == "A" then
		if value ~= 0 then
			 local vStart = self:GetPos()
			 local vForward = self:GetUp()

			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * 2048)
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
				if (trace.Entity.Owner ~= self.Owner and not self:CheckOwner(trace.Entity)) or (trTwo.Entity.Owner ~= self.Owner and not self:CheckOwner(trTwo.Entity)) then return end
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

function ENT:OnRestore()
	Wire_Restored(self)
end

-- Free Fall's Owner Check Code
function ENT:CheckOwner(ent)
	ply = self.pl

	hasCPPI = (type( CPPI ) == "table")
	hasEPS = type( eps ) == "table"
	hasPropSecure = type( PropSecure ) == "table"
	hasProtector = type( Protector ) == "table"

	if not hasCPPI and not hasPropProtection and not hasSPropProtection and not hasEPS and not hasPropSecure and not hasProtector then return true end

	local t = hook.GetTable()

	local fn = t.CanTool.PropProtection
	hasPropProtection = type( fn ) == "function"
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
	hasSPropProtection = type( fn ) == "function"
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

function MakeWireNailer( pl, Pos, Ang, model, flim )
	if ( !pl:CheckLimit( "wire_nailers" ) ) then return false end

	local wire_nailer = ents.Create( "gmod_wire_nailer" )
	if (!wire_nailer:IsValid()) then return false end

	wire_nailer:SetAngles( Ang )
	wire_nailer:SetPos( Pos )
	wire_nailer:SetModel( model )
	wire_nailer:Spawn()

	wire_nailer:Setup( flim )
	wire_nailer:SetPlayer( pl )
	wire_nailer.pl = pl

	pl:AddCount( "wire_nailers", wire_nailer )

	return wire_nailer
end
duplicator.RegisterEntityClass("gmod_wire_nailer", MakeWireNailer, "Pos", "Ang", "Model", "Flim")
