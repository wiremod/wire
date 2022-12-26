-- Replicated from serverside, same function as the one below except this takes precedence
local holoDisplayCVar = CreateConVar("wire_holograms_display_owners_maxdist", "-1", {FCVAR_REPLICATED})

local holoDisplayCVarCL = CreateClientConVar( "wire_holograms_display_owners_maxdist_cl" , "-1", true, false,
"The maximum distance that wire_holograms_display_owners will allow names to be seen. -1 for original function.", -1, 32768)

local function WireHologramsShowOwners()
	local eye = EyePos()
	local entList = ents.FindByClass( "gmod_wire_hologram" )
	local finalEntList = {}

	local finalCVar = 0
	-- Both cvars, server-replicated and clientside
	local cva = holoDisplayCVar:GetInt()
	local cvb = holoDisplayCVarCL:GetInt()

	if cva == -1 then -- Server allows mapwide visibility for display, default to the client's setting
		finalCVar = cvb
	else
		if cvb >= 0 then -- Use whichever value is lower, as long as the client isn't trying to get mapwide visibility of names while the server prevents it
			finalCVar = math.min( cva, cvb)
		else -- If all else fails, settle with what the server is using
			finalCVar = cva
		end
	end

	local holoDisplayDist = finalCVar ^ 2

	if finalCVar > 0 then -- Can't check for -1 from the above variable since it is squared, and it needs to be squared for performance reasons comparing distances
		for _,ent in pairs( entList ) do
			local distToEye = eye:DistToSqr( ent:GetPos() )
			if distToEye < holoDisplayDist then finalEntList[ #finalEntList + 1 ] = ent end
		end
	else -- Default to the original function of showing ALL holograms
		-- if, in the end, both are 0, why even bother trying to do it at all (and why is this running?)
		if finalCVar == -1 then finalEntList = entList end
	end

	local names = setmetatable({},{__index=function(t, ply)
		local name = ply:IsValid() and ply:GetName() or "(disconnected)"
		t[ply] = name
		return name
	end})
	for _, ent in pairs( finalEntList ) do
		local vec = ent:GetPos():ToScreen()
		if vec.visible then
			draw.DrawText( names[ent:GetPlayer()] .. "\n" .. ent.steamid, "DermaDefault", vec.x, vec.y, Color(255,0,0,255), 1 )
		end
	end
end

local display_owners = false
concommand.Add( "wire_holograms_display_owners", function()
	display_owners = not display_owners
	if display_owners then
		hook.Add( "HUDPaint", "wire_holograms_showowners", WireHologramsShowOwners)
	else
		hook.Remove("HUDPaint", "wire_holograms_showowners")
	end
end )
