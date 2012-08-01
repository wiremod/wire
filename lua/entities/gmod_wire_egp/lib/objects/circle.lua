-- Author: Divran
local Obj = EGP:NewObject( "Circle" )
Obj.angle = 0
Obj.fidelity = 180
local cos, sin, rad, floor = math.cos, math.sin, math.rad, math.floor
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		local vertices = {}
		local ang = -rad(self.angle)
		local c = cos(ang)
		local s = sin(ang)
		for i=0,360,floor(360/self.fidelity) do
			local radd = rad(i)
			local x = cos(radd)
			local u = (x+1)/2
			local y = sin(radd)
			local v = (y+1)/2

			local tempx = x * self.w * c - y * self.h * s + self.x
			y = x * self.w * s + y * self.h * c + self.y
			x = tempx

			vertices[#vertices+1] = { x = x, y = y, u = u, v = v }
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		if (vertices and #vertices>0) then
			surface.DrawPoly( vertices )
		end
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( (self.angle%360)*20 )
	EGP.umsg.Char( self.fidelity - 128 )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.angle = um:ReadShort()/20
	tbl.fidelity = um:ReadChar() + 128
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle, fidelity = self.fidelity } )
	return tbl
end
