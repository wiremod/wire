WireToolSetup.setCategory( "Input, Output/Keyboard Interaction", "Vehicle Control" )
WireToolSetup.open( "keyboard", "Keyboard", "gmod_wire_keyboard", nil, "Keyboards" )

if ( CLIENT ) then
	language.Add( "Tool.wire_keyboard.name", "Wired Keyboard Tool (Wire)" )
	language.Add( "Tool.wire_keyboard.desc", "Spawns a keyboard input for use with the hi-speed wire system." )
	language.Add( "Tool.wire_keyboard.leavekey", "Leave Key" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if (SERVER) then
	ModelPlug_Register("Keyboard")
	
	function TOOL:GetConVars() 
		return self:GetClientNumber( "autobuffer" ) ~= 0, self:GetClientNumber( "sync" ) ~= 0
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_input.mdl",
	sync = "1",
	layout = "American",
	autobuffer = "1",
	leavekey = KEY_LALT
}

WireToolSetup.SetupLinking(true, "vehicle")

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_keyboard", true)

	panel:CheckBox("Lock player controls on keyboard", "wire_keyboard_sync")

	local languages = panel:ComboBox("Keyboard Layout", "wire_keyboard_layout")
	local curlayout = LocalPlayer():GetInfo("wire_keyboard_layout")
	for k,v in pairs( Wire_Keyboard_Remap ) do
		languages:AddChoice( k )
		if k == curlayout then 
			local curindex = #languages.Choices 
			timer.Simple(0, function() languages:ChooseOptionID(curindex) end) -- This needs to be delayed or it'll set the box to show "0"
		end
	end
	
	panel:Help("When on, automatically removes the key from the buffer when the user releases it.\nWhen off, leaves all keys in the buffer until they are manually removed.\nTo manually remove a key, write any value to cell 0 to remove the first key, or write a specific ascii value to any address other than 0 to remove that specific key.")
	panel:CheckBox("Automatic buffer clear", "wire_keyboard_autobuffer")

	panel:AddControl("Numpad", {
		Label = "#Tool.wire_keyboard.leavekey",
		Command = "wire_keyboard_leavekey",
	})
end
