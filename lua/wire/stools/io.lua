AddCSLuaFile( "io.lua" )
WireToolSetup.setCategory( "I/O" )

do -- wire_adv_input
	WireToolSetup.open( "adv_input", "Adv. Input", "gmod_wire_adv_input", WireToolMakeAdvInput )

	if CLIENT then
		language.Add( "tool.wire_adv_input.name", "Adv. Input Tool (Wire)" )
		language.Add( "tool.wire_adv_input.desc", "Spawns a adv. input for use with the wire system." )
		language.Add( "tool.wire_adv_input.0", "Primary: Create/Update Adv. Input" )
		language.Add( "WireAdvInputTool_keymore", "Increase:" )
		language.Add( "WireAdvInputTool_keyless", "Decrease:" )
		language.Add( "WireAdvInputTool_toggle", "Toggle" )
		language.Add( "WireAdvInputTool_value_min", "Minimum:" )
		language.Add( "WireAdvInputTool_value_max", "Maximum:" )
		language.Add( "WireAdvInputTool_value_start", "Start at:" )
		language.Add( "WireAdvInputTool_speed", "Change per second:" )
		language.Add( "sboxlimit_wire_adv_inputs", "You've hit wired adv input limit!" )
	end
	WireToolSetup.BaseLang("Adv. Inputs")

	if SERVER then
	  CreateConVar('sbox_maxwire_adv_inputs',20)
	  ModelPlug_Register("Numpad")
	end

	TOOL.ClientConVar = {
		keymore = "3",
		keyless = "1",
		toggle = "0",
		value_min = "0",
		value_max = "10",
		value_start = "5",
		speed = "1",
		model = "models/beer/wiremod/numpad.mdl",
		modelsize = ""
	}
	TOOL.ModelInfo = {"","",""}

	function TOOL:Think()
		if self.ModelInfo[1]!= self:GetClientInfo( "model" ) || self.ModelInfo[2]!= self:GetClientInfo( "modelsize" ) then
			self.ModelInfo[1] = self:GetClientInfo( "model" )
			self.ModelInfo[2] = self:GetClientInfo( "modelsize" )
			self.ModelInfo[3] = self.ModelInfo[1]
			if (self.ModelInfo[1] && self.ModelInfo[2] && self.ModelInfo[2]!="") then
				local test = string.sub(self.ModelInfo[1], 1, -5) .. self.ModelInfo[2] .. string.sub(self.ModelInfo[1], -4)
				if (util.IsValidModel(test) && util.IsValidProp(test)) then
					self.ModelInfo[3] = test
				end
			end
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() then
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		self:UpdateGhost( self.GhostEntity )
	end

	function TOOL.BuildCPanel( CPanel )
		CPanel:AddControl("Label", {Text = "Model Size (if available)"})
		CPanel:AddControl("ComboBox", {
			Label = "Model Size",
			MenuButton = 0,
			Options = {
					["normal"] = { wire_adv_input_modelsize = "" },
					["mini"] = { wire_adv_input_modelsize = "_mini" },
					["nano"] = { wire_adv_input_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(CPanel, "Numpad", "wire_adv_input", "#ToolWireIndicator_Model")
		CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keymore", Command = "wire_adv_input_keymore"})
		CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keyless", Command = "wire_adv_input_keyless"})
		CPanel:CheckBox("#WireAdvInputTool_toggle", "wire_adv_input_toggle")
		CPanel:NumSlider("#WireAdvInputTool_value_min", "wire_adv_input_value_min", -50, 50, 0)
		CPanel:NumSlider("#WireAdvInputTool_value_max", "wire_adv_input_value_max", -50, 50, 0)
		CPanel:NumSlider("#WireAdvInputTool_value_start", "wire_adv_input_value_start", -50, 50, 0)
		CPanel:NumSlider("#WireAdvInputTool_speed", "wire_adv_input_speed", 0.1, 50, 1)
	end
end -- wire_adv_input



do -- wire_adv_pod
	WireToolSetup.open( "adv_pod", "Advanced Pod Controller", "gmod_wire_adv_pod", WireToolMakeAdvPod )

	if CLIENT then
		language.Add("tool.wire_adv_pod.name", "Advanced Pod Controller Tool (Wire)")
		language.Add("tool.wire_adv_pod.desc", "Spawn/link a Wire Advanced Pod controller.")
		language.Add("tool.wire_adv_pod.0", "Primary: Create Advanced Pod controller. Secondary: Link Advanced controller.")
		language.Add("tool.wire_adv_pod.1", "Now select the pod to link to.")
	end
	WireToolSetup.BaseLang("Adv. Pod Controllers")

	if SERVER then
		ModelPlug_Register("podctrlr")
	end

	TOOL.NoLeftOnClass = true
	TOOL.ClientConVar = {
		model = "models/jaanus/wiretool/wiretool_siren.mdl"
	}

	function TOOL:RightClick(trace)
		if (CLIENT) then return true end
		if self:GetStage() == 0 and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
			self.PodCont = trace.Entity
			self:SetStage(1)
			return true
		elseif self:GetStage() == 1 and trace.Entity:IsVehicle() then
			local owner = self:GetOwner()
			if self.PodCont:Link(trace.Entity) then
				owner:PrintMessage(HUD_PRINTTALK,"Adv. Pod linked!")
			else
				owner:PrintMessage(HUD_PRINTTALK,"Link failed!")
			end
			self:SetStage(0)
			self.PodCont = nil
			return true
		else
			return false
		end
	end

	function TOOL:Reload(trace)
		self:SetStage(0)
		self.PodCont = nil
	end

	function TOOL.BuildCPanel(panel)
		ModelPlug_AddToCPanel(panel, "podctrlr", "wire_adv_pod", nil, nil, nil, 1)
	end
end -- wire_adv_pod



do --wire_button
	WireToolSetup.open( "button", "Button", "gmod_wire_button", WireToolMakeButton )

	if CLIENT then
		language.Add( "tool.wire_button.name", "Button Tool (Wire)" )
		language.Add( "tool.wire_button.desc", "Spawns a button for use with the wire system." )
		language.Add( "tool.wire_button.0", "Primary: Create/Update Button" )
		language.Add( "WireButtonTool_toggle", "Toggle" )
		language.Add( "WireButtonTool_entityout", "Output Entity" )
		language.Add( "WireButtonTool_value_on", "Value On:" )
		language.Add( "WireButtonTool_value_off", "Value Off:" )
		language.Add( "sboxlimit_wire_buttons", "You've hit wired buttons limit!" )
	end
	WireToolSetup.BaseLang("Buttons")

	if SERVER then
		CreateConVar('sbox_maxwire_buttons', 20)
		ModelPlug_Register("button")
	end

	TOOL.ClientConVar = {
		model = "models/props_c17/clock01.mdl",
		model_category = "button",
		toggle = "0",
		value_off = "0",
		value_on = "1",
		description = "",
		entityout = "0"
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_button")

		ModelPlug_AddToCPanel_Multi(
			panel,
			{	button = "Normal",
				button_small = "Small"
			},
			"wire_button",
			"#Button_Model", nil, "#Button_Model", 6
		)
		panel:CheckBox("#WireButtonTool_toggle", "wire_button_toggle")
		panel:CheckBox("#WireButtonTool_entityout", "wire_button_entityout")
		panel:NumSlider("#WireButtonTool_value_on", "wire_button_value_on", -10, 10, 1)
		panel:NumSlider("#WireButtonTool_value_off", "wire_button_value_off", -10, 10, 1)
	end
end --wire_button

do --wire_dynamic_button
	WireToolSetup.open( "dynamic_button", "Dynamic Button", "gmod_wire_dynamic_button", WireToolMakeDynamicButton )

	if CLIENT then
		language.Add( "tool.wire_dynamic_button.name", "Dynamic Button Tool (Wire)" )
		language.Add( "tool.wire_dynamic_button.desc", "Spawns a dynamic button for use with the wire system." )
		language.Add( "tool.wire_dynamic_button.0", "Primary: Create/Update Dynamic Button" )
		language.Add( "WireDynamicButtonTool_toggle", "Toggle" )
		language.Add( "WireDynamicButtonTool_entityout", "Output Entity" )
		language.Add( "WireDynamicButtonTool_value_on", "Value On:" )
		language.Add( "WireDynamicButtonTool_value_off", "Value Off:" )
		language.Add( "sboxlimit_wire_dynamic_buttons", "You've hit wired dynamic buttons limit!" )
	end
	WireToolSetup.BaseLang("Dynamic Buttons")

	if SERVER then
		CreateConVar('sbox_maxwire_dynamic_buttons', 20)
	end

	TOOL.ClientConVar = {
		model = "models/bull/ranger.mdl",
		model_category = "dynamic_button",
		toggle = "0",
		value_off = "0",
		value_on = "1",
		description = "",
		entityout = "0",
        material_on  = "bull/dynamic_button_1",
        material_off = "bull/dynamic_button_0",
        on_r = 0,
        on_g = 255,
        on_b = 0,
        off_r = 255,
        off_g = 0,
        off_b = 0
	}

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_dynamic_button")

		ModelPlug_AddToCPanel_Multi(
			panel,
			{	dynamic_button = "Normal",
				dynamic_button_small = "Small"
			},
			"wire_dynamic_button",
			"#Dynamic_Button_Model", nil, "#Dynamic_Button_Model", 1.1
		)

		panel:NumSlider("#WireDynamicButtonTool_value_on", "wire_dynamic_button_value_on", -10, 10, 1)
        panel:AddControl("ComboBox", {
			Label = "WireDynamicButtonMaterialsOn",
			MenuButton = "0",
			Options = list.Get( "WireDynamicButtonMaterialsOn" )
        } )

		panel:AddControl("Color", {
			Label = "#ToolWireDynamicButton_colour_on",
			Red = "wire_dynamic_button_on_r",
			Green = "wire_dynamic_button_on_g",
			Blue = "wire_dynamic_button_on_b",
			ShowAlpha = "0",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		panel:NumSlider("#WireDynamicButtonTool_value_off", "wire_dynamic_button_value_off", -10, 10, 1)
        panel:AddControl("ComboBox", {
			Label = "#WireDynamicButtonTool_entityout",
			MenuButton = "0",
			Options = list.Get( "WireDynamicButtonMaterialsOff" )
        } )

		panel:AddControl("Color", {
			Label = "#ToolWireDynamicButton_colour_off",
			Red = "wire_dynamic_button_off_r",
			Green = "wire_dynamic_button_off_g",
			Blue = "wire_dynamic_button_off_b",
			ShowAlpha = "0",
			ShowHSV = "1",
			ShowRGB = "1",
			Multiplier = "255"
		})

		panel:CheckBox("#WireDynamicButtonTool_toggle", "wire_dynamic_button_toggle")
		panel:CheckBox("#WireDynamicButtonTool_entityout", "wire_dynamic_button_entityout")


	end
end --wire_dynamic_button

do -- wire_dual_input
	WireToolSetup.open( "dual_input", "Dual Input", "gmod_wire_dual_input", WireToolMakeDualInput )

	if CLIENT then
		language.Add( "tool.wire_dual_input.name", "Dual Input Tool (Wire)" )
		language.Add( "tool.wire_dual_input.desc", "Spawns a daul input for use with the wire system." )
		language.Add( "tool.wire_dual_input.0", "Primary: Create/Update Input" )
		language.Add( "WireDualInputTool_keygroup", "Key 1:" )
		language.Add( "WireDualInputTool_keygroup2", "Key 2:" )
		language.Add( "WireDualInputTool_toggle", "Toggle" )
		language.Add( "WireDualInputTool_value_on", "Value 1 On:" )
		language.Add( "WireDualInputTool_value_on2", "Value 2 On:" )
		language.Add( "WireDualInputTool_value_off", "Value Off:" )
		language.Add( "sboxlimit_wire_dual_inputs", "You've hit inputs limit!" )
		language.Add( "undone_gmod_wire_dual_input", "Undone Wire Dual Input" )
		language.Add( "Cleanup_gmod_wire_dual_input", "Wire Dual Inputs" )
		language.Add( "Cleaned_gmod_wire_dual_input", "Cleaned Up Wire Dual Inputs" )
	end
	WireToolSetup.BaseLang("Dual Inputs")

	if SERVER then
		CreateConVar('sbox_maxwire_dual_inputs', 20)
		ModelPlug_Register("Numpad")
	end

	TOOL.ClientConVar = {
		keygroup = 7,
		keygroup2 = 4,
		toggle = 0,
		value_off = 0,
		value_on = 1,
		value_on2 = -1,
		model = "models/beer/wiremod/numpad.mdl",
		modelsize = ""
	}
	TOOL.ModelInfo = {"","",""}

	function TOOL:Think()
		if self.ModelInfo[1]!= self:GetClientInfo( "model" ) || self.ModelInfo[2]!= self:GetClientInfo( "modelsize" ) then
			self.ModelInfo[1] = self:GetClientInfo( "model" )
			self.ModelInfo[2] = self:GetClientInfo( "modelsize" )
			self.ModelInfo[3] = self.ModelInfo[1]
			if (self.ModelInfo[1] && self.ModelInfo[2] && self.ModelInfo[2]!="") then
				local test = string.sub(self.ModelInfo[1], 1, -5) .. self.ModelInfo[2] .. string.sub(self.ModelInfo[1], -4)
				if (util.IsValidModel(test) && util.IsValidProp(test)) then
					self.ModelInfo[3] = test
				end
			end
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() then
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		self:UpdateGhost( self.GhostEntity )
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_dual_input")

		panel:AddControl("Label", {Text = "Model Size (if available)"})
		panel:AddControl("ComboBox", {
			Label = "Model Size",
			MenuButton = 0,
			Options = {
					["normal"] = { wire_dual_input_modelsize = "" },
					["mini"] = { wire_dual_input_modelsize = "_mini" },
					["nano"] = { wire_dual_input_modelsize = "_nano" }
				}
		})

		ModelPlug_AddToCPanel(panel, "Numpad", "wire_dual_input", "#ToolWireIndicator_Model")

		panel:AddControl("Numpad", {
			Label = "#WireDualInputTool_keygroup",
			Command = "wire_dual_input_keygroup"
		})

		panel:AddControl("Numpad", {
			Label = "#WireDualInputTool_keygroup2",
			Command = "wire_dual_input_keygroup2"
		})

		panel:CheckBox("#WireDualInputTool_toggle", "wire_dual_input_toggle")
		panel:NumSlider("#WireDualInputTool_value_on", "wire_dual_input_value_on", -10, 10, 1)
		panel:NumSlider("#WireDualInputTool_value_off", "wire_dual_input_value_off", -10, 10, 1)
		panel:NumSlider("#WireDualInputTool_value_on2", "wire_dual_input_value_on2", -10, 10, 1)
	end
end -- wire_dual_input



do -- wire_input
	WireToolSetup.open( "input", "Numpad Input", "gmod_wire_input", WireToolMakeInput )

	if CLIENT then
		language.Add( "tool.wire_input.name", "Input Tool (Wire)" )
		language.Add( "tool.wire_input.desc", "Spawns a input for use with the wire system." )
		language.Add( "tool.wire_input.0", "Primary: Create/Update Input" )
		language.Add( "WireInputTool_keygroup", "Key:" )
		language.Add( "WireInputTool_toggle", "Toggle" )
		language.Add( "WireInputTool_value_on", "Value On:" )
		language.Add( "WireInputTool_value_off", "Value Off:" )
		language.Add( "sboxlimit_wire_inputs", "You've hit inputs limit!" )
	end
	WireToolSetup.BaseLang("Inputs")

	if SERVER then
		CreateConVar('sbox_maxwire_inputs', 20)
		ModelPlug_Register("Numpad")
	end

	TOOL.ClientConVar = {
		keygroup = 7,
		toggle = 0,
		value_off = 0,
		value_on = 1,
		model = "models/beer/wiremod/numpad.mdl",
		modelsize = ""
	}
	TOOL.ModelInfo = {"","",""}

	function TOOL:Think()
		if self.ModelInfo[1]!= self:GetClientInfo( "model" ) || self.ModelInfo[2]!= self:GetClientInfo( "modelsize" ) then
			self.ModelInfo[1] = self:GetClientInfo( "model" )
			self.ModelInfo[2] = self:GetClientInfo( "modelsize" )
			self.ModelInfo[3] = self.ModelInfo[1]
			if (self.ModelInfo[1] && self.ModelInfo[2] && self.ModelInfo[2]!="") then
				local test = string.sub(self.ModelInfo[1], 1, -5) .. self.ModelInfo[2] .. string.sub(self.ModelInfo[1], -4)
				if (util.IsValidModel(test) && util.IsValidProp(test)) then
					self.ModelInfo[3] = test
				end
			end
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		if !self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() then
			self:MakeGhostEntity( self.ModelInfo[3], Vector(0,0,0), Angle(0,0,0) )
		end
		self:UpdateGhost( self.GhostEntity )
	end

	function TOOL.BuildCPanel(panel)
		WireToolHelpers.MakePresetControl(panel, "wire_input")
		panel:AddControl("Label", {Text = "Model Size (if available)"})
		panel:AddControl("ComboBox", {
			Label = "Model Size",
			MenuButton = 0,
			Options = {
					["normal"] = { wire_input_modelsize = "" },
					["mini"] = { wire_input_modelsize = "_mini" },
					["nano"] = { wire_input_modelsize = "_nano" }
				}
		})
		ModelPlug_AddToCPanel(panel, "Numpad", "wire_input", "#ToolWireIndicator_Model")
		panel:AddControl("Numpad", {
			Label = "#WireInputTool_keygroup",
			Command = "wire_input_keygroup"
		})
		panel:CheckBox("#WireInputTool_toggle", "wire_input_toggle")
		panel:NumSlider("#WireInputTool_value_on", "wire_input_value_on", -10, 10, 1)
		panel:NumSlider("#WireInputTool_value_off", "wire_input_value_off", -10, 10, 1)
	end
end -- wire_input
