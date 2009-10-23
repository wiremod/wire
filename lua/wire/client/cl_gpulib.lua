local RT_CACHE_SIZE = 16

//
// Create rendertarget cache
//
if not RenderTargetCache then
	RenderTargetCache = {}
	for i = 1,RT_CACHE_SIZE do
		RenderTargetCache[i] = {
			Target = GetRenderTarget("WireGPU_RT_"..i, 512, 512),
			Used = false
		}
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

local GPU = {}
GPU.__index = GPU

function WireGPU(ent)
	local self = {
		entindex = ent:EntIndex(),
		Entity = ent
	}
	setmetatable(self, GPU)
	self:Initialize()
	return self
end

function GPU:Initialize()
	//
	// Rendertarget cache management
	//
	for i = 1,#RenderTargetCache do
		if not RenderTargetCache[i].Used then
			RenderTargetCache[i].Used = true
			self.RTindex = i
			self.RT = RenderTargetCache[i].Target
			return RenderTargetCache[i].Target
		end
	end

	//Need to create new. PANIC?!
	//print("RENDER TARGET PANIC. RENDER TARGET PANIC!")
	return RenderTargetCache[1].Target
end

function GPU:Finalize()
	RenderTargetCache[self.RTindex].Used = false
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
	//Generate vertex data
	local vertices = {
		{ x = x  , y = y   },
		{ x = x+w, y = y   },
		{ x = x+w, y = y+h },
		{ x = x  , y = y+h },
	}

	//Rotation
	local rotated_texcoords = texcoords[rotation]
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
end

function GPU:RenderToGPU(renderfunction)
	local oldw = ScrW()
	local oldh = ScrH()

	local NewRT = self.RT
	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(NewRT)
	render.SetViewPort(0,0,512,512)
	cam.Start2D()
		PCallError(renderfunction)
	cam.End2D()
	render.SetViewPort(0,0,oldw,oldh)
	render.SetRenderTarget(OldRT)
end

function GPU:Render()
	local model = self.Entity:GetModel()
	local OF, OU, OR, Res, RatioX, Rot90
	local monitor = WireGPU_Monitors[model]
	OF = WireGPU_Monitors[model].OF
	OU = WireGPU_Monitors[model].OU
	OR = WireGPU_Monitors[model].OR
	Res = WireGPU_Monitors[model].RS
	RatioX = WireGPU_Monitors[model].RatioX
	Rot90 = WireGPU_Monitors[model].rot90

	local rot = Angle(0, 90, 90)
	if Rot90 then
		rot = Angle(0, 90, 0)
	end

	local ang = self.Entity:LocalToWorldAngles(rot)

	local pos = self.Entity:GetPos()+(self.Entity:GetForward()*OF)+(self.Entity:GetUp()*OU)+(self.Entity:GetRight()*OR)

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture", self.RT)

	cam.Start3D2D(pos,ang,Res)
		local w = 512
		local h = 512
		local x = w*-0.5
		local y = h*-0.5

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture(WireGPU_texScreen)
		self.DrawScreen(x, y, w/RatioX, h, 0, 0)
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
	if self.RTindex then return RenderTargetCache[self.RTindex].Target end

	return self:NeedRenderTarget()
end

function WireGPU_ReturnRenderTarget(entindex)
	return GPUs[entindex]:Finalize()
end

function WireGPU_DrawScreen(x, y, w, h, rotation, scale)
	return GPU.DrawScreen(x, y, w, h, rotation, scale)
end
