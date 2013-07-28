ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Gyroscope"
ENT.Author      = "Erkle"
ENT.Contact     = "ErkleMad@hotmail.com"


function ENT:GetOut180()
	return self:GetNetworkedBool( 0 )
end

function ENT:SetOut180( Out180 )
	return self:SetNetworkedBool( 0, Out180 )
end
