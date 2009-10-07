ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Hover Drive Controller"
ENT.Author          = "TAD2020"
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = true
ENT.AdminSpawnable  = false

cleanup.Register("hoverdrivecontrolers")

function ENT:GetTargetZ()
	return self.Entity:GetNetworkedInt( 0 )
end
function ENT:SetTargetZ( z )
	return self.Entity:SetNetworkedInt( 0, z )
end


function ENT:GetSpeed()

	// Sensible limits
	if (!SinglePlayer()) then
		return math.Clamp( self.Entity:GetNetworkedFloat( 1 ), 0.0, 10.0 )
	end

	return self.Entity:GetNetworkedFloat( 1 )
end

function ENT:SetSpeed( s )

	self.Entity:SetNetworkedFloat( 1, s )

end


function ENT:GetHoverMode()
	return self.Entity:GetNetworkedInt( 2 )
end

function ENT:SetHoverMode( h )
	return self.Entity:SetNetworkedInt( 2, h )
end
