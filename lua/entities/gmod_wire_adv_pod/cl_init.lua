include("shared.lua")
ENT.RenderGroup = RENDERGROUP_BOTH

local bindlist = ENT.bindlist
ENT.bindlist = nil

hook.Add("PlayerBindPress", "wire_adv_pod", function(ply, bind, pressed)
	if ply:InVehicle() then
		if (bind == "invprev") then
			bind = "1"
		elseif (bind == "invnext") then
			bind = "2"
		else return end
		RunConsoleCommand("wire_adv_pod_bind", bind )
	end
end)

local hideHUD = false
local firstTime = true

hook.Add( "HUDShouldDraw", "Wire adv pod HUDShouldDraw", function( name )
	if hideHUD then
		if LocalPlayer():InVehicle() then
			if firstTime then
				LocalPlayer():ChatPrint( "The owner of this vehicle has hidden your hud using an adv pod controller. If it gets stuck this way, use the console command 'wire_adv_pod_hud_show' to forcibly enable it again." )
				firstTime = false
			end

			if name ~= "CHudCrosshair" and name ~= "CHudChat" then return false end -- Don't return false on crosshairs. Those are toggled using the other input. And we don't want to hide the chat box.
		elseif not LocalPlayer():InVehicle() then
			hideHUD = false
		end
	end
end)

usermessage.Hook( "wire adv pod hud", function( um )
	local vehicle = um:ReadEntity()
	if LocalPlayer():InVehicle() and LocalPlayer():GetVehicle() == vehicle then
		hideHUD = um:ReadBool()
	else
		hideHUD = false
	end
end)

concommand.Add( "wire_adv_pod_hud_show", function(ply,cmd,args)
	hideHUD = false
end)
