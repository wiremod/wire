-- Replicated from serverside, same function as the one below except this takes precedence
local holoDisplayCVar = CreateConVar("wire_holograms_display_owners_maxdist", "-1", {FCVAR_REPLICATED})
local holoDisplayCVarCL = CreateClientConVar( "wire_holograms_display_owners_maxdist_cl" , "-1", true, false,
"The maximum distance that wire_holograms_display_owners will allow names to be seen. -1 for original function.", -1, 32768)

local function WireHologramsShowOwners()
	local finalCVar = 0
	-- Both cvars, server-replicated and clientside
	local cva = holoDisplayCVar:GetInt()
	local cvb = holoDisplayCVarCL:GetInt()

	if cva == -1 then -- Server allows mapwide visibility for display, default to the client's setting
		finalCVar = cvb
	else
		if cvb >= 0 then -- Use whichever value is lower, as long as the client isn't trying to get mapwide visibility of names while the server prevents it
			finalCVar = math.min(cva, cvb)
		else -- If all else fails, settle with what the server is using
			finalCVar = cva
		end
	end

	local entList = {}

	if finalCVar > 0 then -- Can't check for -1 from the above variable since it is squared, and it needs to be squared for performance reasons comparing distances
		local holoDisplayDist = finalCVar ^ 2
		local eyePos = EyePos()

		for _, ent in ipairs(ents.FindByClass("gmod_wire_hologram")) do
			if eyePos:DistToSqr(ent:GetPos()) < holoDisplayDist then entList[#entList + 1] = ent end
		end
	elseif finalCVar == -1 then
		-- Default to the original function of showing ALL holograms
		-- if, in the end, both are 0, why even bother trying to do it at all (and why is this running?)
		entList = ents.FindByClass("gmod_wire_hologram")
	end

	local names = setmetatable({}, {__index = function(t, ply)
		local name = ply:IsValid() and ply:Nick() or "(disconnected)"
		t[ply] = name

		return name
	end})

	for _, ent in ipairs(entList) do
		local vec = ent:GetPos():ToScreen()

		if vec.visible then
			local text = names[ent:GetPlayer()] .. "\n" .. ent.steamid
			draw.DrawText(text, "DermaDefaultBold", vec.x + 1, vec.y + 1, color_black, TEXT_ALIGN_CENTER)
			draw.DrawText(text, "DermaDefaultBold", vec.x, vec.y, color_white, TEXT_ALIGN_CENTER)
		end
	end
end

local display_owners = false

concommand.Add("wire_holograms_display_owners", function()
	display_owners = not display_owners

	if display_owners then
		hook.Add("HUDPaint", "wire_holograms_showowners", WireHologramsShowOwners)
	else
		hook.Remove("HUDPaint", "wire_holograms_showowners")
	end
end)
