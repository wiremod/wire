--------------------------------------------------------
--  Frame Saving & Loading
--------------------------------------------------------

local EGP = EGP

EGP.Frames = WireLib.RegisterPlayerTable()

function EGP:SaveFrame( ply, Ent, index )
	if not EGP.Frames[ply] then EGP.Frames[ply] = {} end
	EGP.Frames[ply][index] = table.Copy(Ent.RenderTable)
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
