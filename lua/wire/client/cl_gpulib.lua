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
WireGPU_matScreen 	= Material("models\duckeh\buttons\0")
WireGPU_texScreen	= surface.GetTextureID("models\duckeh\buttons\0")

//
// Rendertarget cache management
//
function WireGPU_NeedRenderTarget(entindex)
	for i=1,#RenderTargetCache do
		if (not RenderTargetCache[i].Used) then
			RenderTargetCache[i].Used = entindex
			return RenderTargetCache[i].Target
		end
	end

	//Need to create new. PANIC?!
	//print("RENDER TARGET PANIC. RENDER TARGET PANIC!")
	return RenderTargetCache[1].Target
end

function WireGPU_GetMyRenderTarget(entindex)
	for i=1,#RenderTargetCache do
		if ((RenderTargetCache[i].Used) and
		    (RenderTargetCache[i].Used == entindex)) then
			return RenderTargetCache[i].Target
		end
	end
	return WireGPU_NeedRenderTarget(entindex)
end

function WireGPU_ReturnRenderTarget(entindex)
	for i=1,#RenderTargetCache do
		if ((RenderTargetCache[i].Used) and
		    (RenderTargetCache[i].Used == entindex)) then
			RenderTargetCache[i].Used = nil
		end
	end
end

//
// Misc helper functions
//
function WireGPU_DrawScreen(x,y,w,h,rotation,scale)
	vertex = {}

	//Generate vertex data
	vertex[1] = {}
	vertex[1]["x"] = x
	vertex[1]["y"] = y

	vertex[2] = {}
	vertex[2]["x"] = x+w
	vertex[2]["y"] = y

	vertex[3] = {}
	vertex[3]["x"] = x+w
	vertex[3]["y"] = y+h

	vertex[4] = {}
	vertex[4]["x"] = x
	vertex[4]["y"] = y+h

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

