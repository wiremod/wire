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
	net.WriteInt( (self.angle%360)*20, 16 )
	net.WriteUInt( self.fidelity, 8 )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self )
	local tbl = {}
	tbl.angle = net.ReadInt(16)/20
	tbl.fidelity = net.ReadUInt(8)
	table.Merge( tbl, self.BaseClass.Receive( self ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle, fidelity = self.fidelity } )
	return tbl
end
