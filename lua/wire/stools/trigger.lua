-- Wire Trigger created by mitterdoo
WireToolSetup.setCategory( "Detection" )
WireToolSetup.open( "trigger", "Trigger", "gmod_wire_trigger", nil, "Triggers" )

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	filter = 0, -- 0: all entities, 1: only players, 2: only props (and stuff that isn't a player)
	owneronly = 0,
	sizex = 64,
	sizey = 64,
	sizez = 64,
	offsetx = 0,
	offsety = 0,
	offsetz = 0,
}
local DrawOutline
if CLIENT then
	DrawOutline = CreateClientConVar( "wire_trigger_drawalltriggers", "0", true )
	language.Add( "Tool.wire_trigger.filter", "Filters" )
	language.Add( "Tool.wire_trigger.owneronly", "Owner's Stuff Only" )
	language.Add( "Tool.wire_trigger.sizex", "Size X" )
	language.Add( "Tool.wire_trigger.sizey", "Size Y" )
	language.Add( "Tool.wire_trigger.sizez", "Size Z" )
	language.Add( "Tool.wire_trigger.offsetx", "Offset X" )
	language.Add( "Tool.wire_trigger.offsety", "Offset Y" )
	language.Add( "Tool.wire_trigger.offsetz", "Offset Z" )
	language.Add( "tool.wire_trigger.name", "Trigger Tool (Wire)" )
	language.Add( "tool.wire_trigger.desc", "Spawns a Trigger" )
	language.Add( "Tool.wire_trigger.alltriggers", "All Triggers Visible" )
	language.Add( "tool.wire_trigger.resetsize", "Reset Size" )
	language.Add( "tool.wire_trigger.resetoffset", "Reset Offset" )
	language.Add( "Tool.wire_trigger.filter_all", "All Entities" )
	language.Add( "Tool.wire_trigger.filter_players", "Only Players" )
	language.Add( "Tool.wire_trigger.filter_props", "Only Props" )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }

	concommand.Add( "wire_trigger_reset_size", function( ply, cmd, args )

		RunConsoleCommand( "wire_trigger_sizex", 64 )
		RunConsoleCommand( "wire_trigger_sizey", 64 )
		RunConsoleCommand( "wire_trigger_sizez", 64 )

	end )
	concommand.Add( "wire_trigger_reset_offset", function( ply, cmd, args )

		RunConsoleCommand( "wire_trigger_offsetx", 0 )
		RunConsoleCommand( "wire_trigger_offsety", 0 )
		RunConsoleCommand( "wire_trigger_offsetz", 0 )

	end )

end

WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 64 )

function TOOL:GetConVars()
	return self:GetClientInfo( "model" ), self:GetClientNumber( "filter" ), self:GetClientNumber( "owneronly" ), self:GetClientNumber( "sizex" ), self:GetClientNumber( "sizey" ), self:GetClientNumber( "sizez" ), self:GetClientNumber( "offsetx" ), self:GetClientNumber( "offsety" ), self:GetClientNumber( "offsetz" )
end

local function DrawTriggerOutlines( list )
	cam.Start3D( LocalPlayer():EyePos(), LocalPlayer():EyeAngles() )
		for k,ent in pairs( list ) do
			local trig = ent:GetTriggerEntity()

			render.DrawWireframeBox( trig:GetPos(), Angle(0,0,0), trig:OBBMins(), trig:OBBMaxs(), Color( 255, 255, 0 ), true )
			render.DrawLine( trig:GetPos(), ent:GetPos(), Color( 255, 255, 0 ) )
		end
	cam.End3D()
end

hook.Add( "HUDPaint", "wire_trigger_draw_all_triggers", function()
	if DrawOutline:GetBool() then
		DrawTriggerOutlines( ents.FindByClass( "gmod_wire_trigger" ) )
	end
end )

function TOOL:DrawHUD()
	local tr = util.TraceLine( util.GetPlayerTrace( LocalPlayer() ) )
	local ent = tr.Entity
	if IsValid( ent ) and ent:GetClass() == "gmod_wire_trigger" and not DrawOutline:GetBool() then
		DrawTriggerOutlines( {ent} )
	end
end
function TOOL:RightClick( tr )
	if SERVER then return end

	if IsValid( tr.Entity ) then
		local ent = tr.Entity
		if ent:GetClass() == "gmod_wire_trigger" then

			-- http:--youtu.be/RTR1ny0O_io
			local size = ent:GetTriggerSize()
			local offset = ent:GetTriggerOffset()
			RunConsoleCommand( "wire_trigger_sizex", size.x )
			RunConsoleCommand( "wire_trigger_sizey", size.y )
			RunConsoleCommand( "wire_trigger_sizez", size.z )
			RunConsoleCommand( "wire_trigger_offsetx", offset.x )
			RunConsoleCommand( "wire_trigger_offsety", offset.y )
			RunConsoleCommand( "wire_trigger_offsetz", offset.z )
			RunConsoleCommand( "wire_trigger_filter", ent:GetFilter() )
			RunConsoleCommand( "wire_trigger_owneronly", ent:GetOwnerOnly() and 1 or 0 )
			RunConsoleCommand( "wire_trigger_model", ent:GetModel() )
			return true

		end
	end
end


function TOOL.BuildCPanel( panel )
	ModelPlug_AddToCPanel(panel, "Misc_Tools", "wire_trigger")
	panel:CheckBox( "#Tool.wire_trigger.alltriggers", "wire_trigger_drawalltriggers" )
	panel:AddControl( "ComboBox", {
		Label = "#Tool.wire_trigger.filter",
		Options = {
			["#Tool.wire_trigger.filter_all"] = { wire_trigger_filter = 0 },
			["#Tool.wire_trigger.filter_players"] = { wire_trigger_filter = 1 },
			["#Tool.wire_trigger.filter_props"] = { wire_trigger_filter = 2 },
		}
	})
	panel:CheckBox( "#Tool.wire_trigger.owneronly", "wire_trigger_owneronly" )
	panel:Button( "#Tool.wire_trigger.resetsize", "wire_trigger_reset_size" )
	panel:NumSlider("#Tool.wire_trigger.sizex", "wire_trigger_sizex", -1000, 1000, 64)
	panel:NumSlider("#Tool.wire_trigger.sizey", "wire_trigger_sizey", -1000, 1000, 64)
	panel:NumSlider("#Tool.wire_trigger.sizez", "wire_trigger_sizez", -1000, 1000, 64)
	panel:Button( "#Tool.wire_trigger.resetoffset", "wire_trigger_reset_offset" )
	panel:NumSlider("#Tool.wire_trigger.offsetx", "wire_trigger_offsetx", -1000, 1000, 0)
	panel:NumSlider("#Tool.wire_trigger.offsety", "wire_trigger_offsety", -1000, 1000, 0)
	panel:NumSlider("#Tool.wire_trigger.offsetz", "wire_trigger_offsetz", -1000, 1000, 0)
end
