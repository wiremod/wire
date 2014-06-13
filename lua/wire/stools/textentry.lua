WireToolSetup.setCategory("Input, Output/Keyboard Interaction")
WireToolSetup.open("textentry","Text Entry","gmod_wire_textentry",nil,"Text Entries")
if CLIENT then
	local lang=function(x,y)
		language.Add("tool.wire_textentry."..x,y)
	end
	lang("name","Wire Text Entry")
	lang("desc","Input strings on a keyboard to be used with the wire system.")
	lang("0","Primary: Create/Update a Text Entry keyboard.")
end
TOOL.ClientConVar["model"] = "models/beer/wiremod/keyboard.mdl"
TOOL.ClientConVar["hold"] = "0.1"
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)
if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber("hold")
	end
end
function TOOL.BuildCPanel(panel)
	panel:AddControl("Header",{Description="Input strings on a keyboard to be used with the wire system."})
	panel:NumSlider("Hold Length","wire_textentry_hold",0.1,100,1)
	panel:ControlHelp("Sets how long the string output is set to the inputted text in seconds.")
end