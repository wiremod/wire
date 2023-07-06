AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Grabber"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.WireDebugName	= "Grabber"

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "BeamLength" )
end

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "Grab","Strength (The strength of the weld. The weld will break if enough force is applied. Setting to zero makes the weld unbreakable.)","Range" })
	self.Outputs = Wire_CreateOutputs(self, {"Holding", "Grabbed Entity [ENTITY]"})
	self.WeldStrength = 0
	self.Weld = nil
	self.WeldEntity = nil
	self.EntHadGravity = true
	self.ExtraProp = nil
	self.ExtraPropWeld = nil
	self:GetPhysicsObject():SetMass(10)

	self:Setup(100, true)
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

function ENT:LinkEnt( prop )
	if not IsValid(prop) then return false, "Not a valid entity!" end
	self.ExtraProp = prop
	WireLib.SendMarks(self, {prop})
	return true
end
function ENT:UnlinkEnt()
	if IsValid(self.ExtraPropWeld) then
		self.ExtraPropWeld:Remove()
		self.ExtraPropWeld = nil
	end
	self.ExtraProp = nil
	WireLib.SendMarks(self, {})
	return true
end

function ENT:ResetGrab()
	if IsValid(self.Weld) then
		self.Weld:Remove()
		if self.EntHadGravity and IsValid(self.WeldEntity) and IsValid(self.WeldEntity:GetPhysicsObject()) and self.Gravity then
			self.WeldEntity:GetPhysicsObject():EnableGravity(true)
		end
	end
	if IsValid(self.ExtraPropWeld) then
		self.ExtraPropWeld:Remove()
	end

	self.Weld = nil
	self.WeldEntity = nil
	self.ExtraPropWeld = nil

	self:SetColor(Color(255, 255, 255, self:GetColor().a))
	Wire_TriggerOutput(self, "Holding", 0)
	Wire_TriggerOutput(self, "Grabbed Entity", self.WeldEntity)
end

function ENT:CanGrab(trace)
	if not trace.Entity or not isentity(trace.Entity) then return false end
	if (not trace.Entity:IsValid() and not trace.Entity:IsWorld()) or trace.Entity:IsPlayer() then return false end
	-- If there's no physics object then we can't constraint it!
	if not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end

	if not WireLib.CanTool(self:GetPlayer(), trace.Entity, "weld") then return false end

	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "Grab" then
		if value ~= 0 and self.Weld == nil then
			local vStart = self:GetPos()
			local vForward = self:GetUp()

			local filter = ents.FindByClass( "gmod_wire_spawner" ) -- for prop spawning contraptions that grab spawned props
			table.insert( filter, self )

			local trace = util.TraceLine {
				start = vStart,
				endpos = vStart + (vForward * self:GetBeamLength()),
				filter = filter
			}
			if not self:CanGrab(trace) then return end

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
			self.EntHadGravity = trace.Entity:GetPhysicsObject():IsGravityEnabled()

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
	elseif iname == "Range" then
		self:SetBeamLength(math.Clamp(value,0,32000))
	end
end

--duplicator support (TAD2020)
function ENT:BuildDupeInfo()
	local info = BaseClass.BuildDupeInfo(self) or {}

	if self.WeldEntity and self.WeldEntity:IsValid() then
		info.WeldEntity = self.WeldEntity:EntIndex()
	end

	if self.ExtraProp and self.ExtraProp:IsValid() then
		info.ExtraProp = self.ExtraProp:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.WeldEntity = GetEntByID(info.WeldEntity)

	self.ExtraProp = GetEntByID(info.ExtraProp)

	if self.WeldEntity and self.Inputs.Grab.Value ~= 0 then

		if not self.Weld and self.trace~=nil then
			self.Weld = constraint.Weld(self, self.trace, 0, 0, self.WeldStrength)
			self.Weld.Type = "" --prevents the duplicator from making this weld
		end

		if IsValid(self.ExtraProp) then
			self.ExtraPropWeld = constraint.Weld(self.ExtraProp, self.WeldEntity, 0, 0, self.WeldStrength)
			self.ExtraPropWeld.Type = "" --prevents the duplicator from making this weld
		end

		if self.Gravity then
			self.WeldEntity:GetPhysicsObject():EnableGravity(false)
		end
		if self.Weld then
			self:SetColor(Color(255, 0, 0, self:GetColor().a))
			Wire_TriggerOutput(self, "Holding", 1)
			Wire_TriggerOutput(self, "Grabbed Entity", self.WeldEntity)
		else
			self:ResetGrab()
		end
	end
end

duplicator.RegisterEntityClass("gmod_wire_grabber", WireLib.MakeWireEnt, "Data", "Range", "Gravity")
