TOOL.Category   = "Wire - Display"
TOOL.Name       = "GPULib Switcher"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

if (CLIENT) then
	language.Add("Tool_wire_gpulib_switcher_name", "GPULib Screen Switcher")
	language.Add("Tool_wire_gpulib_switcher_desc", "Spawns a graphics processing unit")
	language.Add("Tool_wire_gpulib_switcher_0", "Primary: Link a GPULib Screen (Console/Digital/Text Screen/GPU/Oscilloscope) to a different prop/entity, Reload: Unlink")
	language.Add("Tool_wire_gpulib_switcher_1", "Now click a prop or other entity to link to. Press Reload to cancel.")
end

if CLIENT then

	usermessage.Hook("wire_gpulib_setent", function(um)
		local screen = Entity(um:ReadShort())
		if not screen:IsValid() then return end
		if not screen.GPU then return end

		local ent = Entity(um:ReadShort())
		if not ent:IsValid() then return end

		screen.GPU.Entity = ent
		screen.GPU.entindex = ent:EntIndex()

		if screen == ent then return end

		screen.GPU.actualEntity = screen

		local model = ent:GetModel()
		local monitor = WireGPU_Monitors[model]

		local h = 512*monitor.RS
		local w = h/monitor.RatioX
		local x = -w/2
		local y = -h/2

		local corners = {
			{ x  , y   },
			{ x  , y+h },
			{ x+w, y   },
			{ x+w, y+h },
		}

		local mins, maxs = screen:OBBMins(), screen:OBBMaxs()

		local function setbounds(timerid)
			if not screen:IsValid() then
				timer.Remove(timerid)
				return
			end
			if not ent:IsValid() then
				timer.Remove(timerid)

				screen.ExtraRBoxPoints[1001] = nil
				screen.ExtraRBoxPoints[1002] = nil
				screen.ExtraRBoxPoints[1003] = nil
				screen.ExtraRBoxPoints[1004] = nil
				Wire_UpdateRenderBounds(screen)

				screen.GPU.Entity = screen.GPU.actualEntity
				screen.GPU.entindex = screen.GPU.actualEntity:EntIndex()
				screen.GPU.actualEntity = nil

				return
			end

			local ang = ent:LocalToWorldAngles(monitor.rot)
			local pos = ent:LocalToWorld(monitor.offset)

			screen.ExtraRBoxPoints = screen.ExtraRBoxPoints or {}
			for i,x,y in ipairs_map(corners, unpack) do
				local p = Vector(x, y, 0)
				p:Rotate(ang)
				p = screen:WorldToLocal(p+pos)

				screen.ExtraRBoxPoints[i+1000] = p
			end

			Wire_UpdateRenderBounds(screen)
		end

		local timerid = "wire_gpulib_updatebounds"..screen:EntIndex()
		timer.Create(timerid, 5, 0, setbounds, timerid)

		setbounds()
	end) -- umsg hook

	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool_wire_gpulib_switcher_name", Description = "#Tool_wire_gpulib_switcher_desc" })
	end

elseif SERVER then

	local function switchscreen(screen, ent)
		screen.GPUEntity = ent
		umsg.Start("wire_gpulib_setent")
			umsg.Short(screen:EntIndex())
			umsg.Short(ent:EntIndex())
		umsg.End()

		duplicator.StoreEntityModifier(screen, "wire_gpulib_switcher", { screen:EntIndex(), ent:EntIndex() })
	end

	duplicator.RegisterEntityModifier("wire_gpulib_switcher", function(ply, screen, data)
		local screenid, entid = unpack(data)
		if entid == screenid then return end -- no need to switch the screen

		WireLib.PostDupe(entid, function(ent)
			switchscreen(screen, ent)
		end)
	end)

	function TOOL:LeftClick(trace)
		local ent = trace.Entity

		if ent:IsPlayer() then return false end
		if CLIENT then return true end

		if not ent:IsValid() then return false end

		if self:GetStage() == 0 then
			--if not ent.IsGPU then return false end -- needs check for GPULib-ness
			self.screen = ent

			self:SetStage(1)

			return true
		elseif self:GetStage() == 1 then
			switchscreen(self.screen, ent)
			self.screen = nil

			self:SetStage(0)

			return true
		end
	end

	function TOOL:Reload(trace)
		if self:GetStage() == 0 then
			local ent = trace.Entity

			if ent:IsPlayer() then return false end
			if CLIENT then return true end

			switchscreen(ent, ent)

			return true
		else
			self:SetStage(0)
			return true
		end
	end

end -- if SERVER
