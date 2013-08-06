AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Grabber"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Grabber"


-- Shared

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "Grab","Strength" })
	self.Outputs = Wire_CreateOutputs(self, {"Holding", "Grabbed Entity [ENTITY]"})
	self.WeldStrength = 0
	self.Weld = nil
	self.WeldEntity = nil
	self.ExtraProp = nil
	self.ExtraPropWeld = nil
	self:GetPhysicsObject():SetMass(10)

	self:Setup(100, true)

	self.OnlyGrabOwners = GetConVarNumber('sbox_wire_grabbers_onlyOwnersProps') > 0
end

function ENT:OnRemove()
	if self.Weld then
		self:ResetGrab()
	end
	Wire_Remove(self)
end

function ENT:Setup(Range, Gravity)
	if Range then self:SetBeamLength(Range) end
	self.Gravity = Gravity
end

function ENT:ResetGrab()
	if self.Weld and self.Weld:IsValid() then
		self.Weld:Remove()
		if self.WeldEntity then
			if self.WeldEntity:IsValid() then
				if self.Gravity then
					self.WeldEntity:GetPhysicsObject():EnableGravity(true)
				end
			end
		end
	end
	if self.ExtraPropWeld and self.ExtraPropWeld:IsValid() then
		self.ExtraPropWeld:Remove()
	end

	self.Weld = nil
	self.WeldEntity = nil
	self.ExtraPropWeld = nil

	self:SetColor(Color(255, 255, 255, self:GetColor().a))
	Wire_TriggerOutput(self,"Holding",0)
	Wire_TriggerOutput(self, "Grabbed Entity", self.WeldEntity)
end

function ENT:TriggerInput(iname, value)
	if iname == "Grab" then
		if value ~= 0 and self.Weld == nil then
			local vStart = self:GetPos()
			local vForward = self:GetUp()

			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self }
			local trace = util.TraceLine( trace )

			-- Bail if we hit world or a player
			if (not trace.Entity:IsValid() and trace.Entity ~= game.GetWorld())  or trace.Entity:IsPlayer() then return end
			-- If there's no physics object then we can't constraint it!
			if not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return end

			if self.OnlyGrabOwners and (trace.Entity:GetOwner() ~= self:GetOwner() and not self:CheckOwner(trace.Entity)) then return end

			-- Weld them!
			local const = constraint.Weld(self, trace.Entity, 0, 0, self.WeldStrength)
			if const then
				const.Type = "" --prevents the duplicator from making this weld
			end

			local const2
			--Msg("+Weld1\n")
			if self.ExtraProp then
				if self.ExtraProp:IsValid() then
					const2 = constraint.Weld(self.ExtraProp, trace.Entity, 0, 0, self.WeldStrength)
					if const2 then
						const2.Type = "" --prevents the duplicator from making this weld
					end
					--Msg("+Weld2\n")
				end
			end
			if self.Gravity then
				trace.Entity:GetPhysicsObject():EnableGravity(false)
			end

			self.WeldEntity = trace.Entity
			self.Weld = const
			self.ExtraPropWeld = const2

			self:SetColor(Color(255, 0, 0, self:GetColor().a))
			Wire_TriggerOutput(self, "Holding", 1)
			Wire_TriggerOutput(self, "Grabbed Entity", self.WeldEntity)
		elseif value == 0 then
			if self.Weld ~= nil or self.ExtraPropWeld ~= nil then
				self:ResetGrab()
			end
		end
	elseif iname == "Strength" then
		self.WeldStrength = math.max(value,0)
	end
end

--duplicator support (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if self.WeldEntity and self.WeldEntity:IsValid() then
		info.WeldEntity = self.WeldEntity:EntIndex()
	end

	if self.ExtraProp and self.ExtraProp:IsValid() then
		info.ExtraProp = self.ExtraProp:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.WeldEntity = GetEntByID(info.WeldEntity)

	self.ExtraProp = GetEntByID(info.ExtraProp)

	if self.WeldEntity and self.Inputs.Grab.Value ~= 0 then

		if not self.Weld then
			self.Weld = constraint.Weld(self, trace.Entity, 0, 0, self.WeldStrength)
			self.Weld.Type = "" --prevents the duplicator from making this weld
		end

		if IsValid(self.ExtraProp) then
			self.ExtraPropWeld = constraint.Weld(self.ExtraProp, self.WeldEntity, 0, 0, self.WeldStrength)
			self.ExtraPropWeld.Type = "" --prevents the duplicator from making this weld
		end

		if self.Gravity then
			self.WeldEntity:GetPhysicsObject():EnableGravity(false)
		end

		self:SetColor(Color(255, 0, 0, self:GetColor().a))
		Wire_TriggerOutput(self, "Holding", 1)
		Wire_TriggerOutput(self, "Grabbed Entity", self.WeldEntity)
	end
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

duplicator.RegisterEntityClass("gmod_wire_grabber", WireLib.MakeWireEnt, "Data", "Range", "Gravity")
