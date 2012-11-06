WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "value", "Constant Value", "gmod_wire_value", nil, "Constant Values" )

if CLIENT then
	language.Add("Tool.wire_value.name", "Value Tool (Wire)")
	language.Add("Tool.wire_value.desc", "Spawns a constant value for use with the wire system.")
	language.Add("Tool.wire_value.0", "Primary: Create/Update Value, Secondary: Copy Settings")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	ModelPlug_Register("Numpad")
	
	local playerValues = {}
	util.AddNetworkString( "wire_value_values" )
	net.Receive( "wire_value_values", function( length, ply )
		playerValues[ply] = net.ReadTable()
	end)
	function TOOL:GetConVars() 
		return playerValues[self:GetOwner()] or {}
	end	
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireValue( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.Model = "models/kobilica/value.mdl"
TOOL.ClientConVar = {
	model = TOOL.Model,
	modelsize = "",
}

if CLIENT then
	local ValuePanels = {}
	local selectedValues = {}
	local function SendUpdate()
		net.Start("wire_value_values")
			net.WriteTable(selectedValues)
		net.SendToServer()
	end
	// Supported Data Types.
	local DataTypes = {
		["NORMAL"] = "Number",
		["STRING"] = "String",
		["VECTOR"] = "Vector",
		["ANGLE"]  = "Angle"
	}
	local function AddValue( panel, id )
		local w,_ = panel:GetSize()
		selectedValues[id] = {
			DataType = "Number",
			Value = 0
		}
		local control = vgui.Create( "DCollapsibleCategory", panel )
		control:SetSize( w, 100 )
		control:SetText( "Value: " .. id )
		control:SetLabel( "Value " .. id )
		control:Dock(TOP)
		
		local typeSelection = vgui.Create( "DComboBox", control )
		local _, controlW = control:GetSize()
		typeSelection:SetText( DataTypes["NORMAL"] )
		typeSelection:SetSize( controlW , 25 )
		typeSelection:DockMargin( 5,2,5,2 )
		typeSelection:Dock( TOP )
		typeSelection.OnSelect = function( panel, index, value )
			selectedValues[id].DataType = value
			SendUpdate()
		end

		for k,v in pairs( DataTypes ) do
			typeSelection:AddChoice(v)
		end
		
		local valueEntry = vgui.Create( "DTextEntry",control )
		valueEntry:Dock( TOP )
		valueEntry:DockMargin( 5,2,5,2 )
		valueEntry:DockPadding(5,5,5,5)
		valueEntry:SetValue(0)
		
		local oldLoseFocus = valueEntry.OnLoseFocus
		valueEntry.OnLoseFocus = function( panel )
			if panel:GetValue() != nil then
				local value = panel:GetValue()
				selectedValues[id].Value = panel:GetValue()
				SendUpdate()
			end
			oldLoseFocus(panel) -- Otherwise we can't close the spawnmenu!
		end

		return control 
	end
	local ValuePanels = {}
	function TOOL.BuildCPanel( panel )
		WireToolHelpers.MakeModelSizer(panel, "wire_value_modelsize")
		ModelPlug_AddToCPanel(panel, "Value", "wire_value", "#ToolWireIndicator_Model")
		
		local reset = panel:Button("Reset Values")
		
		local w,_ = panel:GetSize()
		local valueSlider = vgui.Create( "DNumSlider", panel )
		valueSlider:SetSize(w, 25 )
		valueSlider:SetText( "Amount:" )
		valueSlider:SetDark( true )
		valueSlider:SetMin(1)
		valueSlider:SetMax(20)
		valueSlider:SetDecimals( 0 )
		valueSlider:DockMargin( 5, 5, 5, 5 )
		valueSlider:Dock( TOP )
		
		local LastValueAmount = 0
		reset.DoClick = function( panel )
			valueSlider:SetValue(1)
			for k,v in pairs(ValuePanels) do
				v:Remove()
				v = nil
			end
			
			for k,v in pairs( selectedValues ) do
				v = nil
			end

			LastValueAmount = 0
			
			valueSlider.OnValueChanged( panel, 1 )
		end
		
		valueSlider.OnValueChanged = function( valueSlider, value )
			local value = tonumber(value) -- Silly Garry, giving me strings.
			if value != LastValueAmount then
				
				if value > LastValueAmount then
					for i = LastValueAmount + 1, value, 1 do
						ValuePanels[i] = AddValue( panel, i )
						
						local _,h = panel:GetSize()
						panel:SetSize(w, h+120 )
					end
				elseif value < LastValueAmount then
					for i = value + 1, LastValueAmount, 1 do
						selectedValues[i] = nil
						ValuePanels[i]:Remove()
						ValuePanels[i] = nil
						local _,h = panel:GetSize()
						panel:SetSize(w, h-120 )
					end
				else
					Msg("Error Incorrect value exists?!?!.\n")
				end
				LastValueAmount = value
				SendUpdate()
			end
		end
		valueSlider:OnValueChanged( 1 )
	end
end
