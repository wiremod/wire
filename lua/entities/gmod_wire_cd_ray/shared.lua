ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Wire CD Ray"
ENT.Author          = ""
ENT.Contact         = ""
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false


function ENT:SetEffect( name )
	self.Entity:SetNetworkedString( "Effect", name )
end

function ENT:GetEffect( name )
	return self.Entity:GetNetworkedString( "Effect" )
end


function ENT:SetOn( boolon )
	self.Entity:SetNetworkedBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self.Entity:GetNetworkedBool( "On" )
end

function ENT:SetOffset( v )
	self.Entity:SetNetworkedVector( "Offset", v, true )
end

function ENT:GetOffset( name )
	return self.Entity:GetNetworkedVector( "Offset" )
end

function ENT:SetBeamRange(length)
	self.Entity:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamRange()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end

function ENT:GetBeamLength()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end
