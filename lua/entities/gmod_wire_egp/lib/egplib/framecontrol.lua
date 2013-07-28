--------------------------------------------------------
--  Frame Saving & Loading
--------------------------------------------------------

local EGP = EGP

EGP.Frames = {}

function EGP:SaveFrame( ply, Ent, index )
	if (!EGP.Frames[ply]) then EGP.Frames[ply] = {} end
	EGP.Frames[ply][index] = table.Copy(Ent.RenderTable)
end

function EGP:LoadFrame( ply, Ent, index )
	if (!EGP.Frames[ply]) then EGP.Frames[ply] = {} return false end
	if (SERVER) then
		local bool = (EGP.Frames[ply][index] != nil)
		if (!bool) then return false end
		return true, table.Copy(EGP.Frames[ply][index])
	else
		local frame = EGP.Frames[ply][index]
		if (!frame) then return false end
		Ent.RenderTable = table.Copy(frame)
		Ent:EGP_Update()
	end
end
