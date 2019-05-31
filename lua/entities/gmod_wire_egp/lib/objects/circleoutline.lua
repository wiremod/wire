-- Author: Divran
local Obj = EGP:NewObject( "CircleOutline" )
Obj.angle = 0
Obj.size = 1
Obj.fidelity = 180
local cos, sin, rad = math.cos, math.sin, math.rad
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity"}) then
			local vertices = {}
			local ang = -rad(self.angle)
			local c = cos(ang)
			local s = sin(ang)
			for radd=0, 2*math.pi*(1 - 0.5/self.fidelity), 2*math.pi/self.fidelity do
				local x = cos(radd)
				local y = sin(radd)

				local tempx = x * self.w * c - y * self.h * s + self.x
				y = x * self.w * s + y * self.h * c + self.y
				x = tempx

				vertices[#vertices+1] = { x = x, y = y }
			end
			self.vert_cache.verts = vertices
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawPath(self.vert_cache.verts, self.size, true)
	end
end
Obj.Transmit = function( self )
	net.WriteInt( (self.angle%360)*20, 16 )
	net.WriteInt( self.size, 16 )
	net.WriteUInt(self.fidelity, 8)
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.angle = net.ReadInt(16)/20
	tbl.size = net.ReadInt(16)
	tbl.fidelity = net.ReadUInt(8)
	table.Merge( tbl, self.BaseClass.Receive( self ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle, size = self.size, fidelity = self.fidelity } )
	return tbl
end
