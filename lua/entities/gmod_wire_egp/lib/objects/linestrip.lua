-- Author: sk8 (& Divran)

local Obj = E2Lib.EGP.ObjectInherit("LineStrip", "PolyOutline")

Obj.Draw = function( self )
	local n = #self.vertices
	if (self.a>0 and n>0 and self.size>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		EGP:DrawPath(self.vertices, self.size, false)
	end
end

return Obj