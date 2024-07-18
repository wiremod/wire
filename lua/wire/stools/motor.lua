WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "motor", "Motor", "gmod_wire_motor", nil, "Motors" )

if CLIENT then
	language.Add( "Tool.wire_motor.name", "Motor Tool (Wire)" )
	language.Add( "Tool.wire_motor.desc", "Makes a controllable motor" )
	language.Add( "WireMotorTool_torque", "Torque:" )
	language.Add( "WireMotorTool_friction", "Hinge Friction:" )
	language.Add( "WireMotorTool_nocollide", "No Collide" )
	language.Add( "WireMotorTool_forcelimit", "Force Limit:" )
	language.Add( "WireMotorTool_offset", "Position Offset:" )
	TOOL.Information = {
		{ name = "left_0",   stage = 0, text = "Choose the wheel's axis" },
		{ name = "reload_0", stage = 0, text = "Remove wire motor constraint" },
		{ name = "left_1",   stage = 1, text = "Choose the base's axis" },
		{ name = "reload_1", stage = 1, text = "Cancel wire motor" },
		{ name = "left_2",   stage = 2, text = "Place the controller" },
		{ name = "reload_2", stage = 2, text = "Cancel wire motor" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:MakeEnt(ply, model, Ang, trace)
		return MakeWireMotorController(ply, trace.HitPos, Ang, nil, model, self.constraint, self.axis)
	end
end

function TOOL:GetConVars()
	return self:GetClientNumber( "torque" ),
			self:GetClientNumber( "friction" ),
			self:GetClientNumber( "nocollide" ),
			self:GetClientNumber( "forcelimit" ),
			self:GetClientNumber( "offset" )
end

function TOOL:LeftClick_Update( trace )
	local const = trace.Entity.constraint
	if IsValid( const ) then
		-- Don't remove the controller when the constraint is removed
		const:DontDeleteOnRemove( trace.Entity )
		if IsValid(trace.Entity.axis) then trace.Entity.axis:DontDeleteOnRemove( trace.Entity ) end
		-- Get constraint info
		local tbl = const:GetTable()
		-- Remove constraint
		const:Remove()

		-- Get convars
		local torque, friction, nocollide, forcelimit = self:GetConVars()

		-- Make new constraint, at the old constraint's position, but with the new convar settings
		local const, axis = MakeWireMotor( self:GetOwner(),
								tbl.Ent1, tbl.Ent2,
								tbl.Bone1, tbl.Bone2,
								tbl.LPos1, tbl.LPos2,
								friction, torque, nocollide, forcelimit )

		-- Set the new references
		const.MyCrtl = trace.Entity:EntIndex()
		trace.Entity:SetConstraint( const )
		trace.Entity:DeleteOnRemove( const )

		if axis then
			trace.Entity:SetAxis( axis )
			trace.Entity:DeleteOnRemove( axis )
		end
	end
end

function TOOL:LeftClick( trace )
	if IsValid( trace.Entity ) and trace.Entity:IsPlayer() then return end

	-- If there's no physics object then we can't constraint it!
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local iNum = self:NumObjects()
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

	-- Update existing constraint
	if self:CheckHitOwnClass( trace ) and iNum == 0 then
		if SERVER then
			self:LeftClick_Update( trace )
		end
		return true
	end

	-- Don't allow us to choose the world as the first object
	if iNum == 0 and not IsValid( trace.Entity ) then return end

	-- Don't allow us to choose the same object
	if iNum == 1 and trace.Entity == self:GetEnt(1) then return end


	-- Get client's CVars
	local torque, friction, nocollide, forcelimit, offset = self:GetConVars()

	if iNum > 1 then
		if CLIENT then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local Ent1, Ent2, Ent3 = self:GetEnt(1), self:GetEnt(2), trace.Entity
		local const, axis = self.constraint, self.axis

		if not const or not IsValid( const ) then
			WireLib.AddNotify(self:GetOwner(), "Wire Motor Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		local controller = self:LeftClick_Make(trace, ply)
		if isbool(controller) then return controller end
		self:LeftClick_PostMake(controller, ply, trace)

		if controller then
			controller:DeleteOnRemove( const )
			if axis then controller:DeleteOnRemove( axis ) end
		end

		self:ClearObjects()
		self:SetStage(0)
	elseif iNum == 1 then
		self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		if CLIENT then
			self:ClearObjects()
			self:ReleaseGhostEntity()
			return true
		end

		local Ent1,  Ent2  = self:GetEnt(1),	  self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	  self:GetBone(2)
		local WPos1, WPos2 = self:GetPos(1),	  self:GetPos(2)
		local LPos1, LPos2 = self:GetLocalPos(1), self:GetLocalPos(2)
		local Norm1, Norm2 = self:GetNormal(1),	  self:GetNormal(2)
		local Phys1, Phys2 = self:GetPhys(1), 	  self:GetPhys(2)

		-- Note: To keep stuff ragdoll friendly try to treat things as physics objects rather than entities
		local Ang1, Ang2 = Norm1:Angle(), (Norm2 * -1):Angle()
		local TargetAngle = Phys1:AlignAngles( Ang1, Ang2 )

		Phys1:SetAngles( TargetAngle )

		-- Move the object so that the hitpos on our object is at the second hitpos
		local TargetPos = WPos2 + (Phys1:GetPos() - self:GetPos(1))

		-- Set the position
		Phys1:SetPos( TargetPos )

		-- Wake up the physics object so that the entity updates
		Phys1:Wake()

		-- Set the hinge Axis perpendicular to the trace hit surface
		LPos1 = Phys1:WorldToLocal( WPos2 + Norm2 * 64 )

		local constraint, axis = MakeWireMotor( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, friction, torque, nocollide, forcelimit )
		self.constraint, self.axis = constraint, axis

		undo.Create("gmod_wire_motor")
			if axis then undo.AddEntity( axis ) end
			if constraint then undo.AddEntity( constraint ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		if axis then self:GetOwner():AddCleanup( "constraints", axis ) end
		if constraint then self:GetOwner():AddCleanup( "constraints", constraint ) end

		self:SetStage(2)
		self:ReleaseGhostEntity()
	else
		offset = math.Clamp(offset, 0, 1024)
		self:SetObject( iNum + 1, trace.Entity, trace.HitPos + trace.HitNormal*offset, Phys, trace.PhysicsBone, trace.HitNormal )
		self:StartGhostEntity( trace.Entity )
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Reload( trace )
	if self:GetStage() > 0 then
		self:ClearObjects()
		self:SetStage(0)
		self:ReleaseGhostEntity()
	else
		if not IsValid( trace.Entity ) or trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end
	
		return constraint.RemoveConstraints( trace.Entity, "WireMotor" )
	end
end

function TOOL:Think()
	if self:NumObjects() == 1 then self:UpdateGhostEntity() end
end

TOOL.ClientConVar = {
	torque = 500,
	friction = 1,
	nocollide = 1,
	forcelimit = 0,
	offset = 2,
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

function TOOL.BuildCPanel(panel)
	local models = {
		["models/jaanus/wiretool/wiretool_siren.mdl"] = true,
		["models/jaanus/wiretool/wiretool_controlchip.mdl"] = true,
		["models/fasteroid/inductor.mdl"] = true
	}

	WireDermaExts.ModelSelect( panel, "wire_motor_model", models, 1 )
	panel:NumSlider( "#WireMotorTool_torque", "wire_motor_torque", 0, 10000, 5 )
	panel:NumSlider( "#WireMotorTool_forcelimit", "wire_motor_forcelimit", 0, 50000, 10 )
	panel:NumSlider( "#WireMotorTool_friction", "wire_motor_friction", 0, 100, 1 )
	panel:NumSlider( "#WireMotorTool_offset", "wire_motor_offset", 0, 512, 2 )
	panel:CheckBox( "#WireMotorTool_nocollide", "wire_motor_nocollide" )
end
