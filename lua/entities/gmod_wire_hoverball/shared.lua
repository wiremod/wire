ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Hover Ball"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:GetTargetZ()
	return self:GetNetworkedInt( 0 )
end

function ENT:SetTargetZ( z )
	return self:SetNetworkedInt( 0, z )
end


function ENT:GetSpeed()

	// Sensible limits
	if (!game.SinglePlayer()) then
		return math.Clamp( self:GetNetworkedFloat( 1 ), 0.0, 10.0 )
	end

	return self:GetNetworkedFloat( 1 )
end

function ENT:SetSpeed( s )

	self:SetNetworkedFloat( 1, s )

end


function ENT:GetHoverMode()
	return self:GetNetworkedBool( 2 )
end

function ENT:SetHoverMode( h )
	return self:SetNetworkedBool( 2, h )
end
