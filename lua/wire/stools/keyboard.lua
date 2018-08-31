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
		return self:GetClientNumber( "autobuffer" ) ~= 0, self:GetClientNumber( "sync" ) ~= 0, self:GetClientNumber( "enterkeyascii" ) ~= 0
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_input.mdl",
	sync = "1",
	layout = "American",
	autobuffer = "1",
	leavekey = KEY_LALT,
	enterkeyascii = "1"
}

WireToolSetup.SetupLinking(true, "vehicle")

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_keyboard", true)

	local languages = panel:ComboBox("Keyboard Layout", "wire_keyboard_layout")
	local curlayout = LocalPlayer():GetInfo("wire_keyboard_layout")
	for k,v in pairs( Wire_Keyboard_Remap ) do
		languages:AddChoice( k )
		if k == curlayout then
			local curindex = #languages.Choices
			timer.Simple(0, function() languages:ChooseOptionID(curindex) end) -- This needs to be delayed or it'll set the box to show "0"
		end
	end
	panel:Help( "The selected language is clientside. Any keyboard you use, created by any player, will use your selection. If your keyboard layout is not available in this list, you are welcome to create it and post it as a pull request on the wiremod github page." )

	panel:AddControl("Numpad", {
		Label = "#Tool.wire_keyboard.leavekey",
		Command = "wire_keyboard_leavekey",
	})
	panel:Help( "This is the key used to exit a keyboard. This option is clientside. Any keyboard you use, created by any player, will use this key." )

	panel:CheckBox("Lock player controls on keyboard", "wire_keyboard_sync")
	panel:Help( "When on, 'locks' the player into the keyboard, meaning any keys they press will not move their character around. When off, they can walk around while typing. This option is serverside, and will be saved on the keyboard through duplications." )

	panel:CheckBox("Automatic buffer clear", "wire_keyboard_autobuffer")
	panel:Help( "When on, automatically removes the key from the buffer when the user releases it.\nWhen off, leaves all keys in the buffer until they are manually removed.\nTo manually remove a key, write any value to cell 0 to remove the first key, or write a specific ascii value to any address other than 0 to remove that specific key. This option is serverside, and will be saved on the keyboard through duplications.")

	panel:CheckBox("Use '\\n' for ENTER key instead of '\\r'","wire_keyboard_enterkeyascii")
	panel:Help( "On: Enter=10 ('\\n')\nOff: Enter=13 ('\\r')\nThis option is serverside, and will be saved on the keyboard through duplications." )
end
