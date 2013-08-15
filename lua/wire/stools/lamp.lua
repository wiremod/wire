WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "lamp", "Lamp", "gmod_wire_lamp", nil, "Lamps" )

if CLIENT then
	language.Add( "tool.wire_lamp.name", "Wire Lamps" )
	language.Add( "tool.wire_lamp.desc", "Spawns a lamp for use with the wire system." )
	language.Add( "tool.wire_lamp.0", "Primary: Create lamp" )
	language.Add( "WireLampTool_RopeLength", "Rope Length:")
	language.Add( "WireLampTool_FOV", "FOV:")
	language.Add( "WireLampTool_Dist", "Distance:")
	language.Add( "WireLampTool_Bright", "Brightness:")
	language.Add( "WireLampTool_Const", "Constraint:" )
	language.Add( "WireLampTool_Color", "Color:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10 )

if SERVER then
	function TOOL:GetConVars()
		return math.Clamp( self:GetClientNumber( "r" ), 0, 255 ),
		math.Clamp( self:GetClientNumber( "g" ), 0, 255 ),
		math.Clamp( self:GetClientNumber( "b" ), 0, 255 ),
		self:GetClientInfo( "texture" ),
		self:GetClientNumber( "fov" ),
		self:GetClientNumber( "distance" ),
		self:GetClientNumber( "brightness" )
	end

	function TOOL:LeftClick_PostMake( ent, ply, trace )
		if trace.Entity and trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end
		
		-- If there's no physics object then we can't constraint it!
		if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end
		if ent == true then return true end
		if ent == nil or ent == false or not IsValid( ent ) then return false end
		
		local const = self:GetClientInfo( "const" )
		
		if const == "weld" then
			local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
			undo.Create( self.WireClass )
				undo.AddEntity( ent )
				undo.AddEntity( const )
				undo.SetPlayer( ply )
			undo.Finish()
		elseif const == "rope" then
			local length = math.Clamp( self:GetClientNumber( "ropelength" ), 4, 1024 )
			local material = "cable/rope"
			
			local LPos1 = Vector( -15, 0, 0 )
			if ent:GetModel() == "models/maxofs2d/lamp_projector.mdl" then LPos1 = Vector( -10, 0, 0 )
			elseif ent:GetModel() == "models/lamps/torch.mdl" then LPos1 = Vector( -7.9, 0, 0 ) end
			local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )
			
			if IsValid( trace.Entity ) then
				local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
				if IsValid( phys ) then
					LPos2 = phys:WorldToLocal( trace.HitPos )
				end
			end
			
			local constraint, rope = constraint.Rope( ent, trace.Entity, 0, trace.PhysicsBone, LPos1, LPos2, 0, length, 0, 1, material, nil )
			ent:GetPhysicsObject():Wake()
			
			undo.Create( self.WireClass )
				undo.AddEntity( ent )
				undo.AddEntity( rope )
				undo.AddEntity( constraint )
				undo.SetPlayer( ply )
			undo.Finish()
		else
			ent:GetPhysicsObject():EnableMotion( false ) -- freeze
			undo.Create( self.WireClass )
				undo.AddEntity( ent )
				undo.SetPlayer( ply )
			undo.Finish()
		end

		ply:AddCleanup( self.WireClass, ent )
		return true
	end
end

TOOL.ClientConVar = {
	ropelength   = 64,
	ropematerial = "cable/rope",
	r            = 255,
	g            = 255,
	b            = 255,
	const        = "none",
	texture      = "effects/flashlight001",
	fov 		 = 90,
	distance 	 = 1024,
	brightness 	 = 8,
	model		 = "models/lamps/torch.mdl"
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_lamp")
	
	WireDermaExts.ModelSelect(panel, "wire_lamp_model", list.Get( "LampModels" ), 1)
	panel:NumSlider("#WireLampTool_RopeLength", "wire_lamp_ropelength", 4, 400, 0)
	panel:NumSlider("#WireLampTool_FOV", "wire_lamp_fov", 10, 170, 2)
	panel:NumSlider("#WireLampTool_Dist", "wire_lamp_distance", 64, 2048, 0)
	panel:NumSlider("#WireLampTool_Bright", "wire_lamp_brightness", 0, 8, 2)
	
	panel:AddControl("ComboBox", {
		Label = "#WireLampTool_Const",
		Options = {
			["Rope"] = { wire_lamp_const = "rope" },
			["Weld"] = { wire_lamp_const = "weld" },
			["None"] = { wire_lamp_const = "none" },
		}
	})
	
	panel:AddControl("Color", {
		Label = "#WireLampTool_Color",
		Red	= "wire_lamp_r",
		Green = "wire_lamp_g",
		Blue = "wire_lamp_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	local MatSelect = panel:MatSelect( "wire_lamp_texture", nil, true, 0.33, 0.33 )
	for k, v in pairs( list.Get( "LampTextures" ) ) do
		MatSelect:AddMaterial( v.Name or k, k )
	end
end
