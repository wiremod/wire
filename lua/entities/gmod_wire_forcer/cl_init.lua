include('shared.lua')

function ENT:Draw()
	self.BaseClass.Draw(self)
	Wire_DrawTracerBeam( self, 1, self:GetForceBeam() )
end
