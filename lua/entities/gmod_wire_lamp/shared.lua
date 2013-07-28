ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Lamp"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetOn( on )
	self:SetNetworkedBool( "Enabled", on )
end

function ENT:GetOn()
	return self:GetNetworkedVar( "Enabled", true )
end
