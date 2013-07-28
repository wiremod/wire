ENT.Type            = "anim"
ENT.Base            = "base_anim"

ENT.PrintName       = "Wire Hologram"
ENT.Author          = "McLovin"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false

--Taken from base_gmodentity--
function ENT:SetPlayer( ply )
	self:SetVar( "Founder", ply )
	self:SetVar( "FounderIndex", ply:UniqueID() )

	self:SetNetworkedString( "FounderName", ply:Nick() )
end

function ENT:GetPlayer()
	return self:GetVar( "Founder", NULL )
end
