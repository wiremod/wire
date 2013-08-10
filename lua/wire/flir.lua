--[[
	Simulation of FLIR (forward-looking infrared) vision.
	Possible future ideas:
	* Different materials have different emissivities:
		aluminium is about 20%, wherease asphalt is 95%.
		maybe we could use the physical properties to simulate this?
	* the luminance of a texture contributes *negatively* to its emissivity
	* IR sensors often have auto gain control that we might simulate with auto-exposure
	* players are drawn fullbright but NPCs aren't.
--]]

if not FLIR then FLIR = { enabled = false } end

if CLIENT then
	FLIR.living = CreateMaterial("flir_living", "UnlitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1,
	})

	FLIR.normal = CreateMaterial("flir_normal", "VertexLitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1,
		["$halflambert"] = 1 -- causes the diffuse lighting to 'wrap around' more
	})

	FLIR.colmod = {
		[ "$pp_colour_addr" ] = 0.4,
		[ "$pp_colour_addg" ] = -.5,
		[ "$pp_colour_addb" ] = -.5,
		[ "$pp_colour_brightness" ] = .1,
		[ "$pp_colour_contrast" ] = 1.2,
		[ "$pp_colour_colour" ] = 0,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0
	}

	local materialOverrides = {
			PlayerDraw = { FLIR.living, FLIR.normal },
			DrawOpaqueRenderables = { FLIR.normal, nil },
			DrawTranslucentRenderables = { FLIR.normal, nil },
			DrawSkybox = { FLIR.normal, nil }
	}

	function FLIR.start()
		if FLIR.enabled then return else FLIR.enabled = true end

		for hookName, materials in pairs(materialOverrides) do
			hook.Add("Pre" .. hookName, "flir", function() render.MaterialOverride(materials[1]) end)
			hook.Add("Post" .. hookName, "flir", function() render.MaterialOverride(materials[2]) end)
		end

		hook.Add("RenderScreenspaceEffects", "flir", function()
			DrawColorModify(FLIR.colmod)
			DrawBloom(0,100,5,5,3,0.1,0,0,0)
			DrawSharpen(1,0.5)
		end)
	end

	function FLIR.stop()
		if FLIR.enabled then FLIR.enabled = false else return end
		for hookName, materials in pairs(materialOverrides) do
			hook.Remove("Pre" .. hookName, "flir")
			hook.Remove("Post" .. hookName, "flir")
		end
		hook.Remove("RenderScreenspaceEffects", "flir")
		render.MaterialOverride(nil)
	end

	function FLIR.enable(enabled)
		if enabled then FLIR.start() else FLIR.stop() end
	end

	usermessage.Hook("flir.enable",function(um)
		FLIR.enable(um:ReadBool())
	end)

	concommand.Add("flir_enable", function(player, command, args)
		FLIR.enable(tobool(args[1]))
	end)
else
	function FLIR.start(player) FLIR.enable(player, true) end
	function FLIR.stop(player) FLIR.enable(player, false) end

	function FLIR.enable(player, enabled)
		umsg.Start( "flir.enable", player)
			umsg.Bool( enabled )
		umsg.End()
	end
end
