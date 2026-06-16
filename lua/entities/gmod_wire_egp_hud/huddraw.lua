
if CLIENT then
	local EGP_HUD_FirstPrint = true
	local tbl = {}

	local cvarHudPrint = CreateClientConVar("wire_egp_hud_print", "1", true, false, "Controls whether you are notified when you connect to an EGP HUD")

	--------------------------------------------------------
	-- Paint
	--------------------------------------------------------
	local makeArray = EGP.ParentingFuncs.makeArray
	local makeTable = EGP.ParentingFuncs.makeTable

	local function scaleObject(bool, v)
		local xMin, xMax, yMin, yMax, _xMul, _yMul
		if (bool) then -- 512 -> screen
			xMin = 0
			xMax = 512
			yMin = 0
			yMax = 512
			_xMul = ScrW()
			_yMul = ScrH()
		else -- screen -> 512
			xMin = 0
			xMax = ScrW()
			yMin = 0
			yMax = ScrH()
			_xMul = 512
			_yMul = 512
		end

		local xMul = _xMul/(xMax-xMin)
		local yMul = _yMul/(yMax-yMin)

		if v.verticesindex then
			local r = makeArray(v, true)
			for i=1,#r,2 do
				r[i] = (r[i] - xMin) * xMul
				r[i+1] = (r[i+1]- yMin) * yMul
			end
			local settings = {}
			if isstring(v.verticesindex) then settings = { [v.verticesindex] = makeTable( v, r ) } else v.vertices = makeTable(v, r) end
			v:EditObject(settings)
		else
			if v.x then
				v.x = (v.x - xMin) * xMul
			end
			if v.y then
				v.y = (v.y - yMin) * yMul
			end
			if v.w then
				v.w = v.w * xMul
			end
			if v.h then
				v.h = v.h * yMul
			end
		end
		v.res = bool
	end

	local egpDraw = EGP.Draw

	local function hudPaint()
		for ent in pairs(tbl) do
			if not ent or not ent:IsValid() then
				tbl[ent] = nil
			else
				if ent.RenderTable then
					if ent.gmod_wire_egp_hud then
						local resolution = ent:GetResolution(false)
						local rt = ent.RenderTable

						for _, v in ipairs(rt) do
							if (v.res or false) ~= resolution then
								scaleObject(not v.res, v)
							end
						end

						egpDraw(ent)
					else
						if not ent.NeedsUpdate then
							local mat = ent:GetEGPMatrix()
							for _, obj in ipairs(ent.RenderTable) do
								local oldtex = EGP:SetMaterial(obj.material)
								obj:Draw(ent, mat)
								EGP:FixMaterial(oldtex)
							end
						else
							egpDraw(ent)
						end
					end
				end
			end
		end
	end


	--------------------------------------------------------
	-- Toggle
	--------------------------------------------------------
	local function EGP_Use()
		local ent = net.ReadEntity()
		if not ent or not ent:IsValid() then return end

		if net.ReadBool() then -- Enable
			tbl[ent] = true

			if ent.gmod_wire_egp_hud then ent:EGP_Update() end
			hook.Add("HUDPaint", "EGP_HUDPaint", hudPaint)
		else
			tbl[ent] = nil

			if next(tbl) == nil then
				hook.Remove("HUDPaint","EGP_HUDPaint")
			end
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
		hook.Remove("HUDPaint","EGP_HUDPaint")
		net.Start("EGP_HUD_Unlink")
		net.SendToServer()
	end)
else -- SERVER
	local vehiclelinks = {}

	local function EGPHudConnect(ent, state, ply)
		if state then
			if not ent.Users then ent.Users = {} end

			if not ent.Users[ply] then
				ent.Users[ply] = true
			end

			EGP:SendDataStream(ply, ent:EntIndex(), true)
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

	util.AddNetworkString("EGP_HUD_Unlink")

	net.Receive("EGP_HUD_Unlink", function(_, ply)
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
