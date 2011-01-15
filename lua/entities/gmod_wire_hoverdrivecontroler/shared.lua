ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Hover Drive Controller"
ENT.Author          = "TAD2020"
ENT.Contact         = ""
ENT.Purpose         = "It Teleports."
ENT.Instructions    = "Use wire."
ENT.Category		= "Wiremod"

ENT.Spawnable       = true
ENT.AdminSpawnable  = true

cleanup.Register("hoverdrivecontrolers")

function ENT:GetTargetZ()
	return self:GetNetworkedInt( 0 )
end
function ENT:SetTargetZ( z )
	return self:SetNetworkedInt( 0, z )
end


function ENT:GetSpeed()

	// Sensible limits
	if (!SinglePlayer()) then
		return math.Clamp( self:GetNetworkedFloat( 1 ), 0.0, 10.0 )
	end

	return self:GetNetworkedFloat( 1 )
end

function ENT:SetSpeed( s )

	self:SetNetworkedFloat( 1, s )

end


function ENT:GetHoverMode()
	return self:GetNetworkedInt( 2 )
end

function ENT:SetHoverMode( h )
	return self:SetNetworkedInt( 2, h )
end
