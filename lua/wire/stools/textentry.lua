WireToolSetup.setCategory("Input, Output/Keyboard Interaction")
WireToolSetup.open("textentry","Text Entry","gmod_wire_textentry",nil,"Text Entries")
if CLIENT then
	local lang=function(x,y)
		language.Add("tool.wire_textentry."..x,y)
	end
	lang("name","Wire Text Entry")
	lang("desc","Input strings on a keyboard to be used with the wire system.")
end
TOOL.ClientConVar["Model"] = "models/beer/wiremod/keyboard.mdl"
TOOL.ClientConVar["Hold"] = "1"
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)
if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("Model"),self:GetClientNumber("Hold")
	end
end
WireToolSetup.SetupLinking(true)
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header",{Description="Input strings on a keyboard to be used with the wire system."})
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_textentry", true)
	panel:NumSlider("Hold Length","wire_textentry_hold",0,10,1)
	panel:ControlHelp("Sets how long the string output is set to the inputted text in seconds. 0 for forever.")
end

