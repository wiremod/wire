TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Weld/Constraint Latch"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if CLIENT then
    language.Add( "Tool_wire_latch_name", "Latch Tool (Wire)" )
    language.Add( "Tool_wire_latch_desc", "Makes a controllable latch" )
    language.Add( "Tool_wire_latch_0", "Primary: Click on first entity to be latched" )
    language.Add( "Tool_wire_latch_1", "Left click on the second entity" )
    language.Add( "Tool_wire_latch_2", "Left click to place the controller" )
	language.Add( "undone_wirelatch", "Undone Wire Latch" )
end

function TOOL:LeftClick( trace )
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 1 ) then

		if ( CLIENT ) then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local Ent1, Ent2, Ent3  = self:GetEnt(1),	 self:GetEnt(2), trace.Entity
		local const = self.constraint

		if ( !const ) or ( !const:IsValid() ) then
			WireLib.AddNotify(self:GetOwner(), "Latch Weld Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		// Attach our Controller to the weld constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireLatchController( ply, trace.HitPos, Ang, self:GetModel() )

		// Send Entity and Constraint info over to the controller
		controller:SendVars(self.Ent1, self.Ent2, self.Bone1, self.Bone2, self.constraint)

		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)

		undo.Create("WireLatch")
			undo.AddEntity( controller )
			undo.AddEntity( const )
			undo.AddEntity( const2 )
			undo.SetPlayer( ply )
		undo.Finish()

		if const then controller:DeleteOnRemove( const ) end

		self:ClearObjects()
		self:SetStage(0)

	elseif ( iNum == 1 ) then

		if ( CLIENT ) then
			return true
		end

		// Get information we're about to use
		self.Ent1,  self.Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		self.Bone1, self.Bone2 = self:GetBone(1),	 self:GetBone(2)

		local const = MakeWireLatch( self.Ent1, self.Ent2, self.Bone1, self.Bone2 )

		self.constraint = const

		undo.Create("WireLatch")
			if constraint then undo.AddEntity( const ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		self:SetStage(2)

	else

		self:SetStage( iNum+1 )

	end

	return true

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

	function MakeWireLatch( Ent1, Ent2, Bone1, Bone2 )
		if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
		if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end

		local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
		local Phys2 = Ent2:GetPhysicsObjectNum( Bone2)

		if ( Phys1 == Phys2 ) then return false end

		local const = constraint.Weld( Ent1, Ent2, Bone1, Bone2, 0 )

		if ( !const ) then return nil end

		return const
	end

end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool_wire_latch_name", Description = "#Tool_wire_latch_desc" } )
	WireDermaExts.ModelSelect(panel, "wire_latch_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
