ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Speedometer"
ENT.Author      = "Erkle"
ENT.Contact     = "ErkleMad@hotmail.com"


function ENT:GetXYZMode()
	return self:GetNetworkedBool( 0 )
end

function ENT:GetAngVel()
	return self:GetNetworkedBool( 1 )
end

function ENT:SetModes( XYZMode, AngVel )
	self:SetNetworkedBool( 0, XYZMode )
	self:SetNetworkedBool( 1, AngVel )
end
