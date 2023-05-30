hook.Add("Initialize","EGP_HUD_Initialize",function()
	if CLIENT then
		local EGP_HUD_FirstPrint = true
		local tbl = {}

		

		--------------------------------------------------------
		-- Toggle
		--------------------------------------------------------
		local function EGP_Use()
			local ent = net.ReadEntity()
			if not ent or not ent:IsValid() then return end
			local bool = net.ReadInt(2) or 0
			if bool == -1 then
				ent.On = nil
				-- Clear the screen so there isn't a ghost frame next time it's enabled
				ent.RenderTable = {}
				ent.RenderTable_Indices = {}
				ent:EGP_Update()
				tbl[Ent] = nil
			elseif bool == 1 then
				ent.EGPHudOn = true
				if not tbl[ent] then EGP:AddHUDEGP(ent) end
			elseif bool == 0 then
				if ent.EGPHudOn == true then
					ent.EGPHudOn = nil
					ent.RenderTable = {}
					ent.RenderTable_Indices = {}
					ent:EGP_Update()
					LocalPlayer():ChatPrint("[EGP] EGP HUD Disconnected.")
					tbl[Ent] = nil
				else
					if not tbl[ent] then -- Why is this table even like this in the first place
						tbl[Ent] = true
					end
					ent.EGPHudOn = true
					if EGP_HUD_FirstPrint then
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected. NOTE: Type 'wire_egp_hud_unlink' in console to disconnect yourself from all EGP HUDs.")
						EGP_HUD_FirstPrint = nil
					else
						LocalPlayer():ChatPrint("[EGP] EGP HUD Connected.")
					end
				end
			end
			
			net.Start("EGP_HUD_Use")
			net.WriteEntity(ent)
			net.WriteBool(ent.EGPHudOn or false)
			net.SendToServer()
		end
		net.Receive( "EGP_HUD_Use", EGP_Use )

		--------------------------------------------------------
		-- Disconnect all HUDs
		--------------------------------------------------------
		concommand.Add("wire_egp_hud_unlink",function()
			local en = ents.FindByClass("gmod_wire_egp_hud")
			LocalPlayer():ChatPrint("[EGP] Disconnected from all EGP HUDs.")
			for _, v in ipairs(en) do
				v.On = nil
			end
		end)

		--------------------------------------------------------
		-- Add / Remove HUD Entities
		--------------------------------------------------------
		function EGP:AddHUDEGP(Ent)
			tbl[Ent] = true
		end

		function EGP:RemoveHUDEGP(Ent)
			tbl[Ent] = nil
		end

		--------------------------------------------------------
		-- Paint
		--------------------------------------------------------
		hook.Add("HUDPaint","EGP_HUDPaint",function()
			for Ent, _ in pairs(tbl) do
				if not Ent or not Ent:IsValid() then
					tbl[Ent] = nil
					break
				else
					if Ent.EGPHudOn == true then
						if Ent.RenderTable and #Ent.RenderTable > 0 then
							local mat = Ent:GetEGPMatrix()

							for _, object in pairs(Ent.RenderTable) do
								local oldtex = EGP:SetMaterial(object.material)
								-- Why was this excluded from here? Fixes parenting breaking when not looking at EGP
								if object.parent and object.parent ~= 0 then
									if not object.IsParented then EGP:SetParent(Ent, object.index, object.parent) end
									local _, data = EGP:GetGlobalPos(Ent, object.index)
									EGP:EditObject(object, data)
								elseif not object.parent or object.parent == 0 and object.IsParented then
									EGP:UnParent(Ent, object.index)
								end
								object:Draw(Ent, mat)
								EGP:FixMaterial(oldtex)

								-- Check for 3DTracker parent
								if object.parent then
									local hasObject, _, parent = EGP:HasObject(Ent, object.parent)
									if hasObject and parent.NeedsConstantUpdate then
										Ent:EGP_Update()
									end
								end
							end
						end
					end
				end
			end
		end) -- HUDPaint hook
	else -- SERVER
		local vehiclelinks = {}
		
		local function EGP_Use_Server(len, ply)
			local ent = net.ReadEntity()
			local state = net.ReadBool()
			if not IsValid(ent) then return end
			
			if not ent.Users then ent.Users = {} end
			
			local id = ply:AccountID()
			
			if ent.Users[id] and not state then
				ent.Users[id] = nil
				-- Do not insert a DoAction for ClearScreen here. That would be a mistake
			elseif state then
				ent.Users[id] = ply
				-- Fast-forward the player's RenderTable by creating every object that's on the server's
				for _, v in pairs(ent.RenderTable) do
					EGP:DoAction(ent, { player = ply }, "SendObject", v)
				end
			end
			
			if table.IsEmpty(ent.Users) and not ent.IsEGPHUD then
				ent.Users = nil
			end
			
		end
		net.Receive( "EGP_HUD_Use", EGP_Use_Server )

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
								net.Start("EGP_HUD_Use")
									net.WriteEntity(hud)
									net.WriteInt(-1, 2)
								net.Send(vehicle:GetDriver())
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
					net.Start("EGP_HUD_Use")
						net.WriteEntity(k)
						net.WriteInt(1, 2)
					net.Send(ply)
				end
			end
		end)

		hook.Add("PlayerLeaveVehicle","EGP_HUD_PlayerLeaveVehicle",function(ply, vehicle)
			for k, v in pairs( vehiclelinks ) do
				if v[vehicle] ~= nil then
					net.Start( "EGP_HUD_Use")
						net.WriteEntity(k)
						net.WriteInt(-1, 2)
					net.Send(ply)
				end
			end
		end)
	end
end)
