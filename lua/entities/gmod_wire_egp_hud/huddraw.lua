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
					if (!tbl[ent]) then -- strange... this entity should be in the table. Might have gotten removed due to a lagspike. Add it again
						EGP:AddHUDEGP( ent )
					end
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
			tbl[Ent] = true
		end

		function EGP:RemoveHUDEGP( Ent )
			tbl[Ent] = nil
		end

		--------------------------------------------------------
		-- Paint
		--------------------------------------------------------
		hook.Add("HUDPaint","EGP_HUDPaint",function()
			for v,_ in pairs( tbl ) do
				if (!v or !v:IsValid()) then
					EGP:RemoveHUDEGP( v )
					break
				else
					if (v.On == true) then
						v.HasUpdatedThisFrame = nil
						if (v.RenderTable and #v.RenderTable > 0) then
							for k2,v2 in pairs( v.RenderTable ) do
								local oldtex = EGP:SetMaterial( v2.material )
								v2:Draw()
								EGP:FixMaterial( oldtex )

								-- Check for 3DTracker parent
								if (!v.HasUpdatedThisFrame and v2.parent) then
									local bool, k3, v3 = EGP:HasObject( v, v2.parent )
									if (bool and v3.Is3DTracker) then
										v:EGP_Update()
										v.HasUpdatedThisFrame = true
									end
								end
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
			hud.LinkedVehicle = vehicle
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
				hud.LinkedVehicle = nil
			end
		end

		hook.Add("PlayerEnteredVehicle","EGP_HUD_PlayerEnteredVehicle",function( ply, vehicle )
			for k,v in pairs( vehiclelinks ) do
				if (v == vehicle) then
					umsg.Start( "EGP_HUD_Use", ply )
						umsg.Entity( k )
						umsg.Char( 1 )
					umsg.End()
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
				end
			end
		end)
	end
end)
