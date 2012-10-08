AddCSLuaFile( "display.lua" )
WireToolSetup.setCategory( "Display" )

local function CreateFlatGetAngle( self, trace )
	local Ang = trace.HitNormal:Angle()
	if self:GetClientNumber("createflat") == 0 then
		Ang.pitch = Ang.pitch + 90
	end
	return Ang
end


do -- wire_indicator
	WireToolSetup.open( "indicator", "Indicator", "gmod_wire_indicator", nil, "Indicators" )

	if CLIENT then
		language.Add( "tool.wire_indicator.name", "Indicator Tool (Wire)" )
		language.Add( "tool.wire_indicator.desc", "Spawns a indicator for use with the wire system." )
		language.Add( "tool.wire_indicator.0", "Primary: Create/Update Indicator" )
		language.Add( "ToolWireIndicator_Model", "Model:" )
		language.Add( "ToolWireIndicator_a_value", "A Value:" )
		language.Add( "ToolWireIndicator_a_colour", "A Colour:" )
		language.Add( "ToolWireIndicator_b_value", "B Value:" )
		language.Add( "ToolWireIndicator_b_colour", "B Colour:" )
		language.Add( "ToolWireIndicator_Material", "Material:" )
		language.Add( "ToolWireIndicator_90", "Rotate segment 90" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_indicators", "You've hit indicators limit!" )

	if SERVER then
		ModelPlug_Register("indicator")

		function TOOL:GetConVars()
			return self:GetClientNumber("a"),
			math.Clamp(self:GetClientNumber("ar"),0,255),
			math.Clamp(self:GetClientNumber("ag"),0,255),
			math.Clamp(self:GetClientNumber("ab"),0,255),
			math.Clamp(self:GetClientNumber("aa"),0,255),
			self:GetClientNumber("b"),
			math.Clamp(self:GetClientNumber("br"),0,255),
			math.Clamp(self:GetClientNumber("bg"),0,255),
			math.Clamp(self:GetClientNumber("bb"),0,255),
			math.Clamp(self:GetClientNumber("ba"),0,255),
			self:GetClientInfo( "material" ),
			self:GetClientNumber( "noclip" ) == 1
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireIndicator( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.ClientConVar = {
		model    = "models/jaanus/wiretool/wiretool_siren.mdl",
		a        = 0,
		ar       = 255,
		ag       = 0,
		ab       = 0,
		aa       = 255,
		b        = 1,
		br       = 0,
		bg       = 255,
		bb       = 0,
		ba       = 255,
		material = "models/debug/debugwhite",
		noclip   = 0,
		rotate90 = 0,
		weld     = 1,
	}

	--function TOOL:GetGhostAngle( Ang )
	function TOOL:GetAngle( trace )
		local Ang = trace.HitNormal:Angle()
		local Model = self:GetModel()
		--these models get mounted differently
		if Model == "models/props_borealis/bluebarrel001.mdl" || Model == "models/props_junk/PopCan01a.mdl" then
			return Ang + Angle(-90, 0, 0)
		elseif Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
			return Ang + Angle(0, 0, (self:GetClientNumber("rotate90") * 90))
		end
		Ang.pitch = Ang.pitch + 90
		return Ang
	end

	function TOOL:GetGhostMin( min )
		local Model = self:GetModel()
		--these models are different
		if Model == "models/props_trainstation/trainstation_clock001.mdl" or Model == "models/segment.mdl" or Model == "models/segment2.mdl" then
			return min.x
		end
		return min.z
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_indicator")
		panel:NumSlider("#ToolWireIndicator_a_value", "wire_indicator_a", -10, 10, 1)

		panel:AddControl("Color", {
			Label = "#ToolWireIndicator_a_colour",
			Red = "wire_indicator_ar",
			Green = "wire_indicator_ag",
			Blue = "wire_indicator_ab",
			Alpha = "wire_indicator_aa",
			ShowAlpha = "1",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		panel:NumSlider("#ToolWireIndicator_b_value", "wire_indicator_b", -10, 10, 1)

		panel:AddControl("Color", {
			Label = "#ToolWireIndicator_b_colour",
			Red = "wire_indicator_br",
			Green = "wire_indicator_bg",
			Blue = "wire_indicator_bb",
			Alpha = "wire_indicator_ba",
			ShowAlpha = "1",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		ModelPlug_AddToCPanel(panel, "indicator", "wire_indicator", "#ToolWireIndicator_Model", nil, "#ToolWireIndicator_Model")

		panel:AddControl("ComboBox", {
			Label = "#ToolWireIndicator_Material",
			Options = {
				["Matte"]	= { wire_indicator_material = "models/debug/debugwhite" },
				["Shiny"]	= { wire_indicator_material = "models/shiny" },
				["Metal"]	= { wire_indicator_material = "models/props_c17/metalladder003" }
			}
		})

		panel:CheckBox("#ToolWireIndicator_90", "wire_indicator_rotate90")
		panel:CheckBox("#WireGatesTool_noclip", "wire_indicator_noclip")
		panel:CheckBox("Weld", "wire_indicator_weld")
	end
end -- wire_indicator



do -- wire_7seg
	WireToolSetup.open( "7seg", "7 Segment Display", "gmod_wire_indicator" )

	TOOL.GhostAngle = Angle(90, 0, 0)
	TOOL.GhostMin = "x"

	if CLIENT then
		language.Add( "tool.wire_7seg.name", "7-Segment Display Tool" )
		language.Add( "tool.wire_7seg.desc", "Spawns 7 indicators for numeric display with the wire system." )
		language.Add( "tool.wire_7seg.0", "Primary: Create display/Update Indicator" )
		language.Add( "ToolWire7Seg_a_colour", "Off Colour:" )
		language.Add( "ToolWire7Seg_b_colour", "On Colour:" )
		language.Add( "ToolWire7SegTool_worldweld", "Allow weld to world" )
		language.Add( "undone_wire7seg", "Undone 7-Segment Display" )
	end

	-- define MaxLimitName cause this tool just uses gmod_wire_indicators
	TOOL.MaxLimitName = "wire_indicators"

	if SERVER then
		function TOOL:GetConVars()
			return 0,
			math.Clamp(self:GetClientNumber("ar"),0,255),
			math.Clamp(self:GetClientNumber("ag"),0,255),
			math.Clamp(self:GetClientNumber("ab"),0,255),
			math.Clamp(self:GetClientNumber("aa"),0,255),
			1,
			math.Clamp(self:GetClientNumber("br"),0,255),
			math.Clamp(self:GetClientNumber("bg"),0,255),
			math.Clamp(self:GetClientNumber("bb"),0,255),
			math.Clamp(self:GetClientNumber("ba"),0,255)
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWire7Seg( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.ClientConVar = {
		model     = "models/segment.mdl",
		ar        = 70, --default: dark grey off, full red on
		ag        = 70,
		ab        = 70,
		aa        = 255,
		br        = 255,
		bg        = 0,
		bb        = 0,
		ba        = 255,
		worldweld = 1,
	}

	function TOOL:PostMake_SetPos() end

	function TOOL:LeftClick_PostMake( wire_indicators, ply, trace )
		if not wire_indicators then return end
		local worldweld = self:GetClientNumber("worldweld") == 1
		undo.Create("Wire7Seg")
			for x=1, 7 do
				--make welds
				local const = WireLib.Weld(wire_indicators[x], trace.Entity, trace.PhysicsBone, true, false, worldweld)
				undo.AddEntity( wire_indicators[x] )
				undo.AddEntity( const )
				ply:AddCleanup( "wire_indicators", wire_indicators[x] )
				ply:AddCleanup( "wire_indicators", const)
			end
			undo.SetPlayer( ply )
		undo.Finish()
		return true
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_7seg")

		panel:AddControl("Color", {
			Label = "#ToolWire7Seg_a_colour",
			Red = "wire_7seg_ar",
			Green = "wire_7seg_ag",
			Blue = "wire_7seg_ab",
			Alpha = "wire_7seg_aa",
			ShowAlpha = "1",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		panel:AddControl("Color", {
			Label = "#ToolWire7Seg_b_colour",
			Red = "wire_7seg_br",
			Green = "wire_7seg_bg",
			Blue = "wire_7seg_bb",
			Alpha = "wire_7seg_ba",
			ShowAlpha = "1",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		panel:AddControl("ComboBox", {
			Label = "#ToolWireIndicator_Model",
			Options = {
				["Huge 7-seg bar"]	= { wire_7seg_model = "models/segment2.mdl" },
				["Normal 7-seg bar"]		= { wire_7seg_model = "models/segment.mdl" },
				["Small 7-seg bar"]		= { wire_7seg_model = "models/segment3.mdl" },
			}
		})

		panel:CheckBox("#ToolWire7SegTool_worldweld", "wire_7seg_worldweld")
	end
end -- wire_7seg



do -- wire_consolescreen
	WireToolSetup.open( "consolescreen", "Console Screen", "gmod_wire_consolescreen", nil,  "Screens" )

	if CLIENT then
		language.Add( "tool.wire_consolescreen.name", "Console Screen Tool (Wire)" )
		language.Add( "tool.wire_consolescreen.desc", "Spawns a console screen" )
		language.Add( "tool.wire_consolescreen.0", "Primary: Create/Update screen" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_consolescreens", "You've hit console screens limit!" )

	if SERVER then
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireconsoleScreen( ply, trace.HitPos, Ang, model )
		end
	end

	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.NoLeftOnClass = true -- no update ent function needed
	TOOL.ClientConVar = {
		model      = "models/props_lab/monitor01b.mdl",
		createflat = 0,
		weld       = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_consolescreen_model", list.Get( "WireScreenModels" ), 2)
		panel:CheckBox("#Create Flat to Surface", "wire_consolescreen_createflat")
		panel:CheckBox("Weld", "wire_consolescreen_weld")
	end
end -- wire_consolescreen



do -- wire_digitalscreen
	WireToolSetup.open( "digitalscreen", "Digital Screen", "gmod_wire_digitalscreen", nil, "Digital Screens" )

	if CLIENT then
		language.Add( "tool.wire_digitalscreen.name", "Digital Screen Tool (Wire)" )
		language.Add( "tool.wire_digitalscreen.desc", "Spawns a digital screen, which can be used to draw pixel by pixel." )
		language.Add( "tool.wire_digitalscreen.0", "Primary: Create/Update screen" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_digitalscreens", "You've hit digital screens limit!" )

	if SERVER then
		function TOOL:GetConVars()
			return self:GetClientInfo("width"), self:GetClientInfo("height")
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireDigitalScreen( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.NoLeftOnClass = true -- no update ent function needed
	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.ClientConVar = {
		model      = "models/props_lab/monitor01b.mdl",
		width      = 32,
		height     = 32,
		createflat = 0,
		weld       = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_digitalscreen_model", list.Get( "WireScreenModels" ), 2)
		panel:NumSlider("Width", "wire_digitalscreen_width", 1, 512, 0)
		panel:NumSlider("Height", "wire_digitalscreen_height", 1, 512, 0)
		panel:CheckBox("#Create Flat to Surface", "wire_digitalscreen_createflat")
		panel:CheckBox("Weld", "wire_digitalscreen_weld")
	end
end -- wire_digitalscreen



do -- wire_lamp
	WireToolSetup.open( "lamp", "Lamp", "gmod_wire_lamp", nil, "Lamps" )

	if CLIENT then
		language.Add( "tool.wire_lamp.name", "Wire Lamps" )
		language.Add( "tool.wire_lamp.desc", "Spawns a lamp for use with the wire system." )
		language.Add( "tool.wire_lamp.0", "Primary: Create hanging lamp Secondary: Create unattached lamp" )
		language.Add( "WireLampTool_RopeLength", "Rope Length:")
		language.Add( "WireLampTool_Color", "Color:" )
		language.Add( "WireLampTool_Const", "Constraint:" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 10, "wire_lamps", "You've hit lamps limit!" )

	if SERVER then
		function TOOL:GetConVars()
			return math.Clamp( self:GetClientNumber( "r" ), 0, 255 ),
			math.Clamp( self:GetClientNumber( "g" ), 0, 255 ),
			math.Clamp( self:GetClientNumber( "b" ), 0, 255 ),
			self:GetClientInfo( "texture" )
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			local r, g, b, Texture = self:GetConVars()
			return MakeWireLamp( ply, r, g, b, Texture, { Pos = trace.HitPos, Angle = Ang } )
		end

		function TOOL:LeftClick_PostMake( ent, ply, trace )
			if ent == true then return true end
			if ent == nil or ent == false or not ent:IsValid() then return false end

			local const = self:GetClientInfo( "const" )

			if const == "weld" then
				local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
				undo.Create( self.WireClass )
					undo.AddEntity( ent )
					undo.AddEntity( const )
					undo.SetPlayer( ply )
				undo.Finish()
			elseif const == "rope" then

				local length   = self:GetClientNumber( "ropelength" )
				local material = self:GetClientInfo( "ropematerial" )

				local LPos1 = Vector( 0, 0, 5 )
				local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )

				if trace.Entity:IsValid() then
					local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
					if phys:IsValid() then
						LPos2 = phys:WorldToLocal( trace.HitPos )
					end
				end

				local constraint, rope = constraint.Rope( ent, trace.Entity, 0, trace.PhysicsBone, LPos1, LPos2, 0, length, 0, 1.5, material, nil )

				undo.Create( self.WireClass )
					undo.AddEntity( ent )
					undo.AddEntity( rope )
					undo.AddEntity( constraint )
					undo.SetPlayer( ply )
				undo.Finish()

			else --none
				ent:GetPhysicsObject():EnableMotion(false) -- freeze

				undo.Create( self.WireClass )
					undo.AddEntity( ent )
					undo.SetPlayer( ply )
				undo.Finish()
			end

			ply:AddCleanup( self.WireClass, ent )

			return true
		end
	end

	function TOOL:GetAngle( trace )
		return trace.HitNormal:Angle() - Angle( 90, 0, 0 )
	end

	function TOOL:SetPos( ent, trace )
		ent:SetPos(trace.HitPos + trace.HitNormal * 10)
	end

	--TOOL.GhostAngle = Angle(180, 0, 0)
	TOOL.Model = "models/props_wasteland/prison_lamp001c.mdl"
	TOOL.ClientConVar = {
		ropelength   = 64,
		ropematerial = "cable/rope",
		r            = 255,
		g            = 255,
		b            = 255,
		const        = "rope",
		texture      = "effects/flashlight001",
	}

	-- Spawn a lamp without constraints (just frozen)
	function TOOL:RightClick( trace )
		-- TODO: redo this function
		if not trace.HitPos then return false end
		if trace.Entity:IsPlayer() then return false end
		if CLIENT then return true end

		local ply = self:GetOwner()
		local noconstraint = true

		local ent = self:LeftClick_Make( trace, ply, noconstraint )
		if ent == true then return true end
		if ent == nil or ent == false or not ent:IsValid() then return false end

		undo.Create( self.WireClass )
			undo.AddEntity( ent )
			undo.AddEntity( const )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( self.WireClass, ent )

		return true
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_lamp")

		panel:NumSlider("#WireLampTool_RopeLength", "wire_lamp_ropelength", 4, 400, 0)

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

		panel:AddControl("ComboBox", {
			Label = "#WireLampTool_Const",
			Options = {
				["Rope"] = { wire_lamp_const = "rope" },
				["Weld"] = { wire_lamp_const = "weld" },
				["None"] = { wire_lamp_const = "none" },
			}
		})

		local MatSelect = panel:MatSelect( "wire_lamp_texture", nil, true, 0.33, 0.33 )
		for k, v in pairs( list.Get( "LampTextures" ) ) do
			MatSelect:AddMaterial( v.Name or k, k )
		end
	end
end -- wire_lamp



do -- wire_light
	WireToolSetup.open( "light", "Light", "gmod_wire_light", nil, "Lights" )

	if CLIENT then
		language.Add( "tool.wire_light.name", "Light Tool (Wire)" )
		language.Add( "tool.wire_light.desc", "Spawns a Light for use with the wire system." )
		language.Add( "tool.wire_light.0", "Primary: Create Light" )
		language.Add( "WireLightTool_directional", "Directional Component" )
		language.Add( "WireLightTool_radiant", "Radiant Component" )
		language.Add( "WireLightTool_glow", "Glow Component" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 8, "wire_lights", "You've hit lights limit!" )

	if SERVER then
		function TOOL:GetConVars()
			return
				self:GetClientNumber("directional") ~= 0,
				self:GetClientNumber("radiant") ~= 0,
				self:GetClientNumber("glow") ~= 0
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireLight( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.ClientConVar = {
		model       = "models/jaanus/wiretool/wiretool_siren.mdl",
		directional = 0,
		radiant     = 0,
		glow        = 0,
		weld        = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_light_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
		panel:CheckBox("#WireLightTool_directional", "wire_light_directional")
		panel:CheckBox("#WireLightTool_radiant", "wire_light_radiant")
		panel:CheckBox("#WireLightTool_glow", "wire_light_glow")
		panel:CheckBox("Weld", "wire_light_weld")
	end
end -- wire_light



do -- wire_oscilloscope
	WireToolSetup.open( "oscilloscope", "Oscilloscope", "gmod_wire_oscilloscope", nil, "Oscilloscopes" )

	if CLIENT then
		language.Add( "tool.wire_oscilloscope.name", "Oscilloscope Tool (Wire)" )
		language.Add( "tool.wire_oscilloscope.desc", "Spawns a oscilloscope what display line graphs." )
		language.Add( "tool.wire_oscilloscope.0", "Primary: Create/Update oscilloscope" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_oscilloscopes", "You've hit oscilloscopes limit!" )

	if SERVER then
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireOscilloscope( ply, trace.HitPos, Ang, model )
		end
	end

	TOOL.NoLeftOnClass = true -- no update ent function needed
	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.ClientConVar = {
		model      = "models/props_lab/monitor01b.mdl",
		createflat = 0,
		weld       = 1,
	}


	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_oscilloscope_model", list.Get( "WireScreenModels" ), 2)
		panel:CheckBox("#Create Flat to Surface", "wire_oscilloscope_createflat")
		panel:CheckBox("Weld", "wire_oscilloscope_weld")
	end
end -- wire_oscilloscope



do -- wire_panel
	WireToolSetup.open( "panel", "Control Panel", "gmod_wire_panel", nil, "Control Panels" )

	if CLIENT then
		language.Add( "tool.wire_panel.name", "Control Panel Tool (Wire)" )
		language.Add( "tool.wire_panel.desc", "Spawns a panel what display values." )
		language.Add( "tool.wire_panel.0", "Primary: Create/Update panel" )
		language.Add( "Tool_wire_panel_createflat", "Create flat to surface" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_panels", "You've hit panels limit!" )

	if SERVER then
		function TOOL:GetConVars() end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWirePanel( ply, trace.HitPos, Ang, model )
		end
	end

	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.NoLeftOnClass = true -- no update ent function needed
	TOOL.ClientConVar = {
		model      = "models/props_lab/monitor01b.mdl",
		createflat = 1,
		weld       = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_panel_model", list.Get( "WireScreenModels" ), 2) -- screen witha GPULib setup
		panel:CheckBox("#Tool_wire_panel_createflat", "wire_panel_createflat")
		panel:CheckBox("Weld", "wire_panel_weld")
	end
end -- wire_panel



do -- wire_pixel
	WireToolSetup.open( "pixel", "Pixel", "gmod_wire_pixel", nil, "Pixels" )

	if CLIENT then
		language.Add( "tool.wire_pixel.name", "Pixel Tool (Wire)" )
		language.Add( "tool.wire_pixel.desc", "Spawns a Pixel for use with the wire system." )
		language.Add( "tool.wire_pixel.0", "Primary: Create Pixel" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_pixels", "You've hit pixels limit!" )

	if SERVER then
		ModelPlug_Register("pixel")

		function TOOL:GetConVars()
			return self:GetClientNumber( "noclip" ) == 1
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWirePixel( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.NoLeftOnClass = true -- no update ent function needed
	TOOL.ClientConVar = {
		model  = "models/jaanus/wiretool/wiretool_siren.mdl",
		noclip = 0,
		weld   = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireDermaExts.ModelSelect(panel, "wire_pixel_model", list.Get("Wire_pixel_Models"), 3, true)
		panel:CheckBox("#WireGatesTool_noclip", "wire_pixel_noclip")
		panel:CheckBox("Weld", "wire_pixel_weld")
	end
end -- wire_pixel



do -- wire_screen
	WireToolSetup.open( "screen", "Screen", "gmod_wire_screen", nil, "Screens" )

	if CLIENT then
		language.Add( "tool.wire_screen.name", "Screen Tool (Wire)" )
		language.Add( "tool.wire_screen.desc", "Spawns a screen that display values." )
		language.Add( "tool.wire_screen.0", "Primary: Create/Update screen" )
		language.Add("Tool_wire_screen_singlevalue", "Only one value")
		language.Add("Tool_wire_screen_singlebigfont", "Use bigger font for single-value screen")
		language.Add("Tool_wire_screen_texta", "Text A:")
		language.Add("Tool_wire_screen_textb", "Text B:")
		language.Add("Tool_wire_screen_leftalign", "Left alignment")
		language.Add("Tool_wire_screen_floor", "Floor screen value")
		language.Add("Tool_wire_screen_createflat", "Create flat to surface")
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_screens", "You've hit screens limit!" )

	if SERVER then
		ModelPlug_Register("pixel")

		function TOOL:GetConVars()
			return self:GetClientNumber("singlevalue") == 1,
			self:GetClientNumber("singlebigfont") == 1,
			self:GetClientInfo("texta"),
			self:GetClientInfo("textb"),
			self:GetClientNumber("leftalign") == 1,
			self:GetClientNumber("floor") == 1
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireScreen( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.ClientConVar = {
		model         = "models/props_lab/monitor01b.mdl",
		singlevalue   = 0,
		singlebigfont = 1,
		texta         = "Value A",
		textb         = "Value B",
		createflat    = 1,
		leftalign     = 0,
		floor         = 0,
		weld          = 1,
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_screen")
		WireDermaExts.ModelSelect(panel, "wire_screen_model", list.Get( "WireScreenModels" ), 2) -- screen with GPULib setup
		panel:CheckBox("#Tool_wire_screen_singlevalue", "wire_screen_singlevalue")
		panel:CheckBox("#Tool_wire_screen_singlebigfont", "wire_screen_singlebigfont")
		panel:CheckBox("#Tool_wire_screen_leftalign", "wire_screen_leftalign")
		panel:CheckBox("#Tool_wire_screen_floor", "wire_screen_floor")
		panel:TextEntry("#Tool_wire_screen_texta", "wire_screen_texta")
		panel:TextEntry("#Tool_wire_screen_textb", "wire_screen_textb")
		panel:CheckBox("#Tool_wire_screen_createflat", "wire_screen_createflat")
		panel:CheckBox("Weld", "wire_screen_weld")
	end
end -- wire_screen



do -- wire_soundemitter
	WireToolSetup.open( "soundemitter", "Sound Emitter", "gmod_wire_soundemitter", nil, "Sound Emitters" )

	if CLIENT then
		language.Add( "tool.wire_soundemitter.name", "Sound Emitter Tool (Wire)" )
		language.Add( "tool.wire_soundemitter.desc", "Spawns a sound emitter for use with the wire system." )
		language.Add( "tool.wire_soundemitter.0", "Primary: Create/Update Sound Emitter" )
		language.Add( "WireEmitterTool_sound", "Sound:" )
		language.Add( "WireEmitterTool_collision", "Collision" )
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 10, "wire_emitters", "You've hit sound emitters limit!" )

	if SERVER then
		ModelPlug_Register("speaker")

		function TOOL:GetConVars()
			return Sound( self:GetClientInfo( "sound" ) )
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireEmitter( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.ClientConVar = {
		model     = "models/cheeze/wires/speaker.mdl",
		sound     = "synth/square.wav",
		collision = 0,
		weld      = 1,
	}
	function TOOL.BuildCPanel(panel)
		local wide = panel:GetWide()

		local SoundNameText = vgui.Create("DTextEntry", ValuePanel)
		SoundNameText:SetText("")
		SoundNameText:SetWide(wide)
		SoundNameText:SetTall(20)
		SoundNameText:SetMultiline(false)
		SoundNameText:SetConVar("wire_soundemitter_sound")
		SoundNameText:SetVisible(true)
		panel:AddItem(SoundNameText)

		local SoundBrowserButton = vgui.Create("DButton")
		SoundBrowserButton:SetText("Open Sound Browser")
		SoundBrowserButton:SetWide(wide)
		SoundBrowserButton:SetTall(20)
		SoundBrowserButton:SetVisible(true)
		SoundBrowserButton.DoClick = function()
			RunConsoleCommand("wire_sound_browser_open",SoundNameText:GetValue())
		end
		panel:AddItem(SoundBrowserButton)

		local SoundPre = vgui.Create("DPanel")
		SoundPre:SetWide(wide)
		SoundPre:SetTall(20)
		SoundPre:SetVisible(true)

		local SoundPreWide = SoundPre:GetWide()

		local SoundPrePlay = vgui.Create("DButton", SoundPre)
		SoundPrePlay:SetText("Play")
		SoundPrePlay:SetWide(SoundPreWide / 2)
		SoundPrePlay:SetPos(0, 0)
		SoundPrePlay:SetTall(20)
		SoundPrePlay:SetVisible(true)
		SoundPrePlay.DoClick = function()
			RunConsoleCommand("play",SoundNameText:GetValue())
		end

		local SoundPreStop = vgui.Create("DButton", SoundPre)
		SoundPreStop:SetText("Stop")
		SoundPreStop:SetWide(SoundPreWide / 2)
		SoundPreStop:SetPos(SoundPreWide / 2, 0)
		SoundPreStop:SetTall(20)
		SoundPreStop:SetVisible(true)
		SoundPreStop.DoClick = function()
			RunConsoleCommand("play", "common/NULL.WAV") //Playing a silent sound will mute the preview but not the sound emitters.
		end
		panel:AddItem(SoundPre)
		SoundPre:InvalidateLayout(true)
		SoundPre.PerformLayout = function()
			local SoundPreWide = SoundPre:GetWide()
			SoundPrePlay:SetWide(SoundPreWide / 2)
			SoundPreStop:SetWide(SoundPreWide / 2)
			SoundPreStop:SetPos(SoundPreWide / 2, 0)
		end

		panel:CheckBox("#WireEmitterTool_collision", "wire_soundemitter_collision")
		ModelPlug_AddToCPanel(panel, "speaker", "wire_soundemitter", nil, nil, true)
		panel:CheckBox("Weld", "wire_soundemitter_weld")
	end
end -- wire_soundemitter



do -- wire_textscreen
	--Wire text screen by greenarrow
	--http://gmodreviews.googlepages.com/
	--http://forums.facepunchstudios.com/greenarrow
	WireToolSetup.open( "textscreen", "Text Screen", "gmod_wire_textscreen", nil, "Text Screens" )

	if CLIENT then
		language.Add("tool.wire_textscreen.name", "Text Screen Tool (Wire)" )
		language.Add("tool.wire_textscreen.desc", "Spawns a screen that displays text." )
		language.Add("tool.wire_textscreen.0", "Primary: Create/Update text screen, Secondary: Copy settings" )

		language.Add("Tool_wire_textscreen_tsize", "Text size:")
		language.Add("Tool_wire_textscreen_tjust", "Horizontal alignment:")
		language.Add("Tool_wire_textscreen_valign", "Vertical alignment:")
		language.Add("Tool_wire_textscreen_colour", "Text colour:")
		language.Add("Tool_wire_textscreen_createflat", "Create flat to surface")
		language.Add("Tool_wire_textscreen_text", "Default text:")
	end
	WireToolSetup.BaseLang()

	WireToolSetup.SetupMax( 20, "wire_textscreens", "You've hit sound text screens limit!" )

	if SERVER then
		ModelPlug_Register("speaker")

		function TOOL:GetConVars()
			return
				self:GetClientInfo("text"),
				(16 - tonumber(self:GetClientInfo("tsize"))),
				self:GetClientNumber("tjust"),
				self:GetClientNumber("valign"),
				Color(
					math.min(self:GetClientNumber("tred"), 255),
					math.min(self:GetClientNumber("tgreen"), 255),
					math.min(self:GetClientNumber("tblue"), 255)
				),
				Color(0,0,0)
		end

		function TOOL:MakeEnt( ply, model, Ang, trace )
			return MakeWireTextScreen( ply, trace.HitPos, Ang, model, self:GetConVars() )
		end
	end

	TOOL.GetAngle = CreateFlatGetAngle
	TOOL.ClientConVar = {
		model       = "models/kobilica/wiremonitorbig.mdl",
		tsize       = 10,
		tjust       = 1,
		valign      = 0,
		tred        = 255,
		tblue       = 255,
		tgreen      = 255,
		ninputs     = 3,
		createflat  = 1,
		weld        = 1,
		text        = "",
	}

	function TOOL:RightClick( trace )
		if not trace.HitPos then return false end
		local ent = trace.Entity
		if ent:IsPlayer() then return false end
		if CLIENT then return true end

		local ply = self:GetOwner()

		if ent:IsValid() && ent:GetClass() == "gmod_wire_textscreen" then
			ply:ConCommand('wire_textscreen_text "'..ent.text..'"')
			return true
		end

	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_textscreen")
		panel:NumSlider("#Tool_wire_textscreen_tsize", "wire_textscreen_tsize", 1, 15, 0)
		panel:NumSlider("#Tool_wire_textscreen_tjust", "wire_textscreen_tjust", 0, 2, 0)
		panel:NumSlider("#Tool_wire_textscreen_valign", "wire_textscreen_valign", 0, 2, 0)
		panel:AddControl("Color", {
			Label = "#Tool_wire_textscreen_colour",
			Red = "wire_textscreen_tred",
			Green = "wire_textscreen_tgreen",
			Blue = "wire_textscreen_tblue",
			ShowAlpha = "0",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})
		WireDermaExts.ModelSelect(panel, "wire_textscreen_model", list.Get( "WireScreenModels" ), 2)
		panel:CheckBox("#Tool_wire_textscreen_createflat", "wire_textscreen_createflat")
		panel:TextEntry("#Tool_wire_textscreen_text", "wire_textscreen_text")

		panel:CheckBox("Weld", "wire_textscreen_weld")
	end
end -- wire_textscreen



do -- Holography--
	WireToolSetup.setCategory( "Render" )

	do -- wire_holoemitter
		WireToolSetup.open( "holoemitter", "HoloEmitter", "gmod_wire_holoemitter", nil, "HoloEmitters" )

		local function HoloRightClick( self, trace )
			if CLIENT then return true end

			local ent = trace.Entity

			if (self:GetStage() == 0) then
				if (ent:GetClass() == "gmod_wire_holoemitter") then
					self.Target = ent
					self:SetStage(1)
				else
					self:GetOwner():ChatPrint("That's not a holoemitter.")
					return false
				end
			else
				if (self.Target == ent or ent:IsWorld()) then
					self:GetOwner():ChatPrint("Holoemitter unlinked.")
					self.Target:UnLink()
					self:SetStage(0)
					return true
				end
				self.Target:Link( ent )
				self:SetStage(0)
				self:GetOwner():ChatPrint( "Holoemitter linked to entity (".. tostring(ent)..")" )
			end

			return true
		end

		if CLIENT then
			language.Add( "tool.wire_holoemitter.name", "Holographic Emitter Tool (Wire)" )
			language.Add( "tool.wire_holoemitter.desc", "The emitter required for holographic projections" )
			language.Add( "tool.wire_holoemitter.0", "Primary: Create emitter, Secondary: Link emitter to any entity (makes it draw local to that entity instead)" )
			language.Add( "tool.wire_holoemitter.1", "Secondary: Link to entity (click the same holoemitter again to unlink it)" )
			language.Add( "Tool_wire_holoemitter_fadetime", "Client side max fade time (set to 0 to never fade)." )
			language.Add( "Tool_wire_holoemitter_keeplatestdot", "Keep latest dot indefinitely (prevent fading)." )
		end
		WireToolSetup.BaseLang()

		WireToolSetup.SetupMax( 10, "wire_holoemitters", "You've hit the holoemitters limit!" )

		if SERVER then
			function TOOL:MakeEnt( ply, model, Ang, trace )
				return MakeWireHoloemitter( ply, trace.HitPos, Ang, model )
			end
		end

		TOOL.RightClick   = HoloRightClick
		TOOL.Reload       = HoloReload
		TOOL.ClientConVar = {
			model = "models/jaanus/wiretool/wiretool_range.mdl",
			weld = 1
		}

		function TOOL.BuildCPanel( panel )
			WireToolHelpers.MakePresetControl(panel, "wire_holoemitter")
			WireDermaExts.ModelSelect(panel, "wire_holoemitter_model", list.Get( "Wire_Misc_Tools_Models" ), 1)

			panel:NumSlider("#Tool_wire_holoemitter_fadetime", "cl_wire_holoemitter_maxfadetime", 0, 100, 1)
			panel:CheckBox("#Tool_wire_holoemitter_keeplatestdot", "wire_holoemitter_keeplatestdot")

			panel:CheckBox("Weld", "wire_holoemitter_weld")
		end
	end -- wire_holoemitter

	do -- wire_hologrid
		WireToolSetup.open( "hologrid", "HoloGrid", "gmod_wire_hologrid", nil, "HoloGrids" )

		if CLIENT then

			local stage0 = "Secondary: Link HoloGrid with HoloEmitter or reference entity, Reload: Unlink HoloEmitter or HoloGrid"
			local stage1 = "Select the HoloGrid to link to."
			local stage2 = "Select the Holo Emitter or reference entity to link to."

			language.Add( "tool.wire_hologrid.name", "Holographic Grid Tool (Wire)" )
			language.Add( "tool.wire_hologrid.desc", "The grid to aid in holographic projections" )
			language.Add( "tool.wire_hologrid.0", "Primary: Create grid, "..stage0 )
			language.Add( "tool.wire_hologrid.1", stage1 )
			language.Add( "tool.wire_hologrid.2", stage2 )
			language.Add( "Tool_wire_hologrid_usegps", "Use GPS coordinates" )
		end
		WireToolSetup.BaseLang()

		WireToolSetup.SetupMax( 20, "wire_hologrids", "You've hit sound hologrids limit!" )

		if SERVER then
			function TOOL:GetConVars()
				return util.tobool(self:GetClientNumber( "usegps" ))
			end

			function TOOL:MakeEnt( ply, model, Ang, trace )
				return MakeWireHologrid( ply, trace.HitPos, Ang, model, self:GetConVars() )
			end
		end

		TOOL.RightClick    = HoloRightClick
		TOOL.Reload        = HoloReload
		TOOL.NoGhostOn     = { "sbox_maxwire_holoemitters" }
		TOOL.NoLeftOnClass = true
		TOOL.ClientConVar  = {
			model = "models/jaanus/wiretool/wiretool_siren.mdl",
			usegps = 0,
			weld   = 1,
		}

		function TOOL.BuildCPanel( panel )
			WireDermaExts.ModelSelect(panel, "wire_hologrid_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
			panel:CheckBox("#Tool_wire_hologrid_usegps", "wire_hologrid_usegps")
			panel:CheckBox("Weld", "wire_hologrid_weld")
		end
	end -- wire_hologrid
end -- holography
