
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw()
	self.BaseClass.Draw(self)
	Wire_DrawTracerBeam( self, 1 )
end
