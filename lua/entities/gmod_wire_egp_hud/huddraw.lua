hook.Add("Initialize","EGP_HUD_Initialize",function()
	if (CLIENT) then
		local EGP_HUD_FirstPrint = true
		local tbl = {}

		--------------------------------------------------------
		-- Toggle
		--------------------------------------------------------
		local function EGP_Use( um )
			local ent = um:ReadEntity()
			local bool = um:ReadChar()
			if (bool == -1) then
				ent.On = nil
			elseif (bool == 1) then
				ent.On = true
			elseif (bool == 0) then
				if (ent.On == true) then
					ent.On = nil
					LocalPlayer():ChatPrint("[EGP] EGP HUD Disconnected.")
				else
					ent.On = true
					if (EGP_HUD_FirstPrint) then
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected. NOTE: Type 'wire_egp_hud_unlink' in console to disconnect yourself from all EGP HUDs.")
						EGP_HUD_FirstPrint = nil
					else
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected.")
					end
				end
			end
		end
		usermessage.Hook( "EGP_HUD_Use", EGP_Use )

		--------------------------------------------------------
		-- Disconnect all HUDs
		--------------------------------------------------------
		concommand.Add("wire_egp_hud_unlink",function()
			local en = ents.FindByClass("gmod_wire_egp_hud")
			LocalPlayer():ChatPrint("[EGP] Disconnected from all EGP HUDs.")
			for k,v in ipairs( en ) do
				en.On = nil
			end
		end)

		--------------------------------------------------------
		-- Add / Remove HUD Entities
		--------------------------------------------------------
		function EGP:AddHUDEGP( Ent )
			table.insert( tbl, Ent )
		end

		function EGP:RemoveHUDEGP( Ent )
			for k,v in ipairs( tbl ) do
				if (v == Ent) then
					table.remove( tbl, k )
					return
				end
			end
		end

		--------------------------------------------------------
		-- Paint
		--------------------------------------------------------
		hook.Add("HUDPaint","EGP_HUDPaint",function()
			for k,v in ipairs( tbl ) do
				if (!v or !v:IsValid()) then
					table.remove( tbl, k )
					break
				else
					if (v.On == true) then
						if (v.RenderTable and #v.RenderTable > 0) then
							for k2,v2 in ipairs( v.RenderTable ) do
								local oldtex = EGP:SetMaterial( v2.material )
								v2:Draw()
								EGP:FixMaterial( oldtex )
							end
						end
					end
				end
			end
		end)
	else
		local vehiclelinks = {}

		function EGP:LinkHUDToVehicle( hud, vehicle )
			vehiclelinks[hud] = vehicle
		end

		function EGP:UnlinkHUDFromVehicle( hud )
			if (vehiclelinks[hud]) then
				local vehicle = vehiclelinks[hud]
				if (vehicle and vehicle:IsValid()) then
					if (vehicle:GetDriver() and vehicle:GetDriver():IsValid()) then
						umsg.Start( "EGP_HUD_Use", vehicle:GetDriver() )
							umsg.Entity( hud )
							umsg.Char( -1 )
						umsg.End()
					end
				end
				vehiclelinks[hud] = nil
			end
		end

		hook.Add("PlayerEnteredVehicle","EGP_HUD_PlayerEnteredVehicle",function( ply, vehicle )
			for k,v in pairs( vehiclelinks ) do
				if (v == vehicle) then
					umsg.Start( "EGP_HUD_Use", ply )
						umsg.Entity( k )
						umsg.Char( 1 )
					umsg.End()
					return
				end
			end
		end)

		hook.Add("PlayerLeaveVehicle","EGP_HUD_PlayerLeaveVehicle",function( ply, vehicle )
			for k,v in pairs( vehiclelinks ) do
				if (v == vehicle) then
					umsg.Start( "EGP_HUD_Use", ply )
						umsg.Entity( k )
						umsg.Char( -1 )
					umsg.End()
					return
				end
			end
		end)
	end
end)
