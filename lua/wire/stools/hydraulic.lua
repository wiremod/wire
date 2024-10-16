WireToolSetup.setCategory( "Physics/Constraints" )
WireToolSetup.open( "hydraulic", "Hydraulic", "gmod_wire_hydraulic", nil, "Hydraulics" )

TOOL.ClientConVar = {
	material = "cable/rope",
	width = "3",
	speed = "16",
	model = "models/beer/wiremod/hydraulic.mdl",
	modelsize = "",
	fixed = "0",
	stretchonly = "0",
}

if CLIENT then
	language.Add( "Tool.wire_hydraulic.name", "Hydraulic Tool (Wire)" )
	language.Add( "Tool.wire_hydraulic.desc", "Makes a controllable hydraulic" )
	language.Add( "Tool.wire_hydraulic.stretchonly", "Winch Mode (Stretch Only)" )
	language.Add( "Tool.wire_hydraulic.stretchonly.help", "If this isn't enabled then it acts like a spring, pushing away the objects as they move closer." )
	language.Add( "Tool.wire_hydraulic.width", "Width:" )
	language.Add( "Tool.wire_hydraulic.material", "Material:" )
	language.Add( "Tool.wire_hydraulic.fixed", "Fixed" )
	language.Add( "Tool.wire_hydraulic.speed", "In/Out Speed Mul" )
	TOOL.Information = {
		{ name = "left_0", stage = 0, text = "Place hydraulic" },
		{ name = "right_0", stage = 0, text = "Place hydraulic along the hit normal" },
		{ name = "left_1", stage = 1, text = "Choose the second point" },
		{ name = "left_2", stage = 2, text = "Place the controller" },
	}
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(16)

if SERVER then
	function TOOL:MakeEnt(ply, model, Ang, trace)
		return MakeWireHydraulicController(ply, trace.HitPos, Ang, model, nil, self.constraint, self.rope)
	end
end

function TOOL:GetConVars()
	return self:GetClientInfo( "material" ) or "cable/rope",
			self:GetClientNumber("width", 3),
			self:GetClientNumber("speed", 16),
			self:GetClientNumber("fixed", 0),
			self:GetClientNumber("stretchonly", 0) ~= 0
end

function TOOL:LeftClick_Update( trace )
	local const = trace.Entity.constraint
	if IsValid( const ) then
		-- Don't remove the controller when the constraint is removed
		const:DontDeleteOnRemove( trace.Entity )
		if IsValid(trace.Entity.rope) then trace.Entity.rope:DontDeleteOnRemove( trace.Entity ) end
		-- Get constraint info
		local tbl = const:GetTable()
		-- Remove constraint
		const:Remove()

		-- Get convars
		local material, width, speed, fixed, stretchonly = self:GetConVars()

		-- Make new constraint, at the old constraint's position, but with the new convar settings
		local const, rope = MakeWireHydraulic( self:GetOwner(),
								tbl.Ent1, tbl.Ent2,
								tbl.Bone1, tbl.Bone2,
								tbl.LPos1, tbl.LPos2,
								width, material, speed, fixed, stretchonly )

		-- Set the new references
		const.MyCrtl = trace.Entity:EntIndex()
		trace.Entity:SetConstraint( const, rope )
		trace.Entity:DeleteOnRemove( const )
		if rope then
			trace.Entity:DeleteOnRemove( rope )
		end
	end
end

function TOOL:LeftClick( trace )
	if not trace.Hit or ( trace.Entity:IsValid() and trace.Entity:IsPlayer() ) then return end
	if ( SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()

	-- Update existing constraint
	if self:CheckHitOwnClass( trace ) and iNum == 0 then
		if SERVER then
			self:LeftClick_Update( trace )
		end
		return true
	end

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 1 ) then

		if ( CLIENT ) then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local const, rope = self.constraint, self.rope

		if not IsValid(const) then
			WireLib.AddNotify(self:GetOwner(), "Wire Hydraulic Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		local controller = self:LeftClick_Make(trace, ply)
		if isbool(controller) then return controller end
		self:LeftClick_PostMake(controller, ply, trace)

		if controller then
			controller:DeleteOnRemove(const)
			if rope then controller:DeleteOnRemove( rope ) end
		end

		self:ClearObjects()
		self:SetStage(0)

	elseif ( iNum == 1 ) then

		if CLIENT then return true end

		-- Get client's CVars
		local material, width, speed, fixed, stretchonly = self:GetConVars()

		-- Get information we're about to use
		local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
		local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)

		local const, rope = MakeWireHydraulic(self:GetOwner(), Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, speed, fixed, stretchonly)
		if not IsValid(const) then
			WireLib.AddNotify(self:GetOwner(), "Wire Hydraulic Invalid!", NOTIFY_GENERIC, 7)
			self:ClearObjects()
			self:SetStage(0)
			return
		end

		self.constraint, self.rope = const,rope

		undo.Create(self.WireClass)
			undo.AddEntity(const)
			if rope then undo.AddEntity(rope) end
			undo.SetPlayer(self:GetOwner())
		undo.Finish()
		self:GetOwner():AddCleanup("ropeconstraints", const)
		if rope then self:GetOwner():AddCleanup("ropeconstraints", rope) end

		self:SetStage(2)
	else
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:RightClick( trace )
	if self:NumObjects() > 1 then
		if not IsValid(self.constraint) then
			self:ClearObjects()
			self:SetStage(0)
		else
			return false
		end
	end

	local tr = {}
	tr.start = trace.HitPos
	tr.endpos = tr.start + (trace.HitNormal * 16384)
	tr.filter = {self:GetOwner()}
	if IsValid(trace.Entity) then
		tr.filter[2] = trace.Entity
	end
	local trace2 = util.TraceLine( tr )

	if CLIENT or not WireLib.CanTool(self:GetOwner(), trace2.Entity, "wire_hydraulic") then return false end

	return self:LeftClick(trace) and self:LeftClick(trace2)
end

function TOOL:Reload( trace )
	if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	return constraint.RemoveConstraints( trace.Entity, "WireHydraulic" )
end

function TOOL:Think()
	-- Disable ghost when making the constraint
	if self:GetStage() == 2 then
		WireToolObj.Think(self)
	end
end

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSizer(panel, "wire_hydraulic_modelsize")
	WireDermaExts.ModelSelect(panel, "wire_hydraulic_model", list.Get( "Wire_Hydraulic_Models" ), 1, true)
	panel:CheckBox("#Tool.wire_hydraulic.stretchonly","wire_hydraulic_stretchonly")
	panel:ControlHelp("#Tool.wire_hydraulic.stretchonly.help")
	panel:CheckBox("#Tool.wire_hydraulic.fixed","wire_hydraulic_fixed")
	panel:NumSlider("#Tool.wire_hydraulic.speed","wire_hydraulic_speed",4,120,0)
	panel:NumSlider("#Tool.wire_hydraulic.width","wire_hydraulic_width",1,20,2)
	panel:AddControl( "RopeMaterial", { Label = "#Tool.wire_hydraulic.material", convar = "wire_hydraulic_material" } )
end
