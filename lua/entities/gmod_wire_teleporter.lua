AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Teleporter"
ENT.WireDebugName 	= "Teleporter"
ENT.Author			= "Divran"

if CLIENT then return end -- No more client

local cooldownCvar = CreateConVar("wire_teleporter_cooldown","1",{FCVAR_ARCHIVE,FCVAR_NOTIFY})

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Jumping = false
	self.TargetPos = self:GetPos()
	self.TargetAng = self:GetAngles()
	self.Entities = {}
	self.LocalPos = {}
	self.LocalAng = {}
	self.LocalVel = {}
	self.UseSounds = true
	self.UseEffects = true

	self.ClassSpecificActions = {
		gmod_wire_hoverball = function( ent, oldpos, newpos ) ent:SetZTarget( newpos.z ) end,
		gmod_toggleablehoverball = function( ent, oldpos, newpos ) ent:SetTargetZ( newpos.z ) end,
		gmod_hoverball = function( ent, oldpos, newpos ) ent.dt.TargetZ = newpos.z end,
	}

	self:ShowOutput()

	self.Inputs = Wire_CreateInputs( self, { "Jump (Activates the teleporter.\nIf nothing happens and an error noise is played, the destination does not have enough room to fit your contraption.)", "TargetPos [VECTOR]", "X", "Y", "Z", "TargetAngle [ANGLE]", "Sound" })
end

function ENT:TriggerInput(iname, value)
	if (iname == "Jump") then
		if (value ~= 0 and not self.Jumping) then
			self:Jump(self.UseAngle or self.Inputs.TargetAngle.Src ~= nil)
			self.UseAngle = false
		end
	elseif (iname == "TargetPos") then
		self.TargetPos = value
	elseif (iname == "X") then
		self.TargetPos.x = value
	elseif (iname == "Y") then
		self.TargetPos.y = value
	elseif (iname == "Z") then
		self.TargetPos.z = value
	elseif (iname == "TargetAngle") then
		self.TargetAng = value
		-- if the angle is set, we should use it for jumping
		-- even if there's nothing connected to the angle wire.
		-- otherwise, we can't use wirelink for angles.
		self.UseAngle = true
	elseif (iname == "Sound") then
		self.UseSounds = value ~= 0
	end
	self:ShowOutput()
end

function ENT:ShowOutput()
	self:SetOverlayText( "Target Position = " .. tostring(self.TargetPos) .. "\nTarget Angle = " .. tostring(self.TargetAng) .. "\nSounds = " .. (self.UseSounds and "Yes" or "No") .. "\nEffects = " .. (self.UseEffects and "Yes" or "No") )
end

function ENT:Jump( withangles )
	--------------------------------------------------------------------
	-- Check for errors
	--------------------------------------------------------------------

	-- Is already teleporting
	if (self.Jumping) then
		return
	end

	-- The target position is outside the world
	if (not util.IsInWorld( self.TargetPos )) then
		self:EmitSound("buttons/button8.wav")
		return
	end

	-- The position or angle hasn't changed
	if (self:GetPos() == self.TargetPos and self:GetAngles() == self.TargetAng) then
		self:EmitSound("buttons/button8.wav")
		return
	end



	--------------------------------------------------------------------
	-- Find other entities
	--------------------------------------------------------------------

	-- Get the localized positions
	local ents = constraint.GetAllConstrainedEntities( self )

	-- If the teleporter is parented, and not constrained, then get the contraption of the parent instead
	local val = next(ents) -- the first value of GetAllConstrainedEntities is always 'self', so we skip this value and check the next
	if next(ents,val) == nil and IsValid(self:GetParent()) then
		ents = constraint.GetAllConstrainedEntities( self:GetParent() )
	end

	-- Check world
	self.Entities = {}
	self.OtherEntities = {}
	for _, ent in pairs( ents ) do
		-- Calculate the position after teleport, without actually moving the entity
		local pos = self:WorldToLocal( ent:GetPos() )
		pos:Rotate( self.TargetAng )
		pos = pos + self.TargetPos

		local b = util.IsInWorld( pos )
		if not b then -- If an entity will be outside the world after teleporting..
			self:EmitSound("buttons/button8.wav")
			return
		elseif ent ~= self then -- if the entity is not equal to self
			if self:CheckAllowed( ent ) then -- If the entity can be teleported
				table.insert(self.Entities, ent)
			else -- If the entity can't be teleported
				self.OtherEntities[#self.OtherEntities+1] = ent
			end
		end
	end

	-- All error checking passed
	self.Jumping = true

	--------------------------------------------------------------------
	-- Sound and visual effects
	--------------------------------------------------------------------
	if self.UseSounds then self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav") end -- Starting sound

	if self.UseEffects then
		-- Effect out
		local effectdata = EffectData()
		effectdata:SetEntity( self )
		local Dir = (self.TargetPos - self:GetPos())
		Dir:Normalize()
		effectdata:SetOrigin( self:GetPos() + Dir * math.Clamp( self:BoundingRadius() * 5, 180, 4092 ) )
		util.Effect( "jump_out", effectdata, true, true )

		DoPropSpawnedEffect( self )

		for _, ent in pairs( ents ) do
			-- Effect out
			local effectdata = EffectData()
			effectdata:SetEntity( ent )
			effectdata:SetOrigin( self:GetPos() + Dir * math.Clamp( ent:BoundingRadius() * 5, 180, 4092 ) )
			util.Effect( "jump_out", effectdata, true, true )
		end
	end

	-- Call the next stage after a short time. This small delay is necessary for sounds and effects to work properly.
	timer.Simple( 0.05, function()
		if not IsValid( self ) then return end
		self:Jump_Part2( withangles )
	end )
end

function ENT:Jump_Part2( withangles )
	local OldPos = self:GetPos()

	--------------------------------------------------------------------
	-- Other entities
	--------------------------------------------------------------------

	-- Save local positions, angles, and velocity
	self.LocalPos = {}
	self.LocalAng = {}
	self.LocalVel = {}
	for k, ent in pairs(self.Entities) do
		if IsValid(ent) then
			if (ent:GetPhysicsObjectCount() > 1) then -- Check for bones
				local tbl = { Main = self:WorldToLocal( ent:GetPos() ) }
				local tbl2 = { Main = self:WorldToLocal( ent:GetVelocity() + ent:GetPos() ) }

				for i=0, ent:GetPhysicsObjectCount()-1 do
					local b = ent:GetPhysicsObjectNum( i )
					tbl[i] = ent:WorldToLocal( b:GetPos() )

					tbl2[i] = ent:WorldToLocal( ent:GetPos() + b:GetVelocity() )
					b:SetVelocity( b:GetVelocity() * -1 )
				end

				-- Save the localized position table
				self.LocalPos[ent] = tbl

				-- Save the localized velocity table
				self.LocalVel[ent] = tbl2
			else
				-- Save the localized position
				self.LocalPos[ent] = self:WorldToLocal( ent:GetPos() )

				-- Save the localized velocity
				self.LocalVel[ent] = self:WorldToLocal( ent:GetVelocity() + ent:GetPos() )
			end

			ent:SetVelocity( ent:GetVelocity() * -1 )

			if withangles then
				self.LocalAng[ent] = self:WorldToLocalAngles( ent:GetAngles() )
			end
		else
			self.Entities[k] = nil
		end
	end

	--------------------------------------------------------------------
	-- The teleporter itself
	--------------------------------------------------------------------

	-- Save old parent and then unparent the teleporter (is restored after teleporting)
	-- This prevents an issue that deletes the entire contraption
	local parent = self:GetParent()
	self:SetParent()

	local oldvel = self:WorldToLocal( self:GetVelocity() + self:GetPos() ) -- Velocity
	self:SetPos( self.TargetPos ) -- Position
	if withangles then self:SetAngles( self.TargetAng )	end -- Angle
	self:GetPhysicsObject():SetVelocity( self:LocalToWorld( oldvel ) - self:GetPos() ) -- Set new velocity

	if self.UseSounds then self:EmitSound("npc/turret_floor/die.wav", 450, 70) end -- Sound

	local Dir = (OldPos - self:GetPos()):GetNormalized()
	if self.UseEffects then
		-- Effect
		effectdata = EffectData()
		effectdata:SetEntity( self )
		effectdata:SetOrigin( self:GetPos() + Dir * math.Clamp( self:BoundingRadius() * 5, 180, 4092 ) )
		util.Effect( "jump_in", effectdata, true, true )
	end

	--------------------------------------------------------------------
	-- Other entities
	--------------------------------------------------------------------

	for k, ent in pairs(self.Entities) do
		if IsValid(ent) then
			local oldPos = ent:GetPos() -- Remember old position
			if withangles then ent:SetAngles( self:LocalToWorldAngles( self.LocalAng[ent] ) ) end -- Angles

			if (ent:GetPhysicsObjectCount() > 1) then -- Check for bones
				ent:SetPos( self:LocalToWorld( self.LocalPos[ent].Main ) ) -- Position

				-- Set new velocity
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:SetVelocity( self:LocalToWorld( self.LocalVel[ent].Main ) - ent:GetPos() )
				else
					ent:SetVelocity( self:LocalToWorld( self.LocalVel[ent].Main ) )
				end

				for i=0, ent:GetPhysicsObjectCount()-1 do -- For each bone...
					local b = ent:GetPhysicsObjectNum( i )

					b:SetPos( ent:LocalToWorld(self.LocalPos[ent][i]) ) -- Position
					b:SetVelocity( ent:LocalToWorld( self.LocalVel[ent][i] ) - ent:GetPos() ) -- Set new velocity
				end

				ent:GetPhysicsObject():Wake()
			else -- If it doesn't have bones
				ent:SetPos( self:LocalToWorld(self.LocalPos[ent]) ) -- Position

				-- Set new velocity
				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:SetVelocity( self:LocalToWorld( self.LocalVel[ent] ) - ent:GetPos() )
				else
					ent:SetVelocity( self:LocalToWorld( self.LocalVel[ent] ) )
				end

				ent:GetPhysicsObject():Wake()
			end

			if self.UseEffects then
				-- Effect in
				effectdata = EffectData()
				effectdata:SetEntity( ent )
				effectdata:SetOrigin( self:GetPos() + Dir * math.Clamp( ent:BoundingRadius() * 5, 180, 4092 ) )
				util.Effect( "jump_in", effectdata, true, true )
				DoPropSpawnedEffect( ent )
			end


			if self.ClassSpecificActions[ent:GetClass()] then -- Call function specific for this entity class
				self.ClassSpecificActions[ent:GetClass()]( ent, oldPos, ent:GetPos() )
			end
		else
			self.Entities[k] = nil
		end
	end

	if self.UseEffects then
		for _, ent in pairs( self.OtherEntities ) do -- Render the effect on all other entities in the contraption
			-- Effect in
			effectdata = EffectData()
			effectdata:SetEntity( ent )
			effectdata:SetOrigin( self:GetPos() + Dir * math.Clamp( ent:BoundingRadius() * 5, 180, 4092 ) )
			util.Effect( "jump_in", effectdata, true, true )
			DoPropSpawnedEffect( ent )
		end
	end

	self:SetParent( parent ) -- restore parent

	-- Cooldown - prevent teleporting for a time
	timer.Create(
		"teleporter_"..self:EntIndex(), -- name
		cooldownCvar:GetFloat(), -- delay
		1, -- nr of runs
		function() -- function
			if self:IsValid() then
				self.Jumping = false
			end
		end
	)
end

function ENT:CheckAllowed( e )
	if (e:GetParent():EntIndex() ~= 0) then return false end

	-- These shouldn't happen, ever, but they're here just to be safe
	local c = e:GetClass()
	if c == "Player" or c:find("npc_") then return false end

	return true
end

function ENT:Setup(UseSounds, UseEffects)
	self.UseSounds = UseSounds
	self.UseEffects = UseEffects
	self:ShowOutput()
end

duplicator.RegisterEntityClass("gmod_wire_hoverdrivecontroler", WireLib.MakeWireEnt, "Data", "UseSounds", "UseEffects" )
duplicator.RegisterEntityClass("gmod_wire_teleporter", WireLib.MakeWireEnt, "Data", "UseSounds", "UseEffects")
scripted_ents.Alias("gmod_wire_hoverdrivecontroler", "gmod_wire_teleporter")
