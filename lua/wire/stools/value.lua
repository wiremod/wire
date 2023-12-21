WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "value", "Constant Value", "gmod_wire_value", nil, "Constant Values" )

if CLIENT then
	language.Add("Tool.wire_value.name", "Value Tool (Wire)")
	language.Add("Tool.wire_value.desc", "Spawns a constant value for use with the wire system.")

	TOOL.Information = {
		{ name = "left", text = "Create/Update " .. TOOL.Name },
		{ name = "right", text = "Copy settings" },
	}

	WireToolSetup.setToolMenuIcon( "icon16/database_go.png" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

-- shared helper functions
local function netWriteValues( selectedValues )
	local amount = math.Clamp(#selectedValues,0,20)
	net.WriteUInt(amount,5)
	for i=1,amount do
		local DataType, Value = selectedValues[i].DataType, selectedValues[i].Value

		net.WriteString( selectedValues[i].DataType )
		net.WriteString( string.sub(selectedValues[i].Value,1,3000) )
	end
end
local function netReadValues()
	local t = {}
	local amount = net.ReadUInt(5)
	for i=1,amount do
		t[i] = {
			DataType=net.ReadString(),
			Value=net.ReadString()
		}
	end
	return t
end

if SERVER then
	local playerValues = WireLib.RegisterPlayerTable()
	util.AddNetworkString( "wire_value_values" )
	net.Receive( "wire_value_values", function( length, ply )
		playerValues[ply] = netReadValues()
	end)
	function TOOL:GetConVars()
		return playerValues[self:GetOwner()] or {}
	end

	function TOOL:RightClick(trace)
		if not IsValid(trace.Entity) or trace.Entity:GetClass() ~= "gmod_wire_value" then return false end
		playerValues[self:GetOwner()] = trace.Entity.value
		net.Start("wire_value_values")
			netWriteValues(trace.Entity.value)
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
	local itemPanel
	local resetButton

	local SendUpdate

	-- Saves the values in cookies so that they can be loaded next session
	local function saveValues( values )
		values = values or selectedValues

		local old_amount = cookie.GetNumber( "wire_constant_value_amount", 0 )

		cookie.Set( "wire_constant_value_amount", #values )

		if old_amount > #values then
			for i=#values+1,old_amount do
				cookie.Delete( "wire_constant_value_value" .. i )
				cookie.Delete( "wire_constant_value_type" .. i )
			end
		end

		for k, v in pairs( values ) do
			cookie.Set( "wire_constant_value_value" .. k, string.sub(v.Value,1,3000) )
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
			netWriteValues(selectedValues)
		net.SendToServer()

		saveValues()
	end

	local validityChecks = {
		Number = 		function( val ) return tonumber(val) ~= nil end,
		["2D Vector"] = function( val ) local x,y = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *$" ) return tonumber(x) ~= nil and tonumber(y) ~= nil end,
		Vector = 		function( val ) local x,y,z = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" ) return tonumber(x) ~= nil and tonumber(y) ~= nil and tonumber(z) ~= nil end,
		["4D Vector"] = function( val ) local x,y,z,w = string.match( val, "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *, *([%d.]+) *$" ) return tonumber(x) ~= nil and tonumber(y) ~= nil and tonumber(z) ~= nil and tonumber(w) ~= nil end,
		String = 		function( val ) return true end,
	}
	validityChecks.Angle = validityChecks.Vector -- it's the same as vectors

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
		pnl.id = id

		local top_panel = vgui.Create( "DPanel", pnl )
		top_panel.Paint = function() end
		top_panel:Dock( TOP )

		local _ = vgui.Create( "DPanel", top_panel ) -- this was the only solution I could think of to properly align this shit
		_:Dock( RIGHT )
		_.Paint = function() end
		_:SetSize( 16, 14 )
		local rem = vgui.Create( "DImageButton", _ )
		rem:SetImage( "icon16/delete.png" )
		rem:SizeToContents()
		rem:SetPos( 0, 4 )
		rem:SetToolTip( "Remove this value" )

		rem.DoClick = function()
			if #selectedValues == 1 then -- can't remove the last value
				resetButton:DoClick() -- instead, do a reset
				return
			end

			local id = pnl.id
			panels[id]:Remove()
			table.remove( panels, id )
			table.remove( selectedValues, id )
			slider:SetValue( math.max( slider:GetValue() - 1, 1 ) )
			for i=id, math.Clamp(math.Round(slider:GetValue()),1,20) do
				panels[i].id = i
				panels[i]:SetLabel( "Value " .. i )
			end
		end

		local typeSelection = vgui.Create( "DComboBox", top_panel )
		typeSelection:Dock( FILL )
		typeSelection:DockMargin( 2, 2, 2, 2 )
		pnl.typeSelection = typeSelection

		typeSelection.OnSelect = function( panel, index, value )
			selectedValues[pnl.id].DataType = types_lookup[value] or "NORMAL"
			SendUpdate()

			local val, tp = selectedValues[pnl.id].Value, selectedValues[pnl.id].DataType
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
			selectedValues[pnl.id].Value = panel:GetValue()

			local val, tp = selectedValues[pnl.id].Value, selectedValues[pnl.id].DataType
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
			selectedValues[pnl.id].Value = panel:GetValue()
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
		saveValues( netReadValues() )

		if not IsValid(slider) then -- They right clicked without opening the cpanel first, just save the values
			return
		end

		loadValues()
	end)

	local function loadPreset(data)
		local values = {}
		-- Did you know Garry's Mod has a cool feature where this table's keys can be strings OR numbers?
		if isnumber(next(data)) then
			for i = 1, #data, 2 do
				table.insert(values, { DataType = data[i], Value = data[i + 1] })
			end
		else
			for i = 1, table.Count(data), 2 do
				table.insert(values, { DataType = data[tostring(i)], Value = data[tostring(i + 1)] })
			end
		end
		saveValues(values)
	end

	-- Build context menu panel
	function TOOL.BuildCPanel( panel )
		local ctrl = vgui.Create("ControlPresets", panel)
		ctrl.OnSelect = function(self, index, value, data)
			if not data then return end
			loadPreset(data)
			loadValues()
		end
		ctrl.QuickSaveInternal = function(self, text)
			local tbl = {}
			for _, v in ipairs(selectedValues) do
				table.insert(tbl, v.DataType)
				table.insert(tbl, v.Value)
			end

			presets.Add("wire_value", text, tbl)
			ctrl:Update()
		end
		ctrl:SetPreset("wire_value")
		panel:AddPanel(ctrl)

		WireToolHelpers.MakeModelSizer(panel, "wire_value_modelsize")
		ModelPlug_AddToCPanel(panel, "Value", "wire_value", true)

		local reset = panel:Button("Reset Values")
		resetButton = reset

		typeGuessCheckbox = panel:CheckBox( "Automatically guess types", "wire_value_guesstype" )
		typeGuessCheckbox:SetToolTip(
[[When enabled, the type dropdown will automatically be updated as you type with
guessed types. It's unable to guess angles because they look the same as vectors.

The green check you see inside the text boxes is the validator. If the value you write
is a value that can't be parsed as the selected type, the green check will turn into
a red X to indicate there's an error (You can then hover your cursor over the text box
to see what's wrong).

There will never be an error if auto type guessing is enabled (unless you manually
set the type), because it will automatically set the type to a string when all other
types fail.]] )

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
			if value ~= LastValueAmount then
				if value > LastValueAmount then
					for i = LastValueAmount + 1, value, 1 do
						panels[i] = AddValue( itemPanel, i )
					end
				elseif value < LastValueAmount then
					for i = value + 1, LastValueAmount, 1 do
						selectedValues[i] = nil
						if IsValid(panels[i]) then panels[i]:Remove() end
						panels[i] = nil
					end
				end

				itemPanel:SetTall( value * 73 )
				LastValueAmount = value
				SendUpdate()
			end
		end

		itemPanel = vgui.Create( "DPanel" )
		itemPanel.Paint = function() end
		panel:AddItem( itemPanel )
		itemPanel:SetTall( 73 )

		loadValues()
		SendUpdate()

		local pnl = vgui.Create( "DPanel" )
		panel:AddItem( pnl )
		pnl.Paint = function() end
		pnl:SetTall( 16 )

		local add = vgui.Create( "DImageButton", pnl )
		add:SetImage( "icon16/add.png" )
		add:SizeToContents()
		add:SetToolTip( "Add a new value" )

		function pnl.PerformLayout()
			add:Center()
		end

		function add.DoClick()
			slider:SetValue( math.min( slider:GetValue() + 1, 20 ) )
		end
	end
end
