WireToolSetup.setCategory( "Physics/Constraints" )
WireToolSetup.open( "latch", "Weld/Constraint Latch", "gmod_wire_latch", nil, "Constraint Latches" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if CLIENT then
	language.Add( "Tool.wire_latch.name", "Latch Tool (Wire)" )
	language.Add( "Tool.wire_latch.desc", "Makes a controllable latch" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Choose the first entity to be latched" },
		{ name = "left_1", stage = 1, text = "Choose the second entity to be latched" },
		{ name = "reload_1", stage = 1, text = "Cancel" },
		{ name = "left_2", stage = 2, text = "Place the controller" },
		{ name = "reload_2", stage = 2, text = "Cancel" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 15 )

function TOOL:LeftClick( trace )
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end

	// If there's no physics object then we can't constraint it!
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

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

		local controller = self:LeftClick_Make( trace, ply )
		if isbool(controller) then return controller end
		if not IsValid(controller) then
			WireLib.AddNotify( self:GetOwner(), "Weld latch controller placement failed!", NOTIFY_GENERIC, 7 )
			self.Constraint = nil
			self:ClearObjects()
			self:SetStage(0)
			return false
		end
		self:LeftClick_PostMake( controller, ply, trace )

		// Send entity and constraint info over to the controller
		controller:SendVars( self.Ent1, self.Ent2, self.Bone1, self.Bone2, self.Constraint )

		// Initialize controller inputs/outputs
		controller:TriggerInput( "Activate", 1 )
		Wire_TriggerOutput( controller, "Welded", 1 )

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

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.wire_latch.name", Description = "#Tool.wire_latch.desc" } )
	WireDermaExts.ModelSelect(panel, "wire_latch_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
