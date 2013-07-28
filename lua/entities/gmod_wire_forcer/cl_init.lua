include('shared.lua')

function ENT:Draw()
	self.BaseClass.Draw(self)
	if (self:GetNWBool("ShowBeam",false)) then Wire_DrawTracerBeam( self, 1, self:GetForceBeam() ) end
end
