ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Vector Thruster"
ENT.Author          = "TAD2020"
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetEffect( name )
	self:SetNetworkedString( "Effect", name )
end
function ENT:GetEffect()
	return self:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self:SetNetworkedBool( "vecon", boolon, true )
end
function ENT:IsOn()
	return self:GetNetworkedBool( "vecon" )
end

function ENT:SetMode( v )
	self:SetNetworkedInt( "vecmode", v, true )
end
function ENT:GetMode()
	return self:GetNetworkedInt( "vecmode" )
end

function ENT:SetOffset( v )
	self:SetNetworkedVector( "Offset", v, true )
end
function ENT:GetOffset( name )
	return self:GetNetworkedVector( "Offset" )
end

function ENT:SetNormal( v )
	self:SetNetworkedInt( "vecx", v.x * 100, true )
	self:SetNetworkedInt( "vecy", v.y * 100, true )
	self:SetNetworkedInt( "vecz", v.z * 100, true )
end
function ENT:GetNormal()
	return Vector(
				self:GetNetworkedInt( "vecx" ) / 100,
				self:GetNetworkedInt( "vecy" ) / 100,
				self:GetNetworkedInt( "vecz" ) / 100
			)
end
