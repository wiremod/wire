WireToolSetup.setCategory( "Vehicle Control", "Visuals" )
WireToolSetup.open( "cam", "Cam Controller", "gmod_wire_cameracontroller", nil, "Cam Controllers" )

if ( CLIENT ) then
	language.Add( "Tool.wire_cam.name", "Cam Controller Tool (Wire)" )
	language.Add( "Tool.wire_cam.desc", "Spawns a constant Cam Controller prop for use with the wire system." )
	language.Add( "Tool.wire_cam.0", "Primary: Create/Update Cam Controller Secondary: Link a cam controller to a Pod." )
	language.Add( "Tool.wire_cam.1", "Now click a pod to link to." )
	language.Add( "Tool.wire_cam.parentlocal", "Coordinates local to parent" )
	language.Add( "Tool.wire_cam.automove", "Client side movement" )
	language.Add( "Tool.wire_cam.localmove", "Localized movement" )
	language.Add( "Tool.wire_cam.allowzoom", "Client side zooming" )
	language.Add( "Tool.wire_cam.autounclip", "Auto un-clip" )
	language.Add( "Tool.wire_cam.drawplayer", "Draw player" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20 )

if SERVER then
	function TOOL:GetConVars()
		return 	self:GetClientNumber( "parentlocal" ),
				self:GetClientNumber( "automove" ),
				self:GetClientNumber( "localmove" ),
				self:GetClientNumber( "allowzoom" ),
				self:GetClientNumber( "autounclip" ),
				self:GetClientNumber( "drawplayer" )
	end
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "parentlocal" ] = "0"
TOOL.ClientConVar[ "automove" ] = "0"
TOOL.ClientConVar[ "localmove" ] = "0"
TOOL.ClientConVar[ "allowzoom" ] = "0"
TOOL.ClientConVar[ "autounclip" ] = "0"
TOOL.ClientConVar[ "drawplayer" ] = "1"

WireToolSetup.SetupLinking()

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_cam_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
	panel:CheckBox("#Tool.wire_cam.parentlocal", "wire_cam_parentlocal" )
	panel:CheckBox("#Tool.wire_cam.automove", "wire_cam_automove" )
	panel:Help( "Allow the player to rotate the camera using their mouse. When active, the position input becomes the center of the camera's orbit." )
	panel:CheckBox("#Tool.wire_cam.localmove", "wire_cam_localmove" )
	panel:Help( "Determines whether the client side movement is local to the parent or not (NOTE: only used if 'client side movement' is enabled)" )
	panel:CheckBox("#Tool.wire_cam.allowzoom", "wire_cam_allowzoom" )
	panel:Help( "Allow the player to move the camera in and out using the scroller on their mouse. The 'Distance' input is used as an offset for this. (NOTE: only used if 'client side movement' is enabled. NOTE: The cam controller's outputs might be wrong when this is enabled, because the server doesn't know how much they've zoomed - it only knows what the 'Distance' input is set to)." )
	panel:CheckBox("#Tool.wire_cam.autounclip", "wire_cam_autounclip" )
	panel:Help( "Automatically prevents the camera from clipping into walls by moving it closer to the parent entity (or cam controller if no parent is specified)." )
	panel:CheckBox("#Tool.wire_cam.drawplayer", "wire_cam_drawplayer" )
	panel:Help( "Enable/disable the player being able to see themselves. Useful if you want to position the camera inside the player's head." )
	
	panel:Help( "As you may have noticed, there are a lot of behaviors that change depending on which checkboxes are checked. For a detailed walkthrough of everything, go to http://wiki.wiremod.com/wiki/Cam_Controller") 
end
