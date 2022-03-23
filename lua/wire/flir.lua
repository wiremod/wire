--[[
	Simulation of FLIR (forward-looking infrared) vision.
	Possible future ideas:
	* Different materials have different emissivities:
		aluminium is about 20%, wherease asphalt is 95%.
		maybe we could use the physical properties to simulate this?
	* the luminance of a texture contributes *negatively* to its emissivity
	* IR sensors often have auto gain control that we might simulate with auto-exposure


	TODO: 
	
--]]


if not FLIR then FLIR = { enabled = false } end

if CLIENT then
	FLIR.RenderStack = {}
	FLIR.enabled = false
	local function hide() return end

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



	--add and remove entities from the FLIR rendering stack
	local function SetFLIR(ent)
		if not IsValid(ent) then return end
		local c = ent:GetClass()

		if (string.match(c, "^prop_") or ent:GetMoveType() == MOVETYPE_VPHYSICS or (ent:IsPlayer() and ent != ply) or ent:IsNPC() or ent:IsRagdoll() or c == "gmod_wire_hologram") and ent:GetColor().a > 0 then
			table.insert(FLIR.RenderStack, ent)
			ent:CallOnRemove("RemoveFLIR", RemoveFLIR)
			ent.RenderOverride = hide	--we're already rendering later, so don't bother beforehand
		end
	end

	local function RemoveFLIR(ent)
		if not IsValid(ent) then return end

		table.RemoveByValue(FLIR.RenderStack, ent)
		ent.RenderOverride = nil
	end



	

	function FLIR.start()
		local cheats = GetConVar("sv_cheats"):GetInt()
		if not cheats then
			ply:ChatPrint("sv_cheats must be enabled for wire FLIR to work!")
			return
		end



		if FLIR.enabled then return else FLIR.enabled = true end

			ply:ConCommand("mat_fullbright = 1")	--lightmodes suck. I tried to make them work. This is for the best. Illuminates whole map.

			for _, v in pairs(ents.GetAll()) do
				SetFLIR(v)
			end


		hook.Add("PostDraw2DSkyBox", "wire_flir", function() --overrides 2d skybox to be gray, as it normally becomes white or black
			DrawColorModify(FLIR.skycol)
		end)

		
		hook.Add("PostDrawOpaqueRenderables", "wire_flir", function(_, sky)
			if sky then return end

			DrawColorModify(FLIR.mapcol)
			--render.SetColorMaterialIgnoreZ()
			render.MaterialOverride(Material("models/debug/debugwhite"))

			for _, v in pairs(FLIR.RenderStack) do
				if not IsValid(v) or v:GetNoDraw() then
					RemoveFLIR(v)
					goto next
				end

				v.RenderOverride = nil
				v:DrawModel()
				v.RenderOverride = hide

				::next::
			end

			render.MaterialOverride(nil)
		end)



		hook.Add("RenderScreenspaceEffects", "wire_flir", function()
			--post-processing
			DrawColorModify(FLIR.desat)
			DrawBloom(0.5,1.0,2,2,2,1, 1, 1, 1)
			DrawBokehDOF(1, 0.1, 0.1)

			--reset lighting so the menus are intelligble (try 1)
		end)


		hook.Add("OnEntityCreated", "wire_flir", function(ent)
			if FLIR.enabled then
				SetFLIR(ent)
			end
		end)

		hook.Add("CreateClientsideRagdoll", "wire_flir", function(ent, rag)
			if FLIR.enabled then
				SetFLIR(rag)
			end
		end)
	end



	function FLIR.stop()
		if FLIR.enabled then FLIR.enabled = false else return end

		timer.Destroy("wire_flir_update")

		ply:ConCommand("mat_fullbright = 0")

		hook.Remove("PostDrawOpaqueRenderables", "wire_flir")
		hook.Remove("PostDrawTranslucentRenderables", "wire_flir")
		hook.Remove("RenderScreenspaceEffects", "wire_flir")
		hook.Remove("PostDraw2DSkyBox", "wire_flir")
		hook.Remove("PreRender", "wire_flir")
		hook.Remove("OnEntityCreated", "wire_flir")
		hook.Remove("CreateClientsideRagdoll", "wire_flir")

		for _, v in pairs(ents.GetAll()) do
			RemoveFLIR(v)
		end
	end

	
	function FLIR.toggle()
		if not FLIR.enabled then FLIR.start() else FLIR.stop() end
	end


	concommand.Add("flir_toggle", function()
		FLIR.toggle()
	end)

	function FLIR.enable(enabled)
		if enabled then FLIR.start() else FLIR.stop() end
	end

	net.Receive("FLIR.enable", function()
		local enabled = net.ReadBool()
		FLIR.enable(enabled)
	end)

else
	function FLIR.start(ply) FLIR.enable(ply, true) end
	function FLIR.stop(ply) FLIR.enable(ply, false) end

	util.AddNetworkString("FLIR.enable")
	
	function FLIR.enable(ply, enabled)
		net.Start("FLIR.enable")
		net.WriteBool(enabled)
		net.Send(ply)
	end
end