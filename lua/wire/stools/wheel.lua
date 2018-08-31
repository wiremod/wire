WireToolSetup.setCategory( "Physics/Force" )
WireToolSetup.open( "wheel", "Wheel", "gmod_wire_wheel", nil, "Wheels" )

if CLIENT then
	language.Add( "tool.wire_wheel.name", "Wheel Tool (wire)" )
	language.Add( "tool.wire_wheel.desc", "Attaches a wheel to something." )
	TOOL.Information = { { name = "left", text = "Attach a wheel" } }

	language.Add( "tool.wire_wheel.group", "Input value to go forward:" )
	language.Add( "tool.wire_wheel.group_reverse", "Input value to go in reverse:" )
	language.Add( "tool.wire_wheel.group_stop", "Input value for no acceleration:" )
	language.Add( "tool.wire_wheel.group_desc", "All these values need to be different." )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 30 )

TOOL.ClientConVar = {
	torque 		= 3000,
	friction 	= 1,
	nocollide 	= 1,
	forcelimit 	= 0,
	fwd			= 1,	-- Forward
	bck			= -1,	-- Back
	stop 		= 0,	-- Stop
}

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "fwd" ), self:GetClientNumber( "bck" ), self:GetClientNumber( "stop" ), self:GetClientNumber( "torque" )
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		local targetPhys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )

		-- Get client's CVars
		local friction 		= self:GetClientNumber( "friction" )
		local nocollide		= self:GetClientNumber( "nocollide" )
		local limit			= self:GetClientNumber( "forcelimit" )

		local fwd,bck,stop,torque = self:GetConVars() -- These are the ones used in Setup
		if fwd == stop or bck == stop or fwd == bck then return false end

		-- Create the wheel
		local wheelEnt = WireLib.MakeWireEnt(ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model}, fwd, bck, stop, torque )
		self:SetPos( wheelEnt, trace )

		-- Wake up the physics object so that the entity updates
		wheelEnt:GetPhysicsObject():Wake()

		-- Set the hinge Axis perpendicular to the trace hit surface
		local LPos1 = wheelEnt:GetPhysicsObject():WorldToLocal( wheelEnt:GetPos() + trace.HitNormal )
		local LPos2 = targetPhys:WorldToLocal( trace.HitPos )

		local constraint, axis = constraint.Motor( wheelEnt, trace.Entity, 0, trace.PhysicsBone, LPos1,	LPos2, friction, 1000, 0, nocollide, false, ply, limit )

		undo.Create(self.WireClass)
			undo.AddEntity( axis )
			undo.AddEntity( constraint )
			undo.AddEntity( wheelEnt )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( self.WireClass, axis )
		ply:AddCleanup( self.WireClass, constraint )
		ply:AddCleanup( self.WireClass, wheelEnt )

		--BUGFIX:WIREMOD-11:Deleting prop did not deleting wheels
		wheelEnt:SetWheelBase(trace.Entity)

		wheelEnt:SetMotor( constraint )
		wheelEnt:SetDirection( constraint.direction )
		wheelEnt:SetAxis( trace.HitNormal )
		wheelEnt:DoDirectionEffect()

		return wheelEnt
	end

	function TOOL:LeftClick_PostMake(_, _, _) end -- We're handling this in MakeEnt since theres a motor
end

function TOOL:GetAngle(trace)
	return trace.HitNormal:Angle() + Angle(self:GetOwner():GetInfoNum( "wheel_rx", 0 ), self:GetOwner():GetInfoNum( "wheel_ry", 0 ), self:GetOwner():GetInfoNum( "wheel_rz", 0 ))
end
function TOOL:SetPos( ent, trace )
	local wheelOffset = ent:GetPos() - ent:NearestPoint( ent:GetPos() - (trace.HitNormal * 512) )
	ent:SetPos( trace.HitPos + wheelOffset + trace.HitNormal )
end

function TOOL:GetModel()
	local ply = self:GetOwner()
	if self:CheckValidModel(ply:GetInfo("wheel_model")) then --use a valid model or the server crashes :<
		return ply:GetInfo("wheel_model")
	else
		return "models/props_c17/oildrum001.mdl" --use some other random, valid prop instead
	end
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_wheel")
	panel:NumSlider("#tool.wire_wheel.group", "wire_wheel_fwd", -10, 10, 0)
	panel:NumSlider("#tool.wire_wheel.group_stop", "wire_wheel_stop", -10, 10, 0)
	panel:NumSlider("#tool.wire_wheel.group_reverse", "wire_wheel_bck", -10, 10, 0)
	--WireDermaExts.ModelSelect(panel, "wheel_model", list.Get( "WheelModels" ), 3, true) -- This doesn't seem to set the wheel_rx convars right
	panel:AddControl( "PropSelect", { Label = "#tool.wheel.model",
									 ConVar = "wheel_model",
									 Category = "Wheels",
									 height = 5,
									 Models = list.Get( "WheelModels" ) } )
	panel:NumSlider("#tool.wheel.torque", "wire_wheel_torque", 10, 10000, 0)
	panel:NumSlider("#tool.wheel.forcelimit", "wire_wheel_forcelimit", 0, 50000, 0)
	local frictionPanel = panel:NumSlider("#tool.wheel.friction", "wire_wheel_friction", 0, 50, 2)
	frictionPanel:SetTooltip("How quickly the wheel comes to a stop. Note: An existing wheel's friction cannot be updated")
	panel:CheckBox("#tool.wheel.nocollide", "wire_wheel_nocollide")
end
