WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "latch", "Weld/Constraint Latch", "gmod_wire_latch", nil, "Constraint Latches" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if CLIENT then
    language.Add( "Tool.wire_latch.name", "Latch Tool (Wire)" )
    language.Add( "Tool.wire_latch.desc", "Makes a controllable latch" )
    language.Add( "Tool.wire_latch.0", "Primary: Click on first entity to be latched" )
    language.Add( "Tool.wire_latch.1", "Left click on the second entity" )
    language.Add( "Tool.wire_latch.2", "Left click to place the controller" )
	language.Add( "undone_wirelatch", "Undone Wire Latch" )
end

function TOOL:LeftClick( trace )
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end

	// If there's no physics object then we can't constraint it!
	if SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 1 ) then
		if CLIENT then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local Ent1, Ent2, Ent3  = self:GetEnt(1),	 self:GetEnt(2), trace.Entity
		local const = self.Constraint

		// Attach controller to the weld constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireLatchController( ply, trace.HitPos, Ang, self:GetModel() )

		if !IsValid(controller) then
			WireLib.AddNotify( self:GetOwner(), "Weld latch controller placement failed!", NOTIFY_GENERIC, 7 )
			self.Constraint = nil
			self:ClearObjects()
			self:SetStage(0)
			return false
		end

		// Send entity and constraint info over to the controller
		controller:SendVars( self.Ent1, self.Ent2, self.Bone1, self.Bone2, self.Constraint )

		// Initialize controller inputs/outputs
		controller:TriggerInput( "Activate", 1 )
		Wire_TriggerOutput( controller, "Welded", 1 )

		// Finish placing the controller
		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld( controller, trace.Entity, trace.PhysicsBone, true )

		undo.Create("WireLatch")
			undo.AddEntity( controller )
			undo.AddEntity( const2 )
			undo.SetPlayer( ply )
		undo.Finish()

		self.Constraint = nil
		self:ClearObjects()
		self:SetStage(0)

	elseif ( iNum == 1 ) then
		if CLIENT then
			return true
		end

		// Get information we're about to use
		self.Ent1,  self.Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		self.Bone1, self.Bone2 = self:GetBone(1),	 self:GetBone(2)

		self.Constraint = MakeWireLatch( self.Ent1, self.Ent2, self.Bone1, self.Bone2 )

		if IsValid(self.Constraint) then
			self:SetStage(2)
		else
			WireLib.AddNotify( self:GetOwner(), "Weld latch invalid!", NOTIFY_GENERIC, 7 )
			self:ClearObjects()
			self:SetStage(0)
		end

	else
		self:SetStage( iNum+1 )

	end

	return true
end

function TOOL:Reload( trace )
	if IsValid(self.Constraint) then
		self.Constraint:Remove()
	end

	self.Constraint = nil
	self:ClearObjects()
	self:SetStage(0)
end

if SERVER then
	function MakeWireLatchController( pl, Pos, Ang, model )
		local controller = ents.Create("gmod_wire_latch")

		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
		controller:SetPlayer(pl)

		controller:Spawn()

		return controller
	end
	duplicator.RegisterEntityClass("gmod_wire_latch", MakeWireLatchController, "Pos", "Ang", "Model")

	function MakeWireLatch( Ent1, Ent2, Bone1, Bone2, forcelimit )
		if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
		if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end

		local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
		local Phys2 = Ent2:GetPhysicsObjectNum( Bone2 )

		if ( Phys1 == Phys2 ) then return false end

		local const = constraint.Weld( Ent1, Ent2, Bone1, Bone2, forcelimit or 0 )

		if !IsValid(const) then return nil end

		const.Type = "" -- prevents the duplicator from copying this weld

		return const
	end
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.wire_latch.name", Description = "#Tool.wire_latch.desc" } )
	WireDermaExts.ModelSelect(panel, "wire_latch_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
