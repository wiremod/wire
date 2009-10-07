ENT.Type        = "anim"
ENT.Base        = "base_wire_entity"

ENT.PrintName   = "Wire Speedometer"
ENT.Author      = "Erkle"
ENT.Contact     = "ErkleMad@hotmail.com"


function ENT:GetXYZMode()
	return self.Entity:GetNetworkedBool( 0 )
end

function ENT:GetAngVel()
	return self.Entity:GetNetworkedBool( 1 )
end

function ENT:SetModes( XYZMode, AngVel )
	self.Entity:SetNetworkedBool( 0, XYZMode )
	self.Entity:SetNetworkedBool( 1, AngVel )
end
