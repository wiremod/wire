WireToolSetup.setCategory( "Render" )
WireToolSetup.open( "cam", "Cam Controller", "gmod_wire_cameracontroller", nil, "Cam Controllers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_cam.name", "Cam Controller Tool (Wire)" )
	language.Add( "Tool.wire_cam.desc", "Spawns a constant Cam Controller prop for use with the wire system." )
	language.Add( "Tool.wire_cam.0", "Primary: Create/Update Cam Controller Secondary: Link a cam controller to a Pod." )
	language.Add( "Tool.wire_cam.1", "Now click a pod to link to." )
	language.Add( "Tool.wire_cam.static","External camera entity")
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "static" )
	end
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "static" ] = "0"

WireToolSetup.SetupLinking(SingleLink)

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cam_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#Tool.wire_cam.static", "wire_cam_static" )
end
