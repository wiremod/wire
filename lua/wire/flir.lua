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

	FLIR.normal = CreateMaterial("flir_normal", "VertexLitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1,
		["$halflambert"] = 1, -- causes the diffuse lighting to 'wrap around' more
		["$color2"] = "[10.0 10.0 10.0]"
	})

	FLIR.entcol = {
		["$pp_colour_colour" ] = 0,
		["$pp_colour_brightness"] = -0.00,
		["$pp_colour_contrast"] = 4
	}

	FLIR.mapcol = {
		[ "$pp_colour_brightness" ] = 0,
		[ "$pp_colour_contrast" ] = 0.2
	}

	FLIR.skycol = {
		[ "$pp_colour_contrast" ] = 0.2,
		[ "$pp_colour_brightness" ] = 1
	}

	local function SetFLIRMat(ent)
		if not IsValid(ent) then return end

		if ent:GetMoveType() == MOVETYPE_VPHYSICS or IsValid(ent:GetParent()) or ent:IsPlayer() or ent:IsNPC() or ent:IsRagdoll() then
				ent.FLIRMat = ent:GetMaterial()
				ent:SetMaterial("!flir_normal")	
		end

	end

	

	function FLIR.start()
		if FLIR.enabled then return else FLIR.enabled = true end

		

		bright = false
		hook.Add("PreRender", "wire_flir", function()			--lighting mode 1  = fullbright
			render.SetLightingMode(1)			
		end)


		hook.Add("PostDraw2DSkyBox", "wire_flir", function() --overrides 2d skybox to be gray, as it normally becomes white
			DrawColorModify(FLIR.skycol)
		end)

		hook.Add("PostDrawTranslucentRenderables", "wire_flir", function(_a, _b, sky) 
			if not sky then 
				render.SetLightingMode(0)
				DrawColorModify(FLIR.mapcol)
			end
		end)

		hook.Add("RenderScreenspaceEffects", "wire_flir", function()
			DrawColorModify(FLIR.entcol)
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

		hook.Remove("PostDrawTranslucentRenderables", "wire_flir")
		hook.Remove("RenderScreenspaceEffects", "wire_flir")
		hook.Remove("PostDraw2DSkyBox", "wire_flir")
		hook.Remove("PreRender", "wire_flir")
		hook.Remove("OnEntityCreated", "wire_flir")
		hook.Remove("CreateClientsideRagdoll", "wire_flir")
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