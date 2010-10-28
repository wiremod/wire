local Obj = EGP:NewObject( "Circle" )
Obj.material = ""
Obj.angle = 0
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		local vertices = {}
		local ang = -math.rad(self.angle)
		local c = math.cos(ang)
		local s = math.sin(ang)
		for i=0,360,10 do
			local rad = math.rad(i)
			local x = math.cos(rad)
			local u = (x+1)/2
			local y = math.sin(rad)
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
	EGP.umsg.Short( self.angle )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.angle = um:ReadShort()
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	table.Merge( tbl, { angle = self.angle } )
	return tbl
end
