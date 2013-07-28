include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw()
	// Update renderbounds
	local length = self:GetBeamLength()
	if self.render_beam_length ~= length then
		local bbmin = self:OBBMins()
		local bbmax = self:OBBMaxs()
		bbmax = bbmax + Vector(0, 0, length)

		self.render_beam_length = length
		self:SetRenderBounds(bbmin, bbmax)
	end

	self.BaseClass.Draw(self)
	Wire_DrawTracerBeam( self, 1 )
end
