ENT.Type           = "anim"
ENT.Base           = "base_wire_entity"

ENT.PrintName      = "Wire Control Panel"
ENT.Author         = ""
ENT.Contact        = ""
ENT.Purpose        = ""
ENT.Instructions   = ""

ENT.Spawnable      = false
ENT.AdminSpawnable = false


function ENT:SetChannelValue( channel_number, value )
	self:SetNetworkedFloat( "cVal"..channel_number, value )
end

function ENT:GetChannelValue( channel_number )
	return self:GetNetworkedFloat( "cVal"..channel_number )
end
