WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "las_reciever", "Laser Pointer Receiver", "gmod_wire_las_reciever", nil, "Laser Pointer Receivers" )

if CLIENT then
	language.Add( "Tool.wire_las_reciever.name", "Laser Receiver Tool (Wire)" )
	language.Add( "Tool.wire_las_reciever.desc", "Spawns a constant laser receiver prop for use with the wire system." )
	language.Add( "Tool.wire_las_reciever.0", "Primary: Create/Update Laser Receiver" )
	language.Add( "WireILaserRecieverTool_ilas_reciever", "Laser Receiver:" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if SERVER then
	function TOOL:GetConVars() end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireLaserReciever( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_range.mdl",
}

function TOOL.BuildCPanel(panel)
	panel:Help("#Tool.wire_las_reciever.desc")
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_las_reciever")
end