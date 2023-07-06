-- Author: mitterdoo (with help from Divran)

WireToolSetup.setCategory("Input, Output")
WireToolSetup.open("interactiveprop","Interactive Prop","gmod_wire_interactiveprop",nil,"Interactive Props")
if CLIENT then
	language.Add( "Tool.wire_interactiveprop.name", "Wire Interactive Prop" )
	language.Add( "Tool.wire_interactiveprop.desc", "Opens a UI panel which controls outputs for use with wire system." )
end



TOOL.ClientConVar = {
	model = "models/props_lab/receiver01a.mdl"
}

if SERVER then
	function TOOL:GetDataTables()
    return {}
  end
end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax(20)


function TOOL.BuildCPanel(panel)
	panel:AddControl("Header",{Description="Opens a UI panel which controls outputs for use with the wire system."})
	ModelPlug_AddToCPanel(panel, "InteractiveProp", "wire_interactiveprop", true)
end
