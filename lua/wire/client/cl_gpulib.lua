local RT_CACHE_SIZE = 32

//
// Create rendertarget cache
//
if not RenderTargetCache then
	RenderTargetCache = { Used = {}, Free = {} }
	for i = 1,RT_CACHE_SIZE do
		local Target = GetRenderTarget("WireGPU_RT_"..i, 512, 512)
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
WireGPU_matScreen = Material("ignore_this_error")
WireGPU_texScreen = surface.GetTextureID("ignore_this_error")

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

local GPU = {}
GPU.__index = GPU

function WireGPU(ent, ...)
	local self = {
		entindex = ent and ent:EntIndex() or 0,
		Entity = ent or NULL,
	}
	setmetatable(self, GPU)
	self:Initialize(...)
	return self
end

function GPU:Initialize(no_rendertarget)
	if no_rendertarget then return nil end
	-- Rendertarget cache management

	-- find a free one
	self.RT = next(RenderTargetCache.Free)

	-- no free RT? bail out
	if not self.RT then return nil end

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

function GPU:GetInfo()
	local ent = self.Entity
	if not ent:IsValid() then ent = self.actualEntity end
	if not ent then return end

	local model = ent:GetModel()
	local monitor = WireGPU_Monitors[model]

	local ang = ent:LocalToWorldAngles(monitor.rot)
	local pos = ent:LocalToWorld(monitor.offset)

	return monitor, pos, ang
end

-- If width is specified, height is ignored. if neither is specified, a height of 512 is used.
function GPU:RenderToWorld(width, height, renderfunction)
	local monitor, pos, ang = self:GetInfo()

	local h = width and width*monitor.RatioX or height or 512
	local w = h/monitor.RatioX
	local x = -w/2
	local y = -h/2
	cam.Start3D2D(pos, ang, monitor.RS*512/h)
		PCallError(renderfunction, x, y, w, h, monitor, pos, ang)
	cam.End3D2D()
end

function GPU:Render(rotation, scale, width, height, postrenderfunction)
	if not self.RT then return end

	local monitor, pos, ang = self:GetInfo()

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture", self.RT)

	cam.Start3D2D(pos, ang, monitor.RS)
		PCallError(function()
			local aspect = 1/monitor.RatioX
			local w = (width  or 512)*aspect
			local h = (height or 512)
			local x = -w/2
			local y = -h/2

			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(-256*aspect,-256,512*aspect,512)

			surface.SetTexture(WireGPU_texScreen)
			self.DrawScreen(x, y, w, h, rotation or 0, scale or 0)

			if postrenderfunction then postrenderfunction(pos, ang, monitor.RS, aspect) end
		end)
	cam.End3D2D()

	WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex)
end

-- compatibility

local GPUs = {}

function WireGPU_NeedRenderTarget(entindex)
	if not GPUs[entindex] then GPUs[entindex] = WireGPU(Entity(entindex)) end
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
