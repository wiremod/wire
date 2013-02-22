WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hydraulic", "Hydraulic", "gmod_wire_hydraulic", nil, "Hydraulics" )

TOOL.ClientConVar[ "material" ] = "cable/rope"
TOOL.ClientConVar[ "width" ] = "3"
TOOL.ClientConVar[ "fixed" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/beer/wiremod/hydraulic.mdl"
TOOL.ClientConVar[ "modelsize" ] = ""

if SERVER then
	ModelPlug_Register("Hydraulic")
end

if CLIENT then
	language.Add( "Tool.wire_hydraulic.name", "Hydraulic Tool (Wire)" )
	language.Add( "Tool.wire_hydraulic.desc", "Makes a controllable hydraulic" )
	language.Add( "Tool.wire_hydraulic.0", "Primary: Place hydraulic\nSecondary: Place hydraulic along the hit normal" )
	language.Add( "Tool.wire_hydraulic.1", "Left click on the second point" )
	language.Add( "Tool.wire_hydraulic.2", "Left click to place the controller" )
	language.Add( "WireHydraulicTool_width", "Width:" )
	language.Add( "WireHydraulicTool_material", "Material:" )
	language.Add( "WireHydraulicTool_fixed", "Fixed" )
	language.Add( "undone_wirehydraulic", "Undone Wire Hydraulic" )
end

function TOOL:LeftClick( trace )
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
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
		local const, rope = self.constraint, self.rope

		if ( !const ) or ( !const:IsValid() ) then
			WireLib.AddNotify(self:GetOwner(), "Wire Hydraulic Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		local model = self:GetModel()

		// Attach our Controller to the Elastic constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireHydraulicController(ply, trace.HitPos, Ang, model, nil, const, rope)

		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)

		undo.Create("WireHydraulic")
			undo.AddEntity( controller )
			undo.AddEntity( const )
			undo.AddEntity( rope )
			undo.AddEntity( const2 )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( "ropeconstraints", controller )
		ply:AddCleanup( "ropeconstraints", const2 )

		if const then controller:DeleteOnRemove( const ) end
		if rope then controller:DeleteOnRemove( rope ) end

		self:ClearObjects()
		self:SetStage(0)

	elseif ( iNum == 1 ) then

		if ( CLIENT ) then
			return true
		end

		// Get client's CVars
		local material		= self:GetClientInfo( "material" ) or "cable/rope"
		local width		= self:GetClientNumber( "width" )  or 3
		local fixed		= self:GetClientNumber( "fixed" ) or 0

		// Get information we're about to use
		local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
		local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)

		local const,rope = MakeWireHydraulic( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, fixed )

		self.constraint, self.rope = const,rope

		undo.Create("WireHydraulic")
			if constraint then undo.AddEntity( const ) end
			if rope   then undo.AddEntity( rope ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()

		if const then	self:GetOwner():AddCleanup( "ropeconstraints", const ) end
		if rope then		self:GetOwner():AddCleanup( "ropeconstraints", rope ) end

		self:SetStage(2)

	else

		self:SetStage( iNum+1 )

	end

	return true

end

function TOOL:RightClick( trace )

	local iNum = self:NumObjects()

	if ( iNum > 1 ) then
		if ( !self.constraint ) or ( !self.constraint:IsValid() ) then
			self:ClearObjects()
			self:SetStage(0)
		else
			return false
		end
	end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	local tr = {}
	tr.start = trace.HitPos
	tr.endpos = tr.start + (trace.HitNormal * 16384)
	tr.filter = {}
	tr.filter[1] = self:GetOwner()
	if (trace.Entity:IsValid()) then
		tr.filter[2] = trace.Entity
	end

	local tr = util.TraceLine( tr )

	if ( !tr.Hit ) then
		self:ClearObjects()
		return
	end

	// Don't try to constrain world to world
	if ( trace.HitWorld && tr.HitWorld ) then
		self:ClearObjects()
		return
	end

	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then
		self:ClearObjects()
		return
	end
	if ( tr.Entity:IsValid() && tr.Entity:IsPlayer() ) then
		self:ClearObjects()
		return
	end

	local Phys2 = tr.Entity:GetPhysicsObjectNum( tr.PhysicsBone )
	self:SetObject( 2, tr.Entity, tr.HitPos, Phys2, tr.PhysicsBone, trace.HitNormal )

	if ( CLIENT ) then
		return true
	end

	// Get client's CVars
	local material		= self:GetClientInfo( "material" ) or "cable/rope"
	local width			= self:GetClientNumber( "width" ) or 3
	local fixed			= self:GetClientNumber( "fixed" ) or 0

	// Get information we're about to use
	local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
	local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
	local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)

	local const,rope = MakeWireHydraulic( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, fixed )

	self.constraint, self.rope = const,rope

	undo.Create("WireHydraulic")
		if const then undo.AddEntity( const ) end
		if rope   then undo.AddEntity( rope ) end
		if controller then undo.AddEntity( controller ) end
		undo.SetPlayer( self:GetOwner() )
	undo.Finish()

	if constraint then	self:GetOwner():AddCleanup( "ropeconstraints", const ) end
	if rope then		self:GetOwner():AddCleanup( "ropeconstraints", rope ) end

	self:SetStage(2)

	return true

end

if SERVER then

	local function CalcElasticConsts(Phys1, Phys2, Ent1, Ent2)
		local minMass = 0;

		if ( Ent1:IsWorld() ) then minMass = Phys2:GetMass()
		elseif ( Ent2:IsWorld() ) then minMass = Phys1:GetMass()
		else
			minMass = math.min( Phys1:GetMass(), Phys2:GetMass() )
		end

		// const, damp
		local const = minMass * 100
		local damp = const * 0.2

		if ( iFixed == 0 ) then

			const = minMass * 50
			damp = const * 0.1

		end

		return const, damp
	end

	//need for the const to find the controler after being duplicator pasted
	WireHydraulicTracking = {}

	function MakeWireHydraulicController( pl, Pos, Ang, model, MyEntId, const, rope )
		local controller = ents.Create("gmod_wire_hydraulic")

		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:Setup()
		controller:SetPlayer(pl)

		if (!const) then
			WireHydraulicTracking[ MyEntId ] = controller
		else
			controller.MyId = controller:EntIndex()
			const.MyCrtl = controller:EntIndex()
			controller:SetConstraint( const )
			controller:DeleteOnRemove( const )
		end

		controller:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )

		if (rope) then
			controller:SetRope( rope )
			controller:DeleteOnRemove( rope )
		end

		controller:Spawn()

		return controller
	end

	duplicator.RegisterEntityClass("gmod_wire_hydraulic", MakeWireHydraulicController, "Pos", "Ang", "Model", "MyId" )

	function MakeWireHydraulic( pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, fixed, MyCrtl )
		if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
		if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end

		local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
		local Phys2 = Ent2:GetPhysicsObjectNum( Bone2)
		local WPos1 = Phys1:LocalToWorld( LPos1 )
		local WPos2 = Phys2:LocalToWorld( LPos2 )

		if ( Phys1 == Phys2 ) then return false end

		local constant, dampen = CalcElasticConsts( Phys1, Phys2, Ent1, Ent2 )

		local const, rope = constraint.Elastic( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, constant, dampen, 0, material, width, false )

		if fixed == 1 then
			local slider = constraint.Slider( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0 )
			slider:SetTable( {} )
			const:DeleteOnRemove( slider )
		end

		if ( !const ) then return nil, rope end

		local ctable = {
			Type     = "WireHydraulic",
			pl       = pl,
			Ent1     = Ent1,
			Ent2     = Ent2,
			Bone1    = Bone1,
			Bone2    = Bone2,
			LPos1    = LPos1,
			LPos2    = LPos2,
			width    = width,
			material = material,
			fixed    = fixed
		}
		const:SetTable( ctable )

		if (MyCrtl) then
			--Msg("finding crtl for this wired hyd const\n")
			local controller = WireHydraulicTracking[ MyCrtl ]

			const.MyCrtl = controller:EntIndex()
			controller.MyId = controller:EntIndex()

			controller:SetConstraint( const )
			controller:DeleteOnRemove( const )
			if (rope) then
				controller:SetRope( rope )
				controller:DeleteOnRemove( rope )
			end

			Ent1:DeleteOnRemove( controller )
			Ent2:DeleteOnRemove( controller )
			const:DeleteOnRemove( controller )
		end

		return const, rope
	end

	duplicator.RegisterConstraint( "WireHydraulic", MakeWireHydraulic, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width", "material", "fixed", "MyCrtl" )

end

function TOOL:Reload( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end

	local  bool = constraint.RemoveConstraints( trace.Entity, "WireHydraulic" )
	return bool

end

function TOOL:Think() end -- Disable ghost

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSizer(panel, "wire_hydraulic_modelsize")
	WireDermaExts.ModelSelect(panel, "wire_hydraulic_model", list.Get( "Wire_Hydraulic_Models" ), 1, true)
	panel:CheckBox("#WireHydraulicTool_fixed","wire_hydraulic_fixed")
	panel:NumSlider("#WireHydraulicTool_width","wire_hydraulic_width",1,20,2)
	panel:AddControl( "RopeMaterial", { Label = "#WireHydraulicTool_material", convar = "wire_hydraulic_material" } )
end
