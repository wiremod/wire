-- Author: Divran
local Obj = EGP:NewObject( "WedgeOutline" )
Obj.angle = 0
Obj.size = 45
Obj.fidelity = 180
local rad, cos, sin = math.rad, math.cos, math.sin
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0 and self.size != 360) then
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

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		local n = #vertices
		for i=1,n do
			local v = vertices[i]
			if (i+1 > n) then break end
			local x, y = v.x, v.y
			local x2, y2 = vertices[i+1].x, vertices[i+1].y
			surface.DrawLine( x, y, x2, y2 )
		end
		surface.DrawLine( vertices[n].x, vertices[n].y, vertices[1].x, vertices[1].y )
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
	table.Merge( tbl, { angle = self.angle, size = self.size } )
	return tbl
end
