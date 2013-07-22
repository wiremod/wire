AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Latch"

include('shared.lua')


function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Activate", "NoCollide", "Strength" } )
	self.Outputs = Wire_CreateOutputs( self, { "Welded" } )

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
		"All collisions disabled"
	}

	self.Nocollide = nil
	self:TriggerInput("NoCollide", 0)
end

-- Run if weld is removed (will run *after* Create_Weld)
local function Weld_Removed( weld, ent )
	if IsValid(ent) then
		if !ent.Constraint or ent.Constraint == weld then
			ent.Constraint = nil
			Wire_TriggerOutput( ent, "Welded", 0 )
			ent:UpdateOverlay()
		end
	end
end

function ENT:Remove_Weld()
	if self.Constraint then
		if self.Constraint:IsValid() then
			self.Constraint:Remove()
		end
		self.Constraint = nil
	end
end

function ENT:Create_Weld()
	self:Remove_Weld()
	self.Constraint = MakeWireLatch( self.Ent1, self.Ent2, self.Bone1, self.Bone2, self.weld_strength or 0 )

	if self.Constraint then
		self.Constraint:CallOnRemove( "Weld Latch Removed", Weld_Removed, self )
	end
end

-- This function is called by the STOOL
function ENT:SendVars( Ent1, Ent2, Bone1, Bone2, const )
	self.Ent1 = Ent1
	self.Ent2 = Ent2
	self.Bone1 = Bone1
	self.Bone2 = Bone2
	self.Constraint = const
end

function ENT:TriggerInput( iname, value )
	if iname == "Activate" then
		if value == 0 and self.Constraint then
			self:Remove_Weld()

		elseif value ~= 0 and not self.Constraint then
			self:Create_Weld()
			Wire_TriggerOutput( self, "Welded", 1 )
		end

	elseif iname == "NoCollide" then
		self.nocollide_status = value
		local mask = self.nocollide_masks[value] or {false, false, false}

		if IsValid( self.Ent1 ) then
			local phys = self.Ent1:GetPhysicsObject()
			if phys:IsValid() then phys:EnableCollisions(not mask[1]) end
		end

		if IsValid( self.Ent2 ) then
			local phys = self.Ent2:GetPhysicsObject()
			if phys:IsValid() then phys:EnableCollisions(not mask[2]) end
		end

		if mask[3] then
			if not self.Nocollide then
				if self.Ent1 and self.Ent2 then
					-- enable NoCollide between the two entities
					self.Nocollide = constraint.NoCollide( self.Ent1, self.Ent2, self.Bone1, self.Bone2 )
				end
			end
		else
			if self.Nocollide then
				if self.Nocollide:IsValid() then
					-- disable NoCollide between the two entities
					self.Nocollide:Input("EnableCollisions", nil, nil, nil)
					self.Nocollide:Remove()
				end
				self.Nocollide = nil
			end
		end

	elseif iname == "Strength" then
		local newvalue = math.max( value, 0 )
		if newvalue ~= self.weld_strength then
			self.weld_strength = newvalue

			if self.Constraint then
				self:Create_Weld()
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
		if IsValid( self.Constraint ) then
			self:SetOverlayText( "Welded" )
		else
			self:SetOverlayText( "Deactivated" )
		end
		return
	end
	local text = self.Constraint and "Welded and " or "Not welded but "
	text = text .. desc
	self:SetOverlayText( text )
end

-- duplicator support
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Ent1 ) then
		info.Ent1 = self.Ent1:EntIndex()
		info.Bone1 = self.Bone1
	end
	if IsValid( self.Ent2 ) then
		info.Ent2 = self.Ent2:EntIndex()
		info.Bone2 = self.Bone2
	end

	info.Activate = self.Constraint and 1 or 0
	info.NoCollide = self.nocollide_status
	info.weld_strength = self.weld_strength

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.Ent1 then
		self.Ent1 = GetEntByID(info.Ent1)
		self.Bone1 = info.Bone1
		if !self.Ent1 then
			self.Ent1 = ents.GetByIndex(info.Ent1)
		end
	end

	if info.Ent2 then
		self.Ent2 = GetEntByID(info.Ent2)
		self.Bone2 = info.Bone2
		if !self.Ent2 then
			self.Ent2 = ents.GetByIndex(info.Ent2)
		end
	end

	-- Default to world entity
	if self.Ent1 or self.Ent2 then
		if self.Ent1 then
			self.Ent2 = self.Ent2 or game.GetWorld()
		else
			self.Ent1 = self.Ent1 or game.GetWorld()
		end
	end

	self:TriggerInput("Strength", info.weld_strength or 0)
	self:TriggerInput("Activate", info.Activate)
	self:TriggerInput("NoCollide", info.NoCollide)
end
