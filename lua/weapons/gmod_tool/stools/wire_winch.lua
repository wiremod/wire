TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Winch"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

TOOL.ClientConVar = {
	material = "cable/rope",
	width = "3",
	fwd_speed = "64",
	bwd_speed = "64",
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
}

if CLIENT then
	language12.Add( "Tool_wire_winch_name", "Winch Tool (Wire)" )
	language12.Add( "Tool_wire_winch_desc", "Makes a controllable winch" )
	language12.Add( "Tool_wire_winch_0", "Primary: Place winch\nSecondary: Place winch along the hit normal" )
	language12.Add( "Tool_wire_winch_1", "Left click on the second point" )
	language12.Add( "Tool_wire_winch_2", "Left click to place the controller" )
	language12.Add( "WireWinchTool_width", "Width:" )
	language12.Add( "WireWinchTool_material", "Material:" )
	language12.Add( "WireWinchTool_fixed", "Fixed" )
	language12.Add( "undone_wirewinch", "Undone Wire Winch" )
end


function TOOL:LeftClick( trace )
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end

	-- If there's no physics object then we can't constraint it!
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
			WireLib.AddNotify(self:GetOwner(), "Wire Winch Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		-- Attach our Controller to the Elastic constraint
		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireWinchController(ply, trace.HitPos, Ang, self:GetModel(), nil, const, rope)

		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld(controller, trace.Entity, trace.PhysicsBone, true)

		undo.Create("WireWinch")
			undo.AddEntity( controller )
			undo.AddEntity( const )
			undo.AddEntity( rope )
			undo.AddEntity( const2 )
			undo.SetPlayer( ply )
		undo.Finish()

		if (ply!=nil) then ply:AddCleanup( "ropeconstraints", controller ) end
		if (ply!=nil) then ply:AddCleanup( "ropeconstraints", const2 ) end

		if const then controller:DeleteOnRemove( const ) end
		if rope then controller:DeleteOnRemove( rope ) end

		self:ClearObjects()
		self:SetStage(0)

	elseif ( iNum == 1 ) then

		if ( CLIENT ) then
			return true
		end

		-- Get client's CVars
		local material		= self:GetClientInfo( "material" ) or "cable/rope"
		local width		= self:GetClientNumber( "width" )  or 3
		local fwd_speed		= self:GetClientNumber( "fwd_speed" ) or 64
		local bwd_speed		= self:GetClientNumber( "bwd_speed" ) or 64

		-- Get information we're about to use
		local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
		local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)

		local const,rope = MakeWireWinch( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, fwd_speed, bwd_speed, material )

		self.constraint, self.rope = const,rope

		undo.Create("WireWinch")
			if constraint then undo.AddEntity( const ) end
			if rope   then undo.AddEntity( rope ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()


		if const then	self:GetOwner():AddCleanup( "ropeconstraints", const ) end
		if rope then	self:GetOwner():AddCleanup( "ropeconstraints", rope ) end

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

	-- If there's no physics object then we can't constraint it!
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

	-- Don't try to constrain world to world
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

	-- Get client's CVars
	local material		= self:GetClientInfo( "material" ) or "cable/rope"
	local width			= self:GetClientNumber( "width" ) or 3
	local fwd_speed		= self:GetClientNumber( "fwd_speed" ) or 64
	local bwd_speed		= self:GetClientNumber( "bwd_speed" ) or 64

	-- Get information we're about to use
	local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
	local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
	local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)

	local const,rope = MakeWireWinch( self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, fwd_speed, bwd_speed, material )

	self.constraint, self.rope = const,rope

	undo.Create("WireWinch")
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

		-- const, damp
		local const = minMass * 100
		local damp = const * 0.2

		if ( iFixed == 0 ) then

			const = minMass * 50
			damp = const * 0.1

		end

		return const, damp
	end

	--need for the const to find the controler after being duplicator pasted
	WireWinchTracking = {}

	local function SetWinchParameters(controller, const, rope)
		controller.MyId = controller:EntIndex()

		if const then
			const.MyCrtl = controller:EntIndex()
			controller:SetConstraint( const )
			controller:DeleteOnRemove( const )
		end

		if rope then
			controller:SetRope( rope )
			controller:DeleteOnRemove( rope )
		end
	end

	function MakeWireWinchController( pl, Pos, Ang, model, MyId, const, rope )
		local controller = ents.Create("gmod_wire_winch_controller")

		controller:SetPos( Pos )
		controller:SetAngles( Ang )
		controller:SetModel(model)
		controller:Setup()
		controller:SetPlayer(pl)
		controller:Spawn()

		SetWinchParameters(controller, const, rope)
		if MyId then
			WireWinchTracking[ MyId ] = controller
		end

		return controller
	end

	duplicator.RegisterEntityClass("gmod_wire_winch_controller", MakeWireWinchController, "Pos", "Ang", "Model", "MyId")

	function MakeWireWinch( pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, fwd_speed, bwd_speed, material, MyCrtl )
		if ( !constraint.CanConstrain( Ent1, Bone1 ) ) then return false end
		if ( !constraint.CanConstrain( Ent2, Bone2 ) ) then return false end

		local Phys1 = Ent1:GetPhysicsObjectNum( Bone1 )
		local Phys2 = Ent2:GetPhysicsObjectNum( Bone2 )
		local WPos1 = Phys1:LocalToWorld( LPos1 )
		local WPos2 = Phys2:LocalToWorld( LPos2 )

		if ( Phys1 == Phys2 ) then return false end

		local constant, dampen = CalcElasticConsts( Phys1, Phys2, Ent1, Ent2 )

		local const, rope = constraint.Elastic( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, constant, dampen, 0, material, width, true )

		if ( !const ) then return nil, rope end

		local ctable = {
			Type 		= "WireWinch",
			pl			= pl,
			Ent1		= Ent1,
			Ent2		= Ent2,
			Bone1		= Bone1,
			Bone2		= Bone2,
			LPos1		= LPos1,
			LPos2		= LPos2,
			width		= width,
			fwd_speed	= fwd_speed,
			bwd_speed	= bwd_speed,
			material	= material
		}
		const:SetTable( ctable ) -- Shouldn't this be merged instead of replaced?

		if (MyCrtl) then
			--Msg("finding crtl for this wired wnc const\n")
			local controller = WireWinchTracking[ MyCrtl ]

			SetWinchParameters(controller, const, rope)

			Ent1:DeleteOnRemove( controller )
			Ent2:DeleteOnRemove( controller )
			const:DeleteOnRemove( controller )
		end

		return const, rope
	end

	duplicator.RegisterConstraint( "WireWinch", MakeWireWinch, "pl", "Ent1", "Ent2", "Bone1", "Bone2", "LPos1", "LPos2", "width", "fwd_speed", "bwd_speed", "material", "MyCrtl" )

end

function TOOL:Reload( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end

	local  bool = constraint.RemoveConstraints( trace.Entity, "WireWinch" )
	return bool

end

function TOOL:GetModel()
	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local modelcheck = self:GetClientInfo( "model" )

	if (util.IsValidModel(modelcheck) and util.IsValidProp(modelcheck)) then
		model = modelcheck
	end

	return model
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_winch_name", Description = "#Tool_wire_winch_desc" })
	WireDermaExts.ModelSelect(panel, "wire_winch_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

	panel:AddControl("CheckBox", {
		Label = "#WireWinchTool_fixed",
		Command = "wire_winch_fixed"
	})

	panel:AddControl("Slider", {
		Label = "#WireWinchTool_width",
		Type = "Float",
		Min = "1",
		Max = "20",
		Command = "wire_winch_width"
	})

	panel:AddControl("MaterialGallery", {
		Label = "#WireWinchTool_material",
		Height = "64",
		Width = "28",
		Rows = "1",
		Stretch = "1",

		Options = {
			["Wire"] = { Material = "cable/rope_icon", wire_winch_material = "cable/rope" },
			["Cable 2"] = { Material = "cable/cable_icon", wire_winch_material = "cable/cable2" },
			["XBeam"] = { Material = "cable/xbeam", wire_winch_material = "cable/xbeam" },
			["Red Laser"] = { Material = "cable/redlaser", wire_winch_material = "cable/redlaser" },
			["Blue Electric"] = { Material = "cable/blue_elec", wire_winch_material = "cable/blue_elec" },
			["Physics Beam"] = { Material = "cable/physbeam", wire_winch_material = "cable/physbeam" },
			["Hydra"] = { Material = "cable/hydra", wire_winch_material = "cable/hydra" },
		},

		CVars = {
			[0] = "wire_winch_material"
		}
	})
end
