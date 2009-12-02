AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Latch"

include('shared.lua')

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")


function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Activate", "NoCollide" } )

	-- masks containing all current states
	self.nocollide_masks = {
		-- Ent1, Ent2 , nocollide between the two
		{ false, false, true  }, -- 1 nocollide between the two
		{ true , false, false }, -- 2 nocollide Ent1 with all
		{ false, true , false }, -- 3 nocollide Ent2 with all
		{ true , true , false }  -- 4 nocollide both with all
		-- all other values: { false, false, false }
	}

	self.nocollide_description = {
		"NoCollided",
		"Ent1 has collisions disabled",
		"Ent2 has collisions disabled",
		"all collisions disabled"
	}

	-- the constraint
	self.nocollide = nil

	self:TriggerInput("NoCollide", 0)
end

-- This function is called by the STOOL
function ENT:SendVars( Ent1, Ent2, Bone1, Bone2, const )
	self.Ent1 = Ent1
	self.Ent2 = Ent2
	self.Bone1 = Bone1
	self.Bone2 = Bone2
	self.Constraint = const
end

local function UnNoCollide(Ent1, Ent2, Bone1, Bone2)
	local Phys1 = Ent1:GetPhysicsObjectNum(Bone1)
	local Phys2 = Ent2:GetPhysicsObjectNum(Bone2)

	local Constraint = ents.Create( "phys_constraint" )
		Constraint:SetKeyValue( "spawnflags", 1 )
		Constraint:SetPhysConstraintObjects( Phys1, Phys2 )
	Constraint:Spawn()
	Constraint:Activate()
	Constraint:Remove()
end

function ENT:TriggerInput(iname, value)
	if iname == "Activate" then

		if value == 0 and self.Constraint then

			self.Constraint:Remove()
			self.Constraint = nil

			self:SetOverlayText( "Weld Latch - Deactivated" )

		end

		if value ~= 0 and not self.Constraint then
			self.Constraint = constraint.Weld( self.Ent1, self.Ent2, self.Bone1, self.Bone2, 0 )

			if self.Constraint then
				self.Constraint.Type = "" -- prevents the duplicator from making this weld
			end
		end

	elseif iname == "NoCollide" then

		self.nocollide_status = value
		local mask = self.nocollide_masks[value] or {false, false, false}

		if self.Ent1 and not self.Ent1:IsWorld() then
			local phys = self.Ent1:GetPhysicsObject()
			if phys:IsValid() then phys:EnableCollisions(not mask[1]) end
		end

		if self.Ent2 and not self.Ent2:IsWorld() then
			local phys = self.Ent2:GetPhysicsObject()
			if phys:IsValid() then phys:EnableCollisions(not mask[2]) end
		end

		if mask[3] then
			if not self.nocollide then
				if self.Ent1 and self.Ent2 then
					-- enable NoCollide between the two entities
					self.nocollide = constraint.NoCollide( self.Ent1, self.Ent2, self.Bone1, self.Bone2 )
				end
			end
		else
			if self.nocollide then
				-- disable NoCollide between the two entities
				self.nocollide:Remove()
				self.nocollide = nil
				UnNoCollide(self.Ent1, self.Ent2, self.Bone1, self.Bone2)
			end
		end

	end

	self:UpdateOverlay()
end

function ENT:OnRemove()
	self:TriggerInput("Activate", 0)
	self:TriggerInput("NoCollide", 0)
end

function ENT:UpdateOverlay()
	local desc = self.nocollide_description[self.nocollide_status]
	if not desc then
		if self.Constraint then
			self:SetOverlayText( "Weld Latch - Welded" )
		else
			self:SetOverlayText( "Weld Latch - Deactivated" )
		end
		return
	end
	local text = self.Constraint and "Weld Latch - Welded and " or "Weld Latch - Not welded but "
	text = text .. desc
	self:SetOverlayText( text )
end

-- duplicator support (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.Ent1) and (self.Ent1:IsValid()) then
		info.Ent1 = self.Ent1:EntIndex()
		info.Bone1 = self.Bone1
	end
	if (self.Ent2) and (self.Ent2:IsValid()) then
		info.Ent2 = self.Ent2:EntIndex()
		info.Bone2 = self.Bone2
	end
	info.Activate = self.Constraint and 1 or 0
	info.NoCollide = self.nocollide_status
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.Ent1) then
		self.Ent1 = GetEntByID(info.Ent1)
		self.Bone1 = info.Bone1
		if (!self.Ent1) then
			self.Ent1 = ents.GetByIndex(info.Ent1)
		end
	end
	if (info.Ent2) then
		self.Ent2 = GetEntByID(info.Ent2)
		self.Bone2 = info.Bone2
		if (!self.Ent2) then
			self.Ent2 = ents.GetByIndex(info.Ent2)
		end
	end
	self:TriggerInput("Activate", info.Activate)
	self:TriggerInput("NoCollide", info.NoCollide)
end
