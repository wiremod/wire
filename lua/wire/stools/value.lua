WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "value", "Constant Value", "gmod_wire_value", nil, "Constant Values" )

if CLIENT then
	language.Add("Tool.wire_value.name", "Value Tool (Wire)")
	language.Add("Tool.wire_value.desc", "Spawns a constant value for use with the wire system.")
	language.Add("Tool.wire_value.0", "Primary: Create/Update Value, Secondary: Copy Settings")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	local playerValues = {}
	util.AddNetworkString( "wire_value_values" )
	net.Receive( "wire_value_values", function( length, ply )
		playerValues[ply] = net.ReadTable()
	end)
	function TOOL:GetConVars() 
		return playerValues[self:GetOwner()] or {}
	end

	function TOOL:RightClick(trace)
		if not IsValid(trace.Entity) or trace.Entity:GetClass() != "gmod_wire_value" then return false end
		playerValues[self:GetOwner()] = trace.Entity.value
		net.Start("wire_value_values")
			net.WriteTable(trace.Entity.value)
		net.Send(self:GetOwner())
	end
end

TOOL.ClientConVar = {
	model = "models/kobilica/value.mdl",
	modelsize = "",
	guesstype = "1",
}

if CLIENT then
	function TOOL:RightClick(trace)
		return IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_value"
	end
	
	-- Supported data types
	local types_lookup = {
		Number = "NORMAL",
		String = "STRING",
		Angle = "ANGLE",
		Vector = "VECTOR",
		["2D Vector"] = "VECTOR2",
		["4D Vector"] = "VECTOR4",
	}
	local types_lookup2 = {
		NORMAL = "Number",
		STRING  = "String",
		ANGLE = "Angle",
		VECTOR = "Vector",
		VECTOR2 = "2D Vector",
		VECTOR4 = "4D Vector",
	}
	
	local types_ordered = {	"Number", "String", "Angle", "Vector", "2D Vector", "4D Vector" }

	local ValuePanels = {}
	local selectedValues = {}
	local panels = {}
	local slider
	local typeGuessCheckbox
	
	local SendUpdate
	
	-- Saves the values in cookies so that they can be loaded next session
	local function saveValues( values )
		values = values or selectedValues
		
		local old_amount = cookie.GetNumber( "wire_constant_value_amount", 0 )
		
		cookie.Set( "wire_constant_value_amount", #values )
		
		if old_amount > #values then
			for i=#values,old_amount do
				cookie.Delete( "wire_constant_value_value" .. i )
				cookie.Delete( "wire_constant_value_type" .. i )
			end
		end
		
		for k, v in pairs( values ) do
			cookie.Set( "wire_constant_value_value" .. k, v.Value )
			cookie.Set( "wire_constant_value_type" .. k, v.DataType )
		end
	end
	
	-- Loads the values from cookies
	-- Don't worry about performance, because while garry's cookies are saved in a database,
	-- they're also saved in Lua tables, which means they're accessed instantly.
	local function loadValues( dontupdate )
		local oldSendUpdate = SendUpdate
		SendUpdate = function() end -- Don't update now
		
		local amount = cookie.GetNumber( "wire_constant_value_amount", 0 )
		
		slider:SetValue(amount)
		
		for i=1,amount do
			local tp = cookie.GetString( "wire_constant_value_type" .. i, "NORMAL" )
			local val = cookie.GetString( "wire_constant_value_value" .. i, "0" )
			
			tp = types_lookup2[tp] or "Number"
			
			selectedValues[i].DataType = tp
			selectedValues[i].Value = val
			
			panels[i].valueEntry:SetValue( val )
			panels[i].typeSelection:SetText( tp )
			panels[i].typeSelection:OnSelect( _, tp )
		end
		
		SendUpdate = oldSendUpdate -- okay now it's fine to update again
	end
	
	-- Sends the values to the server
	function SendUpdate()
		net.Start("wire_value_values")
			net.WriteTable(selectedValues)
		net.SendToServer()
		
		saveValues()
	end
	
	local validityChecks = {
		Number = 		function( val ) return string.match( val, "^ *([%d.]+) *$" ) ~= nil end,
		["2D Vector"] = function( val ) local x,y = string.match( val, "^ *([%d.]+) *, *([%d.]+) *$" ) return x and y end,
		Vector = 		function( val ) local x,y,z = string.match( val, "^ *([%d.]+) *, *([%d.]+) *, *([%d.]+) *$" ) return x and y and z end,
		["4D Vector"] = function( val ) local x,y,z,w = string.match( val, "^ *([%d.]+) *, *([%d.]+) *, *([%d.]+) *, *([%d.]+) *$" ) return x and y and z and w end,
		Angle =			function( val ) local x,y,z = string.match( val, "^ *([%d.]+) *, *([%d.]+) *, *([%d.]+) *$" ) return x and y and z end, -- it's the same as vectors
		String = 		function( val ) return true end,
	}
	
	local examples = {
		Number = "12.34",
		["2D Vector"] = "12.34, 12.34",
		Vector = "12.34, 12.34, 12.34",
		["4D Vector"] = "12.34, 12.34, 12.34, 12.34",
		String = "Hello World",
		Angle = "90, 180, 360",
	}
	
	-- Check if what the user wrote is a valid value of the specified type
	local function validateValue( str, tp )
		if validityChecks[tp] then
			return validityChecks[tp]( str )
		else
			return false
		end
	end
	
	local typeGuessing = { -- we're not checking angle because it's indistinguishable from vectors
		-- dropdown position, function
		{1,	validityChecks.Number},
		{5,	validityChecks["2D Vector"]},
		{4,	validityChecks.Vector},
		{6,	validityChecks["4D Vector"]},
		{2,	validityChecks.String},
	}
	
	-- Guess the type of the value the user wrote
	local function guessType( str, typeSelection )
		for i=1,#typeGuessing do
			local dropdownPos = typeGuessing[i][1]
			local func = typeGuessing[i][2]
			
			if func( str ) then
				typeSelection:ChooseOptionID( dropdownPos )
				return
			end
		end
	end
	
	-- Add another value panel
	local function AddValue( panel, id )
		local w = panel:GetWide()
	
		selectedValues[id] = {
			DataType = "NORMAL",
			Value = 0,
		}
		
		local pnl = vgui.Create( "DCollapsibleCategory", panel )
		pnl:SetWide( w )
		pnl:SetLabel( "Value " .. id )
		pnl:Dock( TOP )
		
		local typeSelection = vgui.Create( "DComboBox", pnl )
		pnl.typeSelection = typeSelection
		typeSelection:SetWide( w )
		typeSelection:Dock( TOP )
		typeSelection:DockMargin( 2, 2, 2, 2 )
		
		typeSelection.OnSelect = function( panel, index, value )
			selectedValues[id].DataType = types_lookup[value] or "NORMAL"
			SendUpdate()
			
			local val, tp = selectedValues[id].Value, selectedValues[id].DataType
			tp = types_lookup2[tp] or "Number"
			
			if validateValue( val, tp ) then
				pnl.valueEntry:SetToolTip()
				pnl.parseIcon:SetImage( "icon16/accept.png" )
			else
				pnl.valueEntry:SetToolTip( "This is not a valid " .. string.lower( tp ) .. ".\nExample: '" .. (examples[tp] or "No example available for this type") .. "'." )
				pnl.parseIcon:SetImage( "icon16/cancel.png" )
			end
		end
		
		for k,v in pairs( types_ordered ) do
			typeSelection:AddChoice(v)
		end	
		
		local valueEntry = vgui.Create( "DTextEntry",pnl )
		pnl.valueEntry = valueEntry
		valueEntry:Dock( TOP )
		valueEntry:DockMargin( 2, 2, 2, 2 )
		
		valueEntry.OnChange = function( panel )
			selectedValues[id].Value = panel:GetValue()
			
			local val, tp = selectedValues[id].Value, selectedValues[id].DataType
			tp = types_lookup2[tp] or "Number"
			
			if typeGuessCheckbox:GetChecked() then
				guessType( val, typeSelection )
			else
				if validateValue( val, tp ) then
					pnl.valueEntry:SetToolTip()
					pnl.parseIcon:SetImage( "icon16/accept.png" )
				else
					pnl.valueEntry:SetToolTip( "This is not a valid " .. string.lower( tp ) .. ".\nExample: '" .. (examples[tp] or "No example available for this type") .. "'." )
					pnl.parseIcon:SetImage( "icon16/cancel.png" )
				end
			end
		end
		
		local oldLoseFocus = valueEntry.OnLoseFocus
		valueEntry.OnLoseFocus = function( panel )
			selectedValues[id].Value = panel:GetValue()
			SendUpdate()
			oldLoseFocus(panel) -- Otherwise we can't close the spawnmenu!
		end
		
		local parseIcon = vgui.Create( "DImage", valueEntry )
		pnl.parseIcon = parseIcon
		parseIcon:Dock( RIGHT )
		parseIcon:DockMargin( 2,2,2,2 )
		parseIcon:SetImage( "icon16/accept.png" )
		parseIcon:SizeToContents()
		
		typeSelection:ChooseOptionID( 1 )

		return pnl
	end
	
	-- Receive values from the server (when they right click to copy)
	net.Receive( "wire_value_values", function( length )
		saveValues( net.ReadTable() )
		
		if not IsValid(slider) then -- They right clicked without opening the cpanel first, just save the values
			return
		end
		
		loadValues()
	end)
	
	-- Build context menu panel
	function TOOL.BuildCPanel( panel )
		WireToolHelpers.MakeModelSizer(panel, "wire_value_modelsize")
		ModelPlug_AddToCPanel(panel, "Value", "wire_value", true)
		
		local reset = panel:Button("Reset Values")
		
		typeGuessCheckbox = panel:CheckBox( "Automatically guess types", "wire_value_guesstype" )
		typeGuessCheckbox:SetToolTip( "When enabled, the type dropdown will automatically be updated as you type with guessed types. It's unable to guess angles because it looks the same as vectors." )
		
		local w,_ = panel:GetSize()
		local valueSlider = vgui.Create( "DNumSlider" )
		slider = valueSlider
		panel:AddItem( valueSlider )
		valueSlider:SetText( "Amount:" )
		valueSlider:SetMin(1)
		valueSlider:SetMax(20)
		valueSlider:SetDark( true )
		valueSlider:SetDecimals( 0 )
		
		local LastValueAmount = 0
		reset.DoClick = function( panel )
			valueSlider:SetValue(1)
			
			for k,v in pairs(panels) do
				v:Remove()
				panels[k] = nil
			end
			
			for k,v in pairs( selectedValues ) do
				selectedValues[k] = nil
			end

			LastValueAmount = 0
			
			valueSlider:OnValueChanged( 1 )
			SendUpdate()
		end
		
		valueSlider.OnValueChanged = function( valueSlider, value )
			local value = math.Clamp(math.Round(tonumber(value)),1,20)
			if value != LastValueAmount then
				if value > LastValueAmount then
					for i = LastValueAmount + 1, value, 1 do
						panels[i] = AddValue( panel, i )
					end
				elseif value < LastValueAmount then
					for i = value + 1, LastValueAmount, 1 do
						selectedValues[i] = nil
						if IsValid(panels[i]) then panels[i]:Remove() end
						panels[i] = nil
					end
				end
				
				panel:SetTall( value * 120 )
				LastValueAmount = value
				SendUpdate()
			end
		end
		
		loadValues()
		SendUpdate()
	end
end
