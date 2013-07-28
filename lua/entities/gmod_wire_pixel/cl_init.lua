
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw( )
	self:DrawModel( )
end

function ENT:DrawEntityOutline( ff )
end

function ENT:DoNormalDraw( )

end
