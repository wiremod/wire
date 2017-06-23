-- Author: mitterdoo (with help from Divran)

WireToolSetup.setCategory("Input, Output/Keyboard Interaction")
WireToolSetup.open("textentry","Text Entry","gmod_wire_textentry",nil,"Text Entries")
if CLIENT then
	language.Add( "Tool.wire_textentry.name", "Wire Text Entry" )
	language.Add( "Tool.wire_textentry.desc", "Input strings into a prompt to be used with the wire system." )
	language.Add( "Tool.wire_textentry.disableuse", "Disable use" )
	language.Add( "Tool.wire_textentry.hold", "Hold length" )
end

TOOL.ClientConVar = {
	model = "models/beer/wiremod/keyboard.mdl",
	hold = "1",
	disableuse = "1",
}

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("hold"),self:GetClientNumber("disableuse")
	end
end

WireToolSetup.SetupLinking(true, "vehicle")

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header",{Description="Input strings on a keyboard to be used with the wire system."})
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_textentry", true)
	panel:NumSlider( "#Tool.wire_textentry.hold","wire_textentry_hold",0,10,1)
	panel:ControlHelp("Sets how long the string output remains set. 0 for forever.")
	panel:CheckBox( "#Tool.wire_textentry.disableuse", "wire_textentry_disableuse" )
	panel:ControlHelp("Pressing use on the keyboard normally brings up the prompt. This option allows you to disable that. Useful when linked to a vehicle.")
end
