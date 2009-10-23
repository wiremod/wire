local RT_CACHE_SIZE = 16

//
// Create rendertarget cache
//
if (!RenderTargetCache) then
	RenderTargetCache = {}
	for i=1,RT_CACHE_SIZE do
		RenderTargetCache[i] = {}
		RenderTargetCache[i].Target = GetRenderTarget("WireGPU_RT_"..i, 512, 512)
		RenderTargetCache[i].Used = nil
	end
end

//
// Create basic fonts
//
surface.CreateFont("lucida console", 20, 800, true, false, "WireGPU_ConsoleFont")

//
// Create screen textures and materials
//
WireGPU_matScreen 	= Material("ignore_this_error")
WireGPU_texScreen	= surface.GetTextureID("ignore_this_error")

WireGPUmeta = {}
WireGPUmeta.__index = WireGPUmeta

function WireGPU(ent)
	local self = {
		entindex = ent:EntIndex(),
		Entity = ent
	}
	setmetatable(self, WireGPUmeta)
	self:NeedRenderTarget()
	return self
end

//
// Rendertarget cache management
//
function WireGPUmeta:NeedRenderTarget()
	for i=1,#RenderTargetCache do
		if not RenderTargetCache[i].Used then
			RenderTargetCache[i].Used = self.entindex
			self.RTindex = i
			return RenderTargetCache[i].Target
		end
	end

	//Need to create new. PANIC?!
	//print("RENDER TARGET PANIC. RENDER TARGET PANIC!")
	return RenderTargetCache[1].Target
end

function WireGPUmeta:GetMyRenderTarget()
	if self.RTindex then return RenderTargetCache[self.RTindex].Target end

	return self:NeedRenderTarget()
end

function WireGPUmeta:ReturnRenderTarget()
	RenderTargetCache[self.RTindex].Used = nil
end

//
// Misc helper functions
//
function WireGPUmeta.DrawScreen(x,y,w,h,rotation,scale)
	//Generate vertex data
	local vertex = {
		{ x = x  , y = y   },
		{ x = x+w, y = y   },
		{ x = x+w, y = y+h },
		{ x = x  , y = y+h },
	}

	//Rotation
	if (rotation == 0) then
		vertex[4]["u"] = 0-scale
		vertex[4]["v"] = 1+scale
		vertex[3]["u"] = 1+scale
		vertex[3]["v"] = 1+scale
		vertex[2]["u"] = 1+scale
		vertex[2]["v"] = 0-scale
		vertex[1]["u"] = 0-scale
		vertex[1]["v"] = 0-scale
	end

	if (rotation == 1) then
		vertex[2]["u"] = 0-scale
		vertex[2]["v"] = 0-scale
		vertex[3]["u"] = 1+scale
		vertex[3]["v"] = 0-scale
		vertex[4]["u"] = 1+scale
		vertex[4]["v"] = 1+scale
		vertex[1]["u"] = 0-scale
		vertex[1]["v"] = 1+scale
	end

	if (rotation == 2) then
		vertex[3]["u"] = 0-scale
		vertex[3]["v"] = 0-scale
		vertex[4]["u"] = 1+scale
		vertex[4]["v"] = 0-scale
		vertex[1]["u"] = 1+scale
		vertex[1]["v"] = 1+scale
		vertex[2]["u"] = 0-scale
		vertex[2]["v"] = 1+scale
	end

	if (rotation == 3) then
		vertex[4]["u"] = 0-scale
		vertex[4]["v"] = 0-scale
		vertex[1]["u"] = 1+scale
		vertex[1]["v"] = 0-scale
		vertex[2]["u"] = 1+scale
		vertex[2]["v"] = 1+scale
		vertex[3]["u"] = 0-scale
		vertex[3]["v"] = 1+scale
	end

	surface.DrawPoly(vertex)
end

function WireGPUmeta:RenderToGPU(renderfunction)
	local oldw = ScrW()
	local oldh = ScrH()

	local NewRT = self:GetMyRenderTarget()
	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(NewRT)
	render.SetViewPort(0,0,512,512)
	cam.Start2D()
		PCallError(renderfunction)
	cam.End2D()
	render.SetViewPort(0,0,oldw,oldh)
	render.SetRenderTarget(OldRT)
end

function WireGPUmeta:Render()
	local model = self.Entity:GetModel()
	local OF, OU, OR, Res, RatioX, Rot90
	if (WireGPU_Monitors[model]) && (WireGPU_Monitors[model].OF) then
		OF = WireGPU_Monitors[model].OF
		OU = WireGPU_Monitors[model].OU
		OR = WireGPU_Monitors[model].OR
		Res = WireGPU_Monitors[model].RS
		RatioX = WireGPU_Monitors[model].RatioX
		Rot90 = WireGPU_Monitors[model].rot90
	else
		OF = 0
		OU = 0
		OR = 0
		Res = 1
		RatioX = 1
	end

	local ang = self.Entity:GetAngles()
	local rot = Angle(-90,90,0)
	if Rot90 then
		rot = Angle(0,90,0)
	end

	ang:RotateAroundAxis(ang:Right(),   rot.p)
	ang:RotateAroundAxis(ang:Up(),      rot.y)
	ang:RotateAroundAxis(ang:Forward(), rot.r)
	--ang = self.Entity:LocalToWorldAngles(rot)

	local pos = self.Entity:GetPos()+(self.Entity:GetForward()*OF)+(self.Entity:GetUp()*OU)+(self.Entity:GetRight()*OR)

	local OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
	WireGPU_matScreen:SetMaterialTexture("$basetexture", self:GetMyRenderTarget())

	cam.Start3D2D(pos,ang,Res)
		local w = 512
		local h = 512
		local x = -w/2
		local y = -h/2

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(-256,-256,512/RatioX,512)

		surface.SetDrawColor(255,255,255,255)
		surface.SetTexture(WireGPU_texScreen)
		self.DrawScreen(x,y,w/RatioX,h,0,0)
	cam.End3D2D()

	WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex)
end

-- compatibility

local GPUs = {}

function WireGPU_NeedRenderTarget(entindex)
	if not GPUs[entindex] then GPUs[entindex] = WireGPU(Entity(entindex)) end
	return GPUs[entindex]:NeedRenderTarget()
end

function WireGPU_GetMyRenderTarget(entindex)
	if not GPUs[entindex] then GPUs[entindex] = WireGPU(Entity(entindex)) end
	return GPUs[entindex]:GetMyRenderTarget()
end

function WireGPU_ReturnRenderTarget(entindex)
	if not GPUs[entindex] then GPUs[entindex] = WireGPU(Entity(entindex)) end
	return GPUs[entindex]:ReturnRenderTarget()
end

function WireGPU_DrawScreen(x,y,w,h,rotation,scale)
	return WireGPUmeta.DrawScreen(x,y,w,h,rotation,scale)
end
