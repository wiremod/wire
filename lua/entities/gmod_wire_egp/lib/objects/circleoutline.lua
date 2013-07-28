-- Author: Divran
local Obj = EGP:NewObject( "CircleOutline" )
Obj.angle = 0
Obj.size = 1
Obj.fidelity = 180
local cos, sin, rad, floor = math.cos, math.sin, math.rad, math.floor
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		local vertices = {}
		local ang = -rad(self.angle)
		local c = cos(ang)
		local s = sin(ang)
		for i=0,360,360/self.fidelity do
			local radd = rad(i)
			local x = cos(radd)
			local y = sin(radd)

			local tempx = x * self.w * c - y * self.h * s + self.x
			y = x * self.w * s + y * self.h * c + self.y
			x = tempx

			vertices[#vertices+1] = { x = x, y = y, u = u, v = v }
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )

		local n = #vertices
		for i=1, n do
			local v = vertices[i]
			if (i+1<=n) then
				local x, y = v.x, v.y
				local x2, y2 = vertices[i+1].x, vertices[i+1].y
				EGP:DrawLine( x, y, x2, y2, self.size )
			end
		end

		EGP:DrawLine( vertices[n].x, vertices[n].y, vertices[1].x, vertices[1].y, self.size )
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
