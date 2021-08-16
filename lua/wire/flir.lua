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
		["$halflambert"] = 1, -- causes the diffuse lighting to 'wrap around' more
		["$color2"] = "[10.0 10.0 10.0]"
	})

	FLIR.entcol = {
		["$pp_colour_colour" ] = 0,
		["$pp_colour_brightness"] = -0.3,
		["$pp_colour_contrast"] = 1.0
	}

	FLIR.mapcol = {
		[ "$pp_colour_brightness" ] = 0.8,
		[ "$pp_colour_contrast" ] = 0.5,
		[ "$pp_colour_colour"] = 0.0,
	}

	FLIR.skycol = {
		[ "$pp_colour_brightness" ] = -0.3
	}

	local materialOverrides = {
			PlayerDraw = { FLIR.living, FLIR.normal },
			DrawSkybox = { FLIR.normal, nil }
	}

	local function SetFLIRMat(ent)
		if not IsValid(ent) then return end

		if ent:GetMoveType() == MOVETYPE_VPHYSICS or IsValid(ent:GetParent()) or ent:IsPlayer() or ent:IsNPC() or ent:IsRagdoll() then
				ent.FLIRMat = ent:GetMaterial()
				ent:SetMaterial("!flir_normal")	
		end

	end

	hook.Add("OnEntityCreated", "flir", function(ent)
		if FLIR.enabled then
			SetFLIRMat(ent)
		end
	end)

	hook.Add("CreateClientsideRagdoll", "flir", function(ent, rag)
		if FLIR.enabled then
			SetFLIRMat(rag)
		end
	end)

	function FLIR.start()
		if FLIR.enabled then return else FLIR.enabled = true end

		bright = false
		hook.Add("PreRender", "flirbright", function()			--rendermode 2 avoids fullbright issues with particles freaking out
			render.SetLightingMode(2)								    --but still brightness dark areas as they should
			bright = true
		end)

		hook.Add("PostRender", "flirbright", function()
			if bright then
				render.SetLightingMode(0)
				bright = false
			end
		end)

		hook.Add("PreDrawHUD", "flirbright", function()
			if bright then
				render.SetLightingMode(0)
				bright = false
			end
		end)



		for hookName, materials in pairs(materialOverrides) do
			hook.Add("Pre" .. hookName, "flir", function() render.MaterialOverride(materials[1]) end)
			hook.Add("Post" .. hookName, "flir", function() render.MaterialOverride(materials[2]) end)
		end

		hook.Add("PostDraw2DSkyBox", "flir", function() --overrides 2d skybox to be gray, as it normally becomes white
			DrawColorModify(FLIR.skycol)
		end)

		hook.Add("PreDrawOpaqueRenderables", "flir", function()
			DrawColorModify(FLIR.mapcol)		--rendermode 2 saturates a lot
		end)

		hook.Add("RenderScreenspaceEffects", "flir", function()
			DrawColorModify(FLIR.entcol)
			DrawBloom(0.5,1.0,2,2,2,1, 1, 1, 1)
			DrawBokehDOF(1, 0.1, 0.1)
		end)

		for k, v in pairs(ents.GetAll()) do
			SetFLIRMat(v)
		end
	end

	function FLIR.stop()
		if FLIR.enabled then FLIR.enabled = false else return end
		for hookName, materials in pairs(materialOverrides) do
			hook.Remove("Pre" .. hookName, "flir")
			hook.Remove("Post" .. hookName, "flir")
		end
		hook.Remove("RenderScreenspaceEffects", "flir")
		hook.Remove("PostDraw2DSkyBox", "flir")
		hook.Remove("PreDrawOpaqueRenderables", "flir")
		hook.Remove("PreRender", "flirbright")
		hook.Remove("PostRender", "flirbright")
		render.MaterialOverride(nil)

		
		for k, v in pairs(ents.GetAll()) do
			if v.FLIRMat then
				v:SetMaterial(v.FLIRMat)
				v.FLIRMat = nil
			end
		end
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
