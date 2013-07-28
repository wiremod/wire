ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Dynamic Button"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetOn( bOn )
	self:SetNetworkedBool( "OnOff", bOn, true )
end
function ENT:IsOn()
	return self:GetNetworkedBool( "OnOff" )
end
