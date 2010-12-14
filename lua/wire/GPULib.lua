if CLIENT then

	local RT_CACHE_SIZE = 32

	//
	// Create rendertarget cache
	//
	if not RenderTargetCache then
		RenderTargetCache = { Used = {}, Free = {} }
		for i = 1,RT_CACHE_SIZE do
			local Target = GetRenderTarget("WireGPU_RT_"..i, 512, 512)
			if not Target then break end
			RenderTargetCache.Free[Target] = i
		end
	end

	//
	// Create basic fonts
	//
	surface.CreateFont("lucida console", 20, 800, true, false, "WireGPU_ConsoleFont")

	//
	// Create screen textures and materials
	//
	WireGPU_matScreen = CreateMaterial("GPURT","UnlitGeneric",{})

	function PrintWBI(text)
		local fontnames = {
			"Trebuchet24",
			"Trebuchet22",
			"Trebuchet20",
			"Trebuchet19",
			"Trebuchet18",
		}

		hook.Add("HUDPaint", "wiremod_installed_improperly_popup", function()
			local fontname,w,h

			-- Find a font that fits the screen
			local fontindex = 0
			repeat
				fontindex = fontindex + 1
				fontname = fontnames[fontindex]
				surface.SetFont(fontname)
				w,h = surface.GetTextSize(text)
			until w+20 < ScrW() or fontindex == #fontnames

			-- draw the text centered on the screen
			local x,y = ScrW()/2-w/2, ScrH()/2-h/2

			-- on a grey box with black borders
			draw.RoundedBox(1, x-11, y-7, w+22, h+14, Color(0,0,0,192) )
			draw.RoundedBox(1, x-9, y-5, w+18, h+10, Color(128,128,128,255) )

			-- draw the text
			draw.DrawText(text, fontname, x, y, Color(255,255,255,255), TEXT_ALIGN_LEFT)
		end)

		print(text)
	end -- function PrintWBI
end

--------------------------------------------------------------------------------
-- WireGPU class
--------------------------------------------------------------------------------
--   Usage:
--     Initialize:
--       self.GPU = WireGPU(self.Entity)
--
--     OnRemove:
--       self.GPU:Finalize()
--
--     Draw (if something changes):
--       self.GPU:RenderToGPU(function()
--           ...code...
--       end)
--
--     Draw (every frame):
--       self.GPU:Render()
--------------------------------------------------------------------------------

GPULib = {}

local GPU = {}
GPU.__index = GPU
GPULib.GPU = GPU

function GPULib.WireGPU(ent, ...)
	local self = {
		entindex = ent and ent:EntIndex() or 0,
		Entity = ent or NULL,
	}
	setmetatable(self, GPU)
	self:Initialize(...)
	return self
end
WireGPU = GPULib.WireGPU

function GPU:GetInfo()
	local ent = self.Entity
	if not ent:IsValid() then ent = self.actualEntity end
	if not ent then return end

	local model = ent:GetModel()
	local monitor = WireGPU_Monitors[model]

	local pos = ent:LocalToWorld(monitor.offset)
	local ang = ent:LocalToWorldAngles(monitor.rot)

	return monitor, pos, ang
end

if CLIENT then

	function GPU:Initialize(no_rendertarget)
		if no_rendertarget then return nil end
		-- Rendertarget cache management

		-- find a free one
		self.RT = next(RenderTargetCache.Free)

		-- no free RT? bail out
		if not self.RT then
			if not MissingRenderTargetMessageDisplayed and not next(RenderTargetCache.Used) then
				PrintWBI([[
					In order for rendertargets to work, you need to restart Garry's Mod.

					You might need to unblock .txt file download if restarting didn't help.
					If that also fails, go to wiremod.com and download+install wiremod.

					To get rid of this message, write 'lua_run_cl hook.Remove("HUDPaint", "wiremod_installed_improperly_popup")' into your console.
				]])
				MissingRenderTargetMessageDisplayed = true
			end
			return nil
		end

		-- mark RT as used
		RenderTargetCache.Used[self.RT] = RenderTargetCache.Free[self.RT]
		RenderTargetCache.Free[self.RT] = nil

		-- clear the new RT
		self:Clear()
		return self.RT
	end

	function GPU:Finalize()
		if not self.RT then return end
		RenderTargetCache.Free[self.RT] = RenderTargetCache.Used[self.RT]
		RenderTargetCache.Used[self.RT] = nil
		self.RT = nil
	end

	function GPU:Clear(color)
		if not self.RT then return end
		render.ClearRenderTarget(self.RT, color or Color(0, 0, 0))
	end

	local texcoords = {
		[0] = {
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
		},
		{
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
		},
		{
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
			{ u = 1, v = 0 },
		},
		{
			{ u = 1, v = 0 },
			{ u = 1, v = 1 },
			{ u = 0, v = 1 },
			{ u = 0, v = 0 },
		},
	}
	-- helper function for GPU:Render
	function GPU.DrawScreen(x, y, w, h, rotation, scale)
		-- generate vertex data
		local vertices = {
			--[[
			Vector(x  , y  ),
			Vector(x+w, y  ),
			Vector(x+w, y+h),
			Vector(x  , y+h),
			]]
			{ x = x  , y = y   },
			{ x = x+w, y = y   },
			{ x = x+w, y = y+h },
			{ x = x  , y = y+h },
		}

		-- rotation and scaling
		local rotated_texcoords = texcoords[rotation] or texcoords[0]
		for index,vertex in ipairs(vertices) do
			local tex = rotated_texcoords[index]
			if tex.u == 0 then
				vertex.u = tex.u-scale
			else
				vertex.u = tex.u+scale
			end
			if tex.v == 0 then
				vertex.v = tex.v-scale
			else
				vertex.v = tex.v+scale
			end
		end

		surface.DrawPoly(vertices)
		--render.DrawQuad(unpack(vertices))
	end

	function GPU:RenderToGPU(renderfunction)
		if not self.RT then return end
		local oldw = ScrW()
		local oldh = ScrH()

		local NewRT = self.RT
		local OldRT = render.GetRenderTarget()

		render.SetRenderTarget(NewRT)
		render.SetViewPort(0, 0, 512, 512)
		cam.Start2D()
			PCallError(renderfunction)
		cam.End2D()
		render.SetViewPort(0, 0, oldw, oldh)
		render.SetRenderTarget(OldRT)
	end

	-- If width is specified, height is ignored. if neither is specified, a height of 512 is used.
	function GPU:RenderToWorld(width, height, renderfunction, zoffset)
		local monitor, pos, ang = self:GetInfo()

		if zoffset then
			pos = pos + ang:Up()*zoffset
		end

		local h = width and width*monitor.RatioX or height or 512
		local w = width or h/monitor.RatioX
		local x = -w/2
		local y = -h/2

		local res = monitor.RS*512/h
		cam.Start3D2D(pos, ang, res)
			PCallError(renderfunction, x, y, w, h, monitor, pos, ang, res)
		cam.End3D2D()
	end

	function GPU:Render(rotation, scale, width, height, postrenderfunction)
		if not self.RT then return end

		local monitor, pos, ang = self:GetInfo()

		local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
		WireGPU_matScreen:SetMaterialTexture("$basetexture", self.RT)

		local res = monitor.RS
		cam.Start3D2D(pos, ang, res)
			PCallError(function()
				local aspect = 1/monitor.RatioX
				local w = (width  or 512)*aspect
				local h = (height or 512)
				local x = -w/2
				local y = -h/2

				surface.SetDrawColor(0,0,0,255)
				surface.DrawRect(-256*aspect,-256,512*aspect,512)

				surface.SetMaterial(WireGPU_matScreen)
				self.DrawScreen(x, y, w, h, rotation or 0, scale or 0)

				if postrenderfunction then postrenderfunction(pos, ang, res, aspect) end
			end)
		cam.End3D2D()

		WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex)
	end

	-- compatibility

	local GPUs = {}

	function WireGPU_NeedRenderTarget(entindex)
		if not GPUs[entindex] then GPUs[entindex] = GPULib.WireGPU(Entity(entindex)) end
		return GPUs[entindex].RT
	end

	function WireGPU_GetMyRenderTarget(entindex)
		local self = GPUs[entindex]
		if self.RT then return self.RT end

		return self:Initialize()
	end

	function WireGPU_ReturnRenderTarget(entindex)
		return GPUs[entindex]:Finalize()
	end

	function WireGPU_DrawScreen(x, y, w, h, rotation, scale)
		return GPU.DrawScreen(x, y, w, h, rotation, scale)
	end

end

-- GPULib switcher functionality
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
	end) -- usermessage.Hook

elseif SERVER then

	function GPULib.switchscreen(screen, ent)
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
			GPULib.switchscreen(screen, ent)
		end)
	end)

end
