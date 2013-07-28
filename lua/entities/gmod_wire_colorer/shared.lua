ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire Colorer"
ENT.Author          = ""
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
	self:SetNetworkedBool( "On", boolon, true )
end

function ENT:IsOn()
	return self:GetNetworkedBool( "On" )
end

function ENT:SetOffset( v )
	self:SetNetworkedVector( "Offset", v, true )
end

function ENT:GetOffset()
	return self:GetNetworkedVector( "Offset" )
end

function ENT:SetBeamLength( length )
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end
