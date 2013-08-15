WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "light", "Light", "gmod_wire_light", nil, "Lights" )

if CLIENT then
	language.Add( "tool.wire_light.name", "Light Tool (Wire)" )
	language.Add( "tool.wire_light.desc", "Spawns a Light for use with the wire system." )
	language.Add( "tool.wire_light.0", "Primary: Create Light" )
	language.Add( "WireLightTool_RopeLength", "Rope Length:")
	language.Add( "WireLightTool_bright", "Glow brightness:")
	language.Add( "WireLightTool_size", "Glow size:" )
	language.Add( "WireLightTool_directional", "Directional Component" )
	language.Add( "WireLightTool_radiant", "Radiant Component" )
	language.Add( "WireLightTool_glow", "Glow Component" )
	language.Add( "WireLightTool_const", "Constraint:" )
	language.Add( "WireLightTool_color", "Initial Color:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(8)

if SERVER then
	function TOOL:GetConVars()
		return
			self:GetClientNumber("directional") ~= 0,
			self:GetClientNumber("radiant") ~= 0,
			self:GetClientNumber("glow") ~= 0,
			self:GetClientNumber("brightness"),
			self:GetClientNumber("size"),
			self:GetClientNumber("r"),
			self:GetClientNumber("g"),
			self:GetClientNumber("b")
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
			
			local LPos1 = Vector( 0, 0, 0 )
			if ent:GetModel() == "models/maxofs2d/light_tubular.mdl" then LPos1 = Vector( 0, 0, 5 ) end
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
	model        = "models/jaanus/wiretool/wiretool_siren.mdl",
	directional  = 0,
	radiant      = 0,
	glow         = 0,
	ropelength   = 64,
	brightness	 = 2,
	size		 = 256,
	const		 = "weld",
	r			 = 0,
	g 			 = 0,
	b			 = 0
}

function TOOL.BuildCPanel(panel)
	local Models = list.Get( "Wire_Misc_Tools_Models" ) -- default wire models
	Models["models/MaxOfS2D/light_tubular.mdl"] = true -- GMod light

	WireDermaExts.ModelSelect(panel, "wire_light_model", Models, 1)
	panel:CheckBox("#WireLightTool_directional", "wire_light_directional")
	panel:CheckBox("#WireLightTool_radiant", "wire_light_radiant")
	panel:CheckBox("#WireLightTool_glow", "wire_light_glow")
	panel:NumSlider("#WireLightTool_bright", "wire_light_brightness", 0, 10, 0)
	panel:NumSlider("#WireLightTool_size", "wire_light_size", 0, 1024, 0)
	panel:AddControl("ComboBox", {
		Label = "#WireLightTool_Const",
		Options = {
			["Weld"] = { wire_light_const = "weld" },
			["None"] = { wire_light_const = "none" },
			["Rope"] = { wire_light_const = "rope" }
		}
	})
	panel:NumSlider("#WireLightTool_RopeLength", "wire_light_ropelength", 4, 1024, 0)
	panel:AddControl("Color", {
		Label = "#WireLightTool_color",
		Red	= "wire_light_r",
		Green = "wire_light_g",
		Blue = "wire_light_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
end
