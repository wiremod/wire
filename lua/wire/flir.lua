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

	FLIR.RenderStack = {}
	FLIR.Render = 0

	FLIR.bright = CreateMaterial("flir_bright", "UnlitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1
	})

	FLIR.mapcol = {
		[ "$pp_colour_brightness" ] = 0.4,
		[ "$pp_colour_contrast" ] = 0.4	
	}

	FLIR.skycol = {
		[ "$pp_colour_contrast" ] = 0.2,
		[ "$pp_colour_brightness" ] = 1
	}

	FLIR.desat = {
		["$pp_colour_colour"] = 0,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_brightness"] = 0
	}

	local function SetFLIRMat(ent)
		if not IsValid(ent) then return end

		if ent:GetMoveType() == MOVETYPE_VPHYSICS or ent:IsPlayer() or ent:IsNPC() or ent:IsRagdoll() or ent:GetClass() == "gmod_wire_hologram" then
			ent.FLIRCol = ent:GetColor()	
			ent.RenderOverride = FLIR.Render

			table.insert(FLIR.RenderStack, ent)			--add entity to the FLIR renderstack and remove it from regular opaque rendering
		end
	end

	local function RemoveFLIRMat(ent)
		ent.RenderOverride = nil
		
		if ent.FLIRCol then
			ent:SetColor(ent.FLIRCol)
		end
		table.RemoveByValue(FLIR.RenderStack, ent)
	end

	function FLIR.Render(self)
		if FLIR.Render == 1 then self:DrawModel() end
	end


	function FLIR.start()
		if FLIR.enabled then return else FLIR.enabled = true end

		bright = false
		hook.Add("PreRender", "wire_flir", function()			--lighting mode 1  = fullbright
			render.SetLightingMode(1)
			FLIR.Render = 0
		end)


		hook.Add("PostDraw2DSkyBox", "wire_flir", function() --overrides 2d skybox to be gray, as it normally becomes white or black
			DrawColorModify(FLIR.skycol)
		end)

		hook.Add("PreDrawTranslucentRenderables", "wire_flir", function(a, b, sky)
			if not sky then
				DrawColorModify(FLIR.mapcol)
			end
		end)
		
		hook.Add("PostDrawTranslucentRenderables", "wire_flir", function(_a, _b, sky)
			if sky then return end

			render.SetLightingMode(0)
			FLIR.Render = 1
			render.MaterialOverride(FLIR.bright)

			for k, v in pairs(FLIR.RenderStack) do				--draw all the FLIR highlighted enemies after the opaque render
				if v:IsValid() then v:DrawModel() end									--to separate then from the rest of the map	
			end

			FLIR.Render = 0
			render.MaterialOverride(nil)
			render.SetLightingMode(1)
		end)


		hook.Add("RenderScreenspaceEffects", "wire_flir", function()
			render.SetLightingMode(0)

			DrawColorModify(FLIR.desat)
			DrawBloom(0.5,1.0,2,2,2,1, 1, 1, 1)
			DrawBokehDOF(1, 0.1, 0.1)
		end)


		hook.Add("OnEntityCreated", "wire_flir", function(ent)
			if FLIR.enabled then
				SetFLIRMat(ent)
			end
		end)

		hook.Add("CreateClientsideRagdoll", "wire_flir", function(ent, rag)
			if FLIR.enabled then
				SetFLIRMat(rag)
			end
		end)

		for k, v in pairs(ents.GetAll()) do
			SetFLIRMat(v)
		end
	end

	function FLIR.stop()
		if FLIR.enabled then FLIR.enabled = false else return end

		render.SetLightingMode(0)

		hook.Remove("PreDrawTranslucentRenderables", "wire_flir")
		hook.Remove("PostDrawTranslucentRenderables", "wire_flir")
		hook.Remove("RenderScreenspaceEffects", "wire_flir")
		hook.Remove("PostDraw2DSkyBox", "wire_flir")
		hook.Remove("PreRender", "wire_flir")
		hook.Remove("OnEntityCreated", "wire_flir")
		hook.Remove("CreateClientsideRagdoll", "wire_flir")
		render.MaterialOverride(nil)

		for k, v in pairs(ents.GetAll()) do
			RemoveFLIRMat(v)
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