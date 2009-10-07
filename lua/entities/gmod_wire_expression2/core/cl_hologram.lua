if not datastream then require( "datastream" ) end

local hologram_owners = {}

datastream.Hook( "wire_holograms_owners", function( ply, handler, id, encoded, decoded )

	for k,v in pairs( encoded[1] ) do
		if v.owner and v.owner:IsValid() and v.hologram and v.hologram:IsValid() then
			table.insert( hologram_owners, { ["owner"] = v.owner, ["hologram"] = v.hologram } )
		end
	end

	hook.Add( "HUDPaint", "draw_wire_hologram_owners", function( )
		for k,v in pairs( hologram_owners ) do
			if v.owner and v.owner:IsValid() and v.owner:IsPlayer() and v.hologram and v.hologram:IsValid() then
				local vec = v.hologram:GetPos():ToScreen()
				draw.DrawText(v.owner:Name(), "ScoreboardText", vec.x, vec.y, Color(255,0,0,255), 1)
			end
		end
	end )

end)

-- this function is called from the client side
function wire_holograms_remove_owners_display()
	hook.Remove( "HUDPaint", "draw_wire_hologram_owners" )
	hologram_owners = {}
end
