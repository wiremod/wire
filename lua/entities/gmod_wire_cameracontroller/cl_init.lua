
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

local living = CreateMaterial("flir_living","UnlitGeneric", {["$basetexture"] = "color/white", ["$model"] = 1, ["$translucent"] = 0, ["$alpha"] = 0, ["$nocull"] = 0, ["$ignorez"] = 0});
local normal = CreateMaterial("flir_normal","VertexLitGeneric", {["$basetexture"] = "color/white", ["$model"] = 1, ["$translucent"] = 0, ["$ignorez"] = 0});

local colmod = {
	[ "$pp_colour_addr" ] = -.4,
	[ "$pp_colour_addg" ] = -.5,
	[ "$pp_colour_addb" ] = -.5,
	[ "$pp_colour_brightness" ] = .1,
	[ "$pp_colour_contrast" ] = 1.2,
	[ "$pp_colour_colour" ] = 0,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

local flir_enabled = false
local function flir_start()
	if (flir_enabled) then return end
	flir_enabled = true
	hook.Add("PrePlayerDraw","flir_PrePlayerDraw",function()
		render.MaterialOverride(living);
	end);
	hook.Add("PostPlayerDraw","flir_PostPlayerDraw",function()
		--render.MaterialOverride(nil);
		render.MaterialOverride(normal);
	end);

	hook.Add("PreDrawOpaqueRenderables","flir_PreDrawOpaqueRenderables",function()
		render.MaterialOverride(normal);
	end);
	hook.Add("PostDrawOpaqueRenderables","flir_PostDrawOpaqueRenderables",function()
		render.MaterialOverride(nil);
	end);

	hook.Add("PreDrawTranslucentRenderables","flir_PreDrawTranslucentRenderables",function()
		render.MaterialOverride(normal);
	end);
	hook.Add("PostDrawTranslucentRenderables","flir_PostDrawTranslucentRenderables",function()
		render.MaterialOverride(nil);
	end);

	hook.Add("PreDrawSkybox","flir_PreDrawSkybox",function()
		render.MaterialOverride(normal);
	end);
	hook.Add("PostDrawSkybox","flir_PostDrawSkybox",function()
		render.MaterialOverride(nil);
	end);

	hook.Add("RenderScreenspaceEffects","flir_RenderScreenspaceEffects",function()
		DrawColorModify(colmod);
		DrawBloom(0,100,5,5,3,0.1,0,0,0);
		DrawSharpen(1,0.5);
	end);
end

local function flir_end()
	if (!flir_enabled) then return end
	flir_enabled = false
	render.MaterialOverride(nil);
	hook.Remove("PrePlayerDraw","flir_PrePlayerDraw");
	hook.Remove("PostPlayerDraw","flir_PostPlayerDraw");

	hook.Remove("PreDrawOpaqueRenderables","flir_PreDrawOpaqueRenderables");
	hook.Remove("PostDrawOpaqueRenderables","flir_PostDrawOpaqueRenderables");

	hook.Remove("PreDrawTranslucentRenderables","flir_PreDrawTranslucentRenderables");
	hook.Remove("PostDrawTranslucentRenderables","flir_PostDrawTranslucentRenderables");

	hook.Remove("PreDrawSkybox","flir_PreDrawSkybox");
	hook.Remove("PostDrawSkybox","flir_PostDrawSkybox");

	hook.Remove("RenderScreenspaceEffects","flir_RenderScreenspaceEffects");
end

usermessage.Hook("toggle_flir",function(um)
	local mode = um:ReadBool();
	if(mode == true) then
		flir_start();
	else
		flir_end();
	end
end);
