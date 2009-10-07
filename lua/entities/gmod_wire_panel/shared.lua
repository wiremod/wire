ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Control Panel"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetChannelValue( int, float )
	if (int == 1) then self.Entity:SetNetworkedFloat( "cVal1", float ) end
	if (int == 2) then self.Entity:SetNetworkedFloat( "cVal2", float ) end
	if (int == 3) then self.Entity:SetNetworkedFloat( "cVal3", float ) end
	if (int == 4) then self.Entity:SetNetworkedFloat( "cVal4", float ) end
	if (int == 5) then self.Entity:SetNetworkedFloat( "cVal5", float ) end
	if (int == 6) then self.Entity:SetNetworkedFloat( "cVal6", float ) end
	if (int == 7) then self.Entity:SetNetworkedFloat( "cVal7", float ) end
	if (int == 8) then self.Entity:SetNetworkedFloat( "cVal8", float ) end
end

function ENT:GetChannelValue( int )
	if (int == 1) then return self.Entity:GetNetworkedFloat( "cVal1" ) end
	if (int == 2) then return self.Entity:GetNetworkedFloat( "cVal2" ) end
	if (int == 3) then return self.Entity:GetNetworkedFloat( "cVal3" ) end
	if (int == 4) then return self.Entity:GetNetworkedFloat( "cVal4" ) end
	if (int == 5) then return self.Entity:GetNetworkedFloat( "cVal5" ) end
	if (int == 6) then return self.Entity:GetNetworkedFloat( "cVal6" ) end
	if (int == 7) then return self.Entity:GetNetworkedFloat( "cVal7" ) end
	if (int == 8) then return self.Entity:GetNetworkedFloat( "cVal8" ) end
end
