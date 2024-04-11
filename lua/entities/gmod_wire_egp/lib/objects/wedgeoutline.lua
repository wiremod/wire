-- Author: Divran
local Obj = E2Lib.EGP.ObjectInherit("WedgeOutline", "Wedge")
local rad, cos, sin = math.rad, math.cos, math.sin

Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0 and self.size ~= 360) then
		if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity", "size"}) then
			local vertices = {}

			vertices[1] = { x = self.x, y = self.y }
			local ang = -rad(self.angle)
			local c = cos(ang)
			local s = sin(ang)
			for ii=0,self.fidelity do
				local i = ii*(360-self.size)/self.fidelity
				local radd = rad(i)
				local x = cos(radd)
				local y = sin(radd)
				local tempx = x * self.w * c - y * self.h * s + self.x
				y = x * self.w * s + y * self.h * c + self.y
				x = tempx

				vertices[ii+2] = { x = x, y = y }
			end
			self.vert_cache.verts = vertices
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawPath(self.vert_cache.verts, 1, true)
	end
end
