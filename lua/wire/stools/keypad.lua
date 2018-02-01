WireToolSetup.setCategory( "Input, Output" )
WireToolSetup.open( "keypad", "Keypad", "gmod_wire_keypad", nil, "Keypads" )

if CLIENT then
	language.Add( "tool."..TOOL.Mode..".name", TOOL.Name.." Tool (Wire)" )
	language.Add( "tool."..TOOL.Mode..".desc", "Spawns a "..TOOL.Name )
	language.Add( "tool."..TOOL.Mode..".password", "Password: " )
	language.Add( "tool."..TOOL.Mode..".secure", "Display Asterisks: " )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

if SERVER then
	function TOOL:GetConVars()
		return util.CRC(self:GetClientInfo("password")), self:GetClientNumber("secure") ~= 0
	end

	function TOOL:CheckPassword()
		local password = self:GetClientNumber("password")
		if password == nil or string.find(password, "0") then
			WireLib.AddNotify(self:GetOwner(), "Password can only contain numbers 1-9", NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
			return false
		elseif string.len(password) > 4 then
			WireLib.AddNotify(self:GetOwner(), "Password cannot be over 4 characters", NOTIFY_ERROR, 5, NOTIFYSOUND_DRIP3)
			return false
		end
		return true
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return self:CheckPassword() and WireLib.MakeWireEnt( ply, {Class = self.WireClass, Pos=trace.HitPos, Angle=Ang, Model=model}, self:GetConVars() )
	end

	function TOOL:LeftClick_Update( trace )
		if self:CheckPassword() then trace.Entity:Setup(self:GetConVars()) end
	end
end

TOOL.ClientConVar = {
	model = "models/props_lab/keypad.mdl",
	password = "",
	secure = "0",
	createflat = "1", -- The model needs this
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_keypad")
	panel:TextEntry("#tool.wire_keypad.password", "wire_keypad_password"):SetNumeric(true)
	panel:CheckBox("#tool.wire_keypad.secure", "wire_keypad_secure")
end
