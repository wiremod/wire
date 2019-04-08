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
		for i=0,self.fidelity-1 do
			local radd = rad(i*360/self.fidelity)
			local x = cos(radd)
			local y = sin(radd)

			local tempx = x * self.w * c - y * self.h * s + self.x
			y = x * self.w * s + y * self.h * c + self.y
			x = tempx

			vertices[#vertices+1] = { x = x, y = y, u = u, v = v }
		end

		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		EGP:DrawPath(vertices, self.size, true)
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
