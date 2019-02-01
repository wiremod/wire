AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Constraint Latch"
ENT.Purpose         = "Controllable weld and nocollide between two selected entities"
ENT.WireDebugName = "Latch"

if CLIENT then return end -- No more client

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
	self.IsPasting = false
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
	if self.IsPasting then return end
	if self.Constraint then
		if self.Constraint:IsValid() then
			self.Constraint:Remove()
		end
		self.Constraint = nil
	end
end

function ENT:Post_Weld()
	if not IsValid(self.Constraint) then return end

	if not self.CreationID then
		self.CreationID = self.Constraint:GetCreationID()
	end
	self.Constraint:CallOnRemove( "Weld Latch Removed", Weld_Removed, self )

	-- Hack the creation ID so the duplicator orders the weld in the original order it was created in
	local ent_meta = FindMetaTable("Entity")
	local override_meta = {
		__index = function(t,k)
			if k=="GetCreationID" then
				return function() return self.CreationID end
			else
				return ent_meta.__index(t,k)
			end
		end,
		__concat = ent_meta.__concat,
		__tostring = ent_meta.__tostring,
		__newindex = ent_meta.__newindex,
		__eq = ent_meta.__eq
	}
	debug.setmetatable(self.Constraint, override_meta)

end

function ENT:Create_Weld()
	if self.IsPasting then return end
	self:Remove_Weld()
	self.Constraint = MakeWireLatch( self.Ent1, self.Ent2, self.Bone1, self.Bone2, self.weld_strength or 0 )
	self:Post_Weld()
end

-- This function is called by the STOOL
function ENT:SendVars( Ent1, Ent2, Bone1, Bone2, const )
	self.Ent1 = Ent1
	self.Ent2 = Ent2
	self.Bone1 = Bone1
	self.Bone2 = Bone2
	self.Constraint = const
	self:Post_Weld()
end

function ENT:TriggerInput( iname, value )
	if iname == "Activate" then
		if value == 0 then
			self:Remove_Weld()

		elseif not self.Constraint then
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
	local info = BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Ent1 ) then
		info.Ent1 = self.Ent1:EntIndex()
		info.Bone1 = self.Bone1
	end
	if IsValid( self.Ent2 ) then
		info.Ent2 = self.Ent2:EntIndex()
		info.Bone2 = self.Bone2
	end

	info.new = true
	info.Activate = self.Constraint and 1 or 0
	info.NoCollide = self.nocollide_status
	info.weld_strength = self.weld_strength

	if not IsValid(self.Constraint) then
		self:Create_Weld()
		timer.Simple(0, function()
			if self:IsValid() then
				self:Remove_Weld()
			end
		end)
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Ent1 = GetEntByID(info.Ent1, game.GetWorld())
	if IsValid(self.Ent1) then
		self.Bone1 = info.Bone1
	end

	self.Ent2 = GetEntByID(info.Ent2, game.GetWorld())
	if IsValid(self.Ent2) then
		self.Bone2 = info.Bone2
	end

	if info.new then
		self.IsPasting = true -- Don't use this if it's an old wire latch that uses old behavior
	else
		self:TriggerInput("Activate", info.Activate)
	end
	self:TriggerInput("Strength", info.weld_strength or 0)
	self:TriggerInput("NoCollide", info.NoCollide)
end

hook.Add("AdvDupe_FinishPasting", "Wire_Latch", function(TimedPasteData, TimedPasteDataCurrent)
	for k, v in pairs(TimedPasteData[TimedPasteDataCurrent].CreatedEntities) do
		if IsValid(v) and v:GetClass() == "gmod_wire_latch" and v.IsPasting then
			v.IsPasting = false
			if v.Ent1 and v.Ent2 then
				for k, c1 in pairs(constraint.FindConstraints( v.Ent1, "Weld" )) do
					for k, c2 in pairs(constraint.FindConstraints( v.Ent2, "Weld" )) do
						if c1.Constraint == c2.Constraint then
							v.Constraint = c1.Constraint
							v:Post_Weld()
							goto Exit_DoubleLoop
						end
					end
				end
				::Exit_DoubleLoop::
				v:TriggerInput("Activate", v.Inputs.Activate.Value)
			end
		end
	end
end)

duplicator.RegisterEntityClass("gmod_wire_latch", WireLib.MakeWireEnt, "Data")

function MakeWireLatch( Ent1, Ent2, Bone1, Bone2, forcelimit )
	if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
	if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end

	local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
	local Phys2 = Ent2:GetPhysicsObjectNum( Bone2 )

	if ( Phys1 == Phys2 ) then return false end

	local const = constraint.Weld( Ent1, Ent2, Bone1, Bone2, forcelimit or 0 )

	if !IsValid(const) then return nil end

	return const
end
