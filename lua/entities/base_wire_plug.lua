AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )

function ENT:GetClosestSocket()
	local sockets = ents.FindInSphere( self:GetPos(), 100 )

	local ClosestDist
	local Closest

	for k,v in pairs( sockets ) do
		if (v:GetClass() == self:GetSocketClass() and not v:GetNWBool( "Linked", false )) then
			local pos, _ = v:GetLinkPos()
			local Dist = self:GetPos():Distance( pos )
			if Dist<=v:GetAttachRange() and (ClosestDist == nil or ClosestDist > Dist) then
				ClosestDist = Dist
				Closest = v
			end
		end
	end

	return Closest
end

if CLIENT then
	function ENT:DrawEntityOutline()
		if (GetConVar("wire_plug_drawoutline"):GetBool()) then
			BaseClass.DrawEntityOutline( self )
		end
	end
	return -- No more client
end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Socket = nil
	self:SetNWBool( "Linked", false )
end

function ENT:SetSocket(socket)
	self.Socket = socket
	self:SetNWBool("Linked",IsValid(socket))
end
