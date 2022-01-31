local HoloDisplayCVar = GetConVar("wire_holograms_display_owners_maxdist")

local HoloDisplayCVarCL = CreateClientConVar("wire_holograms_display_owners_maxdist_cl","-1",true,false,
"The maximum distance that wire_holograms_display_owners will allow names to be seen. -1 for original function.",-1,32768)

local function WireHologramsShowOwners()
	local Eye = EyePos()
	local EntList = ents.FindByClass( "gmod_wire_hologram" )
	local FinalEntList = {}

	local FinalCVar = HoloDisplayCVar:GetInt()
	local CVA = HoloDisplayCVar:GetInt()
	local CVB = HoloDisplayCVarCL:GetInt()

	if CVA == -1 then -- Server allows mapwide visibility for display, default to the client's setting
		FinalCVar = CVB
	else
		if CVB >= 0 then -- Use whichever value is lower, as long as the client isn't trying to get mapwide visibility of names while the server prevents it
			FinalCVar = math.min(CVA,CVB)
		else -- If all else fails, settle with what the server is using
			FinalCVar = CVA
		end
	end

	local HoloDisplayDist = FinalCVar ^ 2

	if FinalCVar > 0 then -- Can't check for -1 from the above variable since it is squared, and it needs to be squared for performance reasons comparing distances
		for _,ent in pairs(EntList) do
			local DistToEye = Eye:DistToSqr(ent:GetPos())
			if DistToEye < HoloDisplayDist then FinalEntList[#FinalEntList + 1] = ent end
		end
	else -- Default to the original function of showing ALL holograms
		-- if, in the end, both are 0, why even bother trying to do it at all (and why is this running?)
		if FinalCVar == -1 then FinalEntList = EntList end
	end

	for _,ent in pairs( FinalEntList ) do
		local id = ent:GetNWInt( "ownerid" )

		for _,ply in pairs( player.GetAll() ) do
			if ply:UserID() == id then
				local vec = ent:GetPos():ToScreen()

				draw.DrawText( ply:Name() .. "\n" .. ply:SteamID(), "DermaDefault", vec.x, vec.y, Color(255,0,0,255), 1 )
				break
			end
		end
	end
end

local display_owners = false
concommand.Add( "wire_holograms_display_owners", function()
	display_owners = !display_owners
	if display_owners then
		hook.Add( "HUDPaint", "wire_holograms_showowners", WireHologramsShowOwners)
	else
		hook.Remove("HUDPaint", "wire_holograms_showowners")
	end
end )
