ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Plug"
ENT.Author          = "Divran"
ENT.Contact         = "www.wiremod.com"
ENT.Purpose         = "Links with a socket"
ENT.Instructions    = "Move a plug close to a socket to link them, and data will be transferred through the link."

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:GetClosestSocket()
	local sockets = ents.FindInSphere( self:GetPos(), 100 )

	local ClosestDist
	local Closest

	for k,v in pairs( sockets ) do
		if (v:GetClass() == "gmod_wire_socket" and !v:GetNWBool( "Linked", false )) then
			local pos, _ = v:GetLinkPos()
			local Dist = self:GetPos():Distance( pos )
			if (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end
