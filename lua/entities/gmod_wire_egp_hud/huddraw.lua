hook.Add("Initialize","EGP_HUD_Initialize",function()
	if CLIENT then
		local EGP_HUD_FirstPrint = true
		local tbl = {}

		local cvarHudPrint = CreateClientConVar("wire_egp_hud_print", "1", true, false, "Controls whether you are notified when you connect to an EGP HUD")


		--------------------------------------------------------
		-- Toggle
		--------------------------------------------------------
		local function EGP_Use()
			local ent = net.ReadEntity()
			if not ent or not ent:IsValid() then return end

			if net.ReadBool() then -- Enable
				tbl[ent] = true
			else
				tbl[ent] = nil
			end

			if cvarHudPrint:GetBool() then -- Print
				if tbl[ent] then
					if EGP_HUD_FirstPrint then
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected. NOTE: Type 'wire_egp_hud_unlink' in console to disconnect yourself from all EGP HUDs.")
						EGP_HUD_FirstPrint = nil
					else
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected.")
					end
				else
					LocalPlayer():ChatPrint("[EGP] EGP HUD Disconnected.")
				end
			end
		end
		net.Receive("EGP_HUD_Use", EGP_Use)

		--------------------------------------------------------
		-- Disconnect all HUDs
		--------------------------------------------------------
		concommand.Add("wire_egp_hud_unlink",function()
			LocalPlayer():ChatPrint("[EGP] Disconnected from all EGP HUDs.")
			tbl = {}
			net.Start("EGP_HUD_Unlink")
			net.SendToServer()
		end)

		--------------------------------------------------------
		-- Paint
		--------------------------------------------------------
		hook.Add("HUDPaint","EGP_HUDPaint",function()
			for Ent, _ in pairs(tbl) do
				if not Ent or not Ent:IsValid() then
					tbl[Ent] = nil
					break
				else
					if Ent.RenderTable and #Ent.RenderTable > 0 then
						local mat = Ent:GetEGPMatrix()

						for _, object in ipairs(Ent.RenderTable) do
							-- Fixes parenting breaking when not looking at EGP
							if object.parent ~= 0 then
								if not object.IsParented then EGP:SetParent(Ent, object.index, object.parent) end
								local _, data = EGP:GetGlobalPos(Ent, object.index)
								EGP:EditObject(object, data)
							elseif object.IsParented then
								EGP:UnParent(Ent, object)
							end

							local oldtex = EGP:SetMaterial(object.material)
							object:Draw(Ent, mat)
							EGP:FixMaterial(oldtex)

							-- Check for 3DTracker or cursor parent
							if object.NeedsConstantUpdate or object.parent == -1 then Ent:EGP_Update() end
						end
					end
				end
			end
		end) -- HUDPaint hook
	else -- SERVER
		local vehiclelinks = {}

		local function EGPHudConnect(ent, state, ply)
			if state then
				if not ent.Users then ent.Users = {} end

				if not ent.Users[ply] then
					ent.Users[ply] = true
				end
			elseif ent.Users and ent.Users[ply] then
				ent.Users[ply] = nil

				if table.IsEmpty(ent.Users) and not ent.IsEGPHUD then
					ent.Users = nil
				end
			else -- Nothing changed
				return
			end

			E2Lib.triggerEvent("egpHudConnect", { ent, ply, state and 1 or 0 })

			net.Start("EGP_HUD_Use") net.WriteEntity(ent) net.WriteBool(state) net.Send(ply)

		end
		EGP.EGPHudConnect = EGPHudConnect

		local function unlinkUser(ply)
			local egps = ents.FindByClass("gmod_wire_egp*")
			for _, egp in pairs(egps) do
				if egp.Users and egp.Users[ply] then
					egp.Users[ply] = nil
					E2Lib.triggerEvent("egpHudConnect", { egp, ply, 0 })
				end
			end
		end

		net.Receive("EGP_HUD_Unlink", function(len, ply)
			unlinkUser(ply)
		end)

		function EGP:LinkHUDToVehicle(hud, vehicle)
			if not hud.LinkedVehicles then hud.LinkedVehicles = {} end
			if not hud.Marks then hud.Marks = {} end

			hud.Marks[#hud.Marks + 1] = vehicle
			hud.LinkedVehicles[vehicle] = true
			vehiclelinks[hud] = hud.LinkedVehicles

			vehicle:CallOnRemove("EGP HUD unlink on remove", function(ent)
				EGP:UnlinkHUDFromVehicle(hud, ent)
			end)

			timer.Simple(0.1, function() -- timers solve everything (this time, it's the fact that the entity isn't valid on the client after dupe)
				WireLib.SendMarks(hud)
			end)
		end

		function EGP:UnlinkHUDFromVehicle(hud, vehicle)
			if not vehicle then -- unlink all
				if hud.Marks then
					for i = 1, #hud.Marks do
						if hud.Marks[i]:IsValid() then
							hud.Marks[i]:RemoveCallOnRemove("EGP HUD unlink on remove")
						end
					end
				end
				vehiclelinks[hud] = nil
				hud.LinkedVehicles = nil
				hud.Marks = nil
			else
				if vehiclelinks[hud] then
					local bool = vehiclelinks[hud][vehicle]
					if bool then
						if vehicle:IsValid() then
							vehicle:RemoveCallOnRemove("EGP HUD unlink on remove")
							if vehicle:GetDriver() and vehicle:GetDriver():IsValid() then
								EGPHudConnect(hud, false, vehicle:GetDriver())
							end
						end
					end

					if hud.Marks then
						for i = 1, #hud.Marks do
							if hud.Marks[i] == vehicle then
								table.remove(hud.Marks, i)
								break
							end
						end
					end

					hud.LinkedVehicles[vehicle] = nil
					if not next(hud.LinkedVehicles) then
						hud.LinkedVehicles = nil
						hud.Marks = nil
					end

					vehiclelinks[hud] = hud.LinkedVehicles
				end
			end

			WireLib.SendMarks(hud)
		end

		hook.Add("PlayerEnteredVehicle","EGP_HUD_PlayerEnteredVehicle",function(ply, vehicle)
			for k, v in pairs( vehiclelinks ) do
				if v[vehicle] ~= nil then
					EGPHudConnect(k, true, ply)
				end
			end
		end)

		hook.Add("PlayerLeaveVehicle","EGP_HUD_PlayerLeaveVehicle",function(ply, vehicle)
			for k, v in pairs( vehiclelinks ) do
				if v[vehicle] ~= nil then
					EGPHudConnect(k, false, ply)
				end
			end
		end)

		hook.Add("PlayerDisconnected", "EGP_HUD_PlayerDisconnected", function(ply)
			unlinkUser(ply)
		end)
	end
end)
