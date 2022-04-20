--------------------------------------------------------
--  Frame Saving & Loading
--------------------------------------------------------

local EGP = EGP

EGP.Frames = WireLib.RegisterPlayerTable()
EGP.FrameCounts = WireLib.RegisterPlayerTable()

function EGP:SaveFrame( ply, Ent, index )
	if not EGP.Frames[ply] then EGP.Frames[ply] = {} end
	if not EGP.FrameCounts[ply] then EGP.FrameCounts[ply] = 0 end
	if EGP.FrameCounts[ply] > 256 and (not EGP.Frames[ply][index]) then return false end -- TODO convar to change limit, 256 seems enough for an obscure feature
	if not EGP.Frames[ply][index] then EGP.FrameCounts[ply] = EGP.FrameCounts[ply] + 1 end
	EGP.Frames[ply][index] = table.Copy(Ent.RenderTable)
	return true
end

function EGP:LoadFrame( ply, Ent, index )
	if not EGP.Frames[ply] then EGP.Frames[ply] = {} return false end
	if SERVER then
		if not EGP.Frames[ply][index] then return false end
		return true, table.Copy(EGP.Frames[ply][index])
	else
		local frame = EGP.Frames[ply][index]
		-- TODO This looks like there should be a return true or something like that at the end of the function
		if not frame then return false end
		Ent.RenderTable = table.Copy(frame)
		Ent:EGP_Update()
	end
end
