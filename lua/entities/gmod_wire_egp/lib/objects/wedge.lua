-- Author: Divran
local Obj = EGP:NewObject( "Wedge" )
Obj.angle = 0
Obj.size = 45
Obj.fidelity = 180
local rad, cos, sin = math.rad, math.cos, math.sin
Obj.Draw = function( self )
	if self.a>0 and self.w > 0 and self.h > 0 and self.size ~= 360 then
		if EGP:CacheNeedsUpdate(self, {"x", "y", "w", "h", "angle", "fidelity", "size"}) then
			local vertices = {}

			vertices[1] = { x = self.x, y = self.y, u = 0, v = 0 }
			local ang = -rad(self.angle)
			local c = cos(ang)
			local s = sin(ang)
			for ii=0,self.fidelity do
				local i = ii*(360-self.size)/self.fidelity
				local radd = rad(i)
				local x = cos(radd)
				local u = (x+1)/2
				local y = sin(radd)
				local v = (y+1)/2

				--radd = -rad(self.angle)
				local tempx = x * self.w * c - y * self.h * s + self.x
				y = x * self.w * s + y * self.h * c + self.y
				x = tempx

				vertices[ii+2] = { x = x, y = y, u = u, v = v }
			end
			self.vert_cache.verts = vertices
		end
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawPoly( self.vert_cache.verts )
	end
end
Obj.Transmit = function( self )
	net.WriteInt( (self.angle%360)*20, 16 )
	net.WriteInt( (self.size%360)*20, 16 )
	net.WriteUInt(self.fidelity, 8)
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.angle = net.ReadInt(16)/20
	tbl.size = net.ReadInt(16)/20
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
function Obj:Contains(egp, x, y)
	x, y = EGP.WorldToLocal(egp, self, x, y)
	x, y = x / self.w, y / self.h
	
	if x * x + y * y > 1 then return false end
	theta = math.deg(math.atan2(y, x))
	return theta <= -self.size or 0 <= theta
end
